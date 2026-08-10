import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/main.dart';

void main() {
  testWidgets('renders vault login brand', (tester) async {
    await tester.pumpWidget(const DoomsdayClockApp());
    expect(find.textContaining('DOØMSDAY CLØCK'), findsWidgets);
    expect(find.textContaining('VAULT LOGIN'), findsOneWidget);
  });
}
