import 'package:dailycompany/data/models/liguori_manner.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _remain = [
  TimerMovement(
    label: 'Remain',
    prompt: 'Stay with Him. No further prompt.',
    seconds: 600,
  ),
];

class LiguoriPracticeScreen extends ConsumerWidget {
  const LiguoriPracticeScreen({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.liguoriVisitTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 12,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setLiguoriVisitTime(
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final mannerAsync = ref.watch(liguoriMannerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text('The Visit', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Alphonsus’s own manner: the acts, a spiritual communion, '
          'and the closing prayer to Mary. Today’s Visit is on Today.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        mannerAsync.when(
          loading: () => const EmptyLoading(),
          error: (e, _) => Text('$e'),
          data: (manner) => _Prayers(manner: manner),
        ),
        const SizedBox(height: 28),
        ChromeLabel('Remain'),
        const SizedBox(height: 10),
        Text(
          'Ten minutes before Him. One visit, not a horarium.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const GuidedTimer(movements: _remain),
        const SizedBox(height: 28),
        ChromeLabel('Hour of the Visit'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          subtitle: const Text('One soft tap. Off by default.'),
          value: settings.liguoriVisitEnabled,
          onChanged: ctrl.setLiguoriVisitEnabled,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.liguoriVisitTime),
          enabled: settings.liguoriVisitEnabled,
          onTap: settings.liguoriVisitEnabled
              ? () => _pickTime(context, ref)
              : null,
        ),
      ],
    );
  }
}

class _Prayers extends StatelessWidget {
  const _Prayers({required this.manner});

  final LiguoriManner manner;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChromeLabel('Acts before each Visit'),
        const SizedBox(height: 10),
        Text(manner.actsBefore, style: body),
        const SizedBox(height: 28),
        ChromeLabel('Spiritual Communion'),
        const SizedBox(height: 10),
        Text(manner.spiritualCommunion, style: body),
        const SizedBox(height: 16),
        Text(manner.shorterAct, style: body?.copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(height: 28),
        ChromeLabel('After the Visit to Mary'),
        const SizedBox(height: 10),
        Text(manner.closingMary, style: body),
      ],
    );
  }
}
