import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/main.dart';

void main() {
  testWidgets('renders DOOMSDAY CLOCK brand', (tester) async {
    await tester.pumpWidget(const DoomsdayClockApp());
    expect(find.text('DOOMSDAY CLOCK 2.0'), findsOneWidget);
    expect(find.text('Bulletin'), findsOneWidget);
  });
}
