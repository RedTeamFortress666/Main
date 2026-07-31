import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';

class _MemorySecretStore implements PolybiusSecretStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }
}

void main() {
  group('EncryptionService payloads', () {
    test('encrypt uses a fresh IV per message', () async {
      final service = EncryptionService(_MemorySecretStore());
      await service.init();

      final a = service.encrypt('same plaintext');
      final b = service.encrypt('same plaintext');

      expect(a, isNot(equals(b)));
      expect(a, startsWith('v2:'));
      expect(service.decrypt(a), 'same plaintext');
      expect(service.decrypt(b), 'same plaintext');
    });

    test('fresh install binds the working key to a device id', () async {
      final service = EncryptionService(_MemorySecretStore());
      await service.init();
      expect(service.deviceBound, isTrue);
    });

    test('decrypts legacy static-IV payloads', () async {
      final store = _MemorySecretStore();
      final keyBytes = List<int>.generate(32, (i) => i);
      final ivBytes = List<int>.generate(16, (i) => 100 + i);
      await store.write('polybius_aes_key', base64Encode(keyBytes));
      await store.write('polybius_aes_iv', base64Encode(ivBytes));

      final legacyEncrypter = enc.Encrypter(
        enc.AES(enc.Key(Uint8List.fromList(keyBytes)), mode: enc.AESMode.cbc),
      );
      final legacyPayload = legacyEncrypter
          .encrypt('legacy secret', iv: enc.IV(Uint8List.fromList(ivBytes)))
          .base64;

      final service = EncryptionService(store);
      await service.init();

      expect(service.decrypt(legacyPayload), 'legacy secret');
    });
  });

  group('Password and PIN hashing', () {
    test('PBKDF2 hash verifies and is salted', () {
      final h1 = EncryptionService.hashPassword('hunter2');
      final h2 = EncryptionService.hashPassword('hunter2');

      expect(h1, isNot(equals(h2)));
      expect(h1, startsWith('pbkdf2:'));
      expect(EncryptionService.verifyPassword('hunter2', h1), isTrue);
      expect(EncryptionService.verifyPassword('wrong', h1), isFalse);
      expect(EncryptionService.isLegacyHash(h1), isFalse);
    });

    test('legacy sha256 password hashes still verify', () {
      final legacy =
          sha256.convert(utf8.encode('polybius_salt_v1::developer')).toString();

      expect(EncryptionService.isLegacyHash(legacy), isTrue);
      expect(EncryptionService.verifyPassword('developer', legacy), isTrue);
      expect(EncryptionService.verifyPassword('nope', legacy), isFalse);
    });

    test('PIN hashing round-trips and rejects wrong PIN', () {
      final hash = EncryptionService.hashPin('123456');

      expect(EncryptionService.verifyPin('123456', hash), isTrue);
      expect(EncryptionService.verifyPin('654321', hash), isFalse);
    });

    test('legacy PIN hashes still verify', () {
      final legacy = sha256.convert(utf8.encode('pin::000000')).toString();

      expect(EncryptionService.verifyPin('000000', legacy), isTrue);
      expect(EncryptionService.verifyPin('111111', legacy), isFalse);
    });
  });
}
