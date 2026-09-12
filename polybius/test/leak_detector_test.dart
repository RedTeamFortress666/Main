import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/constants/master_glyphs.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/redlight/auto_patcher.dart';
import 'package:polybius/features/redlight/cabinet_policy.dart';
import 'package:polybius/features/redlight/leak_detector.dart';

void main() {
  test('legacy snapshot marks the known leaks open', () {
    final report = LeakDetector.scan(
      const LeakSnapshot(
        policy: CabinetPolicy.legacy,
        mixer: 'DEVELOPER',
        operatorUsername: 'DEVELOPER',
        sessionIsV2: false,
        cabinetRecordExists: true,
        masterJunk: 12,
        derangeSecret: 'DEVELOPER',
      ),
    );
    expect(report.byId('session.legacy')!.severity, LeakSeverity.open);
    expect(report.byId('phosphor.username')!.severity, LeakSeverity.open);
    expect(report.byId('cover.chrome')!.severity, LeakSeverity.open);
    expect(report.byId('v1.stego')!.severity, LeakSeverity.open);
    expect(report.byId('decrypt.density')!.severity, LeakSeverity.open);
    expect(report.byId('cover.pin_gate')!.severity, LeakSeverity.open);
    expect(report.byId('glyphs.tofu')!.severity, LeakSeverity.open);
    expect(report.byId('redlight.vault')!.severity, LeakSeverity.open);
    expect(report.byId('cabinet.hive')!.severity, LeakSeverity.residual);
    expect(report.byId('client.owned')!.severity, LeakSeverity.residual);
    expect(report.byId('ledger.chain')!.severity, LeakSeverity.patched);
    expect(report.openCount, 8);
  });

  test('a sealed policy without a minted vault still reads open', () {
    final report = LeakDetector.scan(
      const LeakSnapshot(
        policy: CabinetPolicy.woven,
        mixer: 'n0t-a-username-mixer',
        sessionIsV2: true,
        masterJunk: 0,
        redlightSealed: false,
      ),
    );
    expect(report.byId('redlight.vault')!.severity, LeakSeverity.open);
    expect(report.openCount, 1);
  });

  test('a broken patch ledger is an open finding', () {
    final report = LeakDetector.scan(
      const LeakSnapshot(
        policy: CabinetPolicy.woven,
        mixer: 'n0t-a-username-mixer',
        sessionIsV2: true,
        redlightSealed: true,
        masterJunk: 0,
        ledgerIntact: false,
        ledgerEntries: 2,
      ),
    );
    expect(report.byId('ledger.chain')!.severity, LeakSeverity.open);
    expect(report.openCount, 1);
  });

  test('interwoven auto-patcher closes the remediable leaks', () {
    final report = AutoPatcher.afterWeave(
      const LeakSnapshot(
        policy: CabinetPolicy.legacy,
        mixer: 'n0t-a-username-mixer',
        operatorUsername: 'DEVELOPER',
        sessionIsV2: true,
        cabinetRecordExists: true,
        masterJunk: 0,
        derangeSecret: 'n0t-a-username-mixer',
        redlightSealed: true,
      ),
    );
    expect(report.byId('session.legacy')!.severity, LeakSeverity.patched);
    expect(report.byId('redlight.vault')!.severity, LeakSeverity.patched);
    expect(report.byId('phosphor.username')!.severity, LeakSeverity.patched);
    expect(report.byId('cover.chrome')!.severity, LeakSeverity.patched);
    expect(report.byId('v1.stego')!.severity, LeakSeverity.patched);
    expect(report.byId('decrypt.density')!.severity, LeakSeverity.patched);
    expect(report.byId('cover.pin_gate')!.severity, LeakSeverity.patched);
    expect(report.byId('glyphs.tofu')!.severity, LeakSeverity.patched);
    expect(report.byId('cabinet.hive')!.severity, LeakSeverity.residual);
    expect(report.byId('client.owned')!.severity, LeakSeverity.residual);
    expect(report.byId('ledger.chain')!.severity, LeakSeverity.patched);
    expect(report.openCount, 0);
  });

  test('woven V1 encrypt is 10 glyphs for HELLO and decryptAuto reads it', () {
    const seed = 'v2-protocol-seed';
    final locked = DateTime.utc(2026, 8, 31, 0);
    final v1 = CipherEngine(
      seed: seed,
      at: locked,
      stego: CabinetPolicy.woven.v1Stego,
    );
    final cipher = v1.encrypt('HELLO');
    expect(cipher.runes.length, 10);
    expect(
      CipherEngine.decryptAuto(seed: seed, text: cipher, at: locked),
      'HELLO',
    );
    final cabinet = CipherEngine(
      seed: seed,
      at: locked,
      stego: false,
      density: GlyphDensity.cabinet,
    ).encrypt('HELLO');
    expect(cabinet.runes.length, 15);
    expect(
      CipherEngine.decryptAuto(seed: seed, text: cabinet, at: locked),
      'HELLO',
    );
  });

  test('master cabinet has no junk runes and is larger than 560', () {
    expect(MasterGlyphs.junkCount, 0);
    expect(MasterGlyphs.size, greaterThan(560));
  });
}
