class OperatorCard {
  const OperatorCard({
    required this.username,
    required this.displayName,
    required this.inviteCode,
    required this.pin,
    required this.password,
    required this.backupPassword,
    required this.tier,
  });

  final String username;
  final String displayName;
  final String inviteCode;
  final String pin;
  final String password;
  final String backupPassword;
  final String tier;

  bool get hasSecrets =>
      pin.isNotEmpty || password.isNotEmpty || backupPassword.isNotEmpty;

  OperatorCard copyWith({
    String? username,
    String? displayName,
    String? inviteCode,
    String? pin,
    String? password,
    String? backupPassword,
    String? tier,
  }) =>
      OperatorCard(
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        inviteCode: inviteCode ?? this.inviteCode,
        pin: pin ?? this.pin,
        password: password ?? this.password,
        backupPassword: backupPassword ?? this.backupPassword,
        tier: tier ?? this.tier,
      );
}
