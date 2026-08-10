/// Shared Bluetooth peer / message models.
library;

import 'package:polybius/features/bluetooth/bluetooth_protocol.dart';

class BtPeer {
  const BtPeer({
    required this.id,
    required this.name,
    this.rssi,
    this.connected = false,
  });

  final String id;
  final String name;
  final int? rssi;
  final bool connected;

  BtPeer copyWith({bool? connected, int? rssi, String? name}) => BtPeer(
        id: id,
        name: name ?? this.name,
        rssi: rssi ?? this.rssi,
        connected: connected ?? this.connected,
      );
}

class BtMessage {
  const BtMessage({
    required this.fromId,
    required this.fromName,
    required this.payload,
    required this.at,
    this.outbound = false,
    this.kind = BtEnvelopeKind.cipher,
    this.confirmCode,
    this.poolId,
    this.rawEnvelope,
  });

  final String fromId;
  final String fromName;
  final String payload;
  final DateTime at;
  final bool outbound;
  final BtEnvelopeKind kind;
  final String? confirmCode;
  final String? poolId;
  final String? rawEnvelope;

  bool get isCipher => kind == BtEnvelopeKind.cipher;
  bool get isRotorOffer => kind == BtEnvelopeKind.rotorOffer;
}

/// Pending mutual-confirm rotor / pool share over Bluetooth.
class BtRotorSharePending {
  const BtRotorSharePending({
    required this.peerId,
    required this.peerName,
    required this.confirmCode,
    required this.syncPayload,
    required this.poolId,
    required this.initiatedLocally,
    this.localConfirmed = false,
    this.remoteConfirmed = false,
  });

  final String peerId;
  final String peerName;
  final String confirmCode;
  final String syncPayload;
  final String poolId;
  final bool initiatedLocally;
  final bool localConfirmed;
  final bool remoteConfirmed;

  bool get bothConfirmed => localConfirmed && remoteConfirmed;

  BtRotorSharePending copyWith({
    bool? localConfirmed,
    bool? remoteConfirmed,
  }) =>
      BtRotorSharePending(
        peerId: peerId,
        peerName: peerName,
        confirmCode: confirmCode,
        syncPayload: syncPayload,
        poolId: poolId,
        initiatedLocally: initiatedLocally,
        localConfirmed: localConfirmed ?? this.localConfirmed,
        remoteConfirmed: remoteConfirmed ?? this.remoteConfirmed,
      );
}
