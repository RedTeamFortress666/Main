import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/data/polybius_operator_cards.dart';
import 'package:doomsday_clock/services/planner_service.dart';
import 'package:doomsday_clock/services/polybius_operators.dart';
import 'package:doomsday_clock/services/bulletin_service.dart';

void main() {
  test('Nov 5 unlocks with Remember remember phrase', () {
    final p = PlannerService();
    final nov5 = DateTime(2026, 11, 5);
    final nov4 = DateTime(2026, 11, 4);

    expect(p.isGunpowderDay(nov5), isTrue);
    expect(p.isGunpowderDay(nov4), isFalse);

    expect(p.matchesRitual('Remember remember', nov5), isTrue);
    expect(p.matchesRitual('remember remember', nov5), isTrue);
    expect(p.matchesRitual('Remember remember', nov4), isFalse);
    expect(p.matchesRitual('wrong words', nov5), isFalse);

    // Legacy full riddle still works
    expect(
      p.matchesRitual(
        'remember remember the 5th of november the gunpowder treason '
        'and plot i know of no reason why gunpowder treason should ever be forgot',
        nov5,
      ),
      isTrue,
    );
  });

  test('20 April unlocks with MechaH birthday line', () {
    final p = PlannerService();
    final apr20 = DateTime(2026, 4, 20);
    final apr19 = DateTime(2026, 4, 19);

    expect(p.isMechaHDay(apr20), isTrue);
    expect(p.isUnlockDay(apr20), isTrue);
    expect(p.isUnlockDay(apr19), isFalse);

    expect(p.matchesRitual(PlannerService.mechaHBirthday, apr20), isTrue);
    expect(
      p.matchesRitual('happy birthday mechah i grok thee', apr20),
      isTrue,
    );
    expect(p.matchesRitual(PlannerService.mechaHBirthday, apr19), isFalse);
  });

  test('Gam3.0n is the only Cherry cache roster viewer', () {
    expect(PolybiusOperatorCards.canOpenCherryCache('GAM3.0N'), isTrue);
    expect(PolybiusOperatorCards.canOpenCherryCache('Gam3.0n'), isTrue);
    expect(PolybiusOperatorCards.canOpenCherryCache('REDTEAM01'), isFalse);
    expect(PolybiusOperatorCards.all.length, greaterThanOrEqualTo(44));
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

  test('Gam3.0n admin credentials authenticate', () {
    final ok = authenticatePolybiusAdmin(
      username: 'GAM3.0N',
      password: 'Dig1tal.Ra1n99',
      pin: '816639',
    );
    expect(ok, isNotNull);
    expect(ok!.tier, 'developer');
  });

  test('bulletin source is BAS', () {
    expect(BulletinService.sourceUrl, contains('thebulletin.org'));
  });
}
