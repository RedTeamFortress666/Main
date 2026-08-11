import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Extracts an embedded APK asset and hands it to the system package installer.
class ApkInstaller {
  static const _channel = MethodChannel('doomsday_clock/packages');

  static Future<String> materializeAsset(String assetPath, String fileName) async {
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/$fileName');
    final data = await rootBundle.load(assetPath);
    await out.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return out.path;
  }

  static Future<bool> canInstall() async {
    try {
      return await _channel.invokeMethod<bool>('canRequestPackageInstalls') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openInstallPermissionSettings() async {
    await _channel.invokeMethod('openUnknownAppSettings');
  }

  static Future<void> installFromPath(String path) async {
    await _channel.invokeMethod('installApk', {'path': path});
  }

  static Future<void> installAsset(String assetPath, {String? fileName}) async {
    final name = fileName ?? assetPath.split('/').last;
    final path = await materializeAsset(assetPath, name);
    final allowed = await canInstall();
    if (!allowed) {
      await openInstallPermissionSettings();
    }
    await installFromPath(path);
  }
}
