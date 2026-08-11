import 'package:flutter_test/flutter_test.dart';
import 'package:polybius_flasher/main.dart';

void main() {
  testWidgets('flasher brand renders', (tester) async {
    await tester.pumpWidget(const PolybiusFlasherApp());
    await tester.pump();
    expect(find.textContaining('PØLYBÎŪS'), findsWidgets);
    expect(find.text('FLASHER'), findsOneWidget);
    expect(find.text('R36S'), findsOneWidget);
    expect(find.text('CYD ESP32-2432S028'), findsOneWidget);
    expect(find.text('LilyGO T-Deck'), findsOneWidget);
    expect(find.text('FLASH'), findsOneWidget);
  });
}
