import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:polybius/core/crypto/aead.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';

/// Authenticated encryption for Hive payloads.
///
/// New payloads: `v3:` + AES-256-GCM (random 12-byte nonce, 128-bit tag).
/// `v2:` AES-CBC (random IV, no MAC) remains readable for migration.
/// Pre-v2 static-IV CBC remains readable when a legacy IV is still stored.
class EncryptionService {
  EncryptionService(this._storage);

  final PolybiusSecretStore _storage;
  static const _keyName = 'polybius_aes_key';
  static const _ivName = 'polybius_aes_iv';
  static const _deviceIdName = 'polybius_device_id';
  static const _v2Prefix = 'v2:';
  static const _v3Prefix = 'v3:';

  /// Native keystore-backed stores report true. Web localStorage is obfuscation.
  bool deviceBound = false;

  static const _pbkdf2Iterations = 210000;
  static const _pbkdf2Prefix = 'pbkdf2';

  Uint8List? _key;
  enc.IV? _legacyIv;

  Future<void> init() async {
    var masterB64 = await _storage.read(_keyName);
    final freshInstall = masterB64 == null;
    if (freshInstall) {
      masterB64 = base64Encode(_randomBytes(32));
      await _storage.write(_keyName, masterB64);
    }

    var deviceIdB64 = await _storage.read(_deviceIdName);
    if (deviceIdB64 == null && freshInstall) {
      deviceIdB64 = base64Encode(_randomBytes(16));
      await _storage.write(_deviceIdName, deviceIdB64);
    }

    final master = base64Decode(masterB64);
    if (deviceIdB64 != null) {
      final derived =
          Hmac(sha256, master).convert(base64Decode(deviceIdB64)).bytes;
      _key = Uint8List.fromList(derived);
      deviceBound = true;
    } else {
      _key = Uint8List.fromList(master);
      deviceBound = false;
    }

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
    final sealed = AesGcmAead.encrypt(
      key: _key!,
      plaintext: Uint8List.fromList(utf8.encode(plain)),
    );
    return '$_v3Prefix${base64Encode(sealed)}';
  }

  String decrypt(String cipher) {
    if (cipher.startsWith(_v3Prefix)) {
      final sealed = base64Decode(cipher.substring(_v3Prefix.length));
      return utf8.decode(AesGcmAead.decrypt(key: _key!, sealed: sealed));
    }
    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(_key!), mode: enc.AESMode.cbc),
    );
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

  static String hashPassword(String password) => _pbkdf2Hash('pw::$password');

  static String hashPin(String pin) => _pbkdf2Hash('pin::$pin');

  static bool verifyPassword(String password, String stored) =>
      _verify('pw::$password', stored);

  static bool verifyPin(String pin, String stored) =>
      _verify('pin::$pin', stored);

  static bool isLegacyHash(String stored) =>
      !stored.startsWith('$_pbkdf2Prefix:');

  static String _pbkdf2Hash(String input) {
    final salt = _randomBytes(16);
    final hash = _pbkdf2(utf8.encode(input), salt, _pbkdf2Iterations, 32);
    return '$_pbkdf2Prefix:$_pbkdf2Iterations:${base64Encode(salt)}:${base64Encode(hash)}';
  }

  static bool _verify(String input, String stored) {
    if (isLegacyHash(stored)) {
      return false;
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
