import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/features/transport/matrix_fallback.dart';
import 'package:polybius/features/transport/operator_channel.dart';
import 'package:polybius/features/transport/sync_frame.dart';
import 'package:polybius/features/transport/transport_hub.dart';

void main() {
  test('frames pad to a constant size', () {
    final a = SyncFrame(kind: 'pool', payload: Uint8List.fromList([1, 2, 3]));
    final b = SyncFrame.cover();
    expect(a.encodePadded().length, AppConstants.syncFrameBytes);
    expect(b.encodePadded().length, AppConstants.syncFrameBytes);
    expect(SyncFrame.tryParse(a.encodePadded())!.kind, 'pool');
    expect(SyncFrame.tryParse(a.encodePadded())!.payload, [1, 2, 3]);
  });

  test('hub falls back to QR when RNS and Matrix are dark', () async {
    final hub = TransportHub();
    final report = await hub.dispatch(
      SyncFrame(kind: 'score', payload: Uint8List(8)),
    );
    expect(report.channel, 'QR');
    expect(report.frame.length, AppConstants.syncFrameBytes);
  });

  test('loopback channel echoes a frame', () async {
    final loop = LoopbackChannel();
    late Uint8List seen;
    final sub = loop.incoming.listen((f) => seen = f);
    await loop.send(Uint8List.fromList([9, 9]));
    await Future<void>.delayed(Duration.zero);
    expect(seen, [9, 9]);
    await sub.cancel();
    loop.dispose();
  });

  test('matrix fallback records a sealed PUT', () async {
    final http = RecordingMatrixHttp();
    final mx = MatrixFallback(
      homeserver: 'https://matrix.example',
      accessToken: 'syt_test',
      roomId: '!room:example',
      http: http,
    );
    await mx.send(Uint8List.fromList([4, 4, 4]));
    expect(http.puts, isNotEmpty);
    expect(http.puts.first.path, contains('com.sinnesloschen.polybius.sync'));
    mx.dispose();
  });
}
