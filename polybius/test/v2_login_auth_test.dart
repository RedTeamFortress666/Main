import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/auth/v2_login_protocol.dart';

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
  late AuthNotifier auth;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('polybius_v2_auth');
    final encryption = EncryptionService(_MemorySecretStore());
    await encryption.init();
    storage = StorageService(encryption);
    await storage.init(hivePath: tempDir.path);
    auth = AuthNotifier(storage);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('bootstrapped DEVELOPER logs in on V2 and issues a ticket', () async {
    final ok = await auth.login('DEVELOPER', 'developer');
    expect(ok, isTrue);
    expect(auth.state.user?.username, 'DEVELOPER');
    expect(auth.state.handshake.ok, isTrue);
    expect(
      auth.state.handshake.lines.map((l) => l.label).toList(),
      containsAll(['CHALLENGE', 'VERIFY', 'TICKET', 'LEAK SWEEP', 'AUTOPATCH', 'CABINET']),
    );
    expect(auth.state.handshake.lines[1].status, 'PBKDF2');
    expect(await storage.hasV2Ticket(), isTrue);
    expect(await storage.getSessionUser(), 'DEVELOPER');
    expect(V2LoginProtocol.version, 2);
  });

  test('wrong password is ACCESS DENIED and does not issue a ticket', () async {
    final ok = await auth.login('DEVELOPER', 'wrong');
    expect(ok, isFalse);
    expect(auth.state.error, 'ACCESS DENIED');
    expect(auth.state.handshake.lines.last.status, 'DENIED');
    expect(await storage.hasV2Ticket(), isFalse);
  });
}
