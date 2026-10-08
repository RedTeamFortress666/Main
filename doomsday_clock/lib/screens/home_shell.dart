import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/noir_theme.dart';
import '../widgets/doomsday_logo.dart';
import '../widgets/matrix_chrome.dart';
import 'alarm_tab.dart';
import 'auth_gate.dart';
import 'bulletin_tab.dart';
import 'clock_tab.dart';
import 'planner_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AuthSession? _session;
  bool _vaultSetupPending = false;
  int _index = 0;

  void _onAuth(AuthSession session, {required bool needsVaultSetup}) {
    setState(() {
      _session = session;
      _vaultSetupPending = needsVaultSetup;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return AuthGate(onAuthenticated: _onAuth);
    }
    if (_vaultSetupPending) {
      return VaultSetupScreen(
        session: _session!,
        onDone: () => setState(() => _vaultSetupPending = false),
      );
    }

    final pages = [
      const BulletinTab(),
      const ClockTab(),
      PlannerTab(session: _session!),
      const AlarmTab(),
    ];

    return MatrixRainBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const DoomsdayLogo(size: 52, showWordmark: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOOMSDAY CLOCK 2.0',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  fontSize: 20,
                                  shadows: [
                                    Shadow(
                                      color: NoirTheme.matrix
                                          .withValues(alpha: 0.45),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                          ),
                          Text(
                            '${_session!.displayName} · ${_session!.tier} · BNE AEST',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: NoirTheme.pink),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Logout',
                      onPressed: () async {
                        await AuthService().logout();
                        setState(() {
                          _session = null;
                          _vaultSetupPending = false;
                        });
                      },
                      icon: const Icon(Icons.logout, color: NoirTheme.crimson),
                    ),
                  ],
                ),
              ),
              Expanded(child: pages[_index]),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: NoirTheme.panel,
          indicatorColor: NoirTheme.matrix.withValues(alpha: 0.2),
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article),
              label: 'Bulletin',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Clock',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Planner',
            ),
            NavigationDestination(
              icon: Icon(Icons.alarm_outlined),
              selectedIcon: Icon(Icons.alarm),
              label: 'Alarm',
            ),
          ],
        ),
      ),
    );
  }
}
