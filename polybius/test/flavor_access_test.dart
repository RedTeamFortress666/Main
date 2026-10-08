import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/core/constants/operator_identities.dart';
import 'package:polybius/core/constants/app_constants.dart';

/// Compile with:
///   flutter test --dart-define=POLYBIUS_FLAVOR=hq test/flavor_access_test.dart
///   flutter test --dart-define=POLYBIUS_FLAVOR=user test/flavor_access_test.dart
void main() {
  test('AppFlavor matches POLYBIUS_FLAVOR dart-define', () {
    // ignore: avoid_print
    print('flavor=${AppFlavor.current} display=${AppFlavor.displayName}');
    expect(AppFlavor.displayName, isNotEmpty);
    if (AppFlavor.isHq) {
      expect(AppFlavor.allowDeveloperTools, isTrue);
      expect(AppFlavor.displayName, 'EMOJINIGMA HQ');
      expect(AppFlavor.subtitle, contains('DEV ADMIN'));
    } else {
      expect(AppFlavor.allowDeveloperTools, isFalse);
      expect(AppFlavor.displayName, 'PØLYBĪUS');
      expect(AppFlavor.subtitle, contains('OPERATOR TERMINAL'));
    }
  });

  test('HQ-facing identities include admin/developer tiers', () {
    final privileged = OperatorIdentities.unique
        .where((id) =>
            id.tier == UserTier.admin || id.tier == UserTier.developer)
        .toList();
    expect(privileged, isNotEmpty);
    expect(
      privileged.any((id) => id.username == AppConstants.adminUsername),
      isTrue,
    );
  });

  test('User-facing identities include agent tiers', () {
    final agents = OperatorIdentities.unique
        .where((id) => id.tier == UserTier.agent)
        .toList();
    expect(agents.length, greaterThanOrEqualTo(8));
    expect(
      agents.any((id) => id.username == AppConstants.opTemptressUsername),
      isTrue,
    );
  });
}
