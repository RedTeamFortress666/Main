import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/operator_roster.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/models/models.dart';

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
    final box = Hive.box(accountsBox);
    if (!box.containsKey(AppConstants.developerUsername)) {
      final dev = UserAccount(
        username: AppConstants.developerUsername,
        passwordHash: EncryptionService.hashPassword('developer'),
        pinHash: EncryptionService.hashPin(AppConstants.developerDefaultPin),
        tier: UserTier.developer,
        createdAt: DateTime.now(),
      );
      await box.put(
        dev.username,
        _encryption.encrypt(_encodeJson(dev.toJson())),
      );
      await logAudit('BOOTSTRAP', AppConstants.developerUsername,
          'DEVELOPER account created on first install');
    }
    // Operator admin account: RedTeam01, dev code B1-66-3R, dev number 816639.
    if (!box.containsKey(AppConstants.adminUsername)) {
      final admin = UserAccount(
        username: AppConstants.adminUsername,
        displayName: AppConstants.adminDisplayName,
        passwordHash: EncryptionService.hashPassword(AppConstants.adminDevNumber),
        pinHash: EncryptionService.hashPin(AppConstants.adminDevNumber),
        tier: UserTier.admin,
        createdAt: DateTime.now(),
      );
      await box.put(
        admin.username,
        _encryption.encrypt(_encodeJson(admin.toJson())),
      );
      await logAudit('BOOTSTRAP', AppConstants.adminUsername,
          'RedTeam01 admin account created on first install');
    }
    await _bootstrapOperator(
      username: AppConstants.opSpamKatUsername,
      displayName: AppConstants.opSpamKatDisplayName,
      password: AppConstants.opSpamKatPassword,
      backupPassword: AppConstants.opSpamKatBackupPassword,
      pin: AppConstants.opSpamKatPin,
      tier: UserTier.developer,
      note: 'SpamKat2 developer (W1-66-3R)',
    );
    await _bootstrapOperator(
      username: AppConstants.opGameOnUsername,
      displayName: AppConstants.opGameOnDisplayName,
      password: AppConstants.opGameOnPassword,
      backupPassword: AppConstants.opGameOnBackupPassword,
      pin: AppConstants.opGameOnPin,
      tier: UserTier.developer,
      note: 'Gam3.0n developer (B1-66-3R)',
    );
    await _bootstrapOperator(
      username: AppConstants.opKasperUsername,
      displayName: AppConstants.opKasperDisplayName,
      password: AppConstants.opKasperPassword,
      backupPassword: AppConstants.opKasperBackupPassword,
      pin: AppConstants.opKasperPin,
      tier: UserTier.admin,
      note: 'KASP3R admin (TR1-66-3R)',
    );
    await _bootstrapOperator(
      username: AppConstants.opTemptressUsername,
      displayName: AppConstants.opTemptressDisplayName,
      password: AppConstants.opTemptressPassword,
      backupPassword: AppConstants.opTemptressBackupPassword,
      pin: AppConstants.opTemptressPin,
      tier: UserTier.agent,
      note: 'T3mptress standard user (80-081-35)',
    );
    if (await getInvite(AppConstants.opTemptressInviteCode) == null) {
      await saveInvite(InviteCode(
        code: AppConstants.opTemptressInviteCode.toUpperCase(),
        tier: InviteTier.standard,
        createdBy: 'SYSTEM',
        createdAt: DateTime.now(),
      ));
    }
    // Admin/user pool roster (10 procedurally assigned operators).
    for (final op in OperatorRoster.pool) {
      await _bootstrapOperator(
        username: op.username,
        displayName: op.displayName,
        password: op.password,
        backupPassword: op.backupPassword,
        pin: op.pin,
        tier: op.tier,
        note: '${op.displayName} ${op.tier.name} (${op.inviteCode})',
      );
      // Persist the invite so the invites box / audit trail also lists it.
      if (await getInvite(op.inviteCode) == null) {
        await saveInvite(InviteCode(
          code: op.inviteCode.toUpperCase(),
          tier: op.tier == UserTier.admin
              ? InviteTier.admin
              : InviteTier.standard,
          createdBy: 'SYSTEM',
          createdAt: DateTime.now(),
        ));
      }
    }
    // Embed the developer's game file number on first install.
    if (await getGameFileNumber() == null) {
      await setGameFileNumber(AppConstants.devGameFileNumber);
    }
  }

  Future<void> _bootstrapOperator({
    required String username,
    required String displayName,
    required String password,
    required String backupPassword,
    required String pin,
    required UserTier tier,
    required String note,
  }) async {
    final box = Hive.box(accountsBox);
    if (box.containsKey(username)) return;
    final account = UserAccount(
      username: username,
      displayName: displayName,
      passwordHash: EncryptionService.hashPassword(password),
      backupPasswordHash: EncryptionService.hashPassword(backupPassword),
      pinHash: EncryptionService.hashPin(pin),
      tier: tier,
      requiresPin: true,
      createdAt: DateTime.now(),
    );
    await box.put(
      account.username,
      _encryption.encrypt(_encodeJson(account.toJson())),
    );
    await logAudit('BOOTSTRAP', username, note);
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

  /// Rotor complexity (2–6 emojis per character).
  Future<int?> getCipherComplexity() async {
    final raw = Hive.box(settingsBox).get('cipherComplexity');
    return raw is int ? raw : null;
  }

  Future<void> setCipherComplexity(int value) async {
    await Hive.box(settingsBox).put('cipherComplexity', value);
  }

  /// Reticulum bridge WebSocket URL. Defaults to the local desktop companion;
  /// on iOS/Android point this at a bridge reachable on the LAN.
  String getReticulumUrl() {
    final raw = Hive.box(settingsBox).get('reticulumUrl');
    return raw is String && raw.isNotEmpty ? raw : 'ws://127.0.0.1:8765';
  }

  Future<void> setReticulumUrl(String url) async {
    await Hive.box(settingsBox).put('reticulumUrl', url);
  }

  /// Pool rotation window in hours (VALKYRIE sets this to 2).
  Future<int> getPoolWindowHours() async {
    final raw = Hive.box(settingsBox).get('poolWindowHours');
    return raw is int ? raw : 6;
  }

  Future<void> setPoolWindowHours(int hours) async {
    await Hive.box(settingsBox).put('poolWindowHours', hours);
  }

  Future<void> deleteAccount(String username) async {
    await Hive.box(accountsBox).delete(username.toUpperCase());
  }

  /// VALKYRIE: wipe transient network state (invites, audit, sessions) and all
  /// non-developer accounts, so the network can be re-established from scratch.
  Future<void> wipeNetworkState() async {
    await Hive.box(invitesBox).clear();
    await Hive.box(auditBox).clear();
    await clearSession();
    final accounts = await getAllAccounts();
    for (final a in accounts) {
      if (a.tier != UserTier.developer) {
        await deleteAccount(a.username);
      }
    }
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

  Future<void> setSessionUser(String? username) async {
    final box = Hive.box(sessionBox);
    if (username == null) {
      await box.delete('user');
    } else {
      await box.put('user', username);
    }
  }

  Future<String?> getSessionUser() async {
    final box = Hive.box(sessionBox);
    return box.get('user') as String?;
  }

  Future<void> clearSession() => setSessionUser(null);
}
