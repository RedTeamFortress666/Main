import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/polybius_operator_cards.dart';
import '../services/qr_card_codec.dart';
import '../theme/noir_theme.dart';

class QrShareSheet extends StatelessWidget {
  const QrShareSheet({super.key, required this.card});

  final PolybiusOperatorCard card;

  static Future<void> show(BuildContext context, PolybiusOperatorCard card) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: NoirTheme.panel,
      isScrollControlled: true,
      builder: (_) => QrShareSheet(card: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = QrCardCodec.encode(card);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SHARE · ${card.username}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: NoirTheme.neonMagenta,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan with DOØMSDAY CLØCK vault open. '
              'Credentials reveal under DARTH CHERRY.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NoirTheme.mist.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              payload,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: NoirTheme.chrome,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
