import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/polybius_launcher.dart';
import '../services/vault_service.dart';
import '../theme/noir_theme.dart';
import '../widgets/matrix_chrome.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key, required this.session});

  final AuthSession session;

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  final _vault = VaultService();
  final _noteCtrl = TextEditingController();
  DateTime _selected = DateTime.now();
  List<PlannerNote> _notes = [];
  bool _vaultOpen = false;
  String _holdLabel = 'SAVE NOTE';
  bool _holding = false;
  DateTime? _holdStarted;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final notes = await _vault.loadNotes();
    final open = await _vault.isVaultOpenForDay(
      widget.session.username,
      _selected,
    );
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _vaultOpen = open;
      _holdLabel = open ? 'OPEN' : 'SAVE NOTE';
    });
  }

  Future<void> _openPayload({required bool hq}) async {
    if (_launching) return;
    setState(() => _launching = true);
    final ok = await PolybiusLauncher.open(hq: hq);
    if (!mounted) return;
    setState(() => _launching = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archive offline.')),
      );
    }
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
            primary: NoirTheme.matrix,
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

  Future<void> _onHoldStart() async {
    setState(() {
      _holding = true;
      _holdStarted = DateTime.now();
      _holdLabel = _vaultOpen ? 'OPEN' : '…';
    });
    if (_vaultOpen) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!_holding || !mounted) return;
      final admin = widget.session.tier == 'admin' ||
          widget.session.tier == 'developer';
      if (admin) {
        await _openPayload(hq: true);
      }
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!_holding || _holdStarted == null) return;
    final body = _noteCtrl.text.trim();
    final note = PlannerNote(
      id: _vault.newId(),
      dayKey: _vault.dayKey(_selected),
      body: body.isEmpty ? '(empty note)' : body,
      updatedAt: DateTime.now(),
    );
    final notes = [..._notes, note];
    await _vault.saveNotes(notes);

    var unlocked = _vaultOpen;
    if (_vault.matchesRitual(body, _selected)) {
      await _vault.unlockVaultForDay(widget.session.username, _selected);
      unlocked = true;
      HapticFeedback.heavyImpact();
    }

    if (!mounted) return;
    setState(() {
      _notes = notes;
      _vaultOpen = unlocked;
      _holdLabel = unlocked ? 'OPEN' : 'SAVE NOTE';
      _holding = false;
    });
    if (unlocked) {
      await _openPayload(hq: false);
    }
  }

  void _onHoldEnd() {
    if (_vaultOpen && _holdLabel == 'OPEN') {
      // Short tap on OPEN launches the concealed user payload.
      if (_holdStarted != null &&
          DateTime.now().difference(_holdStarted!) <
              const Duration(seconds: 2)) {
        _openPayload(hq: false);
      }
      setState(() => _holding = false);
      return;
    }
    setState(() {
      _holding = false;
      _holdLabel = _vaultOpen ? 'OPEN' : 'SAVE NOTE';
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = _vault.dayKey(_selected);
    final dayNotes = _notes.where((n) => n.dayKey == dayKey);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('CALENDAR · PAST / FUTURE',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        NeonPanel(
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  setState(() {
                    _selected = _selected.subtract(const Duration(days: 1));
                  });
                  await _reload();
                },
                icon: const Icon(Icons.chevron_left, color: NoirTheme.matrix),
              ),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE').format(_selected).toUpperCase(),
                        style: const TextStyle(color: NoirTheme.pink),
                      ),
                      Text(
                        DateFormat('d MMM yyyy').format(_selected),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('TAP TO JUMP',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: NoirTheme.yellow,
                          )),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  setState(() {
                    _selected = _selected.add(const Duration(days: 1));
                  });
                  await _reload();
                },
                icon: const Icon(Icons.chevron_right, color: NoirTheme.matrix),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteCtrl,
          maxLines: 4,
          style: const TextStyle(color: NoirTheme.mist),
          decoration: InputDecoration(
            hintText: 'Note for $dayKey — ritual words unlock vault…',
            hintStyle: TextStyle(color: NoirTheme.mist.withValues(alpha: 0.35)),
            filled: true,
            fillColor: NoirTheme.panel,
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        const SizedBox(height: 10),
        Listener(
          onPointerDown: (_) => _onHoldStart(),
          onPointerUp: (_) => _onHoldEnd(),
          onPointerCancel: (_) => _onHoldEnd(),
          child: NeonPanel(
            color: _holdLabel == 'OPEN' ? NoirTheme.peace : NoirTheme.matrix,
            child: Center(
              child: Text(
                _holdLabel,
                style: TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800,
                  color: _holdLabel == 'OPEN'
                      ? NoirTheme.peace
                      : NoirTheme.matrix,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('NOTES · $dayKey', style: Theme.of(context).textTheme.labelLarge),
        ...dayNotes.map((n) => Text('• ${n.body}')),
        if (_vaultOpen)
          Text(
            _launching ? 'Opening archive…' : 'Archive synchronized.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NoirTheme.mist.withValues(alpha: 0.45),
                ),
          )
        else
          Text(
            'Notes save on a long press. Nothing else is stored here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NoirTheme.mist.withValues(alpha: 0.45),
                ),
          ),
      ],
    );
  }
}
