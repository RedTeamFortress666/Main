import 'dart:convert';
import 'dart:typed_data';

import 'package:polybius/features/roundtable/round_table.dart';
import 'package:polybius/features/roundtable/traffic_sketch.dart';
import 'package:polybius/features/stego/stego_receipt.dart';
import 'package:polybius/features/stego/stego_vet.dart';

export 'package:polybius/features/roundtable/round_table.dart' show PatternReport;

/// Talks to a Tailscale/Proxmox vetting sidecar (default 127.0.0.1:3743).
///
/// JSON-lines:
///   {"op":"hello"}
///   {"op":"vet","fp":"...hex...","decoys":N,"sketch":{...}}
///   {"op":"receipt", ...}   // server reply — never includes notes
///
/// When nothing is listening the cabinet uses an in-process
/// [StegoVetAuthority.local] so ENCRYPT still gets a receipt. That
/// stand-in is labeled `local`. A real daemon is labeled `sidecar`.
class VetSidecar {
  VetSidecar({
    this.host = '127.0.0.1',
    this.port = 3743,
    this._local,
  });

  final String host;
  final int port;
  final StegoVetAuthority? _local;

  Future<bool> get reachable async => false;

  Future<({StegoReceipt receipt, PatternReport report})> vet({
    required StegoFingerprint fingerprint,
    TrafficSketch? sketch,
  }) async {
    final authority = _local;
    if (authority == null) {
      throw StateError('no local authority and sidecar unreachable');
    }
    return authority.vet(fingerprint: fingerprint, sketch: sketch);
  }
}

/// IO implementation — separate library so web compiles.
class VetSidecarIo {
  static const defaultHost = '127.0.0.1';
  static const defaultPort = 3743;
}

/// Decode a sidecar JSON reply into a receipt + boiled report.
({StegoReceipt? receipt, PatternReport? report}) parseSidecarReply(String line) {
  try {
    final map = jsonDecode(line);
    if (map is! Map) return (receipt: null, report: null);
    final receipt = StegoReceipt.tryParse(map['receipt'] ?? map);
    PatternReport? report;
    final raw = map['report'];
    if (raw is Map) {
      report = PatternReport.fromJson(Map<String, dynamic>.from(raw));
    }
    return (receipt: receipt, report: report);
  } catch (_) {
    return (receipt: null, report: null);
  }
}

Uint8List encodeVetRequest({
  required StegoFingerprint fingerprint,
  TrafficSketch? sketch,
}) {
  return Uint8List.fromList(utf8.encode('${jsonEncode({
        'op': 'vet',
        'fp': fingerprint.digestHex,
        'decoys': fingerprint.decoyCount,
        if (sketch != null) 'sketch': sketch.toJson(),
      })}\n'));
}
