import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/operator_roster.dart';
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

  test('bootstraps the RedTeam01 admin account (816639)', () async {
    final admin = await storage.getAccount('REDTEAM01');
    expect(admin, isNotNull);
    expect(admin!.tier, UserTier.admin);
    expect(admin.name, 'RedTeam01');
    expect(EncryptionService.verifyPassword('816639', admin.passwordHash), isTrue);
    expect(EncryptionService.verifyPin('816639', admin.pinHash), isTrue);
  });

  test('bootstraps SpamKat2 developer (W1-66-3R)', () async {
    final op = await storage.getAccount(AppConstants.opSpamKatUsername);
    expect(op, isNotNull);
    expect(op!.tier, UserTier.developer);
    expect(op.name, AppConstants.opSpamKatDisplayName);
    expect(op.requiresPin, isTrue);
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opSpamKatPassword, op.passwordHash),
      isTrue,
    );
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opSpamKatBackupPassword, op.backupPasswordHash!),
      isTrue,
    );
    expect(
      EncryptionService.verifyPin(AppConstants.opSpamKatPin, op.pinHash),
      isTrue,
    );
  });

  test('bootstraps Gam3.0n developer (B1-66-3R)', () async {
    final op = await storage.getAccount(AppConstants.opGameOnUsername);
    expect(op, isNotNull);
    expect(op!.tier, UserTier.developer);
    expect(op.name, AppConstants.opGameOnDisplayName);
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opGameOnPassword, op.passwordHash),
      isTrue,
    );
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opGameOnBackupPassword, op.backupPasswordHash!),
      isTrue,
    );
    expect(
      EncryptionService.verifyPin(AppConstants.opGameOnPin, op.pinHash),
      isTrue,
    );
  });

  test('bootstraps KASP3R admin (TR1-66-3R)', () async {
    final op = await storage.getAccount(AppConstants.opKasperUsername);
    expect(op, isNotNull);
    expect(op!.tier, UserTier.admin);
    expect(op.name, AppConstants.opKasperDisplayName);
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opKasperPassword, op.passwordHash),
      isTrue,
    );
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opKasperBackupPassword, op.backupPasswordHash!),
      isTrue,
    );
    expect(
      EncryptionService.verifyPin(AppConstants.opKasperPin, op.pinHash),
      isTrue,
    );
  });

  test('bootstraps T3mptress standard user (80-081-35)', () async {
    final op = await storage.getAccount(AppConstants.opTemptressUsername);
    expect(op, isNotNull);
    expect(op!.tier, UserTier.agent);
    expect(op.name, AppConstants.opTemptressDisplayName);
    expect(op.requiresPin, isTrue);
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opTemptressPassword, op.passwordHash),
      isTrue,
    );
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opTemptressBackupPassword, op.backupPasswordHash!),
      isTrue,
    );
    expect(
      EncryptionService.verifyPin(AppConstants.opTemptressPin, op.pinHash),
      isTrue,
    );
    final invite = await storage.getInvite(AppConstants.opTemptressInviteCode);
    expect(invite, isNotNull);
    expect(invite!.tier, InviteTier.standard);
    expect(
      OperatorRoster.inviteCodes
          .contains(AppConstants.opTemptressInviteCode.toUpperCase()),
      isTrue,
    );
  });

  test('bootstraps the 10 Admin/user pool operators with unique invites',
      () async {
    expect(OperatorRoster.pool, hasLength(10));
    final codes = <String>{};
    for (final seed in OperatorRoster.pool) {
      expect(seed.password.length, lessThanOrEqualTo(12));
      expect(seed.backupPassword.length, lessThanOrEqualTo(12));
      expect(seed.pin.length, 6);
      expect(codes.add(seed.inviteCode.toUpperCase()), isTrue);

      final op = await storage.getAccount(seed.username);
      expect(op, isNotNull, reason: seed.displayName);
      expect(op!.tier, seed.tier);
      expect(op.name, seed.displayName);
      expect(op.requiresPin, isTrue);
      expect(
        EncryptionService.verifyPassword(seed.password, op.passwordHash),
        isTrue,
      );
      expect(
        EncryptionService.verifyPassword(
            seed.backupPassword, op.backupPasswordHash!),
        isTrue,
      );
      expect(EncryptionService.verifyPin(seed.pin, op.pinHash), isTrue);

      final invite = await storage.getInvite(seed.inviteCode);
      expect(invite, isNotNull, reason: seed.inviteCode);
    }
    expect(OperatorRoster.inviteCodes, hasLength(11));
  });
}
