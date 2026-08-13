import 'package:flutter_test/flutter_test.dart';
import 'package:polybius_flasher/asset_integrity.dart';
import 'package:polybius_flasher/board_presets.dart';
import 'package:polybius_flasher/flasher_bridge.dart';
import 'package:polybius_flasher/flasher_event.dart';
import 'package:polybius_flasher/main.dart';

void main() {
  test('esp presets map chip/firmware correctly', () {
    expect(FlashTarget.esp32e.isEsp, isTrue);
    expect(FlashTarget.esp32e.defaultChip, 'esp32');
    expect(FlashTarget.esp32e.defaultBaud, 115200);
    expect(FlashTarget.esp32e.firmwareFileName, 'polybius-cyd.bin');
    expect(FlashTarget.esp32e.espPreset, EspPreset.esp32e);
    expect(FlashTarget.tdeck.defaultChip, 'esp32s3');
    expect(FlashTarget.tdeck.espPreset?.preferSkipAutoReset, isTrue);
    expect(FlashTarget.cyd2usb.firmwareFileName, 'polybius-cyd.bin');
    expect(FlashTarget.cydClassic.title, 'CYD CLASSIC');
    expect(FlashTarget.androidOtg.isEsp, isFalse);
    expect(FlashTarget.androidOtg.isAndroidOtg, isTrue);
  });

  test('bundled catalog includes Portal, V.1 USER, and Darth Cherry', () {
    expect(FlasherBridge.coreSuiteIds, ['portal_hq', 'v1_user', 'darth_cherry']);
    final suite = FlasherBridge.coreSuite;
    expect(suite.length, 3);
    expect(suite.every((a) => a.isBundled), isTrue);
    expect(AssetIntegrity.cydBin.sha256.length, 64);
    expect(AssetIntegrity.portalApk.sha256.length, 64);
    expect(AssetIntegrity.r36sZip.fileName, contains('r36s'));
  });

  test('asset integrity table covers firmware zip and core apks', () {
    expect(AssetIntegrity.all.length, greaterThanOrEqualTo(6));
    for (final a in AssetIntegrity.all) {
      expect(a.sha256, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(a.assetPath, isNotEmpty);
      expect(a.fileName, isNotEmpty);
    }
  });

  test('flasher event log line is structured', () {
    final e = FlasherEvent(
      stage: 'adb_install',
      message: 'pm install failed',
      percent: 0.5,
      level: FlasherLogLevel.error,
      target: 'androidOtg',
      detail: 'VERSION_DOWNGRADE',
      ok: false,
    );
    final line = e.toLogLine();
    expect(line, contains('[androidOtg]'));
    expect(line, contains('[adb_install]'));
    expect(line, contains('VERSION_DOWNGRADE'));
    expect(line, contains('FAIL'));
  });

  test('operation report summarizes successes and failures', () {
    final report = OperationReport(target: 'androidOtg', title: 'ADB queue');
    report.add(name: 'PORTAL', ok: true, detail: 'Success');
    report.add(name: 'DARTH', ok: false, detail: 'INSUFFICIENT_STORAGE');
    final s = report.summary();
    expect(s, contains('1 ok, 1 failed'));
    expect(s, contains('PORTAL'));
    expect(s, contains('INSUFFICIENT_STORAGE'));
    expect(report.allOk, isFalse);
  });

  test('tdeck manual boot steps mention trackball', () {
    expect(EspPreset.tdeck.manualBootSteps.toLowerCase(), contains('trackball'));
    expect(EspPreset.cydClassic.manualBootSteps.toLowerCase(), contains('boot'));
    expect(EspPreset.cydClassic.overwriteWarning.toLowerCase(), contains('overwrites'));
  });
}
