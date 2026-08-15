import 'dart:async';

import 'package:benedictdaily/core/haptics/bell_haptics.dart';
import 'package:benedictdaily/data/providers.dart';
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

  int get defaultMinutes => switch (this) {
        LectioMovement.lectio => 4,
        LectioMovement.meditatio => 4,
        LectioMovement.oratio => 4,
        LectioMovement.contemplatio => 8,
      };
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

  @override
  void initState() {
    super.initState();
    _remaining = _movement.defaultMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _journalCtrl.dispose();
    super.dispose();
  }

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
    setState(() {
      _movement = values[idx + 1];
      _remaining = _movement.defaultMinutes * 60;
    });
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    final day = ref.watch(selectedDayProvider);
    final journal = ref.watch(journalProvider);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final readings = catalog.calendar.resolveFor(day);
        final reading = readings.isEmpty ? null : readings.first;
        final prior = reading == null
            ? null
            : ref.read(journalProvider.notifier).previousFor(reading.id);

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text('Lectio Divina', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              reading == null
                  ? 'No reading today.'
                  : catalog.calendar.readingHeadline(reading),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text(
              _movement.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(_movement.prompt, style: Theme.of(context).textTheme.titleMedium),
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
                  onPressed: reading == null
                      ? null
                      : (_running ? _pause : _start),
                  child: Text(_running ? 'Pause' : 'Begin'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _running || _remaining == 0 ? null : _advance,
                  child: const Text('Next movement'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (reading != null) ...[
              ChromeLabel('Today\'s passage'),
              const SizedBox(height: 10),
              ReadingBody(text: reading.textEn),
            ],
            if (prior != null) ...[
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
              onPressed: reading == null
                  ? null
                  : () async {
                      await ref
                          .read(journalProvider.notifier)
                          .add(reading.id, _journalCtrl.text);
                      _journalCtrl.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Journal saved.')),
                        );
                      }
                    },
              child: const Text('Save entry'),
            ),
            if (journal.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '${journal.length} saved entries',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}
