import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:polybius/core/crypto/signature_service.dart';

SecureRandom _secureRandom() {
  final sr = FortunaRandom();
  final r = Random.secure();
  sr.seed(KeyParameter(
      Uint8List.fromList(List<int>.generate(32, (_) => r.nextInt(256)))));
  return sr;
}

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _keypair() {
  final gen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
      _secureRandom(),
    ));
  final pair = gen.generateKeyPair();
  return AsymmetricKeyPair(
      pair.publicKey as RSAPublicKey, pair.privateKey as RSAPrivateKey);
}

String _modulusB64(RSAPublicKey pub) {
  var v = pub.modulus!;
  final bytes = <int>[];
  while (v > BigInt.zero) {
    bytes.add((v & BigInt.from(0xff)).toInt());
    v = v >> 8;
  }
  return base64Encode(bytes.reversed.toList());
}

void main() {
  group('SignatureService (RSA)', () {
    test('verifies a valid signature and rejects tampering', () {
      final kp = _keypair();
      final svc = SignatureService(modulusB64: _modulusB64(kp.publicKey));

      final message = utf8.encode('polybius-invite');
      final sig = SignatureService.signBytes(message, kp.privateKey);

      expect(svc.verifyBytes(message, sig), isTrue);
      expect(svc.verifyBytes(utf8.encode('polybius-inv1te'), sig), isFalse);
    });

    test('rejects a signature from a different key', () {
      final kp = _keypair();
      final other = _keypair();

      final message = utf8.encode('m');
      final sig = SignatureService.signBytes(message, kp.privateKey);

      expect(SignatureService(modulusB64: _modulusB64(kp.publicKey))
          .verifyBytes(message, sig), isTrue);
      expect(SignatureService(modulusB64: _modulusB64(other.publicKey))
          .verifyBytes(message, sig), isFalse);
    });

    test('update payload verification detects tampering', () async {
      final kp = _keypair();
      final svc = SignatureService(modulusB64: _modulusB64(kp.publicKey));

      final payload = utf8.encode('a fake update binary payload');
      final sig = SignatureService.signPayload(payload, kp.privateKey);

      expect(await svc.verifyPayload(payload, sig), isTrue);
      expect(await svc.verifyPayload(utf8.encode('tampered payload'), sig),
          isFalse);
    });
  });

  group('SignedToken (RSA)', () {
    test('mints, encodes, parses and verifies a token', () async {
      final kp = _keypair();
      final svc = SignatureService(modulusB64: _modulusB64(kp.publicKey));

      final token = SignedToken.mint(
        fileNumber: 'PB-ABC123',
        tier: 'developer',
        privateKey: kp.privateKey,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      final parsed = SignedToken.tryParse(token.encode());

      expect(parsed, isNotNull);
      expect(parsed!.fileNumber, 'PB-ABC123');
      expect(parsed.tier, 'developer');
      expect(await svc.verifyToken(parsed), isTrue);
    });

    test('rejects an expired token even with a valid signature', () async {
      final kp = _keypair();
      final svc = SignatureService(modulusB64: _modulusB64(kp.publicKey));

      final expired = SignedToken.mint(
        fileNumber: 'PB-OLD',
        tier: 'user',
        privateKey: kp.privateKey,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      expect(expired.isExpired, isTrue);
      expect(await svc.verifyToken(expired), isFalse);
    });

    test('tryParse returns null for garbage input', () {
      expect(SignedToken.tryParse('not-a-token'), isNull);
      expect(SignedToken.tryParse(''), isNull);
    });
  });
}
