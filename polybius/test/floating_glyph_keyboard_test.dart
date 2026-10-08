import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/crypto/unpredictable_shift.dart';
import 'package:polybius/core/widgets/floating_glyph_keyboard.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, height: 200, child: child),
      ),
    );
  }

  testWidgets('renders every Polybius-square glyph', (tester) async {
    final key = GlobalKey<FloatingGlyphKeyboardState>();
    await tester.pumpWidget(
      wrap(
        FloatingGlyphKeyboard(
          key: key,
          shift: UnpredictableShift(random: Random(1)),
        ),
      ),
    );
    await tester.pump();

    final shown = key.currentState!.glyphs;
    expect(shown.toList()..sort(), equals(PolybiusSquareGlyphs.keys.toList()..sort()));
    for (final glyph in shown.toSet()) {
      expect(find.text(glyph), findsWidgets);
    }
    expect(
      find.bySemanticsLabel('A POLYBĪUS SQU\\R3 floating glyph keyboard'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the same glyph bag after a fade pulse', (tester) async {
    final key = GlobalKey<FloatingGlyphKeyboardState>();
    final shift = UnpredictableShift(random: Random(21));
    await tester.pumpWidget(
      wrap(FloatingGlyphKeyboard(key: key, shift: shift)),
    );
    await tester.pump();
    final before = key.currentState!.glyphs;

    // One pulse is at most 1.3s; land past the first reshuffle.
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();

    final after = key.currentState!.glyphs;
    expect(after.toList()..sort(), equals(before.toList()..sort()));
    expect(after.length, PolybiusSquareGlyphs.keys.length);
  });

  testWidgets('interactive keys report the tapped glyph', (tester) async {
    String? tapped;
    final key = GlobalKey<FloatingGlyphKeyboardState>();
    await tester.pumpWidget(
      wrap(
        FloatingGlyphKeyboard(
          key: key,
          interactive: true,
          shift: UnpredictableShift(random: Random(4)),
          onGlyph: (g) => tapped = g,
        ),
      ),
    );
    // Mid-pulse so the key is visible enough to hit-test.
    await tester.pump(const Duration(milliseconds: 400));

    final target = key.currentState!.glyphs.first;
    await tester.tap(find.text(target).first);
    expect(tapped, target);
  });
}
