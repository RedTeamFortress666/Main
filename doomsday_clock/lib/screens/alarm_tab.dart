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

class _AlarmTabState extends State<AlarmTab> {
  TimeOfDay _alarm = const TimeOfDay(hour: 3, minute: 33);
  bool _armed = false;
  bool _darthInstalled = false;
  bool _veilUnlocked = false;
  bool _holding = false;
  String? _loadedModelPath;
  String _prompt = '';
  String _reply = '';
  final _pathCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _probe();
    _restore();
  }

  Future<void> _probe() async {
    final ok = await DarthCherryProbe.isInstalled();
    if (mounted) setState(() => _darthInstalled = ok);
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

  Future<void> _holdUnlockStart() async {
    if (!_darthInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'DARTH CHERRY (com.polybius.red_veil) required — install & ENABLE FILTER',
          ),
        ),
      );
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
          _darthInstalled
              ? 'Companion detected · hold the eye 3s with FILTER enabled'
              : 'Install DARTH CHERRY to reveal the hidden AI interface',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NoirTheme.mist.withValues(alpha: 0.65),
              ),
        ),
        const SizedBox(height: 10),
        Listener(
          onPointerDown: (_) => _holdUnlockStart(),
          onPointerUp: (_) => _holdUnlockEnd(),
          onPointerCancel: (_) => _holdUnlockEnd(),
          child: NeonPanel(
            color: NoirTheme.pink,
            child: Center(
              child: Text(
                _veilUnlocked
                    ? 'VEIL OPEN · GRØK-REBEL 6.0'
                    : (_holding ? '… REVEALING' : 'HOLD EYE TO REVEAL'),
                style: TextStyle(
                  color: NoirTheme.pink,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: NoirTheme.pink.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_veilUnlocked) ...[
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
