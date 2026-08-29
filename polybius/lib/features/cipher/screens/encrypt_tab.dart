import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/engine/pool_manager.dart';
import 'package:polybius/features/cipher/screens/clipboard_row.dart';
import 'package:polybius/features/redlight/glyph_derangement.dart';
import 'package:polybius/features/redlight/redlight_keyboard.dart';
import 'package:polybius/features/redlight/vanishing_buffer.dart';
import 'package:polybius/features/redlight/vanishing_field.dart';

class EncryptTab extends ConsumerStatefulWidget {
  const EncryptTab({super.key});

  @override
  ConsumerState<EncryptTab> createState() => _EncryptTabState();
}

class _EncryptTabState extends ConsumerState<EncryptTab> {
  final _buffer = VanishingBuffer();
  String _output = '';

  void _encrypt() {
    final duress = ref.read(duressProvider);
    var plaintext = _buffer.take();
    if (plaintext.isEmpty && duress.active && duress.coverPlaintext.isNotEmpty) {
      plaintext = duress.coverPlaintext;
    }
    final engine = CipherEngine(
      seed: ref.read(cipherEngineProvider).seed,
      density: ref.read(glyphDensityProvider),
    );
    setState(() {
      _output = engine.encrypt(plaintext);
    });
    // Same audit line in both identities — do not log length of a cover
    // message as a distinguisher if we can avoid it. Length of empty-vs-real
    // still leaks; we log a constant.
    ref.read(storageServiceProvider).logAudit(
          'ENCRYPT',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
          'cabinet',
        );
  }

  @override
  Widget build(BuildContext context) {
    final lamp = ref.watch(cabinetLampProvider);
    final sound = ref.watch(gameSettingsProvider).soundEnabled;
    final operator = ref.watch(authProvider).user?.username ?? '000000';
    final derange = GlyphDerangement(
      poolId: ref.watch(displayPoolIdProvider),
      slot: PoolManager.slotOf(DateTime.now()),
      pin: operator,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VanishingField(buffer: _buffer),
          const SizedBox(height: 6),
          Text(
            lamp
                ? 'CABINET LAMP ON — PHOSPHOR MAP LIVE'
                : 'HOUSE LIGHTS — QWERTY TYPES QWERTY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: lamp ? NeonTheme.dangerRed : Colors.white38,
            ),
          ),
          const SizedBox(height: 6),
          RedlightKeyboard(
            derangement: derange,
            buffer: _buffer,
            lampOn: lamp,
            audio: sound,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('2-GLYPH'),
                  selected: ref.watch(glyphDensityProvider) ==
                      GlyphDensity.compact,
                  onSelected: (_) => ref
                      .read(glyphDensityProvider.notifier)
                      .state = GlyphDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('3-GLYPH'),
                  selected: ref.watch(glyphDensityProvider) ==
                      GlyphDensity.cabinet,
                  onSelected: (_) => ref
                      .read(glyphDensityProvider.notifier)
                      .state = GlyphDensity.cabinet,
                ),
              ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ElevatedButton(onPressed: _encrypt, child: const Text('ENCRYPT')),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: NeonTheme.neonCyan),
                color: NeonTheme.surface,
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output.isEmpty ? '...' : _output,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          ClipboardRow(
            color: NeonTheme.neonCyan,
            getCopyText: () => _output,
            onPaste: (_) {},
          ),
        ],
      ),
    );
  }
}
