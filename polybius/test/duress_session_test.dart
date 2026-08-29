import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/duress/cabinet_identity.dart';
import 'package:polybius/features/duress/duress_session.dart';

void main() {
  test('cover seed differs from the real seed and is PIN-bound', () {
    const real = 'real-seed';
    const salt = 'salt';
    final a = DuressSession.deriveSeed(realSeed: real, salt: salt, pin: '666000');
    final b = DuressSession.deriveSeed(realSeed: real, salt: salt, pin: '666000');
    final c = DuressSession.deriveSeed(realSeed: real, salt: salt, pin: '000000');
    expect(a, b);
    expect(a, isNot(equals(c)));
    expect(a, isNot(equals(real)));
  });

  test('cover ciphertext does not decrypt on the real engine', () {
    const real = 'real-seed';
    final at = DateTime.utc(2026, 8, 29, 0);
    final cabinet = CabinetIdentity(
      duressPinHash: EncryptionService.hashPin('666000'),
      coverInitials: 'CLX',
      coverPlaintext: 'HIGH SCORE AT DAWN',
      coverSalt: 'salt',
    );
    final session = DuressSession.arm(
      cabinet: cabinet,
      realSeed: real,
      pin: '666000',
    );
    final coverEngine = CipherEngine(
      seed: session.effectiveSeed,
      at: at,
      stego: false,
    );
    final realEngine = CipherEngine(seed: real, at: at, stego: false);
    final ct = coverEngine.encrypt('HIGH SCORE AT DAWN');
    expect(coverEngine.decrypt(ct), 'HIGH SCORE AT DAWN');
    expect(realEngine.decrypt(ct), isNot(equals('HIGH SCORE AT DAWN')));
  });
}
