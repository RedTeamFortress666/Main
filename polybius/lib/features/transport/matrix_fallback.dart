import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:polybius/features/transport/operator_channel.dart';

/// Optional Matrix room fallback.
///
/// We POST a custom event `com.sinnesloschen.polybius.sync` whose body is
/// the already-sealed frame (base64). The homeserver sees an opaque blob
/// and a room id — that *is* metadata. Prefer Reticulum or QR.
///
/// This class does not perform HTTP itself so tests stay hermetic. Inject
/// [MatrixHttp] (real or fake).
class MatrixFallback implements OperatorChannel {
  MatrixFallback({
    this.homeserver,
    this.accessToken,
    this.roomId,
    this.http,
  });

  String? homeserver;
  String? accessToken;
  String? roomId;
  MatrixHttp? http;
  final _incoming = StreamController<Uint8List>.broadcast();

  static const eventType = 'com.sinnesloschen.polybius.sync';

  bool get configured =>
      (homeserver ?? '').isNotEmpty &&
      (accessToken ?? '').isNotEmpty &&
      (roomId ?? '').isNotEmpty;

  @override
  String get name => 'MATRIX';

  @override
  Future<ChannelStatus> status() async {
    if (!configured) {
      return const ChannelStatus(
        online: false,
        detail: 'MATRIX ROOM NOT ARMED',
      );
    }
    return ChannelStatus(
      online: http != null,
      detail: http == null
          ? 'MATRIX CONFIGURED — NO COURIER'
          : 'MATRIX $roomId',
    );
  }

  @override
  Future<void> send(Uint8List frame) async {
    final client = http;
    if (!configured || client == null) {
      throw StateError('MATRIX UNAVAILABLE');
    }
    final txn = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final path =
        '/_matrix/client/v3/rooms/${Uri.encodeComponent(roomId!)}/send/$eventType/$txn';
    await client.putJson(
      Uri.parse('${homeserver!.replaceAll(RegExp(r'/$'), '')}$path'),
      token: accessToken!,
      body: {'body': base64Encode(frame), 'msgtype': eventType},
    );
  }

  /// Feed a received event body (tests / polling loop).
  void ingestEventBody(String b64) {
    try {
      _incoming.add(Uint8List.fromList(base64Decode(b64)));
    } catch (_) {}
  }

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  void dispose() => _incoming.close();
}

abstract class MatrixHttp {
  Future<void> putJson(Uri uri, {required String token, required Map<String, dynamic> body});
}

/// Records PUTs for tests. Does not touch the network.
class RecordingMatrixHttp implements MatrixHttp {
  final puts = <Uri>[];
  final bodies = <Map<String, dynamic>>[];

  @override
  Future<void> putJson(
    Uri uri, {
    required String token,
    required Map<String, dynamic> body,
  }) async {
    puts.add(uri);
    bodies.add(body);
  }
}
