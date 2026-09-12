import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/roundtable/round_table.dart';
import 'package:polybius/features/roundtable/traffic_sketch.dart';

void main() {
  const table = RoundTable();

  test('human-typed gaps vote HUMAN and never interfere', () {
    final sketch = TrafficSketch(
      gapsMs: [210, 180, 640, 150, 190, 880, 240, 170, 510],
      decoyCount: 2,
      hasReceipt: true,
      channel: 'qr',
    );
    final report = table.convene(sketch, nowMs: 1);
    expect(report.verdict, CadenceVerdict.human);
    expect(report.interfered, isFalse);
    expect(report.boil, contains('NO INTERFERENCE'));
    expect(report.votes.map((v) => v.seat), RoundTable.seats);
  });

  test('metronome gaps plus history vote HOSTILE but still do not drop', () {
    final machine = TrafficSketch(
      gapsMs: List<int>.filled(16, 16),
      decoyCount: 20,
      hasReceipt: false,
      channel: 'agent',
    );
    final prior = List<TrafficSketch>.generate(
      3,
      (i) => TrafficSketch(
        gapsMs: List<int>.filled(12, 16),
        decoyCount: 20,
        channel: 'agent',
        atMs: i,
      ),
    );
    final report = table.convene(machine, history: prior, nowMs: 9);
    expect(report.verdict, CadenceVerdict.hostile);
    expect(report.interfered, isFalse, reason: 'watch only — never drop H2H');
    expect(report.boil, contains('DOUBLESPEAK'));
  });

  test('a sketch has no room for plaintext or glyphs', () {
    final json = const TrafficSketch(
      gapsMs: [100, 200],
      fingerprintPrefix: 'deadbeef',
      decoyCount: 3,
    ).toJson();
    expect(json.containsKey('plain'), isFalse);
    expect(json.containsKey('cipher'), isFalse);
    expect(json['f'], 'deadbeef');
  });
}
