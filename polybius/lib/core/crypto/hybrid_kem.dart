import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pqcrypto/pqcrypto.dart' hide sha256;
import 'package:polybius/core/crypto/aead.dart';

/// Hybrid ML-KEM-768 (Kyber) + AES-256-GCM envelope.
///
/// Forward pass: each [seal] call runs a fresh Kyber encapsulation, so the
/// ciphertext (and therefore every QR) is unique even for identical plaintext
/// and the same recipient public key. The Kyber *private* key never appears in
/// the envelope — it is used only locally in [open].
class HybridKem {
  HybridKem._();

  static const version = 3;
  static const alg = 'mlkem768-aes256gcm';
  static const _kdfInfo = 'polybius-darth-cherry-v3';

  static final _kem = PqcKem.kyber768;

  static (Uint8List pk, Uint8List sk) generateKeyPair() {
    final (pk, sk) = _kem.generateKeyPair();
    return (pk, sk);
  }

  static String fingerprint(Uint8List publicKey) =>
      sha256.convert(publicKey).toString().substring(0, 16).toUpperCase();

  static Uint8List _aesKey(Uint8List sharedSecret) {
    return Uint8List.fromList(
      Hmac(sha256, sharedSecret).convert(utf8.encode(_kdfInfo)).bytes,
    );
  }

  /// Encapsulate to [recipientPk] and AEAD-seal [plaintext].
  static HybridEnvelope seal({
    required Uint8List recipientPk,
    required List<int> plaintext,
  }) {
    final (kemCt, ss) = _kem.encapsulate(recipientPk);
    final key = _aesKey(ss);
    final aad = Uint8List.fromList([...kemCt, ...utf8.encode(alg)]);
    final sealed = AesGcmAead.encrypt(
      key: key,
      plaintext: Uint8List.fromList(plaintext),
      aad: aad,
    );
    key.fillRange(0, key.length, 0);
    ss.fillRange(0, ss.length, 0);
    return HybridEnvelope(
      id: base64Url.encode(AesGcmAead.randomBytes(16)),
      kemCt: kemCt,
      aead: sealed,
      recipientFp: fingerprint(recipientPk),
    );
  }

  /// Decapsulate with the local private key. Returns null on auth failure.
  static List<int>? open({
    required Uint8List privateKey,
    required HybridEnvelope envelope,
  }) {
    try {
      final ss = _kem.decapsulate(privateKey, envelope.kemCt);
      final key = _aesKey(ss);
      final aad = Uint8List.fromList([...envelope.kemCt, ...utf8.encode(alg)]);
      final plain = AesGcmAead.decrypt(
        key: key,
        sealed: envelope.aead,
        aad: aad,
      );
      key.fillRange(0, key.length, 0);
      ss.fillRange(0, ss.length, 0);
      return plain;
    } catch (_) {
      return null;
    }
  }
}

class HybridEnvelope {
  const HybridEnvelope({
    required this.id,
    required this.kemCt,
    required this.aead,
    required this.recipientFp,
  });

  final String id;
  final Uint8List kemCt;
  final Uint8List aead;
  final String recipientFp;

  Map<String, dynamic> toJson() => {
        'v': HybridKem.version,
        'alg': HybridKem.alg,
        'id': id,
        'kem': base64Encode(kemCt),
        'ct': base64Encode(aead),
        'fp': recipientFp,
      };

  String encode() =>
      base64Url.encode(utf8.encode(jsonEncode(toJson())));

  static HybridEnvelope? tryParse(String raw) {
    try {
      final map = jsonDecode(utf8.decode(base64Url.decode(raw.trim())))
          as Map<String, dynamic>;
      if (map['v'] != HybridKem.version || map['alg'] != HybridKem.alg) {
        return null;
      }
      return HybridEnvelope(
        id: map['id'] as String,
        kemCt: Uint8List.fromList(base64Decode(map['kem'] as String)),
        aead: Uint8List.fromList(base64Decode(map['ct'] as String)),
        recipientFp: map['fp'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
