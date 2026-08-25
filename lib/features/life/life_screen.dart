import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/data/content_catalog.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/iap/oblate_paywall_screen.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LifeScreen extends ConsumerWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    final unlocked = ref.watch(oblateUnlockedProvider);
    final portalId = ref.watch(currentPortalIdProvider);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final episodes = catalog.life;
        final numbered = episodes.where((e) => e.chapter > 0).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text(
              'Life of Benedict',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              unlocked
                  ? 'Gregory the Great, Dialogues Book II · $numbered episodes'
                  : 'Free through episode 5 · Oblate unlocks the rest',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            for (final ep in episodes) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  ep.chapter == 0
                      ? 'Prologue'
                      : 'Episode ${ep.chapter} of $numbered',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                subtitle: Text(
                  ep.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: (!unlocked && !IapController.lifeChapterFree(ep.chapter))
                    ? Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      )
                    : null,
                onTap: () {
                  if (!unlocked && !IapController.lifeChapterFree(ep.chapter)) {
                    openOblatePaywall(context);
                    return;
                  }
                  context.push(PortalRoutes.lifeEpisode(portalId, ep.chapter));
                },
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
    final unlocked = ref.watch(oblateUnlockedProvider);
    if (!unlocked && !IapController.lifeChapterFree(chapter)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Life')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Episodes beyond 5 are part of Oblate.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => openOblatePaywall(context),
                child: const Text('Unlock Oblate'),
              ),
            ],
          ),
        ),
      );
    }

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
        final numbered = catalog.life.where((e) => e.chapter > 0).length;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              ep.chapter == 0
                  ? 'Prologue'
                  : 'Episode ${ep.chapter} of $numbered',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            children: [
              Text(ep.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              ReadingBody(text: ep.textEn),
            ],
          ),
        );
      },
    );
  }
}
