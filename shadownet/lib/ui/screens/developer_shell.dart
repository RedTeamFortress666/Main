import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/shadow_theme.dart';
import 'connect_points_screen.dart';
import 'dashboard_screen.dart';
import 'inference_screen.dart';
import 'model_vault_screen.dart';
import 'qshield_panel_screen.dart';

class DeveloperShell extends StatefulWidget {
  const DeveloperShell({super.key});

  @override
  State<DeveloperShell> createState() => _DeveloperShellState();
}

class _DeveloperShellState extends State<DeveloperShell> {
  int _index = 0;

  static const _tabs = [
    _Tab('MESH', Icons.hub_outlined),
    _Tab('MODELS', Icons.storage_outlined),
    _Tab('CONNECT', Icons.link_outlined),
    _Tab('QSHIELD', Icons.security_outlined),
    _Tab('BRIDGE', Icons.bolt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const ModelVaultScreen(),
      const ConnectPointsScreen(),
      const QShieldPanelScreen(),
      const InferenceScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'SHADØWNET',
              style: TextStyle(
                color: ShadowTheme.neonCyan,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: ShadowTheme.neonPurple.withValues(alpha: 0.8),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: ShadowTheme.qshieldBlue),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'QSHIELD',
                style: TextStyle(
                  fontSize: 10,
                  color: ShadowTheme.qshieldBlue,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: ShadowTheme.surface,
        indicatorColor: ShadowTheme.neonPurple.withValues(alpha: 0.3),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon, color: ShadowTheme.neonGreen),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon);
  final String label;
  final IconData icon;
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DeveloperShell(),
    ),
  ],
);
