import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/bluetooth/bluetooth_link_service.dart';
import 'package:polybius/features/bluetooth/bluetooth_protocol.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';
import 'package:polybius/features/cipher/veil/veil_state.dart';

/// Neo-noir cyberpunk Bluetooth messaging — scan, link, chat bubbles,
/// decrypt-via-current-rotor, and mutual-confirm rotor/pool share.
class BluetoothMessagingPanel extends ConsumerStatefulWidget {
  const BluetoothMessagingPanel({super.key});

  @override
  ConsumerState<BluetoothMessagingPanel> createState() =>
      _BluetoothMessagingPanelState();
}

class _BluetoothMessagingPanelState
    extends ConsumerState<BluetoothMessagingPanel>
    with SingleTickerProviderStateMixin {
  final _btPayload = TextEditingController();
  String? _selectedPeerId;
  String? _decryptPreview;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _btPayload.dispose();
    super.dispose();
  }

  BtPeer? _peer(BluetoothLinkState bt) {
    final id = _selectedPeerId;
    if (id == null) return null;
    try {
      return bt.peers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _decryptPayload(String ciphertext) {
    final engine = ref.read(cipherEngineProvider);
    final plain = engine.decrypt(ciphertext);
    final veil = ref.read(veilProvider);
    setState(() {
      _decryptPreview = veil.mode == VeilMode.matrix
          ? 'MATRIX VEIL — ${plain.length} chars held'
          : (plain.isEmpty ? '(no plaintext recovered)' : plain);
    });
    ref.read(storageServiceProvider).logAudit(
          'BT_DECRYPT_ROTOR',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
        );
  }

  Future<void> _shareRotor(String peerId) async {
    final seed = ref.read(poolSeedProvider);
    final complexity = ref.read(cipherComplexityProvider);
    final scores = ref.read(highScoresProvider);
    final token = PoolSync.fromSeed(
      seed,
      complexity: complexity,
      scores: scores,
    );
    final code = await ref
        .read(bluetoothLinkProvider.notifier)
        .offerRotorShare(peerId: peerId, token: token);
    if (!mounted || code == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: NeonTheme.surface,
        content: Text(
          'CONFIRM CODE $code — peer must match',
          style: const TextStyle(
            fontFamily: 'monospace',
            color: NeonTheme.neonYellow,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmShare() async {
    final token =
        await ref.read(bluetoothLinkProvider.notifier).confirmRotorShare();
    if (token != null) {
      ref.read(poolSeedProvider.notifier).setSeed(token.seed);
      ref.read(cipherComplexityProvider.notifier).setComplexity(token.complexity);
      if (token.scores.isNotEmpty) {
        await ref.read(highScoresProvider.notifier).mergeRemote(token.scores);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: NeonTheme.surface,
            content: Text(
              'POOL ALIGNED — ${token.poolId}',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.neonGreen,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final engine = ref.watch(cipherEngineProvider);
    final bt = ref.watch(bluetoothLinkProvider);
    final operatorName =
        auth.user?.displayName ?? auth.user?.username ?? 'OPERATOR';
    final peer = _peer(bt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderStrip(
          pulse: _pulse,
          enabled: bt.enabled,
          status: bt.status,
          onToggle: (v) {
            ref.read(bluetoothLinkProvider.notifier).setEnabled(
                  v,
                  operatorName: operatorName,
                );
          },
        ),
        if (!bt.enabled)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Enable the link to scan POLYBIUS-* peers across HQ and user builds.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        if (bt.enabled) ...[
          const SizedBox(height: 14),
          _PeerRail(
            peers: bt.peers,
            scanning: bt.scanning,
            selectedId: _selectedPeerId,
            onSelect: (p) => setState(() => _selectedPeerId = p.id),
            onLink: (p) async {
              await ref.read(bluetoothLinkProvider.notifier).connect(p);
              setState(() => _selectedPeerId = p.id);
            },
            onRescan: () =>
                ref.read(bluetoothLinkProvider.notifier).startScan(),
          ),
          if (bt.pendingShare != null) ...[
            const SizedBox(height: 14),
            _ConfirmCodeCard(
              pending: bt.pendingShare!,
              onConfirm: _confirmShare,
              onReject: () =>
                  ref.read(bluetoothLinkProvider.notifier).rejectRotorShare(),
            ),
          ],
          if (peer != null) ...[
            const SizedBox(height: 14),
            _Composer(
              controller: _btPayload,
              peerName: peer.name,
              poolId: engine.poolId,
              onSend: () {
                ref.read(bluetoothLinkProvider.notifier).sendCiphertext(
                      peer.id,
                      _btPayload.text,
                    );
                _btPayload.clear();
              },
              onDecryptLocal: () {
                if (_btPayload.text.trim().isEmpty) return;
                _decryptPayload(_btPayload.text.trim());
              },
              onShareRotor: () => _shareRotor(peer.id),
            ),
          ],
          if (_decryptPreview != null) ...[
            const SizedBox(height: 10),
            _DecryptPreview(
              text: _decryptPreview!,
              onClear: () => setState(() => _decryptPreview = null),
            ),
          ],
          if (bt.messages.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '◈ SIGNAL TRAFFIC',
              style: TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.neonYellow,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            ...bt.messages.take(10).map(
                  (m) => _MessageBubble(
                    message: m,
                    onDecrypt: m.isCipher
                        ? () => _decryptPayload(m.payload)
                        : null,
                  ),
                ),
          ],
        ],
      ],
    );
  }
}

class _HeaderStrip extends StatelessWidget {
  const _HeaderStrip({
    required this.pulse,
    required this.enabled,
    required this.status,
    required this.onToggle,
  });

  final AnimationController pulse;
  final bool enabled;
  final String status;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = enabled ? 0.35 + pulse.value * 0.35 : 0.08;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0018), Color(0xFF001A22), Color(0xFF120028)],
            ),
            border: Border.all(
              color: (enabled ? NeonTheme.neonCyan : Colors.white24)
                  .withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: NeonTheme.neonCyan.withValues(alpha: glow),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                enabled ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: enabled ? NeonTheme.neonCyan : Colors.white38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BLUETOOTH LINK',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: NeonTheme.neonGreen,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: enabled ? NeonTheme.neonCyan : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: NeonTheme.neonCyan,
                activeTrackColor: NeonTheme.neonCyan.withValues(alpha: 0.35),
                onChanged: onToggle,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PeerRail extends StatelessWidget {
  const _PeerRail({
    required this.peers,
    required this.scanning,
    required this.selectedId,
    required this.onSelect,
    required this.onLink,
    required this.onRescan,
  });

  final List<BtPeer> peers;
  final bool scanning;
  final String? selectedId;
  final ValueChanged<BtPeer> onSelect;
  final ValueChanged<BtPeer> onLink;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'NEARBY OPERATORS',
              style: TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.neonPink,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onRescan,
              child: const Text(
                'RESCAN',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonCyan,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        if (scanning)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              color: NeonTheme.neonCyan,
              backgroundColor: Colors.white12,
              minHeight: 2,
            ),
          ),
        if (peers.isEmpty)
          const Text(
            'No POLYBIUS-* peers yet. Enable Bluetooth on both devices.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          )
        else
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: peers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final p = peers[i];
                final selected = selectedId == p.id;
                return InkWell(
                  onTap: () => onSelect(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 148,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF0A2030)
                          : NeonTheme.surface,
                      border: Border.all(
                        color: selected
                            ? NeonTheme.neonCyan
                            : (p.connected
                                ? NeonTheme.neonGreen
                                : Colors.white24),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    NeonTheme.neonCyan.withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: selected
                                ? NeonTheme.neonCyan
                                : NeonTheme.neonGreen,
                          ),
                        ),
                        Text(
                          p.rssi != null ? '${p.rssi} dBm' : '—',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => onLink(p),
                          child: Text(
                            p.connected ? 'SELECT' : 'LINK',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: NeonTheme.neonPink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConfirmCodeCard extends StatelessWidget {
  const _ConfirmCodeCard({
    required this.pending,
    required this.onConfirm,
    required this.onReject,
  });

  final BtRotorSharePending pending;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF220010), Color(0xFF0A0018), Color(0xFF001820)],
        ),
        border: Border.all(color: NeonTheme.neonYellow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.neonYellow.withValues(alpha: 0.25),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            pending.initiatedLocally
                ? 'SHARE ROTOR / POOL'
                : 'INCOMING ROTOR / POOL',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonYellow,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pool ${pending.poolId} · ${pending.peerName}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Text(
            pending.confirmCode,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 36,
              letterSpacing: 10,
              color: NeonTheme.neonCyan,
              shadows: [
                Shadow(color: NeonTheme.neonCyan, blurRadius: 18),
                Shadow(color: NeonTheme.neonPink, blurRadius: 28),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pending.localConfirmed
                ? (pending.remoteConfirmed
                    ? 'BOTH CONFIRMED'
                    : 'YOU CONFIRMED — waiting on peer')
                : 'Confirm this code matches on both devices',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NeonTheme.dangerRed,
                    side: const BorderSide(color: NeonTheme.dangerRed),
                  ),
                  child: const Text('REJECT'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: pending.localConfirmed ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: NeonTheme.neonYellow,
                    side: const BorderSide(color: NeonTheme.neonYellow, width: 2),
                  ),
                  child: Text(
                    pending.localConfirmed ? 'CONFIRMED' : 'CONFIRM CODE',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.peerName,
    required this.poolId,
    required this.onSend,
    required this.onDecryptLocal,
    required this.onShareRotor,
  });

  final TextEditingController controller;
  final String peerName;
  final String poolId;
  final VoidCallback onSend;
  final VoidCallback onDecryptLocal;
  final VoidCallback onShareRotor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0618),
        border: Border.all(color: NeonTheme.neonPink.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CHANNEL → $peerName · rotor pool $poolId',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonPink,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 2,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Emoji ciphertext',
              labelStyle: TextStyle(color: NeonTheme.neonGreen, fontSize: 12),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send, size: 18),
                label: const Text('SEND BT'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: NeonTheme.neonPink,
                  side: const BorderSide(color: NeonTheme.neonPink, width: 2),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onDecryptLocal,
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('DECRYPT VIA ROTOR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NeonTheme.neonCyan,
                  side: const BorderSide(color: NeonTheme.neonCyan),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onShareRotor,
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('SHARE ROTOR / POOL'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NeonTheme.neonYellow,
                  side: const BorderSide(color: NeonTheme.neonYellow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecryptPreview extends StatelessWidget {
  const _DecryptPreview({required this.text, required this.onClear});

  final String text;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF031A08),
        border: Border.all(color: NeonTheme.neonGreen),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DECRYPT · CURRENT ROTOR',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonGreen,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  text,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonGreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
            },
            icon: const Icon(Icons.copy, color: NeonTheme.neonCyan, size: 18),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onDecrypt});

  final BtMessage message;
  final VoidCallback? onDecrypt;

  @override
  Widget build(BuildContext context) {
    final accent = message.outbound ? NeonTheme.neonPink : NeonTheme.neonGreen;
    final label = switch (message.kind) {
      BtEnvelopeKind.rotorOffer => 'ROTOR OFFER',
      BtEnvelopeKind.rotorAck => 'ROTOR ACK',
      BtEnvelopeKind.rotorReject => 'ROTOR REJECT',
      BtEnvelopeKind.cipher => 'CIPHER',
      BtEnvelopeKind.unknown => 'SIGNAL',
    };

    return Align(
      alignment:
          message.outbound ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: message.outbound
                ? const [Color(0xFF2A0030), Color(0xFF120018)]
                : const [Color(0xFF002818), Color(0xFF061018)],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${message.outbound ? '→' : '←'} ${message.fromName}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: accent,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.payload,
              style: const TextStyle(fontSize: 15, height: 1.3),
            ),
            if (message.confirmCode != null) ...[
              const SizedBox(height: 4),
              Text(
                'CODE ${message.confirmCode}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonYellow,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ],
            if (onDecrypt != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onDecrypt,
                icon: Icon(Icons.lock_open, size: 14, color: accent),
                label: Text(
                  'DECRYPT VIA CURRENT ROTOR',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: accent,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
