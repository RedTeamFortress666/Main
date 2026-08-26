import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/auth/login_policy.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/core/constants/operator_identities.dart';
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
    tempDir = await Directory.systemTemp.createTemp('polybius_pixelwiz');
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

  test('PixelWiz / PIXELWIZ resolve to PIXELW1Z identity', () {
    expect(OperatorIdentities.loginAliases['PIXELWIZ'], 'PIXELW1Z');
    expect(OperatorIdentities.byUsername('PIXELWIZ')?.username, 'PIXELW1Z');
    expect(OperatorIdentities.byUsername('PixelWiz')?.username, 'PIXELW1Z');
    expect(OperatorIdentities.byDisplayName('PixelWiz')?.username, 'PIXELW1Z');
    expect(OperatorIdentities.byDisplayName('PixelW1z')?.username, 'PIXELW1Z');

    final id = OperatorIdentities.byUsername('PIXELW1Z')!;
    expect(id.inviteOrFileCode, 'PW9-66-3R');
    expect(id.password, 'PixelZap12');
    expect(id.backupPassword, 'WizPixel5');
    expect(id.pin, '367879');
    expect(id.tier, UserTier.agent);
    expect(LoginPolicy.userAgentUsernames, contains('PIXELW1Z'));
  });

  test('PixelWiz logs in on V.1 USER with password, backup, and PIN', () async {
    final deniedOnPortal = await auth.login('PixelWiz', 'PixelZap12');
    expect(deniedOnPortal, isFalse);
    expect(auth.state.error, contains('V.1 USER'));

    final ok = await auth.login(
      'PixelWiz',
      'PixelZap12',
      flavor: PolybiusFlavor.user,
    );
    expect(ok, isTrue);
    expect(auth.state.user?.username.toUpperCase(), 'PIXELW1Z');
    expect(auth.state.user?.tier, UserTier.agent);
    expect(await auth.verifyPin('367879'), isTrue);
    await auth.logout();

    final backup = await auth.login(
      'PIXELWIZ',
      'WizPixel5',
      flavor: PolybiusFlavor.user,
    );
    expect(backup, isTrue);
    expect(auth.state.user?.username.toUpperCase(), 'PIXELW1Z');
  });

  test('VALKYRIE wipe relinks PixelWiz and PW9-66-3R for V.1 USER', () async {
    expect(await storage.getAccount('PIXELW1Z'), isNotNull);
    expect(await storage.getInvite('PW9-66-3R'), isNotNull);

    await storage.wipeNetworkState();

    expect(await storage.getAccount('SPAMKAT2'), isNotNull,
        reason: 'developers survive VALKYRIE');
    final op = await storage.getAccount('PIXELW1Z');
    expect(op, isNotNull, reason: 'agent roster relinked after VALKYRIE');
    expect(op!.tier, UserTier.agent);
    expect(op.requiresPin, isTrue);
    expect(
      EncryptionService.verifyPassword('PixelZap12', op.passwordHash),
      isTrue,
    );
    expect(
      EncryptionService.verifyPassword('WizPixel5', op.backupPasswordHash!),
      isTrue,
    );
    expect(EncryptionService.verifyPin('367879', op.pinHash), isTrue);

    final invite = await storage.getInvite('PW9-66-3R');
    expect(invite, isNotNull);
    expect(invite!.tier, InviteTier.standard);

    final ok = await auth.login(
      'PixelWiz',
      'PixelZap12',
      flavor: PolybiusFlavor.user,
    );
    expect(ok, isTrue);
    expect(await auth.verifyPin('367879'), isTrue);
  });
}
