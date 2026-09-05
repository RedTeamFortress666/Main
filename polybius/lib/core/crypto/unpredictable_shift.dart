import 'dart:math';

/// Glyphs for the floating Polybius-square keyboard (Darth Cherry v3).
class PolybiusSquareGlyphs {
  static const String phrase = r'A POLYBĪUS SQU\R3';

  static List<String> get keys => [
        for (final rune in phrase.runes)
          if (rune != 0x20) String.fromCharCode(rune),
      ];

  /// Visual-only keycaps used by the disappearing keyboard. Mapping to latin
  /// characters lives in RAM for the current pulse and is never serialized.
  static const List<int> cherryRunes = [
    0x16A0, 0x16A2, 0x16A6, 0x16A8, 0x16B1, 0x16B2, 0x16B7, 0x16B9,
    0x16BA, 0x16BE, 0x16C1, 0x16C3, 0x16C7, 0x16C8, 0x16C9, 0x16CA,
    0x16CB, 0x16CF, 0x16D2, 0x16D6, 0x16DA, 0x16DC, 0x16DE, 0x16DF,
    0x2591, 0x2592, 0x2593, 0x2588, 0x25CF, 0x25C9, 0x2726, 0x2727,
    0x272A, 0x2730, 0x269C, 0x2620,
  ];

  static List<String> get cherryKeys => [
        for (final r in cherryRunes) String.fromCharCode(r),
      ];
}

/// Keyboard rearrangements that cannot be read as a "next shift".
class UnpredictableShift {
  UnpredictableShift({
    Random? random,
    this.columns = 6,
    this.maxAttempts = 64,
  }) : _rng = random ?? Random.secure();

  final Random _rng;
  final int columns;
  final int maxAttempts;

  static const Duration minPulse = Duration(milliseconds: 800);
  static const Duration maxPulse = Duration(milliseconds: 1300);

  List<int>? _lastRelative;

  Duration nextPulse() {
    final span = maxPulse.inMilliseconds - minPulse.inMilliseconds;
    return Duration(
      milliseconds: minPulse.inMilliseconds + _rng.nextInt(span + 1),
    );
  }

  double nextSpinRadiansPerSecond() {
    final speed = 1.4 + _rng.nextDouble() * 2.8;
    return _rng.nextBool() ? speed : -speed;
  }

  List<int> nextPermutation(int n) {
    if (n <= 1) return [0];
    var perm = _fisherYates(n);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      perm = _fisherYates(n);
      if (isStructuredShift(perm, columns: columns)) continue;
      if (_lastRelative != null && _same(perm, _lastRelative!)) continue;
      _lastRelative = List<int>.from(perm);
      return perm;
    }
    _lastRelative = List<int>.from(perm);
    return perm;
  }

  List<T> scramble<T>(List<T> current, {List<T>? canonical}) {
    final n = current.length;
    if (n <= 1) return List<T>.from(current);

    var perm = _fisherYates(n);
    var next = [for (final i in perm) current[i]];
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      perm = _fisherYates(n);
      if (isStructuredShift(perm, columns: columns)) continue;
      if (_lastRelative != null && _same(perm, _lastRelative!)) continue;
      next = [for (final i in perm) current[i]];
      if (canonical != null && isCyclicShiftOf(next, canonical)) continue;
      if (canonical != null &&
          isGridSlideOf(next, canonical, columns: columns)) {
        continue;
      }
      _lastRelative = List<int>.from(perm);
      return next;
    }
    _lastRelative = List<int>.from(perm);
    return next;
  }

  /// Pair visual glyphs with latin letters for this pulse only.
  Map<String, String> latinMap(List<String> glyphs, List<String> latin) {
    final n = min(glyphs.length, latin.length);
    final order = scramble(List<int>.generate(n, (i) => i));
    return {
      for (var i = 0; i < n; i++) glyphs[i]: latin[order[i]],
    };
  }

  List<int> _fisherYates(int n) {
    final a = List<int>.generate(n, (i) => i);
    for (var i = n - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = a[i];
      a[i] = a[j];
      a[j] = tmp;
    }
    return a;
  }

  static bool isStructuredShift(List<int> perm, {int columns = 6}) {
    if (perm.isEmpty) return true;
    if (_isCyclicIndexShift(perm)) return true;
    if (_isReverse(perm)) return true;
    if (_isGridRowSlide(perm, columns)) return true;
    if (_isGridColumnSlide(perm, columns)) return true;
    return false;
  }

  static bool isCyclicShiftOf<T>(List<T> candidate, List<T> origin) {
    final n = origin.length;
    if (candidate.length != n || n == 0) return false;
    for (var k = 0; k < n; k++) {
      var match = true;
      for (var i = 0; i < n; i++) {
        if (candidate[i] != origin[(i + k) % n]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }

  static bool isGridSlideOf<T>(
    List<T> candidate,
    List<T> origin, {
    int columns = 6,
  }) {
    final n = origin.length;
    if (candidate.length != n || columns <= 0 || n % columns != 0) {
      return false;
    }
    final rows = n ~/ columns;
    for (var k = 0; k < columns; k++) {
      var match = true;
      for (var i = 0; i < n; i++) {
        final row = i ~/ columns;
        final col = i % columns;
        final src = row * columns + (col + k) % columns;
        if (candidate[i] != origin[src]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    for (var k = 0; k < rows; k++) {
      var match = true;
      for (var i = 0; i < n; i++) {
        final row = i ~/ columns;
        final col = i % columns;
        final src = ((row + k) % rows) * columns + col;
        if (candidate[i] != origin[src]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }

  static bool _isCyclicIndexShift(List<int> perm) {
    final n = perm.length;
    final offset = perm[0] % n;
    for (var i = 0; i < n; i++) {
      if (perm[i] != (i + offset) % n) return false;
    }
    return true;
  }

  static bool _isReverse(List<int> perm) {
    final n = perm.length;
    for (var i = 0; i < n; i++) {
      if (perm[i] != n - 1 - i) return false;
    }
    return true;
  }

  static bool _isGridRowSlide(List<int> perm, int columns) {
    final n = perm.length;
    if (columns <= 1 || n % columns != 0) return false;
    final offset = (perm[0] - 0) % columns;
    if (perm[0] ~/ columns != 0) return false;
    for (var i = 0; i < n; i++) {
      final row = i ~/ columns;
      final col = i % columns;
      final expected = row * columns + (col + offset) % columns;
      if (perm[i] != expected) return false;
    }
    return true;
  }

  static bool _isGridColumnSlide(List<int> perm, int columns) {
    final n = perm.length;
    if (columns <= 0 || n % columns != 0) return false;
    final rows = n ~/ columns;
    if (rows <= 1) return false;
    if (perm[0] % columns != 0) return false;
    final offsetRows = perm[0] ~/ columns;
    for (var i = 0; i < n; i++) {
      final row = i ~/ columns;
      final col = i % columns;
      final expected = ((row + offsetRows) % rows) * columns + col;
      if (perm[i] != expected) return false;
    }
    return true;
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
