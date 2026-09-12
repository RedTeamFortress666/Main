import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/engine/pool_manager.dart';
import 'package:polybius/features/cipher/screens/clipboard_row.dart';
import 'package:polybius/core/widgets/cabinet_atmosphere.dart';
import 'package:polybius/features/redlight/cherry_banner.dart';
import 'package:polybius/features/redlight/glyph_derangement.dart';
import 'package:polybius/features/redlight/redlight_keyboard.dart';
import 'package:polybius/features/redlight/redlight_sealed_panel.dart';
import 'package:polybius/features/redlight/redlight_vault.dart';
import 'package:polybius/features/redlight/vanishing_buffer.dart';
import 'package:polybius/features/redlight/vanishing_field.dart';
import 'package:polybius/features/roundtable/round_table.dart';
import 'package:polybius/features/roundtable/traffic_sketch.dart';
import 'package:polybius/features/stego/stego_receipt.dart';
import 'package:polybius/features/stego/stego_vet.dart';

/// Open cipher ENCRYPT.
///
/// Default is advanced V1: a normal plaintext field over the new engine
/// (odometer rotors, 2-glyph map, no stored char-index). The glyph
/// keyboard is Darth Cherry only.
class EncryptTab extends ConsumerStatefulWidget {
  const EncryptTab({super.key});

  @override
  ConsumerState<EncryptTab> createState() => _EncryptTabState();
}

class _EncryptTabState extends ConsumerState<EncryptTab> {
  final _inputController = TextEditingController();
  final _buffer = VanishingBuffer();
  String _output = '';
  StegoReceipt? _receipt;
  PatternReport? _report;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _plaintext({required bool cherry}) {
    final duress = ref.read(duressProvider);
    var text = cherry ? _buffer.take() : _inputController.text;
    if (text.isEmpty && duress.active && duress.coverPlaintext.isNotEmpty) {
      text = duress.coverPlaintext;
    }
    return text;
  }

  Future<void> _encrypt({required bool cherry}) async {
    final gaps = List<int>.from(_buffer.gapsMs);
    final plaintext = _plaintext(cherry: cherry);
    final policy = ref.read(cabinetPolicyProvider);
    final useStego = cherry ? true : policy.v1Stego;
    final engine = CipherEngine(
      seed: ref.read(cipherEngineProvider).seed,
      density: cherry
          ? ref.read(glyphDensityProvider)
          : GlyphDensity.compact,
      stego: useStego,
    );
    final cipher = engine.encrypt(plaintext);
    StegoReceipt? receipt;
    PatternReport? report;
    if (policy.stegoVet || policy.roundTable) {
      final fp = StegoFingerprint.of(engine, cipher);
      final sketch = TrafficSketch(
        gapsMs: gaps,
        decoyCount: fp.decoyCount,
        fingerprintPrefix: fp.prefix,
        atMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      final out = await ref.read(storageServiceProvider).vetStego(
            fingerprint: fp,
            sketch: sketch,
          );
      receipt = out.receipt;
      report = out.report;
      await ref.read(leakSurfaceProvider.notifier).refresh(
            username: ref.read(authProvider).user?.username,
          );
    }
    if (!mounted) return;
    setState(() {
      _output = cipher;
      _receipt = receipt;
      _report = report;
    });
    ref.read(storageServiceProvider).logAudit(
          'ENCRYPT',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
          cherry ? 'cabinet' : 'v1',
        );
  }

  @override
  Widget build(BuildContext context) {
    final cherry = ref.watch(darthCherryProvider);
    return cherry ? _cherryBody() : _v1Body();
  }

  Widget _v1Body() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _inputController,
            maxLines: 3,
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'PLAINTEXT',
              labelStyle: TextStyle(color: NeonTheme.neonGreen),
              border: OutlineInputBorder(),
            ),
          ),
          ClipboardRow(
            color: NeonTheme.neonGreen,
            getCopyText: () => _inputController.text,
            onPaste: (text) => setState(() => _inputController.text = text),
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: () { _encrypt(cherry: false); },
            child: const Text('ENCRYPT'),
          ),
          const SizedBox(height: 12),
          if (_receipt != null || _report != null) _vetStrip(),
          Expanded(child: _cipherOut()),
          ClipboardRow(
            color: NeonTheme.neonCyan,
            getCopyText: () => _output,
            onPaste: (text) => setState(() => _inputController.text = text),
          ),
        ],
      ),
    );
  }

  Widget _cherryBody() {
    final access = ref.watch(redlightAccessProvider).valueOrNull ??
        const RedlightAccess.sealed(RedlightSeal.noTicket);
    final lamp = access.granted && ref.watch(cabinetLampProvider);
    final sound = ref.watch(gameSettingsProvider).soundEnabled;

    return CabinetAtmosphere(
      cherry: true,
      child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CherryBanner(
            lampOn: lamp,
            report: ref.watch(leakReportProvider),
            ledger: ref.watch(autoPatcherProvider).latest,
          ),
          const SizedBox(height: 6),
          if (!access.granted) ...[
            RedlightSealedPanel(access: access),
            const SizedBox(height: 6),
          ] else ...[
            VanishingField(buffer: _buffer),
            const SizedBox(height: 6),
            RedlightKeyboard(
              // Secret is HMAC(device key, owner‖mixer): never stored, never
              // the username, not recomputable from a copied Hive box.
              derangement: GlyphDerangement(
                poolId: ref.watch(displayPoolIdProvider),
                slot: PoolManager.slotOf(DateTime.now()),
                pin: access.derangeSecret,
              ),
              buffer: _buffer,
              lampOn: lamp,
              audio: sound,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('2-GLYPH'),
                  selected:
                      ref.watch(glyphDensityProvider) == GlyphDensity.compact,
                  onSelected: (_) => ref
                      .read(glyphDensityProvider.notifier)
                      .state = GlyphDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('3-GLYPH'),
                  selected:
                      ref.watch(glyphDensityProvider) == GlyphDensity.cabinet,
                  onSelected: (_) => ref
                      .read(glyphDensityProvider.notifier)
                      .state = GlyphDensity.cabinet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: access.granted ? () { _encrypt(cherry: true); } : null,
            child: const Text('ENCRYPT'),
          ),
          const SizedBox(height: 8),
          if (_receipt != null || _report != null) _vetStrip(),
          Expanded(child: _cipherOut()),
          ClipboardRow(
            color: NeonTheme.neonCyan,
            getCopyText: () => _output,
            onPaste: (_) {},
          ),
        ],
      ),
      ),
    );
  }

  Widget _vetStrip() {
    final receipt = _receipt;
    final report = _report;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          if (receipt != null)
            Text(
              'VET ${receipt.readout} · ${receipt.origin.toUpperCase()}',
              key: const ValueKey<String>('stego-vet-receipt'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 1,
                color: NeonTheme.neonYellow,
              ),
            ),
          if (report != null)
            Text(
              'TABLE ${report.readout} · ${report.boil}',
              key: const ValueKey<String>('roundtable-report'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: report.verdict == CadenceVerdict.hostile
                    ? NeonTheme.dangerRed
                    : NeonTheme.neonGreen,
              ),
            ),
        ],
      ),
    );
  }

  Widget _cipherOut() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: NeonTheme.neonCyan),
        color: NeonTheme.surface.withValues(alpha: 0.82),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.neonCyan.withValues(alpha: 0.22),
            blurRadius: 12,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          _output.isEmpty ? '...' : _output,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
