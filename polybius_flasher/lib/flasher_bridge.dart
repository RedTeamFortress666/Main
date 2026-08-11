import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
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
  });

  final int deviceId;
  final int vendorId;
  final int productId;
  final String deviceName;
  final String productName;
  final String manufacturerName;
  final bool hasPermission;

  factory UsbDeviceInfo.fromMap(Map<dynamic, dynamic> m) {
    return UsbDeviceInfo(
      deviceId: m['deviceId'] as int,
      vendorId: m['vendorId'] as int,
      productId: m['productId'] as int,
      deviceName: (m['deviceName'] as String?) ?? '',
      productName: (m['productName'] as String?) ?? '',
      manufacturerName: (m['manufacturerName'] as String?) ?? '',
      hasPermission: m['hasPermission'] as bool? ?? false,
    );
  }

  String get label {
    final name = productName.trim().isNotEmpty
        ? productName
        : manufacturerName.trim().isNotEmpty
            ? manufacturerName
            : deviceName;
    return '$name  (VID ${vendorId.toRadixString(16)} PID ${productId.toRadixString(16)})';
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

class FlasherBridge {
  FlasherBridge._();
  static final FlasherBridge instance = FlasherBridge._();

  static const _methods = MethodChannel('com.polybius.flasher/native');
  static const _events = EventChannel('com.polybius.flasher/events');

  StreamSubscription<dynamic>? _sub;
  final _logController = StreamController<String>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  Stream<String> get logs => _logController.stream;
  Stream<double> get progress => _progressController.stream;

  void ensureListening() {
    _sub ??= _events.receiveBroadcastStream().listen((event) {
      if (event is! Map) return;
      final type = event['type'];
      final value = event['value'];
      if (type == 'log' && value is String) {
        _logController.add(value);
      } else if (type == 'progress' && value is num) {
        _progressController.add(value.toDouble());
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

  Future<bool> requestUsbPermission(int deviceId) async {
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'requestUsbPermission',
      {'deviceId': deviceId},
    );
    return raw?['granted'] as bool? ?? false;
  }

  Future<NativeResult> flashEsp({
    required int deviceId,
    required String firmwarePath,
    required String chip,
    int offset = 0x10000,
    int baud = 460800,
  }) async {
    ensureListening();
    final raw = await _methods.invokeMethod<Map<dynamic, dynamic>>(
      'flashEsp',
      {
        'deviceId': deviceId,
        'firmwarePath': firmwarePath,
        'chip': chip,
        'offset': offset,
        'baud': baud,
      },
    );
    return NativeResult.fromMap(raw ?? {});
  }

  Future<void> cancelFlash() => _methods.invokeMethod('cancelFlash');

  Future<String?> pickSdTree() async {
    return _methods.invokeMethod<String>('pickSdTree');
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

  /// Copies a bundled asset into app documents and returns the absolute path.
  Future<String> materializeAsset(String assetPath, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final out = File(p.join(dir.path, fileName));
    if (await out.exists() && await out.length() > 0) {
      // Refresh if asset may have changed (size mismatch is a cheap check).
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
}
