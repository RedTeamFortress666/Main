import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:polybius/features/redlight/redlight_vault.dart';

/// Who is looking at this screen.
enum GlassesViewer {
  /// Arcade attract / false screensaver. Non-intended.
  public,

  /// This device is the paired HUD (loopback glasses).
  hud,
}

/// Device-bound glasses session. Same shape as a V2 ticket: the MAC is
/// under the working key, so a copied pairing string fails on another
/// box. Does not prove a password.
class GlassesSession {
  const GlassesSession({
    required this.owner,
    required this.nonce,
    required this.issuedMs,
    required this.mac,
  });

  final String owner;
  final String nonce;
  final int issuedMs;
  final String mac;

  String get canonical => 'v1:GLASSES:$owner:$issuedMs:$nonce';

  String get wire => '$canonical:$mac';

  bool verify(List<int> Function(List<int>) deviceMac) {
    final expected = base64Url.encode(deviceMac(utf8.encode(canonical)));
    if (expected.length != mac.length) return false;
    var d = 0;
    for (var i = 0; i < mac.length; i++) {
      d |= expected.codeUnitAt(i) ^ mac.codeUnitAt(i);
    }
    return d == 0;
  }

  static GlassesSession issue({
    required String owner,
    required List<int> Function(List<int>) deviceMac,
    int? issuedMs,
    String? nonce,
  }) {
    final at = issuedMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    final n = nonce ??
        base64Url.encode(List<int>.generate(12, (_) => Random.secure().nextInt(256)));
    final who = owner.trim().toUpperCase();
    final canonical = 'v1:GLASSES:$who:$at:$n';
    return GlassesSession(
      owner: who,
      nonce: n,
      issuedMs: at,
      mac: base64Url.encode(deviceMac(utf8.encode(canonical))),
    );
  }

  static GlassesSession? parse(String wire) {
    final parts = wire.split(':');
    if (parts.length != 6) return null;
    if (parts[0] != 'v1' || parts[1] != 'GLASSES') return null;
    final issued = int.tryParse(parts[3]);
    if (issued == null) return null;
    return GlassesSession(
      owner: parts[2],
      issuedMs: issued,
      nonce: parts[4],
      mac: parts[5],
    );
  }
}

/// What the HUD is allowed to paint. Lamp matrix + phosphor bit.
/// No plaintext, no mixer, no derangement secret.
class HudFrame {
  const HudFrame({
    required this.owner,
    required this.gain,
    required this.lift,
    required this.crush,
    required this.phosphor,
  });

  final String owner;
  final double gain;
  final double lift;
  final double crush;
  final bool phosphor;

  factory HudFrame.fromProfile(RedlightProfile profile, {required bool phosphor}) {
    return HudFrame(
      owner: profile.owner,
      gain: profile.lampGain,
      lift: profile.lampLift,
      crush: profile.crush,
      phosphor: phosphor,
    );
  }

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'gain': gain,
        'lift': lift,
        'crush': crush,
        'phosphor': phosphor,
      };

  Uint8List encode() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));
}
