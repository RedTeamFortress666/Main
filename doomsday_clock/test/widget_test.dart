import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doomsday_clock/main.dart';
import 'package:doomsday_clock/screens/planner_tab.dart';
import 'package:doomsday_clock/services/auth_service.dart';
import 'package:doomsday_clock/theme/noir_theme.dart';

void main() {
  testWidgets('renders vault login brand', (tester) async {
    await tester.pumpWidget(const DoomsdayClockApp());
    expect(find.textContaining('DOOMSDAY CLOCK 2.0'), findsWidgets);
    expect(find.textContaining('VAULT LOGIN'), findsOneWidget);
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
