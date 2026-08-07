import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/reticulum/reticulum_client.dart';

/// Relays emoji ciphertext over a Reticulum mesh via the companion bridge.
/// Requires `polybius/bridge/polybius_bridge.py` to be running.
class ReticulumRelayScreen extends ConsumerStatefulWidget {
  const ReticulumRelayScreen({super.key});

  @override
  ConsumerState<ReticulumRelayScreen> createState() =>
      _ReticulumRelayScreenState();
}

class _ReticulumRelayScreenState extends ConsumerState<ReticulumRelayScreen> {
  final _peerController = TextEditingController();
  final _payloadController = TextEditingController();
  final _urlController = TextEditingController();
  final List<ReticulumMessage> _received = [];
  final List<StreamSubscription> _subs = [];

  bool _connecting = true;
  bool _connected = false;
  String? _address;
  String? _status;

  @override
  void initState() {
    super.initState();
    _urlController.text = ref.read(storageServiceProvider).getReticulumUrl();
    final client = ref.read(reticulumClientProvider);
    _subs.add(client.address.listen((a) {
      if (mounted) setState(() => _address = a);
    }));
    _subs.add(client.incoming.listen((m) {
      if (mounted) setState(() => _received.insert(0, m));
    }));
    _subs.add(client.errors.listen((e) {
      if (mounted) setState(() => _status = e);
    }));
    _open();
  }

  Future<void> _open() async {
    final client = ref.read(reticulumClientProvider);
    final url = _urlController.text.trim();
    setState(() => _connecting = true);
    // Persist the chosen bridge URL so it sticks across launches.
    await ref.read(storageServiceProvider).setReticulumUrl(url);
    final ok = await client.connect(url: url);
    if (!mounted) return;
    setState(() {
      _connecting = false;
      _connected = ok;
      _address = client.localAddress;
      _status = ok ? null : 'BRIDGE OFFLINE — start polybius_bridge.py';
    });
  }

  Future<void> _reconnect() async {
    await ref.read(reticulumClientProvider).disconnect();
    if (!mounted) return;
    setState(() {
      _connected = false;
      _address = null;
    });
    await _open();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _peerController.dispose();
    _payloadController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _send() {
    final ok = ref.read(reticulumClientProvider).send(
          _peerController.text.trim(),
          _payloadController.text.trim(),
        );
    setState(() => _status = ok ? 'RELAYED' : 'NOT CONNECTED');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonTheme.background,
      appBar: AppBar(
        backgroundColor: NeonTheme.surface,
        title: const Text('◈ RETICULUM RELAY ◈',
            style: TextStyle(fontFamily: 'monospace', fontSize: 15)),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/menu'),
            icon: const Icon(Icons.exit_to_app,
                color: NeonTheme.neonYellow, size: 18),
            label: const Text('EXIT TO ARCADE',
                style: TextStyle(
                    color: NeonTheme.neonYellow,
                    fontFamily: 'monospace',
                    fontSize: 11)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.circle,
                  size: 12,
                  color: _connected ? NeonTheme.neonGreen : NeonTheme.dangerRed),
              const SizedBox(width: 8),
              Text(
                _connecting
                    ? 'CONNECTING…'
                    : (_connected ? 'MESH ONLINE' : 'MESH OFFLINE'),
                style: TextStyle(
                  fontFamily: 'monospace',
                  color:
                      _connected ? NeonTheme.neonGreen : NeonTheme.dangerRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('BRIDGE URL',
              style: TextStyle(
                  color: NeonTheme.neonPink, fontFamily: 'monospace', fontSize: 11)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'ws://<bridge-host>:8765',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _connecting ? null : _reconnect,
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('RECONNECT', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NeonTheme.neonCyan,
                  side: const BorderSide(color: NeonTheme.neonCyan),
                ),
              ),
            ],
          ),
          const Text(
            'The bridge is a desktop companion (polybius_bridge.py). On phones,'
            ' point this at its LAN address, e.g. ws://192.168.1.50:8765.',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 12),
          const Text('YOUR ADDRESS',
              style: TextStyle(
                  color: NeonTheme.neonCyan, fontFamily: 'monospace', fontSize: 11)),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  _address ?? '—',
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 11, color: Colors.white),
                ),
              ),
              if (_address != null)
                IconButton(
                  icon: const Icon(Icons.copy,
                      color: NeonTheme.neonCyan, size: 18),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _address!)),
                ),
            ],
          ),
          const Divider(color: Colors.white24, height: 28),
          TextField(
            controller: _peerController,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              labelText: "Peer address (hex destination hash)",
              labelStyle: TextStyle(color: NeonTheme.neonPink, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _payloadController,
            maxLines: 2,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Emoji ciphertext to relay',
              labelStyle: TextStyle(color: NeonTheme.neonGreen, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _connected ? _send : null,
            icon: const Icon(Icons.send),
            label: const Text('RELAY CIPHERTEXT'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonYellow,
                    fontSize: 11)),
          ],
          const Divider(color: Colors.white24, height: 28),
          const Text('INBOUND',
              style: TextStyle(
                  color: NeonTheme.neonCyan, fontFamily: 'monospace', fontSize: 11)),
          if (_received.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No messages yet.',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ..._received.map((m) => Card(
                color: NeonTheme.surface,
                child: ListTile(
                  dense: true,
                  title: SelectableText(m.payload,
                      style: const TextStyle(fontSize: 16)),
                  subtitle: Text('from ${m.from}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 9, fontFamily: 'monospace')),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy,
                        color: NeonTheme.neonCyan, size: 18),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: m.payload)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
