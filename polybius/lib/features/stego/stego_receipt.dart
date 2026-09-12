import 'dart:convert';

/// Status a sidecar is allowed to return. Never includes payload.
enum VetStatus { pass, hold, quarantine }

/// What the cabinet may store after a vet.
///
/// The unused-master decoys, the plaintext, and the analyst dossier do
/// not travel with this object. A Hive dump of receipts is a list of
/// opaque verdicts. Minting a PASS requires the authority MAC key,
/// which the cabinet does not hold.
class StegoReceipt {
  const StegoReceipt({
    required this.id,
    required this.status,
    required this.atMs,
    required this.fingerprintPrefix,
    required this.mac,
    this.origin = 'local',
  });

  final String id;
  final VetStatus status;
  final int atMs;

  /// 8 hex chars. Not enough to recover the decoy runes.
  final String fingerprintPrefix;
  final String mac;
  final String origin;

  String get canonical =>
      'v1:VET:${status.name}:$id:$atMs:$fingerprintPrefix:$origin';

  String get readout =>
      '${status.name.toUpperCase()} · ${id.length >= 8 ? id.substring(0, 8) : id}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        'atMs': atMs,
        'fp': fingerprintPrefix,
        'mac': mac,
        'origin': origin,
      };

  static StegoReceipt? tryParse(Object? raw) {
    if (raw is String) {
      try {
        return tryParse(jsonDecode(raw));
      } catch (_) {
        return null;
      }
    }
    if (raw is! Map) return null;
    try {
      final map = Map<String, dynamic>.from(raw);
      final name = map['status'] as String? ?? '';
      final status = VetStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => VetStatus.hold,
      );
      final id = map['id'] as String? ?? '';
      final fp = map['fp'] as String? ?? '';
      final mac = map['mac'] as String? ?? '';
      if (id.isEmpty || mac.isEmpty) return null;
      return StegoReceipt(
        id: id,
        status: status,
        atMs: (map['atMs'] as num?)?.toInt() ?? 0,
        fingerprintPrefix: fp,
        mac: mac,
        origin: map['origin'] as String? ?? 'local',
      );
    } catch (_) {
      return null;
    }
  }
}
