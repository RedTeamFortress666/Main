import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/app_config.dart';

void main() {
  tearDown(AppConfig.resetFlavorForTest);

  test('all-tier runtime flag', () {
    expect(AppConfig.isAllTier, isFalse);
    AppConfig.enableAllTierRuntime();
    expect(AppConfig.isAllTier, isTrue);
  });
}
