import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:polybius/core/constants/emoji_pool.dart';

/// Generates the 560-emoji cipher pool from a seed key. The seed is normally
/// the calendar date, but can be any string so a randomised pool can be shared
/// between users (they derive an identical pool from the same seed).
class DailyPool {
  DailyPool({DateTime? date, String? seed})
      : key = seed ?? DateFormat('yyyy-MM-dd').format(date ?? DateTime.now());

  /// The seed key that fully determines the pool ordering.
  final String key;

  /// Kept for back-compat; equals the seed key.
  String get dateKey => key;

  List<String> generate() {
    final seed = sha256.convert(utf8.encode(key)).bytes;
    final rng = _SeededRandom(seed);
    final corpus = emojiCorpus
        .where((e) => e.runes.length == 1)
        .toList();
    corpus.shuffle(rng);
        return corpus.take(560).toList();
  }

  static List<String> forDate(DateTime date) => DailyPool(date: date).generate();
  static List<String> forSeed(String seed) => DailyPool(seed: seed).generate();
}

class _SeededRandom implements Random {
  _SeededRandom(List<int> seed) : _state = seed.fold(0, (a, b) => a ^ b);

  int _state;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => nextInt(1 << 32) / (1 << 32);

  @override
  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }
}
