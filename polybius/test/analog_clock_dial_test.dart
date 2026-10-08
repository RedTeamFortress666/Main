import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/clock/widgets/analog_clock_dial.dart';

void main() {
  testWidgets('analog dial exposes 5:11 for the set face', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnalogClockDial(hour: 5, minute: 11),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Analog face 05:11'), findsOneWidget);
  });
}
