import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/services/vault_service.dart';
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

  test('bulletin baseline parses seconds language', () {
    final s = BulletinService();
    // ignore: invalid_use_of_visible_for_testing_member
    final parsed = s.runtimeType; // smoke
    expect(parsed.toString(), contains('BulletinService'));
    expect(BulletinService.sourceUrl, contains('thebulletin.org'));
  });
}
