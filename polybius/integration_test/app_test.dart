import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:polybius/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('register, login, and keep /cipher gated until unlock',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'OPERATOR');
    await tester.enterText(find.byType(TextField).at(1), 'correcthorse1');
    await tester.enterText(find.byType(TextField).at(2), 'correcthorse1');
    await tester.enterText(find.byType(TextField).at(3), '123456');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'OPERATOR');
    await tester.enterText(find.byType(TextField).at(1), 'correcthorse1');
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.text('START GAME'), findsOneWidget);
    expect(find.textContaining('CHERRY CIPHER'), findsNothing);

    final menu = tester.element(find.text('START GAME'));
    GoRouter.of(menu).go('/cipher');
    await tester.pumpAndSettle();
    expect(find.text('START GAME'), findsOneWidget);
    expect(find.textContaining('CHERRY CIPHER'), findsNothing);

    GoRouter.of(tester.element(find.text('START GAME'))).go('/devportal');
    await tester.pumpAndSettle();
    expect(find.text('START GAME'), findsOneWidget);
    expect(find.textContaining('ACCESS PORTAL'), findsNothing);
  });
}
