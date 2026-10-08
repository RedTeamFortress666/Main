import 'dart:convert';

import 'package:polybius/core/crypto/hkdf.dart';

/// Session-derived letter/digit remapping.
///
/// Seeded from pool ID + UTC 2-hour slot + operator PIN. Letters stay in
/// the letter alphabet; digits stay in digits — a derangement (no fixed
/// points) so a red-lamp observer never sees a key that types itself.
class GlyphDerangement {
  GlyphDerangement({
    required this.poolId,
    required this.slot,
    required this.pin,
  }) : _map = _build(poolId, slot, pin);

  final String poolId;
  final int slot;
  final String pin;
  final Map<String, String> _map;

  static const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const digits = '0123456789';

  static Map<String, String> _build(String poolId, int slot, String pin) {
    final key = utf8.encode('$poolId::$slot::$pin::REDLIGHT');
    final map = <String, String>{};
    void derange(String alphabet, String domain) {
      final items = alphabet.split('');
      _shuffle(items, key, domain);
      _breakFixedPoints(items, alphabet);
      for (var i = 0; i < alphabet.length; i++) {
        map[alphabet[i]] = items[i];
      }
    }

    derange(letters, 'L');
    derange(digits, 'D');
    return map;
  }

  static void _shuffle(List<String> items, List<int> key, String domain) {
    for (var i = items.length - 1; i > 0; i--) {
      final block = hmacSha256(key, utf8.encode('$domain::$i'));
      var n = 0;
      for (final b in block.take(4)) {
        n = (n << 8) | b;
      }
      final j = n.remainder(i + 1).abs();
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }

  /// Rotate any leftover fixed points with the next index (Sattolo-ish).
  static void _breakFixedPoints(List<String> items, String alphabet) {
    for (var i = 0; i < items.length; i++) {
      if (items[i] == alphabet[i]) {
        final j = (i + 1) % items.length;
        final tmp = items[i];
        items[i] = items[j];
        items[j] = tmp;
      }
    }
    // Last-pair swap can reintroduce a single fixed point on odd cycles;
    // one more pass is enough for these alphabets.
    for (var i = 0; i < items.length; i++) {
      if (items[i] == alphabet[i]) {
        final j = (i + 1) % items.length;
        final tmp = items[i];
        items[i] = items[j];
        items[j] = tmp;
      }
    }
  }

  String mapGlyph(String raw) {
    if (raw.isEmpty) return raw;
    final ch = raw.toUpperCase();
    return _map[ch] ?? raw;
  }

  /// House-lights key → cabinet character (uppercase in, charset-aware out).
  String type(String physical, {required bool shift}) {
    final mapped = mapGlyph(physical);
    if (letters.contains(physical.toUpperCase())) {
      return shift ? mapped : mapped.toLowerCase();
    }
    return mapped;
  }

  Map<String, String> get table => Map.unmodifiable(_map);
}
