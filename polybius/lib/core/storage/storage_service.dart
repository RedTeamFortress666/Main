import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/features/duress/cabinet_identity.dart';

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
