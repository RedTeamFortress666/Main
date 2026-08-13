import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_veil/death_star_display.dart';
import 'package:red_veil/main.dart';

void main() {
  testWidgets('DARTH CHERRY shows idle Death Star when filter is off',
      (tester) async {
    await tester.pumpWidget(const DarthCherryApp());
    expect(find.text('DARTH CHERRY'), findsOneWidget);
    expect(find.text('ENABLE FILTER'), findsOneWidget);
    expect(find.byType(DeathStarDisplay), findsOneWidget);
    final star = tester.widget<DeathStarDisplay>(find.byType(DeathStarDisplay));
    expect(star.look, DeathStarLook.idle);
    expect(find.textContaining('Polybius'), findsNothing);
    expect(find.textContaining('eyeball'), findsNothing);
    expect(find.textContaining('plaintext'), findsNothing);
  });

  testWidgets('DeathStarDisplay accepts each look', (tester) async {
    for (final look in DeathStarLook.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: DeathStarDisplay(look: look, size: 120)),
          ),
        ),
      );
      expect(find.byType(DeathStarDisplay), findsOneWidget);
      final star =
          tester.widget<DeathStarDisplay>(find.byType(DeathStarDisplay));
      expect(star.look, look);
      await tester.pump(const Duration(milliseconds: 100));
    }
  });

  test('DeathStarLook covers idle / filterOn / matrix', () {
    expect(DeathStarLook.values, hasLength(3));
  });
}
