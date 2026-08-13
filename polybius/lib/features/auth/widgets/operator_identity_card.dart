import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polybius/core/constants/operator_identities.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/matrix_illuminati_eye.dart';

/// Operator identity card.
///
/// Without Darth Cherry: neon Illuminati eye + username + invite / game-file code.
/// With Darth Cherry active: also reveals password, backup password, and PIN.
class OperatorIdentityCard extends StatelessWidget {
  const OperatorIdentityCard({
    super.key,
    required this.identity,
    required this.secretsUnlocked,
  });

  final OperatorIdentity identity;
  final bool secretsUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A1628),
            secretsUnlocked
                ? const Color(0xFF2A0510)
                : const Color(0xFF120028),
            const Color(0xFF051a12),
          ],
        ),
        border: Border.all(
          color: secretsUnlocked ? NeonTheme.dangerRed : NeonTheme.neonGreen,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (secretsUnlocked ? NeonTheme.dangerRed : NeonTheme.neonCyan)
                .withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MatrixIlluminatiEye(size: 88, revealed: secretsUnlocked),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity.displayName,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: secretsUnlocked
                            ? NeonTheme.neonPink
                            : NeonTheme.neonCyan,
                        shadows: [
                          Shadow(
                            color: NeonTheme.neonGreen.withValues(alpha: 0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      identity.username,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      identity.tier.name.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: secretsUnlocked
                            ? NeonTheme.dangerRed
                            : NeonTheme.neonYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FieldRow(
            label: 'INVITE / FILE',
            value: identity.inviteOrFileCode,
            color: NeonTheme.neonGreen,
          ),
          if (secretsUnlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                border: Border.all(color: NeonTheme.dangerRed.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '◈ DARTH CHERRY UNLOCKED ◈',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: NeonTheme.dangerRed,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FieldRow(
                    label: 'PASSWORD',
                    value: identity.password,
                    color: NeonTheme.neonPink,
                  ),
                  const SizedBox(height: 6),
                  _FieldRow(
                    label: 'BACKUP PW',
                    value: identity.backupPassword,
                    color: NeonTheme.neonOrange,
                  ),
                  const SizedBox(height: 6),
                  _FieldRow(
                    label: 'PIN',
                    value: identity.pin,
                    color: NeonTheme.neonYellow,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              'Enable DARTH CHERRY overlay to reveal credentials',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.white38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.copy, size: 16, color: color),
          onPressed: () => Clipboard.setData(ClipboardData(text: value)),
        ),
      ],
    );
  }
}
