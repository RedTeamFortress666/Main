import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/bluetooth/bluetooth_protocol.dart';
import 'package:polybius/features/bluetooth/bluetooth_uuids.dart';

void main() {
  test('Polybius BLE UUIDs are stable across flavors', () {
    expect(PolybiusBle.serviceUuid, startsWith('6b1a0100'));
    expect(PolybiusBle.rxUuid, startsWith('6b1a0101'));
    expect(PolybiusBle.txUuid, startsWith('6b1a0102'));
    expect(PolybiusBle.nameToken, 'POLYBIUS');
  });

  test('PB1 envelopes round-trip for cipher chat', () {
    final env = BtEnvelope.cipher('🐸🧪');
    final raw = env.encode();
    expect(raw.startsWith('PB1|'), isTrue);
    final parsed = BtEnvelope.parse(raw);
    expect(parsed.kind, BtEnvelopeKind.cipher);
    expect(parsed.payload, '🐸🧪');
  });
}
