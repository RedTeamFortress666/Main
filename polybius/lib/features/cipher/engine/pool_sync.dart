import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:polybius/features/arcade/high_score_models.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';

/// A compact pool-sync token shared between users (QR / copy / share) so both
/// derive an identical pool + rotor configuration and can encrypt/decrypt to
/// the same plaintext.
///
/// v2 also carries arcade high scores so peers merge competitive boards when
/// they align pools.
class PoolSync {
  const PoolSync({
    required this.poolId,
    required this.seed,
    required this.expiresAt,
    required this.emojiPoolHash,
    this.complexity = 2,
    this.scores = const [],
  });

  final String poolId;
  final String seed;
  final DateTime expiresAt;
  final String emojiPoolHash;

  /// Rotor complexity (2–6) so aligned users match emojis-per-character.
  final int complexity;

  /// Optional high-score board snapshot exchanged with the pool.
  final List<HighScoreEntry> scores;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Recomputes the pool from the seed and confirms the hash matches.
  bool verifyIntegrity() => _poolHash(seed) == emojiPoolHash;

  String encode() {
    final json = {
      'v': 2,
      'pid': poolId,
      's': seed,
      'e': expiresAt.millisecondsSinceEpoch,
      'h': emojiPoolHash,
      'c': complexity,
      if (scores.isNotEmpty)
        'hs': [for (final e in scores.take(15)) e.toJson()],
    };
    return base64Url.encode(utf8.encode(jsonEncode(json)));
  }

  static PoolSync? tryParse(String raw) {
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(raw.trim())))
          as Map<String, dynamic>;
      final hsRaw = decoded['hs'];
      final scores = <HighScoreEntry>[];
      if (hsRaw is List) {
        for (final e in hsRaw) {
          if (e is Map) {
            scores.add(
              HighScoreEntry.fromJson(
                Map<String, dynamic>.from(
                  e.map((k, v) => MapEntry(k.toString(), v)),
                ),
              ),
            );
          }
        }
      }
      return PoolSync(
        poolId: decoded['pid'] as String,
        seed: decoded['s'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(decoded['e'] as int),
        emojiPoolHash: decoded['h'] as String,
        complexity: (decoded['c'] as int?) ?? 2,
        scores: scores,
      );
    } catch (_) {
      return null;
    }
  }

  /// Builds a token for [seed] valid for [window] (default 6 hours, matching
  /// the intended 4–6h rotation).
  static PoolSync fromSeed(
    String seed, {
    Duration window = const Duration(hours: 6),
    int complexity = 2,
    List<HighScoreEntry> scores = const [],
  }) {
    return PoolSync(
      poolId: poolIdFor(seed),
      seed: seed,
      expiresAt: DateTime.now().add(window),
      emojiPoolHash: _poolHash(seed),
      complexity: complexity,
      scores: scores,
    );
  }

  static String poolIdFor(String seed) =>
      sha256.convert(utf8.encode(seed)).toString().substring(0, 12).toUpperCase();

  static String _poolHash(String seed) {
    final pool = DailyPool(seed: seed).generate().join();
    return sha256.convert(utf8.encode(pool)).toString().substring(0, 16);
  }
}
