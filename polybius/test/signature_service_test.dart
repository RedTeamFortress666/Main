import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/crypto/signature_service.dart';

Future<(String pubB64, List<int> privSeed)> _newKeyPair() async {
  final algo = Ed25519();
  final kp = await algo.newKeyPair();
  final priv = await kp.extractPrivateKeyBytes();
  final pub = await kp.extractPublicKey();
  return (base64Encode(pub.bytes), priv);
}

void main() {
  group('SignatureService', () {
    test('verifies a valid detached signature and rejects tampering', () async {
      final (pubB64, priv) = await _newKeyPair();
      final svc = SignatureService(publicKeyB64: pubB64);

      final message = utf8.encode('polybius-invite');
      final sig = await SignatureService.signBytes(message, priv);

      expect(await svc.verifyBytes(message, sig), isTrue);
      expect(await svc.verifyBytes(utf8.encode('polybius-inv1te'), sig), isFalse);
    });

    test('rejects a signature from a different key', () async {
      final (pubB64, priv) = await _newKeyPair();
      final (otherPub, _) = await _newKeyPair();

      final message = utf8.encode('m');
      final sig = await SignatureService.signBytes(message, priv);

      expect(await SignatureService(publicKeyB64: pubB64).verifyBytes(message, sig),
          isTrue);
      expect(await SignatureService(publicKeyB64: otherPub).verifyBytes(message, sig),
          isFalse);
    });

    test('update payload verification detects tampering', () async {
      final (pubB64, priv) = await _newKeyPair();
      final svc = SignatureService(publicKeyB64: pubB64);

      final payload = utf8.encode('a fake update binary payload');
      final sig = await SignatureService.signPayload(payload, priv);

      expect(await svc.verifyPayload(payload, sig), isTrue);
      expect(await svc.verifyPayload(utf8.encode('tampered payload'), sig), isFalse);
    });
  });

  group('SignedToken', () {
    test('mints, encodes, parses and verifies a token', () async {
      final (pubB64, priv) = await _newKeyPair();
      final svc = SignatureService(publicKeyB64: pubB64);

      final token = await SignedToken.mint(
        fileNumber: 'PB-ABC123',
        tier: 'developer',
        privateSeed: priv,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      final wire = token.encode();
      final parsed = SignedToken.tryParse(wire);

      expect(parsed, isNotNull);
      expect(parsed!.fileNumber, 'PB-ABC123');
      expect(parsed.tier, 'developer');
      expect(await svc.verifyToken(parsed), isTrue);
    });

    test('rejects an expired token even with a valid signature', () async {
      final (pubB64, priv) = await _newKeyPair();
      final svc = SignatureService(publicKeyB64: pubB64);

      final expired = await SignedToken.mint(
        fileNumber: 'PB-OLD',
        tier: 'user',
        privateSeed: priv,
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
