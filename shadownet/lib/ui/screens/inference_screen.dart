import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/abliterated_model.dart';
import '../../core/models/connect_point.dart';
import '../../core/theme/shadow_theme.dart';
import '../../providers/mesh_providers.dart';

class InferenceScreen extends ConsumerStatefulWidget {
  const InferenceScreen({super.key});

  @override
  ConsumerState<InferenceScreen> createState() => _InferenceScreenState();
}

class _InferenceScreenState extends ConsumerState<InferenceScreen> {
  final _promptCtrl = TextEditingController(
    text: 'Summarize Shadøwnet mesh capabilities in one sentence.',
  );
  String? _response;
  String? _error;
  bool _loading = false;
  bool _useQShield = true;
  ConnectPoint? _selected;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mesh = ref.watch(meshControllerProvider);
    final points = mesh.points;
    _selected ??= points.isNotEmpty ? points.first : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('INFERENCE BRIDGE', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Send prompts through QShield-sealed connect points to on-device models',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (points.isEmpty)
          const Text('Add a connect point first.')
        else
          DropdownButtonFormField<ConnectPoint>(
            value: _selected,
            dropdownColor: ShadowTheme.surface,
            items: points
                .map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                )
                .toList(),
            onChanged: (p) => setState(() => _selected = p),
            decoration: const InputDecoration(labelText: 'Connect point'),
          ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Seal with QShield'),
          subtitle: const Text('Hybrid encrypt payload before inference call'),
          value: _useQShield,
          activeColor: ShadowTheme.qshieldBlue,
          onChanged: (v) => setState(() => _useQShield = v),
        ),
        TextField(
          controller: _promptCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Prompt',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _loading || _selected == null ? null : _run,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('INVOKE MODEL'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ShadowTheme.neonGreen,
            foregroundColor: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: ShadowTheme.dangerRed)),
        if (_response != null) ...[
          Text('RESPONSE', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ShadowTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ShadowTheme.neonGreen.withValues(alpha: 0.3)),
            ),
            child: Text(_response!),
          ),
        ],
      ],
    );
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _response = null;
    });

    final bridge = ref.read(inferenceBridgeProvider);
    final mesh = ref.read(meshControllerProvider);
    final point = _selected!;
    final linked = _findModel(mesh.models, point.linkedModelId);

    final result = await bridge.complete(
      point: point,
      prompt: _promptCtrl.text,
      sealWithQShield: _useQShield,
      modelName: linked?.localPath.isNotEmpty == true
          ? linked!.localPath
          : linked?.displayName,
    );

    setState(() {
      _loading = false;
      if (result.success) {
        _response = result.text;
        if (result.latencyMs != null) {
          _response = '${result.text}\n\n[${result.latencyMs}ms · QShield: ${result.usedQShield}]';
        }
      } else {
        _error = result.error;
      }
    });
  }
}

AbliteratedModel? _findModel(List<AbliteratedModel> models, String? id) {
  if (id == null) return null;
  for (final m in models) {
    if (m.id == id) return m;
  }
  return null;
}
