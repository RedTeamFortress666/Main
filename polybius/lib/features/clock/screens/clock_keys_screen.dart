import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/crypto/unpredictable_shift.dart';
import 'package:polybius/core/widgets/floating_glyph_keyboard.dart';
import 'package:polybius/features/clock/clock_session.dart';
import 'package:polybius/features/clock/screens/keyboard_qr_scan_screen.dart';
import 'package:polybius/features/clock/session_binary_key.dart';

/// Glyph keys reached by a double-tap on SLEEP.
class ClockKeysScreen extends ConsumerWidget {
  const ClockKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(clockSessionProvider).unlocked;
    if (!unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/clock');
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF140008),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    PolybiusSquareGlyphs.phrase,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFFF2A4D),
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('keyboard-scan'),
                    onPressed: () {
                      final key = ref.read(clockSessionProvider).sessionKey;
                      if (key == null || !SessionBinaryKey.isValid(key)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('NEED SESSION KEY')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => KeyboardQrScanScreen(sessionKey: key),
                        ),
                      );
                    },
                    child: const Text('SCAN'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/clock/desk'),
                    child: const Text('CHERRY'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Expanded(child: FloatingGlyphKeyboard()),
            ],
          ),
        ),
      ),
    );
  }
}
