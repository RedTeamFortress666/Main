import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/auth/login_policy.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/core/constants/operator_roster.dart';
import 'package:polybius/core/constants/operator_wave2.dart';
import 'package:polybius/core/constants/operator_wave3.dart';
import 'package:polybius/core/models/models.dart';

void main() {
  test('dev admin roster has 24 operators', () {
    expect(LoginPolicy.devAdminUsernames, hasLength(24));
    expect(LoginPolicy.devAdminUsernames, contains('REDTEAM01'));
    expect(LoginPolicy.devAdminUsernames, contains('SPAMKAT2'));
    expect(LoginPolicy.devAdminUsernames, contains('NEONVULT'));
    expect(LoginPolicy.devAdminUsernames, contains('HEXWRAITH'));
    expect(LoginPolicy.devAdminUsernames, contains('APEXW0LF'));
    expect(LoginPolicy.devAdminUsernames, contains('ZER0KERN'));
    expect(LoginPolicy.devAdminUsernames, isNot(contains('GL1TCHCAT')));
    expect(LoginPolicy.devAdminUsernames, isNot(contains('AUR0RAFOX')));
  });

  test('user agent roster has 50 operators', () {
    expect(LoginPolicy.userAgentUsernames, hasLength(50));
    expect(LoginPolicy.userAgentUsernames, contains('T3MPTRESS'));
    expect(LoginPolicy.userAgentUsernames, contains('GL1TCHCAT'));
    expect(LoginPolicy.userAgentUsernames, contains('TACHY0N'));
    expect(LoginPolicy.userAgentUsernames, contains('AUR0RAFOX'));
    expect(LoginPolicy.userAgentUsernames, contains('TIDALNYX'));
    expect(LoginPolicy.userAgentUsernames, isNot(contains('REDTEAM01')));
  });

  test('portal flavor allows admin and developer only', () {
    expect(
      LoginPolicy.tierAllowed(UserTier.admin, flavor: PolybiusFlavor.hq),
      isTrue,
    );
    expect(
      LoginPolicy.tierAllowed(UserTier.developer, flavor: PolybiusFlavor.hq),
      isTrue,
    );
    expect(
      LoginPolicy.tierAllowed(UserTier.agent, flavor: PolybiusFlavor.hq),
      isFalse,
    );
    expect(
      LoginPolicy.rejectionMessage(UserTier.agent, flavor: PolybiusFlavor.hq),
      contains('V.1 USER'),
    );
  });

  test('user flavor allows agent tier only', () {
    expect(
      LoginPolicy.tierAllowed(UserTier.agent, flavor: PolybiusFlavor.user),
      isTrue,
    );
    expect(
      LoginPolicy.tierAllowed(UserTier.admin, flavor: PolybiusFlavor.user),
      isFalse,
    );
    expect(
      LoginPolicy.tierAllowed(
        UserTier.developer,
        flavor: PolybiusFlavor.user,
      ),
      isFalse,
    );
    expect(
      LoginPolicy.rejectionMessage(
        UserTier.admin,
        flavor: PolybiusFlavor.user,
      ),
      contains('PORTAL'),
    );
  });

  test('every seeded dev admin maps to admin or developer tier', () {
    final seeds = [
      ...OperatorRoster.pool.where((o) => o.tier != UserTier.agent),
      ...OperatorWave2.admins,
      ...OperatorWave2.developers,
      ...OperatorWave3.admins,
      ...OperatorWave3.developers,
    ];
    for (final seed in seeds) {
      expect(
        LoginPolicy.devAdminUsernames,
        contains(seed.username),
        reason: seed.displayName,
      );
    }
    expect(
      LoginPolicy.devAdminUsernames,
      contains(AppConstants.adminUsername),
    );
    expect(
      LoginPolicy.devAdminUsernames,
      contains(AppConstants.opSpamKatUsername),
    );
  });

  test('every seeded user agent maps to agent tier', () {
    final seeds = [
      ...OperatorRoster.pool.where((o) => o.tier == UserTier.agent),
      ...OperatorWave2.users,
      ...OperatorWave3.users,
    ];
    for (final seed in seeds) {
      expect(
        LoginPolicy.userAgentUsernames,
        contains(seed.username),
        reason: seed.displayName,
      );
    }
    expect(
      LoginPolicy.userAgentUsernames,
      contains(AppConstants.opTemptressUsername),
    );
    expect(
      LoginPolicy.userAgentUsernames,
      contains(AppConstants.opMizzPicklesUsername),
    );
  });
}
