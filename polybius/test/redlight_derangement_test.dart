import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/redlight/glyph_derangement.dart';
import 'package:polybius/features/redlight/vanishing_buffer.dart';

void main() {
  test('same pool/slot/pin is stable and a derangement', () {
    final a = GlyphDerangement(poolId: 'AABBCC', slot: 3, pin: '123456');
    final b = GlyphDerangement(poolId: 'AABBCC', slot: 3, pin: '123456');
    expect(a.table, equals(b.table));
    for (final ch in GlyphDerangement.letters.split('')) {
      expect(a.mapGlyph(ch), isNot(equals(ch)));
      expect(GlyphDerangement.letters.contains(a.mapGlyph(ch)), isTrue);
    }
    for (final ch in GlyphDerangement.digits.split('')) {
      expect(a.mapGlyph(ch), isNot(equals(ch)));
    }
  });

  test('slot or pin change remaps', () {
    final a = GlyphDerangement(poolId: 'AABBCC', slot: 3, pin: '123456');
    final b = GlyphDerangement(poolId: 'AABBCC', slot: 4, pin: '123456');
    final c = GlyphDerangement(poolId: 'AABBCC', slot: 3, pin: '000000');
    expect(a.table, isNot(equals(b.table)));
    expect(a.table, isNot(equals(c.table)));
  });

  test('vanishing buffer holds secret after flash wipe', () {
    final buf = VanishingBuffer(fadeMs: 10);
    buf.append('M');
    buf.append('K');
    expect(buf.plaintext, 'MK');
    expect(buf.flash, 'K');
    expect(buf.take(), 'MK');
    expect(buf.isEmpty, isTrue);
    expect(buf.flash, isEmpty);
  });
}
