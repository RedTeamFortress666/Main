/// Cover identity stored encrypted at rest.
///
/// A dump of this record reveals that a cover PIN *exists*. That is a
/// local-forensic leak, not a UI leak. Coercion resistance is about the
/// arcade looking identical — not about hiding the feature from someone
/// who already has the Hive box and the device key.
class CabinetIdentity {
  const CabinetIdentity({
    required this.duressPinHash,
    required this.coverInitials,
    required this.coverPlaintext,
    required this.coverSalt,
  });

  final String duressPinHash;
  final String coverInitials;
  final String coverPlaintext;
  final String coverSalt;

  Map<String, dynamic> toJson() => {
        'duressPinHash': duressPinHash,
        'coverInitials': coverInitials,
        'coverPlaintext': coverPlaintext,
        'coverSalt': coverSalt,
      };

  factory CabinetIdentity.fromJson(Map<dynamic, dynamic> json) =>
      CabinetIdentity(
        duressPinHash: json['duressPinHash'] as String,
        coverInitials: (json['coverInitials'] as String? ?? 'CLX').toUpperCase(),
        coverPlaintext: json['coverPlaintext'] as String? ?? '',
        coverSalt: json['coverSalt'] as String,
      );
}
