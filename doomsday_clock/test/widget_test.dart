import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doomsday_clock/main.dart';
import 'package:doomsday_clock/screens/desk_tab.dart';
import 'package:doomsday_clock/screens/planner_tab.dart';
import 'package:doomsday_clock/screens/route_tab.dart';
import 'package:doomsday_clock/services/auth_service.dart';
import 'package:doomsday_clock/theme/noir_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home desk shows three cover apps, not vault login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DoomsdayClockApp());
    await tester.pump();
    expect(find.textContaining('CRYPT3X OS'), findsWidgets);
    expect(find.text('MAIL'), findsOneWidget);
    expect(find.text('F-DROID'), findsOneWidget);
    expect(find.text('BRAVE'), findsOneWidget);
    expect(find.textContaining('VAULT LOGIN'), findsNothing);
  });

  testWidgets('desk lists only mail, fdroid, brave', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DeskTab()),
      ),
    );
    await tester.pump();
    expect(find.text('MAIL'), findsOneWidget);
    expect(find.text('F-DROID'), findsOneWidget);
    expect(find.text('BRAVE'), findsOneWidget);
    expect(find.textContaining('PØLYBĪUS'), findsNothing);
    expect(find.textContaining('.apk'), findsNothing);
  });

  testWidgets('route tab exposes DNS presets and hardened profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NoirTheme.dark,
        home: const Scaffold(body: RouteTab()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('QUAD9'), findsOneWidget);
    expect(find.textContaining('PROTON'), findsOneWidget);
    expect(find.textContaining('APPLY 2026 HARDENED PROFILE'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    expect(find.textContaining('PRINT'), findsWidgets);
  });

  testWidgets('planner conceals Polybius — no player or APK cards', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: NoirTheme.dark,
        home: Scaffold(
          body: PlannerTab(
            session: AuthSession(
              username: 'ARTEM3S',
              displayName: 'Art3mas',
              tier: 'admin',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SAVE NOTE'), findsOneWidget);
    expect(find.textContaining('Nothing else is stored here'), findsOneWidget);
    expect(find.textContaining('.apk'), findsNothing);
    expect(find.textContaining('http'), findsNothing);
    expect(find.textContaining('player'), findsNothing);
    expect(find.textContaining('DOWNLOAD'), findsNothing);
  });
}
