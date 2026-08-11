/// Build flavor — select with `--dart-define=POLYBIUS_FLAVOR=hq|user`
/// and matching Android product flavors (`hq` / `user`).
library;

enum PolybiusFlavor {
  /// PØLYBÎŪS PORTAL — Dev Admin fork with triple-tier (agent / admin / developer)
  /// access and cross encrypt/decrypt tooling.
  hq,

  /// Everyday-user APK — ENCRYPT / DECRYPT / SYNC / CONNECT without HQ tools.
  user,
}

class AppFlavor {
  static const String _raw = String.fromEnvironment(
    'POLYBIUS_FLAVOR',
    defaultValue: 'hq',
  );

  static PolybiusFlavor get current {
    switch (_raw.toLowerCase()) {
      case 'user':
        return PolybiusFlavor.user;
      case 'hq':
      case 'admin':
      case 'dev':
      default:
        return PolybiusFlavor.hq;
    }
  }

  static bool get isHq => current == PolybiusFlavor.hq;
  static bool get isUser => current == PolybiusFlavor.user;

  static String get displayName =>
      isHq ? 'PØLYBÎŪS PORTAL' : 'PØLYBÎŪS V.1';

  static String get subtitle => isHq
      ? 'DEV ADMIN · TRIPLE TIER · V1 STABLE'
      : 'USER BUILD · V1 STABLE';

  /// Developer unlock state + red-team panel only on the HQ fork.
  static bool get allowDeveloperTools => isHq;

  /// HQ keeps the Layer-1 login gate; user builds skip pre-login.
  static bool get requiresStartupLogin => isHq;

  /// Raw 560-emoji pool viewer is HQ-only (leak prevention + admin tooling).
  static bool get showPoolTab => isHq;

  /// Ritual portal title — never "DEV" on the everyday user APK.
  static String get accessPortalTitle =>
      isHq ? 'DEV ACCESS PORTAL' : 'USER ACCESS PORTAL';

  /// After cinematic splash: both flavors land on the arcade menu
  /// (START GAME / LOAD GAME / …). HQ still routes through login first.
  static String get postSplashRoute => '/menu';

  /// Language that completes the GAME OVER → portal ritual for this flavor.
  /// HQ / Portal: Russian. User V.1: Japanese (optional settings cue).
  static String get ritualLanguage => isHq ? 'RUSSIAN' : 'JAPANESE';
}
