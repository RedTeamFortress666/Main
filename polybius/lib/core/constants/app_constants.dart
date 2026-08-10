/// Application-wide constants for PØLYBĪUS.
library;

class AppConstants {
  static const String appName = 'PØLYBĪUS';

  /// Retired for V1 Stable — must never authenticate.
  static const String retiredDeveloperUsername = 'DEVELOPER';

  /// @Deprecated('Use adminUsername / operator accounts — DEVELOPER is stricken')
  static const String developerUsername = retiredDeveloperUsername;
  static const String developerDefaultPin = '000000';

  /// Operator admin account (RedTeam01) bootstrapped on first install.
  static const String adminUsername = 'REDTEAM01';
  static const String adminDisplayName = 'RedTeam01';

  /// 6-digit dev number used as RedTeam01's PIN and initial password.
  static const String adminDevNumber = '816639';

  /// Game file number embedded for the developer's copy of the game.
  static const String devGameFileNumber = 'B1-66-3R';

  // --- Bootstrapped operator accounts (created on first install) ---

  /// Developer operator: SpamKat2 / W1-66-3R.
  static const String opSpamKatUsername = 'SPAMKAT2';
  static const String opSpamKatDisplayName = 'SpamKat2';
  static const String opSpamKatDevCode = 'W1-66-3R';
  static const String opSpamKatPin = '810739';
  static const String opSpamKatPassword = 'Ev1l-Schm33';
  static const String opSpamKatBackupPassword = 'LilB1tScary99';

  /// Developer operator: Gam3.0n / B1-66-3R.
  static const String opGameOnUsername = 'GAM3.0N';
  static const String opGameOnDisplayName = 'Gam3.0n';
  static const String opGameOnDevCode = 'B1-66-3R';
  static const String opGameOnPin = '816639';
  static const String opGameOnPassword = 'Dig1tal.Ra1n99';
  static const String opGameOnBackupPassword = '01-p0lyb1u5-10';

  /// Admin operator: KASP3R / TR1-66-3R.
  static const String opKasperUsername = 'KASP3R';
  static const String opKasperDisplayName = 'KASP3R';
  static const String opKasperInviteCode = 'TR1-66-3R';
  static const String opKasperPin = '791639';
  static const String opKasperPassword = 'BurnHideFr13d';
  static const String opKasperBackupPassword = 'P1ckl3M0rty69';

  /// Standard user operator: T3mptress / 80-081-35.
  static const String opTemptressUsername = 'T3MPTRESS';
  static const String opTemptressDisplayName = 'T3mptress';
  static const String opTemptressInviteCode = '80-081-35';
  static const String opTemptressPin = '808135';
  static const String opTemptressPassword = 'not1nkansas69';
  static const String opTemptressBackupPassword = 'NoPlaceL1ke';

  /// Admin operator: CrownOfCorns / C0-9N-3E.
  static const String opCrownOfCornsUsername = 'CROWNOFCORNS';
  static const String opCrownOfCornsDisplayName = 'CrownOfCorns';
  static const String opCrownOfCornsInviteCode = 'C0-9N-3E';
  static const String opCrownOfCornsPin = '539667';
  static const String opCrownOfCornsPassword = '20YokoMicrowave14';
  static const String opCrownOfCornsBackupPassword = 'C0rnS1lo14';

  /// Standard user operator: MizzPickl3s / SP-1N-33.
  static const String opMizzPicklesUsername = 'MIZZPICKL3S';
  static const String opMizzPicklesDisplayName = 'MizzPickl3s';
  static const String opMizzPicklesInviteCode = 'SP-1N-33';
  static const String opMizzPicklesPin = '080826';
  static const String opMizzPicklesPassword = '8-Bit.Bitch3s';
  static const String opMizzPicklesBackupPassword = 'Glitch.B1tch99';

  /// Admin operator: P!k.ZuP / D4-N6-3R.
  static const String opPikZupUsername = 'P!K.ZUP';
  static const String opPikZupDisplayName = 'P!k.ZuP';
  static const String opPikZupInviteCode = 'D4-N6-3R';
  static const String opPikZupPin = '839093';
  static const String opPikZupPassword = 'DocCh1ck3n';
  static const String opPikZupBackupPassword = 'TakeAOrdaPr33z';

  static const int poolSize = 560;
  static const int halfPool = 280;
  static const int titleHoldMs = 3000;
  static const int devTitleHoldMs = 6000;
  static const int langSelectHoldMs = 3000;
  static const int gameOverHoldMs = 6000;
  static const int glitchFlashMs = 120;
  static const List<String> mkUltraPhrases = [
    'PROJECT MKULTRA',
    'MIDNIGHT CLIMAX',
    'OPERATION MOCKINGBIRD',
    'COINTELPRO ACTIVE',
    'BLUEBIRD PROTOCOL',
    'ARTICHOKE DIRECTIVE',
    'POLYBIUS CABINET',
    'SUBLIMINAL VECTOR',
    'NEURAL DISSOCIATION',
    'MEMORY FRAGMENTATION',
  ];
  static const List<String> supportedLanguages = [
    'ENGLISH',
    'SPANISH',
    'FRENCH',
    'GERMAN',
    'RUSSIAN',
    'CHINESE',
    'JAPANESE',
  ];
}

enum UserTier { guest, agent, admin, developer }

enum InviteTier { standard, agent, admin, developer }
