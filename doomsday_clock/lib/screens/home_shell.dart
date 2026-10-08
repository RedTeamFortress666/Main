import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/noir_theme.dart';
import '../widgets/doomsday_logo.dart';
import '../widgets/matrix_chrome.dart';
import 'alarm_tab.dart';
import 'auth_gate.dart';
import 'bulletin_tab.dart';
import 'clock_tab.dart';
import 'desk_tab.dart';
import 'planner_tab.dart';
import 'route_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AuthSession? _session;
  bool _vaultSetupPending = false;
  bool _showLogin = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final s = await AuthService().currentSession();
    if (s == null || !mounted) return;
    final needs = await AuthService().needsVaultSetup(s.username);
    setState(() {
      _session = s;
      _vaultSetupPending = needs;
    });
  }

  void _onAuth(AuthSession session, {required bool needsVaultSetup}) {
    setState(() {
      _session = session;
      _vaultSetupPending = needsVaultSetup;
      _showLogin = false;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin && _session == null) {
      return AuthGate(
        onAuthenticated: _onAuth,
        onCancel: () => setState(() => _showLogin = false),
      );
    }
    if (_session != null && _vaultSetupPending) {
      return VaultSetupScreen(
        session: _session!,
        onDone: () => setState(() => _vaultSetupPending = false),
      );
    }

    final operator = _session != null;
    final pages = operator
        ? <Widget>[
            DeskTab(onOpenRoute: () => setState(() => _index = 1)),
            const RouteTab(),
            const BulletinTab(),
            PlannerTab(session: _session!),
            const AlarmTab(),
          ]
        : <Widget>[
            DeskTab(onOpenRoute: () => setState(() => _index = 1)),
            const RouteTab(),
            const ClockTab(),
          ];

    final destinations = operator
        ? const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Desk',
            ),
            NavigationDestination(
              icon: Icon(Icons.alt_route_outlined),
              selectedIcon: Icon(Icons.alt_route),
              label: 'Route',
            ),
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article),
              label: 'Bulletin',
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
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Desk',
            ),
            NavigationDestination(
              icon: Icon(Icons.alt_route_outlined),
              selectedIcon: Icon(Icons.alt_route),
              label: 'Route',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Clock',
            ),
          ];

    if (_index >= pages.length) {
      _index = 0;
    }

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
                            'CRYPT3X OS',
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
                            operator
                                ? '${_session!.displayName} · ${_session!.tier} · BNE AEST'
                                : 'DESK · MAIL / F-DROID / BRAVE / CHERRY',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: NoirTheme.pink),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: operator ? 'Logout' : 'Operator vault',
                      onPressed: () async {
                        if (operator) {
                          await AuthService().logout();
                          setState(() {
                            _session = null;
                            _vaultSetupPending = false;
                            _index = 0;
                          });
                        } else {
                          setState(() => _showLogin = true);
                        }
                      },
                      icon: Icon(
                        operator ? Icons.logout : Icons.lock_outline,
                        color: NoirTheme.crimson,
                      ),
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
          destinations: destinations,
        ),
      ),
    );
  }
}
