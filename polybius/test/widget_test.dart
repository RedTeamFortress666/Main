import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/constants/app_constants.dart';

void main() {
  test('app name uses special characters', () {
    expect(AppConstants.appName, 'PØLYBĪUS');
  });
}
