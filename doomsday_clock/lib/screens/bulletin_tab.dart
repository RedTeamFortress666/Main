import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/bulletin_service.dart';
import '../theme/noir_theme.dart';

class BulletinTab extends StatefulWidget {
  const BulletinTab({super.key});

  @override
  State<BulletinTab> createState() => _BulletinTabState();
}

class _BulletinTabState extends State<BulletinTab>
    with SingleTickerProviderStateMixin {
  final _service = BulletinService();
  BulletinSnapshot? _snap;
  String? _error;
  bool _loading = true;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _refresh();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _service.load(forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _snap = snap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snap;
    return RefreshIndicator(
      color: NoirTheme.cyan,
      onRefresh: () => _refresh(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('BULLETIN OF THE ATOMIC SCIENTISTS',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          if (_loading && snap == null)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (snap != null) ...[
            FadeTransition(
              opacity: Tween(begin: 0.55, end: 1.0).animate(_pulse),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: NoirTheme.crimson.withValues(alpha: 0.55)),
                  gradient: LinearGradient(
                    colors: [
                      NoirTheme.crimson.withValues(alpha: 0.18),
                      NoirTheme.panel,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snap.headline,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: NoirTheme.crimson,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snap.minutesLabel.toUpperCase(),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 36,
                            color: NoirTheme.mist,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'to midnight',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: NoirTheme.amber,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('NEWS ANALYSIS', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(snap.summary, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(
              'Source: ${snap.sourceUrl}\n'
              'Fetched: ${DateFormat.yMMMd().add_jm().format(snap.fetchedAt)}'
              '${snap.fromNetwork ? ' · live digest' : ' · cached / baseline'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NoirTheme.mist.withValues(alpha: 0.55),
                  ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: NoirTheme.crimson)),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => _refresh(force: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: NoirTheme.cyan,
              side: const BorderSide(color: NoirTheme.cyan),
            ),
            child: const Text('REFRESH DAILY BULLETIN'),
          ),
        ],
      ),
    );
  }
}
