import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Multi-alphabet glyph sets used for pool share (steg / hieroglyph / sigil).
enum GlyphSet { steg, hieroglyph, sigil }

class GlyphAlphabets {
  GlyphAlphabets._();

  /// Steganographic blocks + braille dots.
  static const List<int> stegRunes = [
    0x2591, 0x2592, 0x2593, 0x2588, 0x2580, 0x2584, 0x25A0, 0x25A1,
    0x25AA, 0x25AB, 0x25CF, 0x25CB, 0x25E6, 0x2022, 0x2219, 0x00B7,
    0x2801, 0x2802, 0x2803, 0x2804, 0x2805, 0x2806, 0x2807, 0x2808,
    0x2809, 0x280A, 0x280B, 0x280C, 0x280D, 0x280E, 0x280F, 0x2810,
    0x2716, 0x2717, 0x271D, 0x2020, 0x2021, 0x00A4, 0x220E, 0x2302,
  ];

  /// Egyptian hieroglyphs + solar/lunar marks.
  static const List<int> hieroglyphRunes = [
    0x13000, 0x13079, 0x13080, 0x130C0, 0x130ED, 0x1313F, 0x13153,
    0x131A3, 0x131F3, 0x13216, 0x13250, 0x13296, 0x132BD, 0x132F9,
    0x13333, 0x1336F, 0x1339B, 0x133CF, 0x2625, 0x263D, 0x263E,
    0x2609, 0x2641, 0x2727,
  ];

  /// Runes + star sigils.
  static const List<int> sigilRunes = [
    0x16A0, 0x16A2, 0x16A6, 0x16A8, 0x16B1, 0x16B2, 0x16B7, 0x16B9,
    0x16BA, 0x16BE, 0x16C1, 0x16C3, 0x16C7, 0x16C8, 0x16C9, 0x16CA,
    0x16CB, 0x16CF, 0x16D2, 0x16D6, 0x16DA, 0x16DC, 0x16DE, 0x16DF,
    0x269C, 0x2694, 0x2696, 0x2726, 0x2727, 0x2729, 0x272A, 0x272B,
    0x272C, 0x272D, 0x272E, 0x272F, 0x2730, 0x2731,
  ];

  static List<String> glyphsFor(GlyphSet set) {
    final runes = switch (set) {
      GlyphSet.steg => stegRunes,
      GlyphSet.hieroglyph => hieroglyphRunes,
      GlyphSet.sigil => sigilRunes,
    };
    return [for (final r in runes) String.fromCharCode(r)];
  }

  static List<String> combined(Iterable<GlyphSet> sets) {
    final ordered = sets.toList()..sort((a, b) => a.name.compareTo(b.name));
    final seen = <String>{};
    final out = <String>[];
    for (final set in ordered) {
      for (final g in glyphsFor(set)) {
        if (seen.add(g)) out.add(g);
      }
    }
    return out;
  }
}

/// Seeded multi-alphabet pool + QR/share token (same seed → same glyphs).
class AlphabetPool {
  AlphabetPool({
    required this.seed,
    this.sets = const {GlyphSet.steg, GlyphSet.hieroglyph, GlyphSet.sigil},
  });

  final String seed;
  final Set<GlyphSet> sets;

  List<String> get glyphs {
    final corpus = GlyphAlphabets.combined(sets);
    final rng = _Seeded(sha256.convert(utf8.encode('alpha::$seed')).bytes);
    final shuffled = List<String>.from(corpus)..shuffle(rng);
    return shuffled;
  }

  String get poolId =>
      sha256.convert(utf8.encode(seed)).toString().substring(0, 10).toUpperCase();

  AlphabetPoolToken token({Duration window = const Duration(hours: 6)}) {
    final g = glyphs.join();
    return AlphabetPoolToken(
      seed: seed,
      sets: sets.toList()..sort((a, b) => a.name.compareTo(b.name)),
      expiresAt: DateTime.now().add(window),
      poolHash: sha256.convert(utf8.encode(g)).toString().substring(0, 16),
      poolId: poolId,
    );
  }

  static AlphabetPool randomise() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return AlphabetPool(seed: base64Url.encode(bytes));
  }
}

class AlphabetPoolToken {
  const AlphabetPoolToken({
    required this.seed,
    required this.sets,
    required this.expiresAt,
    required this.poolHash,
    required this.poolId,
  });

  final String seed;
  final List<GlyphSet> sets;
  final DateTime expiresAt;
  final String poolHash;
  final String poolId;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool verifyIntegrity() {
    final pool = AlphabetPool(seed: seed, sets: sets.toSet());
    return sha256
            .convert(utf8.encode(pool.glyphs.join()))
            .toString()
            .substring(0, 16) ==
        poolHash;
  }

  String encode() {
    final json = {
      'v': 2,
      'pid': poolId,
      's': seed,
      'a': sets.map((e) => e.name).toList(),
      'e': expiresAt.millisecondsSinceEpoch,
      'h': poolHash,
    };
    return base64Url.encode(utf8.encode(jsonEncode(json)));
  }

  static AlphabetPoolToken? tryParse(String raw) {
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(raw.trim())))
          as Map<String, dynamic>;
      final names = (decoded['a'] as List<dynamic>).cast<String>();
      final sets = [
        for (final n in names) GlyphSet.values.byName(n),
      ];
      return AlphabetPoolToken(
        seed: decoded['s'] as String,
        sets: sets,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(decoded['e'] as int),
        poolHash: decoded['h'] as String,
        poolId: decoded['pid'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  AlphabetPool toPool() => AlphabetPool(seed: seed, sets: sets.toSet());
}

class _Seeded implements Random {
  _Seeded(List<int> seed) : _state = seed.fold(0, (a, b) => a ^ b);

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
