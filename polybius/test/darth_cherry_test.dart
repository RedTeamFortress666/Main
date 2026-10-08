import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/constants/unlock_codes.dart';

void main() {
  test('Darth Cherry codes are recognised, others are not', () {
    expect(UnlockCodes.isDarthCherry('DARTH-CHERRY'), isTrue);
    expect(UnlockCodes.isDarthCherry('darth-cherry'), isTrue);
    expect(UnlockCodes.isDarthCherry(' CH3-RRY '), isTrue);
    expect(UnlockCodes.isDarthCherry('B1-66-3R'), isFalse);
    expect(UnlockCodes.isDarthCherry(''), isFalse);
  });
}
