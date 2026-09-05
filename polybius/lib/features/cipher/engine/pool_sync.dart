import 'dart:convert';
import 'dart:typed_data';

import 'package:polybius/core/crypto/aead.dart';
import 'package:polybius/core/crypto/hybrid_kem.dart';
import 'package:polybius/core/crypto/unique_qr.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';

/// Public-key alignment token. Carries only a Kyber public key + unique id.
/// The seed / emoji pool is never serialized.
class PoolSync {
  const PoolSync({
    required this.id,
    required this.publicKey,
    required this.fingerprint,
    required this.expiresAt,
  });

  final String id;
  final Uint8List publicKey;
  final String fingerprint;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool verifyIntegrity() =>
      HybridKem.fingerprint(publicKey) == fingerprint;

  String encode() {
    final json = {
      'v': 3,
      't': 'pk',
      'id': id,
      'pk': base64Encode(publicKey),
      'fp': fingerprint,
      'e': expiresAt.millisecondsSinceEpoch,
    };
    return base64Url.encode(utf8.encode(jsonEncode(json)));
  }

  List<String> qrFrames() => UniqueQrCodec.split(encode(), sid: id);

  static PoolSync? tryParse(String raw) {
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(raw.trim())))
          as Map<String, dynamic>;
      if (decoded['v'] != 3 || decoded['t'] != 'pk') return null;
      final pk = Uint8List.fromList(base64Decode(decoded['pk'] as String));
      return PoolSync(
        id: decoded['id'] as String,
        publicKey: pk,
        fingerprint: decoded['fp'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(decoded['e'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  static PoolSync fromPublicKey(
    Uint8List publicKey, {
    Duration window = const Duration(hours: 6),
  }) {
    return PoolSync(
      id: base64Url.encode(AesGcmAead.randomBytes(16)),
      publicKey: publicKey,
      fingerprint: HybridKem.fingerprint(publicKey),
      expiresAt: DateTime.now().add(window),
    );
  }

  static String poolIdFor(Uint8List publicKey) =>
      CipherEngine.poolIdFor(publicKey);
}
