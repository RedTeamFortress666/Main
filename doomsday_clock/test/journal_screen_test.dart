import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doomsday_clock/main.dart';
import 'package:doomsday_clock/screens/journal_screen.dart';
import 'package:doomsday_clock/services/planner_service.dart';
import 'package:doomsday_clock/services/qr_card_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpJournal(WidgetTester tester, DateTime now) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      DoomsdayClockApp(
        home: JournalScreen(
          now: now,
          planner: PlannerService(holdMs: 200),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> holdSave(WidgetTester tester) async {
    final gesture = await tester.press(find.byKey(const Key('save-button')));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  String allText(WidgetTester tester) {
    final buf = StringBuffer();
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      buf.writeln(text.data ?? '');
    }
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      buf.writeln(field.decoration?.hintText ?? '');
      buf.writeln(field.decoration?.labelText ?? '');
    }
    return buf.toString().toLowerCase();
  }

  testWidgets('sealed journal never mentions the archive or ritual', (tester) async {
    await pumpJournal(tester, DateTime(2026, 8, 18));

    expect(find.text('Calendar / Journal'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    final visible = allText(tester);
    expect(visible.contains('vault'), isFalse);
    expect(visible.contains('remember remember'), isFalse);
    expect(visible.contains('darth'), isFalse);
    expect(visible.contains('cherry'), isFalse);
    expect(visible.contains('gunpowder'), isFalse);
    expect(visible.contains('hidden'), isFalse);
    expect(find.text('Operator cards'), findsNothing);
    expect(find.text('Scan'), findsNothing);
  });

  testWidgets('tap Save stores a journal entry', (tester) async {
    await pumpJournal(tester, DateTime(2026, 8, 18));

    await tester.enterText(find.byKey(const Key('journal-note')), 'Morning coffee');
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    expect(find.text('• Morning coffee'), findsOneWidget);
    expect(find.text('Operator cards'), findsNothing);
  });

  testWidgets('holding Save on 5 Nov with the phrase opens operator cards',
      (tester) async {
    await pumpJournal(tester, DateTime(2026, 11, 1));

    await tester.tap(find.byKey(const Key('day-2026-11-5')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('journal-note')), 'remember remember');
    await holdSave(tester);

    await tester.ensureVisible(find.text('Operator cards'));
    await tester.pumpAndSettle();
    expect(find.text('Operator cards'), findsOneWidget);
    expect(find.text('DARTH CHERRY'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('scanned card secrets stay hidden until DARTH CHERRY is on',
      (tester) async {
    await pumpJournal(tester, DateTime(2026, 11, 5));

    await tester.enterText(find.byKey(const Key('journal-note')), 'remember remember');
    await holdSave(tester);

    await tester.ensureVisible(find.text('Paste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();

    final payload = QrCardCodec.encodePolybiusCard(
      username: 'GAM3.0N',
      displayName: 'Gam3.0n',
      tier: 'developer',
      inviteCode: 'B1-66-3R',
    );
    await tester.enterText(find.byKey(const Key('paste-card-field')), payload);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('GAM3.0N'), findsOneWidget);
    expect(find.text('Dig1tal.Ra1n99'), findsNothing);
    expect(find.text('816639'), findsNothing);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Dig1tal.Ra1n99'), findsOneWidget);
    expect(find.text('816639'), findsOneWidget);
    expect(find.text('01-p0lyb1u5-10'), findsOneWidget);
  });
}
