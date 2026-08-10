/// Access codes for the hidden cipher engine.
///
/// The crypto engine is reachable ONLY by logging in at the access portal
/// (reached via: LOAD GAME file number → SETTINGS difficulty 11 → ritual
/// language → lose a game → hold GAME OVER → ERROR report SEND).
/// Accepted codes:
/// - `B1-66-3R` / `D1-66-3R` / `W1-66-3R` → developer access (full engine +
///   dev panel; requires a developer or admin account)
/// - `Tr1-66-3R` and the Admin/user pool invite codes (`OperatorRoster`) →
///   user-only access for agent accounts; privileged (admin/developer)
///   accounts receive full engine access
/// - or a valid invite token signed by the project key (SignedToken)
library;

import 'package:polybius/core/constants/app_flavor.dart';

class UnlockCodes {
  static const String devB1663R = 'B1-66-3R';
  static const String devD1663R = 'D1-66-3R';
  static const String devW1663R = 'W1-66-3R';
  static const String userTr1663R = 'TR1-66-3R';
  static const String compoundDifficulty = '7';

  /// Legacy compound language (settings hold SELECT no longer opens portal).
  static const String compoundLanguage = 'RUSSIAN';

  /// Legacy Chinese check retained for invite-code side path.
  static const String chineseLanguage = 'CHINESE';

  static const int ritualDifficulty = 11;

  /// Flavor-specific ritual language: RUSSIAN (Portal) / JAPANESE (V.1).
  static String get ritualLanguage => AppFlavor.ritualLanguage;

  /// Codes that open the full developer engine (privileged account required).
  static const Set<String> developerCodes = {
    devB1663R,
    devD1663R,
    devW1663R,
  };
}

enum UnlockState {
  locked,
  hinted,
  partial,
  unlocked,
  developer,
}
