/// Application-wide constants for PØLYBĪUS.
library;

class AppConstants {
  static const String appName = 'PØLYBĪUS';
  static const String developerUsername = 'DEVELOPER';
  static const String developerDefaultPin = '000000';

  /// Game file number embedded for the developer's copy of the game.
  static const String devGameFileNumber = 'B1-66-3R';
  static const int poolSize = 560;
  static const int halfPool = 280;

  /// Design target for the daily master draw. Actual unique single-codepoint
  /// glyphs may be smaller; [PoolManager] reports the real master size.
  static const int masterPoolTarget = 5600;

  /// Active-pool remapping cadence (UTC). Full master redraw is daily.
  static const int remapHours = 2;

  /// Vanishing plaintext flash — gone before ENCRYPT is typically pressed.
  static const int vanishingMs = 800;

  /// Constant-size transport frame (bytes) to blunt traffic-length metadata.
  static const int syncFrameBytes = 2048;
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
