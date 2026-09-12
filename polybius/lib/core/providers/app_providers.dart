import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/master_glyphs.dart';
import 'package:polybius/core/storage/create_polybius_secret_store.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/auth/v2_login_protocol.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';
import 'package:polybius/features/duress/cabinet_identity.dart';
import 'package:polybius/features/duress/duress_session.dart';
import 'package:polybius/features/redlight/auto_patcher.dart';
import 'package:polybius/features/redlight/cabinet_policy.dart';
import 'package:polybius/features/redlight/leak_detector.dart';
import 'package:polybius/features/redlight/patch_ledger.dart';
import 'package:polybius/features/glasses/glasses_link.dart';
import 'package:polybius/features/redlight/redlight_vault.dart';
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

/// Runs one weave of the interwoven auto-patcher. Returns the chained
/// ledger entry, or null when the patcher is not wired (tests).
typedef Weaver = Future<PatchLedgerEntry?> Function(
  String trigger, {
  String? username,
});

/// Darth Cherry: the only switch that opens the glyph keyboard.
/// Off (default) keeps ENCRYPT as advanced-V1 plaintext.
class DarthCherryNotifier extends StateNotifier<bool> {
  DarthCherryNotifier(this._storage, {this._weaver}) : super(false) {
    _load();
  }

  final StorageService _storage;
  final Weaver? _weaver;

  Future<void> _load() async {
    state = await _storage.getDarthCherry();
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _storage.setDarthCherry(enabled);
    await _storage.logAudit(
      'CHERRY',
      'SYSTEM',
      enabled ? 'DARTH CHERRY ARMED' : 'DARTH CHERRY DARK',
    );
    if (enabled) {
      // Arming Cherry is a weave trigger: the mixer, ticket and policy are
      // re-asserted and the ledger gets a CHERRY line.
      final woven = await _weaver?.call('CHERRY');
      if (woven == null) await _storage.ensureCherryMixer();
    }
  }
}

/// Phosphor mixer — never the operator username.
class CherryMixerNotifier extends StateNotifier<String> {
  CherryMixerNotifier(this._storage) : super('') {
    _load();
  }

  final StorageService _storage;

  Future<void> _load() async {
    state = await _storage.ensureCherryMixer();
  }

  Future<String> ensure() async {
    final mixer = await _storage.ensureCherryMixer();
    state = mixer;
    return mixer;
  }
}

final cherryMixerProvider =
    StateNotifierProvider<CherryMixerNotifier, String>((ref) {
  return CherryMixerNotifier(ref.read(storageServiceProvider));
});

class CabinetPolicyNotifier extends StateNotifier<CabinetPolicy> {
  /// Boots woven so no engine ever runs the legacy path, even for a frame.
  /// The first ledgered weave still detects against [CabinetPolicy.legacy]
  /// so the record shows what the compiled default would have leaked.
  CabinetPolicyNotifier() : super(AutoPatcher.weave());

  void weave() => state = AutoPatcher.weave();

  void set(CabinetPolicy policy) => state = policy;
}

final cabinetPolicyProvider =
    StateNotifierProvider<CabinetPolicyNotifier, CabinetPolicy>((ref) {
  return CabinetPolicyNotifier();
});

class LeakSurface {
  const LeakSurface({
    this.sessionIsV2 = false,
    this.cabinetRecordExists = false,
    this.ledgerIntact = true,
    this.ledgerEntries = 0,
    this.redlightSealed = false,
    this.hybridPqLive = false,
    this.stegoVetBound = false,
    this.roundTableArmed = false,
    this.glassesPaired = false,
  });

  final bool sessionIsV2;
  final bool cabinetRecordExists;
  final bool ledgerIntact;
  final int ledgerEntries;
  final bool redlightSealed;
  final bool hybridPqLive;
  final bool stegoVetBound;
  final bool roundTableArmed;
  final bool glassesPaired;
}

class LeakSurfaceNotifier extends StateNotifier<LeakSurface> {
  LeakSurfaceNotifier(this._storage) : super(const LeakSurface()) {
    refresh();
  }

  final StorageService _storage;

  Future<void> refresh({String? username}) async {
    final ticket = await _storage.hasV2Ticket();
    var cabinet = false;
    var sealed = false;
    var glasses = false;
    if (username != null) {
      cabinet = await _storage.getCabinet(username) != null;
      sealed = await _storage.getRedlightVault(username) != null;
      glasses = await _storage.getGlassesSession(username) != null;
    }
    final ledger = await _storage.getPatchLedger();
    state = LeakSurface(
      sessionIsV2: ticket,
      cabinetRecordExists: cabinet,
      ledgerIntact: ledger.intact,
      ledgerEntries: ledger.entries.length,
      redlightSealed: sealed,
      hybridPqLive: await _storage.hasPqKem(),
      stegoVetBound: await _storage.isStegoVetBound(),
      roundTableArmed: await _storage.getLastPatternReport() != null,
      glassesPaired: glasses,
    );
  }
}

final leakSurfaceProvider =
    StateNotifierProvider<LeakSurfaceNotifier, LeakSurface>((ref) {
  return LeakSurfaceNotifier(ref.read(storageServiceProvider));
});

final leakReportProvider = Provider<LeakReport>((ref) {
  final surface = ref.watch(leakSurfaceProvider);
  return LeakDetector.scan(
    LeakSnapshot(
      policy: ref.watch(cabinetPolicyProvider),
      mixer: ref.watch(cherryMixerProvider),
      operatorUsername: ref.watch(authProvider).user?.username,
      sessionIsV2: surface.sessionIsV2,
      cabinetRecordExists: surface.cabinetRecordExists,
      masterJunk: MasterGlyphs.junkCount,
      derangeSecret: ref.watch(cherryMixerProvider),
      ledgerIntact: surface.ledgerIntact,
      ledgerEntries: surface.ledgerEntries,
      redlightSealed: surface.redlightSealed,
      hybridPqLive: surface.hybridPqLive,
      stegoVetBound: surface.stegoVetBound,
      roundTableArmed: surface.roundTableArmed,
      glassesPaired: surface.glassesPaired,
    ),
  );
});

/// The red-light gate.
///
/// Lamp filter and keypress derangement render only when all of these hold:
/// Darth Cherry armed, policy sealed, an authenticated operator, a verified
/// unexpired V2 ticket on this device whose operator matches, and a vault
/// that decrypts under this device key for that operator. Anything else is a
/// sealed panel with the reason printed on it.
final redlightAccessProvider = FutureProvider<RedlightAccess>((ref) async {
  final cherry = ref.watch(darthCherryProvider);
  final policy = ref.watch(cabinetPolicyProvider);
  final auth = ref.watch(authProvider);
  // Re-evaluate when the session box or vault changes.
  ref.watch(leakSurfaceProvider);
  ref.watch(autoPatcherProvider);

  if (!cherry) return const RedlightAccess.sealed(RedlightSeal.cherryDark);
  if (!policy.sealRedlight) {
    return const RedlightAccess.sealed(RedlightSeal.policyUnsealed);
  }
  final user = auth.user;
  if (user == null || !auth.isAuthenticated) {
    return const RedlightAccess.sealed(RedlightSeal.noOperator);
  }
  final storage = ref.read(storageServiceProvider);
  final ticket = await storage.currentTicket();
  if (ticket == null) return const RedlightAccess.sealed(RedlightSeal.noTicket);
  if (ticket.username != user.username.toUpperCase()) {
    return const RedlightAccess.sealed(RedlightSeal.operatorMismatch);
  }
  final profile = await storage.getRedlightVault(user.username);
  if (profile == null) {
    return const RedlightAccess.sealed(RedlightSeal.vaultLocked);
  }
  if (policy.glassesHud) {
    final glasses = await storage.getGlassesSession(user.username);
    if (glasses == null) {
      return const RedlightAccess.sealed(RedlightSeal.noGlasses);
    }
    final viewer = ref.watch(glassesViewerProvider);
    if (viewer != GlassesViewer.hud) {
      return const RedlightAccess.sealed(RedlightSeal.noGlasses);
    }
  }
  return RedlightAccess.open(
    profile: profile,
    derangeSecret: profile.derangeSecret(storage.deviceMac),
  );
});

final glassesViewerProvider = StateProvider<GlassesViewer>((ref) {
  return GlassesViewer.hud;
});

/// Storage-backed side effects for the patcher.
class _StoragePatchHooks extends PatchHooks {
  const _StoragePatchHooks(this._storage, this._username);

  final StorageService _storage;
  final String? _username;

  @override
  Future<bool> ensureTicket() async {
    if (await _storage.hasV2Ticket()) return true;
    final user = _username ?? await _storage.getSessionUser();
    if (user == null || user.isEmpty) return false;
    await _storage.setV2Session(user);
    return _storage.hasV2Ticket();
  }

  @override
  Future<String> ensureMixer() => _storage.ensureCherryMixer();

  @override
  Future<bool> ensureRedlightVault() async {
    final user = _username ?? await _storage.getSessionUser();
    if (user == null || user.isEmpty) return false;
    await _storage.ensureRedlightVault(user);
    return await _storage.getRedlightVault(user) != null;
  }

  @override
  Future<bool> ensurePqKem() async {
    await _storage.ensurePqKem();
    return _storage.hasPqKem();
  }

  @override
  Future<bool> ensureStegoVet() async {
    await _storage.bindStegoVet();
    return _storage.isStegoVetBound();
  }

  @override
  Future<bool> ensureRoundTable() async {
    await _storage.armRoundTable();
    return await _storage.getLastPatternReport() != null;
  }

  @override
  Future<bool> ensureGlassesLink() async {
    final user = _username ?? await _storage.getSessionUser();
    if (user == null || user.isEmpty) return false;
    await _storage.ensureGlassesLink(user);
    return await _storage.getGlassesSession(user) != null;
  }
}

/// Owns the patch ledger and drives every weave in the app.
///
/// One entry point — [weave] — so LOGIN, RESTORE, CHERRY, SYNC and MANUAL
/// all run the same DETECT → APPLY → VERIFY → LEDGER pipeline and land in
/// the same MAC-chained record.
class AutoPatcherNotifier extends StateNotifier<PatchLedger> {
  AutoPatcherNotifier(this._ref, this._storage) : super(PatchLedger.empty) {
    _load();
  }

  final Ref _ref;
  final StorageService _storage;
  Future<PatchLedgerEntry?>? _inFlight;

  Future<void> _load() async {
    state = await _storage.getPatchLedger();
  }

  Future<PatchLedgerEntry?> weave(String trigger, {String? username}) {
    // Serialise: two triggers landing together (login + listener) must not
    // both read seq N and write N+1.
    final previous = _inFlight ?? Future.value(null);
    final next = previous.then((_) => _weaveNow(trigger, username: username));
    _inFlight = next;
    return next;
  }

  Future<PatchLedgerEntry?> _weaveNow(
    String trigger, {
    String? username,
  }) async {
    final ledger = await _storage.getPatchLedger();
    final user = username ?? _ref.read(authProvider).user?.username;
    final cabinet = user == null ? false : await _storage.getCabinet(user) != null;
    final sealed =
        user == null ? false : await _storage.getRedlightVault(user) != null;
    final glasses =
        user == null ? false : await _storage.getGlassesSession(user) != null;
    final mixer = await _storage.getCherryMixer() ?? '';
    final snapshot = LeakSnapshot(
      policy: ledger.isEmpty
          ? CabinetPolicy.legacy
          : _ref.read(cabinetPolicyProvider),
      mixer: mixer,
      operatorUsername: user,
      sessionIsV2: await _storage.hasV2Ticket(),
      cabinetRecordExists: cabinet,
      masterJunk: MasterGlyphs.junkCount,
      derangeSecret: mixer,
      ledgerIntact: ledger.intact,
      ledgerEntries: ledger.entries.length,
      redlightSealed: sealed,
      hybridPqLive: await _storage.hasPqKem(),
      stegoVetBound: await _storage.isStegoVetBound(),
      roundTableArmed: await _storage.getLastPatternReport() != null,
      glassesPaired: glasses,
    );

    final result = await AutoPatcher.run(
      snapshot: snapshot,
      trigger: ledger.isEmpty ? 'BASELINE·$trigger' : trigger,
      seq: ledger.nextSeq,
      hooks: _StoragePatchHooks(_storage, user),
    );

    if (!ledger.intact) {
      await _storage.logAudit(
        AutoPatcher.tamperAction,
        user ?? 'SYSTEM',
        'Ledger chain failed verification before $trigger',
      );
    }
    final chained = await _storage.appendPatchLedger(result.entry);

    _ref.read(cabinetPolicyProvider.notifier).set(result.policy);
    if (result.snapshot.mixer.isNotEmpty) {
      _ref.read(cherryMixerProvider.notifier).ensure();
    }
    await _ref.read(leakSurfaceProvider.notifier).refresh(username: user);
    await _storage.logAudit(
      AutoPatcher.auditAction,
      user ?? 'SYSTEM',
      '${chained.readout} ·${chained.appliedCount} WOVEN ·${chained.heldCount} HELD',
    );
    state = await _storage.getPatchLedger();
    return chained;
  }

  /// Developer reset. Leaves an audit line — wiping the ledger is itself an
  /// event worth seeing.
  Future<void> reset(String actor) async {
    await _storage.clearPatchLedger();
    await _storage.logAudit('LEDGER_RESET', actor);
    state = PatchLedger.empty;
    await _ref.read(leakSurfaceProvider.notifier).refresh(
          username: _ref.read(authProvider).user?.username,
        );
  }
}

final autoPatcherProvider =
    StateNotifierProvider<AutoPatcherNotifier, PatchLedger>((ref) {
  return AutoPatcherNotifier(ref, ref.read(storageServiceProvider));
});

final darthCherryProvider =
    StateNotifierProvider<DarthCherryNotifier, bool>((ref) {
  return DarthCherryNotifier(
    ref.read(storageServiceProvider),
    weaver: (trigger, {username}) =>
        ref.read(autoPatcherProvider.notifier).weave(trigger, username: username),
  );
});

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

/// Always the real pool. POOL / rotors / sync chrome use this.
final realCipherEngineProvider = Provider<CipherEngine>((ref) {
  return CipherEngine(
    seed: ref.watch(poolSeedProvider),
    stego: false,
  );
});

/// Payload engine. Cover sessions swap the seed here only.
final cipherEngineProvider = Provider<CipherEngine>((ref) {
  final seed = ref.watch(poolSeedProvider);
  final duress = ref.watch(duressProvider);
  final policy = ref.watch(cabinetPolicyProvider);
  return CipherEngine(
    seed: duress.effectiveSeed ?? seed,
    stego: policy.v1Stego,
  );
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
    this.handshake = V2HandshakeLog.empty,
  });

  final UserAccount? user;
  final bool isLoading;
  final String? error;
  final bool needsPin;
  final bool isRestoring;

  /// In-memory only. Never persist. Do not render this flag in the arcade.
  final bool coverArmed;

  final V2HandshakeLog handshake;

  bool get isAuthenticated => user != null && !needsPin;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage, {this._weaver}) : super(const AuthState()) {
    _restoreSession();
  }

  final StorageService _storage;
  final Weaver? _weaver;

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
    // A restored session skipped the handshake, so the weave runs here:
    // the ledger chain is verified and the policy re-asserted before any
    // cipher tab can render.
    await _weaver?.call('RESTORE', username: account.username);
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

  UserAccount? _pendingCommit;

  /// Runs the V2 handshake. With [deferCommit] the account is held back so
  /// the CRT can print the six lines before the router sees `user != null`
  /// and redirects; the caller then runs [commitLogin].
  Future<bool> login(
    String username,
    String password, {
    bool deferCommit = false,
  }) async {
    final lines = <V2HandshakeLine>[];
    void step(String code, String label, String status) {
      lines.add(V2HandshakeLine(code: code, label: label, status: status));
    }

    V2HandshakeLog log({required bool ok, required bool finished}) =>
        V2HandshakeLog(lines: List.unmodifiable(lines), ok: ok, finished: finished);

    if (_isLockedOut) {
      step('01', 'CHALLENGE', 'HOLD');
      state = AuthState(
        error: 'TOO MANY ATTEMPTS — TRY AGAIN LATER',
        handshake: log(ok: false, finished: true),
      );
      return false;
    }

    final nonce = V2SessionTicket.nonce();
    step('01', 'CHALLENGE', nonce.substring(0, 8).toUpperCase());
    state = AuthState(isLoading: true, handshake: log(ok: false, finished: false));

    final account = await _storage.getAccount(username.toUpperCase());
    // Same error for unknown user and bad password to avoid enumeration.
    if (account == null ||
        !EncryptionService.verifyPassword(password, account.passwordHash)) {
      _recordFailure();
      await _storage.logAudit('LOGIN_FAIL', username);
      step('02', 'VERIFY', 'DENIED');
      state = AuthState(
        error: 'ACCESS DENIED',
        handshake: log(ok: false, finished: true),
      );
      return false;
    }

    step('02', 'VERIFY', 'PBKDF2');
    _failedAttempts = 0;
    var updated = account.copyWith(lastLogin: DateTime.now());
    if (EncryptionService.isLegacyHash(account.passwordHash)) {
      updated = updated.copyWith(
        passwordHash: EncryptionService.hashPassword(password),
      );
    }
    await _storage.saveAccount(updated);
    await _storage.setSessionUser(updated.username);
    final ticketOk = await _storage.hasV2Ticket();
    step('03', 'TICKET', ticketOk ? 'ISSUED' : 'FAIL');

    // Steps 04 + 05 are the patcher pipeline: DETECT is the sweep, then
    // APPLY → VERIFY → LEDGER is the weave. The CRT shows real counts.
    final woven = await _weaver?.call('LOGIN', username: updated.username);
    if (woven == null) {
      await _storage.ensureCherryMixer();
      step('04', 'LEAK SWEEP', 'LIVE');
      step('05', 'AUTOPATCH', AutoPatcher.auditAction);
    } else {
      step('04', 'LEAK SWEEP', '${woven.openBefore} OPEN');
      step(
        '05',
        'AUTOPATCH',
        woven.openAfter == 0
            ? '${woven.appliedCount} WOVEN #${woven.seq}'
            : '${woven.openAfter} PENDING #${woven.seq}',
      );
    }
    await _storage.logAudit('LOGIN_OK', username, 'V2 ${V2LoginProtocol.name}');

    step('06', 'CABINET', updated.requiresPin ? 'PIN GATE' : 'READY');
    if (deferCommit) {
      _pendingCommit = updated;
      state = AuthState(
        isLoading: true,
        handshake: log(ok: true, finished: true),
      );
      return true;
    }
    state = AuthState(
      user: updated,
      needsPin: updated.requiresPin,
      handshake: log(ok: true, finished: true),
    );
    return true;
  }

  /// Second half of a deferred [login]: publish the account so the router
  /// moves on. No-op when nothing is pending.
  void commitLogin() {
    final user = _pendingCommit;
    if (user == null) return;
    _pendingCommit = null;
    state = AuthState(
      user: user,
      needsPin: user.requiresPin,
      handshake: state.handshake,
    );
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
    var persist = user;
    if (realOk) {
      persist = persist.copyWith(requiresPin: false);
      if (EncryptionService.isLegacyHash(user.pinHash)) {
        persist = persist.copyWith(pinHash: EncryptionService.hashPin(pin));
      }
    } else {
      // Cover: keep the Hive gate so a restart re-challenges. Do not persist
      // the cover session — that would be a new leak.
      persist = persist.copyWith(requiresPin: true);
    }
    await _storage.saveAccount(persist);
    state = AuthState(
      user: persist,
      coverArmed: coverOk && !realOk,
    );
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

  /// Reachable cover / real PIN path while already logged in (GEAR CAL).
  Future<void> requestOperatorCheckpoint() async {
    final user = state.user;
    if (user == null) return;
    final gated = user.copyWith(requiresPin: true);
    await _storage.saveAccount(gated);
    await _storage.logAudit('PIN_GATE', user.username, 'GEAR CAL');
    state = AuthState(
      user: gated,
      needsPin: true,
      coverArmed: state.coverArmed,
      handshake: state.handshake,
    );
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
      await _storage.saveAccount(account.copyWith(requiresPin: true));
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
  return AuthNotifier(
    ref.read(storageServiceProvider),
    weaver: (trigger, {username}) =>
        ref.read(autoPatcherProvider.notifier).weave(trigger, username: username),
  );
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
