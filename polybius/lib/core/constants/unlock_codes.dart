/// Unlock ritual codes and sequences for the hidden cipher layer.
///
/// Unlock flows (documented for operators):
/// 1. **Title hold**: Hold "PØLYBĪUS" title for 3+ seconds → glitch flash → cipher hint.
/// 2. **Difficulty ritual**: Set difficulty to 11 + language ENGLISH → partial unlock token.
/// 3. **LOAD GAME invite**: Valid invite code opens cipher (tier-based access).
/// 4. **Dev ritual**: LOAD GAME code "B1-66-3R" or "D1-66-3R" with CHINESE language
///    selected in SETTINGS → developer panel (debug builds only show shortcuts).
/// 5. **Compound**: Title hold + difficulty 7 + RUSSIAN → full cipher unlock without invite.
library;

class UnlockCodes {
  static const String devB1663R = 'B1-66-3R';
  static const String devD1663R = 'D1-66-3R';
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
