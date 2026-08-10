import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/cipher/pool_view_gate.dart';

class _MemStore implements PolybiusSecretStore {
  final _data = <String, String>{};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('polybius_pool_gate');
    final enc = EncryptionService(_MemStore());
    await enc.init();
    final storage = StorageService(enc);
    await storage.init(hivePath: tempDir.path);

    container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('pool view stays locked until game file + PIN succeed', () async {
    final auth = container.read(authProvider.notifier);
    final ok = await auth.login(
      AppConstants.opKasperUsername,
      AppConstants.opKasperPassword,
    );
    expect(ok, isTrue);

    final gate = container.read(poolViewGateProvider.notifier);
    expect(container.read(poolViewGateProvider).unlocked, isFalse);

    expect(
      await gate.unlock(gameFileNumber: 'WRONG-CODE', pin: '791639'),
      isFalse,
    );
    expect(container.read(poolViewGateProvider).unlocked, isFalse);

    expect(
      await gate.unlock(
        gameFileNumber: AppConstants.opKasperInviteCode,
        pin: '000000',
      ),
      isFalse,
    );

    expect(
      await gate.unlock(
        gameFileNumber: AppConstants.opKasperInviteCode,
        pin: AppConstants.opKasperPin,
      ),
      isTrue,
    );
    expect(container.read(poolViewGateProvider).unlocked, isTrue);

    gate.lock();
    expect(container.read(poolViewGateProvider).unlocked, isFalse);
  });

  test('bound game file number also unlocks the vault', () async {
    final storage = container.read(storageServiceProvider);
    await storage.setGameFileNumber('PB-TESTFILE');

    final auth = container.read(authProvider.notifier);
    final ok = await auth.login(
      AppConstants.opTemptressUsername,
      AppConstants.opTemptressPassword,
    );
    expect(ok, isTrue);

    final gate = container.read(poolViewGateProvider.notifier);
    expect(
      await gate.unlock(
        gameFileNumber: 'PB-TESTFILE',
        pin: AppConstants.opTemptressPin,
      ),
      isTrue,
    );
  });
}
