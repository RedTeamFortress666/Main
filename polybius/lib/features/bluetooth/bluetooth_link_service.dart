import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/features/bluetooth/bluetooth_models.dart';
import 'package:polybius/features/bluetooth/bluetooth_platform.dart';
import 'package:polybius/features/bluetooth/bluetooth_protocol.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';

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
    this.pendingShare,
    this.lastAppliedPoolId,
  });

  final bool supported;
  final bool enabled;
  final bool scanning;
  final bool advertising;
  final String status;
  final List<BtPeer> peers;
  final List<BtMessage> messages;
  final String localName;
  final BtRotorSharePending? pendingShare;
  final String? lastAppliedPoolId;

  BluetoothLinkState copyWith({
    bool? supported,
    bool? enabled,
    bool? scanning,
    bool? advertising,
    String? status,
    List<BtPeer>? peers,
    List<BtMessage>? messages,
    String? localName,
    BtRotorSharePending? pendingShare,
    bool clearPendingShare = false,
    String? lastAppliedPoolId,
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
        pendingShare:
            clearPendingShare ? null : (pendingShare ?? this.pendingShare),
        lastAppliedPoolId: lastAppliedPoolId ?? this.lastAppliedPoolId,
      );
}

/// Active Bluetooth operator link for nearby ciphertext + rotor/pool exchange.
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
        clearPendingShare: true,
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
      bleListenImpl(peer.id, (payload) => _onInbound(peer, payload));
    } catch (e) {
      state = state.copyWith(status: 'Connect failed: $e');
    }
  }

  void _onInbound(BtPeer peer, String raw) {
    final env = BtEnvelope.parse(raw);
    final msg = BtMessage(
      fromId: peer.id,
      fromName: peer.name,
      payload: env.payload.isNotEmpty ? env.payload : raw,
      at: DateTime.now(),
      kind: env.kind,
      confirmCode: env.confirmCode,
      poolId: env.poolId,
      rawEnvelope: raw,
    );

    var next = state.copyWith(
      messages: [msg, ...state.messages],
    );

    switch (env.kind) {
      case BtEnvelopeKind.rotorOffer:
        if (env.confirmCode != null && env.payload.isNotEmpty) {
          next = next.copyWith(
            pendingShare: BtRotorSharePending(
              peerId: peer.id,
              peerName: peer.name,
              confirmCode: env.confirmCode!,
              syncPayload: env.payload,
              poolId: env.poolId ?? 'UNKNOWN',
              initiatedLocally: false,
            ),
            status: 'Rotor/pool offer — confirm code ${env.confirmCode}',
          );
        }
      case BtEnvelopeKind.rotorAck:
        final pending = state.pendingShare;
        if (pending != null &&
            pending.confirmCode == env.confirmCode &&
            pending.peerId == peer.id) {
          final updated = pending.copyWith(remoteConfirmed: true);
          if (updated.initiatedLocally && updated.localConfirmed) {
            next = next.copyWith(
              clearPendingShare: true,
              lastAppliedPoolId: updated.poolId,
              status: 'Rotor share complete — ${updated.poolId}',
            );
          } else {
            next = next.copyWith(
              pendingShare: updated,
              status: 'Peer confirmed code ${env.confirmCode}',
            );
          }
        }
      case BtEnvelopeKind.rotorReject:
        if (state.pendingShare?.confirmCode == env.confirmCode) {
          next = next.copyWith(
            clearPendingShare: true,
            status: 'Peer rejected rotor share',
          );
        }
      case BtEnvelopeKind.cipher:
      case BtEnvelopeKind.unknown:
        next = next.copyWith(status: 'Cipher inbound from ${peer.name}');
    }

    state = next;
  }

  Future<void> sendCiphertext(String peerId, String payload) async {
    final text = payload.trim();
    if (text.isEmpty) return;
    final envelope = BtEnvelope.cipher(text);
    await _sendEnvelope(peerId, envelope, displayPayload: text);
  }

  /// Offer current pool + rotor sync token; both ends must confirm the
  /// onscreen code before the receiver applies it.
  Future<String?> offerRotorShare({
    required String peerId,
    required PoolSync token,
  }) async {
    final peer = state.peers.cast<BtPeer?>().firstWhere(
          (p) => p?.id == peerId,
          orElse: () => null,
        );
    if (peer == null) {
      state = state.copyWith(status: 'Select a linked peer first');
      return null;
    }
    final code = BtEnvelope.generateConfirmCode();
    final envelope = BtEnvelope.rotorOffer(token: token, confirmCode: code);
    final wrote = await _sendEnvelope(
      peerId,
      envelope,
      displayPayload: 'ROTOR SHARE ${token.poolId}',
      kind: BtEnvelopeKind.rotorOffer,
      confirmCode: code,
      poolId: token.poolId,
    );
    if (!wrote && !state.supported) return null;

    state = state.copyWith(
      pendingShare: BtRotorSharePending(
        peerId: peerId,
        peerName: peer.name,
        confirmCode: code,
        syncPayload: token.encode(),
        poolId: token.poolId,
        initiatedLocally: true,
        localConfirmed: false,
        remoteConfirmed: false,
      ),
      status: 'Confirm code $code with peer',
    );
    return code;
  }

  /// Local operator confirms the onscreen code. Receiver applies pool only
  /// after both local confirm and (for initiator) remote ACK.
  Future<PoolSync?> confirmRotorShare() async {
    final pending = state.pendingShare;
    if (pending == null) return null;

    var updated = pending.copyWith(localConfirmed: true);

    if (!pending.initiatedLocally) {
      // Receiver: ACK the initiator, then apply once both confirmed.
      await _sendEnvelope(
        pending.peerId,
        BtEnvelope.rotorAck(pending.confirmCode),
        displayPayload: 'ACK ${pending.confirmCode}',
        kind: BtEnvelopeKind.rotorAck,
        confirmCode: pending.confirmCode,
      );
      // Receiver treats sending ACK as remote side still needing their confirm;
      // we apply when local is confirmed (peer already showed the code by sending).
      updated = updated.copyWith(remoteConfirmed: true);
      final token = PoolSync.tryParse(pending.syncPayload);
      if (token == null || token.isExpired || !token.verifyIntegrity()) {
        state = state.copyWith(
          clearPendingShare: true,
          status: 'Invalid / expired rotor share',
        );
        return null;
      }
      state = state.copyWith(
        pendingShare: updated,
        clearPendingShare: true,
        lastAppliedPoolId: token.poolId,
        status: 'Pool aligned — ${token.poolId}',
      );
      return token;
    }

    // Initiator: wait for peer ACK (remoteConfirmed) before completing.
    if (!updated.remoteConfirmed) {
      state = state.copyWith(
        pendingShare: updated,
        status: 'Waiting for peer to confirm ${pending.confirmCode}',
      );
      return null;
    }

    state = state.copyWith(
      pendingShare: updated,
      clearPendingShare: true,
      lastAppliedPoolId: pending.poolId,
      status: 'Rotor share complete — ${pending.poolId}',
    );
    return null;
  }

  Future<void> rejectRotorShare() async {
    final pending = state.pendingShare;
    if (pending == null) return;
    if (!pending.initiatedLocally) {
      await _sendEnvelope(
        pending.peerId,
        BtEnvelope.rotorReject(pending.confirmCode),
        displayPayload: 'REJECT ${pending.confirmCode}',
        kind: BtEnvelopeKind.rotorReject,
        confirmCode: pending.confirmCode,
      );
    }
    state = state.copyWith(
      clearPendingShare: true,
      status: 'Rotor share cancelled',
    );
  }

  /// When initiator already confirmed locally and ACK arrives later, finalize.
  void maybeFinalizeInitiatorShare() {
    final pending = state.pendingShare;
    if (pending == null) return;
    if (pending.initiatedLocally &&
        pending.localConfirmed &&
        pending.remoteConfirmed) {
      state = state.copyWith(
        clearPendingShare: true,
        lastAppliedPoolId: pending.poolId,
        status: 'Rotor share complete — ${pending.poolId}',
      );
    }
  }

  Future<bool> _sendEnvelope(
    String peerId,
    BtEnvelope envelope, {
    required String displayPayload,
    BtEnvelopeKind? kind,
    String? confirmCode,
    String? poolId,
  }) async {
    try {
      final wrote = await bleWriteImpl(peerId, envelope.encode());
      final peer = state.peers.cast<BtPeer?>().firstWhere(
            (p) => p?.id == peerId,
            orElse: () => null,
          );
      state = state.copyWith(
        messages: [
          BtMessage(
            fromId: 'local',
            fromName: state.localName,
            payload: displayPayload,
            at: DateTime.now(),
            outbound: true,
            kind: kind ?? envelope.kind,
            confirmCode: confirmCode ?? envelope.confirmCode,
            poolId: poolId ?? envelope.poolId,
            rawEnvelope: envelope.encode(),
          ),
          ...state.messages,
        ],
        status: wrote
            ? 'Sent to ${peer?.name ?? peerId}'
            : 'No writable GATT on peer — kept local',
      );
      return wrote;
    } catch (e) {
      state = state.copyWith(status: 'Send failed: $e');
      return false;
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
