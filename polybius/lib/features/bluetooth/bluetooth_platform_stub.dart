import 'package:polybius/features/bluetooth/bluetooth_models.dart';

Future<bool> bleIsSupportedImpl() async => false;

Future<void> bleRequestPermissionsImpl() async {}

Future<bool> bleEnsureOnImpl() async => false;

Future<void> bleStartScanImpl({
  required void Function(List<BtPeer> peers) onPeers,
  Duration timeout = const Duration(seconds: 14),
}) async {}

Future<void> bleStopScanImpl() async {}

Future<void> bleConnectImpl(String deviceId) async {
  throw UnsupportedError('Bluetooth unavailable');
}

void bleListenImpl(String deviceId, void Function(String payload) onData) {}

Future<bool> bleWriteImpl(String deviceId, String payload) async => false;

Future<void> bleDisconnectAllImpl() async {}
