/// Privileged developer / admin identities accepted for vault login.
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

/// Only privileged admins + developers may open the vault.
/// DEVELOPER / developer is stricken for V1 Stable.
const polybiusPrivilegedOperators = <PolybiusOperator>[
  PolybiusOperator(
    username: 'REDTEAM01',
    displayName: 'RedTeam01',
    password: '816639',
    backupPassword: '816639',
    pin: '816639',
    tier: 'admin',
    inviteOrDevCode: 'B1-66-3R',
  ),
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
  PolybiusOperator(
    username: 'KASP3R',
    displayName: 'KASP3R',
    password: 'BurnHideFr13d',
    backupPassword: 'P1ckl3M0rty69',
    pin: '791639',
    tier: 'admin',
    inviteOrDevCode: 'TR1-66-3R',
  ),
  PolybiusOperator(
    username: 'CROWNOFCORNS',
    displayName: 'CrownOfCorns',
    password: '20YokoMicrowave14',
    backupPassword: 'C0rnS1lo14',
    pin: '539667',
    tier: 'admin',
    inviteOrDevCode: 'C0-9N-3E',
  ),
  PolybiusOperator(
    username: 'P!K.ZUP',
    displayName: 'P!k.ZuP',
    password: 'DocCh1ck3n',
    backupPassword: 'TakeAOrdaPr33z',
    pin: '839093',
    tier: 'admin',
    inviteOrDevCode: 'D4-N6-3R',
  ),
  PolybiusOperator(
    username: 'NITEQUEEN',
    displayName: 'NiteQueen',
    password: 'NiteOwl42',
    backupPassword: 'NightOwl7',
    pin: '314159',
    tier: 'admin',
    inviteOrDevCode: 'NQ1-66-3R',
  ),
  PolybiusOperator(
    username: 'ARTEM3S',
    displayName: 'Art3mas',
    password: 'BowArrow7',
    backupPassword: 'Huntress9',
    pin: '271828',
    tier: 'admin',
    inviteOrDevCode: 'AR2-66-3R',
  ),
];

PolybiusOperator? authenticatePolybiusAdmin({
  required String username,
  required String password,
  required String pin,
}) {
  final u = username.trim().toUpperCase();
  for (final op in polybiusPrivilegedOperators) {
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
