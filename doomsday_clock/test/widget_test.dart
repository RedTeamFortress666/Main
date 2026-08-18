import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doomsday_clock/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots the journal', (tester) async {
    await tester.pumpWidget(const DoomsdayClockApp());
    await tester.pump();
    expect(find.text('DOØMSDAY CLØCK'), findsOneWidget);
    expect(find.text('Calendar / Journal'), findsOneWidget);
  });
}
