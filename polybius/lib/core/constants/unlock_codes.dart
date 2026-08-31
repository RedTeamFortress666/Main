/// Access codes for the hidden cipher engine.
///
/// The crypto engine is reachable ONLY by logging in at the dev access portal
/// (reached via the ritual: hold title 6s → SETTINGS difficulty 11 → LANGUAGES
/// Russian + hold SELECT 3s). Accepted codes:
/// - `B1-66-3R` / `D1-66-3R` → developer access (full engine + dev panel)
/// - `Tr1-66-3R` → user-only access (cipher without the dev panel)
/// - or a valid invite token signed by the project key (SignedToken)
library;

class UnlockCodes {
  static const String devB1663R = 'B1-66-3R';
  static const String devD1663R = 'D1-66-3R';
  static const String userTr1663R = 'TR1-66-3R';

  /// Arms the redlight glyph keyboard in the open cipher. Default V1
  /// encrypt stays a plaintext field until this is enabled.
  static const String darthCherry = 'DARTH-CHERRY';
  static const String darthCherryShort = 'CH3-RRY';

  static bool isDarthCherry(String raw) {
    final upper = raw.trim().toUpperCase();
    return upper == darthCherry || upper == darthCherryShort;
  }

  static const String compoundDifficulty = '7';
  static const String compoundLanguage = 'RUSSIAN';
  static const String ritualLanguage = 'CHINESE';
  static const int ritualDifficulty = 11;
}

enum UnlockState {
  locked,
  hinted,
  partial,
  unlocked,
  developer,
}
