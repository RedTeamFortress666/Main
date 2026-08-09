import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../services/vault_service.dart';
import '../theme/noir_theme.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  final _vault = VaultService();
  final _noteCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();

  List<PlannerNote> _notes = [];
  List<VaultEntry> _vaultEntries = [];
  bool _vaultOpen = false;
  String _holdLabel = 'SAVE NOTE';
  bool _holding = false;
  DateTime? _holdStarted;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _titleCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final notes = await _vault.loadNotes();
    final open = await _vault.isVaultOpenToday();
    final entries = open ? await _vault.loadVault() : <VaultEntry>[];
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _vaultOpen = open;
      _vaultEntries = entries;
      _holdLabel = open ? 'OPEN' : 'SAVE NOTE';
    });
  }

  Future<void> _onHoldStart() async {
    setState(() {
      _holding = true;
      _holdStarted = DateTime.now();
      _holdLabel = '…';
    });
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!_holding || _holdStarted == null) return;
    final elapsed = DateTime.now().difference(_holdStarted!);
    if (elapsed < const Duration(milliseconds: 2800)) return;

    final now = DateTime.now();
    final body = _noteCtrl.text.trim();
    final note = PlannerNote(
      id: _vault.newId(),
      dayKey: _vault.dayKey(now),
      body: body.isEmpty ? '(empty note)' : body,
      updatedAt: now,
    );
    final notes = [..._notes, note];
    await _vault.saveNotes(notes);

    var unlocked = _vaultOpen;
    if (_vault.matchesRitual(body, now)) {
      await _vault.unlockVaultForToday();
      unlocked = true;
      HapticFeedback.heavyImpact();
    }

    if (!mounted) return;
    setState(() {
      _notes = notes;
      _vaultOpen = unlocked;
      _holdLabel = unlocked ? 'OPEN' : 'SAVE NOTE';
      _holding = false;
      _holdStarted = null;
    });
    if (unlocked) {
      final entries = await _vault.loadVault();
      if (mounted) setState(() => _vaultEntries = entries);
    }
  }

  void _onHoldEnd() {
    if (_holdLabel == 'OPEN' && _vaultOpen) return;
    setState(() {
      _holding = false;
      _holdStarted = null;
      _holdLabel = _vaultOpen ? 'OPEN' : 'SAVE NOTE';
    });
  }

  Future<void> _addVaultItem() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final entry = VaultEntry(
      id: _vault.newId(),
      title: title,
      detail: _detailCtrl.text.trim(),
      apkHint: null,
    );
    await _vault.addVaultEntry(entry);
    _titleCtrl.clear();
    _detailCtrl.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Ritual phrase is intentionally not shown in the UI — operator must know
    // today's words. (Tests / operator docs can reveal the rotation.)
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('DAILY PLANNER', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          'Write the day. Hold SAVE NOTE for 3 seconds to commit.\n'
          'Certain words, on the right day, open the vault.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NoirTheme.mist.withValues(alpha: 0.65),
              ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteCtrl,
          maxLines: 4,
          style: const TextStyle(color: NoirTheme.mist),
          decoration: InputDecoration(
            hintText: 'Note for ${_vault.dayKey(today)}…',
            hintStyle: TextStyle(color: NoirTheme.mist.withValues(alpha: 0.35)),
            filled: true,
            fillColor: NoirTheme.panel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: NoirTheme.line),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Listener(
          onPointerDown: (_) => _onHoldStart(),
          onPointerUp: (_) => _onHoldEnd(),
          onPointerCancel: (_) => _onHoldEnd(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _holdLabel == 'OPEN'
                  ? NoirTheme.peace.withValues(alpha: 0.2)
                  : NoirTheme.cyan.withValues(alpha: _holding ? 0.25 : 0.1),
              border: Border.all(
                color: _holdLabel == 'OPEN' ? NoirTheme.peace : NoirTheme.cyan,
              ),
            ),
            child: Text(
              _holdLabel,
              style: TextStyle(
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: _holdLabel == 'OPEN' ? NoirTheme.peace : NoirTheme.cyan,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text('TODAY\'S NOTES', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        ..._notes.where((n) => n.dayKey == _vault.dayKey(today)).map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• ${n.body}',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
        if (_vaultOpen) ...[
          const SizedBox(height: 22),
          Text('VAULT · OPEN',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: NoirTheme.peace,
                  )),
          const SizedBox(height: 8),
          ..._vaultEntries.map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: NoirTheme.peace.withValues(alpha: 0.4)),
                color: NoirTheme.panel,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 18,
                            color: NoirTheme.peace,
                          )),
                  if (e.detail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(e.detail),
                  ],
                  if (e.apkHint != null) ...[
                    const SizedBox(height: 6),
                    SelectableText(
                      e.apkHint!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NoirTheme.cyan,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Stash title / APK name',
              labelStyle: TextStyle(color: NoirTheme.mist),
            ),
            style: const TextStyle(color: NoirTheme.mist),
          ),
          TextField(
            controller: _detailCtrl,
            decoration: const InputDecoration(
              labelText: 'Detail',
              labelStyle: TextStyle(color: NoirTheme.mist),
            ),
            style: const TextStyle(color: NoirTheme.mist),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _addVaultItem,
            style: OutlinedButton.styleFrom(
              foregroundColor: NoirTheme.peace,
              side: const BorderSide(color: NoirTheme.peace),
            ),
            child: const Text('ADD TO VAULT'),
          ),
        ] else ...[
          const SizedBox(height: 22),
          Text(
            'VAULT · SEALED',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: NoirTheme.mist.withValues(alpha: 0.45),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the day\'s particular words, then hold until OPEN.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NoirTheme.mist.withValues(alpha: 0.45),
                ),
          ),
        ],
      ],
    );
  }
}
