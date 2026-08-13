import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart' as peri;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polybius/features/bluetooth/bluetooth_models.dart';
import 'package:polybius/features/bluetooth/bluetooth_uuids.dart';

Future<bool> bleIsSupportedImpl() async {
  try {
    if (!await FlutterBluePlus.isSupported) return false;
    return await peri.BlePeripheral.isSupported();
  } catch (_) {
    return FlutterBluePlus.isSupported;
  }
}

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
bool _peripheralReady = false;
void Function(String deviceId, String name)? _onCentralConnected;
void Function(String deviceId, String payload)? _onPeripheralWrite;
final Set<String> _centrals = {};
final Map<String, BluetoothDevice> _devices = {};
final Map<String, StreamSubscription> _notifySubs = {};
final Map<String, _ChunkBuffer> _chunkBuffers = {};

class _ChunkBuffer {
  _ChunkBuffer(this.total);
  final int total;
  final Map<int, String> parts = {};
  String? assemble() {
    if (parts.length < total) return null;
    final buf = StringBuffer();
    for (var i = 0; i < total; i++) {
      final p = parts[i];
      if (p == null) return null;
      buf.write(p);
    }
    return buf.toString();
  }
}

Future<void> bleStartAdvertisingImpl({
  required String localName,
  required void Function(String deviceId, String name) onCentralConnected,
  required void Function(String deviceId, String payload) onWrite,
}) async {
  _onCentralConnected = onCentralConnected;
  _onPeripheralWrite = onWrite;

  await peri.BlePeripheral.initialize();
  await peri.BlePeripheral.stopAdvertising();
  try {
    await peri.BlePeripheral.clearServices();
  } catch (_) {}

  peri.BlePeripheral.setWriteRequestCallback((deviceId, characteristicId, offset, value) {
    if (value == null || value.isEmpty) return peri.WriteRequestResult();
    final id = characteristicId.toLowerCase();
    if (id != PolybiusBle.rxUuid.toLowerCase()) {
      return peri.WriteRequestResult();
    }
    final text = _decodeIncoming(deviceId, value);
    if (text != null) {
      _centrals.add(deviceId);
      _onCentralConnected?.call(deviceId, 'POLYBIUS-PEER');
      _onPeripheralWrite?.call(deviceId, text);
    }
    return peri.WriteRequestResult();
  });

  peri.BlePeripheral.setConnectionStateChangeCallback((deviceId, connected) {
    if (connected) {
      _centrals.add(deviceId);
      _onCentralConnected?.call(deviceId, 'POLYBIUS-PEER');
    } else {
      _centrals.remove(deviceId);
    }
  });

  peri.BlePeripheral.setCharacteristicSubscriptionChangeCallback(
    (deviceId, characteristicId, isSubscribed, name) {
      if (isSubscribed) {
        _centrals.add(deviceId);
        final label =
            (name != null && name.trim().isNotEmpty) ? name.trim() : 'POLYBIUS-PEER';
        _onCentralConnected?.call(deviceId, label);
      }
    },
  );

  await peri.BlePeripheral.addService(
    peri.BleService(
      uuid: PolybiusBle.serviceUuid,
      primary: true,
      characteristics: [
        peri.BleCharacteristic(
          uuid: PolybiusBle.rxUuid,
          properties: [
            peri.CharacteristicProperties.write.index,
            peri.CharacteristicProperties.writeWithoutResponse.index,
          ],
          permissions: [
            peri.AttributePermissions.writeable.index,
          ],
        ),
        peri.BleCharacteristic(
          uuid: PolybiusBle.txUuid,
          properties: [
            peri.CharacteristicProperties.read.index,
            peri.CharacteristicProperties.notify.index,
          ],
          permissions: [
            peri.AttributePermissions.readable.index,
          ],
        ),
      ],
    ),
  );

  // Android legacy advertise localName is tiny — keep token short.
  final advName = localName.length <= 8
      ? localName
      : PolybiusBle.nameToken;

  await peri.BlePeripheral.startAdvertising(
    services: [PolybiusBle.serviceUuid],
    localName: advName,
    manufacturerData: peri.ManufacturerData(
      manufacturerId: PolybiusBle.manufacturerId,
      data: Uint8List.fromList(utf8.encode(
        localName.length > 20 ? localName.substring(0, 20) : localName,
      )),
    ),
    addManufacturerDataInScanResponse: true,
  );
  _peripheralReady = true;
}

Future<void> bleStopAdvertisingImpl() async {
  _peripheralReady = false;
  try {
    await peri.BlePeripheral.stopAdvertising();
  } catch (_) {}
}

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
      final serviceHit = r.advertisementData.serviceUuids.any(
        (u) => u.str.toLowerCase() == PolybiusBle.serviceUuid.toLowerCase(),
      );
      final nameHit = label.toUpperCase().contains(PolybiusBle.nameToken);
      final mfg = r.advertisementData.manufacturerData;
      final mfgHit = mfg.keys.any(
        (k) => k == PolybiusBle.manufacturerId,
      );
      if (!serviceHit && !nameHit && !mfgHit) continue;

      var display = label;
      if (display.isEmpty && mfgHit) {
        final bytes = mfg[PolybiusBle.manufacturerId];
        if (bytes != null && bytes.isNotEmpty) {
          try {
            display = utf8.decode(bytes);
          } catch (_) {
            display = 'POLYBIUS-PEER';
          }
        }
      }
      if (display.isEmpty) display = 'POLYBIUS-PEER';

      peers.add(BtPeer(
        id: r.device.remoteId.str,
        name: display,
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

Future<void> bleConnectImpl(String deviceId) async {
  final device = BluetoothDevice.fromId(deviceId);
  await device.connect(mtu: 512);
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
        if (s.uuid.str.toLowerCase() != PolybiusBle.serviceUuid.toLowerCase()) {
          continue;
        }
        for (final c in s.characteristics) {
          if (c.uuid.str.toLowerCase() != PolybiusBle.txUuid.toLowerCase()) {
            continue;
          }
          if (!(c.properties.notify || c.properties.indicate)) continue;
          await c.setNotifyValue(true);
          await _notifySubs[deviceId]?.cancel();
          _notifySubs[deviceId] = c.onValueReceived.listen((value) {
            final text = _decodeIncoming(deviceId, Uint8List.fromList(value));
            if (text != null) onData(text);
          });
          return;
        }
      }
      // Fallback: first notify characteristic (legacy peers).
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify || c.properties.indicate) {
            await c.setNotifyValue(true);
            await _notifySubs[deviceId]?.cancel();
            _notifySubs[deviceId] = c.onValueReceived.listen((value) {
              final text = _decodeIncoming(deviceId, Uint8List.fromList(value));
              if (text != null) onData(text);
            });
            return;
          }
        }
      }
    } catch (_) {}
  }();
}

Future<bool> bleWriteImpl(String deviceId, String payload) async {
  // Prefer central→peripheral write when we own a GATT client session.
  if (_devices.containsKey(deviceId)) {
    final ok = await _writeAsCentral(deviceId, payload);
    if (ok) return true;
  }
  // Otherwise notify as peripheral to a subscribed central.
  if (_peripheralReady && _centrals.contains(deviceId)) {
    return _notifyAsPeripheral(deviceId, payload);
  }
  // Last resort: try notify without knowing subscription set.
  if (_peripheralReady) {
    return _notifyAsPeripheral(deviceId, payload);
  }
  return false;
}

Future<bool> _writeAsCentral(String deviceId, String payload) async {
  final device = _devices[deviceId];
  if (device == null) return false;
  final services = await device.discoverServices();
  BluetoothCharacteristic? rx;
  for (final s in services) {
    for (final c in s.characteristics) {
      if (c.uuid.str.toLowerCase() == PolybiusBle.rxUuid.toLowerCase()) {
        rx = c;
        break;
      }
    }
    if (rx != null) break;
  }
  // Fallback: first writable
  if (rx == null) {
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.properties.write || c.properties.writeWithoutResponse) {
          rx = c;
          break;
        }
      }
      if (rx != null) break;
    }
  }
  if (rx == null) return false;

  final withoutResponse = rx.properties.writeWithoutResponse;
  for (final chunk in _chunk(payload)) {
    await rx.write(
      utf8.encode(chunk),
      withoutResponse: withoutResponse,
    );
    if (!withoutResponse) {
      await Future<void>.delayed(const Duration(milliseconds: 8));
    }
  }
  return true;
}

Future<bool> _notifyAsPeripheral(String deviceId, String payload) async {
  try {
    for (final chunk in _chunk(payload)) {
      await peri.BlePeripheral.updateCharacteristic(
        characteristicId: PolybiusBle.txUuid,
        value: Uint8List.fromList(utf8.encode(chunk)),
        deviceId: deviceId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }
    return true;
  } catch (_) {
    try {
      // Broadcast to all subscribers if targeted notify fails.
      for (final chunk in _chunk(payload)) {
        await peri.BlePeripheral.updateCharacteristic(
          characteristicId: PolybiusBle.txUuid,
          value: Uint8List.fromList(utf8.encode(chunk)),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

List<String> _chunk(String payload, {int maxBytes = 160}) {
  final units = utf8.encode(payload);
  if (units.length <= maxBytes) return [payload];
  // Slice on UTF-8 string code-units carefully via substring of original.
  final parts = <String>[];
  var start = 0;
  while (start < payload.length) {
    var end = start;
    var size = 0;
    while (end < payload.length) {
      final cu = payload.codeUnitAt(end);
      final add = cu <= 0x7F
          ? 1
          : cu <= 0x7FF
              ? 2
              : cu <= 0xFFFF
                  ? 3
                  : 4;
      if (size + add > maxBytes) break;
      size += add;
      end++;
    }
    if (end == start) end = start + 1;
    parts.add(payload.substring(start, end));
    start = end;
  }
  final total = parts.length;
  return [
    for (var i = 0; i < total; i++) 'PBX|$i|$total|${parts[i]}',
  ];
}

String? _decodeIncoming(String deviceId, Uint8List value) {
  String raw;
  try {
    raw = utf8.decode(value);
  } catch (_) {
    return null;
  }
  if (!raw.startsWith('PBX|')) {
    _chunkBuffers.remove(deviceId);
    return raw;
  }
  final parts = raw.split('|');
  if (parts.length < 4) return raw;
  final index = int.tryParse(parts[1]);
  final total = int.tryParse(parts[2]);
  if (index == null || total == null || total <= 0) return raw;
  final body = parts.sublist(3).join('|');
  final buf = _chunkBuffers.putIfAbsent(deviceId, () => _ChunkBuffer(total));
  if (buf.total != total) {
    _chunkBuffers[deviceId] = _ChunkBuffer(total)..parts[index] = body;
  } else {
    buf.parts[index] = body;
  }
  final assembled = _chunkBuffers[deviceId]?.assemble();
  if (assembled != null) {
    _chunkBuffers.remove(deviceId);
    return assembled;
  }
  return null;
}

Future<void> bleDisconnectAllImpl() async {
  await bleStopScanImpl();
  await bleStopAdvertisingImpl();
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
  _centrals.clear();
  _chunkBuffers.clear();
  _onCentralConnected = null;
  _onPeripheralWrite = null;
}
