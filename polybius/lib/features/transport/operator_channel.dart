import 'dart:async';
import 'dart:typed_data';

/// One courier in the hybrid mesh. Reticulum is preferred; Matrix is a
/// fallback room; QR is the air-gap courier that always works.
///
/// None of these channels hide *that* you talked. They only carry sealed
/// frames. Timing side-channels remain; send cover frames if you care.
abstract class OperatorChannel {
  String get name;

  Future<ChannelStatus> status();

  Future<void> send(Uint8List frame);

  Stream<Uint8List> get incoming;
}

class ChannelStatus {
  const ChannelStatus({
    required this.online,
    required this.detail,
  });

  final bool online;
  final String detail;
}

/// In-process mailbox for tests and for "Matrix/RNS offline" dry runs.
class LoopbackChannel implements OperatorChannel {
  LoopbackChannel({this.label = 'LOOP'});

  final String label;
  final _box = StreamController<Uint8List>.broadcast();

  @override
  String get name => label;

  @override
  Future<ChannelStatus> status() async => ChannelStatus(
        online: true,
        detail: '$label CABINET',
      );

  @override
  Future<void> send(Uint8List frame) async => _box.add(frame);

  @override
  Stream<Uint8List> get incoming => _box.stream;

  void dispose() => _box.close();
}
