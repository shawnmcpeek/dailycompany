import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/models/francis_story.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/iap/paywall.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/continue_reading.dart';
import 'package:dailycompany/shared/widgets/reading_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FrancisStoriesScreen extends ConsumerWidget {
  const FrancisStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(francisStoriesProvider);
    final portalId = ref.watch(currentPortalIdProvider);
    final unlocked = ref.watch(cycleUnlockedProvider);

    return async.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (book) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text('Stories', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${book.label} — the Little Flowers, not his own writings. '
              'They sit on this shelf, never in the daily cycle.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            const ContinueReadingTile(module: 'stories'),
            if (!unlocked)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Unlock Companion'),
                subtitle: const Text('The stories come with the writings.'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => openPaywall(context),
              )
            else
              for (final c in book.chapters) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Story ${c.chapter} of ${book.chapters.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  subtitle: Text(
                    c.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () =>
                      context.push(PortalRoutes.story(portalId, c.chapter)),
                ),
                const SectionRule(),
              ],
          ],
        );
      },
    );
  }
}

class FrancisStoryScreen extends ConsumerWidget {
  const FrancisStoryScreen({super.key, required this.chapter});

  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(francisStoriesProvider);
    final unlocked = ref.watch(cycleUnlockedProvider);

    if (!unlocked) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: TextButton(
            onPressed: () => openPaywall(context),
            child: const Text('Unlock Companion'),
          ),
        ),
      );
    }

    return async.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (book) {
        FrancisStory? found;
        for (final c in book.chapters) {
          if (c.chapter == chapter) {
            found = c;
            break;
          }
        }
        if (found == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Story not found.')),
          );
        }
        return ReadingPage(
          title: 'Story ${found.chapter} of ${book.chapters.length}',
          snippet: found.textEn,
          children: [
            Text(found.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            ReadingBody(text: found.textEn),
          ],
        );
      },
    );
  }
}
