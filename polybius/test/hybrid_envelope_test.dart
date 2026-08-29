import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/crypto/hybrid_envelope.dart';

void main() {
  test('X25519 + AES-256-GCM round-trips', () async {
    final env = HybridEnvelope();
    final recipient = await env.generateClassicKeyPair();
    final pub = await recipient.extractPublicKey();
    final wire = await env.seal(
      plaintext: 'MIDNIGHT CLIMAX'.codeUnits,
      peerClassicPublic: pub.bytes,
    );
    final clear = await env.open(wire: wire, recipientClassic: recipient);
    expect(String.fromCharCodes(clear), 'MIDNIGHT CLIMAX');
  });

  test('wrong recipient cannot open', () async {
    final env = HybridEnvelope();
    final alice = await env.generateClassicKeyPair();
    final bob = await env.generateClassicKeyPair();
    final alicePub = await alice.extractPublicKey();
    final wire = await env.seal(
      plaintext: [1, 2, 3],
      peerClassicPublic: alicePub.bytes,
    );
    expect(
      () => env.open(wire: wire, recipientClassic: bob),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
