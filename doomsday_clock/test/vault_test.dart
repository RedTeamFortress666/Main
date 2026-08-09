import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/services/vault_service.dart';
import 'package:doomsday_clock/services/polybius_operators.dart';
import 'package:doomsday_clock/services/bulletin_service.dart';

void main() {
  test('ritual words rotate by day and match contiguous input', () {
    final v = VaultService();
    final day = DateTime(2026, 8, 9);
    final phrase = v.ritualPhraseFor(day);
    expect(phrase.split(' '), hasLength(3));
    expect(v.matchesRitual(phrase, day), isTrue);
    expect(v.matchesRitual('prefix $phrase suffix', day), isTrue);
    expect(v.matchesRitual('wrong words here', day), isFalse);
  });

  test('polybius admin auth accepts Art3mas and rejects bad pin', () {
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
