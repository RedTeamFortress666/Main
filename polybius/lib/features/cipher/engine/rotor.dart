import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:polybius/core/constants/app_constants.dart';

/// Single Enigma-style rotor with date-seeded wiring.
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
    final seed = sha256.convert('$dateKey::$name::$offset'.codeUnits).bytes;
    final rng = Random(seed.fold<int>(0, (a, b) => a ^ b));
    final wiring = List<int>.generate(alphabetSize, (i) => i);
    wiring.shuffle(rng);
    final notch = rng.nextInt(alphabetSize);
    return Rotor(name: name, wiring: wiring, notch: notch);
  }

  void step() {
    position = (position + 1) % alphabetSize;
    stepCount++;
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
