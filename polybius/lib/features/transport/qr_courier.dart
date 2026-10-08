import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:polybius/features/transport/operator_channel.dart';

/// Air-gap courier. Frames are base64url; the SYNC tab paints the QR.
/// Incoming is whatever the operator pastes or scans — we do not poll.
class QrCourier implements OperatorChannel {
  final _incoming = StreamController<Uint8List>.broadcast();

  @override
  String get name => 'QR';

  @override
  Future<ChannelStatus> status() async => const ChannelStatus(
        online: true,
        detail: 'AIR-GAP COURIER — SCAN OR PASTE',
      );

  @override
  Future<void> send(Uint8List frame) async {
    // QR is pull-only. The UI reads [encode] and shows it.
  }

  String encode(Uint8List frame) => base64Url.encode(frame);

  void ingestScanned(String raw) {
    try {
      _incoming.add(Uint8List.fromList(base64Url.decode(raw.trim())));
    } catch (_) {
      // Invalid scan is dropped; the SYNC tab reports its own errors.
    }
  }

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  void dispose() => _incoming.close();
}
