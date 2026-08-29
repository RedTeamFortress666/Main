import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:polybius/features/transport/operator_channel.dart';

/// Talks to a local Reticulum sidecar (default `127.0.0.1:3742`).
///
/// Reticulum itself is a Python stack (RNS). This cabinet does not embed
/// it — we speak a tiny JSON-lines protocol to a loopback daemon:
///
///   {"op":"status"}
///   {"op":"send","payload_b64":"..."}
///   {"op":"recv","payload_b64":"..."}   // server-push
///
/// If nothing is listening, the channel reports CABINET OFFLINE and QR
/// still works. That is the honest mesh story on this build.
class ReticulumGateway implements OperatorChannel {
  ReticulumGateway({this.host = '127.0.0.1', this.port = 3742});

  final String host;
  final int port;
  final _incoming = StreamController<Uint8List>.broadcast();

  @override
  String get name => 'RNS';

  @override
  Future<ChannelStatus> status() async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 400),
      );
      socket.destroy();
      return ChannelStatus(
        online: true,
        detail: 'RNS SIDECAR $host:$port',
      );
    } catch (_) {
      return const ChannelStatus(
        online: false,
        detail: 'RNS SIDECAR OFFLINE — QR STILL LIVE',
      );
    }
  }

  @override
  Future<void> send(Uint8List frame) async {
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 2),
    );
    socket.write('${jsonEncode({
      'op': 'send',
      'payload_b64': base64Encode(frame),
    })}\n');
    await socket.flush();
    socket.destroy();
  }

  @override
  Stream<Uint8List> get incoming => _incoming.stream;
}
