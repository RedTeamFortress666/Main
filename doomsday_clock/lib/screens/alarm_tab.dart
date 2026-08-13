import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/darth_probe.dart';
import '../theme/noir_theme.dart';
import '../widgets/matrix_chrome.dart';

class AlarmTab extends StatefulWidget {
  const AlarmTab({super.key});

  @override
  State<AlarmTab> createState() => _AlarmTabState();
}

class _AlarmTabState extends State<AlarmTab>
    with SingleTickerProviderStateMixin {
  TimeOfDay _alarm = const TimeOfDay(hour: 3, minute: 33);
  bool _armed = false;
  bool _darthInstalled = false;
  bool _filterActive = false;
  bool _veilUnlocked = false;
  bool _holding = false;
  String? _loadedModelPath;
  String _prompt = '';
  String _reply = '';
  final _pathCtrl = TextEditingController();
  Timer? _beaconPoll;
  late final AnimationController _eyePulse;

  @override
  void initState() {
    super.initState();
    _eyePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _probe();
    _restore();
    _beaconPoll = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _pollBeacon();
    });
    _pollBeacon();
  }

  Future<void> _probe() async {
    final ok = await DarthCherryProbe.isInstalled();
    if (mounted) setState(() => _darthInstalled = ok);
  }

  Future<void> _pollBeacon() async {
    final status = await DarthCherryProbe.probeFilter();
    if (!mounted) return;
    if (status.active != _filterActive) {
      setState(() => _filterActive = status.active);
      // Filter dropped — seal the veil again so secrets don't linger.
      if (!status.active && _veilUnlocked) {
        final p = await SharedPreferences.getInstance();
        await p.setBool('grok_veil_unlocked', false);
        if (mounted) {
          setState(() {
            _veilUnlocked = false;
            _reply = '';
          });
        }
      }
    } else if (status.active && !_filterActive) {
      setState(() => _filterActive = true);
    }
  }

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _loadedModelPath = p.getString('grok_model_path');
      _veilUnlocked = p.getBool('grok_veil_unlocked') ?? false;
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _alarm,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: NoirTheme.matrix,
            surface: NoirTheme.panel,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _alarm = t);
  }

  bool get _eyeVisible => _filterActive || _darthInstalled;

  Future<void> _holdUnlockStart() async {
    if (!_filterActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _darthInstalled
                ? 'ENABLE DARTH CHERRY FILTER, then hold the eye 3s'
                : 'Install DARTH CHERRY, enable FILTER, then hold the eye',
          ),
        ),
      );
      // Re-check install in case package visibility just became available.
      unawaited(_probe());
      return;
    }
    setState(() => _holding = true);
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!_holding || !mounted) return;
    final p = await SharedPreferences.getInstance();
    await p.setBool('grok_veil_unlocked', true);
    HapticFeedback.heavyImpact();
    setState(() {
      _veilUnlocked = true;
      _holding = false;
    });
  }

  void _holdUnlockEnd() => setState(() => _holding = false);

  Future<void> _loadModel(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('grok_model_path', path);
    setState(() {
      _loadedModelPath = path;
      _reply =
          'GRØK-REBEL 6.0 · model path armed:\n$path\n'
          'Wire a local GGUF runtime (llama.cpp / MLX / ExecuTorch) to this path.';
    });
  }

  void _ask() {
    if (_loadedModelPath == null) {
      setState(() => _reply = 'Load a quantized GGUF first.');
      return;
    }
    setState(() {
      _reply =
          '[[ local inference stub ]]\n'
          'Model: $_loadedModelPath\n'
          'Prompt: $_prompt\n\n'
          'Attach your on-device runner to stream tokens here. '
          'This interface will not phone home.';
    });
  }

  @override
  void dispose() {
    _beaconPoll?.cancel();
    _eyePulse.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('ALARM · AEST BRISBANE',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        NeonPanel(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _alarm.format(context),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 42,
                        color: _armed ? NoirTheme.crimson : NoirTheme.matrix,
                      ),
                ),
              ),
              Column(
                children: [
                  OutlinedButton(
                    onPressed: _pickTime,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NoirTheme.matrix,
                      side: const BorderSide(color: NoirTheme.matrix),
                    ),
                    child: const Text('SET'),
                  ),
                  Switch(
                    value: _armed,
                    activeThumbColor: NoirTheme.crimson,
                    onChanged: (v) => setState(() => _armed = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'DARTH CHERRY VEIL',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: NoirTheme.pink,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _filterActive
              ? 'Filter LIVE · hold the eye 3s to open GRØK-REBEL'
              : (_darthInstalled
                  ? 'Companion installed · ENABLE FILTER to reveal the eye'
                  : 'Install DARTH CHERRY, then ENABLE FILTER to reveal the eye'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NoirTheme.mist.withValues(alpha: 0.65),
              ),
        ),
        const SizedBox(height: 14),
        // Eye is only drawn when companion is known or filter beacon is live —
        // matches Polybius cipher eyeball contract.
        if (_eyeVisible)
          Center(
            child: Listener(
              onPointerDown: (_) => _holdUnlockStart(),
              onPointerUp: (_) => _holdUnlockEnd(),
              onPointerCancel: (_) => _holdUnlockEnd(),
              child: FadeTransition(
                opacity: _filterActive
                    ? const AlwaysStoppedAnimation(1)
                    : Tween(begin: 0.18, end: 0.4).animate(_eyePulse),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _VeilEyePainter(
                      active: _filterActive,
                      holding: _holding,
                      unlocked: _veilUnlocked,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          NeonPanel(
            color: NoirTheme.pink,
            child: Center(
              child: Text(
                'EYE SEALED — start DARTH CHERRY filter',
                style: TextStyle(
                  color: NoirTheme.pink.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (_eyeVisible) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              _veilUnlocked
                  ? 'VEIL OPEN · GRØK-REBEL 6.0'
                  : (_holding ? '… REVEALING' : 'HOLD EYE TO REVEAL'),
              style: TextStyle(
                color: _filterActive ? NoirTheme.pink : NoirTheme.mist,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        if (_veilUnlocked && _filterActive) ...[
          const SizedBox(height: 22),
          Text(
            'GRØK-REBEL 6.0',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 26,
                  color: NoirTheme.yellow,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Local uncensored AI loader — quantized GGUF packs. No cloud.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...grokRebelCatalog.map(
            (m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: NeonPanel(
                color: NoirTheme.yellow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: const TextStyle(
                          color: NoirTheme.yellow,
                          fontWeight: FontWeight.w700,
                        )),
                    Text('${m.quant} · ${m.note}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    SelectableText(
                      m.url,
                      style: const TextStyle(
                        color: NoirTheme.cyan,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _loadModel(
                        'models/${m.id}.gguf',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NoirTheme.yellow,
                        side: const BorderSide(color: NoirTheme.yellow),
                      ),
                      child: const Text('ARM DOWNLOAD SLOT'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          NeonPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LOCAL PATH / FILENAME'),
                TextField(
                  controller: _pathCtrl,
                  style: const TextStyle(color: NoirTheme.mist),
                  decoration: const InputDecoration(
                    hintText: '/sdcard/Models/gemma4-heretic-q4.gguf',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _loadModel(
                    _pathCtrl.text.trim().isEmpty
                        ? 'models/custom.gguf'
                        : _pathCtrl.text.trim(),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NoirTheme.matrix,
                    side: const BorderSide(color: NoirTheme.matrix),
                  ),
                  child: const Text('LOAD INTO GRØK-REBEL'),
                ),
                if (_loadedModelPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Loaded: $_loadedModelPath',
                        style: const TextStyle(color: NoirTheme.matrix)),
                  ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => _prompt = v,
                  maxLines: 3,
                  style: const TextStyle(color: NoirTheme.mist),
                  decoration: const InputDecoration(
                    labelText: 'PROMPT',
                    labelStyle: TextStyle(color: NoirTheme.matrix),
                  ),
                ),
                OutlinedButton(
                  onPressed: _ask,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NoirTheme.pink,
                    side: const BorderSide(color: NoirTheme.pink),
                  ),
                  child: const Text('RUN LOCAL'),
                ),
                if (_reply.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(_reply, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _VeilEyePainter extends CustomPainter {
  _VeilEyePainter({
    required this.active,
    required this.holding,
    required this.unlocked,
  });

  final bool active;
  final bool holding;
  final bool unlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final glow = Paint()
      ..color = (holding ? NoirTheme.crimson : NoirTheme.pink)
          .withValues(alpha: active ? 0.35 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.42, glow);

    final lid = Path()
      ..moveTo(cx - size.width * 0.42, cy)
      ..quadraticBezierTo(cx, cy - size.height * 0.38, cx + size.width * 0.42, cy)
      ..quadraticBezierTo(cx, cy + size.height * 0.38, cx - size.width * 0.42, cy)
      ..close();

    canvas.drawPath(
      lid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = active ? NoirTheme.pink : NoirTheme.mist.withValues(alpha: 0.5),
    );
    canvas.drawPath(
      lid,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF0A0508).withValues(alpha: 0.85),
    );

    final pupilColor = unlocked
        ? NoirTheme.matrix
        : (holding ? NoirTheme.crimson : NoirTheme.pink);
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * (holding ? 0.14 : 0.18),
      Paint()..color = pupilColor,
    );
    canvas.drawCircle(
      Offset(cx - size.width * 0.04, cy - size.height * 0.04),
      size.width * 0.04,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    // Triangle frame (Illuminati cue)
    final tri = Path()
      ..moveTo(cx, cy - size.height * 0.46)
      ..lineTo(cx + size.width * 0.46, cy + size.height * 0.38)
      ..lineTo(cx - size.width * 0.46, cy + size.height * 0.38)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = (active ? NoirTheme.matrix : NoirTheme.mist)
            .withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _VeilEyePainter oldDelegate) =>
      active != oldDelegate.active ||
      holding != oldDelegate.holding ||
      unlocked != oldDelegate.unlocked;
}
