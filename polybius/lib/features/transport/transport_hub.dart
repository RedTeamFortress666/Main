import 'dart:typed_data';

import 'package:polybius/features/transport/matrix_fallback.dart';
import 'package:polybius/features/transport/operator_channel.dart';
import 'package:polybius/features/transport/qr_courier.dart';
import 'package:polybius/features/transport/reticulum_gateway.dart';
import 'package:polybius/features/transport/sync_frame.dart';

/// Prefers Reticulum, falls back to Matrix, always keeps QR.
///
/// Dispatch order: RNS if online, else Matrix if armed, else the caller
/// must show the QR. We never invent a route that does not exist.
class TransportHub {
  TransportHub({
    QrCourier? qr,
    ReticulumGateway? reticulum,
    MatrixFallback? matrix,
  })  : qr = qr ?? QrCourier(),
        reticulum = reticulum ?? ReticulumGateway(),
        matrix = matrix ?? MatrixFallback();

  final QrCourier qr;
  final ReticulumGateway reticulum;
  final MatrixFallback matrix;

  Future<DispatchReport> dispatch(SyncFrame frame, {bool cover = false}) async {
    final wire = (cover ? SyncFrame.cover() : frame).encodePadded();
    final rns = await reticulum.status();
    if (rns.online) {
      await reticulum.send(wire);
      return DispatchReport(channel: reticulum.name, frame: wire);
    }
    final mx = await matrix.status();
    if (mx.online) {
      await matrix.send(wire);
      return DispatchReport(channel: matrix.name, frame: wire);
    }
    return DispatchReport(channel: qr.name, frame: wire);
  }

  Future<List<ChannelStatus>> snapshot() async => [
        await qr.status(),
        await reticulum.status(),
        await matrix.status(),
      ];
}

class DispatchReport {
  const DispatchReport({required this.channel, required this.frame});

  final String channel;
  final Uint8List frame;
}
