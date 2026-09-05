import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/crypto/unpredictable_shift.dart';

void main() {
  test('scramble is not a cyclic shift of the legend', () {
    final shift = UnpredictableShift(random: Random(7), columns: 5);
    final origin = PolybiusSquareGlyphs.keys;
    for (var i = 0; i < 40; i++) {
      final next = shift.scramble(origin, canonical: origin);
      expect(UnpredictableShift.isCyclicShiftOf(next, origin), isFalse);
    }
  });

  test('latin map stays in RAM and covers the charset', () {
    final shift = UnpredictableShift(random: Random(3), columns: 6);
    final glyphs = PolybiusSquareGlyphs.cherryKeys;
    const latin = [
      'A', 'B', 'C', 'D', 'E', 'F',
      'G', 'H', 'I', 'J', 'K', 'L',
      'M', 'N', 'O', 'P', 'Q', 'R',
      'S', 'T', 'U', 'V', 'W', 'X',
      'Y', 'Z', '0', '1', '2', '3',
      '4', '5', '6', '7', '8', '9',
    ];
    final map = shift.latinMap(glyphs, latin);
    expect(map.length, latin.length);
    expect(map.values.toSet().length, latin.length);
  });
}
