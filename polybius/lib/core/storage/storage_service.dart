import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
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
  }

  String _encodeJson(Map<String, dynamic> json) => jsonEncode(json);

  String _sealMap(Map<String, dynamic> json) =>
      _encryption.encrypt(_encodeJson(json));

  Map<String, dynamic>? _openMap(dynamic raw) {
    if (raw is! String) return null;
    try {
      final parsed = jsonDecode(_encryption.decrypt(raw));
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return null;
  }

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
    await box.put(invite.code, _sealMap(invite.toJson()));
  }

  Future<InviteCode?> getInvite(String code) async {
    final box = Hive.box(invitesBox);
    final map = _openMap(box.get(code.toUpperCase()));
    if (map == null) return null;
    try {
      return InviteCode.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<List<InviteCode>> getAllInvites() async {
    final box = Hive.box(invitesBox);
    final invites = <InviteCode>[];
    for (final v in box.values) {
      final map = _openMap(v);
      if (map == null) continue;
      try {
        invites.add(InviteCode.fromJson(map));
      } catch (_) {}
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
    final map = _openMap(box.get('unlockState'));
    if (map == null) return null;
    final raw = map['state'];
    if (raw is! String) return null;
    try {
      return UnlockState.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUnlockState(UnlockState state) async {
    final box = Hive.box(settingsBox);
    await box.put('unlockState', _sealMap({'state': state.name}));
  }

  Future<void> clearUnlockState() async {
    final box = Hive.box(settingsBox);
    await box.delete('unlockState');
  }

  /// The invite code / game file number bound to this copy of the game.
  Future<String?> getGameFileNumber() async {
    return _openSealedString('gameFileNumber');
  }

  Future<void> setGameFileNumber(String code) async {
    await _putSealedString('gameFileNumber', code);
  }

  /// Optional trusted public key override (per-SD/USB keyset binding). When set,
  /// signed tokens/updates are verified against this instead of the embedded key.
  Future<String?> getTrustedPublicKey() async {
    return _openSealedString('trustedPublicKey');
  }

  Future<void> setTrustedPublicKey(String keyB64) async {
    await _putSealedString('trustedPublicKey', keyB64);
  }

  /// The signature-verified access token bound to this copy (base64url wire form).
  Future<String?> getActiveToken() async {
    return _openSealedString('activeToken');
  }

  Future<void> setActiveToken(String token) async {
    await _putSealedString('activeToken', token);
  }

  Future<String?> _openSealedString(String key) async {
    final raw = Hive.box(settingsBox).get(key);
    final map = _openMap(raw);
    if (map != null) {
      final v = map['v'];
      return v is String && v.isNotEmpty ? v : null;
    }
    return null;
  }

  Future<void> _putSealedString(String key, String value) async {
    await Hive.box(settingsBox).put(key, _sealMap({'v': value}));
  }

  /// Peer Kyber public key used as the encrypt target (never a pool seed).
  Future<Uint8List?> getPeerPublicKey() async {
    final map = _openMap(Hive.box(settingsBox).get('peerPublicKey'));
    final b64 = map?['pk'];
    if (b64 is! String || b64.isEmpty) return null;
    try {
      return Uint8List.fromList(base64Decode(b64));
    } catch (_) {
      return null;
    }
  }

  Future<void> setPeerPublicKey(Uint8List publicKey) async {
    await Hive.box(settingsBox).put(
      'peerPublicKey',
      _sealMap({'pk': base64Encode(publicKey)}),
    );
  }

  Future<String?> getPoolSeed() async => null;

  Future<void> setPoolSeed(String seed) async {}

  Future<void> logAudit(String action, String actor, [String? details]) async {
    final box = Hive.box(auditBox);
    final entry = AuditLogEntry(
      timestamp: DateTime.now(),
      action: action,
      actor: actor,
      details: details,
    );
    await box.add(_sealMap(entry.toJson()));
  }

  Future<List<AuditLogEntry>> getAuditLogs({int limit = 100}) async {
    final box = Hive.box(auditBox);
    final entries = <AuditLogEntry>[];
    for (final v in box.values) {
      final map = _openMap(v) ??
          (v is Map ? Map<String, dynamic>.from(v) : null);
      if (map == null) continue;
      try {
        entries.add(AuditLogEntry.fromJson(map));
      } catch (_) {}
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }

  Future<void> setSessionUser(String? username) async {
    final box = Hive.box(sessionBox);
    if (username == null) {
      await box.delete('user');
    } else {
      await box.put('user', _encryption.encrypt(username));
    }
  }

  Future<String?> getSessionUser() async {
    final box = Hive.box(sessionBox);
    final raw = box.get('user');
    if (raw is! String) return null;
    try {
      return _encryption.decrypt(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<void> clearSession() => setSessionUser(null);
}
