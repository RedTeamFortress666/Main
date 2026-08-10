import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polybius/features/bluetooth/bluetooth_models.dart';

Future<bool> bleIsSupportedImpl() => FlutterBluePlus.isSupported;

Future<void> bleRequestPermissionsImpl() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.locationWhenInUse,
  ].request();
}

Future<bool> bleEnsureOnImpl() async {
  try {
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
      return true;
    }
    await FlutterBluePlus.turnOn();
    final state = await FlutterBluePlus.adapterState
        .firstWhere((s) => s == BluetoothAdapterState.on)
        .timeout(const Duration(seconds: 4));
    return state == BluetoothAdapterState.on;
  } catch (_) {
    try {
      return await FlutterBluePlus.adapterState.first ==
          BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }
}

StreamSubscription? _scanSub;

Future<void> bleStartScanImpl({
  required void Function(List<BtPeer> peers) onPeers,
  Duration timeout = const Duration(seconds: 14),
}) async {
  await bleStopScanImpl();
  _scanSub = FlutterBluePlus.scanResults.listen((results) {
    final peers = <BtPeer>[];
    for (final r in results) {
      final name = r.device.platformName.trim();
      final adv = r.advertisementData.advName.trim();
      final label = name.isNotEmpty ? name : adv;
      if (!label.toUpperCase().contains('POLYBIUS')) continue;
      peers.add(BtPeer(
        id: r.device.remoteId.str,
        name: label,
        rssi: r.rssi,
      ));
    }
    onPeers(peers);
  });
  await FlutterBluePlus.startScan(timeout: timeout);
}

Future<void> bleStopScanImpl() async {
  await _scanSub?.cancel();
  _scanSub = null;
  try {
    await FlutterBluePlus.stopScan();
  } catch (_) {}
}

final Map<String, BluetoothDevice> _devices = {};
final Map<String, StreamSubscription> _notifySubs = {};

Future<void> bleConnectImpl(String deviceId) async {
  final device = BluetoothDevice.fromId(deviceId);
  await device.connect();
  _devices[deviceId] = device;
  try {
    await device.discoverServices();
  } catch (_) {}
}

void bleListenImpl(String deviceId, void Function(String payload) onData) {
  final device = _devices[deviceId];
  if (device == null) return;
  () async {
    try {
      final services = await device.discoverServices();
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify || c.properties.indicate) {
            await c.setNotifyValue(true);
            await _notifySubs[deviceId]?.cancel();
            _notifySubs[deviceId] = c.onValueReceived.listen((value) {
              try {
                onData(utf8.decode(value));
              } catch (_) {}
            });
            return;
          }
        }
      }
    } catch (_) {}
  }();
}

Future<bool> bleWriteImpl(String deviceId, String payload) async {
  final device = _devices[deviceId];
  if (device == null) return false;
  final services = await device.discoverServices();
  for (final s in services) {
    for (final c in s.characteristics) {
      final canWrite =
          c.properties.write || c.properties.writeWithoutResponse;
      if (!canWrite) continue;
      await c.write(
        utf8.encode(payload),
        withoutResponse: c.properties.writeWithoutResponse,
      );
      return true;
    }
  }
  return false;
}

Future<void> bleDisconnectAllImpl() async {
  for (final d in _devices.values) {
    try {
      await d.disconnect();
    } catch (_) {}
  }
  _devices.clear();
  for (final s in _notifySubs.values) {
    await s.cancel();
  }
  _notifySubs.clear();
  await bleStopScanImpl();
}
