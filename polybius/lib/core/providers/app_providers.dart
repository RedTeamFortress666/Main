import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/storage/create_polybius_secret_store.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/models/models.dart';
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

final cipherEngineProvider = Provider<CipherEngine>((ref) => CipherEngine());

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
  });

  final UserAccount? user;
  final bool isLoading;
  final String? error;
  final bool needsPin;

  bool get isAuthenticated => user != null && !needsPin;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage) : super(const AuthState()) {
    _restoreSession();
  }

  final StorageService _storage;

  Future<void> _restoreSession() async {
    final username = await _storage.getSessionUser();
    if (username == null) return;
    final account = await _storage.getAccount(username);
    if (account == null) return;
    state = AuthState(
      user: account,
      needsPin: account.requiresPin,
    );
  }

  Future<bool> login(String username, String password) async {
    state = const AuthState(isLoading: true);
    final account = await _storage.getAccount(username.toUpperCase());
    if (account == null) {
      state = const AuthState(error: 'INVALID CREDENTIALS');
      return false;
    }
    final hash = EncryptionService.hashPassword(password);
    if (hash != account.passwordHash) {
      await _storage.logAudit('LOGIN_FAIL', username);
      state = const AuthState(error: 'ACCESS DENIED');
      return false;
    }
    final updated = account.copyWith(lastLogin: DateTime.now());
    await _storage.saveAccount(updated);
    await _storage.setSessionUser(updated.username);
    await _storage.logAudit('LOGIN_OK', username);
    state = AuthState(user: updated, needsPin: updated.requiresPin);
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final user = state.user;
    if (user == null) return false;
    if (EncryptionService.hashPin(pin) != user.pinHash) {
      await _storage.logAudit('PIN_FAIL', user.username);
      return false;
    }
    await _storage.logAudit('PIN_OK', user.username);
    state = AuthState(user: user);
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
  });

  final UnlockState state;
  final bool titleHeld;
  final bool showGlitch;
  final bool fakeCrash;

  UnlockStateData copyWith({
    UnlockState? state,
    bool? titleHeld,
    bool? showGlitch,
    bool? fakeCrash,
  }) =>
      UnlockStateData(
        state: state ?? this.state,
        titleHeld: titleHeld ?? this.titleHeld,
        showGlitch: showGlitch ?? this.showGlitch,
        fakeCrash: fakeCrash ?? this.fakeCrash,
      );
}

class UnlockNotifier extends StateNotifier<UnlockStateData> {
  UnlockNotifier(this._storage) : super(const UnlockStateData());

  final StorageService _storage;

  void onTitleHoldStart() {
    state = state.copyWith(titleHeld: true);
  }

  void onTitleHoldComplete() {
    state = state.copyWith(
      titleHeld: false,
      showGlitch: true,
      state: state.state == UnlockState.locked
          ? UnlockState.hinted
          : state.state,
    );
    _storage.logAudit('UNLOCK_RITUAL', 'SYSTEM', 'Title hold completed');
  }

  void onGlitchComplete() {
    state = state.copyWith(showGlitch: false);
  }

  void checkDifficultyRitual(GameSettings settings) {
    if (settings.difficulty == UnlockCodes.ritualDifficulty &&
        settings.language == 'ENGLISH') {
      if (state.state.index < UnlockState.partial.index) {
        state = state.copyWith(state: UnlockState.partial);
        _storage.logAudit('UNLOCK_RITUAL', 'SYSTEM', 'Difficulty 11 ritual');
      }
    }
    if (settings.difficulty == int.parse(UnlockCodes.compoundDifficulty) &&
        settings.language == UnlockCodes.compoundLanguage) {
      state = state.copyWith(state: UnlockState.unlocked, showGlitch: true);
      _storage.logAudit('UNLOCK_RITUAL', 'SYSTEM', 'Compound unlock');
    }
  }

  Future<void> checkInviteCode(
    String code,
    GameSettings settings,
    UserTier? userTier,
  ) async {
    final upper = code.toUpperCase();
    if (upper == UnlockCodes.devB1663R || upper == UnlockCodes.devD1663R) {
      if (settings.language == UnlockCodes.ritualLanguage) {
        state = state.copyWith(state: UnlockState.developer, showGlitch: true);
        await _storage.logAudit('DEV_UNLOCK', 'SYSTEM', upper);
        return;
      }
    }
    final invite = await _storage.getInvite(upper);
    if (invite != null && !invite.isUsed) {
      state = state.copyWith(state: UnlockState.unlocked, showGlitch: true);
      await _storage.logAudit('INVITE_UNLOCK', 'SYSTEM', upper);
    }
    if (userTier == UserTier.developer || userTier == UserTier.admin) {
      state = state.copyWith(
        state: userTier == UserTier.developer
            ? UnlockState.developer
            : UnlockState.unlocked,
      );
    }
  }

  void triggerFakeCrash() {
    state = state.copyWith(fakeCrash: true);
    Future.delayed(const Duration(seconds: 2), () {
      state = state.copyWith(fakeCrash: false);
    });
  }

  void reset() {
    state = const UnlockStateData();
  }
}

final unlockProvider =
    StateNotifierProvider<UnlockNotifier, UnlockStateData>((ref) {
  return UnlockNotifier(ref.read(storageServiceProvider));
});
