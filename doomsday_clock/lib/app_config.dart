import 'package:meta/meta.dart';

/// Build flavor — privileged default, or all-tier via [enableAllTierRuntime].
class AppConfig {
  AppConfig._();

  static const flavor = String.fromEnvironment(
    'DOOMSDAY_FLAVOR',
    defaultValue: 'privileged',
  );

  static bool _allTierRuntime = false;

  /// Called from `main_all_tier.dart` so `--target lib/main_all_tier.dart` works.
  static void enableAllTierRuntime() => _allTierRuntime = true;

  @visibleForTesting
  static void resetFlavorForTest() => _allTierRuntime = false;

  static bool get isAllTier => _allTierRuntime || flavor == 'all_tier';
  static bool get isPrivileged => !isAllTier;

  static String get displayName =>
      isAllTier ? 'DOØMSDAY CLØCK · ALL TIER' : 'DOØMSDAY CLØCK';

  static String get authSubtitle => isAllTier
      ? 'CYBER TERMINAL · ALL TIER VAULT'
      : 'CYBER TERMINAL · OPERATOR AUTH';
}
