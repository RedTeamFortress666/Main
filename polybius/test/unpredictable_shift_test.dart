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
  group('PolybiusSquareGlyphs', () {
    test('keys are the non-space glyphs of A POLYBĪUS SQU\\R3', () {
      expect(PolybiusSquareGlyphs.phrase, r'A POLYBĪUS SQU\R3');
      expect(PolybiusSquareGlyphs.keys, [
        'A',
        'P',
        'O',
        'L',
        'Y',
        'B',
        'Ī',
        'U',
        'S',
        'S',
        'Q',
        'U',
        r'\',
        'R',
        '3',
      ]);
    });
  });

  group('UnpredictableShift detectors', () {
    test('rejects identity and cyclic index shifts', () {
      expect(UnpredictableShift.isStructuredShift([0, 1, 2, 3, 4]), isTrue);
      expect(UnpredictableShift.isStructuredShift([1, 2, 3, 4, 0]), isTrue);
      expect(UnpredictableShift.isStructuredShift([3, 4, 0, 1, 2]), isTrue);
    });

    test('rejects reverse', () {
      expect(UnpredictableShift.isStructuredShift([4, 3, 2, 1, 0]), isTrue);
    });

    test('rejects uniform row slides on a 5-wide grid', () {
      // Each of 3 rows rotated by +1.
      const perm = [
        1, 2, 3, 4, 0,
        6, 7, 8, 9, 5,
        11, 12, 13, 14, 10,
      ];
      expect(UnpredictableShift.isStructuredShift(perm, columns: 5), isTrue);
    });

    test('rejects uniform column slides on a 5-wide grid', () {
      // Rows rolled down by +1 (3 rows x 5 cols).
      const perm = [
        5, 6, 7, 8, 9,
        10, 11, 12, 13, 14,
        0, 1, 2, 3, 4,
      ];
      expect(UnpredictableShift.isStructuredShift(perm, columns: 5), isTrue);
    });

    test('accepts an irregular scramble', () {
      const perm = [3, 0, 14, 7, 1, 12, 4, 10, 2, 13, 6, 8, 5, 11, 9];
      expect(UnpredictableShift.isStructuredShift(perm, columns: 5), isFalse);
      expect(perm.toSet(), equals({for (var i = 0; i < 15; i++) i}));
    });

    test('detects cyclic shifts of the canonical legend', () {
      final origin = PolybiusSquareGlyphs.keys;
      final shifted = [
        ...origin.skip(4),
        ...origin.take(4),
      ];
      expect(UnpredictableShift.isCyclicShiftOf(shifted, origin), isTrue);
      expect(
        UnpredictableShift.isCyclicShiftOf(
          ['Y', 'B', 'Ī', ...origin.skip(3)],
          origin,
        ),
        isFalse,
      );
    });
  });

  group('UnpredictableShift scramble', () {
    test('pulse duration stays inside 0.8–1.3s', () {
      final shift = UnpredictableShift(random: Random(7));
      for (var i = 0; i < 200; i++) {
        final pulse = shift.nextPulse();
        expect(pulse.inMilliseconds, greaterThanOrEqualTo(800));
        expect(pulse.inMilliseconds, lessThanOrEqualTo(1300));
      }
    });

    test('scrambles never emit a shift-like relative map', () {
      final shift = UnpredictableShift(random: Random(99), columns: 5);
      final canonical = PolybiusSquareGlyphs.keys;
      var current = List<String>.from(canonical);
      for (var i = 0; i < 250; i++) {
        final next = shift.scramble(current, canonical: canonical);
        expect(
          next.toList()..sort(),
          equals(List<String>.from(canonical)..sort()),
        );

        final used = List<bool>.filled(current.length, false);
        final perm = <int>[];
        for (final glyph in next) {
          var src = -1;
          for (var i = 0; i < current.length; i++) {
            if (!used[i] && current[i] == glyph) {
              src = i;
              break;
            }
          }
          expect(src, isNonNegative);
          used[src] = true;
          perm.add(src);
        }
        expect(
          UnpredictableShift.isStructuredShift(perm, columns: 5),
          isFalse,
          reason: 'relative perm $perm from $current to $next',
        );
        expect(
          UnpredictableShift.isCyclicShiftOf(next, canonical),
          isFalse,
        );
        expect(
          UnpredictableShift.isGridSlideOf(next, canonical, columns: 5),
          isFalse,
        );
        current = next;
      }
    });

    test('spin rates are non-zero and not a single shared direction', () {
      final shift = UnpredictableShift(random: Random(3));
      final rates = [
        for (var i = 0; i < 20; i++) shift.nextSpinRadiansPerSecond(),
      ];
      expect(rates.every((r) => r != 0), isTrue);
      expect(rates.any((r) => r > 0), isTrue);
      expect(rates.any((r) => r < 0), isTrue);
    });
  });
}
