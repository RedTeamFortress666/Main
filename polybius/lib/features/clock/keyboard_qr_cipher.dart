import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:polybius/features/clock/session_binary_key.dart';

/// AES-CBC + HMAC envelope that only a Polybius keyboard session can open.
class KeyboardQrCipher {
  KeyboardQrCipher._();

  static const appId = 'PBK';
  static const _domain = 'polybius-keyboard-qr';

  static enc.Key _aesKey(String sessionKey) {
    final secret = SessionBinaryKey.decode(sessionKey);
    final digest = Hmac(sha256, utf8.encode(_domain)).convert(secret);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  static String seal(String sessionKey, List<int> plaintext) {
    final key = _aesKey(sessionKey);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final cipher = encrypter.encryptBytes(plaintext, iv: iv);
    final mac = Hmac(sha256, key.bytes)
        .convert([...iv.bytes, ...cipher.bytes])
        .bytes;
    return jsonEncode({
      'v': 1,
      'app': appId,
      'iv': iv.base64,
      'ct': cipher.base64,
      'mac': base64Encode(mac),
    });
  }

  static List<int>? open(String sessionKey, String envelope) {
    try {
      final map = jsonDecode(envelope) as Map<String, dynamic>;
      if (map['app'] != appId || map['v'] != 1) return null;
      final key = _aesKey(sessionKey);
      final iv = enc.IV.fromBase64(map['iv'] as String);
      final cipher = enc.Encrypted.fromBase64(map['ct'] as String);
      final mac = base64Decode(map['mac'] as String);
      final expect = Hmac(sha256, key.bytes)
          .convert([...iv.bytes, ...cipher.bytes])
          .bytes;
      if (!_constEq(mac, expect)) return null;
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decryptBytes(cipher, iv: iv);
    } catch (_) {
      return null;
    }
  }

  static bool _constEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var d = 0;
    for (var i = 0; i < a.length; i++) {
      d |= a[i] ^ b[i];
    }
    return d == 0;
  }
}
