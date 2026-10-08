import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/master_glyphs.dart';
import 'package:polybius/core/crypto/hkdf.dart';

/// Daily master draw + 2-hour active remapping.
///
/// * 24h: Fisher-Yates the master glyph cabinet with HMAC(seed || day).
/// * 2h: permute the 560-glyph active window with HMAC(seed || day || slot).
///
/// Slot clocks are UTC. Operators whose cabinets disagree on UTC will
/// desynchronise — that is intentional and preferable to leaking a
/// server-chosen mapping.
class PoolManager {
  PoolManager({required this.seed, DateTime? at, DateTime? day})
      : at = (at ?? day ?? DateTime.now()).toUtc() {
    _dayKey = DateFormat('yyyy-MM-dd').format(this.at);
    slot = this.at.hour ~/ AppConstants.remapHours;
  }

  final String seed;
  final DateTime at;
  late final String _dayKey;
  late final int slot;

  DateTime get slotEndsAt {
    final startHour = slot * AppConstants.remapHours;
    return DateTime.utc(at.year, at.month, at.day, startHour)
        .add(const Duration(hours: AppConstants.remapHours));
  }

  int get masterSize => MasterGlyphs.size;

  /// 560-glyph daily draw from the master cabinet (unique).
  List<String> get dailyDraw {
    final master = List<String>.from(MasterGlyphs.all);
    _hmacShuffle(master, utf8.encode('$seed::DAY::$_dayKey'));
    return master.take(AppConstants.poolSize).toList();
  }

  /// Remapped active window for the current 2-hour slot.
  List<String> get activePool {
    final draw = dailyDraw;
    _hmacShuffle(draw, utf8.encode('$seed::SLOT::$_dayKey::$slot'));
    return draw;
  }

  /// Unused master glyphs — decoy hieroglyphs that can sit between pairs.
  List<String> get stegoCabinet {
    final active = activePool.toSet();
    return MasterGlyphs.all.where((g) => !active.contains(g)).toList();
  }

  static String poolIdFor(String seed) =>
      sha256.convert(utf8.encode(seed)).toString().substring(0, 12).toUpperCase();

  static int slotOf(DateTime utc) => utc.toUtc().hour ~/ AppConstants.remapHours;

  /// Deterministic Fisher-Yates. Not a CSPRNG for key generation — it only
  /// needs to be seed-stable across operators.
  static void _hmacShuffle(List<String> items, List<int> key) {
    for (var i = items.length - 1; i > 0; i--) {
      final block = hmacSha256(key, utf8.encode('FY::$i'));
      var n = 0;
      for (final b in block.take(8)) {
        n = (n << 8) | b;
      }
      // Dart ints are arbitrary precision; keep the modulus positive.
      final j = n.remainder(i + 1).abs();
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }
}
