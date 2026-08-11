import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/operator_identities.dart';
import 'package:polybius/core/constants/operator_roster.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/core/storage/storage_service.dart';

class _MemStore implements PolybiusSecretStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

void main() {
  late Directory tempDir;
  late StorageService storage;
  late AuthNotifier auth;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('polybius_logins');
    final enc = EncryptionService(_MemStore());
    await enc.init();
    storage = StorageService(enc);
    await storage.init(hivePath: tempDir.path);
    auth = AuthNotifier(storage);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('every bootstrapped operator can log in with primary password', () async {
    for (final id in OperatorIdentities.unique) {
      final ok = await auth.login(id.displayName, id.password);
      expect(ok, isTrue, reason: 'primary login for ${id.username}');
      expect(auth.state.user?.username, id.username.toUpperCase());
      await auth.logout();
    }
  });

  test('every bootstrapped operator can log in with backup password', () async {
    for (final id in OperatorIdentities.unique) {
      final ok = await auth.login(id.username, id.backupPassword);
      expect(ok, isTrue, reason: 'backup login for ${id.username}');
      await auth.logout();
    }
  });

  test('every bootstrapped operator PIN verifies after login', () async {
    for (final id in OperatorIdentities.unique) {
      final ok = await auth.login(id.username, id.password);
      expect(ok, isTrue, reason: id.username);
      final account = await storage.getAccount(id.username);
      if (account?.requiresPin != true) {
        await auth.logout();
        continue;
      }
      expect(auth.state.needsPin, isTrue);
      final pinOk = await auth.verifyPin(id.pin);
      expect(pinOk, isTrue, reason: 'PIN for ${id.username}');
      expect(auth.state.isAuthenticated, isTrue);
      await auth.logout();
    }
  });

  test('special-character usernames authenticate (GAM3.0N, P!K.ZUP, CUP1D!)',
      () async {
    const specials = ['GAM3.0N', 'P!K.ZUP', 'CUP1D!'];
    for (final name in specials) {
      final account = await storage.getAccount(name);
      expect(account, isNotNull, reason: '$name bootstrapped');
      final id = OperatorIdentities.byUsername(name)!;
      expect(await auth.login(id.displayName, id.password), isTrue);
      await auth.logout();
      expect(await auth.login(name, id.backupPassword), isTrue);
      await auth.logout();
    }
  });

  test('DEVELOPER / developer is stricken on V1 Stable', () async {
    expect(await storage.getAccount('DEVELOPER'), isNull);
    expect(await auth.login('DEVELOPER', 'developer'), isFalse);
    expect(await auth.login('developer', 'developer'), isFalse);
    expect(auth.state.error, contains('STRICKEN'));
  });

  test('operator roster pool matches identity cards', () {
    for (final seed in OperatorRoster.pool) {
      final card = OperatorIdentities.byUsername(seed.username);
      expect(card, isNotNull, reason: seed.username);
      expect(card!.password, seed.password);
      expect(card.inviteOrFileCode, seed.inviteCode);
    }
  });

  test('admin/dev accounts accept dev codes at portal tier check', () async {
    final devCodes = {
      AppConstants.opSpamKatUsername: AppConstants.opSpamKatDevCode,
      AppConstants.opGameOnUsername: AppConstants.opGameOnDevCode,
      AppConstants.adminUsername: AppConstants.devGameFileNumber,
    };
    for (final entry in devCodes.entries) {
      final account = await storage.getAccount(entry.key);
      expect(account, isNotNull);
      expect(
        account!.tier == UserTier.admin || account.tier == UserTier.developer,
        isTrue,
        reason: entry.key,
      );
    }
  });
}
