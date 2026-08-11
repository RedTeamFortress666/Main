import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/features/bluetooth/bluetooth_models.dart';
import 'package:polybius/features/bluetooth/bluetooth_platform.dart';

export 'package:polybius/features/bluetooth/bluetooth_models.dart';

class BluetoothLinkState {
  const BluetoothLinkState({
    this.supported = false,
    this.enabled = false,
    this.scanning = false,
    this.advertising = false,
    this.status = 'Bluetooth idle',
    this.peers = const [],
    this.messages = const [],
    this.localName = 'POLYBIUS',
  });

  final bool supported;
  final bool enabled;
  final bool scanning;
  final bool advertising;
  final String status;
  final List<BtPeer> peers;
  final List<BtMessage> messages;
  final String localName;

  BluetoothLinkState copyWith({
    bool? supported,
    bool? enabled,
    bool? scanning,
    bool? advertising,
    String? status,
    List<BtPeer>? peers,
    List<BtMessage>? messages,
    String? localName,
  }) =>
      BluetoothLinkState(
        supported: supported ?? this.supported,
        enabled: enabled ?? this.enabled,
        scanning: scanning ?? this.scanning,
        advertising: advertising ?? this.advertising,
        status: status ?? this.status,
        peers: peers ?? this.peers,
        messages: messages ?? this.messages,
        localName: localName ?? this.localName,
      );
}

/// Active Bluetooth operator link for nearby ciphertext exchange.
class BluetoothLinkNotifier extends StateNotifier<BluetoothLinkState> {
  BluetoothLinkNotifier() : super(const BluetoothLinkState()) {
    _probe();
  }

  Future<void> _probe() async {
    if (kIsWeb) {
      state = state.copyWith(
        supported: false,
        status: 'Bluetooth unavailable on web',
      );
      return;
    }
    try {
      final ok = await bleIsSupportedImpl();
      state = state.copyWith(
        supported: ok,
        status: ok ? 'Bluetooth ready' : 'Bluetooth not supported here',
      );
    } catch (_) {
      state = state.copyWith(
        supported: false,
        status: 'Bluetooth plugin unavailable',
      );
    }
  }

  Future<void> setEnabled(bool on, {String operatorName = 'POLYBIUS'}) async {
    if (!state.supported && on) await _probe();
    if (!state.supported) {
      state = state.copyWith(status: 'Bluetooth not supported on this device');
      return;
    }
    if (!on) {
      await stop();
      state = state.copyWith(
        enabled: false,
        scanning: false,
        advertising: false,
        status: 'Bluetooth off',
        peers: const [],
      );
      return;
    }

    var named = 'POLYBIUS-${operatorName.toUpperCase()}'.replaceAll(' ', '');
    if (named.length > 18) named = named.substring(0, 18);

    await bleRequestPermissionsImpl();
    final powered = await bleEnsureOnImpl();
    if (!powered) {
      state = state.copyWith(
        enabled: false,
        status: 'Turn on Bluetooth in system settings',
      );
      return;
    }

    state = state.copyWith(
      enabled: true,
      localName: named,
      status: 'Scanning for operators…',
      advertising: true,
    );
    await startScan();
  }

  Future<void> startScan() async {
    if (!state.enabled) return;
    state = state.copyWith(scanning: true, status: 'Scanning for operators…');
    try {
      await bleStartScanImpl(
        onPeers: (peers) {
          final merged = <String, BtPeer>{
            for (final p in state.peers) p.id: p,
          };
          for (final p in peers) {
            final existing = merged[p.id];
            merged[p.id] = p.copyWith(connected: existing?.connected ?? false);
          }
          state = state.copyWith(
            peers: merged.values.toList()
              ..sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999)),
            status: 'Found ${merged.length} nearby operator(s)',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(scanning: false, status: 'Scan failed: $e');
      return;
    }
    if (mounted) state = state.copyWith(scanning: false);
  }

  Future<void> connect(BtPeer peer) async {
    state = state.copyWith(status: 'Connecting to ${peer.name}…');
    try {
      await bleConnectImpl(peer.id);
      final peers = [
        for (final p in state.peers)
          p.id == peer.id ? p.copyWith(connected: true) : p,
      ];
      if (!peers.any((p) => p.id == peer.id)) {
        peers.add(peer.copyWith(connected: true));
      }
      state = state.copyWith(
        peers: peers,
        status: 'Linked with ${peer.name}',
      );
      bleListenImpl(peer.id, (payload) {
        state = state.copyWith(
          messages: [
            BtMessage(
              fromId: peer.id,
              fromName: peer.name,
              payload: payload,
              at: DateTime.now(),
            ),
            ...state.messages,
          ],
        );
      });
    } catch (e) {
      state = state.copyWith(status: 'Connect failed: $e');
    }
  }

  Future<void> sendCiphertext(String peerId, String payload) async {
    final text = payload.trim();
    if (text.isEmpty) return;
    try {
      final wrote = await bleWriteImpl(peerId, text);
      final peer = state.peers.cast<BtPeer?>().firstWhere(
            (p) => p?.id == peerId,
            orElse: () => null,
          );
      state = state.copyWith(
        messages: [
          BtMessage(
            fromId: 'local',
            fromName: state.localName,
            payload: text,
            at: DateTime.now(),
            outbound: true,
          ),
          ...state.messages,
        ],
        status: wrote
            ? 'Sent to ${peer?.name ?? peerId}'
            : 'No writable GATT on peer — kept local',
      );
    } catch (e) {
      state = state.copyWith(status: 'Send failed: $e');
    }
  }

  Future<void> stop() async {
    await bleDisconnectAllImpl();
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}

final bluetoothLinkProvider =
    StateNotifierProvider<BluetoothLinkNotifier, BluetoothLinkState>((ref) {
  return BluetoothLinkNotifier();
});
