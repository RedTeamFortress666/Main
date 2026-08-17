import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/abliterated_model.dart';
import '../core/models/connect_point.dart';

/// Registry for mesh connect points and local model bindings.
class MeshRegistry {
  MeshRegistry._();
  static final MeshRegistry instance = MeshRegistry._();

  static const _pointsKey = 'shadownet_connect_points';
  static const _modelsKey = 'shadownet_models';

  List<ConnectPoint> _points = [];
  List<AbliteratedModel> _models = List.from(abliteratedCatalog);
  bool _loaded = false;

  List<ConnectPoint> get connectPoints => List.unmodifiable(_points);
  List<AbliteratedModel> get models => List.unmodifiable(_models);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final pointsRaw = prefs.getString(_pointsKey);
    if (pointsRaw != null) {
      final list = jsonDecode(pointsRaw) as List<dynamic>;
      _points = list
          .map((e) => ConnectPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _points = _defaultConnectPoints();
    }

    final modelsRaw = prefs.getString(_modelsKey);
    if (modelsRaw != null) {
      final map = jsonDecode(modelsRaw) as Map<String, dynamic>;
      _models = abliteratedCatalog.map((catalog) {
        final saved = map[catalog.id];
        if (saved == null) return catalog;
        return AbliteratedModel.fromJson(
          saved as Map<String, dynamic>,
          catalog,
        );
      }).toList();
    }
    _loaded = true;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pointsKey,
      jsonEncode(_points.map((p) => p.toJson()).toList()),
    );
    final modelMap = <String, dynamic>{};
    for (final m in _models) {
      modelMap[m.id] = m.toJson();
    }
    await prefs.setString(_modelsKey, jsonEncode(modelMap));
  }

  Future<void> addConnectPoint(ConnectPoint point) async {
    _points = [..._points, point];
    await save();
  }

  Future<void> updateConnectPoint(ConnectPoint point) async {
    _points = _points.map((p) => p.id == point.id ? point : p).toList();
    await save();
  }

  Future<void> removeConnectPoint(String id) async {
    _points = _points.where((p) => p.id != id).toList();
    await save();
  }

  Future<void> bindModelPath(String modelId, String path, int bytes) async {
    _models = _models.map((m) {
      if (m.id != modelId) return m;
      return m.copyWith(
        localPath: path,
        isDownloaded: true,
        actualBytes: bytes,
      );
    }).toList();
    await save();
  }

  Future<void> scanDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final name = entity.path.toLowerCase();
      if (!name.endsWith('.gguf')) continue;
      final bytes = entity.lengthSync();
      final gb = bytes / (1024 * 1024 * 1024);
      if (gb < 1.5 || gb > 7.0) continue;

      final matched = _matchCatalog(entity.path, gb);
      if (matched != null) {
        await bindModelPath(matched.id, entity.path, bytes);
      }
    }
  }

  AbliteratedModel? _matchCatalog(String path, double gb) {
    final lower = path.toLowerCase();
    for (final m in _models) {
      if (lower.contains(m.id.replaceAll('-', '')) ||
          lower.contains(m.family.toLowerCase().replaceAll(' ', ''))) {
        return m;
      }
    }
    // Fuzzy: pick closest size in catalog
    AbliteratedModel? best;
    double bestDelta = 999;
    for (final m in _models) {
      final delta = (m.sizeGb - gb).abs();
      if (delta < bestDelta && delta < 1.5) {
        bestDelta = delta;
        best = m;
      }
    }
    return best;
  }

  List<ConnectPoint> _defaultConnectPoints() {
    return [
      ConnectPoint(
        id: 'cp-llama-default',
        label: 'Llama.cpp Server',
        kind: ConnectPointKind.llamaCpp,
        baseUrl: 'http://127.0.0.1:8080',
        modelPath: '',
        port: 8080,
      ),
      ConnectPoint(
        id: 'cp-kobold-default',
        label: 'KoboldCpp Bridge',
        kind: ConnectPointKind.koboldCpp,
        baseUrl: 'http://127.0.0.1:5001',
        modelPath: '',
        port: 5001,
      ),
      ConnectPoint(
        id: 'cp-mlc-default',
        label: 'MLC LLM Local',
        kind: ConnectPointKind.mlcLlm,
        baseUrl: 'http://127.0.0.1:8000',
        modelPath: '',
        port: 8000,
      ),
    ];
  }
}
