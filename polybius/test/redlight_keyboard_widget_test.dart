import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/redlight/glyph_derangement.dart';
import 'package:polybius/features/redlight/redlight_keyboard.dart';
import 'package:polybius/features/redlight/vanishing_buffer.dart';
import 'package:polybius/features/redlight/vanishing_field.dart';

void main() {
  testWidgets('house lights type QWERTY into the vanishing buffer',
      (tester) async {
    final buffer = VanishingBuffer();
    final derange = GlyphDerangement(poolId: 'TEST', slot: 0, pin: 'DEV');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RedlightKeyboard(
            derangement: derange,
            buffer: buffer,
            lampOn: false,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('cabinet-key-H')));
    await tester.pump();
    expect(buffer.plaintext, 'h');
  });

  testWidgets('cabinet lamp types the phosphor derangement', (tester) async {
    final buffer = VanishingBuffer();
    final derange = GlyphDerangement(poolId: 'TEST', slot: 0, pin: 'DEV');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RedlightKeyboard(
            derangement: derange,
            buffer: buffer,
            lampOn: true,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('cabinet-key-H')));
    await tester.pump();
    expect(buffer.plaintext, isNotEmpty);
    expect(buffer.plaintext, isNot(equals('h')));
    expect(buffer.plaintext, isNot(equals('H')));
    expect(buffer.plaintext, derange.type('H', shift: false));
  });

  testWidgets('vanishing field shows the flash glyph', (tester) async {
    final buffer = VanishingBuffer(fadeMs: 50);
    buffer.append('X');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VanishingField(buffer: buffer)),
      ),
    );
    expect(find.text('X'), findsOneWidget);
    expect(find.text('PLAINTEXT'), findsOneWidget);
  });
}
