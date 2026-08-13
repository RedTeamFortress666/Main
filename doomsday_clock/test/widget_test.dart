import 'package:flutter_test/flutter_test.dart';
import 'package:doomsday_clock/main.dart';

void main() {
  testWidgets('renders cyber terminal login', (tester) async {
    await tester.pumpWidget(const DoomsdayClockApp());
    expect(find.textContaining('CLØCK'), findsWidgets);
    expect(find.textContaining('CYBER TERMINAL'), findsOneWidget);
  });
}
