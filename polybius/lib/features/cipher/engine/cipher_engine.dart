import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/crypto/hkdf.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';
import 'package:polybius/features/cipher/engine/pool_manager.dart';
import 'package:polybius/features/cipher/engine/rotor.dart';

/// How many active-pool glyphs carry each plaintext character.
///
/// Compact (default) is 2: one whitened symbol + one integrity mix.
/// Cabinet is 3: the same pair plus an HMAC glyph. We do **not** go back to
/// 6 — that was waste. One glyph is possible (560 > charset) but leaves
/// almost no room for a checksum; 2–3 is the honest efficiency/diffusion
/// trade.
enum GlyphDensity { compact, cabinet }

/// Multi-rotor engine. Each charset character becomes 2 (or 3) pool glyphs.
///
/// Classical flaws we refuse to keep:
///   * The previous build stored the raw character index in emoji #2.
///     Anyone with the pool could read plaintext without the rotors.
///   * All three rotors stepped on every character, collapsing the period.
///   * Reflector construction used `String.hashCode` (VM-unstable).
///
/// This cabinet:
///   * Both (all) glyphs are functions of the rotor image + per-position HMAC.
///   * Decrypt inverts the reciprocal path; it never reads a stored index.
///   * Rotors step as an odometer (period alphabetSize³).
///   * Optional unused-master decoys sit between groups and re-roll per slot.
class CipherEngine {
  CipherEngine({
    DateTime? date,
    String? seed,
    List<String>? pool,
    DateTime? at,
    this.density = GlyphDensity.compact,
    this.stego = true,
  })  : _seed = seed ?? DailyPool(date: date).dateKey,
        _pool = pool ??
            PoolManager(
              seed: seed ?? DailyPool(date: date).dateKey,
              at: at ?? date,
              day: date,
            ).activePool,
        _manager = PoolManager(
          seed: seed ?? DailyPool(date: date).dateKey,
          at: at ?? date,
          day: date,
        ) {
    _resetRotors();
    _reflector = _buildReflector(_seed);
    _index = {for (var i = 0; i < _pool.length; i++) _pool[i]: i};
  }

  final String _seed;
  final List<String> _pool;
  final PoolManager _manager;
  final GlyphDensity density;
  final bool stego;
  late Rotor _rotorI;
  late Rotor _rotorII;
  late Rotor _rotorIII;
  late List<int> _reflector;
  late Map<String, int> _index;

  static const String charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,!?-_:;@#\$%&*+/=';

  String get seed => _seed;

  String get poolId =>
      sha256.convert(utf8.encode(_seed)).toString().substring(0, 12).toUpperCase();

  int get slot => _manager.slot;

  List<String> get pool => List.unmodifiable(_pool);

  List<Rotor> get rotors => [_rotorI, _rotorII, _rotorIII];

  int get glyphsPerChar => density == GlyphDensity.cabinet ? 3 : 2;

  void _resetRotors() {
    _rotorI = Rotor.create('I', _seed, 0);
    _rotorII = Rotor.create('II', _seed, 1);
    _rotorIII = Rotor.create('III', _seed, 2);
  }

  /// Fixed-point-free involution (paired wiring). Even alphabet required.
  List<int> _buildReflector(String seed) {
    final n = Rotor.alphabetSize;
    final perm = List<int>.generate(n, (i) => i);
    final key = utf8.encode('$seed::REFLECTOR');
    for (var i = perm.length - 1; i > 0; i--) {
      final block = hmacSha256(key, utf8.encode('RF::$i'));
      var v = 0;
      for (final b in block.take(8)) {
        v = (v << 8) | b;
      }
      final j = v.remainder(i + 1).abs();
      final tmp = perm[i];
      perm[i] = perm[j];
      perm[j] = tmp;
    }
    final wiring = List<int>.filled(n, 0);
    for (var i = 0; i < n; i += 2) {
      final a = perm[i];
      final b = perm[i + 1];
      wiring[a] = b;
      wiring[b] = a;
    }
    return wiring;
  }

  void _stepRotors() {
    final carryIII = _rotorIII.step();
    if (!carryIII) return;
    final carryII = _rotorII.step();
    if (carryII) {
      _rotorI.step();
    }
  }

  int _transform(int input) {
    var signal = _rotorI.forward(input);
    signal = _rotorII.forward(signal);
    signal = _rotorIII.forward(signal);
    signal = _reflector[signal % _reflector.length];
    signal = _rotorIII.backward(signal);
    signal = _rotorII.backward(signal);
    signal = _rotorI.backward(signal);
    return signal % Rotor.alphabetSize;
  }

  (int w1, int w2, int w3) _whiten(int pos) {
    final block = hmacSha256(utf8.encode(_seed), utf8.encode('WHITE::$pos'));
    int word(int o) => (block[o] << 8) | block[o + 1];
    return (word(0), word(2), word(4));
  }

  int _mod(int a, int m) {
    final r = a % m;
    return r < 0 ? r + m : r;
  }

  /// 3 is coprime to 560, so t → 3t is a bijection on the pool index ring.
  int _mix(int t) => _mod(t * 3, AppConstants.poolSize);

  String _encodeSymbol(int t, int pos) {
    final w = _whiten(pos);
    final idxA = _mod(t + w.$1, AppConstants.poolSize);
    final idxB = _mod(_mix(t) + w.$2, AppConstants.poolSize);
    final buf = StringBuffer()
      ..write(_pool[idxA])
      ..write(_pool[idxB]);
    if (density == GlyphDensity.cabinet) {
      final idxC = _mod(t + w.$3 + pos, AppConstants.poolSize);
      buf.write(_pool[idxC]);
    }
    return buf.toString();
  }

  int? _decodeSymbol(List<int> indices, int pos) {
    if (indices.length < 2) return null;
    final w = _whiten(pos);
    final t = _mod(indices[0] - w.$1, AppConstants.poolSize);
    if (t >= Rotor.alphabetSize) return null;
    final expectB = _mod(_mix(t) + w.$2, AppConstants.poolSize);
    if (expectB != indices[1]) return null;
    if (density == GlyphDensity.cabinet) {
      if (indices.length < 3) return null;
      final expectC = _mod(t + w.$3 + pos, AppConstants.poolSize);
      if (expectC != indices[2]) return null;
    }
    return t;
  }

  String _decoys(int pos) {
    if (!stego) return '';
    final cabinet = _manager.stegoCabinet;
    if (cabinet.isEmpty) return '';
    final block = hmacSha256(utf8.encode(_seed), utf8.encode('STEGO::$pos'));
    final count = block[0] % 3;
    final buf = StringBuffer();
    for (var i = 0; i < count; i++) {
      final idx = ((block[1 + i] << 8) | block[4 + i]) % cabinet.length;
      buf.write(cabinet[idx]);
    }
    return buf.toString();
  }

  /// Encrypt plaintext to an emoji sequence.
  String encrypt(String plaintext) {
    _resetRotors();
    final buffer = StringBuffer();
    var pos = 0;
    for (final rune in plaintext.runes) {
      final char = String.fromCharCode(rune);
      final charIndex = charset.indexOf(char);
      if (charIndex < 0) continue;
      _stepRotors();
      final transformed = _transform(charIndex);
      buffer.write(_encodeSymbol(transformed, pos));
      buffer.write(_decoys(pos));
      pos++;
    }
    return buffer.toString();
  }

  /// Decrypt emoji sequence back to plaintext.
  String decrypt(String emojiText) {
    _resetRotors();
    final needed = glyphsPerChar;
    final gathered = <int>[];
    final buffer = StringBuffer();
    var pos = 0;

    for (final rune in emojiText.runes) {
      final glyph = String.fromCharCode(rune);
      final idx = _index[glyph];
      if (idx == null) continue; // unused-master decoy or noise
      gathered.add(idx);
      if (gathered.length < needed) continue;
      final t = _decodeSymbol(gathered, pos);
      gathered.clear();
      if (t == null) continue;
      _stepRotors();
      final p = _transform(t);
      if (p >= 0 && p < charset.length) {
        buffer.write(charset[p]);
      }
      pos++;
    }
    return buffer.toString();
  }

  CipherEngine clone() {
    final engine = CipherEngine(
      seed: _seed,
      pool: _pool,
      density: density,
      stego: stego,
      at: _manager.at,
    );
    engine._rotorI = _rotorI.copy();
    engine._rotorII = _rotorII.copy();
    engine._rotorIII = _rotorIII.copy();
    return engine;
  }
}
