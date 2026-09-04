import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/models/desales_meditation.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/continue_reading.dart';
import 'package:dailycompany/shared/widgets/reading_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DesalesMeditationsScreen extends ConsumerWidget {
  const DesalesMeditationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meditationsAsync = ref.watch(desalesMeditationsProvider);
    final portalId = ref.watch(currentPortalIdProvider);

    return meditationsAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (meditations) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text(
              'Meditations',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Part I of the Devout Life, ten meditations — "the begin '
              'here." Free, standalone, in any order.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            const ContinueReadingTile(module: 'meditations'),
            for (final m in meditations) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${m.title} of 10',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                subtitle: Text(
                  m.topic,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => context.push(
                  PortalRoutes.meditation(portalId, m.order),
                ),
              ),
              const SectionRule(),
            ],
          ],
        );
      },
    );
  }
}

class DesalesMeditationScreen extends ConsumerWidget {
  const DesalesMeditationScreen({super.key, required this.order});

  final int order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meditationsAsync = ref.watch(desalesMeditationsProvider);

    return meditationsAsync.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (meditations) {
        DesalesMeditation? m;
        for (final candidate in meditations) {
          if (candidate.order == order) {
            m = candidate;
            break;
          }
        }
        if (m == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Meditation not found.')),
          );
        }
        return ReadingPage(
          title: '${m.title} of 10',
          snippet: m.textEn,
          children: [
            Text(m.topic, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            ReadingBody(text: m.textEn),
          ],
        );
      },
    );
  }
}
