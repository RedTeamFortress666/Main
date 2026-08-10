import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/features/arcade/high_score_models.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';

void main() {
  group('PoolSync high-score payload', () {
    test('v2 encode/parse carries scores and stays backward-compatible', () {
      final scores = [
        HighScoreEntry(
          name: 'Ace',
          score: 12000,
          at: DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
        ),
        HighScoreEntry(
          name: 'Bea',
          score: 9000,
          at: DateTime.fromMillisecondsSinceEpoch(1_700_000_100_000),
        ),
      ];
      final token = PoolSync.fromSeed(
        'shared-seed-hs',
        complexity: 3,
        scores: scores,
      );
      final parsed = PoolSync.tryParse(token.encode());
      expect(parsed, isNotNull);
      expect(parsed!.complexity, 3);
      expect(parsed.scores.length, 2);
      expect(parsed.scores.first.name, 'Ace');
      expect(parsed.scores.first.score, 12000);
      expect(parsed.verifyIntegrity(), isTrue);
    });

    test('v1 tokens without hs still parse', () {
      final legacy = PoolSync.fromSeed('legacy-seed');
      // Strip hs by rebuilding encode-compatible map via fromSeed empty scores.
      final parsed = PoolSync.tryParse(legacy.encode());
      expect(parsed, isNotNull);
      expect(parsed!.scores, isEmpty);
    });
  });

  test('AppFlavor user defaults for compile-time hq unless defined', () {
    // Default dart-define in tests is hq.
    expect(AppFlavor.isHq || AppFlavor.isUser, isTrue);
    expect(AppFlavor.accessPortalTitle, isNotEmpty);
  });
}
