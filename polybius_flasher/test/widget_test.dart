import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:polybius_flasher/asset_integrity.dart';
import 'package:polybius_flasher/board_presets.dart';
import 'package:polybius_flasher/crypt3x_lite.dart';
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
    expect(FlashTarget.crypt3xLite.isEsp, isFalse);
    expect(FlashTarget.crypt3xLite.isCrypt3xLite, isTrue);
    expect(FlashTarget.crypt3xLite.title, 'CRYPT3X OS LITE');
    expect(FlashTarget.crypt3xLite.subtitle, contains('8 GiB'));
  });

  test('crypt3x lite catalog matches sidecar json and official hashes', () {
    expect(Crypt3xLiteCatalog.bytes, 8589934592);
    expect(Crypt3xLiteCatalog.zipBytes, 965250113);
    expect(Crypt3xLiteCatalog.sha256, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(Crypt3xLiteCatalog.zipSha256, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(Crypt3xLiteCatalog.bytes, lessThan(16 * 1024 * 1024 * 1024));
    expect(Crypt3xLiteCatalog.bytes, greaterThan(Crypt3xLiteCatalog.fat32MaxBytes));
    expect(
      Crypt3xLiteCatalog.expectedSha256For(Crypt3xLiteCatalog.fileName),
      Crypt3xLiteCatalog.sha256,
    );
    expect(
      Crypt3xLiteCatalog.expectedSha256For(Crypt3xLiteCatalog.zipFileName),
      Crypt3xLiteCatalog.zipSha256,
    );
    expect(
      Crypt3xLiteCatalog.destFileNameFor('picked.img'),
      Crypt3xLiteCatalog.fileName,
    );
    expect(
      Crypt3xLiteCatalog.destFileNameFor('picked.img.zip'),
      Crypt3xLiteCatalog.zipFileName,
    );

    final json = jsonDecode(
      File('assets/r36s/crypt3x-lite.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(json['bundledInApk'], isFalse);
    expect(json['packageDir'], Crypt3xLiteCatalog.packageDir);
    expect((json['image'] as Map)['sha256'], Crypt3xLiteCatalog.sha256);
    expect((json['image'] as Map)['bytes'], Crypt3xLiteCatalog.bytes);
    expect((json['zip'] as Map)['sha256'], Crypt3xLiteCatalog.zipSha256);
    expect((json['zip'] as Map)['bytes'], Crypt3xLiteCatalog.zipBytes);
  });

  test('crypt3x lite host flash script refuses missing image and documents dd', () {
    final script = File('tool/flash_crypt3x_lite.sh').readAsStringSync();
    expect(script, contains(Crypt3xLiteCatalog.sha256));
    expect(script, contains('dd if='));
    expect(script, contains('FLASH'));
    expect(File('tool/flash_crypt3x_lite.sh').statSync().mode & 0x49, isNonZero);
  });

  test('crypt3x lite assemble script rebuilds the R36S flash zip', () {
    final script = File('tool/assemble-crypt3x-lite-zip.sh').readAsStringSync();
    expect(script, contains('CRYPT3X_OS_LITE-r36s-20260815.zip'));
    expect(script, contains('e79ac4225e702c3b5b5dc353198522be2141c2d6f20c8ec9df6f8cb548428f93'));
    expect(script, contains('965251465'));
    expect(File('tool/assemble-crypt3x-lite-zip.sh').statSync().mode & 0x49, isNonZero);
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

  test('r36 storage destination flags cover sd and usb', () {
    expect(R36StorageDestination.sdCard.usesSd, isTrue);
    expect(R36StorageDestination.sdCard.usesUsb, isFalse);
    expect(R36StorageDestination.usbStick.usesUsb, isTrue);
    expect(R36StorageDestination.both.usesSd, isTrue);
    expect(R36StorageDestination.both.usesUsb, isTrue);
    expect(R36StorageDestination.usbStick.label, contains('USB stick'));
  });

  test('tdeck manual boot steps mention trackball', () {
    expect(EspPreset.tdeck.manualBootSteps.toLowerCase(), contains('trackball'));
    expect(EspPreset.cydClassic.manualBootSteps.toLowerCase(), contains('boot'));
    expect(EspPreset.cydClassic.overwriteWarning.toLowerCase(), contains('overwrites'));
  });
}
