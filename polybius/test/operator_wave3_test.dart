import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/auth/login_policy.dart';
import 'package:polybius/core/constants/operator_identities.dart';
import 'package:polybius/core/constants/operator_roster.dart';
import 'package:polybius/core/constants/operator_wave2.dart';
import 'package:polybius/core/constants/operator_wave3.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
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
    tempDir = await Directory.systemTemp.createTemp('polybius_wave3');
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

  test('wave-3 has unique usernames, invites, and 6-digit PINs', () {
    final priorUsernames = {
      ...OperatorRoster.pool.map((o) => o.username.toUpperCase()),
      ...OperatorWave2.all.map((o) => o.username.toUpperCase()),
    };
    final priorInvites = {
      ...OperatorRoster.pool.map((o) => o.inviteCode.toUpperCase()),
      ...OperatorWave2.all.map((o) => o.inviteCode.toUpperCase()),
    };

    final usernames = <String>{};
    final invites = <String>{};
    final pins = <String>{};
    for (final seed in OperatorWave3.all) {
      expect(seed.username, equals(seed.username.toUpperCase()));
      expect(seed.pin, matches(RegExp(r'^\d{6}$')));
      expect(seed.password.length, lessThanOrEqualTo(12));
      expect(seed.backupPassword.length, lessThanOrEqualTo(12));
      expect(priorUsernames.contains(seed.username.toUpperCase()), isFalse,
          reason: seed.username);
      expect(priorInvites.contains(seed.inviteCode.toUpperCase()), isFalse,
          reason: seed.inviteCode);
      expect(usernames.add(seed.username.toUpperCase()), isTrue,
          reason: seed.username);
      expect(invites.add(seed.inviteCode.toUpperCase()), isTrue,
          reason: seed.inviteCode);
      expect(pins.add(seed.pin), isTrue, reason: seed.pin);
    }
    expect(OperatorWave3.all, hasLength(28));
  });

  test('wave-3 identities are on the unique roster', () {
    for (final seed in OperatorWave3.all) {
      final id = OperatorIdentities.byUsername(seed.username);
      expect(id, isNotNull, reason: seed.username);
      expect(id!.inviteOrFileCode, seed.inviteCode);
      expect(id.password, seed.password);
      expect(id.backupPassword, seed.backupPassword);
      expect(id.pin, seed.pin);
      expect(id.tier, seed.tier);
    }
    expect(OperatorIdentities.byDisplayName('V0ltStag')?.username, 'V0LTSTAG');
    expect(OperatorIdentities.byDisplayName('Aur0raFox')?.username, 'AUR0RAFOX');
  });

  test('wave-3 admin logs in on PORTAL; user is gated to V.1 USER', () async {
    final admin = await auth.login('V0ltStag', 'VoltStag91');
    expect(admin, isTrue);
    expect(auth.state.user?.username.toUpperCase(), 'V0LTSTAG');
    await auth.logout();

    final backup = await auth.login('B1TF0RGE', 'ForgeBit2');
    expect(backup, isTrue);
    expect(auth.state.user?.username.toUpperCase(), 'B1TF0RGE');
    await auth.logout();

    final user = await auth.login('Aur0raFox', 'AuroraFx21');
    expect(user, isFalse);
    expect(auth.state.error, contains('V.1 USER'));
  });

  test('wave-3 counts land in login policy sets', () {
    expect(LoginPolicy.devAdminUsernames, containsAll([
      'V0LTSTAG',
      'CR1MS0NRX',
      'OBS1DIAN',
      'STORMK3L',
      'APEXW0LF',
      'B1TF0RGE',
      'GHOSTASM',
      'ZER0KERN',
    ]));
    expect(LoginPolicy.userAgentUsernames, contains('AUR0RAFOX'));
    expect(LoginPolicy.userAgentUsernames, contains('TIDALNYX'));
    expect(LoginPolicy.devAdminUsernames, hasLength(24));
    expect(LoginPolicy.userAgentUsernames, hasLength(50));
  });
}
