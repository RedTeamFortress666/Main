/// Cipher access is not a compiled-in code. The arcade ritual only *primes*
/// the portal route; the operator passphrase lives hashed on the account.
library;

class UnlockCodes {
  static const int ritualDifficulty = 11;
  static const String ritualLanguage = 'RUSSIAN';
}

enum UnlockState {
  locked,
  hinted,
  partial,
  unlocked,
  developer,
}
