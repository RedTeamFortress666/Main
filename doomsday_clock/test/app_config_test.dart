import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/app_config.dart';

void main() {
  tearDown(AppConfig.resetFlavorForTest);

  test('stable runtime flag', () {
    expect(AppConfig.isStable, isFalse);
    expect(AppConfig.isBunker, isTrue);
    AppConfig.enableStableRuntime();
    expect(AppConfig.isStable, isTrue);
    expect(AppConfig.isBunker, isFalse);
    expect(AppConfig.displayName, contains('stable'));
  });
}
