import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/features/auth/v2_login_protocol.dart';
import 'package:polybius/features/duress/cabinet_identity.dart';
import 'package:polybius/features/redlight/auto_patcher.dart';
import 'package:polybius/features/redlight/patch_ledger.dart';
import 'package:polybius/features/redlight/redlight_vault.dart';

class StorageService {
  StorageService(this._encryption);

  final EncryptionService _encryption;

  static const accountsBox = 'accounts';
  static const invitesBox = 'invites';
  static const auditBox = 'audit';
  static const settingsBox = 'settings';
  static const sessionBox = 'session';

  Future<void> init({String? hivePath}) async {
    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }
    await Hive.openBox(accountsBox);
    await Hive.openBox(invitesBox);
    await Hive.openBox(auditBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(sessionBox);
    await _bootstrapDeveloper();
  }

  Future<void> _bootstrapDeveloper() async {
    final existing = await getAccount(AppConstants.developerUsername);
    if (existing == null) {
      final dev = UserAccount(
        username: AppConstants.developerUsername,
        passwordHash: EncryptionService.hashPassword('developer'),
        pinHash: EncryptionService.hashPin(AppConstants.developerDefaultPin),
        tier: UserTier.developer,
        createdAt: DateTime.now(),
      );
      await saveAccount(dev);
      await logAudit('BOOTSTRAP', AppConstants.developerUsername,
          'DEVELOPER account created on first install');
    }
    // Embed the developer's game file number on first install.
    if (await getGameFileNumber() == null) {
      await setGameFileNumber(AppConstants.devGameFileNumber);
    }
  }

  String _encodeJson(Map<String, dynamic> json) => jsonEncode(json);

  Map<String, dynamic> _decodeLegacyPipeJson(String raw) {
    final map = <String, dynamic>{};
    for (final part in raw.split('|')) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        map[part.substring(0, idx)] = part.substring(idx + 1);
      }
    }
    return map;
  }

  UserAccount? _parseAccountPayload(String decrypted) {
    try {
      final parsed = jsonDecode(decrypted);
      if (parsed is Map) {
        return UserAccount.fromJson(Map<String, dynamic>.from(parsed));
      }
    } catch (_) {
      // Fall through to legacy encoding.
    }
    try {
      return UserAccount.fromJson(_decodeLegacyPipeJson(decrypted));
    } catch (_) {
      return null;
    }
  }

  Future<UserAccount?> getAccount(String username) async {
    final box = Hive.box(accountsBox);
    final raw = box.get(username);
    if (raw == null) return null;
    try {
      final decrypted = _encryption.decrypt(raw as String);
      final account = _parseAccountPayload(decrypted);
      if (account != null && !decrypted.trimLeft().startsWith('{')) {
        await saveAccount(account);
      }
      return account;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAccount(UserAccount account) async {
    final box = Hive.box(accountsBox);
    await box.put(
      account.username,
      _encryption.encrypt(_encodeJson(account.toJson())),
    );
  }

  Future<List<UserAccount>> getAllAccounts() async {
    final box = Hive.box(accountsBox);
    final accounts = <UserAccount>[];
    for (final key in box.keys) {
      final account = await getAccount(key as String);
      if (account != null) accounts.add(account);
    }
    return accounts;
  }

  Future<void> saveInvite(InviteCode invite) async {
    final box = Hive.box(invitesBox);
    await box.put(invite.code, invite.toJson());
  }

  Future<InviteCode?> getInvite(String code) async {
    final box = Hive.box(invitesBox);
    final raw = box.get(code.toUpperCase());
    if (raw == null || raw is! Map) return null;
    try {
      return InviteCode.fromJson(Map<dynamic, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  Future<List<InviteCode>> getAllInvites() async {
    final box = Hive.box(invitesBox);
    final invites = <InviteCode>[];
    for (final v in box.values) {
      if (v is! Map) continue;
      try {
        invites.add(InviteCode.fromJson(Map<dynamic, dynamic>.from(v)));
      } catch (_) {
        // Skip a single corrupt record instead of failing the whole load.
      }
    }
    return invites;
  }

  Future<GameSettings> getSettings() async {
    final box = Hive.box(settingsBox);
    final raw = box.get('game');
    if (raw is! Map) return const GameSettings();
    try {
      return GameSettings.fromJson(Map<dynamic, dynamic>.from(raw));
    } catch (_) {
      return const GameSettings();
    }
  }

  Future<void> saveSettings(GameSettings settings) async {
    final box = Hive.box(settingsBox);
    await box.put('game', settings.toJson());
  }

  Future<UnlockState?> getUnlockState() async {
    final box = Hive.box(settingsBox);
    final raw = box.get('unlockState');
    if (raw is! String) return null;
    try {
      return UnlockState.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUnlockState(UnlockState state) async {
    final box = Hive.box(settingsBox);
    await box.put('unlockState', state.name);
  }

  Future<void> clearUnlockState() async {
    final box = Hive.box(settingsBox);
    await box.delete('unlockState');
  }

  /// The invite code / game file number bound to this copy of the game.
  Future<String?> getGameFileNumber() async {
    final raw = Hive.box(settingsBox).get('gameFileNumber');
    return raw is String ? raw : null;
  }

  Future<void> setGameFileNumber(String code) async {
    await Hive.box(settingsBox).put('gameFileNumber', code);
  }

  /// Optional trusted public key override (per-SD/USB keyset binding). When set,
  /// signed tokens/updates are verified against this instead of the embedded key.
  Future<String?> getTrustedPublicKey() async {
    final raw = Hive.box(settingsBox).get('trustedPublicKey');
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  Future<void> setTrustedPublicKey(String keyB64) async {
    await Hive.box(settingsBox).put('trustedPublicKey', keyB64);
  }

  /// The signature-verified access token bound to this copy (base64url wire form).
  Future<String?> getActiveToken() async {
    final raw = Hive.box(settingsBox).get('activeToken');
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  Future<void> setActiveToken(String token) async {
    await Hive.box(settingsBox).put('activeToken', token);
  }

  /// The active cipher pool seed (randomised or synced from another user).
  Future<String?> getPoolSeed() async {
    final raw = Hive.box(settingsBox).get('poolSeed');
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  Future<void> setPoolSeed(String seed) async {
    await Hive.box(settingsBox).put('poolSeed', seed);
  }

  Future<CabinetIdentity?> getCabinet(String username) async {
    final raw = Hive.box(settingsBox).get('cabinet::$username');
    if (raw is! String || raw.isEmpty) return null;
    try {
      final map = jsonDecode(_encryption.decrypt(raw));
      if (map is Map) {
        return CabinetIdentity.fromJson(Map<dynamic, dynamic>.from(map));
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCabinet(String username, CabinetIdentity cabinet) async {
    await Hive.box(settingsBox).put(
      'cabinet::$username',
      _encryption.encrypt(jsonEncode(cabinet.toJson())),
    );
  }

  Future<String> getOperatorInitials() async {
    final raw = Hive.box(settingsBox).get('operatorInitials');
    return raw is String && raw.isNotEmpty ? raw : 'YOU';
  }

  Future<bool> getDarthCherry() async {
    final raw = Hive.box(settingsBox).get('darthCherry');
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  Future<void> setDarthCherry(bool enabled) async {
    await Hive.box(settingsBox).put('darthCherry', enabled);
  }

  /// Random mixer for the phosphor keyboard. Never the operator username.
  Future<String?> getCherryMixer() async {
    final raw = Hive.box(settingsBox).get('cherryMixer');
    if (raw is! String || raw.isEmpty) return null;
    try {
      return _encryption.decrypt(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> setCherryMixer(String mixer) async {
    await Hive.box(settingsBox).put(
      'cherryMixer',
      _encryption.encrypt(mixer),
    );
  }

  Future<String> ensureCherryMixer() async {
    final existing = await getCherryMixer();
    if (existing != null && existing.isNotEmpty && existing.length >= 8) {
      return existing;
    }
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final mixer = base64Url.encode(bytes);
    await setCherryMixer(mixer);
    return mixer;
  }

  // ---------------------------------------------------------------------
  // Red-light vault — filter + keypress obfuscation, sealed per operator
  // ---------------------------------------------------------------------

  static const _redlightKey = 'redlightVault';

  /// Opens the vault for [owner]. Null when absent, undecryptable under this
  /// device key, unparsable, or minted for a different operator.
  Future<RedlightProfile?> getRedlightVault(String owner) async {
    final raw = Hive.box(settingsBox).get(_redlightKey);
    if (raw is! String || raw.isEmpty) return null;
    String plain;
    try {
      plain = _encryption.decrypt(raw);
    } catch (_) {
      return null;
    }
    final profile = RedlightProfile.tryParse(plain);
    if (profile == null) return null;
    if (profile.owner != owner.trim().toUpperCase()) return null;
    return profile;
  }

  Future<bool> hasRedlightVault() async {
    final raw = Hive.box(settingsBox).get(_redlightKey);
    return raw is String && raw.startsWith('v2:');
  }

  /// Mints the vault for [owner] if it is missing or belongs to someone else.
  /// Reuses an existing cherry mixer so the phosphor map does not jump on
  /// the first sealed run. Returns the open profile.
  Future<RedlightProfile> ensureRedlightVault(String owner) async {
    final existing = await getRedlightVault(owner);
    if (existing != null) return existing;
    final mixer = await ensureCherryMixer();
    final profile = RedlightProfile.mint(
      owner: owner,
      mixer: mixer.length >= 16 ? mixer : null,
    );
    await Hive.box(settingsBox).put(
      _redlightKey,
      _encryption.encrypt(jsonEncode(profile.toJson())),
    );
    return profile;
  }

  Future<void> clearRedlightVault() async {
    await Hive.box(settingsBox).delete(_redlightKey);
  }

  /// Verified, unexpired ticket currently in the session box, or null.
  Future<V2SessionTicket?> currentTicket() async {
    final raw = Hive.box(sessionBox).get('ticket');
    if (raw is! String || raw.isEmpty) return null;
    final ticket = V2SessionTicket.parse(raw);
    if (ticket == null) return null;
    if (!ticket.verify(_encryption.mac) || ticket.isExpired()) return null;
    return ticket;
  }

  /// Device-key HMAC, exposed for derivations that must not be recomputable
  /// off-device (red-light derangement secret).
  List<int> deviceMac(List<int> data) => _encryption.mac(data);

  Future<void> setOperatorInitials(String initials) async {
    await Hive.box(settingsBox).put(
      'operatorInitials',
      initials.toUpperCase().padRight(3).substring(0, 3),
    );
  }

  Future<void> logAudit(String action, String actor, [String? details]) async {
    final box = Hive.box(auditBox);
    final entry = AuditLogEntry(
      timestamp: DateTime.now(),
      action: action,
      actor: actor,
      details: details,
    );
    await box.add(entry.toJson());
  }

  Future<List<AuditLogEntry>> getAuditLogs({int limit = 100}) async {
    final box = Hive.box(auditBox);
    final entries = <AuditLogEntry>[];
    for (final v in box.values) {
      if (v is! Map) continue;
      try {
        entries.add(AuditLogEntry.fromJson(Map<dynamic, dynamic>.from(v)));
      } catch (_) {
        // Skip a single corrupt record instead of failing the whole load.
      }
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }

  Future<void> setV2Session(String username) async {
    final ticket = V2SessionTicket.issue(
      username: username,
      mac: _encryption.mac,
    );
    final box = Hive.box(sessionBox);
    await box.put('ticket', ticket.wire);
    await box.put('user', ticket.username);
  }

  Future<bool> hasV2Ticket() async {
    final raw = Hive.box(sessionBox).get('ticket');
    if (raw is! String || raw.isEmpty) return false;
    final ticket = V2SessionTicket.parse(raw);
    return ticket != null &&
        ticket.verify(_encryption.mac) &&
        !ticket.isExpired();
  }

  // ---------------------------------------------------------------------
  // Patch ledger — MAC-chained weave records
  // ---------------------------------------------------------------------

  static const _ledgerKey = 'patchLedger';

  String _ledgerMac(PatchLedgerEntry entry) {
    return base64Url.encode(_encryption.mac(utf8.encode(entry.canonical)));
  }

  /// Loads the chain and verifies every link. Never throws on bad data —
  /// a corrupt record is reported as a broken chain, which is the point.
  Future<PatchLedger> getPatchLedger() async {
    final raw = Hive.box(settingsBox).get(_ledgerKey);
    if (raw is! List) return PatchLedger.empty;
    final entries = <PatchLedgerEntry>[];
    var intact = true;
    for (final v in raw) {
      if (v is! Map) {
        intact = false;
        continue;
      }
      try {
        entries.add(PatchLedgerEntry.fromJson(Map<dynamic, dynamic>.from(v)));
      } catch (_) {
        intact = false;
      }
    }
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (_ledgerMac(e) != e.mac) intact = false;
      if (i > 0 && e.prevMac != entries[i - 1].mac) intact = false;
      if (i > 0 && e.seq <= entries[i - 1].seq) intact = false;
    }
    return PatchLedger(entries: entries, intact: intact);
  }

  /// Chains [entry] onto the ledger and persists. Returns the chained entry.
  Future<PatchLedgerEntry> appendPatchLedger(
    PatchLedgerEntry entry, {
    int cap = AutoPatcher.ledgerCap,
  }) async {
    final ledger = await getPatchLedger();
    final prev = ledger.latest?.mac ?? '';
    final linked = entry.withChain(prevMac: prev, mac: '');
    final chained = linked.withChain(prevMac: prev, mac: _ledgerMac(linked));
    final all = [...ledger.entries, chained];
    final kept = all.length > cap ? all.sublist(all.length - cap) : all;
    await Hive.box(settingsBox).put(
      _ledgerKey,
      kept.map((e) => e.toJson()).toList(),
    );
    return chained;
  }

  Future<void> clearPatchLedger() async {
    await Hive.box(settingsBox).delete(_ledgerKey);
  }

  Future<void> setSessionUser(String? username) async {
    if (username == null) {
      await clearSession();
      return;
    }
    await setV2Session(username);
  }

  Future<String?> getSessionUser() async {
    final box = Hive.box(sessionBox);
    final raw = box.get('ticket');
    if (raw is String && raw.isNotEmpty) {
      final ticket = V2SessionTicket.parse(raw);
      if (ticket != null && ticket.verify(_encryption.mac)) {
        if (!ticket.isExpired()) return ticket.username;
        // Valid MAC, stale age: drop the whole session so the legacy
        // fallback below cannot resurrect it as a bare username.
        await logAudit('TICKET_EXPIRED', ticket.username);
        await clearSession();
        return null;
      }
      await box.delete('ticket');
    }
    final legacy = box.get('user');
    if (legacy is String && legacy.isNotEmpty) {
      await setV2Session(legacy);
      return legacy.trim().toUpperCase();
    }
    return null;
  }

  Future<void> clearSession() async {
    final box = Hive.box(sessionBox);
    await box.delete('user');
    await box.delete('ticket');
  }
}
