import 'package:benedictdaily/data/content_catalog.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LifeScreen extends ConsumerWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final episodes = catalog.life;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text(
              'Life of Benedict',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Gregory the Great, Dialogues Book II · ${episodes.length} episodes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            for (final ep in episodes) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  ep.chapter == 0
                      ? 'Prologue'
                      : 'Episode ${ep.chapter} of ${episodes.where((e) => e.chapter > 0).length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                subtitle: Text(
                  ep.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () => context.push('/life/${ep.chapter}'),
              ),
              const SectionRule(),
            ],
          ],
        );
      },
    );
  }
}

class LifeEpisodeScreen extends ConsumerWidget {
  const LifeEpisodeScreen({super.key, required this.chapter});

  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    return catalogAsync.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        LifeEpisode? ep;
        for (final e in catalog.life) {
          if (e.chapter == chapter) {
            ep = e;
            break;
          }
        }
        if (ep == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Episode not found.')),
          );
        }
        final narrativeCount =
            catalog.life.where((e) => e.chapter > 0).length;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              ep.chapter == 0
                  ? 'Prologue'
                  : 'Episode ${ep.chapter} of $narrativeCount',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            children: [
              Text(ep.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              ReadingBody(text: ep.textEn),
            ],
          ),
        );
      },
    );
  }
}
