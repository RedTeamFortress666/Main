/// Shared Polybius BLE GATT identifiers — identical on PORTAL (HQ) and V.1 (USER).
library;

class PolybiusBle {
  /// Primary service advertised by every Polybius operator phone.
  static const serviceUuid = '6b1a0100-b1b5-4e0c-9a7e-706f6c796269';

  /// Central → peripheral writes (inbound ciphertext / envelopes).
  static const rxUuid = '6b1a0101-b1b5-4e0c-9a7e-706f6c796269';

  /// Peripheral → central notifications (outbound when we are the GATT server).
  static const txUuid = '6b1a0102-b1b5-4e0c-9a7e-706f6c796269';

  /// Legacy scan name token (still accepted) + short advertise localName.
  static const nameToken = 'POLYBIUS';

  /// Manufacturer company id (arbitrary Polybius marker for scan response).
  static const manufacturerId = 0x5042; // 'PB'
}
