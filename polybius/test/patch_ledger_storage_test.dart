import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/redlight/auto_patcher.dart';
import 'package:polybius/features/redlight/cabinet_policy.dart';
import 'package:polybius/features/redlight/leak_detector.dart';
import 'package:polybius/features/redlight/patch_ledger.dart';

class _MemorySecretStore implements PolybiusSecretStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }
}

PatchLedgerEntry _entry(int seq, String trigger) => PatchLedgerEntry(
      seq: seq,
      trigger: trigger,
      atMs: 1757678400000 + seq,
      openBefore: seq == 1 ? 7 : 0,
      openAfter: 0,
      policyCanonical: CabinetPolicy.woven.canonical,
      results: const [],
    );

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('polybius_ledger');
    final encryption = EncryptionService(_MemorySecretStore());
    await encryption.init();
    storage = StorageService(encryption);
    await storage.init(hivePath: tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('appended entries chain and verify under the device key', () async {
    final a = await storage.appendPatchLedger(_entry(1, 'BASELINE·LOGIN'));
    final b = await storage.appendPatchLedger(_entry(2, 'LOGIN'));
    final c = await storage.appendPatchLedger(_entry(3, 'CHERRY'));

    expect(a.prevMac, isEmpty);
    expect(a.mac, isNotEmpty);
    expect(b.prevMac, a.mac);
    expect(c.prevMac, b.mac);

    final ledger = await storage.getPatchLedger();
    expect(ledger.intact, isTrue);
    expect(ledger.entries.length, 3);
    expect(ledger.latest!.readout, '#3 CHERRY 0→0');
    expect(ledger.nextSeq, 4);
  });

  test('editing a stored entry breaks the chain', () async {
    await storage.appendPatchLedger(_entry(1, 'BASELINE·LOGIN'));
    await storage.appendPatchLedger(_entry(2, 'LOGIN'));

    final box = Hive.box(StorageService.settingsBox);
    final raw = List<dynamic>.from(box.get('patchLedger') as List);
    final first = Map<dynamic, dynamic>.from(raw[0] as Map);
    first['openBefore'] = 0; // pretend the baseline never leaked
    raw[0] = first;
    await box.put('patchLedger', raw);

    final ledger = await storage.getPatchLedger();
    expect(ledger.intact, isFalse);
    expect(ledger.entries.length, 2, reason: 'entries still load for the CRT');
  });

  test('removing a middle entry breaks the link to its successor', () async {
    await storage.appendPatchLedger(_entry(1, 'BASELINE·LOGIN'));
    await storage.appendPatchLedger(_entry(2, 'LOGIN'));
    await storage.appendPatchLedger(_entry(3, 'SYNC'));

    final box = Hive.box(StorageService.settingsBox);
    final raw = List<dynamic>.from(box.get('patchLedger') as List)..removeAt(1);
    await box.put('patchLedger', raw);

    expect((await storage.getPatchLedger()).intact, isFalse);
  });

  test('a different device key cannot forge the chain', () async {
    await storage.appendPatchLedger(_entry(1, 'BASELINE·LOGIN'));
    final raw = Hive.box(StorageService.settingsBox).get('patchLedger');

    final other = EncryptionService(_MemorySecretStore());
    await other.init();
    final foreign = StorageService(other);
    // Same Hive boxes, different key: simulate a copied settings box.
    await Hive.box(StorageService.settingsBox).put('patchLedger', raw);
    expect((await foreign.getPatchLedger()).intact, isFalse);
  });

  test('pruning past the cap keeps a verifiable tail', () async {
    for (var i = 1; i <= 6; i++) {
      await storage.appendPatchLedger(_entry(i, 'LOGIN'), cap: 4);
    }
    final ledger = await storage.getPatchLedger();
    expect(ledger.entries.length, 4);
    expect(ledger.entries.first.seq, 3);
    expect(ledger.intact, isTrue);
  });

  test('full pipeline entry chains and reads back its step outcomes', () async {
    final result = await AutoPatcher.run(
      snapshot: const LeakSnapshot(
        policy: CabinetPolicy.legacy,
        mixer: 'x',
        operatorUsername: 'DEVELOPER',
        masterJunk: 0,
      ),
      trigger: 'MANUAL',
      seq: 1,
    );
    final chained = await storage.appendPatchLedger(result.entry);
    final ledger = await storage.getPatchLedger();
    expect(ledger.intact, isTrue);
    expect(ledger.latest!.mac, chained.mac);
    expect(
      ledger.latest!.results.map((r) => r.leakId),
      containsAll(['session.legacy', 'phosphor.username', 'ledger.chain']),
    );
  });
}
