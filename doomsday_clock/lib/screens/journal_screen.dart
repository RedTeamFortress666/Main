import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/planner_note.dart';
import '../models/vault_card.dart';
import '../services/planner_service.dart';
import '../services/qr_card_codec.dart';
import '../services/vault_store.dart';
import '../theme/noir_theme.dart';
import '../widgets/hold_save_button.dart';
import '../widgets/month_calendar.dart';
import '../widgets/operator_card_view.dart';
import 'qr_scan_screen.dart';
import 'qr_share_sheet.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({
    super.key,
    this.now,
    this.planner,
    this.vaultStore,
  });

  final DateTime? now;
  final PlannerService? planner;
  final VaultStore? vaultStore;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late final PlannerService _planner;
  late final VaultStore _vault;
  late DateTime _visibleMonth;
  late DateTime _selected;
  final _noteCtrl = TextEditingController();
  List<PlannerNote> _notes = [];
  List<VaultCard> _cards = [];
  bool _archiveOpen = false;
  bool _darthCherry = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _planner = widget.planner ?? PlannerService();
    _vault = widget.vaultStore ?? VaultStore();
    final now = widget.now ?? DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
    _reload();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final notes = await _planner.loadNotes();
    final open = await _planner.isArchiveOpen();
    final cards = await _vault.load();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _archiveOpen = open;
      _cards = cards;
    });
  }

  Future<void> _saveNote({required bool held}) async {
    final body = _noteCtrl.text.trim();
    if (held && _planner.matchesUnlockRitual(body, _selected)) {
      await _planner.openArchive();
      if (!mounted) return;
      setState(() {
        _archiveOpen = true;
        _status = 'Saved';
      });
      _noteCtrl.clear();
      return;
    }

    if (body.isNotEmpty) {
      final note = PlannerNote(
        id: _planner.newId(),
        dayKey: _planner.dayKey(_selected),
        body: body,
        updatedAt: DateTime.now(),
      );
      final notes = [..._notes, note];
      await _planner.saveNotes(notes);
      if (mounted) {
        setState(() {
          _notes = notes;
          _status = 'Saved';
        });
        _noteCtrl.clear();
      }
    }
  }

  Future<void> _scanCard() async {
    final card = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (card == null) return;
    final cards = await _vault.upsert(card);
    if (!mounted) return;
    setState(() => _cards = cards);
  }

  Future<void> _pasteCard() async {
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => const _PasteDialog(),
    );
    if (raw == null) return;
    final card = QrCardCodec.decode(raw);
    if (card == null) {
      if (!mounted) return;
      setState(() => _status = 'Could not read that code.');
      return;
    }
    final cards = await _vault.upsert(card);
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _status = 'Added ${card.username}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = _planner.dayKey(_selected);
    final dayNotes = _notes.where((n) => n.dayKey == dayKey).toList();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: NoirTheme.ink,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'DOØMSDAY CLØCK',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calendar / Journal',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        MonthCalendar(
                          visibleMonth: _visibleMonth,
                          selected: _selected,
                          onSelectDay: (day) => setState(() => _selected = day),
                          onPrevMonth: () => setState(() {
                            _visibleMonth = DateTime(
                              _visibleMonth.year,
                              _visibleMonth.month - 1,
                            );
                          }),
                          onNextMonth: () => setState(() {
                            _visibleMonth = DateTime(
                              _visibleMonth.year,
                              _visibleMonth.month + 1,
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Entries · ${DateFormat('d MMM').format(_selected)}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        if (dayNotes.isEmpty)
                          Text(
                            'Nothing written for this day.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: NoirTheme.chrome,
                                ),
                          )
                        else
                          ...dayNotes.map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('• ${n.body}'),
                            ),
                          ),
                        if (_archiveOpen) ...[
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Operator cards',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: _darthCherry
                                            ? NoirTheme.crimson
                                            : NoirTheme.neonCyan,
                                      ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _scanCard,
                                icon: const Icon(Icons.qr_code_scanner, size: 18),
                                label: const Text('Scan'),
                              ),
                              TextButton(
                                onPressed: _pasteCard,
                                child: const Text('Paste'),
                              ),
                            ],
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('DARTH CHERRY'),
                            subtitle: const Text(
                              'Reveal passwords, PINs, and backup keys',
                            ),
                            value: _darthCherry,
                            activeThumbColor: NoirTheme.crimson,
                            onChanged: (v) => setState(() => _darthCherry = v),
                          ),
                          if (_cards.isEmpty)
                            const Text(
                              'No cards yet. Scan a PØLYBĪUS operator card.',
                              style: TextStyle(color: NoirTheme.chrome),
                            )
                          else
                            ..._cards.map(
                              (vaultCard) => OperatorCardView(
                                card: vaultCard.card,
                                secretsUnlocked: _darthCherry,
                                onShareQr: () =>
                                    QrShareSheet.show(context, vaultCard.card),
                                onDelete: () async {
                                  final cards = await _vault.remove(vaultCard.id);
                                  if (!mounted) return;
                                  setState(() => _cards = cards);
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: BoxDecoration(
                    color: NoirTheme.panel,
                    border: Border(
                      top: BorderSide(
                        color: NoirTheme.neonCyan.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        DateFormat('EEEE d MMMM yyyy').format(_selected),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('journal-note'),
                        controller: _noteCtrl,
                        maxLines: 3,
                        style: const TextStyle(color: NoirTheme.mist),
                        decoration: InputDecoration(
                          hintText: 'Write a note for this day…',
                          hintStyle: TextStyle(
                            color: NoirTheme.mist.withValues(alpha: 0.35),
                          ),
                          filled: true,
                          fillColor: NoirTheme.voidBlack,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: NoirTheme.neonCyan.withValues(alpha: 0.4),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: NoirTheme.neonMagenta,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      HoldSaveButton(
                        key: const Key('save-button'),
                        holdMs: _planner.holdMs,
                        onTapSave: () => _saveNote(held: false),
                        onHoldComplete: () => _saveNote(held: true),
                      ),
                      if (_status != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _status!,
                          style: const TextStyle(color: NoirTheme.chrome),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_darthCherry)
          IgnorePointer(
            child: Container(
              color: NoirTheme.crimson.withValues(alpha: 0.08),
            ),
          ),
      ],
    );
  }
}

class _PasteDialog extends StatefulWidget {
  const _PasteDialog();

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NoirTheme.panel,
      title: const Text('Paste code'),
      content: TextField(
        key: const Key('paste-card-field'),
        controller: _ctrl,
        autofocus: true,
        maxLines: 4,
        decoration: const InputDecoration(hintText: 'Card code'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
