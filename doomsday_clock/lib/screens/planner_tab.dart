import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/polybius_operator_cards.dart';
import '../models/models.dart';
import '../services/darth_probe.dart';
import '../services/auth_service.dart';
import '../services/planner_service.dart';
import '../theme/noir_theme.dart';
import '../widgets/matrix_chrome.dart';
import '../widgets/operator_identity_card.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key, required this.session});

  final AuthSession session;

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  final _planner = PlannerService();
  final _noteCtrl = TextEditingController();
  DateTime _selected = DateTime.now();
  List<PlannerNote> _notes = [];
  bool _cherryCacheOpen = false;
  bool _darthActive = false;
  bool _darthInstalled = false;
  String _holdLabel = 'SAVE NOTE';
  bool _holding = false;
  double _holdProgress = 0;
  Timer? _holdTimer;
  Timer? _darthPoll;

  bool get _isGam3on =>
      PolybiusOperatorCards.canOpenCherryCache(widget.session.username);

  @override
  void initState() {
    super.initState();
    _reload();
    _pollDarth();
    _darthPoll = Timer.periodic(const Duration(seconds: 2), (_) => _pollDarth());
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _darthPoll?.cancel();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pollDarth() async {
    final installed = await DarthCherryProbe.isInstalled();
    final filter = await DarthCherryProbe.probeFilter();
    if (!mounted) return;
    setState(() {
      _darthInstalled = installed;
      _darthActive = filter.active;
    });
  }

  Future<void> _reload() async {
    final notes = await _planner.loadNotes();
    final open = await _planner.isCherryCacheOpenForDay(
      widget.session.username,
      _selected,
    );
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _cherryCacheOpen = open;
      _holdLabel = open ? 'CACHE OPEN' : 'SAVE NOTE';
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: NoirTheme.neonCyan,
            surface: NoirTheme.panel,
            onSurface: NoirTheme.mist,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selected = picked);
      await _reload();
    }
  }

  void _onHoldStart() {
    if (_holding) return;
    setState(() {
      _holding = true;
      _holdProgress = 0;
      _holdLabel = 'HOLD…';
    });
    const steps = 30;
    var tick = 0;
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (t) async {
      tick++;
      if (!mounted) return;
      setState(() => _holdProgress = tick / steps);
      if (tick < steps) return;
      t.cancel();
      await _completeHold();
    });
  }

  Future<void> _completeHold() async {
    final body = _noteCtrl.text.trim();
    final note = PlannerNote(
      id: _planner.newId(),
      dayKey: _planner.dayKey(_selected),
      body: body.isEmpty ? '(empty note)' : body,
      updatedAt: DateTime.now(),
    );
    final notes = [..._notes, note];
    await _planner.saveNotes(notes);

    var unlocked = _cherryCacheOpen;
    if (_planner.matchesRitual(body, _selected)) {
      await _planner.unlockCherryCacheForDay(
        widget.session.username,
        _selected,
      );
      unlocked = true;
      HapticFeedback.heavyImpact();
    }

    if (!mounted) return;
    setState(() {
      _notes = notes;
      _cherryCacheOpen = unlocked;
      _holding = false;
      _holdProgress = 0;
      _holdLabel = unlocked ? 'CACHE OPEN' : 'SAVE NOTE';
    });
  }

  void _onHoldEnd() {
    if (!_holding) return;
    _holdTimer?.cancel();
    setState(() {
      _holding = false;
      _holdProgress = 0;
      _holdLabel = _cherryCacheOpen ? 'CACHE OPEN' : 'SAVE NOTE';
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = _planner.dayKey(_selected);
    final dayNotes = _notes.where((n) => n.dayKey == dayKey);
    final showCherrySection = _cherryCacheOpen && _isGam3on;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('CYBER PLANNER', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        NeonPanel(
          color: NoirTheme.neonMagenta,
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  setState(
                    () => _selected = _selected.subtract(const Duration(days: 1)),
                  );
                  await _reload();
                },
                icon: const Icon(Icons.chevron_left, color: NoirTheme.neonCyan),
              ),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE').format(_selected).toUpperCase(),
                        style: TextStyle(
                          color: _planner.isGunpowderDay(_selected)
                              ? NoirTheme.crimson
                              : NoirTheme.neonMagenta,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM yyyy').format(_selected),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text(
                        'TAP TO JUMP DATE',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 2,
                          color: NoirTheme.chrome,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  setState(
                    () => _selected = _selected.add(const Duration(days: 1)),
                  );
                  await _reload();
                },
                icon: const Icon(Icons.chevron_right, color: NoirTheme.neonCyan),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteCtrl,
          maxLines: 5,
          style: const TextStyle(color: NoirTheme.mist),
          decoration: InputDecoration(
            hintText: _planner.plannerHintFor(_selected),
            hintStyle: TextStyle(color: NoirTheme.mist.withValues(alpha: 0.35)),
            filled: true,
            fillColor: NoirTheme.voidBlack,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: NoirTheme.neonCyan.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: NoirTheme.neonMagenta, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Listener(
          onPointerDown: (_) => _onHoldStart(),
          onPointerUp: (_) => _onHoldEnd(),
          onPointerCancel: (_) => _onHoldEnd(),
          child: NeonPanel(
            color: _cherryCacheOpen ? NoirTheme.peace : NoirTheme.neonCyan,
            child: Column(
              children: [
                if (_holding)
                  LinearProgressIndicator(
                    value: _holdProgress,
                    backgroundColor: NoirTheme.voidBlack,
                    color: NoirTheme.neonMagenta,
                    minHeight: 3,
                  ),
                const SizedBox(height: 8),
                Text(
                  _holdLabel,
                  style: TextStyle(
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                    color: _cherryCacheOpen
                        ? NoirTheme.peace
                        : NoirTheme.neonCyan,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('NOTES · $dayKey', style: Theme.of(context).textTheme.labelLarge),
        ...dayNotes.map((n) => Text('• ${n.body}')),
        if (showCherrySection) ...[
          const SizedBox(height: 20),
          Text(
            'DARTH CHERRY · OPERATOR CACHE',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _darthActive ? NoirTheme.crimson : NoirTheme.chrome,
                ),
          ),
          const SizedBox(height: 6),
          if (!_darthInstalled)
            Text(
              'Install DARTH CHERRY companion to view sealed credentials.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NoirTheme.amber,
                  ),
            )
          else if (!_darthActive)
            Text(
              'Enable the DARTH CHERRY red filter overlay to reveal passwords, '
              'backup keys, and PINs.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NoirTheme.amber,
                  ),
            )
          else
            Text(
              '${PolybiusOperatorCards.all.length} PØLYBÎŪS operator cards · '
              'secrets unlocked',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NoirTheme.peace,
                  ),
            ),
          const SizedBox(height: 10),
          ...PolybiusOperatorCards.all.map(
            (card) => OperatorIdentityCard(
              card: card,
              secretsUnlocked: _darthActive,
            ),
          ),
        ],
        if (!showCherrySection && _cherryCacheOpen && !_isGam3on)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Cherry cache open — operator roster is restricted to Gam3.0n.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NoirTheme.mist.withValues(alpha: 0.5),
                  ),
            ),
          ),
      ],
    );
  }
}
