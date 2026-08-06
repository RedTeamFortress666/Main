import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// An inbound relayed message from a peer over Reticulum.
class ReticulumMessage {
  const ReticulumMessage({required this.from, required this.payload});
  final String from;
  final String payload;
}

/// A parsed WebSocket frame from the bridge.
sealed class ReticulumFrame {
  const ReticulumFrame();
}

class IdentityFrame extends ReticulumFrame {
  const IdentityFrame(this.address);
  final String address;
}

class MessageFrame extends ReticulumFrame {
  const MessageFrame(this.message);
  final ReticulumMessage message;
}

class ErrorFrame extends ReticulumFrame {
  const ErrorFrame(this.detail);
  final String detail;
}

/// Client for the Python `polybius_bridge.py` (Reticulum/LXMF ↔ WebSocket).
///
/// The bridge carries opaque emoji ciphertext over a Reticulum mesh; this
/// client never handles plaintext. It is opt-in: nothing connects until
/// [connect] is called, and all failures degrade gracefully (the mesh simply
/// isn't available if the bridge isn't running).
class ReticulumClient {
  ReticulumClient({this.url = 'ws://127.0.0.1:8765'});

  final String url;

  WebSocketChannel? _channel;
  final _incoming = StreamController<ReticulumMessage>.broadcast();
  final _errors = StreamController<String>.broadcast();
  final _address = StreamController<String>.broadcast();

  bool connected = false;
  String? localAddress;

  Stream<ReticulumMessage> get incoming => _incoming.stream;
  Stream<String> get errors => _errors.stream;
  Stream<String> get address => _address.stream;

  Future<bool> connect() async {
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      await channel.ready;
      _channel = channel;
      connected = true;
      channel.stream.listen(
        _onData,
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
        cancelOnError: true,
      );
      return true;
    } catch (_) {
      connected = false;
      return false;
    }
  }

  void _onData(dynamic data) {
    if (data is! String) return;
    final frame = parseFrame(data);
    switch (frame) {
      case IdentityFrame(:final address):
        localAddress = address;
        _address.add(address);
      case MessageFrame(:final message):
        _incoming.add(message);
      case ErrorFrame(:final detail):
        _errors.add(detail);
      case null:
        break;
    }
  }

  void _onDisconnect() {
    connected = false;
  }

  /// Relay [payload] (emoji ciphertext) to a peer's hex destination hash.
  bool send(String destinationHash, String payload) {
    final channel = _channel;
    if (channel == null || !connected) return false;
    channel.sink.add(encodeSend(destinationHash, payload));
    return true;
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    connected = false;
  }

  Future<void> dispose() async {
    await disconnect();
    await _incoming.close();
    await _errors.close();
    await _address.close();
  }

  // --- Pure protocol helpers (unit-testable, no socket) ---

  static String encodeSend(String to, String payload) =>
      jsonEncode({'type': 'send', 'to': to, 'payload': payload});

  static ReticulumFrame? parseFrame(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      switch (json['type']) {
        case 'identity':
          final a = json['address'] as String?;
          return a == null ? null : IdentityFrame(a);
        case 'message':
          return MessageFrame(ReticulumMessage(
            from: json['from'] as String? ?? '',
            payload: json['payload'] as String? ?? '',
          ));
        case 'error':
          return ErrorFrame(json['detail'] as String? ?? 'unknown error');
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}

final reticulumClientProvider = Provider<ReticulumClient>((ref) {
  final client = ReticulumClient();
  ref.onDispose(client.dispose);
  return client;
});
