import 'package:dailycompany/core/haptics/bell_haptics.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SerraPracticeScreen extends ConsumerWidget {
  const SerraPracticeScreen({super.key});

  static const _angelusSlots = [
    ('angelus-dawn', 'Dawn'),
    ('angelus-noon', 'Noon'),
    ('angelus-evening', 'Evening'),
  ];

  Future<void> _pickAngelusTime(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.timeForOffice(id).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 12,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setOfficeTime(
          id,
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(placeSaintProvider);
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return async.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (place) {
        final alabado = place.prayer('alabado');
        final angelus = place.prayer('angelus');
        final crown = place.prayer('crown');
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text('Practice', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'The Alabado, the Angelus, and — if you want it — the Crown. '
              'Nothing invented for this house.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (alabado != null) ...[
              const SizedBox(height: 28),
              ChromeLabel(alabado.title),
              const SizedBox(height: 8),
              Text(alabado.note, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              if (alabado.textEs != null)
                Text(
                  alabado.textEs!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              if (alabado.textEn != null) ...[
                const SizedBox(height: 14),
                ReadingBody(text: alabado.textEn!),
              ],
            ],
            if (angelus != null) ...[
              const SizedBox(height: 28),
              ChromeLabel(angelus.title),
              const SizedBox(height: 8),
              Text(angelus.note, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              ReadingBody(text: angelus.textEn ?? ''),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Angelus bell'),
                subtitle: const Text(
                  'Dawn, noon, and evening. Same bells as the Hours.',
                ),
                value: settings.serraAngelusEnabled,
                onChanged: (v) async {
                  await ctrl.setSerraAngelusEnabled(v);
                  if (v && settings.hapticsEnabled) {
                    await BellHaptics.play(BellKind.angelus);
                  }
                },
              ),
              for (final slot in _angelusSlots)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(slot.$2),
                  subtitle: Text(settings.timeForOffice(slot.$1)),
                  enabled: settings.serraAngelusEnabled,
                  onTap: settings.serraAngelusEnabled
                      ? () => _pickAngelusTime(context, ref, slot.$1)
                      : null,
                ),
            ],
            if (crown != null) ...[
              const SizedBox(height: 28),
              ChromeLabel(crown.title),
              const SizedBox(height: 8),
              Text(crown.note, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              GuidedTimer(
                movements: [
                  for (final joy in crown.joys)
                    TimerMovement(
                      label: joy.title,
                      prompt: joy.prompt,
                      seconds: 90,
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
