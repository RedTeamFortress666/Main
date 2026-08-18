import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/cards/user_card_codec.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ConnectTab extends ConsumerStatefulWidget {
  const ConnectTab({super.key});

  @override
  ConsumerState<ConnectTab> createState() => _ConnectTabState();
}

class _ConnectTabState extends ConsumerState<ConnectTab> {
  bool _bluetoothEnabled = false;
  String? _fileNumber;

  @override
  void initState() {
    super.initState();
    _loadFileNumber();
  }

  Future<void> _loadFileNumber() async {
    final n = await ref.read(storageServiceProvider).getGameFileNumber();
    if (!mounted) return;
    setState(() => _fileNumber = n);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final engine = ref.watch(cipherEngineProvider);
    final username = auth.user?.username ?? 'UNKNOWN';
    final tier = auth.user?.tier.name ?? 'guest';
    final card = PolybiusUserCard(
      username: username,
      displayName: username,
      tier: tier,
      inviteCode: _fileNumber ?? '',
    );
    final payload = card.encode();

    return ListView(
      padding: const EdgeInsets.all(24),
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
        _InfoRow('Operator', username),
        _InfoRow('Tier', tier.toUpperCase()),
        _InfoRow('Pool ID', engine.poolId),
        _InfoRow('File', _fileNumber ?? '—'),
        _InfoRow('Platform', _platformName),
        _InfoRow('Version', _platformVersion),
        const SizedBox(height: 28),
        const Text(
          'OPERATOR CARD',
          style: TextStyle(
            fontFamily: 'monospace',
            color: NeonTheme.neonCyan,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Identity QR for pairing. No access key is printed on the card.',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),
        ),
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
        const SizedBox(height: 8),
        const Text(
          'Peer-to-peer mesh networking — coming soon',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 32),
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
