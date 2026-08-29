import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/storage/create_polybius_secret_store.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';
import 'package:polybius/features/duress/cabinet_identity.dart';
import 'package:polybius/features/duress/duress_session.dart';
import 'package:polybius/features/transport/transport_hub.dart';
import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';

final secretStoreProvider = Provider((_) => createPolybiusSecretStore());

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService(ref.read(secretStoreProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.read(encryptionServiceProvider));
});

/// The active cipher pool seed. Defaults to today's date so behaviour is
/// unchanged until the user randomises or syncs a pool. Persisted so a synced
/// pool survives restarts.
final poolSeedProvider =
    StateNotifierProvider<PoolSeedNotifier, String>((ref) {
  return PoolSeedNotifier(ref.read(storageServiceProvider));
});

class PoolSeedNotifier extends StateNotifier<String> {
  PoolSeedNotifier(this._storage) : super(DailyPool().dateKey) {
    _load();
  }

  final StorageService _storage;

  Future<void> _load() async {
    final saved = await _storage.getPoolSeed();
    if (saved != null) state = saved;
  }

  /// Generate a fresh random pool (new hidden mapping / rotor configuration).
  void randomise() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    setSeed(base64Url.encode(bytes));
  }

  void setSeed(String seed) {
    state = seed;
    _storage.setPoolSeed(seed);
  }
}

final cabinetLampProvider = StateProvider<bool>((_) => false);

final glyphDensityProvider =
    StateProvider<GlyphDensity>((_) => GlyphDensity.compact);

class DuressNotifier extends StateNotifier<DuressSession> {
  DuressNotifier() : super(DuressSession.idle);

  void arm(DuressSession session) => state = session;

  void disarm() => state = DuressSession.idle;
}

final duressProvider =
    StateNotifierProvider<DuressNotifier, DuressSession>((ref) {
  return DuressNotifier();
});

final transportHubProvider = Provider<TransportHub>((_) => TransportHub());

final cipherEngineProvider = Provider<CipherEngine>((ref) {
  final seed = ref.watch(poolSeedProvider);
  final duress = ref.watch(duressProvider);
  return CipherEngine(seed: duress.effectiveSeed ?? seed);
});

/// Always the real pool id. Cover sessions keep this on the chrome so the
/// cabinet does not change its nameplate.
final displayPoolIdProvider = Provider<String>((ref) {
  return PoolSync.poolIdFor(ref.watch(poolSeedProvider));
});

final gameSettingsProvider =
    StateNotifierProvider<GameSettingsNotifier, GameSettings>((ref) {
  return GameSettingsNotifier(ref.read(storageServiceProvider));
});

class GameSettingsNotifier extends StateNotifier<GameSettings> {
  GameSettingsNotifier(this._storage) : super(const GameSettings()) {
    _load();
  }

  final StorageService _storage;

  Future<void> _load() async {
    state = await _storage.getSettings();
  }

  Future<void> update(GameSettings settings) async {
    state = settings;
    await _storage.saveSettings(settings);
  }
}

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.needsPin = false,
    this.isRestoring = false,
    this.coverArmed = false,
  });

  final UserAccount? user;
  final bool isLoading;
  final String? error;
  final bool needsPin;
  final bool isRestoring;

  /// In-memory only. Never persist. Do not render this flag in the arcade.
  final bool coverArmed;

  bool get isAuthenticated => user != null && !needsPin;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage) : super(const AuthState()) {
    _restoreSession();
  }

  final StorageService _storage;

  Future<void> _restoreSession() async {
    state = const AuthState(isRestoring: true);
    final username = await _storage.getSessionUser();
    if (username == null) {
      state = const AuthState();
      return;
    }
    final account = await _storage.getAccount(username);
    if (account == null) {
      await _storage.clearSession();
      state = const AuthState();
      return;
    }
    state = AuthState(
      user: account,
      needsPin: account.requiresPin,
    );
  }

  static const _maxAttemptsBeforeLockout = 5;
  static const _lockoutDuration = Duration(seconds: 30);
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  bool get _isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  void _recordFailure() {
    _failedAttempts++;
    if (_failedAttempts >= _maxAttemptsBeforeLockout) {
      _lockoutUntil = DateTime.now().add(_lockoutDuration);
      _failedAttempts = 0;
    }
  }

  Future<bool> login(String username, String password) async {
    if (_isLockedOut) {
      state = const AuthState(error: 'TOO MANY ATTEMPTS — TRY AGAIN LATER');
      return false;
    }
    state = const AuthState(isLoading: true);
    final account = await _storage.getAccount(username.toUpperCase());
    // Same error for unknown user and bad password to avoid enumeration.
    if (account == null ||
        !EncryptionService.verifyPassword(password, account.passwordHash)) {
      _recordFailure();
      await _storage.logAudit('LOGIN_FAIL', username);
      state = const AuthState(error: 'ACCESS DENIED');
      return false;
    }
    _failedAttempts = 0;
    var updated = account.copyWith(lastLogin: DateTime.now());
    if (EncryptionService.isLegacyHash(account.passwordHash)) {
      updated = updated.copyWith(
        passwordHash: EncryptionService.hashPassword(password),
      );
    }
    await _storage.saveAccount(updated);
    await _storage.setSessionUser(updated.username);
    await _storage.logAudit('LOGIN_OK', username);
    state = AuthState(user: updated, needsPin: updated.requiresPin);
    return true;
  }

  /// Creates a new user-tier account. Returns null on success, or an error
  /// message. Does not log the new user in.
  Future<String?> register(String username, String password) async {
    final u = username.trim().toUpperCase();
    if (u.isEmpty || password.isEmpty) {
      return 'ENTER A USERNAME AND PASSWORD';
    }
    if (password.length < 4) return 'PASSWORD TOO SHORT';
    final existing = await _storage.getAccount(u);
    if (existing != null) return 'ACCOUNT ALREADY EXISTS';
    final account = UserAccount(
      username: u,
      passwordHash: EncryptionService.hashPassword(password),
      pinHash: EncryptionService.hashPin('000000'),
      tier: UserTier.agent,
      createdAt: DateTime.now(),
    );
    await _storage.saveAccount(account);
    await _storage.logAudit('REGISTER', u);
    return null;
  }

  Future<bool> verifyPin(String pin) async {
    final user = state.user;
    if (user == null) return false;
    if (_isLockedOut) return false;
    final cabinet = await _storage.getCabinet(user.username);
    final realOk = EncryptionService.verifyPin(pin, user.pinHash);
    final coverOk = cabinet != null &&
        EncryptionService.verifyPin(pin, cabinet.duressPinHash);
    // Always evaluate both. Same audit action either way — a DURESS_OK
    // line would be a gift to the person holding the cabinet.
    if (!realOk && !coverOk) {
      _recordFailure();
      await _storage.logAudit('PIN_FAIL', user.username);
      return false;
    }
    _failedAttempts = 0;
    await _storage.logAudit('PIN_OK', user.username);
    var cleared = user.copyWith(requiresPin: false);
    if (realOk && EncryptionService.isLegacyHash(user.pinHash)) {
      cleared = cleared.copyWith(pinHash: EncryptionService.hashPin(pin));
    }
    await _storage.saveAccount(cleared);
    state = AuthState(user: cleared, coverArmed: coverOk && !realOk);
    return true;
  }

  Future<void> armCabinet({
    required String coverPin,
    required String initials,
    required String coverPlaintext,
  }) async {
    final user = state.user;
    if (user == null) return;
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    await _storage.saveCabinet(
      user.username,
      CabinetIdentity(
        duressPinHash: EncryptionService.hashPin(coverPin),
        coverInitials: initials,
        coverPlaintext: coverPlaintext,
        coverSalt: salt,
      ),
    );
    await _storage.logAudit('PIN_MINT', user.username);
  }

  Future<void> logout() async {
    final user = state.user?.username ?? 'UNKNOWN';
    await _storage.logAudit('LOGOUT', user);
    await _storage.clearSession();
    state = const AuthState();
  }

  void clearCoverFlag() {
    if (!state.coverArmed) return;
    state = AuthState(user: state.user);
  }

  Future<String> mintInvite(InviteTier tier, String createdBy) async {
    const uuid = Uuid();
    final code = 'PB-${uuid.v4().substring(0, 8).toUpperCase()}';
    final invite = InviteCode(
      code: code,
      tier: tier,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    await _storage.saveInvite(invite);
    await _storage.logAudit('INVITE_MINT', createdBy, code);
    return code;
  }

  Future<void> forcePoolReset(String actor) async {
    await _storage.clearSession();
    final accounts = await _storage.getAllAccounts();
    for (final account in accounts) {
      if (account.tier != UserTier.developer) {
        await _storage.saveAccount(account.copyWith(requiresPin: true));
      }
    }
    await _storage.logAudit('POOL_FORCE', actor, 'All users require PIN re-auth');
    state = const AuthState();
  }

  Future<void> setAdminPin(String pin, String actor) async {
    final dev = await _storage.getAccount(AppConstants.developerUsername);
    if (dev == null) return;
    await _storage.saveAccount(
      dev.copyWith(pinHash: EncryptionService.hashPin(pin)),
    );
    await _storage.logAudit('PIN_MINT', actor);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(storageServiceProvider));
});

class UnlockStateData {
  const UnlockStateData({
    this.state = UnlockState.locked,
    this.titleHeld = false,
    this.showGlitch = false,
    this.fakeCrash = false,
    this.pathwayPrimed = false,
  });

  final UnlockState state;
  final bool titleHeld;
  final bool showGlitch;
  final bool fakeCrash;

  /// Set after the 6-second title hold: opens the route toward the hidden
  /// dev access portal (difficulty 11 + Russian hold-to-select).
  final bool pathwayPrimed;

  UnlockStateData copyWith({
    UnlockState? state,
    bool? titleHeld,
    bool? showGlitch,
    bool? fakeCrash,
    bool? pathwayPrimed,
  }) =>
      UnlockStateData(
        state: state ?? this.state,
        titleHeld: titleHeld ?? this.titleHeld,
        showGlitch: showGlitch ?? this.showGlitch,
        fakeCrash: fakeCrash ?? this.fakeCrash,
        pathwayPrimed: pathwayPrimed ?? this.pathwayPrimed,
      );
}

class UnlockNotifier extends StateNotifier<UnlockStateData> {
  UnlockNotifier(this._storage) : super(const UnlockStateData()) {
    _loadPersisted();
  }

  final StorageService _storage;

  Future<void> _loadPersisted() async {
    final saved = await _storage.getUnlockState();
    if (saved != null) {
      state = state.copyWith(state: saved);
    }
  }

  void _persistUnlock() {
    _storage.saveUnlockState(state.state);
  }

  void grantDeveloperAccess() {
    if (state.state.index < UnlockState.developer.index) {
      state = state.copyWith(state: UnlockState.developer);
      _persistUnlock();
    }
  }

  /// User-tier cipher access (no dev panel) — granted by the Tr1-66-3R code or
  /// a user-tier signed invite token.
  void grantUserAccess() {
    if (state.state.index < UnlockState.unlocked.index) {
      state = state.copyWith(state: UnlockState.unlocked);
      _persistUnlock();
    }
  }

  void onTitleHoldStart() {
    state = state.copyWith(titleHeld: true);
  }

  void onTitleHoldComplete() {
    final nextState = state.state == UnlockState.locked
        ? UnlockState.hinted
        : state.state;
    state = state.copyWith(
      titleHeld: false,
      showGlitch: true,
      state: nextState,
      pathwayPrimed: true,
    );
    if (nextState != UnlockState.locked) {
      _persistUnlock();
    }
    _storage.logAudit('UNLOCK_RITUAL', 'SYSTEM', 'Title hold completed');
  }

  void onGlitchComplete() {
    state = state.copyWith(showGlitch: false);
  }

  /// The difficulty/language settings no longer unlock the cipher on their own;
  /// they are only part of the ritual that leads to the dev access portal,
  /// which is the sole entry to the crypto engine.
  void checkDifficultyRitual(GameSettings settings) {}

  Future<void> checkInviteCode(
    String code,
    GameSettings settings,
    UserTier? userTier,
  ) async {
    final upper = code.toUpperCase();
    if (upper == UnlockCodes.devB1663R || upper == UnlockCodes.devD1663R) {
      if (settings.language == UnlockCodes.ritualLanguage) {
        state = state.copyWith(state: UnlockState.developer, showGlitch: true);
        _persistUnlock();
        await _storage.logAudit('DEV_UNLOCK', 'SYSTEM', upper);
        return;
      }
    }
    final invite = await _storage.getInvite(upper);
    if (invite != null && !invite.isUsed) {
      if (invite.expiresAt != null &&
          invite.expiresAt!.isBefore(DateTime.now())) {
        await _storage.logAudit('INVITE_EXPIRED', 'SYSTEM', upper);
        return;
      }
      final usedBy = userTier?.name ?? 'UNKNOWN';
      await _storage.saveInvite(
        invite.copyWith(isUsed: true, usedBy: usedBy),
      );
      state = state.copyWith(state: UnlockState.unlocked, showGlitch: true);
      _persistUnlock();
      await _storage.logAudit('INVITE_UNLOCK', 'SYSTEM', upper);
    }
  }

  void triggerFakeCrash() {
    state = state.copyWith(fakeCrash: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (state.fakeCrash) {
        state = state.copyWith(fakeCrash: false);
      }
    });
  }

  void dismissFakeCrash() {
    state = state.copyWith(fakeCrash: false);
  }

  void reset() {
    state = const UnlockStateData();
    _storage.clearUnlockState();
  }
}

final unlockProvider =
    StateNotifierProvider<UnlockNotifier, UnlockStateData>((ref) {
  return UnlockNotifier(ref.read(storageServiceProvider));
});
