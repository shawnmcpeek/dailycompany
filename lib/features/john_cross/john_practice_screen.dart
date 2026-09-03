import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _sit = [
  TimerMovement(
    label: 'Sit',
    prompt: 'One saying. Do not add to it.',
    seconds: 300,
  ),
];

class JohnPracticeScreen extends ConsumerWidget {
  const JohnPracticeScreen({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.reminderTimeFor('john-cross').split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 7,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setCycleReminderTime(
          'john-cross',
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final day = ref.watch(selectedDayProvider);
    final calAsync = ref.watch(cycleCalendarProvider('john-cross'));

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text('Practice', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Sit with today’s saying. Nothing added to his words.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        calAsync.when(
          loading: () => const EmptyLoading(),
          error: (e, _) => Text('$e'),
          data: (cal) {
            final entries = cal.resolveFor(day);
            if (entries.isEmpty) {
              return const Text('No saying for this day.');
            }
            return _Saying(entry: entries.first);
          },
        ),
        const SizedBox(height: 28),
        ChromeLabel('Sit'),
        const SizedBox(height: 10),
        Text(
          'Five minutes. The saying is the whole of it.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const GuidedTimer(movements: _sit),
        const SizedBox(height: 28),
        ChromeLabel('Hour of the saying'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          subtitle: const Text('One soft tap. Off by default.'),
          value: settings.reminderEnabledFor('john-cross'),
          onChanged: (v) => ctrl.setCycleReminderEnabled('john-cross', v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.reminderTimeFor('john-cross')),
          enabled: settings.reminderEnabledFor('john-cross'),
          onTap: settings.reminderEnabledFor('john-cross')
              ? () => _pickTime(context, ref)
              : null,
        ),
      ],
    );
  }
}

class _Saying extends StatelessWidget {
  const _Saying({required this.entry});

  final CycleEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(entry.chapterTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ReadingBody(text: entry.textEn),
      ],
    );
  }
}
