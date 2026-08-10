/// Shared Bluetooth peer / message models.
library;

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
  });

  final String fromId;
  final String fromName;
  final String payload;
  final DateTime at;
  final bool outbound;
}
