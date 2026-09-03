import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _recollection = [
  TimerMovement(
    label: 'Enter',
    prompt:
        'It is called recollection because the soul collects together all '
        'the faculties and enters within itself to be with its God.',
    seconds: 180,
  ),
  TimerMovement(
    label: 'Remain',
    prompt:
        'The Lord is within us, and we should be there with Him. '
        'Look at Him who never fails His friends.',
    seconds: 420,
  ),
];

class TeresaPracticeScreen extends ConsumerWidget {
  const TeresaPracticeScreen({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.reminderTimeFor('teresa-avila').split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 7,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setCycleReminderTime(
          'teresa-avila',
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
          'Recollection',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'From the Way of Perfection: the soul collects its faculties and '
          'enters within itself. Her own instruction, not a method invented here.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        ChromeLabel('Prayer of recollection'),
        const SizedBox(height: 10),
        Text(
          'Three minutes to enter, seven to remain. Shut the senses up '
          'within this little heaven of the soul.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const GuidedTimer(movements: _recollection),
        const SizedBox(height: 28),
        ChromeLabel('Hour of recollection'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          subtitle: const Text('One soft tap. Off by default.'),
          value: settings.reminderEnabledFor('teresa-avila'),
          onChanged: (v) => ctrl.setCycleReminderEnabled('teresa-avila', v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.reminderTimeFor('teresa-avila')),
          enabled: settings.reminderEnabledFor('teresa-avila'),
          onTap: settings.reminderEnabledFor('teresa-avila')
              ? () => _pickTime(context, ref)
              : null,
        ),
      ],
    );
  }
}
