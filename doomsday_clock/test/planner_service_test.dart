import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doomsday_clock/models/planner_note.dart';
import 'package:doomsday_clock/services/planner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('unlock phrase matches remember remember variants', () {
    final p = PlannerService();
    expect(p.matchesUnlockPhrase('remember remember'), isTrue);
    expect(p.matchesUnlockPhrase('Remember remember'), isTrue);
    expect(p.matchesUnlockPhrase('  REMEMBER   REMEMBER  '), isTrue);
    expect(p.matchesUnlockPhrase('wrong words'), isFalse);
    expect(p.matchesUnlockPhrase(''), isFalse);
  });

  test('ritual requires 5 November and the phrase', () {
    final p = PlannerService();
    final nov5 = DateTime(2026, 11, 5);
    final nov4 = DateTime(2026, 11, 4);

    expect(p.isUnlockDay(nov5), isTrue);
    expect(p.isUnlockDay(nov4), isFalse);
    expect(p.matchesUnlockRitual('remember remember', nov5), isTrue);
    expect(p.matchesUnlockRitual('remember remember', nov4), isFalse);
    expect(p.matchesUnlockRitual('hello journal', nov5), isFalse);
  });

  test('archive flag persists after open', () async {
    final p = PlannerService();
    expect(await p.isArchiveOpen(), isFalse);
    await p.openArchive();
    expect(await p.isArchiveOpen(), isTrue);
  });

  test('notes round-trip', () async {
    final p = PlannerService();
    expect(await p.loadNotes(), isEmpty);
    final saved = PlannerNote(
      id: 'n1',
      dayKey: '2026-11-05',
      body: 'hello',
      updatedAt: DateTime.utc(2026, 11, 5),
    );
    await p.saveNotes([saved]);
    final loaded = await p.loadNotes();
    expect(loaded, hasLength(1));
    expect(loaded.first.body, 'hello');
    expect(loaded.first.dayKey, '2026-11-05');
  });
}
