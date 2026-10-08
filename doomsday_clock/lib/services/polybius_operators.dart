/// Bunker developer identities — SpamKat2 & Gam3.0n only.
class PolybiusOperator {
  const PolybiusOperator({
    required this.username,
    required this.displayName,
    required this.password,
    required this.backupPassword,
    required this.pin,
    required this.tier,
    this.inviteOrDevCode,
  });

  final String username;
  final String displayName;
  final String password;
  final String backupPassword;
  final String pin;
  final String tier;
  final String? inviteOrDevCode;
}

/// DOØMSDAY BUNKER v1 login roster — SpamKat2 & Gam3.0n.
const polybiusBunkerOperators = <PolybiusOperator>[
  PolybiusOperator(
    username: 'SPAMKAT2',
    displayName: 'SpamKat2',
    password: 'Ev1l-Schm33',
    backupPassword: 'LilB1tScary99',
    pin: '810739',
    tier: 'developer',
    inviteOrDevCode: 'W1-66-3R',
  ),
  PolybiusOperator(
    username: 'GAM3.0N',
    displayName: 'Gam3.0n',
    password: 'Dig1tal.Ra1n99',
    backupPassword: '01-p0lyb1u5-10',
    pin: '816639',
    tier: 'developer',
    inviteOrDevCode: 'B1-66-3R',
  ),
];

/// Legacy alias — bunker operators only.
const polybiusPrivilegedOperators = polybiusBunkerOperators;

PolybiusOperator? authenticatePolybiusAdmin({
  required String username,
  required String password,
  required String pin,
}) {
  final u = username.trim().toUpperCase();
  for (final op in polybiusBunkerOperators) {
    if (op.username.toUpperCase() != u && op.displayName.toUpperCase() != u) {
      continue;
    }
    final passOk =
        password == op.password || password == op.backupPassword;
    final pinOk = pin == op.pin;
    if (passOk && pinOk) return op;
  }
  return null;
}

PolybiusOperator? authenticateBunkerOperator({
  required String username,
  required String password,
  required String pin,
}) =>
    authenticatePolybiusAdmin(
      username: username,
      password: password,
      pin: pin,
    );
