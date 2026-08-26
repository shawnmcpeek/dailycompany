import 'package:dailycompany/core/notifications/aspiration_scheduler.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Movements per de Sales' own instruction, Part II ch. 10 — quoted loosely,
/// not verbatim (these are UI prompts, not the display text).
const _morningExercise = [
  TimerMovement(
    label: 'Thank',
    prompt: 'Thank God for keeping you safely through the night.',
    seconds: 40,
  ),
  TimerMovement(
    label: 'Foresee',
    prompt: 'Consider the occasions, duties, and temptations this day may bring.',
    seconds: 50,
  ),
  TimerMovement(
    label: 'Prepare',
    prompt: 'Resolve to use this day in God’s service.',
    seconds: 45,
  ),
  TimerMovement(
    label: 'Ask grace',
    prompt: 'Humble yourself, and ask the grace to carry it out.',
    seconds: 45,
  ),
];

/// Movements per Part II ch. 11.
const _eveningExamination = [
  TimerMovement(
    label: 'Thank',
    prompt: 'Thank God for preserving you through the day past.',
    seconds: 60,
  ),
  TimerMovement(
    label: 'Review',
    prompt: 'Recall where you have been, and what you have done.',
    seconds: 60,
  ),
  TimerMovement(
    label: 'Sorrow',
    prompt: 'Give thanks for what was good; ask forgiveness for what was not.',
    seconds: 60,
  ),
  TimerMovement(
    label: 'Commend',
    prompt: 'Commend yourself, your family, and the Church to God’s keeping.',
    seconds: 60,
  ),
];

const _aspirationLabels = {
  'a1': 'First',
  'a2': 'Second',
  'a3': 'Third',
};

class DesalesPracticeScreen extends ConsumerWidget {
  const DesalesPracticeScreen({super.key});

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    String slotId,
  ) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.timeForAspiration(slotId).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 12,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setAspirationTime(
          slotId,
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
          'The Bouquet, and two short guided forms from Part II.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        ChromeLabel('The Bouquet'),
        const SizedBox(height: 10),
        Text(
          'At the end of a reading, select a line and tap Keep — as someone '
          'leaving a garden takes a few flowers. It pins to the top of '
          'Today, and returns a year from now on the same day.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        const SectionRule(),
        const SizedBox(height: 24),
        ChromeLabel('Morning Exercise'),
        const SizedBox(height: 4),
        Text(
          'Four movements, about three minutes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        const _TimerCard(movements: _morningExercise),
        const SizedBox(height: 28),
        const SectionRule(),
        const SizedBox(height: 24),
        ChromeLabel('Evening Examination'),
        const SizedBox(height: 4),
        Text(
          'Four movements, about four minutes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        const _TimerCard(movements: _eveningExamination),
        const SizedBox(height: 28),
        const SectionRule(),
        const SizedBox(height: 24),
        ChromeLabel('Aspirations'),
        const SizedBox(height: 4),
        Text(
          'Brief, scattered returns to God through an ordinary day — de '
          'Sales’ own "retirement." A soft tap, never an alarm.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Aspiration reminders'),
          subtitle: Text(
            'Three a day, jittered a few minutes so they never land at the '
            'exact same time.',
          ),
          value: settings.desalesAspirationsEnabled,
          onChanged: ctrl.setDesalesAspirationsEnabled,
        ),
        const SizedBox(height: 8),
        for (final slotId in AspirationScheduler.slotIds) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${_aspirationLabels[slotId]} aspiration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              settings.timeForAspiration(slotId),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: IconButton(
              tooltip: 'Set time',
              icon: const Icon(Icons.schedule, size: 20),
              onPressed: () => _pickTime(context, ref, slotId),
            ),
          ),
          const SectionRule(),
        ],
      ],
    );
  }
}

/// Rebuilding GuidedTimer under a fresh key resets it — used here so
/// switching between the two exercises (or reopening this screen) never
/// carries over a stale mid-countdown state from the other one.
class _TimerCard extends StatefulWidget {
  const _TimerCard({required this.movements});

  final List<TimerMovement> movements;

  @override
  State<_TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<_TimerCard> {
  int _resetKey = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GuidedTimer(key: ValueKey(_resetKey), movements: widget.movements),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _resetKey++),
          child: const Text('Restart'),
        ),
      ],
    );
  }
}
