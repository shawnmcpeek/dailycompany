import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _evening = [
  TimerMovement(
    label: 'Read',
    prompt: 'Today’s Confession. Read it as to God, not as a task.',
    seconds: 600,
  ),
  TimerMovement(
    label: 'Rest',
    prompt: 'Our heart is restless, until it repose in Thee.',
    seconds: 300,
  ),
];

class AugustinePracticeScreen extends ConsumerWidget {
  const AugustinePracticeScreen({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.reminderTimeFor('augustine').split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 21,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setCycleReminderTime(
          'augustine',
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text(
          'Evening reading',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'The Confessions were written as prayer. This hour is for that — '
          'today’s reading, then rest in the words.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        ChromeLabel('This evening'),
        const SizedBox(height: 10),
        Text(
          'Ten minutes with the day’s pages, then five of rest. '
          'The calendar is on Today.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const GuidedTimer(movements: _evening),
        const SizedBox(height: 28),
        ChromeLabel('Hour of reading'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          subtitle: const Text('One soft tap. Off by default.'),
          value: settings.reminderEnabledFor('augustine'),
          onChanged: (v) => ctrl.setCycleReminderEnabled('augustine', v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.reminderTimeFor('augustine')),
          enabled: settings.reminderEnabledFor('augustine'),
          onTap: settings.reminderEnabledFor('augustine')
              ? () => _pickTime(context, ref)
              : null,
        ),
      ],
    );
  }
}
