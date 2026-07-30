import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:polybius/core/storage/polybius_secret_store.dart';

/// Wraps AES encryption for Hive payloads and sensitive local data.
///
/// Payload format `v2:<ivB64>:<cipherB64>` uses a random IV per message.
/// Legacy payloads (no prefix) were encrypted with a single stored IV and
/// remain readable for migration.
class EncryptionService {
  EncryptionService(this._storage);

  final PolybiusSecretStore _storage;
  static const _keyName = 'polybius_aes_key';
  static const _ivName = 'polybius_aes_iv';
  static const _v2Prefix = 'v2:';

  static const _pbkdf2Iterations = 10000;
  static const _pbkdf2Prefix = 'pbkdf2';

  enc.Key? _key;
  enc.IV? _legacyIv;

  Future<void> init() async {
    var keyB64 = await _storage.read(_keyName);
    if (keyB64 == null) {
      keyB64 = base64Encode(_randomBytes(32));
      await _storage.write(_keyName, keyB64);
    }
    _key = enc.Key(Uint8List.fromList(base64Decode(keyB64)));

    // Legacy static IV: only needed to decrypt payloads written before v2.
    final ivB64 = await _storage.read(_ivName);
    if (ivB64 != null) {
      _legacyIv = enc.IV(Uint8List.fromList(base64Decode(ivB64)));
    }
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  String encrypt(String plain) {
    final iv = enc.IV(Uint8List.fromList(_randomBytes(16)));
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    final cipher = encrypter.encrypt(plain, iv: iv).base64;
    return '$_v2Prefix${iv.base64}:$cipher';
  }

  String decrypt(String cipher) {
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    if (cipher.startsWith(_v2Prefix)) {
      final parts = cipher.substring(_v2Prefix.length).split(':');
      final iv = enc.IV(Uint8List.fromList(base64Decode(parts[0])));
      return encrypter.decrypt64(parts[1], iv: iv);
    }
    final legacyIv = _legacyIv;
    if (legacyIv == null) {
      throw StateError('No legacy IV available for pre-v2 payload');
    }
    return encrypter.decrypt64(cipher, iv: legacyIv);
  }

  /// PBKDF2-HMAC-SHA256 with a random per-credential salt.
  /// Format: `pbkdf2:<iterations>:<saltB64>:<hashB64>`.
  static String hashPassword(String password) =>
      _pbkdf2Hash('pw::$password');

  static String hashPin(String pin) => _pbkdf2Hash('pin::$pin');

  static bool verifyPassword(String password, String stored) =>
      _verify('pw::$password', stored, _legacyPasswordHash(password));

  static bool verifyPin(String pin, String stored) =>
      _verify('pin::$pin', stored, _legacyPinHash(pin));

  static bool isLegacyHash(String stored) =>
      !stored.startsWith('$_pbkdf2Prefix:');

  static String _pbkdf2Hash(String input) {
    final salt = _randomBytes(16);
    final hash = _pbkdf2(utf8.encode(input), salt, _pbkdf2Iterations, 32);
    return '$_pbkdf2Prefix:$_pbkdf2Iterations:${base64Encode(salt)}:${base64Encode(hash)}';
  }

  static bool _verify(String input, String stored, String legacyHash) {
    if (isLegacyHash(stored)) {
      return _constantTimeEquals(utf8.encode(legacyHash), utf8.encode(stored));
    }
    final parts = stored.split(':');
    if (parts.length != 4) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1 || iterations > 1000000) {
      return false;
    }
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = _pbkdf2(utf8.encode(input), salt, iterations, expected.length);
    return _constantTimeEquals(actual, expected);
  }

  // Pre-PBKDF2 hashes kept only to verify (and then upgrade) old accounts.
  static String _legacyPasswordHash(String password) =>
      sha256.convert(utf8.encode('polybius_salt_v1::$password')).toString();

  static String _legacyPinHash(String pin) =>
      sha256.convert(utf8.encode('pin::$pin')).toString();

  static Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int length,
  ) {
    final hmac = Hmac(sha256, password);
    final blockCount = (length / 32).ceil();
    final output = <int>[];
    for (var block = 1; block <= blockCount; block++) {
      var u = hmac.convert([
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ]).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var k = 0; k < t.length; k++) {
          t[k] ^= u[k];
        }
      }
      output.addAll(t);
    }
    return Uint8List.fromList(output.sublist(0, length));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
