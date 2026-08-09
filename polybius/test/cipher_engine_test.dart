import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';

void main() {
  group('DailyPool', () {
    test('generates exactly 560 unique emojis', () {
      final pool = DailyPool().generate();
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
      engine = CipherEngine(date: DateTime(2026, 7, 22));
    });

    test('encrypt produces emoji output', () {
      final result = engine.encrypt('HELLO');
      expect(result, isNotEmpty);
      expect(result.runes.length, greaterThan(4));
    });

    test('encrypt then decrypt round-trips', () {
      const plaintext = 'Hello World 123!';
      final encrypted = engine.encrypt(plaintext);
      final decrypted = CipherEngine(
        date: DateTime(2026, 7, 22),
      ).decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('rotors step on each character', () {
      engine.encrypt('ABC');
      expect(engine.rotors[0].stepCount, 3);
      expect(engine.rotors[1].stepCount, 3);
      expect(engine.rotors[2].stepCount, 3);
    });

    test('same engine instance round-trips encrypt then decrypt', () {
      const plaintext = 'MEET AT MIDNIGHT';
      final encrypted = engine.encrypt(plaintext);
      // Decrypt on the SAME instance (as the app's shared provider does).
      expect(engine.decrypt(encrypted), plaintext);
    });

    test('a prior encryption does not corrupt a later decryption', () {
      final cipherA = engine.encrypt('FIRST MESSAGE');
      // Advancing the rotors with more work must not break decoding cipherA.
      engine.encrypt('NOISE THAT ADVANCES THE ROTORS');
      expect(engine.decrypt(cipherA), 'FIRST MESSAGE');
    });

    test('round-trips at every rotor complexity 2..6 and emits N per char', () {
      const plaintext = 'MEET AT 0300';
      final expectedChars = plaintext
          .split('')
          .where((c) => CipherEngine.charset.contains(c))
          .length;
      for (var c = 2; c <= 6; c++) {
        final e = CipherEngine(seed: 'complexity-seed', complexity: c);
        final cipher = e.encrypt(plaintext);
        // Each accepted character produces exactly `c` emoji runes.
        expect(cipher.runes.length, expectedChars * c);
        final d = CipherEngine(seed: 'complexity-seed', complexity: c);
        expect(d.decrypt(cipher), plaintext);
      }
    });

    test('complexity is clamped to 2..6', () {
      expect(CipherEngine(seed: 's', complexity: 0).complexity, 2);
      expect(CipherEngine(seed: 's', complexity: 9).complexity, 6);
    });
  });
}
