import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius_flasher/main.dart';

void main() {
  testWidgets('flasher brand renders with five targets', (tester) async {
    await tester.pumpWidget(const PolybiusFlasherApp());
    await tester.pump();
    expect(find.textContaining('PØLYBÎŪS'), findsWidgets);
    expect(find.text('FLASHER'), findsOneWidget);
    expect(find.text('R36S'), findsOneWidget);
    expect(find.text('CYD ESP32-2432S028'), findsOneWidget);
    expect(find.text('ESP32-32E 240×320 Resistive'), findsOneWidget);
    expect(find.text('LilyGO T-Deck'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ANDROID (OTG ADB)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ANDROID (OTG ADB)'), findsOneWidget);
    expect(find.text('FLASH'), findsOneWidget);
  });

  test('esp32e reuses CYD firmware defaults', () {
    expect(FlashTarget.esp32e.isEsp, isTrue);
    expect(FlashTarget.esp32e.defaultChip, 'esp32');
    expect(FlashTarget.esp32e.defaultBaud, 460800);
    expect(FlashTarget.esp32e.firmwareFileName, 'polybius-cyd.bin');
    expect(FlashTarget.tdeck.defaultChip, 'esp32s3');
  });

  test('androidOtg is not an ESP target', () {
    expect(FlashTarget.androidOtg.isEsp, isFalse);
    expect(FlashTarget.androidOtg.isAndroidOtg, isTrue);
    expect(FlashTarget.androidOtg.firmwareAsset, isEmpty);
  });
}
