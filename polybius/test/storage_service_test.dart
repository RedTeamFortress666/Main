import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/operator_roster.dart';
import 'package:polybius/core/constants/operator_wave2.dart';
import 'package:polybius/core/constants/operator_wave3.dart';
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

  test('bootstraps CrownOfCorns admin (C0-9N-3E)', () async {
    final op = await storage.getAccount(AppConstants.opCrownOfCornsUsername);
    expect(op, isNotNull);
    expect(op!.tier, UserTier.admin);
    expect(op.name, AppConstants.opCrownOfCornsDisplayName);
    expect(op.requiresPin, isTrue);
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opCrownOfCornsPassword, op.passwordHash),
      isTrue,
    );
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opCrownOfCornsBackupPassword, op.backupPasswordHash!),
      isTrue,
    );
    expect(
      EncryptionService.verifyPin(AppConstants.opCrownOfCornsPin, op.pinHash),
      isTrue,
    );
    final invite =
        await storage.getInvite(AppConstants.opCrownOfCornsInviteCode);
    expect(invite, isNotNull);
    expect(invite!.tier, InviteTier.admin);
    expect(
      OperatorRoster.inviteCodes
          .contains(AppConstants.opCrownOfCornsInviteCode.toUpperCase()),
      isTrue,
    );
  });

  test('bootstraps MizzPickl3s standard user (SP-1N-33)', () async {
    final op = await storage.getAccount(AppConstants.opMizzPicklesUsername);
    expect(op, isNotNull);
    expect(op!.tier, UserTier.agent);
    expect(op.name, AppConstants.opMizzPicklesDisplayName);
    expect(op.requiresPin, isTrue);
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opMizzPicklesPassword, op.passwordHash),
      isTrue,
    );
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opMizzPicklesBackupPassword, op.backupPasswordHash!),
      isTrue,
    );
    expect(
      EncryptionService.verifyPin(AppConstants.opMizzPicklesPin, op.pinHash),
      isTrue,
    );
    final invite =
        await storage.getInvite(AppConstants.opMizzPicklesInviteCode);
    expect(invite, isNotNull);
    expect(invite!.tier, InviteTier.standard);
    expect(
      OperatorRoster.inviteCodes
          .contains(AppConstants.opMizzPicklesInviteCode.toUpperCase()),
      isTrue,
    );
  });

  test('bootstraps P!k.ZuP admin (D4-N6-3R)', () async {
    final op = await storage.getAccount(AppConstants.opPikZupUsername);
    expect(op, isNotNull);
    expect(op!.tier, UserTier.admin);
    expect(op.name, AppConstants.opPikZupDisplayName);
    expect(op.requiresPin, isTrue);
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opPikZupPassword, op.passwordHash),
      isTrue,
    );
    expect(
      EncryptionService.verifyPassword(
          AppConstants.opPikZupBackupPassword, op.backupPasswordHash!),
      isTrue,
    );
    expect(
      EncryptionService.verifyPin(AppConstants.opPikZupPin, op.pinHash),
      isTrue,
    );
    final invite = await storage.getInvite(AppConstants.opPikZupInviteCode);
    expect(invite, isNotNull);
    expect(invite!.tier, InviteTier.admin);
    expect(
      OperatorRoster.inviteCodes
          .contains(AppConstants.opPikZupInviteCode.toUpperCase()),
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
    // Pool (10) + T3mptress + CrownOfCorns + MizzPickl3s + P!k.ZuP + wave2 (28) + wave3 (28)
    expect(OperatorRoster.inviteCodes, hasLength(70));
  });

  test('bootstraps wave-2 admins, developers, and users', () async {
    expect(OperatorWave2.admins, hasLength(5));
    expect(OperatorWave2.developers, hasLength(3));
    expect(OperatorWave2.users, hasLength(20));
    for (final seed in OperatorWave2.all) {
      final op = await storage.getAccount(seed.username);
      expect(op, isNotNull, reason: seed.displayName);
      expect(op!.tier, seed.tier);
      expect(
        EncryptionService.verifyPassword(seed.password, op.passwordHash),
        isTrue,
      );
      expect(EncryptionService.verifyPin(seed.pin, op.pinHash), isTrue);
      expect(await storage.getInvite(seed.inviteCode), isNotNull);
    }
  });

  test('bootstraps wave-3 admins, developers, and users', () async {
    expect(OperatorWave3.admins, hasLength(5));
    expect(OperatorWave3.developers, hasLength(3));
    expect(OperatorWave3.users, hasLength(20));
    for (final seed in OperatorWave3.all) {
      final op = await storage.getAccount(seed.username);
      expect(op, isNotNull, reason: seed.displayName);
      expect(op!.tier, seed.tier);
      expect(
        EncryptionService.verifyPassword(seed.password, op.passwordHash),
        isTrue,
      );
      expect(EncryptionService.verifyPin(seed.pin, op.pinHash), isTrue);
      expect(await storage.getInvite(seed.inviteCode), isNotNull);
    }
  });
}
