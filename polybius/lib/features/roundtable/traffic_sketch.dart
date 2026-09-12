import 'dart:convert';

/// Metadata a round-table analyst is allowed to see.
///
/// No plaintext. No glyph ciphertext. No unused-master decoy runes.
/// Timing gaps, padded-frame sizes (usually constant), channel name,
/// whether a vet receipt exists, and a one-way fingerprint of the
/// stego *pattern* (not the pattern itself). That is the whole view.
class TrafficSketch {
  const TrafficSketch({
    required this.gapsMs,
    this.paddedSize = 2048,
    this.channel = 'local',
    this.hasReceipt = false,
    this.fingerprintPrefix = '',
    this.decoyCount = 0,
    this.atMs = 0,
  });

  /// Inter-event gaps in milliseconds (keypress fade or send cadence).
  final List<int> gapsMs;
  final int paddedSize;
  final String channel;
  final bool hasReceipt;

  /// First 8 hex chars of the stego fingerprint. Not reversible.
  final String fingerprintPrefix;
  final int decoyCount;
  final int atMs;

  bool get looksHumanTyped {
    if (gapsMs.length < 3) return true;
    final human = gapsMs.where((g) => g >= 80 && g <= 1400).length;
    return human >= (gapsMs.length * 2 / 3).ceil();
  }

  String get canonical => jsonEncode({
        'g': gapsMs,
        's': paddedSize,
        'c': channel,
        'r': hasReceipt ? 1 : 0,
        'f': fingerprintPrefix,
        'd': decoyCount,
        't': atMs,
      });

  Map<String, dynamic> toJson() => {
        'g': gapsMs,
        's': paddedSize,
        'c': channel,
        'r': hasReceipt,
        'f': fingerprintPrefix,
        'd': decoyCount,
        't': atMs,
      };

  static TrafficSketch fromJson(Map<String, dynamic> map) {
    final gaps = (map['g'] as List?)?.map((e) => (e as num).toInt()).toList() ??
        const <int>[];
    return TrafficSketch(
      gapsMs: gaps,
      paddedSize: (map['s'] as num?)?.toInt() ?? 2048,
      channel: map['c'] as String? ?? 'local',
      hasReceipt: map['r'] == true || map['r'] == 1,
      fingerprintPrefix: map['f'] as String? ?? '',
      decoyCount: (map['d'] as num?)?.toInt() ?? 0,
      atMs: (map['t'] as num?)?.toInt() ?? 0,
    );
  }
}
