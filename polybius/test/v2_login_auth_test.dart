import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/auth/v2_login_protocol.dart';
import 'package:polybius/features/redlight/auto_patcher.dart';
import 'package:polybius/features/redlight/cabinet_policy.dart';
import 'package:polybius/features/redlight/leak_detector.dart';

class _MemorySecretStore implements PolybiusSecretStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }
}

class _StorageHooks extends PatchHooks {
  const _StorageHooks(this.storage, this.username);

  final StorageService storage;
  final String? username;

  @override
  Future<bool> ensureTicket() async {
    if (await storage.hasV2Ticket()) return true;
    if (username == null) return false;
    await storage.setV2Session(username!);
    return storage.hasV2Ticket();
  }

  @override
  Future<String> ensureMixer() => storage.ensureCherryMixer();

  @override
  Future<bool> ensureRedlightVault() async {
    if (username == null) return false;
    await storage.ensureRedlightVault(username!);
    return await storage.getRedlightVault(username!) != null;
  }
}

void main() {
  late Directory tempDir;
  late StorageService storage;
  late AuthNotifier auth;
  late EncryptionService encryption;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('polybius_v2_auth');
    encryption = EncryptionService(_MemorySecretStore());
    await encryption.init();
    storage = StorageService(encryption);
    await storage.init(hivePath: tempDir.path);
    auth = AuthNotifier(
      storage,
      weaver: (trigger, {username}) async {
        // Test weaver: the real one lives in autoPatcherProvider. Here we run
        // the pipeline straight against storage so the handshake gets real
        // counts and the ledger really chains.
        final ledger = await storage.getPatchLedger();
        final result = await AutoPatcher.run(
          snapshot: LeakSnapshot(
            policy: ledger.isEmpty ? CabinetPolicy.legacy : CabinetPolicy.woven,
            mixer: await storage.getCherryMixer() ?? '',
            operatorUsername: username,
            sessionIsV2: await storage.hasV2Ticket(),
            redlightSealed: username != null &&
                await storage.getRedlightVault(username) != null,
            masterJunk: 0,
            ledgerIntact: ledger.intact,
            ledgerEntries: ledger.entries.length,
          ),
          trigger: trigger,
          seq: ledger.nextSeq,
          hooks: _StorageHooks(storage, username),
        );
        return storage.appendPatchLedger(result.entry);
      },
    );
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

    // Steps 04/05 carry the pipeline's real counts, chained into the ledger.
    final byLabel = {
      for (final l in auth.state.handshake.lines) l.label: l.status,
    };
    expect(byLabel['LEAK SWEEP'], '8 OPEN',
        reason: 'the compiled legacy policy does not trust the step-03 '
            'ticket until v2Session is woven, so all eight flags read open');
    expect(byLabel['AUTOPATCH'], '8 WOVEN #1');
    final ledger = await storage.getPatchLedger();
    expect(ledger.intact, isTrue);
    expect(ledger.entries.single.trigger, 'LOGIN');
    expect(ledger.entries.single.appliedCount, 8);
    expect(ledger.entries.single.heldCount, 2);
    expect(ledger.entries.single.residualCount, 1);

    // The weave minted the red-light vault for the live operator, sealed
    // under the device key and bound to DEVELOPER only.
    expect(await storage.hasRedlightVault(), isTrue);
    expect(await storage.getRedlightVault('DEVELOPER'), isNotNull);
    expect(await storage.getRedlightVault('SOMEONE_ELSE'), isNull);
  });

  test('second login holds the weave and chains entry #2', () async {
    expect(await auth.login('DEVELOPER', 'developer'), isTrue);
    await auth.logout();
    expect(await auth.login('DEVELOPER', 'developer'), isTrue);
    final byLabel = {
      for (final l in auth.state.handshake.lines) l.label: l.status,
    };
    expect(byLabel['LEAK SWEEP'], '0 OPEN');
    expect(byLabel['AUTOPATCH'], '0 WOVEN #2');
    final ledger = await storage.getPatchLedger();
    expect(ledger.entries.length, 2);
    expect(ledger.entries.last.prevMac, ledger.entries.first.mac);
    expect(ledger.intact, isTrue);
  });

  test('an expired ticket does not restore a session', () async {
    expect(await auth.login('DEVELOPER', 'developer'), isTrue);
    final box = Hive.box(StorageService.sessionBox);
    final wire = box.get('ticket') as String;
    final ticket = V2SessionTicket.parse(wire)!;
    final stale = V2SessionTicket.issue(
      username: ticket.username,
      mac: encryption.mac,
      issuedMs: DateTime.now()
          .toUtc()
          .subtract(V2LoginProtocol.ticketMaxAge + const Duration(hours: 1))
          .millisecondsSinceEpoch,
    );
    await box.put('ticket', stale.wire);
    expect(stale.verify(encryption.mac), isTrue, reason: 'MAC is still good');
    expect(await storage.hasV2Ticket(), isFalse);
    expect(await storage.getSessionUser(), isNull);
    expect(box.get('user'), isNull, reason: 'bare username must not survive');
    final audit = await storage.getAuditLogs();
    expect(audit.any((e) => e.action == 'TICKET_EXPIRED'), isTrue);
  });

  test('deferred login holds the account until commitLogin', () async {
    final ok = await auth.login('DEVELOPER', 'developer', deferCommit: true);
    expect(ok, isTrue);
    expect(auth.state.user, isNull, reason: 'router must not redirect yet');
    expect(auth.state.isLoading, isTrue);
    expect(auth.state.handshake.finished, isTrue);
    expect(auth.state.handshake.lines.length, 6);
    auth.commitLogin();
    expect(auth.state.user?.username, 'DEVELOPER');
    expect(auth.state.isLoading, isFalse);
    expect(auth.state.handshake.lines.length, 6, reason: 'console survives');
    auth.commitLogin();
    expect(auth.state.user?.username, 'DEVELOPER', reason: 'idempotent');
  });

  test('wrong password is ACCESS DENIED and does not issue a ticket', () async {
    final ok = await auth.login('DEVELOPER', 'wrong');
    expect(ok, isFalse);
    expect(auth.state.error, 'ACCESS DENIED');
    expect(auth.state.handshake.lines.last.status, 'DENIED');
    expect(await storage.hasV2Ticket(), isFalse);
  });
}
