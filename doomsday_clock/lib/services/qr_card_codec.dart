import 'dart:convert';

import '../data/polybius_operator_cards.dart';
import '../models/operator_card.dart';

/// Encodes / decodes PØLYBĪUS operator identity cards carried as QR payloads.
///
/// Two wire formats:
/// - `POLYBIUS_CARD_V1:` public identity (username / tier / invite)
/// - `DOOMSDAY_CHERRY_V1:` full identity including sealed credentials
class QrCardCodec {
  QrCardCodec._();

  static const polybiusPrefix = 'POLYBIUS_CARD_V1:';
  static const cherryPrefix = 'DOOMSDAY_CHERRY_V1:';

  static String encodePolybiusCard({
    required String username,
    required String displayName,
    required String tier,
    required String inviteCode,
  }) {
    final json = jsonEncode({
      'v': 1,
      'app': 'polybius',
      'username': username,
      'displayName': displayName,
      'tier': tier,
      'inviteCode': inviteCode,
    });
    return '$polybiusPrefix${base64Url.encode(utf8.encode(json))}';
  }

  static String encodeCherryCard(OperatorCard card) {
    final json = jsonEncode({
      'v': 1,
      'app': 'doomsday_cherry',
      'username': card.username,
      'displayName': card.displayName,
      'inviteCode': card.inviteCode,
      'pin': card.pin,
      'password': card.password,
      'backupPassword': card.backupPassword,
      'tier': card.tier,
    });
    return '$cherryPrefix${base64Url.encode(utf8.encode(json))}';
  }

  static OperatorCard? decode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith(cherryPrefix)) {
      return _decodeMap(trimmed.substring(cherryPrefix.length));
    }
    if (trimmed.startsWith(polybiusPrefix)) {
      return _decodeMap(trimmed.substring(polybiusPrefix.length));
    }
    return _decodeMap(trimmed);
  }

  static OperatorCard? _decodeMap(String payload) {
    try {
      Map<String, dynamic> map;
      try {
        map = jsonDecode(utf8.decode(base64Url.decode(payload)))
            as Map<String, dynamic>;
      } catch (_) {
        map = jsonDecode(payload) as Map<String, dynamic>;
      }
      final username = (map['username'] as String?)?.trim() ?? '';
      if (username.isEmpty) return null;
      final scanned = OperatorCard(
        username: username,
        displayName: map['displayName'] as String? ?? username,
        inviteCode: map['inviteCode'] as String? ?? '',
        pin: map['pin'] as String? ?? '',
        password: map['password'] as String? ?? '',
        backupPassword: map['backupPassword'] as String? ?? '',
        tier: map['tier'] as String? ?? 'agent',
      );
      return PolybiusOperatorCards.hydrate(scanned);
    } catch (_) {
      return null;
    }
  }
}
