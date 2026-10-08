import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/floating_glyph_keyboard.dart';
import 'package:polybius/core/widgets/unique_qr_player.dart';

class EncryptTab extends ConsumerStatefulWidget {
  const EncryptTab({super.key});

  @override
  ConsumerState<EncryptTab> createState() => _EncryptTabState();
}

class _EncryptTabState extends ConsumerState<EncryptTab> {
  String _draft = '';
  String _envelope = '';

  void _encrypt() {
    if (_draft.isEmpty) return;
    final engine = ref.read(cipherEngineProvider);
    setState(() => _envelope = engine.encrypt(_draft));
    ref.read(storageServiceProvider).logAudit(
          'ENCRYPT',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
          '${_draft.length} chars',
        );
    setState(() => _draft = '');
  }

  @override
  Widget build(BuildContext context) {
    final fp = ref.watch(cipherEngineProvider).fingerprint;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'KYBER→AES  fp $fp',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: NeonTheme.cherryGold,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: NeonTheme.cherryBright.withValues(alpha: 0.5)),
            color: NeonTheme.cherryGlass,
          ),
          child: Text(
            _draft.isEmpty ? '…' : _draft,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FloatingGlyphKeyboard(
          interactive: true,
          onChar: (ch) => setState(() => _draft += ch),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                if (_draft.isNotEmpty) {
                  setState(() => _draft = _draft.substring(0, _draft.length - 1));
                }
              },
              child: const Text('DEL', style: TextStyle(color: NeonTheme.cherryBright)),
            ),
            TextButton(
              onPressed: () => setState(() => _draft += ' '),
              child: const Text('SPC', style: TextStyle(color: NeonTheme.cherryGold)),
            ),
            ElevatedButton(
              onPressed: _encrypt,
              child: const Text('SEAL'),
            ),
          ],
        ),
        if (_envelope.isNotEmpty) ...[
          const SizedBox(height: 12),
          UniqueQrPlayer(payload: _envelope),
        ],
      ],
    );
  }
}
