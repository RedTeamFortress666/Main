import 'dart:convert';

import '../data/polybius_operator_cards.dart';
import '../models/cherry_vault_card.dart';

/// Encodes / decodes sharable DARTH CHERRY operator cards as QR payloads.
class QrCardCodec {
  QrCardCodec._();

  static const prefix = 'DOOMSDAY_CHERRY_V1:';

  static String encode(PolybiusOperatorCard card) {
    final payload = <String, dynamic>{
      'v': 1,
      'app': 'doomsday_cherry',
      'username': card.username,
      'displayName': card.displayName,
      'inviteCode': card.inviteCode,
      'pin': card.pin,
      'password': card.password,
      'backupPassword': card.backupPassword,
      'tier': card.tier,
    };
    final json = jsonEncode(payload);
    return '$prefix${base64Url.encode(utf8.encode(json))}';
  }

  static CherryVaultCard? decode(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(prefix)) return null;
    try {
      final b64 = trimmed.substring(prefix.length);
      final json = utf8.decode(base64Url.decode(b64));
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['app'] != 'doomsday_cherry') return null;
      if (map['v'] != 1) return null;
      return CherryVaultCard.fromQrPayload(map);
    } catch (_) {
      return null;
    }
  }
}
