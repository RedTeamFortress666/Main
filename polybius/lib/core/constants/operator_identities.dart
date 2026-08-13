/// Plaintext operator identity cards for V1 Stable.
///
/// Public face (no Darth Cherry): neon Illuminati eye + username + invite code.
/// Under Darth Cherry (`veilProvider.filterActive`): password / backup / PIN.
///
/// DEVELOPER / `developer` is intentionally absent — retired for V1 Stable.
library;

import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/operator_roster.dart';
import 'package:polybius/core/constants/operator_wave2.dart';

class OperatorIdentity {
  const OperatorIdentity({
    required this.username,
    required this.displayName,
    required this.inviteOrFileCode,
    required this.pin,
    required this.password,
    required this.backupPassword,
    required this.tier,
  });

  final String username;
  final String displayName;
  final String inviteOrFileCode;
  final String pin;
  final String password;
  final String backupPassword;
  final UserTier tier;
}

/// All bootstrapped operator accounts except the stricken DEVELOPER login.
class OperatorIdentities {
  static final List<OperatorIdentity> all = [
    OperatorIdentity(
      username: AppConstants.adminUsername,
      displayName: AppConstants.adminDisplayName,
      inviteOrFileCode: AppConstants.devGameFileNumber,
      pin: AppConstants.adminDevNumber,
      password: AppConstants.adminDevNumber,
      backupPassword: AppConstants.adminDevNumber,
      tier: UserTier.admin,
    ),
    OperatorIdentity(
      username: AppConstants.opSpamKatUsername,
      displayName: AppConstants.opSpamKatDisplayName,
      inviteOrFileCode: AppConstants.opSpamKatDevCode,
      pin: AppConstants.opSpamKatPin,
      password: AppConstants.opSpamKatPassword,
      backupPassword: AppConstants.opSpamKatBackupPassword,
      tier: UserTier.developer,
    ),
    OperatorIdentity(
      username: AppConstants.opGameOnUsername,
      displayName: AppConstants.opGameOnDisplayName,
      inviteOrFileCode: AppConstants.opGameOnDevCode,
      pin: AppConstants.opGameOnPin,
      password: AppConstants.opGameOnPassword,
      backupPassword: AppConstants.opGameOnBackupPassword,
      tier: UserTier.developer,
    ),
    OperatorIdentity(
      username: AppConstants.opKasperUsername,
      displayName: AppConstants.opKasperDisplayName,
      inviteOrFileCode: AppConstants.opKasperInviteCode,
      pin: AppConstants.opKasperPin,
      password: AppConstants.opKasperPassword,
      backupPassword: AppConstants.opKasperBackupPassword,
      tier: UserTier.admin,
    ),
    OperatorIdentity(
      username: AppConstants.opTemptressUsername,
      displayName: AppConstants.opTemptressDisplayName,
      inviteOrFileCode: AppConstants.opTemptressInviteCode,
      pin: AppConstants.opTemptressPin,
      password: AppConstants.opTemptressPassword,
      backupPassword: AppConstants.opTemptressBackupPassword,
      tier: UserTier.agent,
    ),
    OperatorIdentity(
      username: AppConstants.opCrownOfCornsUsername,
      displayName: AppConstants.opCrownOfCornsDisplayName,
      inviteOrFileCode: AppConstants.opCrownOfCornsInviteCode,
      pin: AppConstants.opCrownOfCornsPin,
      password: AppConstants.opCrownOfCornsPassword,
      backupPassword: AppConstants.opCrownOfCornsBackupPassword,
      tier: UserTier.admin,
    ),
    OperatorIdentity(
      username: AppConstants.opMizzPicklesUsername,
      displayName: AppConstants.opMizzPicklesDisplayName,
      inviteOrFileCode: AppConstants.opMizzPicklesInviteCode,
      pin: AppConstants.opMizzPicklesPin,
      password: AppConstants.opMizzPicklesPassword,
      backupPassword: AppConstants.opMizzPicklesBackupPassword,
      tier: UserTier.agent,
    ),
    OperatorIdentity(
      username: AppConstants.opPikZupUsername,
      displayName: AppConstants.opPikZupDisplayName,
      inviteOrFileCode: AppConstants.opPikZupInviteCode,
      pin: AppConstants.opPikZupPin,
      password: AppConstants.opPikZupPassword,
      backupPassword: AppConstants.opPikZupBackupPassword,
      tier: UserTier.admin,
    ),
    // BETA pool + wave-2 operators.
    ..._poolIdentities,
    ..._wave2Identities,
  ];

  static const List<OperatorIdentity> _poolIdentities = [
    OperatorIdentity(
      username: 'NITEQUEEN',
      displayName: 'NiteQueen',
      inviteOrFileCode: 'NQ1-66-3R',
      pin: '314159',
      password: 'NiteOwl42',
      backupPassword: 'NightOwl7',
      tier: UserTier.admin,
    ),
    OperatorIdentity(
      username: 'ARTEM3S',
      displayName: 'Art3mas',
      inviteOrFileCode: 'AR2-66-3R',
      pin: '271828',
      password: 'BowArrow7',
      backupPassword: 'Huntress9',
      tier: UserTier.admin,
    ),
    OperatorIdentity(
      username: 'CUP1D!',
      displayName: 'Cup1d!',
      inviteOrFileCode: 'CU3-66-3R',
      pin: '161803',
      password: 'LoveShot99',
      backupPassword: 'CupidsBow1',
      tier: UserTier.agent,
    ),
    OperatorIdentity(
      username: 'DYSLEX1C',
      displayName: 'Dyslex1c',
      inviteOrFileCode: 'DX4-66-3R',
      pin: '141421',
      password: 'SpellMix8',
      backupPassword: 'LexiFix99',
      tier: UserTier.agent,
    ),
    OperatorIdentity(
      username: 'WHYTWOK',
      displayName: 'WhyTwoK',
      inviteOrFileCode: 'Y2K-66-3R',
      pin: '173205',
      password: 'PartyY2K1',
      backupPassword: 'TwoKWave2',
      tier: UserTier.agent,
    ),
    OperatorIdentity(
      username: 'M00NFOX',
      displayName: 'M00nFox',
      inviteOrFileCode: 'MF5-66-3R',
      pin: '223606',
      password: 'MoonRun88',
      backupPassword: 'FoxMoon11',
      tier: UserTier.agent,
    ),
    OperatorIdentity(
      username: 'V3CTORKID',
      displayName: 'V3ctorKid',
      inviteOrFileCode: 'VK6-66-3R',
      pin: '244949',
      password: 'VecTor99',
      backupPassword: 'KidVector3',
      tier: UserTier.agent,
    ),
    OperatorIdentity(
      username: 'GL1TCHCAT',
      displayName: 'Gl1tchCat',
      inviteOrFileCode: 'GC7-66-3R',
      pin: '264575',
      password: 'CatGlitch1',
      backupPassword: 'GlitchMe2',
      tier: UserTier.agent,
    ),
    OperatorIdentity(
      username: 'H0NEYBAD',
      displayName: 'H0neyBad',
      inviteOrFileCode: 'HB8-66-3R',
      pin: '331127',
      password: 'HoneyRun7',
      backupPassword: 'BadHoney9',
      tier: UserTier.agent,
    ),
    OperatorIdentity(
      username: 'PIXELW1Z',
      displayName: 'PixelW1z',
      inviteOrFileCode: 'PW9-66-3R',
      pin: '367879',
      password: 'PixelZap12',
      backupPassword: 'WizPixel5',
      tier: UserTier.agent,
    ),
  ];

  static final List<OperatorIdentity> _wave2Identities = OperatorWave2.all
      .map(
        (o) => OperatorIdentity(
          username: o.username,
          displayName: o.displayName,
          inviteOrFileCode: o.inviteCode,
          pin: o.pin,
          password: o.password,
          backupPassword: o.backupPassword,
          tier: o.tier,
        ),
      )
      .toList();

  /// Deduped list (pool Art3mas overlaps specialised naming).
  static List<OperatorIdentity> get unique {
    final seen = <String>{};
    final out = <OperatorIdentity>[];
    for (final id in all) {
      final key = id.username.toUpperCase();
      if (seen.add(key)) out.add(id);
    }
    return out;
  }

  static OperatorIdentity? byUsername(String username) {
    final u = username.trim().toUpperCase();
    for (final id in unique) {
      if (id.username.toUpperCase() == u) return id;
    }
    return null;
  }

  /// Match login aliases like `Art3mas` → seeded username `ARTEM3S`.
  static OperatorIdentity? byDisplayName(String name) {
    final n = name.trim().toUpperCase();
    if (n.isEmpty) return null;
    for (final id in unique) {
      if (id.displayName.toUpperCase() == n) return id;
    }
    return null;
  }

  /// Dev accounts that may browse the full operator-card roster.
  /// SpamKat2, RedTeam01, and Gam3.0n only — everyone else sees their own card.
  static const Set<String> fullRosterDevUsernames = {
    AppConstants.adminUsername, // REDTEAM01
    AppConstants.opSpamKatUsername, // SPAMKAT2
    AppConstants.opGameOnUsername, // GAM3.0N
  };

  static bool canViewFullRoster(String? username) {
    if (username == null || username.trim().isEmpty) return false;
    return fullRosterDevUsernames.contains(username.trim().toUpperCase());
  }

  /// Cards visible to [username]: full unique roster for the three DEV accounts,
  /// otherwise only that operator's own card (empty if unknown).
  static List<OperatorIdentity> visibleFor(String? username) {
    if (canViewFullRoster(username)) return unique;
    final own = username == null ? null : byUsername(username);
    return own == null ? const [] : [own];
  }

  /// Keep in sync with [OperatorRoster.allSeeds] at compile time via tests.
  static List<OperatorIdentity> fromRoster() => OperatorRoster.allSeeds
      .map(
        (o) => OperatorIdentity(
          username: o.username,
          displayName: o.displayName,
          inviteOrFileCode: o.inviteCode,
          pin: o.pin,
          password: o.password,
          backupPassword: o.backupPassword,
          tier: o.tier,
        ),
      )
      .toList();
}
