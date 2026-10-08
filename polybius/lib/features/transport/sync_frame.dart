import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:polybius/core/constants/app_constants.dart';

/// Constant-size courier frame. Kind + payload + random pad, always
/// [AppConstants.syncFrameBytes] so a watcher cannot tell pool-sync from
/// high-score from rotor-tick by length.
///
/// This blunts *length* metadata. It does not hide that a frame was sent,
/// nor timing — cover traffic (below) is the honest next step, not magic.
class SyncFrame {
  const SyncFrame({
    required this.kind,
    required this.payload,
    this.sentAt,
  });

  /// pool | score | rotor | cover
  final String kind;
  final Uint8List payload;
  final DateTime? sentAt;

  static const _kinds = {'pool', 'score', 'rotor', 'cover'};

  Uint8List encodePadded({int size = AppConstants.syncFrameBytes}) {
    final inner = utf8.encode(jsonEncode({
      'k': kind,
      'p': base64Url.encode(payload),
    }));
    if (inner.length + 4 > size) {
      throw ArgumentError('CABINET FRAME OVERFULL (${inner.length} + 4 > $size)');
    }
    final rng = Random.secure();
    final pad = Uint8List(size - 4 - inner.length);
    for (var i = 0; i < pad.length; i++) {
      pad[i] = rng.nextInt(256);
    }
    final out = BytesBuilder();
    out.add([(inner.length >> 8) & 0xff, inner.length & 0xff]);
    out.add(inner);
    out.add(pad);
    // trailer checksum of kind only — not a MAC; the hybrid envelope is the MAC
    final sum = kind.codeUnits.fold<int>(0, (a, b) => (a + b) & 0xffff);
    out.add([(sum >> 8) & 0xff, sum & 0xff]);
    final bytes = out.toBytes();
    assert(bytes.length == size);
    return bytes;
  }

  static SyncFrame? tryParse(List<int> raw) {
    if (raw.length < 4) return null;
    final innerLen = (raw[0] << 8) | raw[1];
    if (innerLen <= 0 || 2 + innerLen + 2 > raw.length) return null;
    try {
      final map = jsonDecode(utf8.decode(raw.sublist(2, 2 + innerLen)))
          as Map<String, dynamic>;
      final kind = map['k'] as String;
      if (!_kinds.contains(kind)) return null;
      return SyncFrame(
        kind: kind,
        payload: Uint8List.fromList(base64Url.decode(map['p'] as String)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Dummy cover-traffic frame. Same size, no useful payload.
  static SyncFrame cover() {
    final rng = Random.secure();
    return SyncFrame(
      kind: 'cover',
      payload: Uint8List.fromList(
        List<int>.generate(48, (_) => rng.nextInt(256)),
      ),
    );
  }
}
