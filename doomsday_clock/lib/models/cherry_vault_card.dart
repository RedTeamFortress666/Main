import '../data/polybius_operator_cards.dart';

/// Operator identity stored in a user's DARTH CHERRY vault (e.g. from QR scan).
class CherryVaultCard {
  const CherryVaultCard({
    required this.id,
    required this.username,
    required this.displayName,
    required this.inviteCode,
    required this.pin,
    required this.password,
    required this.backupPassword,
    required this.tier,
    required this.receivedAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String inviteCode;
  final String pin;
  final String password;
  final String backupPassword;
  final String tier;
  final DateTime receivedAt;

  PolybiusOperatorCard toOperatorCard() => PolybiusOperatorCard(
        username: username,
        displayName: displayName,
        inviteCode: inviteCode,
        pin: pin,
        password: password,
        backupPassword: backupPassword,
        tier: tier,
      );

  factory CherryVaultCard.fromOperator(
    PolybiusOperatorCard card, {
    required String id,
    DateTime? receivedAt,
  }) =>
      CherryVaultCard(
        id: id,
        username: card.username,
        displayName: card.displayName,
        inviteCode: card.inviteCode,
        pin: card.pin,
        password: card.password,
        backupPassword: card.backupPassword,
        tier: card.tier,
        receivedAt: receivedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'inviteCode': inviteCode,
        'pin': pin,
        'password': password,
        'backupPassword': backupPassword,
        'tier': tier,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory CherryVaultCard.fromJson(Map<String, dynamic> j) => CherryVaultCard(
        id: j['id'] as String,
        username: j['username'] as String,
        displayName: j['displayName'] as String,
        inviteCode: j['inviteCode'] as String,
        pin: j['pin'] as String,
        password: j['password'] as String,
        backupPassword: j['backupPassword'] as String,
        tier: j['tier'] as String,
        receivedAt: DateTime.parse(j['receivedAt'] as String),
      );

  factory CherryVaultCard.fromQrPayload(Map<String, dynamic> j) => CherryVaultCard(
        id: 'qr_${j['username']}_${DateTime.now().millisecondsSinceEpoch}',
        username: j['username'] as String,
        displayName: j['displayName'] as String,
        inviteCode: j['inviteCode'] as String? ?? '',
        pin: j['pin'] as String,
        password: j['password'] as String,
        backupPassword: j['backupPassword'] as String,
        tier: j['tier'] as String? ?? 'agent',
        receivedAt: DateTime.now(),
      );
}
