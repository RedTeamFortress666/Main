import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:polybius/core/storage/polybius_secret_store.dart';

/// Wraps AES encryption for Hive payloads and sensitive local data.
class EncryptionService {
  EncryptionService(this._storage);

  final PolybiusSecretStore _storage;
  static const _keyName = 'polybius_aes_key';
  static const _ivName = 'polybius_aes_iv';

  enc.Key? _key;
  enc.IV? _iv;

  Future<void> init() async {
    var keyB64 = await _storage.read(_keyName);
    var ivB64 = await _storage.read(_ivName);
    if (keyB64 == null || ivB64 == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
      keyB64 = base64Encode(keyBytes);
      ivB64 = base64Encode(ivBytes);
      await _storage.write(_keyName, keyB64);
      await _storage.write(_ivName, ivB64);
    }
    _key = enc.Key(Uint8List.fromList(base64Decode(keyB64)));
    _iv = enc.IV(Uint8List.fromList(base64Decode(ivB64)));
  }

  String encrypt(String plain) {
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    return encrypter.encrypt(plain, iv: _iv!).base64;
  }

  String decrypt(String cipher) {
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(cipher, iv: _iv!);
  }

  static String hashPassword(String password, {String? salt}) {
    final s = salt ?? 'polybius_salt_v1';
    return sha256.convert(utf8.encode('$s::$password')).toString();
  }

  static String hashPin(String pin) =>
      sha256.convert(utf8.encode('pin::$pin')).toString();
}
