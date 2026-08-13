import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/arcade_ui.dart';

enum _Page { menu, controls, languages, difficulty, credits }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _Page _page = _Page.menu;
  Timer? _holdTimer;
  bool _holdingSelect = false;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _go(_Page p) => setState(() => _page = p);

  @override
  Widget build(BuildContext context) {
    return ArcadeScaffold(
      accent: NeonTheme.neonPink,
      child: Column(
        children: [
          const SizedBox(height: 6),
          const ArcadeTitle(fontSize: 32),
          const SizedBox(height: 18),
          ArcadeHeading(_title),
          const SizedBox(height: 18),
          Expanded(child: _buildPage()),
          ArcadeMenuButton(
            label: 'BACK',
            color: NeonTheme.neonPink,
            dense: true,
            onPressed: () =>
                _page == _Page.menu ? context.pop() : _go(_Page.menu),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String get _title => switch (_page) {
        _Page.menu => 'SETTINGS',
        _Page.controls => 'CONTROLS',
        _Page.languages => 'LANGUAGES',
        _Page.difficulty => 'DIFFICULTY',
        _Page.credits => 'CREDITS',
      };

  Widget _buildPage() => switch (_page) {
        _Page.menu => _menu(),
        _Page.controls => _controls(),
        _Page.languages => _languages(),
        _Page.difficulty => _difficulty(),
        _Page.credits => _credits(),
      };

  Widget _menu() {
    return Column(
      children: [
        ArcadeMenuButton(
          label: 'CONTROLS',
          color: NeonTheme.neonCyan,
          dense: true,
          onPressed: () => _go(_Page.controls),
        ),
        ArcadeMenuButton(
          label: 'LANGUAGES',
          color: NeonTheme.neonCyan,
          dense: true,
          onPressed: () => _go(_Page.languages),
        ),
        ArcadeMenuButton(
          label: 'HIGH-SCORES',
          color: NeonTheme.neonCyan,
          dense: true,
          onPressed: () => context.push('/highscore'),
        ),
        ArcadeMenuButton(
          label: 'DIFFICULTY',
          color: NeonTheme.neonCyan,
          dense: true,
          onPressed: () => _go(_Page.difficulty),
        ),
        ArcadeMenuButton(
          label: 'CREDITS',
          color: NeonTheme.neonCyan,
          dense: true,
          onPressed: () => _go(_Page.credits),
        ),
      ],
    );
  }

  Widget _controls() {
    final settings = ref.watch(gameSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CRT INTENSITY',
            style: TextStyle(color: NeonTheme.neonGreen, fontFamily: 'monospace')),
        Slider(
          value: settings.crtIntensity,
          onChanged: (v) => ref
              .read(gameSettingsProvider.notifier)
              .update(settings.copyWith(crtIntensity: v)),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: settings.soundEnabled,
          activeThumbColor: NeonTheme.neonCyan,
          contentPadding: EdgeInsets.zero,
          title: const Text('SOUND',
              style:
                  TextStyle(color: NeonTheme.neonGreen, fontFamily: 'monospace')),
          onChanged: (v) => ref
              .read(gameSettingsProvider.notifier)
              .update(settings.copyWith(soundEnabled: v)),
        ),
      ],
    );
  }

  Widget _difficulty() {
    final settings = ref.watch(gameSettingsProvider);
    // Choices 1-10, plus a blank square that represents the hidden "11".
    return Column(
      children: [
        const Text(
          'SELECT DIFFICULTY',
          style: TextStyle(
            color: Colors.white54,
            fontFamily: 'monospace',
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (var n = 1; n <= 10; n++)
              _DiffCell(
                label: '$n',
                selected: settings.difficulty == n,
                onTap: () => _setDifficulty(n),
              ),
            // Blank square = difficulty 11.
            _DiffCell(
              label: '',
              selected: settings.difficulty == 11,
              onTap: () => _setDifficulty(11),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'CURRENT: ${settings.difficulty}',
          style: const TextStyle(
            color: NeonTheme.neonYellow,
            fontFamily: 'monospace',
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  void _setDifficulty(int n) {
    final settings = ref.read(gameSettingsProvider);
    ref
        .read(gameSettingsProvider.notifier)
        .update(settings.copyWith(difficulty: n));
  }

  Widget _languages() {
    final settings = ref.watch(gameSettingsProvider);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final lang in AppConstants.supportedLanguages)
                  ChoiceChip(
                    label: Text(lang,
                        style: const TextStyle(fontFamily: 'monospace')),
                    selected: settings.language == lang,
                    selectedColor: NeonTheme.neonPink.withValues(alpha: 0.3),
                    onSelected: (_) => ref
                        .read(gameSettingsProvider.notifier)
                        .update(settings.copyWith(language: lang)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Hold-to-select confirms the language. Portal entry is the GAME OVER
        // ritual after LOAD GAME + difficulty 11 + flavor ritual language.
        GestureDetector(
          onLongPressStart: (_) => _startSelectHold(),
          onLongPressEnd: (_) => _endSelectHold(),
          onLongPressCancel: _endSelectHold,
          onTap: () => _endSelectHold(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: _holdingSelect
                    ? NeonTheme.neonYellow
                    : NeonTheme.neonGreen,
                width: _holdingSelect ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_holdingSelect
                          ? NeonTheme.neonYellow
                          : NeonTheme.neonGreen)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              _holdingSelect ? 'HOLD...' : 'SELECT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                letterSpacing: 4,
                fontSize: 18,
                color: _holdingSelect
                    ? NeonTheme.neonYellow
                    : NeonTheme.neonGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startSelectHold() {
    setState(() => _holdingSelect = true);
    _holdTimer = Timer(
      const Duration(milliseconds: AppConstants.langSelectHoldMs),
      _completeSelectHold,
    );
  }

  void _endSelectHold() {
    setState(() => _holdingSelect = false);
    _holdTimer?.cancel();
  }

  void _completeSelectHold() {
    if (!_holdingSelect) return;
    setState(() => _holdingSelect = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('LANGUAGE SET'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _credits() {
    return const Center(
      child: Text(
        'PØLYBĪUS\n\nSINNESLÖSCHEN CORP\n\nA covert arcade experiment.\n'
        'All resemblance to real programs\nis purely coincidental.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'monospace',
          color: NeonTheme.neonCyan,
          height: 1.8,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _DiffCell extends StatelessWidget {
  const _DiffCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? NeonTheme.neonYellow : NeonTheme.neonCyan;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.18 : 0.03),
          border: Border.all(color: color, width: selected ? 2.5 : 1.5),
          boxShadow: [
            if (selected)
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            color: color,
          ),
        ),
      ),
    );
  }
}
