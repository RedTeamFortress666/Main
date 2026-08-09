/// Procedurally assigned Admin/user operator roster for the BETA pool APK.
///
/// Ten accounts bootstrapped on first install. Each has a unique invite code
/// accepted at the dev access portal (user/agent → cipher; admin → full engine).
library;

import 'package:polybius/core/constants/app_constants.dart';

class OperatorSeed {
  const OperatorSeed({
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
  final UserTier tier;
}

/// Fixed roster — memorable alphanumeric passwords (≤12 chars).
class OperatorRoster {
  static const List<OperatorSeed> pool = [
    OperatorSeed(
      username: 'NITEQUEEN',
      displayName: 'NiteQueen',
      inviteCode: 'NQ1-66-3R',
      pin: '314159',
      password: 'NiteOwl42',
      backupPassword: 'NightOwl7',
      tier: UserTier.admin,
    ),
    OperatorSeed(
      username: 'ARTEM3S',
      displayName: 'Artem3s',
      inviteCode: 'AR2-66-3R',
      pin: '271828',
      password: 'BowArrow7',
      backupPassword: 'Huntress9',
      tier: UserTier.admin,
    ),
    OperatorSeed(
      username: 'CUP1D!',
      displayName: 'Cup1d!',
      inviteCode: 'CU3-66-3R',
      pin: '161803',
      password: 'LoveShot99',
      backupPassword: 'CupidsBow1',
      tier: UserTier.agent,
    ),
    OperatorSeed(
      username: 'DYSLEX1C',
      displayName: 'Dyslex1c',
      inviteCode: 'DX4-66-3R',
      pin: '141421',
      password: 'SpellMix8',
      backupPassword: 'LexiFix99',
      tier: UserTier.agent,
    ),
    OperatorSeed(
      username: 'WHYTWOK',
      displayName: 'WhyTwoK',
      inviteCode: 'Y2K-66-3R',
      pin: '173205',
      password: 'PartyY2K1',
      backupPassword: 'TwoKWave2',
      tier: UserTier.agent,
    ),
    OperatorSeed(
      username: 'M00NFOX',
      displayName: 'M00nFox',
      inviteCode: 'MF5-66-3R',
      pin: '223606',
      password: 'MoonRun88',
      backupPassword: 'FoxMoon11',
      tier: UserTier.agent,
    ),
    OperatorSeed(
      username: 'V3CTORKID',
      displayName: 'V3ctorKid',
      inviteCode: 'VK6-66-3R',
      pin: '244949',
      password: 'VecTor99',
      backupPassword: 'KidVector3',
      tier: UserTier.agent,
    ),
    OperatorSeed(
      username: 'GL1TCHCAT',
      displayName: 'Gl1tchCat',
      inviteCode: 'GC7-66-3R',
      pin: '264575',
      password: 'CatGlitch1',
      backupPassword: 'GlitchMe2',
      tier: UserTier.agent,
    ),
    OperatorSeed(
      username: 'H0NEYBAD',
      displayName: 'H0neyBad',
      inviteCode: 'HB8-66-3R',
      pin: '331127',
      password: 'HoneyRun7',
      backupPassword: 'BadHoney9',
      tier: UserTier.agent,
    ),
    OperatorSeed(
      username: 'PIXELW1Z',
      displayName: 'PixelW1z',
      inviteCode: 'PW9-66-3R',
      pin: '367879',
      password: 'PixelZap12',
      backupPassword: 'WizPixel5',
      tier: UserTier.agent,
    ),
  ];

  /// Invite codes accepted at the portal for this Admin/user pool, plus any
  /// specialised named operators (e.g. T3mptress).
  static Set<String> get inviteCodes => {
        ...pool.map((o) => o.inviteCode.toUpperCase()),
        AppConstants.opTemptressInviteCode.toUpperCase(),
        AppConstants.opCrownOfCornsInviteCode.toUpperCase(),
        AppConstants.opMizzPicklesInviteCode.toUpperCase(),
        AppConstants.opPikZupInviteCode.toUpperCase(),
      };
}
