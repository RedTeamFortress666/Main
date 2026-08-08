import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/app.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();
}

Future<void> _bootstrap() async {
  final container = ProviderContainer();
  try {
    await container.read(encryptionServiceProvider).init();
    await container.read(storageServiceProvider).init();
  } catch (error, stackTrace) {
    container.dispose();
    if (kDebugMode) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
    runApp(_BootstrapErrorApp(error: error, onRetry: _bootstrap));
    return;
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PolybiusApp(),
    ),
  );
}

/// Shown when core services (encryption/storage) fail to initialize, so the
/// user gets an actionable error instead of a blank screen.
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.dark,
      home: Scaffold(
        backgroundColor: NeonTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: NeonTheme.dangerRed, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'TERMINAL FAILED TO START',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.dangerRed,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Secure storage could not be initialized on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeonTheme.neonPink,
                  ),
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
