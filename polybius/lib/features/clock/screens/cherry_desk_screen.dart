import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/clock/alphabet_pool.dart';
import 'package:polybius/features/clock/clock_copy.dart';
import 'package:polybius/features/clock/clock_ritual.dart';
import 'package:polybius/features/clock/clock_session.dart';

/// Darth Cherry desk — notes, typebox, and alphabet-pool share.
///
/// Copy describes clock operations only.
class CherryDeskScreen extends ConsumerStatefulWidget {
  const CherryDeskScreen({super.key});

  @override
  ConsumerState<CherryDeskScreen> createState() => _CherryDeskScreenState();
}

class _CherryDeskScreenState extends ConsumerState<CherryDeskScreen> {
  final _typebox = TextEditingController();
  final _paste = TextEditingController();
  Timer? _makeHold;
  Timer? _vanish;
  Timer? _eternityHold;
  bool _eternityArmed = false;
  String? _status;
  bool _ok = true;

  @override
  void dispose() {
    _makeHold?.cancel();
    _vanish?.cancel();
    _eternityHold?.cancel();
    _typebox.dispose();
    _paste.dispose();
    super.dispose();
  }

  void _startMake() {
    _makeHold?.cancel();
    _makeHold = Timer(ClockRitual.makeHold, () {
      _vanish?.cancel();
      _vanish = Timer(ClockRitual.vanishDelay, () {
        if (!mounted) return;
        setState(() => _typebox.clear());
      });
    });
  }

  void _endMake() => _makeHold?.cancel();

  void _onEternityTap() => setState(() => _eternityArmed = true);

  void _startEternityHold() {
    if (!_eternityArmed) return;
    _eternityHold?.cancel();
    _eternityHold = Timer(ClockRitual.eternityHold, () {
      ref.read(clockSessionProvider.notifier).raiseFalseAlarm();
      if (mounted) context.go('/clock/face');
    });
  }

  void _endEternityHold() => _eternityHold?.cancel();

  void _import(String raw) {
    final token = AlphabetPoolToken.tryParse(raw);
    if (token == null) {
      setState(() {
        _ok = false;
        _status = 'INVALID SQUARE';
      });
      return;
    }
    if (token.isExpired) {
      setState(() {
        _ok = false;
        _status = 'SQUARE EXPIRED';
      });
      return;
    }
    if (!token.verifyIntegrity()) {
      setState(() {
        _ok = false;
        _status = 'SQUARE DAMAGED';
      });
      return;
    }
    ref.read(clockSessionProvider.notifier).setAlphabetSeed(token.seed);
    setState(() {
      _ok = true;
      _status = 'SETS ALIGNED — ${token.poolId}';
    });
  }

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanSquare()),
    );
    if (result != null) _import(result);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(clockSessionProvider);
    if (!session.unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/clock');
      });
    }

    final pool = ref.read(clockSessionProvider.notifier).pool;
    final token = pool.token();
    final code = token.encode();

    return Scaffold(
      backgroundColor: const Color(0xFF140008),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                const Text(
                  'CHERRY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFFFF2A4D),
                    letterSpacing: 4,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  key: const Key('eternity'),
                  onTap: _onEternityTap,
                  onLongPressStart: (_) => _startEternityHold(),
                  onLongPressEnd: (_) => _endEternityHold(),
                  onLongPressCancel: _endEternityHold,
                  child: Text(
                    '?∞',
                    style: TextStyle(
                      fontSize: 28,
                      color: _eternityArmed
                          ? const Color(0xFFFFC1C8)
                          : const Color(0xFFFF2A4D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF20000C),
              child: const Text(
                ClockCopy.deskNotes,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'TYPEBOX',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFFFC1C8),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _typebox,
              maxLines: 4,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF20000C),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              key: const Key('make'),
              onLongPressStart: (_) => _startMake(),
              onLongPressEnd: (_) => _endMake(),
              onLongPressCancel: _endMake,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF2A4D), width: 1.6),
                ),
                child: const Text(
                  'MAKE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    letterSpacing: 6,
                    color: Color(0xFFFF2A4D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'STEG / HIEROGLYPH / SIGIL SETS',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFC9A227),
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pool ${pool.poolId} · ${pool.glyphs.length} glyphs',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final g in pool.glyphs.take(48))
                  Text(g, style: const TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(data: code, size: 180),
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: Colors.white38,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () async {
                    await ref.read(clockSessionProvider.notifier).randomisePool();
                    setState(() {
                      _ok = true;
                      _status = 'NEW SET MINTED — SHARE THE SQUARE';
                    });
                  },
                  child: const Text('NEW SET'),
                ),
                TextButton(
                  onPressed: () =>
                      SharePlus.instance.share(ShareParams(text: code)),
                  child: const Text('SHARE'),
                ),
                TextButton(
                  onPressed: _scan,
                  child: const Text('SCAN'),
                ),
              ],
            ),
            TextField(
              controller: _paste,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: const InputDecoration(
                labelText: 'paste a square',
                labelStyle: TextStyle(fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => _import(_paste.text),
              child: const Text('IMPORT'),
            ),
            if (_status != null)
              Text(
                _status!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: _ok ? NeonTheme.neonGreen : NeonTheme.dangerRed,
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    key: const Key('sleep'),
                    onDoubleTap: () => context.go('/clock/keys'),
                    child: const _BarButton(label: 'SLEEP'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    key: const Key('stop'),
                    onDoubleTap: () {
                      ref.read(clockSessionProvider.notifier).lock();
                      context.go('/clock');
                    },
                    child: const _BarButton(label: 'STOP'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'monospace',
          letterSpacing: 4,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _ScanSquare extends StatelessWidget {
  const _ScanSquare();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('SCAN SQUARE', style: TextStyle(fontFamily: 'monospace')),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (capture.barcodes.isEmpty) return;
          final value = capture.barcodes.first.rawValue;
          if (value != null) Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
