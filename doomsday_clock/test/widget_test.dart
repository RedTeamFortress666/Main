import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/main.dart';

void main() {
  testWidgets('renders vault login brand', (tester) async {
    await tester.pumpWidget(const DoomsdayClockApp());
    expect(find.textContaining('DOOMSDAY CLOCK 2.0'), findsWidgets);
    expect(find.textContaining('VAULT LOGIN'), findsOneWidget);
  });
}
