import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';

class PoolTab extends ConsumerWidget {
  const PoolTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(cipherEngineProvider);
    final pool = engine.pool;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'DAILY POOL — $today',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonCyan,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${pool.length} / ${AppConstants.poolSize} emojis active',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Pool seed: ${DailyPool().dateKey}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonGreen,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              childAspectRatio: 1,
            ),
            itemCount: pool.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: index < AppConstants.halfPool
                        ? NeonTheme.neonCyan.withValues(alpha: 0.3)
                        : NeonTheme.neonPink.withValues(alpha: 0.3),
                  ),
                  color: NeonTheme.surface,
                ),
                child: Center(
                  child: Text(
                    pool[index],
                    style: const TextStyle(fontSize: 18),
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
