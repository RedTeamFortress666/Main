import 'dart:async';
import 'dart:typed_data';

import 'package:polybius/features/transport/operator_channel.dart';

/// Web / missing-IO build: Reticulum needs a native sidecar.
class ReticulumGateway implements OperatorChannel {
  ReticulumGateway({this.host = '127.0.0.1', this.port = 3742});

  final String host;
  final int port;

  @override
  String get name => 'RNS';

  @override
  Future<ChannelStatus> status() async => const ChannelStatus(
        online: false,
        detail: 'RNS SIDECAR REQUIRES NATIVE CABINET',
      );

  @override
  Future<void> send(Uint8List frame) async {
    throw StateError('RNS UNAVAILABLE ON THIS CABINET');
  }

  @override
  Stream<Uint8List> get incoming => const Stream.empty();
}
