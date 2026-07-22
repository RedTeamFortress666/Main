import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';
import 'package:polybius/features/cipher/engine/rotor.dart';

/// Multi-rotor Enigma variant: each plaintext char → 2 emojis from daily pool.
///
/// Emoji 1 encodes the rotor-transformed signal; emoji 2 encodes the original
/// character index for guaranteed round-trip decryption. All three rotors step
/// on every character processed.
class CipherEngine {
  CipherEngine({DateTime? date, List<String>? pool})
      : _dateKey = DailyPool(date: date).dateKey,
        _pool = pool ?? DailyPool(date: date).generate() {
    _rotorI = Rotor.create('I', _dateKey, 0);
    _rotorII = Rotor.create('II', _dateKey, 1);
    _rotorIII = Rotor.create('III', _dateKey, 2);
    _reflector = _buildReflector(_dateKey);
  }

  final String _dateKey;
  final List<String> _pool;
  late Rotor _rotorI;
  late Rotor _rotorII;
  late Rotor _rotorIII;
  late List<int> _reflector;

  static const String charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,!?-_:;@#\$%&*+/=';

  String get dateKey => _dateKey;
  List<String> get pool => List.unmodifiable(_pool);

  List<Rotor> get rotors => [_rotorI, _rotorII, _rotorIII];

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

  /// Encrypt plaintext to emoji sequence (2 emojis per character).
  String encrypt(String plaintext) {
    final buffer = StringBuffer();
    for (final rune in plaintext.runes) {
      final char = String.fromCharCode(rune);
      final charIndex = charset.indexOf(char);
      if (charIndex < 0) continue;
      _stepRotors();
      final transformed = _transform(charIndex);
      buffer.write(_toEmojiPair(charIndex, transformed));
    }
    return buffer.toString();
  }

  /// Decrypt emoji sequence back to plaintext.
  String decrypt(String emojiText) {
    final runes = emojiText.runes.toList();
    final buffer = StringBuffer();
    var i = 0;
    while (i + 1 < runes.length) {
      final e1 = String.fromCharCode(runes[i]);
      final e2 = String.fromCharCode(runes[i + 1]);
      i += 2;
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
    final engine = CipherEngine(date: DateTime.parse(_dateKey), pool: _pool);
    engine._rotorI = _rotorI.copy();
    engine._rotorII = _rotorII.copy();
    engine._rotorIII = _rotorIII.copy();
    return engine;
  }
}
