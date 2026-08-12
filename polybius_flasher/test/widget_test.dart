import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius_flasher/flasher_bridge.dart';
import 'package:polybius_flasher/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  test('core suite bundles Portal, V.1 USER, and Darth Cherry', () {
    expect(FlasherBridge.coreSuiteIds, ['portal_hq', 'v1_user', 'darth_cherry']);
    final suite = FlasherBridge.coreSuite;
    expect(suite.length, 3);
    expect(suite.every((a) => a.isBundled), isTrue);
    expect(
      suite.map((a) => a.fileName).toList(),
      [
        'polybius-v1-stable-hq-android-arm64.apk',
        'polybius-v1-stable-user-android-arm64.apk',
        'darth-cherry-1.0.2-android-arm64.apk',
      ],
    );
  });

  testWidgets('R36S shows SD prepare controls', (tester) async {
    await tester.pumpWidget(const PolybiusFlasherApp());
    await tester.pump();
    await tester.tap(find.text('R36S'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('SD PREPARE / FORMAT'), findsOneWidget);
    expect(find.textContaining('Prepare SD before flash'), findsOneWidget);
    expect(find.textContaining('PREPARE SD ONLY'), findsOneWidget);
    expect(find.textContaining('SYSTEM FORMAT SETTINGS'), findsOneWidget);
  });

  testWidgets('Android OTG shows core suite option', (tester) async {
    await tester.pumpWidget(const PolybiusFlasherApp());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('ANDROID (OTG ADB)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('ANDROID (OTG ADB)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.textContaining('CORE SUITE — Portal + V.1 + Darth Cherry'),
      findsOneWidget,
    );
    expect(find.textContaining('PØLYBÎŪS PORTAL'), findsOneWidget);
    expect(find.textContaining('DARTH CHERRY'), findsOneWidget);
  });
}
