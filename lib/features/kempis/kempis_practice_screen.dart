import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _cellSilence = [
  TimerMovement(
    label: 'Silence',
    prompt: 'Withdraw into the inner cell. Sit with the day’s words.',
    seconds: 300,
  ),
];

class KempisPracticeScreen extends ConsumerWidget {
  const KempisPracticeScreen({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.kempisCellTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 20,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setKempisCellTime(
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
        Text('Practice', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'The Cell — solitude and silence, from Book I chapter 20.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        ChromeLabel('The Cell'),
        const SizedBox(height: 10),
        Text(
          'Learn to withdraw thy heart from the love of things visible, '
          'and to turn thyself to things inward. Five minutes of unguided '
          'silence. No movements, no prompt beyond the sitting.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const GuidedTimer(movements: _cellSilence),
        const SizedBox(height: 28),
        ChromeLabel('Hour of withdrawal'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          subtitle: const Text('One soft tap. Off by default.'),
          value: settings.kempisCellEnabled,
          onChanged: ctrl.setKempisCellEnabled,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.kempisCellTime),
          enabled: settings.kempisCellEnabled,
          onTap: settings.kempisCellEnabled
              ? () => _pickTime(context, ref)
              : null,
        ),
      ],
    );
  }
}
