import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/services/vault_service.dart';
import 'package:doomsday_clock/services/polybius_operators.dart';
import 'package:doomsday_clock/services/bulletin_service.dart';

void main() {
  test('vault unlocks only on 5 November with Gunpowder Plot riddle', () {
    final v = VaultService();
    final nov5 = DateTime(2026, 11, 5);
    final nov4 = DateTime(2026, 11, 4);

    expect(v.isUnlockDay(nov5), isTrue);
    expect(v.isUnlockDay(nov4), isFalse);

    final phrase = VaultService.gunpowderRiddle;
    expect(v.matchesRitual(phrase, nov5), isTrue);
    expect(v.matchesRitual('prefix $phrase suffix', nov5), isTrue);
    expect(v.matchesRitual(phrase, nov4), isFalse);
    expect(v.matchesRitual('wrong words here', nov5), isFalse);

    // Punctuation / casing / common variant tolerance
    expect(
      v.matchesRitual(
        'remember remember the 5th of november the gunpowder treason '
        'and plot i know of no reason why gunpowder treason should ever be forgot',
        nov5,
      ),
      isTrue,
    );
    expect(
      v.matchesRitual(
        'Remember, remember the fifth of November, the gunpowder treason '
        'and plot - I know of no reason why gunpowder treason should ever be forgotten',
        nov5,
      ),
      isTrue,
    );
  });

  test('privileged operator auth accepts Art3mas and rejects bad pin', () {
    final ok = authenticatePolybiusAdmin(
      username: 'Art3mas',
      password: 'BowArrow7',
      pin: '271828',
    );
    expect(ok, isNotNull);
    expect(ok!.tier, 'admin');

    final bad = authenticatePolybiusAdmin(
      username: 'Art3mas',
      password: 'BowArrow7',
      pin: '000000',
    );
    expect(bad, isNull);
  });

  test('bulletin source is BAS', () {
    expect(BulletinService.sourceUrl, contains('thebulletin.org'));
  });
}
