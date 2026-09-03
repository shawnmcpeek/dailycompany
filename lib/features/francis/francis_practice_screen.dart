import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FrancisPracticeScreen extends ConsumerWidget {
  const FrancisPracticeScreen({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.francisCanticleTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 7,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref
        .read(settingsProvider.notifier)
        .setFrancisCanticleTime(
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final canticleAsync = ref.watch(francisCanticleProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text('Canticle', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'The Canticle of the Creatures. His praise, as he left it.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        canticleAsync.when(
          loading: () => const EmptyLoading(),
          error: (e, _) => Text('$e'),
          data: (canticle) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                canticle.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              ReadingBody(text: canticle.textEn),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ChromeLabel('A time to praise'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me'),
          subtitle: const Text('One soft tap. Off by default.'),
          value: settings.francisCanticleEnabled,
          onChanged: ctrl.setFrancisCanticleEnabled,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Time'),
          subtitle: Text(settings.francisCanticleTime),
          enabled: settings.francisCanticleEnabled,
          onTap: settings.francisCanticleEnabled
              ? () => _pickTime(context, ref)
              : null,
        ),
      ],
    );
  }
}
