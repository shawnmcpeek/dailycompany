import 'package:dailycompany/data/models/ignatius_content.dart';
import 'package:dailycompany/data/models/portal.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IgnatiusExercisesScreen extends ConsumerWidget {
  const IgnatiusExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final async = ref.watch(ignatiusProgramProvider);
    final unlocked = ref.watch(cycleUnlockedProvider);
    final day = ref.watch(selectedDayProvider);

    if (!unlocked) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          Text(
            'The Exercises',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'The 210-day program waits behind Companion.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return async.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (program) {
        if (!settings.ignatiusDirectorAcked) {
          return _DirectorGate(
            note: program.directorNote,
            onAck: ctrl.ackIgnatiusDirector,
          );
        }

        final elapsed = settings.ignatiusElapsedDays(day);
        final entry = program.forElapsed(elapsed);
        final completed = elapsed >= IgnatiusProgram.length;
        final started = elapsed >= 0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text(
              'The Exercises',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Thirty weeks. Sequential, not a calendar. Pause if you need '
              'to; restart clears the start date.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            if (!started) ...[
              Text(
                'The program has not been started.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ctrl.startIgnatiusProgram(day),
                child: const Text('Begin'),
              ),
            ] else ...[
              ChromeLabel(
                completed
                    ? 'Completed'
                    : settings.ignatiusProgramPaused
                        ? 'Paused · Week ${entry?.week ?? '—'}'
                        : 'Week ${entry?.week} · Day ${entry?.day}',
              ),
              const SizedBox(height: 8),
              if (entry != null) ...[
                Text(
                  entry.isRepetition
                      ? 'Repetition: ${entry.title}'
                      : entry.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ReadingBody(text: entry.textEn),
              ],
              const SizedBox(height: 28),
              if (!completed && !settings.ignatiusProgramPaused)
                OutlinedButton(
                  onPressed: () => ctrl.pauseIgnatiusProgram(day),
                  child: const Text('Pause'),
                ),
              if (settings.ignatiusProgramPaused)
                FilledButton(
                  onPressed: () => ctrl.resumeIgnatiusProgram(day),
                  child: const Text('Resume'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ctrl.restartIgnatiusProgram(),
                child: const Text('Restart'),
              ),
            ],
            const SizedBox(height: 32),
            ChromeLabel('Director'),
            const SizedBox(height: 8),
            Text(
              program.directorNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              PortalRegistry.ignatius.disclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _DirectorGate extends StatelessWidget {
  const _DirectorGate({required this.note, required this.onAck});

  final String note;
  final Future<void> Function() onAck;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text(
          'Before you begin',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text(note, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onAck,
          child: const Text('I understand'),
        ),
      ],
    );
  }
}
