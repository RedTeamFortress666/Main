import 'package:flutter/material.dart';

import '../../core/models/abliterated_model.dart';
import '../../core/theme/shadow_theme.dart';

class ModelTile extends StatelessWidget {
  const ModelTile({
    super.key,
    required this.model,
    this.onBind,
  });

  final AbliteratedModel model;
  final VoidCallback? onBind;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.displayName,
                    style: const TextStyle(
                      color: ShadowTheme.neonGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (model.isDownloaded)
                  const Icon(Icons.check_circle, color: ShadowTheme.neonGreen, size: 18)
                else if (model.inTargetRange)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: ShadowTheme.neonAmber),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '2–6 GB',
                      style: TextStyle(fontSize: 10, color: ShadowTheme.neonAmber),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${model.family} · ${model.quant} · ${model.sizeLabel}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (model.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: model.tags
                    .map(
                      (t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 10)),
                        backgroundColor: ShadowTheme.surface,
                        side: BorderSide(
                          color: ShadowTheme.neonPurple.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (model.localPath.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                model.localPath,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onBind != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onBind,
                  icon: const Icon(Icons.link, size: 16),
                  label: Text(model.isDownloaded ? 'REBIND' : 'BIND GGUF'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
