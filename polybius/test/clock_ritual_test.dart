import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/clock/alphabet_pool.dart';
import 'package:polybius/features/clock/clock_copy.dart';
import 'package:polybius/features/clock/clock_ritual.dart';
import 'package:polybius/features/clock/roman24.dart';

void main() {
  group('Roman24', () {
    test('maps 24-hour values onto I–XXIV', () {
      expect(Roman24.hour(0), 'XXIV');
      expect(Roman24.hour(5), 'V');
      expect(Roman24.hour(11), 'XI');
      expect(Roman24.hour(19), 'XIX');
      expect(Roman24.hour(24), 'XXIV');
    });

    test('formats 5:11 as V XI', () {
      expect(Roman24.format(5, 11), 'V XI');
    });
  });

  group('ClockRitual', () {
    test('opens the desk only at 5:11 + V XIXI + cherry glass', () {
      expect(
        ClockRitual.canOpenDesk(
          hour: 5,
          minute: 11,
          alarm: 'v  xixi',
          cherryActive: true,
        ),
        isTrue,
      );
      expect(
        ClockRitual.canOpenDesk(
          hour: 5,
          minute: 11,
          alarm: 'V XIXI',
          cherryActive: false,
        ),
        isFalse,
      );
      expect(
        ClockRitual.canOpenDesk(
          hour: 4,
          minute: 11,
          alarm: 'V XIXI',
          cherryActive: true,
        ),
        isFalse,
      );
      expect(
        ClockRitual.canOpenDesk(
          hour: 5,
          minute: 11,
          alarm: 'V XI',
          cherryActive: true,
        ),
        isFalse,
      );
    });

    test('hold and vanish timings', () {
      expect(ClockRitual.setAlarmHold, const Duration(seconds: 3));
      expect(ClockRitual.makeHold, const Duration(seconds: 2));
      expect(ClockRitual.vanishDelay, const Duration(milliseconds: 800));
      expect(ClockRitual.eternityHold, const Duration(seconds: 2));
      expect(ClockRitual.factoryPassword, 'oneeyedking');
    });
  });

  group('ClockCopy', () {
    test('desk notes never mention a concealed store', () {
      final lower = ClockCopy.deskNotes.toLowerCase();
      expect(lower.contains('vault'), isFalse);
      expect(lower.contains('hidden'), isFalse);
      expect(ClockCopy.deskNotes.contains('5:11'), isTrue);
      expect(ClockCopy.deskNotes.contains('V XIXI'), isTrue);
      expect(ClockCopy.deskNotes.contains('Darth Cherry'), isTrue);
    });
  });

  group('AlphabetPool', () {
    test('same seed and sets yield the same glyphs', () {
      final a = AlphabetPool(seed: 'desk-alpha');
      final b = AlphabetPool(seed: 'desk-alpha');
      expect(a.glyphs, equals(b.glyphs));
      expect(a.poolId, b.poolId);
      expect(a.glyphs, isNotEmpty);
    });

    test('token round-trips steg/hieroglyph/sigil sets', () {
      final pool = AlphabetPool(seed: 'share-me');
      final token = pool.token();
      final parsed = AlphabetPoolToken.tryParse(token.encode());
      expect(parsed, isNotNull);
      expect(parsed!.verifyIntegrity(), isTrue);
      expect(parsed.sets.toSet(), equals(pool.sets));
      expect(parsed.toPool().glyphs, equals(pool.glyphs));
    });

    test('tampered seed fails integrity', () {
      final token = AlphabetPool(seed: 'genuine').token();
      final bad = AlphabetPoolToken(
        seed: 'other',
        sets: token.sets,
        expiresAt: token.expiresAt,
        poolHash: token.poolHash,
        poolId: token.poolId,
      );
      expect(bad.verifyIntegrity(), isFalse);
    });
  });
}
