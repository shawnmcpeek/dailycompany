import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _offering = [
  TimerMovement(
    label: 'Offer',
    prompt:
        'O my God, O Most Blessed Trinity, I desire to love Thee and to '
        'make Thee loved — to labour for the glory of Holy Church by saving '
        'souls here upon earth. I desire to fulfill perfectly Thy Holy Will.',
    seconds: 180,
  ),
  TimerMovement(
    label: 'The day',
    prompt: 'The little way: this day’s ordinary things, offered.',
    seconds: 300,
  ),
];

class TheresePracticeScreen extends ConsumerWidget {
  const TheresePracticeScreen({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.reminderTimeFor('therese').split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 7,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setCycleReminderTime(
          'therese',
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
          'The offering',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Her own act of oblation, from Taylor’s English of the 1898 '
          'Pauline text — not a Carmelite rite invented here.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        ChromeLabel('Little Way'),
        const SizedBox(height: 10),
        Text(
          'Three minutes with her words, five with the day’s ordinary things.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const GuidedTimer(movements: _offering),
        const SizedBox(height: 28),
        ChromeLabel('Hour of offering'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          subtitle: const Text('One soft tap. Off by default.'),
          value: settings.reminderEnabledFor('therese'),
          onChanged: (v) => ctrl.setCycleReminderEnabled('therese', v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.reminderTimeFor('therese')),
          enabled: settings.reminderEnabledFor('therese'),
          onTap: settings.reminderEnabledFor('therese')
              ? () => _pickTime(context, ref)
              : null,
        ),
      ],
    );
  }
}
