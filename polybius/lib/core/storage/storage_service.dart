import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
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

  Future<void> init() async {
    await Hive.initFlutter();
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
  }

  String _encodeJson(Map<String, dynamic> json) =>
      json.entries.map((e) => '${e.key}=${e.value}').join('|');

  Map<String, dynamic> _decodeJson(String raw) {
    final map = <String, dynamic>{};
    for (final part in raw.split('|')) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        map[part.substring(0, idx)] = part.substring(idx + 1);
      }
    }
    return map;
  }

  Future<UserAccount?> getAccount(String username) async {
    final box = Hive.box(accountsBox);
    final raw = box.get(username);
    if (raw == null) return null;
    try {
      final decrypted = _encryption.decrypt(raw as String);
      return UserAccount.fromJson(_decodeJson(decrypted));
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
    if (raw == null) return null;
    return InviteCode.fromJson(Map<dynamic, dynamic>.from(raw as Map));
  }

  Future<List<InviteCode>> getAllInvites() async {
    final box = Hive.box(invitesBox);
    return box.values
        .map((v) => InviteCode.fromJson(Map<dynamic, dynamic>.from(v as Map)))
        .toList();
  }

  Future<GameSettings> getSettings() async {
    final box = Hive.box(settingsBox);
    final raw = box.get('game');
    if (raw == null) return const GameSettings();
    return GameSettings.fromJson(Map<dynamic, dynamic>.from(raw as Map));
  }

  Future<void> saveSettings(GameSettings settings) async {
    final box = Hive.box(settingsBox);
    await box.put('game', settings.toJson());
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
    final entries = box.values
        .map((v) =>
            AuditLogEntry.fromJson(Map<dynamic, dynamic>.from(v as Map)))
        .toList();
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
