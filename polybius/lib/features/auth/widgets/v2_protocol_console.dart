import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/auth/v2_login_protocol.dart';

/// CRT handshake readout for the V2 login protocol.
class V2ProtocolConsole extends StatelessWidget {
  const V2ProtocolConsole({
    super.key,
    required this.log,
    this.visibleLines,
  });

  final V2HandshakeLog log;
  final int? visibleLines;

  @override
  Widget build(BuildContext context) {
    final lines = log.lines;
    final shown = visibleLines == null
        ? lines
        : lines.take(visibleLines!.clamp(0, lines.length)).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: NeonTheme.neonGreen.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${V2LoginProtocol.name}  PROTOCOL',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonGreen,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '  ${line.code} ${line.label.padRight(12, '.')} ${line.status}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: line.status.contains('DENIED') ||
                          line.status.contains('HOLD')
                      ? NeonTheme.dangerRed
                      : NeonTheme.neonCyan,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
