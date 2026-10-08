import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/app_config.dart';
import 'package:doomsday_clock/main.dart';

void main() {
  tearDown(AppConfig.resetFlavorForTest);

  testWidgets('renders bunker terminal login', (tester) async {
    await tester.pumpWidget(const DoomsdayClockApp());
    expect(find.textContaining('BUNKER'), findsWidgets);
    expect(find.textContaining('SPAMKAT2'), findsOneWidget);
  });

  test('bunker flavor by default', () {
    expect(AppConfig.isBunker, isTrue);
    expect(AppConfig.isStable, isFalse);
    expect(AppConfig.displayName, contains('BUNKER'));
  });
}
