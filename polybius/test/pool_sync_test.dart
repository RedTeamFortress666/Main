import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/crypto/hybrid_kem.dart';
import 'package:polybius/core/crypto/kyber_keystore.dart';
import 'package:polybius/core/crypto/unique_qr.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';

class _MemorySecretStore implements PolybiusSecretStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

void main() {
  test('public-key share round-trips and never includes a seed', () async {
    final ks = KyberKeystore(_MemorySecretStore());
    await ks.init();
    final token = PoolSync.fromPublicKey(ks.publicKey);
    final wire = token.encode();
    expect(wire.contains('seed'), isFalse);
    expect(wire.toLowerCase().contains('"s"'), isFalse);

    final parsed = PoolSync.tryParse(wire);
    expect(parsed, isNotNull);
    expect(parsed!.verifyIntegrity(), isTrue);
    expect(parsed.fingerprint, HybridKem.fingerprint(ks.publicKey));
    expect(parsed.publicKey, ks.publicKey);

    final frames = token.qrFrames();
    expect(frames, isNotEmpty);
    expect(UniqueQrCodec.join(frames), wire);
  });

  test('two shares of the same key produce unique ids', () async {
    final ks = KyberKeystore(_MemorySecretStore());
    await ks.init();
    final a = PoolSync.fromPublicKey(ks.publicKey);
    final b = PoolSync.fromPublicKey(ks.publicKey);
    expect(a.id, isNot(equals(b.id)));
    expect(a.encode(), isNot(equals(b.encode())));
  });

  test('tampered fingerprint fails integrity', () async {
    final ks = KyberKeystore(_MemorySecretStore());
    await ks.init();
    final token = PoolSync.fromPublicKey(ks.publicKey);
    final bad = PoolSync(
      id: token.id,
      publicKey: token.publicKey,
      fingerprint: 'DEADBEEFDEADBEEF',
      expiresAt: token.expiresAt,
    );
    expect(bad.verifyIntegrity(), isFalse);
  });
}
