import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/abliterated_model.dart';
import '../../core/models/connect_point.dart';
import '../../core/theme/shadow_theme.dart';
import '../../providers/mesh_providers.dart';
import '../../shadownet/inference_bridge.dart';
import '../widgets/connect_point_card.dart';

class ConnectPointsScreen extends ConsumerStatefulWidget {
  const ConnectPointsScreen({super.key});

  @override
  ConsumerState<ConnectPointsScreen> createState() =>
      _ConnectPointsScreenState();
}

class _ConnectPointsScreenState extends ConsumerState<ConnectPointsScreen> {
  @override
  Widget build(BuildContext context) {
    final mesh = ref.watch(meshControllerProvider);
    final controller = ref.read(meshControllerProvider.notifier);
    final bridge = ref.watch(inferenceBridgeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'CONNECT POINTS',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              onPressed: () => _showAddDialog(context, controller),
              icon: const Icon(Icons.add_link, color: ShadowTheme.neonCyan),
              tooltip: 'Add connect point',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Plug local inference backends: llama.cpp · KoboldCpp · MLC · Ollama',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...mesh.points.map(
          (p) => ConnectPointCard(
            point: p,
            linkedModel: _findModel(mesh.models, p.linkedModelId),
            onEdit: () => _showEditDialog(context, controller, p),
            onDelete: () => controller.removePoint(p.id),
            onProbe: () => _probe(context, bridge, controller, p),
            onLinkModel: (modelId) {
              controller.updatePoint(p.copyWith(linkedModelId: modelId));
            },
            availableModels: mesh.models.where((m) => m.isDownloaded).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _probe(
    BuildContext context,
    InferenceBridge bridge,
    MeshController controller,
    ConnectPoint point,
  ) async {
    await controller.updatePoint(
      point.copyWith(state: ConnectState.handshaking, clearError: true),
    );
    final ok = await bridge.probeEndpoint(point);
    await controller.updatePoint(
      point.copyWith(
        state: ok ? ConnectState.connected : ConnectState.error,
        lastError: ok ? null : 'Endpoint unreachable',
        clearError: ok,
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Connected to ${point.label}' : 'Probe failed'),
        ),
      );
    }
  }

  void _showAddDialog(BuildContext context, MeshController controller) {
  _showPointDialog(context, controller, null);
  }

  void _showEditDialog(
    BuildContext context,
    MeshController controller,
    ConnectPoint point,
  ) {
    _showPointDialog(context, controller, point);
  }

  void _showPointDialog(
    BuildContext context,
    MeshController controller,
    ConnectPoint? existing,
  ) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final urlCtrl = TextEditingController(text: existing?.baseUrl ?? '');
    final pathCtrl = TextEditingController(text: existing?.modelPath ?? '');
    final portCtrl = TextEditingController(
      text: existing?.port.toString() ?? '8080',
    );
    var kind = existing?.kind ?? ConnectPointKind.llamaCpp;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShadowTheme.surfaceHigh,
        title: Text(
          existing == null ? 'NEW CONNECT POINT' : 'EDIT CONNECT POINT',
          style: const TextStyle(color: ShadowTheme.neonCyan),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              DropdownButtonFormField<ConnectPointKind>(
                value: kind,
                dropdownColor: ShadowTheme.surface,
                items: ConnectPointKind.values
                    .map(
                      (k) => DropdownMenuItem(value: k, child: Text(k.name)),
                    )
                    .toList(),
                onChanged: (v) => kind = v ?? kind,
                decoration: const InputDecoration(labelText: 'Backend kind'),
              ),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL (optional)',
                  hintText: 'http://127.0.0.1:8080',
                ),
              ),
              TextField(
                controller: portCtrl,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: pathCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model path / name on server',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final point = ConnectPoint(
                id: existing?.id ?? const Uuid().v4(),
                label: labelCtrl.text.trim().isEmpty
                    ? 'Connect Point'
                    : labelCtrl.text.trim(),
                kind: kind,
                baseUrl: urlCtrl.text.trim(),
                modelPath: pathCtrl.text.trim(),
                port: int.tryParse(portCtrl.text) ?? 8080,
                linkedModelId: existing?.linkedModelId,
              );
              if (existing == null) {
                await controller.addPoint(point);
              } else {
                await controller.updatePoint(point);
              }
              Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

AbliteratedModel? _findModel(List<AbliteratedModel> models, String? id) {
  if (id == null) return null;
  for (final m in models) {
    if (m.id == id) return m;
  }
  return null;
}
