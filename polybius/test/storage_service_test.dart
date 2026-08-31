import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/core/storage/storage_service.dart';

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
  late Directory tempDir;
  late StorageService storage;
  late EncryptionService encryption;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('polybius_storage_test');
    encryption = EncryptionService(_MemorySecretStore());
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

  test('saves and loads account with boolean fields intact', () async {
    final account = UserAccount(
      username: 'TESTER',
      passwordHash: EncryptionService.hashPassword('secret'),
      pinHash: EncryptionService.hashPin('123456'),
      tier: UserTier.agent,
      createdAt: DateTime.utc(2026, 1, 2),
      requiresPin: true,
    );

    await storage.saveAccount(account);
    final loaded = await storage.getAccount('TESTER');

    expect(loaded, isNotNull);
    expect(loaded!.requiresPin, isTrue);
    expect(loaded.tier, UserTier.agent);
    expect(loaded.createdAt, account.createdAt);
  });

  test('migrates legacy pipe-encoded account payloads', () async {
    final legacyJson = {
      'username': 'LEGACY',
      'passwordHash': 'abc',
      'pinHash': 'def',
      'tier': UserTier.guest.name,
      'requiresPin': false,
    };
    final legacyPayload =
        legacyJson.entries.map((e) => '${e.key}=${e.value}').join('|');
    final encrypted = encryption.encrypt(legacyPayload);

    await Hive.box(StorageService.accountsBox).put('LEGACY', encrypted);

    final loaded = await storage.getAccount('LEGACY');
    expect(loaded, isNotNull);
    expect(loaded!.username, 'LEGACY');
    expect(loaded.requiresPin, isFalse);

    final reloadedRaw =
        Hive.box(StorageService.accountsBox).get('LEGACY') as String;
    final decrypted = encryption.decrypt(reloadedRaw);
    expect(jsonDecode(decrypted), isA<Map>());
  });

  test('Darth Cherry defaults off and persists', () async {
    expect(await storage.getDarthCherry(), isFalse);
    await storage.setDarthCherry(true);
    expect(await storage.getDarthCherry(), isTrue);
    await storage.setDarthCherry(false);
    expect(await storage.getDarthCherry(), isFalse);
  });

  test('V2 session ticket migrates a bare username and rejects a swap', () async {
    await Hive.box(StorageService.sessionBox).put('user', 'DEVELOPER');
    final restored = await storage.getSessionUser();
    expect(restored, 'DEVELOPER');
    expect(await storage.hasV2Ticket(), isTrue);

    final wire = Hive.box(StorageService.sessionBox).get('ticket') as String;
    final swapped = wire.replaceFirst('DEVELOPER', 'INTRUDER');
    await Hive.box(StorageService.sessionBox).put('ticket', swapped);
    await Hive.box(StorageService.sessionBox).delete('user');
    expect(await storage.getSessionUser(), isNull);
    expect(await storage.hasV2Ticket(), isFalse);
  });

  test('cherry mixer is not the operator name and survives reload', () async {
    final a = await storage.ensureCherryMixer();
    expect(a, isNot(equals('DEVELOPER')));
    expect(a.length, greaterThan(8));
    expect(await storage.getCherryMixer(), a);
    final b = await storage.ensureCherryMixer();
    expect(b, a);
  });
}
