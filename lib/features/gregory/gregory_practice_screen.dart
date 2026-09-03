import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _sit = [
  TimerMovement(
    label: 'Sit',
    prompt: 'The government of souls is the art of arts.',
    seconds: 300,
  ),
];

class GregoryPracticeScreen extends ConsumerWidget {
  const GregoryPracticeScreen({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.reminderTimeFor('gregory').split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 8,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setCycleReminderTime(
          'gregory',
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final day = ref.watch(selectedDayProvider);
    final calAsync = ref.watch(cycleCalendarProvider('gregory'));

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text('Practice', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Today’s counsel is on Today. This is a place to sit with it — '
          'not a second office.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        calAsync.when(
          loading: () => const EmptyLoading(),
          error: (e, _) => Text('$e'),
          data: (cal) {
            final entries = cal.resolveFor(day);
            if (entries.isEmpty) return const SizedBox.shrink();
            final e = entries.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(e.chapterTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ReadingBody(text: e.textEn),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        ChromeLabel('Sit'),
        const SizedBox(height: 10),
        Text(
          'Five minutes with the day’s words. No invented rite.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const GuidedTimer(movements: _sit),
        const SizedBox(height: 28),
        ChromeLabel('Hour of the Rule'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          subtitle: const Text('One soft tap. Off by default.'),
          value: settings.reminderEnabledFor('gregory'),
          onChanged: (v) => ctrl.setCycleReminderEnabled('gregory', v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.reminderTimeFor('gregory')),
          enabled: settings.reminderEnabledFor('gregory'),
          onTap: settings.reminderEnabledFor('gregory')
              ? () => _pickTime(context, ref)
              : null,
        ),
      ],
    );
  }
}
