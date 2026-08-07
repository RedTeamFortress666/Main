import 'package:flutter/material.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Shown during app bootstrap and session restore.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: NeonTheme.neonCyan,
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(NeonTheme.neonPink),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'INITIALIZING TERMINAL...',
              style: TextStyle(
                color: Colors.white38,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
