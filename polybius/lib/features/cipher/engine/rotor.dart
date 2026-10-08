import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/crypto/hkdf.dart';

/// Single rotor. Wiring is HMAC-shuffled; motion is odometer, not Enigma
/// notches. The notch is kept as cabinet flavour (and a UI readout) only —
/// double-stepping and "all rotors always step" are classical flaws we do
/// not reproduce.
class Rotor {
  Rotor({
    required this.name,
    required this.wiring,
    required this.notch,
    this.position = 0,
    this.stepCount = 0,
  });

  final String name;
  final List<int> wiring;
  final int notch;
  int position;
  int stepCount;

  static const int alphabetSize = AppConstants.halfPool;

  factory Rotor.create(String name, String dateKey, int offset) {
    final key = utf8Bytes('$dateKey::ROTOR::$name::$offset');
    final wiring = List<int>.generate(alphabetSize, (i) => i);
    for (var i = wiring.length - 1; i > 0; i--) {
      final block = hmacSha256(key, utf8Bytes('RW::$i'));
      var n = 0;
      for (final b in block.take(8)) {
        n = (n << 8) | b;
      }
      final j = n.remainder(i + 1).abs();
      final tmp = wiring[i];
      wiring[i] = wiring[j];
      wiring[j] = tmp;
    }
    final notchBlock = hmacSha256(key, utf8Bytes('NOTCH'));
    final notch = notchBlock[0] | (notchBlock[1] << 8);
    return Rotor(
      name: name,
      wiring: wiring,
      notch: notch % alphabetSize,
    );
  }

  /// Steps one position. Returns true when the wheel wraps to 0 (odometer carry).
  bool step() {
    position = (position + 1) % alphabetSize;
    stepCount++;
    return position == 0;
  }

  int forward(int input) {
    final shifted = (input + position) % alphabetSize;
    return wiring[shifted];
  }

  int backward(int input) {
    final index = wiring.indexOf(input);
    return (index - position + alphabetSize) % alphabetSize;
  }

  bool atNotch() => position == notch;

  Rotor copy() => Rotor(
        name: name,
        wiring: List.from(wiring),
        notch: notch,
        position: position,
        stepCount: stepCount,
      );
}

List<int> utf8Bytes(String s) => s.codeUnits;
