import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/constants/app_constants.dart';
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
    tempDir = await Directory.systemTemp.createTemp('polybius_v1');
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

  test('DEVELOPER account is stricken and cannot log in', () async {
    expect(await storage.getAccount('DEVELOPER'), isNull);
    final ok = await auth.login('DEVELOPER', 'developer');
    expect(ok, isFalse);
    expect(auth.state.error, contains('STRICKEN'));
  });

  test('operator identity cards exclude DEVELOPER', () {
    final names =
        OperatorIdentities.unique.map((o) => o.username.toUpperCase()).toSet();
    expect(names.contains('DEVELOPER'), isFalse);
    expect(names.contains('KASP3R'), isTrue);
    expect(names.contains('REDTEAM01'), isTrue);
    expect(OperatorIdentities.byUsername('KASP3R')?.inviteOrFileCode,
        AppConstants.opKasperInviteCode);
  });

  test('only SpamKat2 / RedTeam01 / Gam3.0n see the full operator roster', () {
    expect(OperatorIdentities.canViewFullRoster('SPAMKAT2'), isTrue);
    expect(OperatorIdentities.canViewFullRoster('REDTEAM01'), isTrue);
    expect(OperatorIdentities.canViewFullRoster('GAM3.0N'), isTrue);
    expect(OperatorIdentities.canViewFullRoster('KASP3R'), isFalse);
    expect(OperatorIdentities.canViewFullRoster('T3MPTRESS'), isFalse);

    final roster = OperatorIdentities.visibleFor('SPAMKAT2');
    expect(roster.length, OperatorIdentities.unique.length);

    final own = OperatorIdentities.visibleFor('KASP3R');
    expect(own.length, 1);
    expect(own.single.username.toUpperCase(), 'KASP3R');

    expect(OperatorIdentities.visibleFor('UNKNOWN_OP'), isEmpty);
  });

  test('Art3mas display name and Gl1tchCat credentials authenticate', () async {
    final art = await auth.login('Art3mas', 'BowArrow7');
    expect(art, isTrue);
    expect(auth.state.user?.username.toUpperCase(), 'ARTEM3S');
    await auth.logout();

    final cat = await auth.login('Gl1tchCat', 'CatGlitch1');
    expect(cat, isTrue);
    expect(auth.state.user?.username.toUpperCase(), 'GL1TCHCAT');
    expect(auth.state.needsPin, isTrue);
    auth.clearPinGate();
    expect(auth.state.needsPin, isFalse);
  });
}
