import 'package:meta/meta.dart';

/// Build flavor:
/// - **bunker** (default) — DOØMSDAY BUNKER v1 for SpamKat2 & Gam3.0n
/// - **stable** — DOØMSDAY CLØCK (stable) for any tier
class AppConfig {
  AppConfig._();

  static const flavor = String.fromEnvironment(
    'DOOMSDAY_FLAVOR',
    defaultValue: 'bunker',
  );

  static bool _stableRuntime = false;

  /// Called from `main_stable.dart`.
  static void enableStableRuntime() => _stableRuntime = true;

  @visibleForTesting
  static void resetFlavorForTest() => _stableRuntime = false;

  static bool get isStable => _stableRuntime || flavor == 'stable' || flavor == 'all_tier';
  static bool get isBunker => !isStable;

  /// Backward-compatible aliases used by older call sites.
  static bool get isAllTier => isStable;
  static bool get isPrivileged => isBunker;

  static String get displayName =>
      isBunker ? 'DOØMSDAY BUNKER v1' : 'DOØMSDAY CLØCK (stable)';

  static String get shortTitle =>
      isBunker ? 'DOOMSDAY BUNKER v1' : 'DOOMSDAY CLOCK (stable)';

  static String get authSubtitle => isBunker
      ? 'BUNKER TERMINAL · SPAMKAT2 / GAM3.0N'
      : 'CYBER TERMINAL · STABLE VAULT';

  static String get authFooter => isBunker
      ? 'Developer bunker — SpamKat2 & Gam3.0n only. '
          'Own card first, secondary player vault underneath.'
      : 'Stable vault for any tier — create account or jack in. '
          'Scan operator QR after 5 November unlock. DARTH CHERRY reveals secrets.';
}
