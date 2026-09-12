import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/crypto/hybrid_envelope.dart';
import 'package:polybius/core/crypto/ml_kem_768.dart';

void main() {
  test('ML-KEM-768 sizes match FIPS 203 and encaps/decaps agree', () async {
    const kem = MlKem768();
    expect(kem.id, 'ml-kem-768');
    final (pk, sk) = kem.generateKeyPair();
    expect(pk.length, MlKem768.publicKeyBytes);
    expect(sk.length, MlKem768.secretKeyBytes);
    final enc = await kem.encaps(pk);
    expect(enc.ciphertext.length, MlKem768.ciphertextBytes);
    expect(enc.sharedSecret.length, MlKem768.sharedSecretBytes);
    final opened = await kem.decaps(sk, enc.ciphertext);
    expect(opened, enc.sharedSecret);
  });

  test('hybrid envelope with Kyber will not open without the PQ secret',
      () async {
    const kem = MlKem768();
    final env = HybridEnvelope(pqKem: kem);
    final classic = await env.generateClassicKeyPair();
    final classicPub = await classic.extractPublicKey();
    final (pqPk, pqSk) = kem.generateKeyPair();

    final wire = await env.seal(
      plaintext: 'MIDNIGHT CLIMAX'.codeUnits,
      peerClassicPublic: classicPub.bytes,
      peerPqPublic: pqPk,
    );
    expect(wire[5] & HybridEnvelope.flagHasPq, isNonZero);

    expect(
      () => env.open(wire: wire, recipientClassic: classic),
      throwsA(isA<FormatException>()),
    );

    final clear = await env.open(
      wire: wire,
      recipientClassic: classic,
      recipientPqSecret: pqSk,
    );
    expect(String.fromCharCodes(clear), 'MIDNIGHT CLIMAX');
  });

  test('wrong classic recipient still fails even with the Kyber secret',
      () async {
    const kem = MlKem768();
    final env = HybridEnvelope(pqKem: kem);
    final alice = await env.generateClassicKeyPair();
    final bob = await env.generateClassicKeyPair();
    final alicePub = await alice.extractPublicKey();
    final (pqPk, pqSk) = kem.generateKeyPair();
    final wire = await env.seal(
      plaintext: [9, 8, 7],
      peerClassicPublic: alicePub.bytes,
      peerPqPublic: pqPk,
    );
    expect(
      () => env.open(
        wire: wire,
        recipientClassic: bob,
        recipientPqSecret: pqSk,
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
