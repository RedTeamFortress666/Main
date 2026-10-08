import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/core/storage/storage_service.dart';

class _MemorySecretStore implements PolybiusSecretStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

void main() {
  late Directory tempDir;
  late AuthNotifier auth;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('polybius_auth_test');
    final encryption = EncryptionService(_MemorySecretStore());
    await encryption.init();
    final storage = StorageService(encryption);
    await storage.init(hivePath: tempDir.path);
    auth = AuthNotifier(storage);
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('first account needs no invite; later accounts do', () async {
    expect(
      await auth.register('OPERATOR', 'correcthorse1', '123456'),
      isNull,
    );
    expect(
      await auth.register('AGENTX', 'correcthorse1', '654321'),
      'INVITE REQUIRED',
    );

    final code = await auth.mintInvite(InviteTier.agent, 'OPERATOR');
    expect(
      await auth.register(
        'AGENTX',
        'correcthorse1',
        '654321',
        inviteCode: code,
      ),
      isNull,
    );
    expect(
      await auth.register(
        'DUPED',
        'correcthorse1',
        '111111',
        inviteCode: code,
      ),
      'INVALID INVITE',
    );
  });

  test('rejects short passwords and non-digit pins', () async {
    expect(
      await auth.register('X', 'short', '123456'),
      'PASSWORD TOO SHORT',
    );
    expect(
      await auth.register('X', 'correcthorse1', '12ab56'),
      'CHOOSE A 6-DIGIT PIN',
    );
  });
}
