import 'package:polybius/core/constants/emoji_pool.dart';

/// Unique single-codepoint glyphs for the daily master draw.
///
/// The mythos target is 5600. Unicode does not give us 5600 clean emoji
/// codepoints. This cabinet uses the curated [emojiCorpus] plus densely
/// assigned emoji blocks. Unassigned, control, modifier, and letter-like
/// runes are skipped so the pool tab does not fill with tofu. [size] is
/// the honest count.
class MasterGlyphs {
  MasterGlyphs._();

  static List<String>? _cache;

  /// Assigned emoji / pictograph blocks only. Misc Technical, dingbats,
  /// arrows, mahjong holes, and alchemical leftovers are left out — those
  /// ranges are where web fonts print tofu or "AA".
  static const _ranges = <(int, int)>[
    (0x1F300, 0x1F5FF), // Misc Symbols and Pictographs
    (0x1F600, 0x1F64F), // Emoticons
    (0x1F680, 0x1F6FF), // Transport
    (0x1F900, 0x1F9FF), // Supplemental Symbols
    (0x1FA70, 0x1FAFF), // Symbols Extended-A
  ];

  static bool isUsable(int code) {
    if (code <= 0x7F) return false;
    if (code >= 0x80 && code <= 0x9F) return false;
    if (code >= 0x0300 && code <= 0x036F) return false;
    if (code == 0x200D || code == 0xFE0F || code == 0xFE0E) return false;
    if (code >= 0xFE00 && code <= 0xFE0F) return false;
    if (code >= 0x1F3FB && code <= 0x1F3FF) return false; // skin tones
    if (code >= 0xE0020 && code <= 0xE007F) return false; // tags
    if (code >= 0x20D0 && code <= 0x20FF) return false; // combining marks
    return true;
  }

  static List<String> get all {
    final cached = _cache;
    if (cached != null) return cached;
    final seen = <int>{};
    final out = <String>[];

    void addRune(int code) {
      if (!isUsable(code)) return;
      if (!seen.add(code)) return;
      out.add(String.fromCharCode(code));
    }

    for (final e in emojiCorpus) {
      final runes = e.runes.toList();
      if (runes.length == 1) addRune(runes.first);
    }
    for (final (start, end) in _ranges) {
      for (var c = start; c <= end; c++) {
        addRune(c);
      }
    }
    return _cache = List.unmodifiable(out);
  }

  static int get size => all.length;

  /// Count of cached glyphs that fail [isUsable]. Zero after the filter.
  static int get junkCount => all.where((g) {
        final runes = g.runes.toList();
        return runes.length != 1 || !isUsable(runes.first);
      }).length;
}
