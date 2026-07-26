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
  });
}
