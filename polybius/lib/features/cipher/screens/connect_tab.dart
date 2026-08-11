import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/auth/screens/operator_cards_screen.dart';
import 'package:polybius/features/bluetooth/bluetooth_link_service.dart';

class ConnectTab extends ConsumerStatefulWidget {
  const ConnectTab({super.key});

  @override
  ConsumerState<ConnectTab> createState() => _ConnectTabState();
}

class _ConnectTabState extends ConsumerState<ConnectTab> {
  final _btPayload = TextEditingController();
  String? _selectedPeerId;

  @override
  void dispose() {
    _btPayload.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final engine = ref.watch(cipherEngineProvider);
    final bt = ref.watch(bluetoothLinkProvider);
    final operatorName =
        auth.user?.displayName ?? auth.user?.username ?? 'OPERATOR';

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
          label: const Text('OPERATOR IDENTITY CARDS'),
        ),
        const SizedBox(height: 6),
        const Text(
          'Eye + callsign + invite publicly. DARTH CHERRY reveals secrets.',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Text(
              'BLUETOOTH LINK',
              style: TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.neonGreen,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Switch(
              value: bt.enabled,
              activeThumbColor: NeonTheme.neonCyan,
              onChanged: (v) {
                ref.read(bluetoothLinkProvider.notifier).setEnabled(
                      v,
                      operatorName: operatorName,
                    );
              },
            ),
          ],
        ),
        Text(
          bt.status,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: bt.enabled ? NeonTheme.neonCyan : Colors.white38,
          ),
        ),
        if (bt.enabled) ...[
          const SizedBox(height: 10),
          if (bt.scanning)
            const LinearProgressIndicator(
              color: NeonTheme.neonCyan,
              backgroundColor: Colors.white12,
            ),
          ...bt.peers.map((p) {
            final selected = _selectedPeerId == p.id;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                p.connected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: p.connected ? NeonTheme.neonGreen : NeonTheme.neonCyan,
              ),
              title: Text(
                p.name,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              subtitle: Text(
                p.rssi != null ? '${p.rssi} dBm' : p.id,
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: NeonTheme.neonPink)
                  : TextButton(
                      onPressed: () async {
                        await ref
                            .read(bluetoothLinkProvider.notifier)
                            .connect(p);
                        setState(() => _selectedPeerId = p.id);
                      },
                      child: Text(p.connected ? 'SELECT' : 'LINK'),
                    ),
              onTap: () => setState(() => _selectedPeerId = p.id),
            );
          }),
          if (bt.peers.isEmpty && !bt.scanning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No POLYBIUS-* peers yet. Enable Bluetooth on both devices.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          if (_selectedPeerId != null) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _btPayload,
              maxLines: 2,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Emoji ciphertext to peer',
                labelStyle: TextStyle(color: NeonTheme.neonPink, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(bluetoothLinkProvider.notifier).sendCiphertext(
                      _selectedPeerId!,
                      _btPayload.text,
                    );
                _btPayload.clear();
              },
              icon: const Icon(Icons.send),
              label: const Text('SEND OVER BLUETOOTH'),
            ),
          ],
          if (bt.messages.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'BT TRAFFIC',
              style: TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.neonYellow,
                fontSize: 11,
              ),
            ),
            ...bt.messages.take(6).map(
                  (m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${m.outbound ? '→' : '←'} ${m.fromName}: ${m.payload}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: m.outbound
                            ? NeonTheme.neonPink
                            : NeonTheme.neonGreen,
                      ),
                    ),
                  ),
                ),
          ],
          TextButton(
            onPressed: () =>
                ref.read(bluetoothLinkProvider.notifier).startScan(),
            child: const Text('RESCAN'),
          ),
        ],
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
