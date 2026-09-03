import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _short = [
  TimerMovement(
    label: 'Presence',
    prompt: 'You are here. God is here.',
    seconds: 50,
  ),
  TimerMovement(
    label: 'Light',
    prompt: 'Ask for light to see the day as it was.',
    seconds: 25,
  ),
  TimerMovement(
    label: 'Review',
    prompt: 'Walk the hours. Where were you given, and where did you refuse?',
    seconds: 125,
  ),
  TimerMovement(
    label: 'Sorrow',
    prompt: 'Sorrow without drama. Tell Him the truth of it.',
    seconds: 50,
  ),
  TimerMovement(
    label: 'Resolve',
    prompt: 'One concrete resolve for the hours that remain.',
    seconds: 50,
  ),
];

const _full = [
  TimerMovement(
    label: 'Presence',
    prompt: 'You are here. God is here.',
    seconds: 120,
  ),
  TimerMovement(
    label: 'Light',
    prompt: 'Ask for light to see the day as it was.',
    seconds: 60,
  ),
  TimerMovement(
    label: 'Review',
    prompt: 'Walk the hours. Where were you given, and where did you refuse?',
    seconds: 300,
  ),
  TimerMovement(
    label: 'Sorrow',
    prompt: 'Sorrow without drama. Tell Him the truth of it.',
    seconds: 120,
  ),
  TimerMovement(
    label: 'Resolve',
    prompt: 'One concrete resolve for the hours that remain.',
    seconds: 120,
  ),
];

int examenReadingId(DateTime day) => 40000 + day.month * 100 + day.day;

class IgnatiusPracticeScreen extends ConsumerStatefulWidget {
  const IgnatiusPracticeScreen({super.key});

  @override
  ConsumerState<IgnatiusPracticeScreen> createState() =>
      _IgnatiusPracticeScreenState();
}

class _IgnatiusPracticeScreenState
    extends ConsumerState<IgnatiusPracticeScreen> {
  bool _shortForm = true;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime(
    BuildContext context,
    String key, {
    required int hour,
    required int minute,
  }) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.reminderTimeFor(key).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? hour,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? minute,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setCycleReminderTime(
          key,
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }

  Future<void> _saveNote() async {
    final day = ref.read(selectedDayProvider);
    final ok = await ref.read(journalProvider.notifier).add(
          examenReadingId(day),
          _note.text,
        );
    if (!mounted) return;
    if (ok) {
      _note.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final day = ref.watch(selectedDayProvider);
    final priorAsync = ref.watch(priorJournalProvider(examenReadingId(day)));
    final prayersAsync = ref.watch(ignatiusPrayersProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text('Examen', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Five movements. The short form is the one he would not drop. '
          'Default to it.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Short form'),
          subtitle: Text(_shortForm ? 'Five minutes.' : 'Twelve minutes.'),
          value: _shortForm,
          onChanged: (v) => setState(() => _shortForm = v),
        ),
        const SizedBox(height: 8),
        ChromeLabel(_shortForm ? 'Short Examen' : 'Full Examen'),
        const SizedBox(height: 16),
        GuidedTimer(movements: _shortForm ? _short : _full),
        const SizedBox(height: 28),
        ChromeLabel('A year ago tonight'),
        const SizedBox(height: 8),
        priorAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (prior) {
            if (prior == null || prior.text.trim().isEmpty) {
              return Text(
                'When you have written a note on this date before, it will '
                'return here.',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            return Text(
              'A year ago tonight you wrote: ${prior.text}',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _note,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Note',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _saveNote,
            child: const Text('Save'),
          ),
        ),
        const SizedBox(height: 28),
        ChromeLabel('Prayers'),
        const SizedBox(height: 8),
        prayersAsync.when(
          loading: () => const EmptyLoading(),
          error: (e, _) => Text('$e'),
          data: (book) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in book.prayers) ...[
                  Text(p.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ReadingBody(text: p.textEn),
                  const SizedBox(height: 20),
                ],
              ],
            );
          },
        ),
        ChromeLabel('Midday Examen'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me at midday'),
          subtitle: const Text('Soft double tap. Off by default.'),
          value: settings.reminderEnabledFor('ignatius'),
          onChanged: (v) => ctrl.setCycleReminderEnabled('ignatius', v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.reminderTimeFor('ignatius')),
          enabled: settings.reminderEnabledFor('ignatius'),
          onTap: settings.reminderEnabledFor('ignatius')
              ? () => _pickTime(context, 'ignatius', hour: 12, minute: 30)
              : null,
        ),
        const SizedBox(height: 12),
        ChromeLabel('Evening Examen'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me in the evening'),
          subtitle: const Text('Off by default.'),
          value: settings.reminderEnabledFor('ignatius-evening'),
          onChanged: (v) =>
              ctrl.setCycleReminderEnabled('ignatius-evening', v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.reminderTimeFor('ignatius-evening')),
          enabled: settings.reminderEnabledFor('ignatius-evening'),
          onTap: settings.reminderEnabledFor('ignatius-evening')
              ? () =>
                  _pickTime(context, 'ignatius-evening', hour: 21, minute: 0)
              : null,
        ),
      ],
    );
  }
}
