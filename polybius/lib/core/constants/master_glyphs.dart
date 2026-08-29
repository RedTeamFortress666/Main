import 'package:polybius/core/constants/emoji_pool.dart';

/// Unique single-codepoint glyphs for the daily master draw.
///
/// The mythos target is 5600. Unicode does not give us 5600 clean emoji
/// codepoints; this cabinet mixes the curated [emojiCorpus] with additional
/// pictograph / symbol blocks. Unassigned codepoints are skipped so the pool
/// tab does not fill with tofu. [size] is the honest count.
class MasterGlyphs {
  MasterGlyphs._();

  static List<String>? _cache;

  static const _ranges = <(int, int)>[
    (0x2300, 0x23FF), // Misc Technical
    (0x2600, 0x26FF), // Misc Symbols
    (0x2700, 0x27BF), // Dingbats
    (0x2B00, 0x2BFF), // Misc Symbols and Arrows
    (0x1F000, 0x1F02F), // Mahjong
    (0x1F0A0, 0x1F0FF), // Playing cards
    (0x1F300, 0x1F5FF), // Misc Symbols and Pictographs
    (0x1F600, 0x1F64F), // Emoticons
    (0x1F680, 0x1F6FF), // Transport
    (0x1F700, 0x1F77F), // Alchemical
    (0x1F780, 0x1F7FF), // Geometric Extended
    (0x1F800, 0x1F8FF), // Arrows Supplement
    (0x1F900, 0x1F9FF), // Supplemental Symbols
    (0x1FA00, 0x1FA6F), // Chess
    (0x1FA70, 0x1FAFF), // Symbols Extended-A
  ];

  static List<String> get all {
    final cached = _cache;
    if (cached != null) return cached;
    final seen = <int>{};
    final out = <String>[];

    void addRune(int code) {
      if (code <= 0x20) return;
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
}
