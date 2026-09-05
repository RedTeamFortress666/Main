import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/crypto/hybrid_kem.dart';
import 'package:polybius/core/crypto/kyber_keystore.dart';
import 'package:polybius/core/crypto/unique_qr.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';

class _MemorySecretStore implements PolybiusSecretStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

void main() {
  late KyberKeystore keystore;
  late CipherEngine engine;

  setUp(() async {
    keystore = KyberKeystore(_MemorySecretStore());
    await keystore.init();
    engine = CipherEngine(keystore: keystore);
  });

  test('hybrid round-trip', () {
    const plaintext = 'Hello World 123!';
    final sealed = engine.encrypt(plaintext);
    expect(engine.decrypt(sealed), plaintext);
  });

  test('each seal is unique even for identical plaintext', () {
    final a = engine.encrypt('HELLO');
    final b = engine.encrypt('HELLO');
    expect(a, isNot(equals(b)));
    expect(engine.decrypt(a), 'HELLO');
    expect(engine.decrypt(b), 'HELLO');
  });

  test('ciphertext does not encode plaintext character indexes', () {
    final sealed = engine.encrypt('AAAAA');
    final env = HybridEnvelope.tryParse(sealed);
    expect(env, isNotNull);
    expect(sealed.contains('AAAAA'), isFalse);
    final json = utf8.decode(base64Url.decode(sealed));
    expect(json.contains('AAAAA'), isFalse);
    expect(json.contains('"kem"'), isTrue);
    expect(json.contains('"ct"'), isTrue);
  });

  test('private key never appears in the envelope JSON', () {
    final sealed = engine.encrypt('secret');
    final json = utf8.decode(base64Url.decode(sealed));
    expect(json.contains('"sk"'), isFalse);
    expect(json.contains('polybius_kyber768_sk'), isFalse);
    expect(json.contains(base64Encode(keystore.publicKey)), isFalse);
  });

  test('wrong private key cannot open the envelope', () async {
    final other = KyberKeystore(_MemorySecretStore());
    await other.init();
    final sealed = engine.encrypt('only-for-local');
    expect(CipherEngine(keystore: other).decrypt(sealed), isEmpty);
  });

  test('unique QR frames reassemble and stay unique', () {
    final payload = engine.encrypt('QR-PAYLOAD');
    final a = UniqueQrCodec.split(payload);
    final b = UniqueQrCodec.split(payload);
    expect(a.first, isNot(equals(b.first)));
    expect(UniqueQrCodec.join(a), payload);
    expect(UniqueQrCodec.join(b), payload);
    expect(a.every(UniqueQrCodec.isFrame), isTrue);
  });

  test('QR assembler waits for every unique frame', () {
    final payload = engine.encrypt('ASSEMBLE-ME');
    final frames = UniqueQrCodec.split(payload);
    final assembler = UniqueQrAssembler();
    for (var i = 0; i < frames.length - 1; i++) {
      expect(assembler.add(frames[i]), isNull);
    }
    expect(assembler.add(frames.last), payload);
  });
}
