/// Build flavor — select with `--dart-define=POLYBIUS_FLAVOR=hq|user`
/// and matching Android product flavors (`hq` / `user`).
library;

enum PolybiusFlavor {
  /// EMOJINIGMA HQ — Dev Admin fork with triple-tier (agent / admin / developer)
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
      isHq ? 'EMOJINIGMA HQ' : 'PØLYBĪUS';

  static String get subtitle => isHq
      ? 'DEV ADMIN · TRIPLE TIER · V1 STABLE'
      : 'OPERATOR TERMINAL · V1 STABLE';

  /// Developer unlock state + red-team panel only on the HQ fork.
  static bool get allowDeveloperTools => isHq;
}
