import 'operator_card.dart';

class VaultCard {
  const VaultCard({
    required this.id,
    required this.card,
    required this.receivedAt,
  });

  final String id;
  final OperatorCard card;
  final DateTime receivedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': card.username,
        'displayName': card.displayName,
        'inviteCode': card.inviteCode,
        'pin': card.pin,
        'password': card.password,
        'backupPassword': card.backupPassword,
        'tier': card.tier,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory VaultCard.fromJson(Map<String, dynamic> json) => VaultCard(
        id: json['id'] as String,
        card: OperatorCard(
          username: json['username'] as String,
          displayName: json['displayName'] as String? ?? '',
          inviteCode: json['inviteCode'] as String? ?? '',
          pin: json['pin'] as String? ?? '',
          password: json['password'] as String? ?? '',
          backupPassword: json['backupPassword'] as String? ?? '',
          tier: json['tier'] as String? ?? 'agent',
        ),
        receivedAt: DateTime.parse(json['receivedAt'] as String),
      );

  factory VaultCard.fromCard(OperatorCard card) => VaultCard(
        id: 'card_${card.username}_${DateTime.now().millisecondsSinceEpoch}',
        card: card,
        receivedAt: DateTime.now(),
      );
}
