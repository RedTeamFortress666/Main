import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/roundtable/round_table.dart';
import 'package:polybius/features/roundtable/traffic_sketch.dart';
import 'package:polybius/features/stego/stego_receipt.dart';

/// One-way view of unused-master decoys. The sidecar may hash this;
/// it never receives plaintext or the active-pool ciphertext.
class StegoFingerprint {
  const StegoFingerprint({
    required this.digestHex,
    required this.decoyCount,
  });

  final String digestHex;
  final int decoyCount;

  String get prefix =>
      digestHex.length >= 8 ? digestHex.substring(0, 8) : digestHex;

  /// Pull unused-master runes out of an encrypted glyph string.
  ///
  /// Active-pool glyphs (the human message) are dropped. What remains
  /// is the decoy stream the V1/Cherry stego path inserted.
  static StegoFingerprint of(CipherEngine engine, String cipher) {
    final active = engine.pool.toSet();
    final decoys = <int>[];
    for (final rune in cipher.runes) {
      final g = String.fromCharCode(rune);
      if (active.contains(g)) continue;
      decoys.add(rune);
    }
    final digest = sha256.convert(utf8.encode(decoys.join(','))).toString();
    return StegoFingerprint(digestHex: digest, decoyCount: decoys.length);
  }
}

/// Sidecar / in-process authority that vets stego and convenes the table.
///
/// The MAC key stays here. The cabinet verifies receipts but cannot
/// mint a PASS. Analyst notes live in [_notes] and are never serialised
/// onto a receipt — that is the "hidden even to developers" line on the
/// device. Whoever runs this process (Proxmox LXC, Tailscale host) can
/// still dump [_notes]; name that residual, do not pretend otherwise.
class StegoVetAuthority {
  StegoVetAuthority(this._macKey, {this.origin = 'local'});

  /// Device-bound local stand-in. Labeled [origin] = `local`. A real
  /// Tailscale/Proxmox daemon uses its own key and origin `sidecar`.
  factory StegoVetAuthority.local(List<int> Function(List<int>) deviceMac) {
    return StegoVetAuthority(
      Uint8List.fromList(deviceMac(utf8.encode('STEGO-VET-AUTHORITY'))),
    );
  }

  final Uint8List _macKey;
  final String origin;
  final _notes = <String, String>{};
  final _history = <TrafficSketch>[];
  final _table = const RoundTable();

  String? noteFor(String receiptId) => _notes[receiptId];

  bool verify(StegoReceipt receipt) {
    final expected = _mac(receipt.canonical);
    return _constEq(expected, receipt.mac);
  }

  /// Vet a fingerprint + optional cadence sketch.
  ///
  /// [plaintext] is rejected if passed — the API does not take it.
  /// Quarantine is for machine-regular decoy counts / hostile cadence,
  /// not for human messages. A HUMAN verdict never becomes quarantine
  /// and [PatternReport.interfered] stays false.
  ({StegoReceipt receipt, PatternReport report}) vet({
    required StegoFingerprint fingerprint,
    TrafficSketch? sketch,
    int? nowMs,
  }) {
    final at = nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    final live = sketch ??
        TrafficSketch(
          gapsMs: const [],
          fingerprintPrefix: fingerprint.prefix,
          decoyCount: fingerprint.decoyCount,
          atMs: at,
        );
    final withFp = TrafficSketch(
      gapsMs: live.gapsMs,
      paddedSize: live.paddedSize,
      channel: live.channel,
      hasReceipt: true,
      fingerprintPrefix: fingerprint.prefix,
      decoyCount: fingerprint.decoyCount,
      atMs: at,
    );
    final report = _table.convene(
      withFp,
      history: List<TrafficSketch>.from(_history),
      nowMs: at,
      origin: origin,
    );
    _history.add(withFp);
    if (_history.length > 32) _history.removeAt(0);

    var status = VetStatus.pass;
    if (fingerprint.decoyCount == 0) {
      status = VetStatus.pass;
    } else if (report.verdict == CadenceVerdict.hostile) {
      status = VetStatus.quarantine;
    } else if (report.verdict == CadenceVerdict.mixed &&
        fingerprint.decoyCount > 48) {
      status = VetStatus.hold;
    }
    if (report.isHuman) status = VetStatus.pass;

    final id = _id(at);
    final draft = StegoReceipt(
      id: id,
      status: status,
      atMs: at,
      fingerprintPrefix: fingerprint.prefix,
      mac: '',
      origin: origin,
    );
    final receipt = StegoReceipt(
      id: id,
      status: status,
      atMs: at,
      fingerprintPrefix: fingerprint.prefix,
      mac: _mac(draft.canonical),
      origin: origin,
    );
    _notes[id] = report.votes.map((v) => '${v.seat}:${v.note}').join('|');
    return (receipt: receipt, report: report);
  }

  String _mac(String canonical) {
    final digest = Hmac(sha256, _macKey).convert(utf8.encode(canonical));
    return base64Url.encode(digest.bytes);
  }

  String _id(int atMs) {
    final rng = Random.secure();
    final n = List<int>.generate(8, (_) => rng.nextInt(256));
    return base64Url.encode([...utf8.encode('$atMs'), ...n]);
  }

  static bool _constEq(String a, String b) {
    if (a.length != b.length) return false;
    var d = 0;
    for (var i = 0; i < a.length; i++) {
      d |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return d == 0;
  }
}
