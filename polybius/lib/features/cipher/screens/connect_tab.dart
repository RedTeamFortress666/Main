import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/core/constants/operator_identities.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/auth/screens/operator_cards_screen.dart';
import 'package:polybius/features/bluetooth/bluetooth_link_service.dart';
import 'package:polybius/features/bluetooth/bluetooth_messaging_panel.dart';

class ConnectTab extends ConsumerWidget {
  const ConnectTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final engine = ref.watch(cipherEngineProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'DEVICE INFO',
          style: TextStyle(
            fontFamily: 'monospace',
            color: NeonTheme.neonCyan,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _InfoRow('Operator', auth.user?.username ?? 'UNKNOWN'),
        _InfoRow('Tier', auth.user?.tier.name.toUpperCase() ?? 'N/A'),
        _InfoRow('Build', AppFlavor.displayName),
        _InfoRow('Pool ID', engine.poolId),
        _InfoRow('Platform', _platformName),
        _InfoRow('Version', '1.0.0-STABLE'),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OperatorCardsScreen()),
            );
          },
          icon: const Icon(Icons.badge_outlined, color: NeonTheme.neonGreen),
          style: OutlinedButton.styleFrom(
            foregroundColor: NeonTheme.neonGreen,
            side: const BorderSide(color: NeonTheme.neonGreen),
          ),
          label: Text(
            OperatorIdentities.canViewFullRoster(auth.user?.username)
                ? 'OPERATOR ROSTER (DEV)'
                : 'MY OPERATOR IDENTITY CARD',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          OperatorIdentities.canViewFullRoster(auth.user?.username)
              ? 'Full roster: SpamKat2 / RedTeam01 / Gam3.0n. DARTH CHERRY reveals secrets.'
              : 'Your card only. DARTH CHERRY reveals your secrets.',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 28),
        const BluetoothMessagingPanel(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/relay'),
            icon: const Icon(Icons.hub, color: NeonTheme.neonPurple),
            style: OutlinedButton.styleFrom(
              foregroundColor: NeonTheme.neonPurple,
              side: const BorderSide(color: NeonTheme.neonPurple),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            label: const Text('RETICULUM RELAY'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mesh transport via companion bridge — scroll the relay for connection then messaging.',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              await ref.read(bluetoothLinkProvider.notifier).setEnabled(false);
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
    );
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
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
