import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polybius_flasher/asset_integrity.dart';
import 'package:polybius_flasher/flasher_event.dart';

class UsbDeviceInfo {
  UsbDeviceInfo({
    required this.deviceId,
    required this.vendorId,
    required this.productId,
    required this.deviceName,
    required this.productName,
    required this.manufacturerName,
    required this.hasPermission,
    this.usbJtag = false,
    this.isAdb = false,
    this.hasMtpOrStorage = false,
    this.serial = '',
    this.hint = '',
  });

  final int deviceId;
  final int vendorId;
  final int productId;
  final String deviceName;
  final String productName;
  final String manufacturerName;
  final bool hasPermission;
  final bool usbJtag;
  final bool isAdb;
  final bool hasMtpOrStorage;
  final String serial;
  final String hint;

  factory UsbDeviceInfo.fromMap(Map<dynamic, dynamic> m) {
    return UsbDeviceInfo(
      deviceId: m['deviceId'] as int,
      vendorId: m['vendorId'] as int,
      productId: m['productId'] as int,
      deviceName: (m['deviceName'] as String?) ?? '',
      productName: (m['productName'] as String?) ?? '',
      manufacturerName: (m['manufacturerName'] as String?) ?? '',
      hasPermission: m['hasPermission'] as bool? ?? false,
      usbJtag: m['usbJtag'] as bool? ?? false,
      isAdb: m['hasAdbInterface'] as bool? ?? m['isAdb'] as bool? ?? false,
      hasMtpOrStorage: m['hasMtpOrStorage'] as bool? ?? false,
      serial: (m['serial'] as String?) ?? '',
      hint: (m['hint'] as String?) ?? '',
    );
  }

  String get label {
    final name = productName.trim().isNotEmpty
        ? productName
        : manufacturerName.trim().isNotEmpty
            ? manufacturerName
            : deviceName.isNotEmpty
                ? deviceName
                : 'USB device';
    final ser = serial.trim().isNotEmpty ? ' · sn $serial' : '';
    final jtag = usbJtag ? ' · USB-JTAG' : '';
    final adb = isAdb ? ' · ADB' : '';
    final mtp = hasMtpOrStorage && !isAdb ? ' · MTP' : '';
    return '$name$ser  (VID 0x${vendorId.toRadixString(16)} '
        'PID 0x${productId.toRadixString(16)}$jtag$adb$mtp)';
  }
}

class NativeResult {
  NativeResult({
    required this.ok,
    required this.message,
    this.errorCode = '',
    this.pmOutput = '',
    this.detail = '',
    this.portsPath = '',
    this.verified = false,
  });
  final bool ok;
  final String message;
  final String errorCode;
  final String pmOutput;
  final String detail;
  final String portsPath;
  final bool verified;

  factory NativeResult.fromMap(Map<dynamic, dynamic> m) {
    return NativeResult(
      ok: m['ok'] as bool? ?? false,
      message: (m['message'] as String?) ?? '',
      errorCode: (m['errorCode'] as String?) ?? '',
      pmOutput: (m['pmOutput'] as String?) ?? '',
      detail: (m['detail'] as String?) ?? '',
      portsPath: (m['portsPath'] as String?) ?? '',
      verified: m['verified'] as bool? ?? false,
    );
  }
}

class BatteryStatus {
  BatteryStatus({
    required this.percent,
    required this.charging,
    required this.low,
    required this.warning,
  });
  final int percent;
  final bool charging;
  final bool low;
  final String warning;

  factory BatteryStatus.fromMap(Map<dynamic, dynamic> m) {
    return BatteryStatus(
      percent: m['percent'] as int? ?? -1,
      charging: m['charging'] as bool? ?? false,
      low: m['low'] as bool? ?? false,
      warning: (m['warning'] as String?) ?? '',
    );
  }
}

class R36PathCandidate {
  R36PathCandidate({
    required this.label,
    required this.hint,
    required this.exists,
  });
  final String label;
  final String hint;
  final bool exists;

  factory R36PathCandidate.fromMap(Map<dynamic, dynamic> m) {
    return R36PathCandidate(
      label: (m['label'] as String?) ?? '',
      hint: (m['hint'] as String?) ?? '',
      exists: m['exists'] as bool? ?? false,
    );
  }
}

/// Catalog entry for APKs installable over OTG ADB.
class ApkCatalogItem {
  const ApkCatalogItem({
    required this.id,
    required this.title,
    required this.fileName,
    required this.url,
    this.subtitle = '',
    this.assetPath,
    this.version = '',
  });

  final String id;
  final String title;
  final String fileName;
  final String url;
  final String subtitle;
  final String? assetPath;
  final String version;

  bool get isBundled => assetPath != null && assetPath!.isNotEmpty;
}

class FlasherBridge {
  FlasherBridge._();
  static final FlasherBridge instance = FlasherBridge._();

  static const _methods = MethodChannel('com.polybius.flasher/native');
  static const _events = EventChannel('com.polybius.flasher/events');

  static const distBase =
      'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flasher-latest-e16f/polybius/dist';

  static const coreSuiteIds = ['portal_hq', 'v1_user', 'darth_cherry'];

  static final apkCatalog = <ApkCatalogItem>[
    ApkCatalogItem(
      id: 'portal_hq',
      title: 'PØLYBÎŪS PORTAL',
      subtitle: 'Bundled · ${AssetIntegrity.portalApk.version} · Dev Admin',
      fileName: AssetIntegrity.portalApk.fileName,
      url: '$distBase/${AssetIntegrity.portalApk.fileName}',
      assetPath: AssetIntegrity.portalApk.assetPath,
      version: AssetIntegrity.portalApk.version,
    ),
    ApkCatalogItem(
      id: 'v1_user',
      title: 'PØLYBÎŪS V.1',
      subtitle: 'Bundled · ${AssetIntegrity.userApk.version}',
      fileName: AssetIntegrity.userApk.fileName,
      url: '$distBase/${AssetIntegrity.userApk.fileName}',
      assetPath: AssetIntegrity.userApk.assetPath,
      version: AssetIntegrity.userApk.version,
    ),
    ApkCatalogItem(
      id: 'darth_cherry',
      title: 'DARTH CHERRY',
      subtitle: 'Bundled · ${AssetIntegrity.darthApk.version}',
      fileName: AssetIntegrity.darthApk.fileName,
      url: '$distBase/${AssetIntegrity.darthApk.fileName}',
      assetPath: AssetIntegrity.darthApk.assetPath,
      version: AssetIntegrity.darthApk.version,
    ),
    ApkCatalogItem(
      id: 'doomsday',
      title: 'DOØMSDAY CLØCK',
      subtitle: '2.1.0 · MechaH portal unlock',
      fileName: 'doomsday-clock-2.1.0-android-arm64.apk',
      url: '$distBase/doomsday-clock-2.1.0-android-arm64.apk',
      version: '2.1.0',
    ),
    ApkCatalogItem(
      id: 'dev_portal',
      title: 'DEV PORTAL (MechaH)',
      subtitle: 'Embedded ritual portal APK',
      fileName: 'polybius-portal-dev-mechah-android-arm64.apk',
      url: '$distBase/polybius-portal-dev-mechah-android-arm64.apk',
    ),
    ApkCatalogItem(
      id: 'red_veil',
      title: 'RED VEIL',
      subtitle: '1.0.0',
      fileName: 'red-veil-1.0.0-android-arm64.apk',
      url: '$distBase/red-veil-1.0.0-android-arm64.apk',
      version: '1.0.0',
    ),
  ];

  static List<ApkCatalogItem> get coreSuite =>
      apkCatalog.where((a) => coreSuiteIds.contains(a.id)).toList();

  StreamSubscription<dynamic>? _sub;
  final _eventController = StreamController<FlasherEvent>.broadcast();
  final List<FlasherEvent> _eventLog = [];

  Stream<FlasherEvent> get events => _eventController.stream;
  List<FlasherEvent> get eventLog => List.unmodifiable(_eventLog);

  /// Legacy adapters used by older UI bits.
  Stream<String> get logs => events
      .where((e) => e.message.isNotEmpty)
      .map((e) => e.toLogLine());

  Stream<ProgressInfo> get progress => events
      .where((e) => e.percent != null)
      .map((e) => ProgressInfo(progress: e.percent!, written: 0, total: 0));

  void ensureListening() {
    _sub ??= _events.receiveBroadcastStream().listen((raw) {
      if (raw is! Map) return;
      final event = FlasherEvent.fromMap(raw);
      _eventLog.add(event);
      if (_eventLog.length > 500) {
        _eventLog.removeRange(0, _eventLog.length - 500);
      }
      _eventController.add(event);
    });
  }

  String dumpEventLog() {
    if (_eventLog.isEmpty) return '(no events yet)';
    return _eventLog.map((e) => e.toLogLine()).join('\n');
  }

  void clearEventLog() => _eventLog.clear();

  Future<List<UsbDeviceInfo>> listUsbDevices() async {
    final raw = await _methods.invokeMethod<List<dynamic>>('listUsbDevices');
    return (raw ?? [])
        .whereType<Map>()
        .map((m) => UsbDeviceInfo.fromMap(m))
        .toList();
  }

  Future<List<UsbDeviceInfo>> listAdbUsbDevices() async {
    final raw =
        await _methods.invokeMethod<List<dynamic>>('listAdbUsbDevices');
    return (raw ?? []).whereType<Map>().map((m) {
      final info = UsbDeviceInfo.fromMap(m);
      return UsbDeviceInfo(
        deviceId: info.deviceId,
        vendorId: info.vendorId,
        productId: info.productId,
        deviceName: info.deviceName,
        productName: info.productName,
        manufacturerName: info.manufacturerName,
        hasPermission: info.hasPermission,
        usbJtag: info.usbJtag,
        isAdb: true,
        serial: info.serial,
        hint: info.hint,
      );
    }).toList();
  }

  Future<List<UsbDeviceInfo>> listUsbInventory() async {
    final raw =
        await _methods.invokeMethod<List<dynamic>>('listUsbInventory');
    return (raw ?? [])
        .whereType<Map>()
        .map((m) => UsbDeviceInfo.fromMap(m))
        .toList();
  }

  Future<BatteryStatus> getBatteryStatus() async {
    final raw =
        await _methods.invokeMethod<Map<dynamic, dynamic>>('getBatteryStatus');
    return BatteryStatus.fromMap(raw ?? {});
  }

  Future<bool> requestUsbPermission(int deviceId) async {
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'requestUsbPermission',
      {'deviceId': deviceId},
    );
    return raw?['granted'] as bool? ?? false;
  }

  Future<NativeResult> flashEsp({
    required int deviceId,
    String? firmwarePath,
    required String chip,
    int offset = 0x0,
    int baud = 115200,
    bool eraseAll = false,
    bool skipAutoReset = false,
    bool syncOnly = false,
    bool hardResetAfter = true,
    int? flashSizeHint,
    int serialMonitorMs = 0,
    String target = 'esp',
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'flashEsp',
      {
        'deviceId': deviceId,
        'firmwarePath': ?firmwarePath,
        'chip': chip,
        'offset': offset,
        'baud': baud,
        'eraseAll': eraseAll,
        'skipAutoReset': skipAutoReset,
        'syncOnly': syncOnly,
        'hardResetAfter': hardResetAfter,
        'flashSizeHint': ?flashSizeHint,
        'serialMonitorMs': serialMonitorMs,
        'target': target,
      },
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<void> cancelFlash() => _methods.invokeMethod('cancelFlash');

  Future<String?> pickSdTree() async {
    return _methods.invokeMethod<String>('pickSdTree');
  }

  Future<String?> pickApk() async {
    return _methods.invokeMethod<String>('pickApk');
  }

  Future<String?> pickExtraFile() async {
    return _methods.invokeMethod<String>('pickExtraFile');
  }

  Future<List<R36PathCandidate>> detectR36Paths(String treeUri) async {
    final raw = await _methods.invokeMethod<List<dynamic>>(
      'detectR36Paths',
      {'treeUri': treeUri},
    );
    return (raw ?? [])
        .whereType<Map>()
        .map(R36PathCandidate.fromMap)
        .toList();
  }

  Future<NativeResult> installR36s({
    required String zipPath,
    required String treeUri,
    String mode = 'direct',
    String? preferredHint,
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'installR36s',
      {
        'zipPath': zipPath,
        'treeUri': treeUri,
        'mode': mode,
        'preferredHint': ?preferredHint,
      },
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<NativeResult> writeR36UsbStick({
    required String zipPath,
    required String treeUri,
    String? extraFilePath,
    bool includeZipCopy = true,
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'writeR36UsbStick',
      {
        'zipPath': zipPath,
        'treeUri': treeUri,
        'extraFilePath': ?extraFilePath,
        'includeZipCopy': includeZipCopy,
      },
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<NativeResult> probeUsbWrite(String treeUri) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'probeUsbWrite',
      {'treeUri': treeUri},
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<NativeResult> prepareSd({
    required String treeUri,
    String layout = 'r36s_ports',
    bool logicalFormat = false,
    bool wipePrevious = true,
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'prepareSd',
      {
        'treeUri': treeUri,
        'layout': layout,
        'logicalFormat': logicalFormat,
        'wipePrevious': wipePrevious,
      },
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<NativeResult> probeSdWrite(String treeUri) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'probeSdWrite',
      {'treeUri': treeUri},
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<NativeResult> openSystemSdFormat() async {
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'openSystemSdFormat',
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<String> listStorageVolumes() async {
    final raw = await _methods.invokeMethod<String>('listStorageVolumes');
    return raw ?? '';
  }

  Future<NativeResult> installApkAdbUsb({
    required int deviceId,
    required String apkPath,
    bool forceDowngrade = false,
    bool forceUser0 = false,
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'installApkAdbUsb',
      {
        'deviceId': deviceId,
        'apkPath': apkPath,
        'forceDowngrade': forceDowngrade,
        'forceUser0': forceUser0,
      },
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<NativeResult> installApkAdbTcp({
    required String host,
    required int port,
    required String apkPath,
    bool forceDowngrade = false,
    bool forceUser0 = false,
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'installApkAdbTcp',
      {
        'host': host,
        'port': port,
        'apkPath': apkPath,
        'forceDowngrade': forceDowngrade,
        'forceUser0': forceUser0,
      },
    );
    return NativeResult.fromMap(raw ?? {});
  }

  /// Materialize a bundled asset and verify SHA-256. Fails early on mismatch.
  Future<String> materializeAsset(
    String assetPath,
    String fileName, {
    String? expectedSha256,
  }) async {
    final bundled = AssetIntegrity.byAssetPath(assetPath) ??
        AssetIntegrity.byFileName(fileName);
    final expect = (expectedSha256 ?? bundled?.sha256)?.toLowerCase();

    final dir = await getApplicationDocumentsDirectory();
    final out = File(p.join(dir.path, fileName));

    Future<String> writeFresh() async {
      final data = await rootBundle.load(assetPath);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (expect != null) {
        final digest = sha256.convert(bytes).toString();
        if (digest != expect) {
          throw StateError(
            'SHA-256 mismatch for $fileName\nexpected $expect\nactual   $digest',
          );
        }
      }
      await out.writeAsBytes(bytes, flush: true);
      return out.path;
    }

    if (await out.exists() && await out.length() > 0) {
      if (expect != null) {
        final digest = (await sha256.bind(out.openRead()).first).toString();
        if (digest == expect) return out.path;
        await out.delete();
        return writeFresh();
      }
      final data = await rootBundle.load(assetPath);
      if (await out.length() == data.lengthInBytes) return out.path;
    }
    return writeFresh();
  }

  Future<String> resolveApk(
    ApkCatalogItem item, {
    void Function(double progress, int received, int total)? onProgress,
  }) async {
    if (item.isBundled) {
      onProgress?.call(0.05, 0, 0);
      final path = await materializeAsset(item.assetPath!, item.fileName);
      final len = await File(path).length();
      onProgress?.call(1.0, len, len);
      return path;
    }
    return downloadApk(item, onProgress: onProgress);
  }

  Future<String> downloadApk(
    ApkCatalogItem item, {
    void Function(double progress, int received, int total)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(dir.path, 'apk_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final out = File(p.join(cacheDir.path, item.fileName));
    if (await out.exists() && await out.length() > 1024 * 100) {
      onProgress?.call(1.0, await out.length(), await out.length());
      return out.path;
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(item.url));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw HttpException(
          'Download failed HTTP ${response.statusCode} for ${item.url}',
        );
      }
      final total = response.contentLength ?? 0;
      final sink = out.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress?.call(received / total, received, total);
        } else {
          onProgress?.call(0, received, 0);
        }
      }
      await sink.flush();
      await sink.close();
      if (await out.length() < 1024) {
        await out.delete();
        throw HttpException('Downloaded APK too small');
      }
      onProgress?.call(1.0, received, total > 0 ? total : received);
      return out.path;
    } finally {
      client.close();
    }
  }
}

class ProgressInfo {
  ProgressInfo({
    required this.progress,
    this.written = 0,
    this.total = 0,
  });
  final double progress;
  final int written;
  final int total;
}
