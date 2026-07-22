import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/emoji_pool.dart';

/// Generates the daily 560-emoji cipher pool seeded by calendar date.
class DailyPool {
  DailyPool({DateTime? date}) : _date = date ?? DateTime.now();

  final DateTime _date;

  String get dateKey => DateFormat('yyyy-MM-dd').format(_date);

  List<String> generate() {
    final seed = sha256.convert(dateKey.codeUnits).bytes;
    final rng = _SeededRandom(seed);
    final corpus = emojiCorpus
        .where((e) => e.runes.length == 1)
        .toList();
    corpus.shuffle(rng);
    return corpus.take(AppConstants.poolSize).toList();
  }

  static List<String> forDate(DateTime date) => DailyPool(date: date).generate();
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
