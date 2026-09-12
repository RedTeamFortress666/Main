import 'dart:typed_data';

import 'package:polybius/core/crypto/hybrid_envelope.dart';
import 'package:pqcrypto/pqcrypto.dart';

/// FIPS 203 ML-KEM-768 (Kyber-768 parameter set) filling [PqKem].
///
/// This is a real encapsulation, not a hash stub: public key 1184 B,
/// secret 2400 B, ciphertext 1088 B, shared secret 32 B. Combined with
/// X25519 in [HybridEnvelope] as HKDF(X25519_ss || MLKEM_ss).
///
/// Honest limits: `pqcrypto` tracks FIPS 203 and ships KATs; it is **not**
/// a CMVP/FIPS 140 module. A broken or swapped implementation is still a
/// [client.owned] residual.
class MlKem768 implements PqKem {
  const MlKem768();

  static const int publicKeyBytes = 1184;
  static const int secretKeyBytes = 2400;
  static const int ciphertextBytes = 1088;
  static const int sharedSecretBytes = 32;

  static final KyberKem _kem = PqcKem.kyber768;

  @override
  String get id => 'ml-kem-768';

  (Uint8List publicKey, Uint8List secretKey) generateKeyPair() {
    final (pk, sk) = _kem.generateKeyPair();
    return (Uint8List.fromList(pk), Uint8List.fromList(sk));
  }

  @override
  Future<PqEncapsulation> encaps(Uint8List peerPublic) async {
    if (peerPublic.length != publicKeyBytes) {
      throw FormatException('ML-KEM-768 PK ${peerPublic.length}');
    }
    final (ct, ss) = _kem.encapsulate(peerPublic);
    return PqEncapsulation(
      ciphertext: Uint8List.fromList(ct),
      sharedSecret: Uint8List.fromList(ss),
    );
  }

  @override
  Future<Uint8List> decaps(Uint8List secretKey, Uint8List ciphertext) async {
    if (secretKey.length != secretKeyBytes) {
      throw FormatException('ML-KEM-768 SK ${secretKey.length}');
    }
    if (ciphertext.length != ciphertextBytes) {
      throw FormatException('ML-KEM-768 CT ${ciphertext.length}');
    }
    return Uint8List.fromList(_kem.decapsulate(secretKey, ciphertext));
  }
}
