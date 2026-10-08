import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/glasses/glasses_link.dart';

class ConnectTab extends ConsumerStatefulWidget {
  const ConnectTab({super.key});

  @override
  ConsumerState<ConnectTab> createState() => _ConnectTabState();
}

class _ConnectTabState extends ConsumerState<ConnectTab> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final nameplate = ref.watch(displayPoolIdProvider);
    final hub = ref.watch(transportHubProvider);
    final policy = ref.watch(cabinetPolicyProvider);
    final surface = ref.watch(leakSurfaceProvider);
    final viewer = ref.watch(glassesViewerProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEVICE INFO',
            style: TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonCyan,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow('Operator', auth.user?.username ?? 'UNKNOWN'),
          _InfoRow('Tier', auth.user?.tier.name.toUpperCase() ?? 'N/A'),
          _InfoRow('Pool ID', nameplate),
          _InfoRow('Platform', _platformName),
          _InfoRow('Version', _platformVersion),
          const SizedBox(height: 24),
          const Text(
            'COURIER MESH',
            style: TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonGreen,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: hub.snapshot(),
            builder: (context, snap) {
              final rows = snap.data;
              if (rows == null) {
                return const Text(
                  'PROBING CABINET…',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                );
              }
              return Column(
                children: [
                  _InfoRow('QR', rows[0].detail),
                  _InfoRow('RNS', rows[1].detail),
                  _InfoRow('MATRIX', rows[2].detail),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Reticulum sidecar default 127.0.0.1:3742 — QR remains the air-gap. '
            'Stego vet default 127.0.0.1:3743 (Tailscale/Proxmox). '
            'Matrix is optional and leaks room metadata. Frames are padded to 2048 bytes.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 20),
          const Text(
            'CABINET MESH',
            style: TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonPink,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            'ML-KEM-768',
            surface.hybridPqLive && policy.hybridPq
                ? 'LIVE · X25519 + KYBER'
                : 'SLOT EMPTY',
          ),
          _InfoRow(
            'STEGO VET',
            surface.stegoVetBound
                ? 'BOUND · RECEIPTS ONLY'
                : 'UNBOUND',
          ),
          _InfoRow(
            'ROUND TABLE',
            surface.roundTableArmed
                ? 'ARMED · CADENCE ONLY · NO H2H INTERFERENCE'
                : 'DARK',
          ),
          _InfoRow(
            'GLASSES',
            surface.glassesPaired
                ? (viewer == GlassesViewer.hud
                    ? 'HUD PAIR · THIS FACE IS THE GLASSES'
                    : 'PAIRED · ATTRACT MODE ON THIS FACE')
                : 'UNPAIRED',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(glassesViewerProvider.notifier)
                      .state = GlassesViewer.hud,
                  child: const Text('I AM THE HUD', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(glassesViewerProvider.notifier)
                      .state = GlassesViewer.public,
                  child: const Text('ATTRACT MODE', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                ref.read(unlockProvider.notifier).reset();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: NeonTheme.dangerRed,
                side: const BorderSide(color: NeonTheme.dangerRed),
              ),
              child: const Text('EXIT / LOGOUT'),
            ),
          ),
        ],
      ),
    );
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  String get _platformVersion => '1.0.0';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.neonGreen,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
