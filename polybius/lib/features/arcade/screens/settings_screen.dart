import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('SETTINGS', style: TextStyle(fontFamily: 'monospace')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeonTheme.neonCyan),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DIFFICULTY: ${settings.difficulty}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Slider(
              value: settings.difficulty.toDouble(),
              min: 1,
              max: 11,
              divisions: 10,
              label: '${settings.difficulty}',
              onChanged: (v) {
                ref.read(gameSettingsProvider.notifier).update(
                      settings.copyWith(difficulty: v.round()),
                    );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'LANGUAGE',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.supportedLanguages.map((lang) {
                final selected = settings.language == lang;
                return ChoiceChip(
                  label: Text(lang, style: const TextStyle(fontFamily: 'monospace')),
                  selected: selected,
                  selectedColor: NeonTheme.neonPink.withValues(alpha: 0.3),
                  onSelected: (_) {
                    ref.read(gameSettingsProvider.notifier).update(
                          settings.copyWith(language: lang),
                        );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('CRT INTENSITY', style: TextStyle(color: NeonTheme.neonGreen)),
                Expanded(
                  child: Slider(
                    value: settings.crtIntensity,
                    onChanged: (v) {
                      ref.read(gameSettingsProvider.notifier).update(
                            settings.copyWith(crtIntensity: v),
                          );
                    },
                  ),
                ),
              ],
            ),
            const Spacer(),
            NeonButton(
              label: 'SAVE & RETURN',
              onPressed: () {
                ref.read(unlockProvider.notifier).checkDifficultyRitual(settings);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
