/// Local GGUF / on-device model descriptor for Abliterated uncensored weights.
class AbliteratedModel {
  const AbliteratedModel({
    required this.id,
    required this.displayName,
    required this.family,
    required this.sizeGb,
    required this.quant,
    this.localPath = '',
    this.isDownloaded = false,
    this.actualBytes = 0,
    this.tags = const [],
  });

  final String id;
  final String displayName;
  final String family;
  final double sizeGb;
  final String quant;
  final String localPath;
  final bool isDownloaded;
  final int actualBytes;
  final List<String> tags;

  bool get inTargetRange => sizeGb >= 2.0 && sizeGb <= 6.0;

  String get sizeLabel {
    if (actualBytes > 0) {
      final gb = actualBytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB on disk';
    }
    return '~${sizeGb.toStringAsFixed(1)} GB';
  }

  AbliteratedModel copyWith({
    String? localPath,
    bool? isDownloaded,
    int? actualBytes,
  }) {
    return AbliteratedModel(
      id: id,
      displayName: displayName,
      family: family,
      sizeGb: sizeGb,
      quant: quant,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      actualBytes: actualBytes ?? this.actualBytes,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'localPath': localPath,
        'isDownloaded': isDownloaded,
        'actualBytes': actualBytes,
      };

  factory AbliteratedModel.fromJson(
    Map<String, dynamic> json,
    AbliteratedModel catalog,
  ) {
    return catalog.copyWith(
      localPath: json['localPath'] as String? ?? '',
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      actualBytes: json['actualBytes'] as int? ?? 0,
    );
  }
}

/// Curated Abliterated / uncensored presets in the 2–6 GB phone-friendly band.
const abliteratedCatalog = <AbliteratedModel>[
  AbliteratedModel(
    id: 'dolphin-llama3-8b-q4',
    displayName: 'Dolphin 2.9 Llama 3 8B',
    family: 'Llama 3',
    sizeGb: 4.7,
    quant: 'Q4_K_M',
    tags: ['abliterated', 'uncensored', 'chat'],
  ),
  AbliteratedModel(
    id: 'llama32-3b-abliterated-q4',
    displayName: 'Llama 3.2 3B Abliterated',
    family: 'Llama 3.2',
    sizeGb: 2.0,
    quant: 'Q4_K_M',
    tags: ['abliterated', 'uncensored', 'fast'],
  ),
  AbliteratedModel(
    id: 'hermes3-8b-abliterated-q4',
    displayName: 'Hermes 3 8B Abliterated',
    family: 'Hermes',
    sizeGb: 4.9,
    quant: 'Q4_K_M',
    tags: ['abliterated', 'uncensored', 'tools'],
  ),
  AbliteratedModel(
    id: 'mistral-7b-abliterated-q4',
    displayName: 'Mistral 7B Abliterated',
    family: 'Mistral',
    sizeGb: 4.1,
    quant: 'Q4_K_M',
    tags: ['abliterated', 'uncensored'],
  ),
  AbliteratedModel(
    id: 'qwen25-7b-abliterated-q4',
    displayName: 'Qwen 2.5 7B Abliterated',
    family: 'Qwen',
    sizeGb: 4.4,
    quant: 'Q4_K_M',
    tags: ['abliterated', 'uncensored', 'multilingual'],
  ),
  AbliteratedModel(
    id: 'phi3-mini-abliterated-q4',
    displayName: 'Phi-3 Mini Abliterated',
    family: 'Phi-3',
    sizeGb: 2.3,
    quant: 'Q4_K_M',
    tags: ['abliterated', 'uncensored', 'compact'],
  ),
];
