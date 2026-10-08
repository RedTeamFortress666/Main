import 'package:flutter/material.dart';

import '../services/cover_apps.dart';
import '../theme/noir_theme.dart';
import '../widgets/matrix_chrome.dart';

/// Public home desk: Proton Mail, F-Droid, Brave, Darth Cherry.
class DeskTab extends StatefulWidget {
  const DeskTab({super.key, this.onOpenRoute});

  final VoidCallback? onOpenRoute;

  @override
  State<DeskTab> createState() => _DeskTabState();
}

class _DeskTabState extends State<DeskTab> {
  final _installed = <String, bool>{};
  String? _busy;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    for (final app in CoverApps.desk) {
      final ok = await CoverApps.isInstalled(app.packageName);
      if (!mounted) return;
      setState(() => _installed[app.packageName] = ok);
    }
  }

  Future<void> _open(CoverApp app) async {
    setState(() => _busy = app.id);
    final ok = await CoverApps.open(app.packageName);
    if (!mounted) return;
    setState(() => _busy = null);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${app.blurb} offline — drop the APK.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('DESK · FOUR APPS', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          'Mail, catalogue, browser, Cherry. Adapt the rest through F-Droid.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NoirTheme.mist.withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 14),
        ...CoverApps.desk.map((app) {
          final ready = _installed[app.packageName];
          final spinning = _busy == app.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: spinning ? null : () => _open(app),
              child: NeonPanel(
                color: app.id == 'cherry'
                    ? NoirTheme.crimson
                    : app.id == 'brave'
                        ? NoirTheme.orange
                        : NoirTheme.matrix,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.label,
                            style: const TextStyle(
                              letterSpacing: 3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            app.blurb,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      spinning
                          ? '…'
                          : ready == true
                              ? 'OPEN'
                              : ready == false
                                  ? 'MISSING'
                                  : '…',
                      style: TextStyle(
                        color: ready == false
                            ? NoirTheme.crimson
                            : NoirTheme.matrix,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        InkWell(
          onTap: widget.onOpenRoute,
          child: const NeonPanel(
            color: NoirTheme.cyan,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ROUTE',
                    style: TextStyle(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text('DNS · IP · PRINT', style: TextStyle(letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
