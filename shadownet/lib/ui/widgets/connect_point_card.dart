import 'package:flutter/material.dart';

import '../../core/models/abliterated_model.dart';
import '../../core/models/connect_point.dart';
import '../../core/theme/shadow_theme.dart';
import 'status_badge.dart';

class ConnectPointCard extends StatelessWidget {
  const ConnectPointCard({
    super.key,
    required this.point,
    required this.onEdit,
    required this.onDelete,
    required this.onProbe,
    required this.onLinkModel,
    required this.availableModels,
    this.linkedModel,
  });

  final ConnectPoint point;
  final AbliteratedModel? linkedModel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onProbe;
  final void Function(String modelId) onLinkModel;
  final List<AbliteratedModel> availableModels;

  Color _stateColor() {
    switch (point.state) {
      case ConnectState.connected:
        return ShadowTheme.neonGreen;
      case ConnectState.handshaking:
        return ShadowTheme.neonAmber;
      case ConnectState.error:
        return ShadowTheme.dangerRed;
      case ConnectState.idle:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    point.label,
                    style: const TextStyle(
                      color: ShadowTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                StatusBadge(
                  label: point.state.name.toUpperCase(),
                  color: _stateColor(),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${point.kind.name} · ${point.effectiveUrl}'),
            if (point.modelPath.isNotEmpty)
              Text('Server model: ${point.modelPath}'),
            if (linkedModel != null)
              Text(
                'Linked: ${linkedModel!.displayName}',
                style: const TextStyle(color: ShadowTheme.neonGreen),
              ),
            if (point.lastError != null)
              Text(
                point.lastError!,
                style: const TextStyle(color: ShadowTheme.dangerRed, fontSize: 12),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onProbe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShadowTheme.neonPurple,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('PROBE'),
                ),
                const SizedBox(width: 8),
                if (availableModels.isNotEmpty)
                  PopupMenuButton<String>(
                    child: const Text('LINK MODEL'),
                    itemBuilder: (ctx) => availableModels
                        .map(
                          (m) => PopupMenuItem(
                            value: m.id,
                            child: Text(m.displayName),
                          ),
                        )
                        .toList(),
                    onSelected: onLinkModel,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
