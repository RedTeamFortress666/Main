import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/apk_installer.dart';
import '../services/auth_service.dart';
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
  final _auth = AuthService();
  final _noteCtrl = TextEditingController();
  DateTime _selected = DateTime.now();
  List<PlannerNote> _notes = [];
  List<VaultEntry> _vaultEntries = [];
  bool _vaultOpen = false;
  String _holdLabel = 'SAVE NOTE';
  bool _holding = false;
  DateTime? _holdStarted;
  bool _showConcealed = false;

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
    final entries = await _loadUserVault();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _vaultOpen = open;
      _vaultEntries = entries;
      _holdLabel = open ? 'OPEN' : 'SAVE NOTE';
    });
  }

  Future<List<VaultEntry>> _loadUserVault() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'vault_entries_${widget.session.username.toUpperCase()}';
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => VaultEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persistVault(List<VaultEntry> entries) async {
    await _auth.saveUserVault(widget.session.username, entries);
    if (mounted) setState(() => _vaultEntries = entries);
  }

  Future<void> _toggleConceal(VaultEntry entry) async {
    if (!entry.concealable) return;
    final next = _vaultEntries
        .map(
          (e) => e.id == entry.id
              ? e.copyWith(concealed: !e.concealed)
              : e,
        )
        .toList();
    await _persistVault(next);
    HapticFeedback.selectionClick();
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
      _holdLabel = '…';
    });
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
      if (_vault.isMechaHDay(_selected)) {
        await _auth.ensureMechaHDevPortal(widget.session.username);
      }
    }

    if (!mounted) return;
    setState(() {
      _notes = notes;
      _vaultOpen = unlocked;
      _holdLabel = unlocked ? 'OPEN' : 'SAVE NOTE';
      _holding = false;
    });
    if (unlocked) {
      final entries = await _loadUserVault();
      if (mounted) setState(() => _vaultEntries = entries);
    }
  }

  void _onHoldEnd() {
    if (_holdLabel == 'OPEN' && _vaultOpen) return;
    setState(() {
      _holding = false;
      _holdLabel = _vaultOpen ? 'OPEN' : 'SAVE NOTE';
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = _vault.dayKey(_selected);
    final dayNotes = _notes.where((n) => n.dayKey == dayKey);
    final visibleEntries = _vaultEntries.where((e) {
      if (!e.concealed) return true;
      return _showConcealed;
    }).toList();
    final concealedCount =
        _vaultEntries.where((e) => e.concealable && e.concealed).length;

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
                        style: TextStyle(
                          color: _vault.isUnlockDay(_selected)
                              ? NoirTheme.crimson
                              : NoirTheme.pink,
                        ),
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
          maxLines: 5,
          style: const TextStyle(color: NoirTheme.mist),
          decoration: InputDecoration(
            hintText: _vault.unlockHintFor(_selected),
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
        if (_vaultOpen) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'VAULT · ${widget.session.displayName}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: NoirTheme.peace,
                      ),
                ),
              ),
              if (concealedCount > 0 || _showConcealed)
                TextButton(
                  onPressed: () =>
                      setState(() => _showConcealed = !_showConcealed),
                  child: Text(
                    _showConcealed ? 'HIDE SLOT' : 'REVEAL SLOT',
                    style: const TextStyle(
                      color: NoirTheme.yellow,
                      letterSpacing: 1,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...visibleEntries.map((e) => _vaultCard(e)),
          if (concealedCount > 0 && !_showConcealed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$concealedCount concealable slot(s) hidden',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NoirTheme.mist.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
              ),
            ),
        ] else
          Text(
            'VAULT SEALED — rituals: 5 Nov (Gunpowder Plot) or 20 Apr '
            '(Happy Birthday MechaH! I grok thee). Hold SAVE NOTE until OPEN.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NoirTheme.mist.withValues(alpha: 0.45),
                ),
          ),
      ],
    );
  }

  Widget _vaultCard(VaultEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NeonPanel(
        color: e.concealed ? NoirTheme.yellow : NoirTheme.peace,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.concealed ? '∎ CONCEALED' : e.title,
                    style: TextStyle(
                      color: e.concealed ? NoirTheme.yellow : NoirTheme.peace,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (e.concealable)
                  IconButton(
                    tooltip: e.concealed ? 'Reveal portal' : 'Conceal portal',
                    onPressed: () => _toggleConceal(e),
                    icon: Icon(
                      e.concealed ? Icons.visibility : Icons.visibility_off,
                      color: e.concealed ? NoirTheme.yellow : NoirTheme.pink,
                      size: 26,
                    ),
                  ),
              ],
            ),
            if (!e.concealed) ...[
              if (e.detail.isNotEmpty) Text(e.detail),
              if (e.apkHint != null) ...[
                const SizedBox(height: 4),
                SelectableText(
                  e.apkHint!,
                  style: const TextStyle(
                    color: NoirTheme.cyan,
                    fontSize: 11,
                  ),
                ),
              ],
              if (e.assetApk != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      try {
                        await ApkInstaller.installAsset(e.assetApk!);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Install prompt launched'),
                          ),
                        );
                      } catch (err) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Install failed: $err')),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: NoirTheme.peace,
                    ),
                    child: const Text(
                      'INSTALL EMBEDDED APK',
                      style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ] else
              const Text(
                'Portal slot concealed — tap the eye to restore.',
                style: TextStyle(fontSize: 12, color: NoirTheme.mist),
              ),
          ],
        ),
      ),
    );
  }
}
