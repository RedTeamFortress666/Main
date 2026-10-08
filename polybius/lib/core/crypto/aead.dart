import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// AES-256-GCM (128-bit tag). Nonce is 12 random bytes per call.
class AesGcmAead {
  AesGcmAead._();

  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List encrypt({
    required Uint8List key,
    required Uint8List plaintext,
    Uint8List? aad,
  }) {
    final nonce = randomBytes(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(key), 128, nonce, aad ?? Uint8List(0)),
      );
    final out = cipher.process(plaintext);
    return Uint8List.fromList([...nonce, ...out]);
  }

  static Uint8List decrypt({
    required Uint8List key,
    required Uint8List sealed,
    Uint8List? aad,
  }) {
    if (sealed.length < 13) {
      throw ArgumentError('truncated AEAD payload');
    }
    final nonce = sealed.sublist(0, 12);
    final body = sealed.sublist(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(KeyParameter(key), 128, nonce, aad ?? Uint8List(0)),
      );
    return cipher.process(body);
  }

  static String encryptUtf8(Uint8List key, String plain) {
    final sealed = encrypt(key: key, plaintext: Uint8List.fromList(utf8.encode(plain)));
    return 'v3:${base64Encode(sealed)}';
  }

  static String decryptUtf8(Uint8List key, String payload) {
    if (!payload.startsWith('v3:')) {
      throw StateError('not an AEAD v3 payload');
    }
    final sealed = base64Decode(payload.substring(3));
    return utf8.decode(decrypt(key: key, sealed: sealed));
  }
}
