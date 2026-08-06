import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';

/// A compact pool-sync token shared between users (QR / copy / share) so both
/// derive an identical pool + rotor configuration and can encrypt/decrypt to
/// the same plaintext.
///
/// It carries a short-lived window (`expiresAt`) and an `emojiPoolHash`
/// (SHA-256 over the 560 emojis) for integrity. NOTE: because this build has no
/// server, the token also carries the pool `seed` so two offline peers can
/// align. That is a deliberate deviation from the server-fetch model where the
/// invitation carries only a pool id + signature and the mapping is fetched
/// separately — see the notes returned with this change.
class PoolSync {
  const PoolSync({
    required this.poolId,
    required this.seed,
    required this.expiresAt,
    required this.emojiPoolHash,
  });

  final String poolId;
  final String seed;
  final DateTime expiresAt;
  final String emojiPoolHash;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Recomputes the pool from the seed and confirms the hash matches.
  bool verifyIntegrity() => _poolHash(seed) == emojiPoolHash;

  String encode() {
    final json = {
      'v': 1,
      'pid': poolId,
      's': seed,
      'e': expiresAt.millisecondsSinceEpoch,
      'h': emojiPoolHash,
    };
    return base64Url.encode(utf8.encode(jsonEncode(json)));
  }

  static PoolSync? tryParse(String raw) {
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(raw.trim())))
          as Map<String, dynamic>;
      return PoolSync(
        poolId: decoded['pid'] as String,
        seed: decoded['s'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(decoded['e'] as int),
        emojiPoolHash: decoded['h'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// Builds a token for [seed] valid for [window] (default 6 hours, matching
  /// the intended 4–6h rotation).
  static PoolSync fromSeed(String seed, {Duration window = const Duration(hours: 6)}) {
    return PoolSync(
      poolId: poolIdFor(seed),
      seed: seed,
      expiresAt: DateTime.now().add(window),
      emojiPoolHash: _poolHash(seed),
    );
  }

  static String poolIdFor(String seed) =>
      sha256.convert(utf8.encode(seed)).toString().substring(0, 12).toUpperCase();

  static String _poolHash(String seed) {
    final pool = DailyPool(seed: seed).generate().join();
    return sha256.convert(utf8.encode(pool)).toString().substring(0, 16);
  }
}
