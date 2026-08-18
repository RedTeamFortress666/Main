import 'dart:convert';

/// Compact PØLYBĪUS operator identity card shared over QR.
///
/// Wire format: `POLYBIUS_CARD_V1:` + base64url(JSON).
/// The payload is public identity only (no password / PIN).
class PolybiusUserCard {
  const PolybiusUserCard({
    required this.username,
    required this.displayName,
    required this.tier,
    required this.inviteCode,
  });

  static const prefix = 'POLYBIUS_CARD_V1:';

  final String username;
  final String displayName;
  final String tier;
  final String inviteCode;

  String encode() {
    final json = jsonEncode({
      'v': 1,
      'app': 'polybius',
      'username': username,
      'displayName': displayName,
      'tier': tier,
      'inviteCode': inviteCode,
    });
    return '$prefix${base64Url.encode(utf8.encode(json))}';
  }

  static PolybiusUserCard? tryParse(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(prefix)) return null;
    try {
      final json = utf8.decode(base64Url.decode(trimmed.substring(prefix.length)));
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['app'] != 'polybius') return null;
      final username = (map['username'] as String?)?.trim() ?? '';
      if (username.isEmpty) return null;
      return PolybiusUserCard(
        username: username,
        displayName: map['displayName'] as String? ?? username,
        tier: map['tier'] as String? ?? 'agent',
        inviteCode: map['inviteCode'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
