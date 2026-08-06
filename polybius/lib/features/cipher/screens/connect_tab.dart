import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';

class ConnectTab extends ConsumerStatefulWidget {
  const ConnectTab({super.key});

  @override
  ConsumerState<ConnectTab> createState() => _ConnectTabState();
}

class _ConnectTabState extends ConsumerState<ConnectTab> {
  bool _bluetoothEnabled = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final engine = ref.watch(cipherEngineProvider);

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
          _InfoRow('Pool ID', engine.poolId),
          _InfoRow('Platform', _platformName),
          _InfoRow('Version', _platformVersion),
          const SizedBox(height: 32),
          Row(
            children: [
              const Text(
                'BLUETOOTH',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonGreen,
                ),
              ),
              const Spacer(),
              Switch(
                value: _bluetoothEnabled,
                activeThumbColor: NeonTheme.neonCyan,
                onChanged: (v) {
                  setState(() => _bluetoothEnabled = v);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        v ? 'Bluetooth scanning... (placeholder)' : 'Bluetooth off',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/relay'),
              icon: const Icon(Icons.hub, color: NeonTheme.neonPurple),
              style: OutlinedButton.styleFrom(
                foregroundColor: NeonTheme.neonPurple,
                side: const BorderSide(color: NeonTheme.neonPurple),
              ),
              label: const Text('RETICULUM RELAY'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Relay ciphertext over a Reticulum mesh (needs the companion bridge).',
            style: TextStyle(color: Colors.white38, fontSize: 11),
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
