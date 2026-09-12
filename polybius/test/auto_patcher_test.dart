import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/redlight/auto_patcher.dart';
import 'package:polybius/features/redlight/cabinet_policy.dart';
import 'package:polybius/features/redlight/leak_detector.dart';
import 'package:polybius/features/redlight/patch_ledger.dart';

class _RecordingHooks extends PatchHooks {
  _RecordingHooks({this.ticket = true, this.vault = true});

  final bool ticket;
  final bool vault;
  final String mixer = 'r4nd0m-mixer-value';
  int ticketCalls = 0;
  int mixerCalls = 0;
  int vaultCalls = 0;

  @override
  Future<bool> ensureTicket() async {
    ticketCalls++;
    return ticket;
  }

  @override
  Future<String> ensureMixer() async {
    mixerCalls++;
    return mixer;
  }

  @override
  Future<bool> ensureRedlightVault() async {
    vaultCalls++;
    return vault;
  }
}

void main() {
  const legacySnap = LeakSnapshot(
    policy: CabinetPolicy.legacy,
    mixer: 'DEVELOPER',
    operatorUsername: 'DEVELOPER',
    sessionIsV2: false,
    cabinetRecordExists: true,
    masterJunk: 0,
    derangeSecret: 'DEVELOPER',
  );

  test('baseline weave: detect 8 open, apply, verify 0 open, ledger names each step',
      () async {
    final hooks = _RecordingHooks();
    final result = await AutoPatcher.run(
      snapshot: legacySnap,
      trigger: 'BASELINE',
      seq: 1,
      hooks: hooks,
      now: DateTime.utc(2026, 9, 12, 12),
    );

    expect(result.before.openCount, 8);
    expect(result.after.openCount, 0);
    expect(result.policy, CabinetPolicy.woven);
    expect(result.policy.isWoven, isTrue);
    expect(hooks.ticketCalls, 1);
    expect(hooks.mixerCalls, 1, reason: 'mixer equal to username is weak');
    expect(hooks.vaultCalls, 1, reason: 'legacy cabinet has no sealed vault');
    expect(result.snapshot.redlightSealed, isTrue);

    final entry = result.entry;
    expect(entry.seq, 1);
    expect(entry.trigger, 'BASELINE');
    expect(entry.openBefore, 8);
    expect(entry.openAfter, 0);
    expect(entry.appliedCount, 8);
    expect(entry.residualCount, 2);
    expect(entry.pendingCount, 0);
    expect(entry.policyCanonical, CabinetPolicy.woven.canonical);

    final byId = {for (final r in entry.results) r.leakId: r};
    expect(byId['session.legacy']!.outcome, PatchOutcome.applied);
    expect(byId['session.legacy']!.title, 'V2 TICKET');
    expect(byId['phosphor.username']!.outcome, PatchOutcome.applied);
    expect(byId['redlight.vault']!.outcome, PatchOutcome.applied);
    expect(byId['redlight.vault']!.title, 'REDLIGHT SEAL');
    expect(byId['cabinet.hive']!.outcome, PatchOutcome.residual);
    expect(byId['client.owned']!.outcome, PatchOutcome.residual);
    expect(byId['ledger.chain']!.outcome, PatchOutcome.held);
    expect(entry.mac, isEmpty, reason: 'storage fills the chain, not the patcher');
  });

  test('second weave on a woven cabinet holds every step and applies none',
      () async {
    final hooks = _RecordingHooks();
    final first = await AutoPatcher.run(
      snapshot: legacySnap,
      trigger: 'BASELINE',
      seq: 1,
      hooks: hooks,
    );
    final second = await AutoPatcher.run(
      snapshot: first.snapshot,
      trigger: 'LOGIN',
      seq: 2,
      hooks: hooks,
    );
    expect(second.before.openCount, 0);
    expect(second.entry.appliedCount, 0);
    expect(second.entry.heldCount, 9);
    expect(second.entry.residualCount, 2);
    expect(hooks.ticketCalls, 1, reason: 'a present ticket is not re-issued');
    expect(hooks.vaultCalls, 1, reason: 'a sealed vault is not re-minted');
  });

  test('no operator to bind leaves the red-light vault PENDING', () async {
    final hooks = _RecordingHooks(vault: false);
    final result = await AutoPatcher.run(
      snapshot: legacySnap.copyWith(operatorUsername: null),
      trigger: 'MANUAL',
      seq: 1,
      hooks: hooks,
    );
    final vault = result.entry.results
        .firstWhere((r) => r.leakId == 'redlight.vault');
    expect(vault.outcome, PatchOutcome.pending);
    expect(vault.after, LeakSeverity.open);
    expect(result.policy.sealRedlight, isTrue,
        reason: 'the flag is woven; the render gate stays shut until minted');
  });

  test('no session to bind leaves the ticket step PENDING, not fake-patched',
      () async {
    final hooks = _RecordingHooks(ticket: false);
    final result = await AutoPatcher.run(
      snapshot: legacySnap.copyWith(operatorUsername: null, mixer: ''),
      trigger: 'MANUAL',
      seq: 1,
      hooks: hooks,
    );
    final ticket = result.entry.results
        .firstWhere((r) => r.leakId == 'session.legacy');
    expect(ticket.outcome, PatchOutcome.pending);
    expect(ticket.after, LeakSeverity.open);
    expect(result.after.openCount, 1);
    expect(result.policy.v2Session, isTrue,
        reason: 'policy flag is woven even while the storage action waits');
  });

  test('a broken ledger chain is an OPEN finding the weave cannot silence',
      () async {
    final result = await AutoPatcher.run(
      snapshot: legacySnap.copyWith(ledgerIntact: false, ledgerEntries: 3),
      trigger: 'RESTORE',
      seq: 4,
      hooks: _RecordingHooks(),
    );
    final chain =
        result.entry.results.firstWhere((r) => r.leakId == 'ledger.chain');
    expect(chain.after, LeakSeverity.open);
    expect(chain.outcome, PatchOutcome.pending);
  });

  test('policy canonical form is stable and copyWith is honest', () {
    expect(
      CabinetPolicy.woven.canonical,
      'stego=0;density=1;chrome=1;mixer=1;pingate=1;v2=1;tofu=1;redlight=1',
    );
    expect(CabinetPolicy.legacy.isWoven, isFalse);
    expect(CabinetPolicy.woven.copyWith(v1Stego: true).isWoven, isFalse);
    expect(CabinetPolicy.legacy.copyWith(), CabinetPolicy.legacy);
  });

  test('ledger entry survives a JSON round trip including chain fields', () {
    final entry = PatchLedgerEntry(
      seq: 9,
      trigger: 'SYNC',
      atMs: 1757678400000,
      openBefore: 1,
      openAfter: 0,
      policyCanonical: CabinetPolicy.woven.canonical,
      results: const [
        PatchResult(
          leakId: 'session.legacy',
          title: 'V2 TICKET',
          action: 'issue',
          before: LeakSeverity.open,
          after: LeakSeverity.patched,
          outcome: PatchOutcome.applied,
        ),
      ],
      prevMac: 'prev',
      mac: 'mac',
    );
    final back = PatchLedgerEntry.fromJson(entry.toJson());
    expect(back.canonical, entry.canonical);
    expect(back.mac, 'mac');
    expect(back.readout, '#9 SYNC 1→0');
    expect(back.results.single.outcome, PatchOutcome.applied);
  });
}
