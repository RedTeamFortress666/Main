import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/abliterated_model.dart';
import '../core/models/connect_point.dart';
import '../core/models/qshield_session.dart';
import '../shadownet/inference_bridge.dart';
import '../shadownet/mesh_registry.dart';
import '../qshield/qshield_core.dart';

final meshRegistryProvider = Provider<MeshRegistry>((ref) => MeshRegistry.instance);

final qshieldCoreProvider = Provider<QShieldCore>((ref) => QShieldCore());

final inferenceBridgeProvider = Provider<InferenceBridge>((ref) {
  return InferenceBridge(qshield: ref.watch(qshieldCoreProvider));
});

class MeshState {
  MeshState({
    this.points = const [],
    this.models = const [],
    this.qshield = const QShieldSessionInfo(),
    this.loading = true,
  });

  final List<ConnectPoint> points;
  final List<AbliteratedModel> models;
  final QShieldSessionInfo qshield;
  final bool loading;

  MeshState copyWith({
    List<ConnectPoint>? points,
    List<AbliteratedModel>? models,
    QShieldSessionInfo? qshield,
    bool? loading,
  }) {
    return MeshState(
      points: points ?? this.points,
      models: models ?? this.models,
      qshield: qshield ?? this.qshield,
      loading: loading ?? this.loading,
    );
  }
}

class MeshController extends StateNotifier<MeshState> {
  MeshController(this._registry, this._qshield) : super(MeshState()) {
    _init();
  }

  final MeshRegistry _registry;
  final QShieldCore _qshield;

  Future<void> _init() async {
    await _registry.load();
    state = MeshState(
      points: _registry.connectPoints,
      models: _registry.models,
      qshield: _qshield.sessionInfo,
      loading: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(
      points: _registry.connectPoints,
      models: _registry.models,
      qshield: _qshield.sessionInfo,
    );
  }

  Future<void> handshake() async {
    final info = await _qshield.establishSession();
    state = state.copyWith(qshield: info);
  }

  void resetQShield() {
    _qshield.reset();
    state = state.copyWith(qshield: _qshield.sessionInfo);
  }

  Future<void> addPoint(ConnectPoint point) async {
    await _registry.addConnectPoint(point);
    await refresh();
  }

  Future<void> updatePoint(ConnectPoint point) async {
    await _registry.updateConnectPoint(point);
    await refresh();
  }

  Future<void> removePoint(String id) async {
    await _registry.removeConnectPoint(id);
    await refresh();
  }

  Future<void> bindModel(String modelId, String path, int bytes) async {
    await _registry.bindModelPath(modelId, path, bytes);
    await refresh();
  }

  Future<void> scanModelsDir(String path) async {
    await _registry.scanDirectory(path);
    await refresh();
  }
}

final meshControllerProvider =
    StateNotifierProvider<MeshController, MeshState>((ref) {
  return MeshController(
    ref.watch(meshRegistryProvider),
    ref.watch(qshieldCoreProvider),
  );
});
