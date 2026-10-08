import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:polybius_flasher/asset_integrity.dart';
import 'package:polybius_flasher/board_presets.dart';
import 'package:polybius_flasher/crypt3x_lite.dart';
import 'package:polybius_flasher/flasher_bridge.dart';
import 'package:polybius_flasher/flasher_event.dart';
import 'package:polybius_flasher/main.dart';
import 'package:polybius_flasher/r36s_iso_manifest.dart';

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
    expect(FlashTarget.crypt3xLite.subtitle, contains('Etcher'));
  });

  test('crypt3x lite catalog matches sidecar json and official hashes', () {
    expect(Crypt3xLiteCatalog.bytes, 8589934592);
    expect(Crypt3xLiteCatalog.zipBytes, 965250113);
    expect(Crypt3xLiteCatalog.kitBytes, 965251465);
    expect(Crypt3xLiteCatalog.sha256, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(Crypt3xLiteCatalog.zipSha256, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(Crypt3xLiteCatalog.kitSha256, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(Crypt3xLiteCatalog.kitSha256, isNot(Crypt3xLiteCatalog.zipSha256));
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
      Crypt3xLiteCatalog.expectedSha256For(Crypt3xLiteCatalog.kitFileName),
      Crypt3xLiteCatalog.kitSha256,
    );
    expect(
      Crypt3xLiteCatalog.destFileNameFor('picked.img'),
      Crypt3xLiteCatalog.fileName,
    );
    expect(
      Crypt3xLiteCatalog.destFileNameFor('picked.img.zip'),
      Crypt3xLiteCatalog.zipFileName,
    );
    expect(
      Crypt3xLiteCatalog.destFileNameFor(Crypt3xLiteCatalog.kitFileName),
      Crypt3xLiteCatalog.kitFileName,
    );
    expect(
      Crypt3xLiteCatalog.etcherDestNameForSha256(Crypt3xLiteCatalog.kitSha256),
      Crypt3xLiteCatalog.kitFileName,
    );
    expect(
      Crypt3xLiteCatalog.etcherDestNameForSha256(Crypt3xLiteCatalog.zipSha256),
      Crypt3xLiteCatalog.zipFileName,
    );
    expect(Crypt3xLiteCatalog.etcherDestNameForSha256('deadbeef'), isNull);
    expect(Crypt3xLiteCatalog.parts.length, 12);
    expect(Crypt3xLiteCatalog.parts.first.fileName, endsWith('.part00'));
    expect(Crypt3xLiteCatalog.parts.last.fileName, endsWith('.part11'));
    expect(
      Crypt3xLiteCatalog.parts.take(11).every((p) => p.bytes == 83886080),
      isTrue,
    );
    expect(
      Crypt3xLiteCatalog.parts.take(11).fold<int>(0, (s, p) => s + p.bytes) +
          Crypt3xLiteCatalog.parts.last.bytes,
      Crypt3xLiteCatalog.kitBytes,
    );
    expect(Crypt3xLiteCatalog.etcherFolder, 'CRYPT3X_ETCHER');
    expect(Crypt3xLiteCatalog.etcherInstructions('x.zip'), contains('balenaEtcher'));
    expect(Crypt3xLiteCatalog.rufusInstructions('x.zip'), contains('DD Image'));
    expect(Crypt3xLiteCatalog.allRequiredDownloads.length, 14);
    expect(
      Crypt3xLiteCatalog.allRequiredDownloads.map((d) => d.fileName),
      contains(Crypt3xLiteCatalog.flasherApkFileName),
    );
    expect(
      Crypt3xLiteCatalog.allRequiredDownloads.map((d) => d.fileName),
      contains(Crypt3xLiteCatalog.parts.first.fileName),
    );

    final json = jsonDecode(
      File('assets/r36s/crypt3x-lite.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(json['bundledInApk'], isFalse);
    expect(json['packageDir'], Crypt3xLiteCatalog.packageDir);
    expect(json['etcherFolder'], Crypt3xLiteCatalog.etcherFolder);
    expect(json['githubDir'], Crypt3xLiteCatalog.githubDir);
    expect(
      Crypt3xLiteCatalog.parts.first.githubUrl,
      contains('polybius/dist/crypt3x-os-lite/CRYPT3X_OS_LITE-r36s-20260815.zip.part00'),
    );
    expect((json['image'] as Map)['sha256'], Crypt3xLiteCatalog.sha256);
    expect((json['image'] as Map)['bytes'], Crypt3xLiteCatalog.bytes);
    expect((json['zip'] as Map)['sha256'], Crypt3xLiteCatalog.zipSha256);
    expect((json['zip'] as Map)['bytes'], Crypt3xLiteCatalog.zipBytes);
    expect((json['kitZip'] as Map)['sha256'], Crypt3xLiteCatalog.kitSha256);
    expect((json['kitZip'] as Map)['bytes'], Crypt3xLiteCatalog.kitBytes);
    final parts = (json['parts'] as List).cast<Map<String, dynamic>>();
    expect(parts.length, 12);
    expect(parts.last['sha256'], Crypt3xLiteCatalog.parts.last.sha256);
    expect(parts.last['altSha256'], Crypt3xLiteCatalog.parts.last.altSha256);
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

  test('crypt3x etcher kit script writes ETCHER and RUFUS instructions', () {
    final script = File('tool/prepare-crypt3x-etcher-kit.sh').readAsStringSync();
    expect(script, contains('CRYPT3X_ETCHER'));
    expect(script, contains('ETCHER.txt'));
    expect(script, contains('RUFUS.txt'));
    expect(script, contains('balenaEtcher'));
    expect(script, contains('DD Image'));
    expect(script, contains('assemble-crypt3x-lite-zip.sh'));
    expect(File('tool/prepare-crypt3x-etcher-kit.sh').statSync().mode & 0x49, isNonZero);
  });

  test('r36s iso manifest lists every required zip path and downloads', () {
    expect(R36IsoManifest.packageFileName, AssetIntegrity.r36sZip.fileName);
    expect(R36IsoManifest.sha256, AssetIntegrity.r36sZip.sha256);
    expect(R36IsoManifest.portZipFiles.length, 23);
    expect(
      R36IsoManifest.portZipFiles.map((f) => f.path),
      containsAll(R36IsoManifest.verifyMustExist),
    );
    expect(
      R36IsoManifest.portZipFiles.any((f) => f.path == 'ports/Polybius.sh'),
      isTrue,
    );
    expect(R36IsoManifest.githubUrl, contains(R36IsoManifest.packageFileName));
    expect(R36IsoManifest.githubBackupUrl, contains('assets/r36s'));
    expect(R36IsoManifest.flasherApkFileName, contains('1.8.0'));
    expect(R36IsoManifest.crypt3xPartFiles.length, 12);
    expect(R36IsoManifest.alternateFlashText(), contains('PortMaster'));
    expect(R36IsoManifest.alternateFlashText(), contains('PREPARE ETCHER / RUFUS KIT'));

    final json = jsonDecode(
      File('assets/r36s/iso-manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(json['sha256'], R36IsoManifest.sha256);
    expect(json['bytes'], R36IsoManifest.bytes);
    final files = (json['files'] as List).cast<Map<String, dynamic>>();
    expect(files.length, R36IsoManifest.portZipFiles.length);
    expect(
      files.map((f) => f['path']),
      R36IsoManifest.portZipFiles.map((f) => f.path),
    );
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
