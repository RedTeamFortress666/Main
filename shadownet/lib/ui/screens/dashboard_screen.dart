import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/connect_point.dart';
import '../../core/theme/shadow_theme.dart';
import '../../providers/mesh_providers.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesh = ref.watch(meshControllerProvider);
    if (mesh.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final downloaded = mesh.models.where((m) => m.isDownloaded).length;
    final inRange = mesh.models.where((m) => m.inTargetRange).length;
    final connected = mesh.points
        .where((p) => p.state == ConnectState.connected).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'DEVELOPER MESH',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Android field console · Abliterated 2–6 GB local models · QShield hybrid transport',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatCard(
              label: 'CONNECT POINTS',
              value: '${mesh.points.length}',
              sub: '$connected live',
              color: ShadowTheme.neonCyan,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'MODELS ON DEVICE',
              value: '$downloaded',
              sub: '$inRange in 2–6 GB band',
              color: ShadowTheme.neonGreen,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'QSHIELD SESSION',
          value: mesh.qshield.isReady ? 'ARMED' : 'IDLE',
          sub: mesh.qshield.hybridProfile,
          color: mesh.qshield.isReady
              ? ShadowTheme.qshieldBlue
              : ShadowTheme.neonAmber,
          wide: true,
        ),
        const SizedBox(height: 24),
        Text('ACTIVE CONNECT POINTS', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (mesh.points.isEmpty)
          const Text('No connect points configured. Open CONNECT tab.')
        else
          ...mesh.points.take(3).map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(p.label, style: const TextStyle(color: ShadowTheme.neonGreen)),
                    subtitle: Text(
                      '${p.kind.name} · ${p.effectiveUrl}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: StatusBadge(
                      label: p.state.name.toUpperCase(),
                      color: p.state == ConnectState.connected
                          ? ShadowTheme.neonGreen
                          : ShadowTheme.neonAmber,
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 16),
        Text('DOWNLOADED ABLITERATED', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        ...mesh.models.where((m) => m.isDownloaded).map(
              (m) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.model_training, color: ShadowTheme.neonPurple),
                  title: Text(m.displayName),
                  subtitle: Text('${m.quant} · ${m.sizeLabel}'),
                ),
              ),
            ),
        if (mesh.models.every((m) => !m.isDownloaded))
          const Text(
            'No GGUF models bound yet. Scan a folder in MODELS tab.',
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    this.wide = false,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: wide ? 1 : 1,
      child: Container(
        width: wide ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ShadowTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 2,
              ),
            ),
            Text(sub, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
