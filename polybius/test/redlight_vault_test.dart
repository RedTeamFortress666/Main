import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/auth/v2_login_protocol.dart';
import 'package:polybius/features/redlight/glyph_derangement.dart';
import 'package:polybius/features/redlight/redlight_sealed_panel.dart';
import 'package:polybius/features/redlight/redlight_vault.dart';

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
  group('RedlightProfile', () {
    test('mint jitters the lamp inside the deep-red band and never reuses '
        'the username as mixer', () {
      final a = RedlightProfile.mint(owner: 'developer', random: Random(1));
      final b = RedlightProfile.mint(owner: 'developer', random: Random(2));
      expect(a.owner, 'DEVELOPER');
      expect(a.mixer, isNot('DEVELOPER'));
      expect(a.mixer.length, greaterThanOrEqualTo(16));
      expect(a.mixer, isNot(b.mixer));
      expect(a.lampGain, inInclusiveRange(1.25, 1.45));
      expect(a.lampLift, inInclusiveRange(20, 36));
      expect(a.crush, inInclusiveRange(0.02, 0.05));
      expect(a.lampFilter, isA<ColorFilter>());
    });

    test('JSON round trip keeps every field', () {
      final p = RedlightProfile.mint(owner: 'DEVELOPER', random: Random(7));
      final back = RedlightProfile.tryParse(jsonEncode(p.toJson()))!;
      expect(back.canonical, p.canonical);
      expect(back.lampFilter, p.lampFilter);
    });

    test('tryParse refuses short mixers and junk', () {
      expect(RedlightProfile.tryParse('not json'), isNull);
      expect(RedlightProfile.tryParse('[1,2]'), isNull);
      expect(
        RedlightProfile.tryParse(jsonEncode({
          'v': 1,
          'owner': 'DEVELOPER',
          'mixer': 'DEVELOPER',
          'gain': 1.3,
          'lift': 24,
          'crush': 0.03,
        })),
        isNull,
        reason: 'a username-length mixer is the leak the vault exists to fix',
      );
    });

    test('derangeSecret is an HMAC — not the mixer, not the owner, and '
        'different under another device key', () async {
      final p = RedlightProfile.mint(owner: 'DEVELOPER', random: Random(3));
      final devA = EncryptionService(_MemorySecretStore());
      final devB = EncryptionService(_MemorySecretStore());
      await devA.init();
      await devB.init();

      final secretA = p.derangeSecret(devA.mac);
      final secretB = p.derangeSecret(devB.mac);
      expect(secretA, isNot(p.mixer));
      expect(secretA, isNot(contains('DEVELOPER')));
      expect(secretA, isNot(secretB), reason: 'same vault, other device');
      expect(p.derangeSecret(devA.mac), secretA, reason: 'deterministic');

      // Different secrets give different key maps, so a copied vault on
      // another device types different glyphs.
      final mapA = GlyphDerangement(poolId: 'pool', slot: 4, pin: secretA);
      final mapB = GlyphDerangement(poolId: 'pool', slot: 4, pin: secretB);
      final lettersA =
          GlyphDerangement.letters.split('').map(mapA.mapGlyph).join();
      final lettersB =
          GlyphDerangement.letters.split('').map(mapB.mapGlyph).join();
      expect(lettersA, isNot(lettersB));
    });
  });

  group('RedlightAccess', () {
    test('sealed states never grant and carry a CRT reason', () {
      for (final seal in RedlightSeal.values) {
        if (seal == RedlightSeal.open) continue;
        final access = RedlightAccess.sealed(seal);
        expect(access.granted, isFalse, reason: seal.name);
        expect(access.reason, isNotEmpty);
        expect(access.derangeSecret, isEmpty);
      }
    });

    test('open grants with a profile and a secret', () {
      final p = RedlightProfile.mint(owner: 'DEVELOPER', random: Random(9));
      final access = RedlightAccess.open(profile: p, derangeSecret: 's3cret');
      expect(access.granted, isTrue);
      expect(access.reason, 'VAULT OPEN');
    });
  });

  group('storage vault', () {
    late Directory tempDir;
    late StorageService storage;
    late EncryptionService encryption;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('polybius_redlight');
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

    test('the stored blob is one AES v2 payload with no plaintext', () async {
      final profile = await storage.ensureRedlightVault('DEVELOPER');
      final raw = Hive.box(StorageService.settingsBox).get('redlightVault');
      expect(raw, isA<String>());
      final blob = raw as String;
      expect(blob, startsWith('v2:'));
      expect(blob, isNot(contains(profile.mixer)));
      expect(blob, isNot(contains('DEVELOPER')));
      expect(blob, isNot(contains('gain')));
      expect(await storage.hasRedlightVault(), isTrue);
    });

    test('vault opens only for its owner on this device', () async {
      final minted = await storage.ensureRedlightVault('developer');
      final opened = await storage.getRedlightVault('DEVELOPER');
      expect(opened, isNotNull);
      expect(opened!.canonical, minted.canonical);
      expect(await storage.getRedlightVault('INTRUDER'), isNull);
    });

    test('ensure is idempotent for the owner and re-mints for a new owner',
        () async {
      final first = await storage.ensureRedlightVault('DEVELOPER');
      final again = await storage.ensureRedlightVault('DEVELOPER');
      expect(again.canonical, first.canonical);

      final other = await storage.ensureRedlightVault('OPERATOR2');
      expect(other.owner, 'OPERATOR2');
      expect(await storage.getRedlightVault('DEVELOPER'), isNull,
          reason: 'one vault per device; it follows the live operator');
    });

    test('ensure reuses an existing strong cherry mixer', () async {
      final mixer = await storage.ensureCherryMixer();
      expect(mixer.length, greaterThanOrEqualTo(16));
      final profile = await storage.ensureRedlightVault('DEVELOPER');
      expect(profile.mixer, mixer);
    });

    test('a copied blob will not open under another device key', () async {
      await storage.ensureRedlightVault('DEVELOPER');
      final other = EncryptionService(_MemorySecretStore());
      await other.init();
      final foreign = StorageService(other);
      // Same Hive box contents, different working key.
      expect(await foreign.getRedlightVault('DEVELOPER'), isNull);
      expect(await foreign.hasRedlightVault(), isTrue,
          reason: 'the blob is visible; its contents are not');
    });

    test('a tampered blob is refused rather than half-read', () async {
      await storage.ensureRedlightVault('DEVELOPER');
      final box = Hive.box(StorageService.settingsBox);
      final blob = box.get('redlightVault') as String;
      final parts = blob.split(':');
      final cipher = base64Decode(parts[2]);
      cipher[cipher.length - 1] ^= 0x01;
      await box.put(
        'redlightVault',
        '${parts[0]}:${parts[1]}:${base64Encode(cipher)}',
      );
      expect(await storage.getRedlightVault('DEVELOPER'), isNull);
    });

    test('clearRedlightVault removes the blob', () async {
      await storage.ensureRedlightVault('DEVELOPER');
      await storage.clearRedlightVault();
      expect(await storage.hasRedlightVault(), isFalse);
      expect(await storage.getRedlightVault('DEVELOPER'), isNull);
    });

    test('currentTicket returns only a verified, unexpired ticket', () async {
      expect(await storage.currentTicket(), isNull);
      await storage.setV2Session('developer');
      final live = await storage.currentTicket();
      expect(live, isNotNull);
      expect(live!.username, 'DEVELOPER');

      final box = Hive.box(StorageService.sessionBox);
      final stale = V2SessionTicket.issue(
        username: 'DEVELOPER',
        mac: encryption.mac,
        issuedMs: DateTime.now()
            .toUtc()
            .subtract(V2LoginProtocol.ticketMaxAge + const Duration(hours: 1))
            .millisecondsSinceEpoch,
      );
      await box.put('ticket', stale.wire);
      expect(await storage.currentTicket(), isNull, reason: 'expired');

      final other = EncryptionService(_MemorySecretStore());
      await other.init();
      final forged = V2SessionTicket.issue(username: 'DEVELOPER', mac: other.mac);
      await box.put('ticket', forged.wire);
      expect(await storage.currentTicket(), isNull, reason: 'foreign MAC');
    });

    test('deviceMac matches the encryption service HMAC', () {
      final data = utf8.encode('REDLIGHT-DERANGE::DEVELOPER::x');
      expect(storage.deviceMac(data), encryption.mac(data));
    });
  });

  testWidgets('RedlightSealedPanel names the seal reason', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RedlightSealedPanel(
            access: RedlightAccess.sealed(RedlightSeal.noTicket),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey<String>('redlight-sealed')), findsOneWidget);
    expect(find.text('REDLIGHT SEALED'), findsOneWidget);
    expect(find.text('NO DEVICE TICKET — V2 LOGIN REQUIRED'), findsOneWidget);
  });
}
