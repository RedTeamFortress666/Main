import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/polybius_operator_cards.dart';
import '../theme/noir_theme.dart';
import 'illuminati_eye.dart';

/// Operator identity card — secrets visible only when DARTH CHERRY filter is on.
class OperatorIdentityCard extends StatelessWidget {
  const OperatorIdentityCard({
    super.key,
    required this.card,
    required this.secretsUnlocked,
  });

  final PolybiusOperatorCard card;
  final bool secretsUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NoirTheme.voidBlack,
            secretsUnlocked
                ? const Color(0xFF2A0018)
                : const Color(0xFF12002A),
            const Color(0xFF001018),
          ],
        ),
        border: Border.all(
          color: secretsUnlocked ? NoirTheme.crimson : NoirTheme.neonMagenta,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (secretsUnlocked ? NoirTheme.crimson : NoirTheme.neonCyan)
                .withValues(alpha: 0.22),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IlluminatiEye(size: 72, revealed: secretsUnlocked),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.displayName,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: secretsUnlocked
                            ? NoirTheme.neonMagenta
                            : NoirTheme.neonCyan,
                      ),
                    ),
                    Text(
                      card.username,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                    Text(
                      card.tier.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        letterSpacing: 2,
                        color: secretsUnlocked
                            ? NoirTheme.crimson
                            : NoirTheme.yellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('INVITE', card.inviteCode, NoirTheme.neonCyan),
          if (secretsUnlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '◈ DARTH CHERRY UNLOCKED ◈',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: NoirTheme.crimson,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _row('PASSWORD', card.password, NoirTheme.neonMagenta),
                  _row('BACKUP', card.backupPassword, NoirTheme.orange),
                  _row('PIN', card.pin, NoirTheme.yellow),
                ],
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Enable DARTH CHERRY overlay to reveal credentials',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.copy, size: 14, color: color),
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
          ),
        ],
      ),
    );
  }
}
