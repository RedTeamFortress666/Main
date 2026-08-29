import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';

void main() {
  final locked = DateTime.utc(2026, 7, 22, 0);

  group('DailyPool', () {
    test('generates exactly 560 unique emojis', () {
      final pool = DailyPool(date: locked).generate();
      expect(pool.length, AppConstants.poolSize);
      expect(pool.toSet().length, AppConstants.poolSize);
    });

    test('same date produces same pool', () {
      final date = DateTime(2026, 7, 22);
      final a = DailyPool(date: date).generate();
      final b = DailyPool(date: date).generate();
      expect(a, equals(b));
    });

    test('different dates produce different pools', () {
      final a = DailyPool(date: DateTime(2026, 7, 22)).generate();
      final b = DailyPool(date: DateTime(2026, 7, 23)).generate();
      expect(a, isNot(equals(b)));
    });
  });

  group('CipherEngine', () {
    late CipherEngine engine;

    setUp(() {
      engine = CipherEngine(date: locked, at: locked, stego: false);
    });

    test('encrypt produces emoji output', () {
      final result = engine.encrypt('HELLO');
      expect(result, isNotEmpty);
      expect(result.runes.length, 10); // 2 glyphs × 5 chars, no stego
    });

    test('encrypt then decrypt round-trips', () {
      const plaintext = 'Hello World 123!';
      final encrypted = engine.encrypt(plaintext);
      final decrypted = CipherEngine(
        date: locked,
        at: locked,
        stego: false,
      ).decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('fast rotor steps once per character; others wait for carry', () {
      engine.encrypt('ABC');
      expect(engine.rotors[2].stepCount, 3);
      expect(engine.rotors[1].stepCount, 0);
      expect(engine.rotors[0].stepCount, 0);
    });

    test('same engine instance round-trips encrypt then decrypt', () {
      const plaintext = 'MEET AT MIDNIGHT';
      final encrypted = engine.encrypt(plaintext);
      expect(engine.decrypt(encrypted), plaintext);
    });

    test('a prior encryption does not corrupt a later decryption', () {
      final cipherA = engine.encrypt('FIRST MESSAGE');
      engine.encrypt('NOISE THAT ADVANCES THE ROTORS');
      expect(engine.decrypt(cipherA), 'FIRST MESSAGE');
    });

    test('transform is reciprocal', () {
      const plaintext = 'Reciprocal Check 42';
      final encrypted = engine.encrypt(plaintext);
      expect(engine.decrypt(encrypted), plaintext);
    });

    test('second glyph is not the raw character index', () {
      final out = engine.encrypt('A');
      final e2 = String.fromCharCode(out.runes.elementAt(1));
      final leak = engine.pool[CipherEngine.charset.indexOf('A') +
          AppConstants.halfPool];
      expect(e2, isNot(equals(leak)));
    });

    test('stego decoys still round-trip', () {
      final noisy = CipherEngine(date: locked, at: locked);
      const plaintext = 'OPERATION MOCKINGBIRD';
      expect(noisy.decrypt(noisy.encrypt(plaintext)), plaintext);
    });

    test('3-glyph cabinet density round-trips', () {
      final cab = CipherEngine(
        date: locked,
        at: locked,
        stego: false,
        density: GlyphDensity.cabinet,
      );
      const plaintext = 'CABINET';
      final out = cab.encrypt(plaintext);
      expect(out.runes.length, plaintext.length * 3);
      expect(cab.decrypt(out), plaintext);
    });
  });
}
