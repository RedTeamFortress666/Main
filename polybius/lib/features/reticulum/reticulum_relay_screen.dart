import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/reticulum/reticulum_client.dart';

/// Relays emoji ciphertext over a Reticulum mesh via the companion bridge.
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
  final _scroll = ScrollController();
  final List<ReticulumMessage> _inbound = [];
  final List<_OutMsg> _outbound = [];
  final List<StreamSubscription> _subs = [];

  bool _connecting = true;
  bool _connected = false;
  bool _connectionExpanded = true;
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
      if (mounted) setState(() => _inbound.insert(0, m));
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
    await ref.read(storageServiceProvider).setReticulumUrl(url);
    final ok = await client.connect(url: url);
    if (!mounted) return;
    setState(() {
      _connecting = false;
      _connected = ok;
      _address = client.localAddress;
      _status = ok ? null : 'BRIDGE OFFLINE — start polybius_bridge.py';
      if (ok) _connectionExpanded = false;
    });
  }

  Future<void> _reconnect() async {
    await ref.read(reticulumClientProvider).disconnect();
    if (!mounted) return;
    setState(() {
      _connected = false;
      _address = null;
      _connectionExpanded = true;
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
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final peer = _peerController.text.trim();
    final payload = _payloadController.text.trim();
    if (peer.isEmpty || payload.isEmpty) {
      setState(() => _status = 'Need peer hash + ciphertext');
      return;
    }
    final ok = ref.read(reticulumClientProvider).send(peer, payload);
    setState(() {
      _status = ok ? 'RELAYED' : 'NOT CONNECTED';
      if (ok) {
        _outbound.insert(
          0,
          _OutMsg(peer: peer, payload: payload, at: DateTime.now()),
        );
        _payloadController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onlineColor =
        _connected ? NeonTheme.neonGreen : NeonTheme.dangerRed;

    return Scaffold(
      backgroundColor: NeonTheme.background,
      appBar: AppBar(
        backgroundColor: NeonTheme.surface,
        title: const Text(
          '◈ RETICULUM RELAY ◈',
          style: TextStyle(fontFamily: 'monospace', fontSize: 15),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/cipher'),
            icon: const Icon(Icons.arrow_back,
                color: NeonTheme.neonCyan, size: 18),
            label: const Text(
              'CIPHER',
              style: TextStyle(
                color: NeonTheme.neonCyan,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // —— Connection strip ——
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF120028),
                  _connected
                      ? const Color(0xFF041a12)
                      : const Color(0xFF1a0510),
                ],
              ),
              border: Border.all(color: onlineColor.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onlineColor,
                    boxShadow: [
                      BoxShadow(color: onlineColor, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _connecting
                        ? 'CONNECTING…'
                        : (_connected ? 'MESH ONLINE' : 'MESH OFFLINE'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: onlineColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(
                    () => _connectionExpanded = !_connectionExpanded,
                  ),
                  child: Text(
                    _connectionExpanded ? 'HIDE LINK' : 'CONNECTION',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: NeonTheme.neonCyan,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // —— Scroll-down connection details ——
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ConnectionPanel(
              urlController: _urlController,
              address: _address,
              connecting: _connecting,
              onReconnect: _reconnect,
            ),
            crossFadeState: _connectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
          ),

          const SizedBox(height: 20),
          const Text(
            'OUTBOUND',
            style: TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonPink,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NeonTheme.surface,
              border: Border.all(color: NeonTheme.neonPink.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _peerController,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Peer destination hash',
                    labelStyle:
                        TextStyle(color: NeonTheme.neonPink, fontSize: 12),
                    prefixIcon: Icon(Icons.person_pin_circle_outlined,
                        color: NeonTheme.neonPink, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _payloadController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Emoji ciphertext',
                    labelStyle:
                        TextStyle(color: NeonTheme.neonGreen, fontSize: 12),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _connected ? _send : null,
                  icon: const Icon(Icons.rocket_launch_outlined),
                  label: const Text('SEND ON MESH'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: NeonTheme.neonPink,
                    side: const BorderSide(color: NeonTheme.neonPink, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _status!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: NeonTheme.neonYellow,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_outbound.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._outbound.take(8).map(
                  (m) => _Bubble(
                    title: '→ ${m.peer}',
                    body: m.payload,
                    accent: NeonTheme.neonPink,
                    alignEnd: true,
                  ),
                ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'INBOUND',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonCyan,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '${_inbound.length}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_inbound.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'Waiting for mesh traffic…\nPaste a peer hash above to send first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
              ),
            )
          else
            ..._inbound.map(
              (m) => _Bubble(
                title: '← ${m.from}',
                body: m.payload,
                accent: NeonTheme.neonCyan,
                alignEnd: false,
                onCopy: () =>
                    Clipboard.setData(ClipboardData(text: m.payload)),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutMsg {
  const _OutMsg({required this.peer, required this.payload, required this.at});
  final String peer;
  final String payload;
  final DateTime at;
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.urlController,
    required this.address,
    required this.connecting,
    required this.onReconnect,
  });

  final TextEditingController urlController;
  final String? address;
  final bool connecting;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0a1020),
          border: Border.all(color: NeonTheme.neonCyan.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BRIDGE URL',
              style: TextStyle(
                color: NeonTheme.neonPink,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: urlController,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'ws://<bridge-host>:8765',
                      hintStyle:
                          TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: connecting ? null : onReconnect,
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('RECONNECT', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NeonTheme.neonCyan,
                    side: const BorderSide(color: NeonTheme.neonCyan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Point phones at the LAN address of polybius_bridge.py '
              '(e.g. ws://192.168.1.50:8765). Scroll down for messaging.',
              style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text(
              'YOUR ADDRESS',
              style: TextStyle(
                color: NeonTheme.neonCyan,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    address ?? '—',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (address != null)
                  IconButton(
                    icon: const Icon(Icons.copy,
                        color: NeonTheme.neonCyan, size: 18),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: address!)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.title,
    required this.body,
    required this.accent,
    required this.alignEnd,
    this.onCopy,
  });

  final String title;
  final String body;
  final Color accent;
  final bool alignEnd;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: NeonTheme.surface,
          border: Border.all(color: accent.withValues(alpha: 0.55)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: accent.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    body,
                    style: const TextStyle(fontSize: 17, height: 1.3),
                  ),
                ],
              ),
            ),
            if (onCopy != null)
              IconButton(
                icon: Icon(Icons.copy, color: accent, size: 16),
                onPressed: onCopy,
              ),
          ],
        ),
      ),
    );
  }
}
