import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/operator_card.dart';
import '../theme/noir_theme.dart';

class OperatorCardView extends StatelessWidget {
  const OperatorCardView({
    super.key,
    required this.card,
    required this.secretsUnlocked,
    this.onShareQr,
    this.onDelete,
  });

  final OperatorCard card;
  final bool secretsUnlocked;
  final VoidCallback? onShareQr;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NoirTheme.voidBlack,
        border: Border.all(
          color: secretsUnlocked ? NoirTheme.crimson : NoirTheme.neonMagenta,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: secretsUnlocked
                            ? NoirTheme.neonMagenta
                            : NoirTheme.neonCyan,
                      ),
                    ),
                    Text(
                      card.username,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                    Text(
                      card.tier.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: NoirTheme.amber,
                      ),
                    ),
                  ],
                ),
              ),
              if (onShareQr != null)
                IconButton(
                  tooltip: 'Share QR',
                  onPressed: onShareQr,
                  icon: const Icon(Icons.qr_code, color: NoirTheme.neonCyan),
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: NoirTheme.crimson),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _row('INVITE', secretsUnlocked ? card.inviteCode : '••••••••', NoirTheme.neonCyan),
          _row(
            'PASSWORD',
            secretsUnlocked ? card.password : '••••••••',
            NoirTheme.neonMagenta,
            copyable: secretsUnlocked,
          ),
          _row(
            'BACKUP',
            secretsUnlocked ? card.backupPassword : '••••••••',
            NoirTheme.amber,
            copyable: secretsUnlocked,
          ),
          _row(
            'PIN',
            secretsUnlocked ? card.pin : '••••••••',
            NoirTheme.yellow,
            copyable: secretsUnlocked,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool copyable = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.85)),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Copy $label',
              icon: Icon(Icons.copy, size: 14, color: color),
              onPressed: () => Clipboard.setData(ClipboardData(text: value)),
            ),
        ],
      ),
    );
  }
}
