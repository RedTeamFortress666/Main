import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';
import 'package:polybius/features/cipher/engine/rotor.dart';

/// Multi-rotor Enigma variant: each plaintext char → 2 emojis from daily pool.
///
/// Emoji 1 encodes the rotor-transformed signal; emoji 2 encodes the original
/// character index for guaranteed round-trip decryption. All three rotors step
/// on every character processed.
class CipherEngine {
  CipherEngine({DateTime? date, String? seed, List<String>? pool, int complexity = 2})
      : _seed = seed ?? DailyPool(date: date).dateKey,
        _pool = pool ?? DailyPool(seed: seed, date: date).generate(),
        complexity = complexity < 2 ? 2 : (complexity > 6 ? 6 : complexity) {
    _resetRotors();
    _reflector = _buildReflector(_seed);
  }

  /// Emojis emitted per plaintext character (2–6). The first two carry the
  /// data; any extra are rotor-derived chaff for added obfuscation. Both
  /// sender and receiver must use the same value (carried in the pool-sync
  /// token), and it is never shown to non-dev users.
  final int complexity;

  /// Secret seed that fully determines the pool, rotors and reflector. Never
  /// surfaced in the UI; only [poolId] (a non-reversible short id) is shown.
  final String _seed;
  final List<String> _pool;
  late Rotor _rotorI;
  late Rotor _rotorII;
  late Rotor _rotorIII;
  late List<int> _reflector;

  static const String charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,!?-_:;@#\$%&*+/=';

  /// The seed itself (needed to build a shareable pool-sync token). Not shown
  /// in any UI.
  String get seed => _seed;

  /// Non-reversible short identifier for the active pool, safe to display.
  String get poolId =>
      sha256.convert(utf8.encode(_seed)).toString().substring(0, 12).toUpperCase();

  List<String> get pool => List.unmodifiable(_pool);

  List<Rotor> get rotors => [_rotorI, _rotorII, _rotorIII];

  /// Rotors are stateful and step on every character. Each encrypt/decrypt
  /// call restarts from the seed-derived initial position so a single shared
  /// engine instance round-trips correctly (matching the cross-device model
  /// where sender and receiver both start from the same pool seed).
  void _resetRotors() {
    _rotorI = Rotor.create('I', _seed, 0);
    _rotorII = Rotor.create('II', _seed, 1);
    _rotorIII = Rotor.create('III', _seed, 2);
  }

  List<int> _buildReflector(String dateKey) {
    final wiring = List<int>.generate(Rotor.alphabetSize, (i) => i);
    var seed = dateKey.hashCode;
    for (var i = wiring.length - 1; i > 0; i--) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final j = seed % (i + 1);
      final tmp = wiring[i];
      wiring[i] = wiring[j];
      wiring[j] = tmp;
    }
    for (var i = 0; i < wiring.length; i++) {
      if (wiring[wiring[i]] != i) {
        wiring[wiring[i]] = i;
      }
    }
    return wiring;
  }

  void _stepRotors() {
    if (_rotorIII.atNotch()) _rotorII.step();
    if (_rotorII.atNotch()) _rotorI.step();
    _rotorIII.step();
    _rotorII.step();
    _rotorI.step();
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

  String _toEmojiPair(int charIndex, int transformed) {
    final idx1 = transformed % AppConstants.halfPool;
    final idx2 = charIndex % AppConstants.halfPool;
    return '${_pool[idx1]}${_pool[idx2 + AppConstants.halfPool]}';
  }

  (int transformed, int charIndex)? _fromEmojiPair(String e1, String e2) {
    final idx1 = _pool.indexOf(e1);
    final idx2 = _pool.indexOf(e2) - AppConstants.halfPool;
    if (idx1 < 0 || idx2 < 0) return null;
    return (idx1, idx2);
  }

  /// Encrypt plaintext to an emoji sequence ([complexity] emojis per char).
  String encrypt(String plaintext) {
    _resetRotors();
    final buffer = StringBuffer();
    for (final rune in plaintext.runes) {
      final char = String.fromCharCode(rune);
      final charIndex = charset.indexOf(char);
      if (charIndex < 0) continue;
      _stepRotors();
      final transformed = _transform(charIndex);
      buffer.write(_toEmojiPair(charIndex, transformed));
      // Rotor-derived chaff emojis to reach the configured complexity.
      for (var j = 0; j < complexity - 2; j++) {
        final idx = (_rotorI.position + charIndex + j * 17) % AppConstants.halfPool;
        buffer.write(_pool[idx]);
      }
    }
    return buffer.toString();
  }

  /// Decrypt an emoji sequence back to plaintext. Reads [complexity]-emoji
  /// groups per character, using the first two and skipping any chaff.
  String decrypt(String emojiText) {
    _resetRotors();
    final runes = emojiText.runes.toList();
    final buffer = StringBuffer();
    var i = 0;
    while (i + complexity <= runes.length) {
      final e1 = String.fromCharCode(runes[i]);
      final e2 = String.fromCharCode(runes[i + 1]);
      i += complexity;
      final decoded = _fromEmojiPair(e1, e2);
      if (decoded == null) continue;
      final (transformed, charIndex) = decoded;
      _stepRotors();
      if (charIndex < charset.length && _transform(charIndex) == transformed) {
        buffer.write(charset[charIndex]);
      }
    }
    return buffer.toString();
  }

  CipherEngine clone() {
    final engine = CipherEngine(seed: _seed, pool: _pool, complexity: complexity);
    engine._rotorI = _rotorI.copy();
    engine._rotorII = _rotorII.copy();
    engine._rotorIII = _rotorIII.copy();
    return engine;
  }
}
