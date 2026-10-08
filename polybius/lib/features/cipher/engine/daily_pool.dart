import 'package:intl/intl.dart';
import 'package:polybius/features/cipher/engine/pool_manager.dart';

/// Date-or-seed entry point. The real work lives in [PoolManager].
class DailyPool {
  DailyPool({DateTime? date, String? seed})
      : key = seed ?? DateFormat('yyyy-MM-dd').format(date ?? DateTime.now()),
        _date = date;

  final String key;
  final DateTime? _date;

  String get dateKey => key;

  List<String> generate() =>
      PoolManager(seed: key, day: _date, at: _date).dailyDraw;

  static List<String> forDate(DateTime date) => DailyPool(date: date).generate();
  static List<String> forSeed(String seed) => DailyPool(seed: seed).generate();
}
