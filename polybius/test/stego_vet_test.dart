import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/roundtable/traffic_sketch.dart';
import 'package:polybius/features/stego/stego_receipt.dart';
import 'package:polybius/features/stego/stego_vet.dart';

void main() {
  test('fingerprint is decoy-only and does not contain HELLO', () {
    final engine = CipherEngine(
      seed: 'v2-protocol-seed',
      at: DateTime.utc(2026, 8, 31),
      stego: true,
    );
    final cipher = engine.encrypt('HELLO');
    final fp = StegoFingerprint.of(engine, cipher);
    expect(fp.digestHex, isNot(contains('HELLO')));
    expect(cipher, isNot(contains(fp.digestHex)));
  });

  test('authority mints a verifiable receipt and hides notes from it', () {
    final authority = StegoVetAuthority(
      Uint8List.fromList(List<int>.filled(32, 7)),
      origin: 'sidecar',
    );
    final out = authority.vet(
      fingerprint: const StegoFingerprint(digestHex: 'abc123def456', decoyCount: 2),
      sketch: const TrafficSketch(
        gapsMs: [200, 180, 500, 160, 220, 700],
        decoyCount: 2,
      ),
    );
    expect(authority.verify(out.receipt), isTrue);
    expect(out.receipt.toJson().containsKey('notes'), isFalse);
    expect(out.receipt.fingerprintPrefix, 'abc123de');
    expect(out.report.interfered, isFalse);
    expect(authority.noteFor(out.receipt.id), isNotNull);
  });

  test('a different authority cannot mint a PASS the first will accept', () {
    final a = StegoVetAuthority(Uint8List.fromList(List<int>.filled(32, 1)));
    final b = StegoVetAuthority(Uint8List.fromList(List<int>.filled(32, 2)));
    final forged = StegoReceipt(
      id: 'x',
      status: VetStatus.pass,
      atMs: 1,
      fingerprintPrefix: 'ffffffff',
      mac: 'nope',
    );
    expect(a.verify(forged), isFalse);
    expect(b.verify(forged), isFalse);
    final real = a.vet(
      fingerprint: const StegoFingerprint(
        digestHex: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        decoyCount: 0,
      ),
    );
    expect(b.verify(real.receipt), isFalse);
    expect(a.verify(real.receipt), isTrue);
  });
}
