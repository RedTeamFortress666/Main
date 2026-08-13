import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/data/polybius_operator_cards.dart';
import 'package:doomsday_clock/services/planner_service.dart';
import 'package:doomsday_clock/services/polybius_operators.dart';
import 'package:doomsday_clock/services/bulletin_service.dart';
import 'package:doomsday_clock/services/qr_card_codec.dart';
import 'package:doomsday_clock/services/ritual_settings_service.dart';

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
  });

  test('custom ritual unlock phrase and date', () {
    final p = PlannerService();
    final customDay = DateTime(2026, 3, 15);
    const custom = RitualSettings(phrase: 'open sesame', month: 3, day: 15);

    expect(p.matchesRitual('open sesame', customDay, custom: custom), isTrue);
    expect(p.matchesRitual('wrong', customDay, custom: custom), isFalse);
    expect(
      p.matchesRitual('open sesame', DateTime(2026, 11, 5), custom: custom),
      isFalse,
    );
  });

  test('QR codec round-trips operator card', () {
    const card = PolybiusOperatorCard(
      username: 'TESTOP',
      displayName: 'Test Op',
      inviteCode: 'T3-ST-0P',
      pin: '123456',
      password: 'secret',
      backupPassword: 'backup',
      tier: 'agent',
    );
    final encoded = QrCardCodec.encode(card);
    final decoded = QrCardCodec.decode(encoded);
    expect(decoded, isNotNull);
    expect(decoded!.username, 'TESTOP');
    expect(decoded.password, 'secret');
    expect(decoded.pin, '123456');
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

  test('bulletin source is BAS', () {
    expect(BulletinService.sourceUrl, contains('thebulletin.org'));
  });
}
