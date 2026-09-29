import 'package:flutter_test/flutter_test.dart';
import 'package:shadownet/core/models/abliterated_model.dart';
import 'package:shadownet/core/models/connect_point.dart';
import 'package:shadownet/qshield/qshield_core.dart';

void main() {
  test('abliterated catalog entries are in 2-6 GB band', () {
    for (final m in abliteratedCatalog) {
      expect(m.inTargetRange, isTrue, reason: m.id);
    }
  });

  test('connect point builds chat completions URL', () {
    final p = ConnectPoint(
      id: 't',
      label: 't',
      kind: ConnectPointKind.llamaCpp,
      baseUrl: 'http://127.0.0.1:8080',
      modelPath: '',
    );
    expect(p.chatCompletionsUrl, 'http://127.0.0.1:8080/v1/chat/completions');
  });

  test('QShield establishes session and seals payload', () async {
    final core = QShieldCore();
    final info = await core.establishSession();
    expect(info.isReady, isTrue);
    expect(info.pqcKeyId.length, greaterThan(10));

    final sealed = await core.sealPayload('test prompt');
    final opened = await core.openPayload(sealed);
    expect(opened, 'test prompt');
  });
}
