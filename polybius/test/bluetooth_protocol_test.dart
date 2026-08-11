import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/bluetooth/bluetooth_protocol.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';

void main() {
  group('BtEnvelope', () {
    test('cipher round-trips and legacy plaintext parses as cipher', () {
      final env = BtEnvelope.cipher('😀😃');
      final encoded = env.encode();
      expect(encoded.startsWith('PB1|'), isTrue);
      final parsed = BtEnvelope.parse(encoded);
      expect(parsed.kind, BtEnvelopeKind.cipher);
      expect(parsed.payload, '😀😃');

      final legacy = BtEnvelope.parse('🔥💧');
      expect(legacy.kind, BtEnvelopeKind.cipher);
      expect(legacy.payload, '🔥💧');
    });

    test('rotor offer carries confirm code + sync token', () {
      final token = PoolSync.fromSeed('test-seed-xyz', complexity: 3);
      final code = BtEnvelope.generateConfirmCode();
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);

      final offer = BtEnvelope.rotorOffer(token: token, confirmCode: code);
      final parsed = BtEnvelope.parse(offer.encode());
      expect(parsed.kind, BtEnvelopeKind.rotorOffer);
      expect(parsed.confirmCode, code);
      expect(parsed.poolId, token.poolId);
      final restored = PoolSync.tryParse(parsed.payload);
      expect(restored, isNotNull);
      expect(restored!.seed, token.seed);
      expect(restored.complexity, 3);
      expect(restored.verifyIntegrity(), isTrue);
    });

    test('ack / reject encode confirm codes', () {
      final ack = BtEnvelope.parse(BtEnvelope.rotorAck('123456').encode());
      expect(ack.kind, BtEnvelopeKind.rotorAck);
      expect(ack.confirmCode, '123456');

      final rej =
          BtEnvelope.parse(BtEnvelope.rotorReject('654321').encode());
      expect(rej.kind, BtEnvelopeKind.rotorReject);
      expect(rej.confirmCode, '654321');
    });
  });
}
