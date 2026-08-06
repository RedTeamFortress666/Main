import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';

void main() {
  group('Seed-based pool sharing', () {
    test('same seed yields identical pool + round-trips across instances', () {
      final a = CipherEngine(seed: 'pool-seed-alpha');
      final b = CipherEngine(seed: 'pool-seed-alpha');

      expect(a.pool, equals(b.pool));
      expect(a.poolId, equals(b.poolId));

      const plaintext = 'RENDEZVOUS AT 0300';
      final cipher = a.encrypt(plaintext);
      expect(b.decrypt(cipher), plaintext);
    });

    test('different seeds yield different pools', () {
      final a = CipherEngine(seed: 'seed-one');
      final b = CipherEngine(seed: 'seed-two');
      expect(a.poolId, isNot(equals(b.poolId)));
      expect(a.pool, isNot(equals(b.pool)));
    });
  });

  group('PoolSync token', () {
    test('encode/parse round-trips and verifies integrity', () {
      final token = PoolSync.fromSeed('shared-seed-123');
      final wire = token.encode();
      final parsed = PoolSync.tryParse(wire);

      expect(parsed, isNotNull);
      expect(parsed!.seed, 'shared-seed-123');
      expect(parsed.poolId, PoolSync.poolIdFor('shared-seed-123'));
      expect(parsed.isExpired, isFalse);
      expect(parsed.verifyIntegrity(), isTrue);
    });

    test('a tampered seed fails the integrity check', () {
      final token = PoolSync.fromSeed('genuine-seed');
      final tampered = PoolSync(
        poolId: token.poolId,
        seed: 'swapped-seed',
        expiresAt: token.expiresAt,
        emojiPoolHash: token.emojiPoolHash,
      );
      expect(tampered.verifyIntegrity(), isFalse);
    });

    test('an expired token is detected', () {
      final expired = PoolSync(
        poolId: 'X',
        seed: 's',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        emojiPoolHash: 'h',
      );
      expect(expired.isExpired, isTrue);
    });

    test('tryParse returns null for garbage', () {
      expect(PoolSync.tryParse('not-a-code'), isNull);
    });
  });
}
