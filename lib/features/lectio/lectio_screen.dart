import 'dart:async';

import 'package:benedictdaily/core/cycle/life_track.dart';
import 'package:benedictdaily/core/haptics/bell_haptics.dart';
import 'package:benedictdaily/core/iap/iap_controller.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/features/iap/oblate_paywall_screen.dart';
import 'package:benedictdaily/features/lectio/journal_export.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LectioMovement { lectio, meditatio, oratio, contemplatio }

extension on LectioMovement {
  String get label => switch (this) {
        LectioMovement.lectio => 'Lectio',
        LectioMovement.meditatio => 'Meditatio',
        LectioMovement.oratio => 'Oratio',
        LectioMovement.contemplatio => 'Contemplatio',
      };

  String get prompt => switch (this) {
        LectioMovement.lectio => 'Read the passage slowly.',
        LectioMovement.meditatio => 'Turn a word or phrase in the heart.',
        LectioMovement.oratio => 'Speak to God from what you have heard.',
        LectioMovement.contemplatio => 'Rest in silence.',
      };

  String get settingsKey => name;
}

class LectioScreen extends ConsumerStatefulWidget {
  const LectioScreen({super.key});

  @override
  ConsumerState<LectioScreen> createState() => _LectioScreenState();
}

class _LectioScreenState extends ConsumerState<LectioScreen> {
  LectioMovement _movement = LectioMovement.lectio;
  late int _remaining;
  Timer? _timer;
  bool _running = false;
  final _journalCtrl = TextEditingController();
  bool _hydratedDraft = false;

  @override
  void initState() {
    super.initState();
    _remaining = 4 * 60;
    _journalCtrl.addListener(_onJournalChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = ref.read(settingsProvider);
      if (settings.ready) {
        setState(() {
          _remaining = _minutesFor(_movement, settings) * 60;
        });
      }
      _restoreDraft();
    });
  }

  void _restoreDraft() {
    if (_hydratedDraft) return;
    _hydratedDraft = true;
    final draft = ref.read(journalDraftProvider);
    if (draft.text.isNotEmpty && _journalCtrl.text != draft.text) {
      _journalCtrl.text = draft.text;
    }
  }

  void _onJournalChanged() {
    final readingId = ref.read(journalDraftProvider).readingId;
    ref.read(journalDraftProvider.notifier).updateText(
          _journalCtrl.text,
          readingId: readingId,
        );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _journalCtrl.removeListener(_onJournalChanged);
    _journalCtrl.dispose();
    super.dispose();
  }

  int _minutesFor(LectioMovement m, AppSettings settings) =>
      settings.minutesForMovement(m.settingsKey);

  void _start() {
    _timer?.cancel();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_remaining <= 1) {
        await _advance();
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  Future<void> _advance() async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      await BellHaptics.play(BellKind.lectioTick);
    }
    final values = LectioMovement.values;
    final idx = values.indexOf(_movement);
    if (idx >= values.length - 1) {
      _timer?.cancel();
      setState(() {
        _running = false;
        _remaining = 0;
      });
      return;
    }
    final next = values[idx + 1];
    setState(() {
      _movement = next;
      _remaining = _minutesFor(next, settings) * 60;
    });
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _saveJournal(int readingId) async {
    ref.read(journalDraftProvider.notifier).bindReading(readingId);
    ref.read(journalDraftProvider.notifier).updateText(
          _journalCtrl.text,
          readingId: readingId,
        );
    final ok = await ref
        .read(journalDraftProvider.notifier)
        .save(readingId: readingId);
    if (!mounted) return;
    if (ok) {
      _journalCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal saved.')),
      );
    }
    // On failure the persistent banner stays via draft.saveFailed.
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    final day = ref.watch(selectedDayProvider);
    final journal = ref.watch(journalProvider);
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final unlocked = ref.watch(oblateUnlockedProvider);
    final draft = ref.watch(journalDraftProvider);

    // Keep field in sync when returning with a held draft.
    if (draft.text.isNotEmpty &&
        _journalCtrl.text.isEmpty &&
        draft.saveFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_journalCtrl.text.isEmpty) {
          _journalCtrl.text = draft.text;
        }
      });
    }

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final ruleReadings = catalog.calendar.resolveFor(day);
        final numberedLife = catalog.life.where((e) => e.chapter > 0).length;
        var passage = lectioPassageFor(
          track: settings.dailyTrack,
          life: catalog.life,
          rule: ruleReadings,
          day: day,
          lifeStart: settings.lifeStart,
          unlocked: unlocked,
          numberedLife: numberedLife,
        );
        if (passage != null &&
            passage.headline.isEmpty &&
            ruleReadings.isNotEmpty) {
          passage = LectioPassage(
            journalId: passage.journalId,
            headline: catalog.calendar.readingHeadline(ruleReadings.first),
            textEn: passage.textEn,
            locked: passage.locked,
          );
        }
        final reading = passage;
        if (reading != null && !reading.locked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(journalDraftProvider.notifier).bindReading(reading.journalId);
          });
        }
        final priorAsync = reading == null || reading.locked
            ? null
            : ref.watch(priorJournalProvider(reading.journalId));
        final prior = priorAsync?.valueOrNull;

        return Column(
          children: [
            if (draft.saveFailed)
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Journal not saved. Your words are still here — tap Retry.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: reading == null || reading.locked
                              ? null
                              : () => _saveJournal(reading.journalId),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                children: [
                  Text(
                    'Lectio Divina',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reading == null
                        ? 'No reading today.'
                        : reading.locked
                            ? 'Today’s Life episode unlocks with Oblate.'
                            : reading.headline,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _movement.label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _movement.prompt,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _fmt(_remaining),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontFamily: 'IBMPlexSans',
                          fontSize: 56,
                          height: 1,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: reading == null || reading.locked
                            ? null
                            : (_running ? _pause : _start),
                        child: Text(_running ? 'Pause' : 'Begin'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed:
                            _running || _remaining == 0 ? null : _advance,
                        child: const Text('Next movement'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ChromeLabel('Durations'),
                  const SizedBox(height: 8),
                  Text(
                    _running
                        ? 'Pause to adjust movement lengths.'
                        : 'Defaults are 4 / 4 / 4 / 8 minutes.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _DurationSlider(
                    label: 'Lectio',
                    value: settings.lectioMinutes,
                    enabled: !_running,
                    onChanged: (v) async {
                      await ctrl.setLectioMinutes(lectio: v);
                      if (_movement == LectioMovement.lectio && mounted) {
                        setState(() => _remaining = v * 60);
                      }
                    },
                  ),
                  _DurationSlider(
                    label: 'Meditatio',
                    value: settings.meditatioMinutes,
                    enabled: !_running,
                    onChanged: (v) async {
                      await ctrl.setLectioMinutes(meditatio: v);
                      if (_movement == LectioMovement.meditatio && mounted) {
                        setState(() => _remaining = v * 60);
                      }
                    },
                  ),
                  _DurationSlider(
                    label: 'Oratio',
                    value: settings.oratioMinutes,
                    enabled: !_running,
                    onChanged: (v) async {
                      await ctrl.setLectioMinutes(oratio: v);
                      if (_movement == LectioMovement.oratio && mounted) {
                        setState(() => _remaining = v * 60);
                      }
                    },
                  ),
                  _DurationSlider(
                    label: 'Contemplatio',
                    value: settings.contemplatioMinutes,
                    enabled: !_running,
                    onChanged: (v) async {
                      await ctrl.setLectioMinutes(contemplatio: v);
                      if (_movement == LectioMovement.contemplatio &&
                          mounted) {
                        setState(() => _remaining = v * 60);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  if (reading != null && reading.locked) ...[
                    ChromeLabel('Today\'s passage'),
                    const SizedBox(height: 10),
                    Text(
                      'The rest of Benedict’s life unlocks with Oblate.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => openOblatePaywall(context),
                      child: const Text('Unlock Oblate'),
                    ),
                  ] else if (reading != null) ...[
                    ChromeLabel('Today\'s passage'),
                    const SizedBox(height: 10),
                    ReadingBody(text: reading.textEn),
                  ],
                  if (prior != null && unlocked) ...[
                    const SizedBox(height: 20),
                    ChromeLabel('From a past cycle'),
                    const SizedBox(height: 8),
                    Text(
                      '"${prior.text}"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  ChromeLabel('Journal'),
                  const SizedBox(height: 8),
                  if (!unlocked) ...[
                    Text(
                      'Saving a journal and hearing past-cycle notes unlocks with Oblate. '
                      'The Lectio timer stays free.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => openOblatePaywall(context),
                      child: const Text('Unlock journal · Oblate'),
                    ),
                  ] else ...[
                    TextField(
                      controller: _journalCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'A word, a prayer, a notice…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: reading == null || reading.locked
                          ? null
                          : () => _saveJournal(reading.journalId),
                      child: const Text('Save entry'),
                    ),
                    if (journal.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        '${journal.length} saved entries',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () async {
                          final catalog =
                              ref.read(contentCatalogProvider).valueOrNull;
                          await JournalExport.share(
                            context,
                            entries: journal,
                            catalog: catalog,
                          );
                        },
                        child: const Text('Export journal'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '$value min',
            onChanged: enabled ? (v) => onChanged(v.round()) : null,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value m',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
