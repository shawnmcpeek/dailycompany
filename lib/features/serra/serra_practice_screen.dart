import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/guided_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SerraPracticeScreen extends ConsumerWidget {
  const SerraPracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(placeSaintProvider);

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
