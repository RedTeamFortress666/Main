import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:polybius/core/crypto/aead.dart';
import 'package:polybius/core/crypto/hybrid_kem.dart';
import 'package:polybius/core/crypto/kyber_keystore.dart';

/// Hybrid message cipher. Ciphertext is a Kyber+AES envelope — never an
/// emoji pair that encodes a plaintext index, and never a pool seed.
class CipherEngine {
  CipherEngine({
    required this.keystore,
    Uint8List? recipientPublicKey,
  }) : recipientPublicKey = recipientPublicKey ?? keystore.publicKey;

  final KyberKeystore keystore;
  Uint8List recipientPublicKey;

  String get fingerprint => HybridKem.fingerprint(recipientPublicKey);

  /// Public identity tag derived from the local Kyber public key — not a seed.
  String get poolId => poolIdFor(keystore.publicKey);

  /// Encrypt plaintext to a unique hybrid envelope (unique KEM ct + nonce).
  String encrypt(String plaintext) {
    final env = keystore.seal(recipientPublicKey, utf8.encode(plaintext));
    return env.encode();
  }

  /// Decrypt with the local Kyber private key only.
  String decrypt(String envelope) {
    final env = HybridEnvelope.tryParse(envelope);
    if (env == null) return '';
    final plain = keystore.open(env);
    if (plain == null) return '';
    return utf8.decode(plain);
  }

  /// Public-key share token. Unique [id] per QR; private key is never included.
  String publicShareToken() {
    final pk = keystore.publicKey;
    return jsonEncode({
      'v': 3,
      't': 'pk',
      'id': base64Url.encode(AesGcmAead.randomBytes(16)),
      'pk': base64Encode(pk),
      'fp': keystore.fingerprint,
    });
  }

  static Uint8List? parsePublicShare(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['t'] != 'pk' || map['v'] != 3) return null;
      final pk = base64Decode(map['pk'] as String);
      final fp = map['fp'] as String?;
      if (fp != null && HybridKem.fingerprint(Uint8List.fromList(pk)) != fp) {
        return null;
      }
      return Uint8List.fromList(pk);
    } catch (_) {
      return null;
    }
  }

  static String poolIdFor(Uint8List publicKey) =>
      sha256.convert(publicKey).toString().substring(0, 12).toUpperCase();
}
