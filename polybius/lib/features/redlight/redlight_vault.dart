import 'dart:convert';
import 'dart:math';

import 'package:flutter/painting.dart';

/// Everything that drives the red-light layer, sealed as one record.
///
/// The phosphor filter constants and the keypress derangement secret live
/// here — never as loose Hive keys. The record is stored AES-encrypted under
/// the device key and carries its [owner]; the vault refuses to open for any
/// other operator. What a Hive dump shows is one opaque `v2:` blob.
class RedlightProfile {
  const RedlightProfile({
    required this.owner,
    required this.mixer,
    required this.lampGain,
    required this.lampLift,
    required this.crush,
    this.version = 1,
  });

  /// Operator (uppercase) the vault was minted for.
  final String owner;

  /// Random derangement seed. Never the username, never shorter than 16 B.
  final String mixer;

  /// Red-channel gain of the cabinet lamp matrix.
  final double lampGain;

  /// Red-channel lift (0–255 offset) of the cabinet lamp matrix.
  final double lampLift;

  /// Green/blue survivor factor — how hard cyan house labels crush.
  final double crush;

  final int version;

  static RedlightProfile mint({
    required String owner,
    String? mixer,
    Random? random,
  }) {
    final rng = random ?? Random.secure();
    final seed = mixer ??
        base64Url.encode(List<int>.generate(24, (_) => rng.nextInt(256)));
    // Small per-vault jitter so two devices never share an identical filter
    // signature; still a deep-red lamp on every one of them.
    return RedlightProfile(
      owner: owner.trim().toUpperCase(),
      mixer: seed,
      lampGain: 1.25 + rng.nextInt(21) / 100, // 1.25 .. 1.45
      lampLift: 20 + rng.nextInt(17).toDouble(), // 20 .. 36
      crush: 0.02 + rng.nextInt(4) / 100, // 0.02 .. 0.05
    );
  }

  ColorFilter get lampFilter => ColorFilter.matrix(<double>[
        lampGain, 0, 0, 0, lampLift,
        0, crush, 0, 0, 0,
        0, 0, crush, 0, 0,
        0, 0, 0, 1, 0,
      ]);

  String get canonical =>
      'v$version|$owner|$mixer|${lampGain.toStringAsFixed(2)}|${lampLift.toStringAsFixed(0)}|${crush.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() => {
        'v': version,
        'owner': owner,
        'mixer': mixer,
        'gain': lampGain,
        'lift': lampLift,
        'crush': crush,
      };

  static RedlightProfile? tryParse(String json) {
    try {
      final map = jsonDecode(json);
      if (map is! Map) return null;
      final owner = map['owner'];
      final mixer = map['mixer'];
      if (owner is! String || mixer is! String || mixer.length < 16) {
        return null;
      }
      return RedlightProfile(
        owner: owner,
        mixer: mixer,
        lampGain: (map['gain'] as num).toDouble(),
        lampLift: (map['lift'] as num).toDouble(),
        crush: (map['crush'] as num).toDouble(),
        version: (map['v'] as num?)?.toInt() ?? 1,
      );
    } catch (_) {
      return null;
    }
  }

  /// Keypress-obfuscation secret for [GlyphDerangement.pin].
  ///
  /// HMAC under the device key over mixer + owner, so the value that keys
  /// the phosphor map is never stored anywhere and cannot be recomputed from
  /// a decrypted vault on another device.
  String derangeSecret(List<int> Function(List<int> data) deviceMac) {
    final digest = deviceMac(utf8.encode('REDLIGHT-DERANGE::$owner::$mixer'));
    return base64Url.encode(digest);
  }
}

/// Why the red-light layer is (or is not) available right now.
enum RedlightSeal {
  /// Vault open; keyboard and lamp live.
  open,

  /// Darth Cherry is dark — nothing to show.
  cherryDark,

  /// No authenticated operator on this device.
  noOperator,

  /// Session box has no valid, unexpired V2 ticket for this device.
  noTicket,

  /// Ticket operator and live operator disagree.
  operatorMismatch,

  /// Policy has not sealed red-light (legacy cabinet).
  policyUnsealed,

  /// Blob present but will not decrypt / parse / is owned by someone else.
  vaultLocked,

  /// Glasses HUD policy is on and this device has no paired session.
  noGlasses,
}

class RedlightAccess {
  const RedlightAccess.sealed(this.seal)
      : profile = null,
        derangeSecret = '';

  const RedlightAccess.open({
    required RedlightProfile this.profile,
    required this.derangeSecret,
  }) : seal = RedlightSeal.open;

  final RedlightSeal seal;
  final RedlightProfile? profile;
  final String derangeSecret;

  bool get granted => seal == RedlightSeal.open && profile != null;

  /// CRT wording for the sealed panel.
  String get reason => switch (seal) {
        RedlightSeal.open => 'VAULT OPEN',
        RedlightSeal.cherryDark => 'DARTH CHERRY DARK',
        RedlightSeal.noOperator => 'NO OPERATOR — LOG IN ON THIS DEVICE',
        RedlightSeal.noTicket => 'NO DEVICE TICKET — V2 LOGIN REQUIRED',
        RedlightSeal.operatorMismatch => 'TICKET OPERATOR MISMATCH',
        RedlightSeal.policyUnsealed => 'CABINET POLICY UNSEALED — RUN WEAVE',
        RedlightSeal.vaultLocked => 'VAULT LOCKED — NOT MINTED ON THIS DEVICE',
        RedlightSeal.noGlasses => 'NO HUD PAIR — ATTRACT MODE FOR THIS FACE',
      };
}
