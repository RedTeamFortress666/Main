import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/auth/v2_login_protocol.dart';

/// CRT handshake readout for the V2 login protocol.
class V2ProtocolConsole extends StatelessWidget {
  const V2ProtocolConsole({
    super.key,
    required this.log,
    this.visibleLines,
    this.preview = false,
  });

  final V2HandshakeLog log;
  final int? visibleLines;

  /// Dim six-step legend before a handshake starts.
  final bool preview;

  static const legend = <(String, String)>[
    ('01', 'CHALLENGE'),
    ('02', 'VERIFY'),
    ('03', 'TICKET'),
    ('04', 'LEAK SWEEP'),
    ('05', 'AUTOPATCH'),
    ('06', 'CABINET'),
  ];

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
        color: Colors.black.withValues(alpha: 0.72),
        border: Border.all(color: NeonTheme.neonGreen.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: NeonTheme.neonGreen.withValues(alpha: 0.22),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: log.ok ? NeonTheme.neonGreen : NeonTheme.neonYellow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NeonTheme.neonGreen.withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${V2LoginProtocol.name}  PROTOCOL',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonGreen,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (preview && shown.isEmpty)
            for (final step in legend)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '  ${step.$1} ${step.$2.padRight(12, '.')} WAIT',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              )
          else
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
                    shadows: [
                      Shadow(
                        color: NeonTheme.neonCyan.withValues(alpha: 0.35),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
