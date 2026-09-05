import 'dart:convert';
import 'dart:typed_data';

import 'package:polybius/core/crypto/hybrid_kem.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';

/// Device-local ML-KEM-768 keypair. The private key is read only to decapsulate
/// and is never copied into QR payloads, clipboards, or Hive.
class KyberKeystore {
  KyberKeystore(this._store);

  final PolybiusSecretStore _store;

  static const _pkName = 'polybius_kyber768_pk';
  static const _skName = 'polybius_kyber768_sk';

  Uint8List? _pk;
  Uint8List? _sk;

  Future<void> init() async {
    final pkB64 = await _store.read(_pkName);
    final skB64 = await _store.read(_skName);
    if (pkB64 != null && skB64 != null) {
      _pk = base64Decode(pkB64);
      _sk = base64Decode(skB64);
      return;
    }
    final (pk, sk) = HybridKem.generateKeyPair();
    _pk = pk;
    _sk = sk;
    await _store.write(_pkName, base64Encode(pk));
    await _store.write(_skName, base64Encode(sk));
  }

  Uint8List get publicKey {
    final pk = _pk;
    if (pk == null) {
      throw StateError('KyberKeystore.init() has not run');
    }
    return Uint8List.fromList(pk);
  }

  String get fingerprint => HybridKem.fingerprint(publicKey);

  /// Encrypt to [recipientPk]. Local private key is not used and not exported.
  HybridEnvelope seal(Uint8List recipientPk, List<int> plaintext) {
    return HybridKem.seal(recipientPk: recipientPk, plaintext: plaintext);
  }

  /// Decrypt with the local private key (forward-pass local use only).
  List<int>? open(HybridEnvelope envelope) {
    final sk = _sk;
    if (sk == null) {
      throw StateError('KyberKeystore.init() has not run');
    }
    return HybridKem.open(privateKey: sk, envelope: envelope);
  }
}
