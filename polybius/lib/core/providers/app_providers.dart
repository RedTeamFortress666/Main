import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/core/storage/create_polybius_secret_store.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';
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

/// Rotor complexity (2–6 emojis per character). Dev-configurable; persisted;
/// carried in the pool-sync token so aligned users match.
final cipherComplexityProvider =
    StateNotifierProvider<CipherComplexityNotifier, int>((ref) {
  return CipherComplexityNotifier(ref.read(storageServiceProvider));
});

class CipherComplexityNotifier extends StateNotifier<int> {
  CipherComplexityNotifier(this._storage) : super(2) {
    _load();
  }

  final StorageService _storage;

  Future<void> _load() async {
    final saved = await _storage.getCipherComplexity();
    if (saved != null) state = saved.clamp(2, 6);
  }

  void setComplexity(int value) {
    state = value.clamp(2, 6);
    _storage.setCipherComplexity(state);
  }
}

final cipherEngineProvider = Provider<CipherEngine>((ref) {
  final seed = ref.watch(poolSeedProvider);
  final complexity = ref.watch(cipherComplexityProvider);
  return CipherEngine(seed: seed, complexity: complexity);
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
  });

  final UserAccount? user;
  final bool isLoading;
  final String? error;
  final bool needsPin;
  final bool isRestoring;

  bool get isAuthenticated => user != null && !needsPin;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage) : super(const AuthState()) {
    _restoreSession();
  }

  final StorageService _storage;

  Future<void> _restoreSession() async {
    state = const AuthState(isRestoring: true);
    try {
      // Hard timeout — a hung Hive/secure-storage read must never
      // leave isRestoring=true (that previously trapped the splash).
      await () async {
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
      }().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Timeout or storage failure → treat as logged out.
      state = const AuthState();
    } finally {
      if (state.isRestoring) {
        state = const AuthState();
      }
    }
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
    final normalized = username.trim().toUpperCase();
    // V1 Stable: beta DEVELOPER login is permanently retired.
    if (normalized == AppConstants.retiredDeveloperUsername ||
        (normalized == 'DEVELOPER' && password == 'developer')) {
      await _storage.logAudit('LOGIN_FAIL', username, 'DEVELOPER retired');
      state = const AuthState(
        error: 'DEVELOPER ACCOUNT STRICKEN — V1 STABLE',
      );
      return false;
    }
    state = const AuthState(isLoading: true);
    final account = await _storage.resolveLoginAccount(username);
    // Same error for unknown user and bad password to avoid enumeration.
    final primaryOk = account != null &&
        EncryptionService.verifyPassword(password, account.passwordHash);
    final backupOk = account?.backupPasswordHash != null &&
        EncryptionService.verifyPassword(
            password, account!.backupPasswordHash!);
    if (account == null || (!primaryOk && !backupOk)) {
      _recordFailure();
      await _storage.logAudit('LOGIN_FAIL', username);
      state = const AuthState(error: 'ACCESS DENIED');
      return false;
    }
    _failedAttempts = 0;
    var updated = account.copyWith(lastLogin: DateTime.now());
    // Rehash whichever credential matched if it is still a legacy hash.
    if (primaryOk && EncryptionService.isLegacyHash(account.passwordHash)) {
      updated = updated.copyWith(
        passwordHash: EncryptionService.hashPassword(password),
      );
    } else if (backupOk &&
        account.backupPasswordHash != null &&
        EncryptionService.isLegacyHash(account.backupPasswordHash!)) {
      updated = updated.copyWith(
        backupPasswordHash: EncryptionService.hashPassword(password),
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
    if (u == AppConstants.retiredDeveloperUsername) {
      return 'USERNAME RESERVED / RETIRED';
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
    if (!EncryptionService.verifyPin(pin, user.pinHash)) {
      _recordFailure();
      await _storage.logAudit('PIN_FAIL', user.username);
      return false;
    }
    _failedAttempts = 0;
    await _storage.logAudit('PIN_OK', user.username);
    var cleared = user.copyWith(requiresPin: false);
    if (EncryptionService.isLegacyHash(user.pinHash)) {
      cleared = cleared.copyWith(pinHash: EncryptionService.hashPin(pin));
    }
    await _storage.saveAccount(cleared);
    state = AuthState(user: cleared);
    return true;
  }

  Future<void> logout() async {
    final user = state.user?.username ?? 'UNKNOWN';
    await _storage.logAudit('LOGOUT', user);
    await _storage.clearSession();
    state = const AuthState();
  }

  /// Confirms a password against the current account (used to gate the dev UI).
  bool verifyCurrentPassword(String password) {
    final user = state.user;
    if (user == null) return false;
    return EncryptionService.verifyPassword(password, user.passwordHash);
  }

  Future<String?> changePassword(String newPassword) async {
    final user = state.user;
    if (user == null) return 'NOT LOGGED IN';
    if (newPassword.length < 4) return 'PASSWORD TOO SHORT';
    final updated =
        user.copyWith(passwordHash: EncryptionService.hashPassword(newPassword));
    await _storage.saveAccount(updated);
    await _storage.logAudit('PASSWORD_CHANGE', user.username);
    state = AuthState(user: updated);
    return null;
  }

  Future<void> setDisplayName(String name) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(displayName: name.trim());
    await _storage.saveAccount(updated);
    await _storage.logAudit('RENAME', user.username, name.trim());
    state = AuthState(user: updated);
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
    final actorAccount = await _storage.getAccount(actor.toUpperCase());
    final targetName =
        (actorAccount?.tier == UserTier.admin ||
                actorAccount?.tier == UserTier.developer)
            ? actor.toUpperCase()
            : AppConstants.adminUsername;
    final target = await _storage.getAccount(targetName);
    if (target == null) return;
    await _storage.saveAccount(
      target.copyWith(pinHash: EncryptionService.hashPin(pin)),
    );
    await _storage.logAudit('PIN_MINT', actor, targetName);
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
    final primed = await _storage.getPathwayPrimed();
    if (saved != null || primed) {
      state = state.copyWith(
        state: saved ?? state.state,
        pathwayPrimed: primed,
      );
    }
  }

  void _persistUnlock() {
    _storage.saveUnlockState(state.state);
  }

  void grantDeveloperAccess() {
    // User-tier APK never receives HQ / developer unlock.
    if (!AppFlavor.allowDeveloperTools) {
      grantUserAccess();
      return;
    }
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
    _storage.setPathwayPrimed(true);
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
    if (UnlockCodes.developerCodes.contains(upper)) {
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
    _storage.setPathwayPrimed(false);
  }
}

final unlockProvider =
    StateNotifierProvider<UnlockNotifier, UnlockStateData>((ref) {
  return UnlockNotifier(ref.read(storageServiceProvider));
});
