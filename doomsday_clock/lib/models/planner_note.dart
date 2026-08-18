class PlannerNote {
  PlannerNote({
    required this.id,
    required this.dayKey,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final String dayKey;
  final String body;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayKey': dayKey,
        'body': body,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PlannerNote.fromJson(Map<String, dynamic> json) => PlannerNote(
        id: json['id'] as String,
        dayKey: json['dayKey'] as String,
        body: json['body'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
