/// Access codes for the hidden cipher engine.
///
/// The crypto engine is reachable ONLY by logging in at the dev access portal
/// (reached via the ritual: hold title 6s → SETTINGS difficulty 11 → LANGUAGES
/// Russian + hold SELECT 3s). Accepted codes:
/// - `B1-66-3R` / `D1-66-3R` / `W1-66-3R` → developer access (full engine +
///   dev panel; requires a developer or admin account)
/// - `Tr1-66-3R` → user-only access for agent accounts; privileged (admin /
///   developer) accounts receive full engine access
/// - or a valid invite token signed by the project key (SignedToken)
library;

class UnlockCodes {
  static const String devB1663R = 'B1-66-3R';
  static const String devD1663R = 'D1-66-3R';
  static const String devW1663R = 'W1-66-3R';
  static const String userTr1663R = 'TR1-66-3R';
  static const String compoundDifficulty = '7';
  static const String compoundLanguage = 'RUSSIAN';
  static const String ritualLanguage = 'CHINESE';
  static const int ritualDifficulty = 11;

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
