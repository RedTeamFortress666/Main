import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/crypto/kyber_keystore.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/core/storage/create_polybius_secret_store.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:uuid/uuid.dart';

final secretStoreProvider = Provider((_) => createPolybiusSecretStore());

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService(ref.read(secretStoreProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.read(encryptionServiceProvider));
});

final kyberKeystoreProvider = Provider<KyberKeystore>((ref) {
  return KyberKeystore(ref.read(secretStoreProvider));
});

final peerPublicKeyProvider = StateProvider<Uint8List?>((ref) => null);

final cipherEngineProvider = Provider<CipherEngine>((ref) {
  final keystore = ref.watch(kyberKeystoreProvider);
  final peer = ref.watch(peerPublicKeyProvider);
  return CipherEngine(keystore: keystore, recipientPublicKey: peer);
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
    // Restored sessions always re-auth with PIN. Password login is stronger.
    state = AuthState(
      user: account,
      needsPin: true,
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

  /// Creates an account. The first operator on an empty store needs no invite;
  /// every later account requires a minted invite code.
  Future<String?> register(
    String username,
    String password,
    String pin, {
    String? inviteCode,
  }) async {
    final u = username.trim().toUpperCase();
    if (u.isEmpty || password.isEmpty) {
      return 'ENTER A USERNAME AND PASSWORD';
    }
    if (password.length < AppConstants.minPasswordLength) {
      return 'PASSWORD TOO SHORT';
    }
    if (pin.length != AppConstants.pinLength || int.tryParse(pin) == null) {
      return 'CHOOSE A 6-DIGIT PIN';
    }
    final existing = await _storage.getAccount(u);
    if (existing != null) return 'ACCOUNT ALREADY EXISTS';
    final accounts = await _storage.getAllAccounts();
    InviteCode? invite;
    if (accounts.isNotEmpty) {
      final code = inviteCode?.trim().toUpperCase() ?? '';
      if (code.isEmpty) return 'INVITE REQUIRED';
      invite = await _storage.getInvite(code);
      if (invite == null || invite.isUsed) return 'INVALID INVITE';
      if (invite.expiresAt != null &&
          invite.expiresAt!.isBefore(DateTime.now())) {
        return 'INVITE EXPIRED';
      }
    }
    final account = UserAccount(
      username: u,
      passwordHash: EncryptionService.hashPassword(password),
      pinHash: EncryptionService.hashPin(pin),
      tier: accounts.isEmpty
          ? UserTier.developer
          : _userTierFromInvite(invite!.tier),
      createdAt: DateTime.now(),
    );
    await _storage.saveAccount(account);
    if (invite != null) {
      await _storage.saveInvite(invite.copyWith(isUsed: true, usedBy: u));
    }
    await _storage.logAudit('REGISTER', u);
    return null;
  }

  static UserTier _userTierFromInvite(InviteTier tier) {
    return switch (tier) {
      InviteTier.standard => UserTier.guest,
      InviteTier.agent => UserTier.agent,
      InviteTier.admin => UserTier.admin,
      InviteTier.developer => UserTier.developer,
    };
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
    await _storage.logAudit('INVITE_MINT', createdBy);
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
    final user = state.user ?? await _storage.getAccount(actor);
    if (user == null) return;
    await _storage.saveAccount(
      user.copyWith(pinHash: EncryptionService.hashPin(pin)),
    );
    await _storage.logAudit('PIN_MINT', actor);
  }

  Future<String?> setPortalPassphrase(String passphrase) async {
    final user = state.user;
    if (user == null) return 'NOT SIGNED IN';
    if (passphrase.length < AppConstants.minPasswordLength) {
      return 'PASSPHRASE TOO SHORT';
    }
    final updated = user.copyWith(
      portalPassHash: EncryptionService.hashPassword(passphrase),
    );
    await _storage.saveAccount(updated);
    state = AuthState(user: updated, needsPin: state.needsPin);
    await _storage.logAudit('PORTAL_PASS', user.username);
    return null;
  }

  bool verifyPortalPassphrase(String passphrase) {
    final hash = state.user?.portalPassHash;
    if (hash == null) return false;
    return EncryptionService.verifyPassword(passphrase, hash);
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
  UnlockNotifier(this._storage) : super(const UnlockStateData());

  final StorageService _storage;

  void grantDeveloperAccess() {
    if (state.state.index < UnlockState.developer.index) {
      state = state.copyWith(state: UnlockState.developer);
    }
  }

  /// User-tier cipher access (no developer panel). Session-only — not persisted.
  void grantUserAccess() {
    if (state.state.index < UnlockState.unlocked.index) {
      state = state.copyWith(state: UnlockState.unlocked);
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
    // Invites are consumed only during register(). This remains a no-op
    // so arcade "load game" rituals cannot open the cipher.
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
