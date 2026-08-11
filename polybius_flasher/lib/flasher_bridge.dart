import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    this.serial = '',
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
  final String serial;

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
      serial: (m['serial'] as String?) ?? '',
    );
  }

  String get label {
    final name = productName.trim().isNotEmpty
        ? productName
        : manufacturerName.trim().isNotEmpty
            ? manufacturerName
            : deviceName.isNotEmpty
                ? deviceName
                : 'ADB device';
    final jtag = usbJtag ? ' · USB-JTAG' : '';
    final adb = isAdb ? ' · ADB' : '';
    return '$name  (VID 0x${vendorId.toRadixString(16)} PID 0x${productId.toRadixString(16)}$jtag$adb)';
  }
}

class NativeResult {
  NativeResult({required this.ok, required this.message});
  final bool ok;
  final String message;

  factory NativeResult.fromMap(Map<dynamic, dynamic> m) {
    return NativeResult(
      ok: m['ok'] as bool? ?? false,
      message: (m['message'] as String?) ?? '',
    );
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

/// Catalog entry for APKs installable over OTG ADB.
class ApkCatalogItem {
  const ApkCatalogItem({
    required this.id,
    required this.title,
    required this.fileName,
    required this.url,
    this.subtitle = '',
  });

  final String id;
  final String title;
  final String fileName;
  final String url;
  final String subtitle;
}

class FlasherBridge {
  FlasherBridge._();
  static final FlasherBridge instance = FlasherBridge._();

  static const _methods = MethodChannel('com.polybius.flasher/native');
  static const _events = EventChannel('com.polybius.flasher/events');

  /// Raw GitHub URLs for dist APKs on the shipping branch.
  static const distBase =
      'https://github.com/RedTeamFortress666/Main/raw/cursor/pool-pin-bt-ui-d8fa/polybius/dist';

  static const apkCatalog = <ApkCatalogItem>[
    ApkCatalogItem(
      id: 'portal_hq',
      title: 'PØLYBÎŪS PORTAL',
      subtitle: 'Dev Admin / triple tier',
      fileName: 'polybius-v1-stable-hq-android-arm64.apk',
      url: '$distBase/polybius-v1-stable-hq-android-arm64.apk',
    ),
    ApkCatalogItem(
      id: 'v1_user',
      title: 'PØLYBÎŪS V.1',
      subtitle: 'ENCRYPT / DECRYPT / SYNC / CONNECT',
      fileName: 'polybius-v1-stable-user-android-arm64.apk',
      url: '$distBase/polybius-v1-stable-user-android-arm64.apk',
    ),
    ApkCatalogItem(
      id: 'doomsday',
      title: 'DOØMSDAY CLØCK',
      subtitle: '2.1.0 · MechaH portal unlock',
      fileName: 'doomsday-clock-2.1.0-android-arm64.apk',
      url: '$distBase/doomsday-clock-2.1.0-android-arm64.apk',
    ),
    ApkCatalogItem(
      id: 'darth_cherry',
      title: 'DARTH CHERRY',
      subtitle: 'Dimmer / temptress',
      fileName: 'darth-cherry-1.0.2-android-arm64.apk',
      url: '$distBase/darth-cherry-1.0.2-android-arm64.apk',
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
    ),
  ];

  StreamSubscription<dynamic>? _sub;
  final _logController = StreamController<String>.broadcast();
  final _progressController = StreamController<ProgressInfo>.broadcast();

  Stream<String> get logs => _logController.stream;
  Stream<ProgressInfo> get progress => _progressController.stream;

  void ensureListening() {
    _sub ??= _events.receiveBroadcastStream().listen((event) {
      if (event is! Map) return;
      final type = event['type'];
      final value = event['value'];
      if (type == 'log' && value is String) {
        _logController.add(value);
      } else if (type == 'progress') {
        if (value is num) {
          _progressController.add(ProgressInfo(progress: value.toDouble()));
        } else if (value is Map) {
          _progressController.add(
            ProgressInfo(
              progress: (value['progress'] as num?)?.toDouble() ?? 0,
              written: (value['written'] as num?)?.toInt() ?? 0,
              total: (value['total'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }
    });
  }

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
    return (raw ?? [])
        .whereType<Map>()
        .map((m) {
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
          );
        })
        .toList();
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

  Future<NativeResult> installR36s({
    required String zipPath,
    required String treeUri,
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'installR36s',
      {'zipPath': zipPath, 'treeUri': treeUri},
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<NativeResult> installApkAdbUsb({
    required int deviceId,
    required String apkPath,
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'installApkAdbUsb',
      {'deviceId': deviceId, 'apkPath': apkPath},
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<NativeResult> installApkAdbTcp({
    required String host,
    required int port,
    required String apkPath,
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'installApkAdbTcp',
      {'host': host, 'port': port, 'apkPath': apkPath},
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<String> materializeAsset(String assetPath, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final out = File(p.join(dir.path, fileName));
    if (await out.exists() && await out.length() > 0) {
      final data = await rootBundle.load(assetPath);
      if (await out.length() == data.lengthInBytes) {
        return out.path;
      }
    }
    final data = await rootBundle.load(assetPath);
    await out.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return out.path;
  }

  /// Download (or reuse cached) catalog APK into app documents.
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
