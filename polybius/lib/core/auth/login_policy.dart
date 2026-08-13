import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/core/constants/operator_roster.dart';
import 'package:polybius/core/constants/operator_wave2.dart';
import 'package:polybius/core/models/models.dart';

/// Layer-1 login rules per APK flavor.
///
/// - **PORTAL (hq):** developer + admin operators only (16 accounts).
/// - **V.1 USER:** agent / standard operators only (30 accounts).
class LoginPolicy {
  LoginPolicy._();

  static bool tierAllowed(UserTier tier, {PolybiusFlavor? flavor}) {
    switch (flavor ?? AppFlavor.current) {
      case PolybiusFlavor.hq:
        return tier == UserTier.admin || tier == UserTier.developer;
      case PolybiusFlavor.user:
        return tier == UserTier.agent;
    }
  }

  static String rejectionMessage(UserTier tier, {PolybiusFlavor? flavor}) {
    final f = flavor ?? AppFlavor.current;
    if (f == PolybiusFlavor.hq) {
      return tier == UserTier.agent
          ? 'USER ACCOUNT — INSTALL PØLYBÎŪS V.1 USER APK'
          : 'ACCESS DENIED';
    }
    return tier == UserTier.admin || tier == UserTier.developer
        ? 'DEV/ADMIN ACCOUNT — INSTALL PØLYBÎŪS PORTAL APK'
        : 'ACCESS DENIED';
  }

  /// All dev/admin operator usernames bootstrapped for PORTAL login tests.
  static Set<String> get devAdminUsernames => {
        AppConstants.adminUsername,
        AppConstants.opSpamKatUsername,
        AppConstants.opGameOnUsername,
        AppConstants.opKasperUsername,
        AppConstants.opCrownOfCornsUsername,
        AppConstants.opPikZupUsername,
        ...OperatorRoster.pool
            .where((o) => o.tier == UserTier.admin)
            .map((o) => o.username),
        ...OperatorWave2.admins.map((o) => o.username),
        ...OperatorWave2.developers.map((o) => o.username),
      };

  /// All user/agent operator usernames bootstrapped for V.1 USER login tests.
  static Set<String> get userAgentUsernames => {
        AppConstants.opTemptressUsername,
        AppConstants.opMizzPicklesUsername,
        ...OperatorRoster.pool
            .where((o) => o.tier == UserTier.agent)
            .map((o) => o.username),
        ...OperatorWave2.users.map((o) => o.username),
      };
}
