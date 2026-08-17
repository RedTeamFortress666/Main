import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/qshield_session.dart';
import '../../core/theme/shadow_theme.dart';
import '../../providers/mesh_providers.dart';

class QShieldPanelScreen extends ConsumerWidget {
  const QShieldPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesh = ref.watch(meshControllerProvider);
    final controller = ref.read(meshControllerProvider.notifier);
    final info = mesh.qshield;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('QSHIELD CORE', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Hybrid X25519 + Kyber512 session · AES-GCM payload sealing',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _PhaseRow(phase: info.phase),
        const SizedBox(height: 16),
        _InfoTile(label: 'HYBRID PROFILE', value: info.hybridProfile),
        _InfoTile(label: 'SESSION ID', value: info.sessionId.isEmpty ? '—' : info.sessionId),
        _InfoTile(
          label: 'CLASSICAL FP',
          value: info.classicalFingerprint.isEmpty ? '—' : info.classicalFingerprint,
        ),
        _InfoTile(
          label: 'PQC KEY ID',
          value: info.pqcKeyId.isEmpty ? '—' : info.pqcKeyId,
        ),
        if (info.createdAt != null)
          _InfoTile(
            label: 'ESTABLISHED',
            value: info.createdAt!.toIso8601String(),
          ),
        if (info.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              info.error!,
              style: const TextStyle(color: ShadowTheme.dangerRed),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.handshake(),
                icon: const Icon(Icons.key),
                label: const Text('ESTABLISH SESSION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShadowTheme.qshieldBlue,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                controller.resetQShield();
              },
              child: const Text('RESET'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('TRANSPORT LAYER', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        const _InfoTile(
          label: 'SEALING',
          value: 'AES-256-GCM with hybrid derived secret',
        ),
        const _InfoTile(
          label: 'KEM FRAME',
          value: 'Kyber512 key_id via SHAKE256 envelope (Phant0m-compatible)',
        ),
        const _InfoTile(
          label: 'HEADERS',
          value: 'X-QShield-Session · qshield_sealed JSON body',
        ),
      ],
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.phase});

  final QShieldHandshakePhase phase;

  @override
  Widget build(BuildContext context) {
    final steps = QShieldHandshakePhase.values
        .where((p) => p != QShieldHandshakePhase.error)
        .toList();
    return Row(
      children: steps.map((s) {
        final active = s.index <= phase.index && phase != QShieldHandshakePhase.error;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active ? ShadowTheme.qshieldBlue : ShadowTheme.surface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  color: active ? ShadowTheme.neonGreen : Colors.white38,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ShadowTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ShadowTheme.qshieldBlue.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
