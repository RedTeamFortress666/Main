enum ConnectPointKind {
  llamaCpp,
  koboldCpp,
  mlcLlm,
  ollama,
  customHttp,
}

enum ConnectState {
  idle,
  handshaking,
  connected,
  error,
}

class ConnectPoint {
  const ConnectPoint({
    required this.id,
    required this.label,
    required this.kind,
    required this.baseUrl,
    required this.modelPath,
    this.apiKey = '',
    this.port = 8080,
    this.enabled = true,
    this.state = ConnectState.idle,
    this.lastError,
    this.linkedModelId,
  });

  final String id;
  final String label;
  final ConnectPointKind kind;
  final String baseUrl;
  final String modelPath;
  final String apiKey;
  final int port;
  final bool enabled;
  final ConnectState state;
  final String? lastError;
  final String? linkedModelId;

  String get effectiveUrl {
    if (baseUrl.isNotEmpty) return baseUrl;
    return 'http://127.0.0.1:$port';
  }

  String get chatCompletionsUrl {
    final base = effectiveUrl.replaceAll(RegExp(r'/$'), '');
    if (base.endsWith('/v1')) return '$base/chat/completions';
    if (base.endsWith('/v1/chat/completions')) return base;
    return '$base/v1/chat/completions';
  }

  ConnectPoint copyWith({
    String? label,
    ConnectPointKind? kind,
    String? baseUrl,
    String? modelPath,
    String? apiKey,
    int? port,
    bool? enabled,
    ConnectState? state,
    String? lastError,
    String? linkedModelId,
    bool clearError = false,
  }) {
    return ConnectPoint(
      id: id,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      baseUrl: baseUrl ?? this.baseUrl,
      modelPath: modelPath ?? this.modelPath,
      apiKey: apiKey ?? this.apiKey,
      port: port ?? this.port,
      enabled: enabled ?? this.enabled,
      state: state ?? this.state,
      lastError: clearError ? null : (lastError ?? this.lastError),
      linkedModelId: linkedModelId ?? this.linkedModelId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'kind': kind.name,
        'baseUrl': baseUrl,
        'modelPath': modelPath,
        'apiKey': apiKey,
        'port': port,
        'enabled': enabled,
        'linkedModelId': linkedModelId,
      };

  factory ConnectPoint.fromJson(Map<String, dynamic> json) {
    return ConnectPoint(
      id: json['id'] as String,
      label: json['label'] as String,
      kind: ConnectPointKind.values.byName(json['kind'] as String),
      baseUrl: json['baseUrl'] as String? ?? '',
      modelPath: json['modelPath'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      port: json['port'] as int? ?? 8080,
      enabled: json['enabled'] as bool? ?? true,
      linkedModelId: json['linkedModelId'] as String?,
    );
  }
}
