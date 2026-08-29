import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/features/cipher/engine/pool_manager.dart';

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
    this.slot = 0,
    this.dayKey,
    this.version = 2,
  });

  final String poolId;
  final String seed;
  final DateTime expiresAt;
  final String emojiPoolHash;
  final int slot;
  final String? dayKey;
  final int version;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  DateTime get _pinnedAt {
    final day = dayKey ?? DateFormat('yyyy-MM-dd').format(expiresAt.toUtc());
    final parts = day.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return DateTime.utc(y, m, d, slot * AppConstants.remapHours);
  }

  /// Recomputes the pinned slot's pool and confirms the hash matches.
  bool verifyIntegrity() => _poolHash(seed, at: _pinnedAt) == emojiPoolHash;

  String encode() {
    final json = {
      'v': version,
      'pid': poolId,
      's': seed,
      'e': expiresAt.millisecondsSinceEpoch,
      'h': emojiPoolHash,
      'slot': slot,
      'day': dayKey,
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
        slot: (decoded['slot'] as num?)?.toInt() ?? 0,
        dayKey: decoded['day'] as String?,
        version: (decoded['v'] as num?)?.toInt() ?? 1,
      );
    } catch (_) {
      return null;
    }
  }

  /// Builds a token for [seed]. Default window is the remainder of the
  /// current 2-hour slot (UTC), not a generous 6h — stale slots desync.
  static PoolSync fromSeed(String seed, {Duration? window, DateTime? at}) {
    final manager = PoolManager(seed: seed, at: at);
    return PoolSync(
      poolId: poolIdFor(seed),
      seed: seed,
      expiresAt: window == null
          ? manager.slotEndsAt
          : DateTime.now().add(window),
      emojiPoolHash: _poolHash(seed, at: at ?? manager.at),
      slot: manager.slot,
      dayKey: DateFormat('yyyy-MM-dd').format(manager.at),
    );
  }

  static String poolIdFor(String seed) =>
      sha256.convert(utf8.encode(seed)).toString().substring(0, 12).toUpperCase();

  static String _poolHash(String seed, {DateTime? at}) {
    final pool = PoolManager(seed: seed, at: at).activePool.join();
    return sha256.convert(utf8.encode(pool)).toString().substring(0, 16);
  }
}
