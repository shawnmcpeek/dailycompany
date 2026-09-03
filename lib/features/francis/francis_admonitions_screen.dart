import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/models/francis_admonition.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FrancisAdmonitionsScreen extends ConsumerWidget {
  const FrancisAdmonitionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(francisAdmonitionsProvider);
    final portalId = ref.watch(currentPortalIdProvider);

    return async.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (book) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
            children: [
              Text(
                'Admonitions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Twenty-eight counsels, as he wrote them. Free, in any order.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              for (final c in book.chapters) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Admonition ${c.chapter} of ${book.chapters.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  subtitle: Text(
                    c.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push(
                    PortalRoutes.admonition(portalId, c.chapter),
                  ),
                ),
                const SectionRule(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class FrancisAdmonitionScreen extends ConsumerWidget {
  const FrancisAdmonitionScreen({super.key, required this.chapter});

  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(francisAdmonitionsProvider);

    return async.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (book) {
        FrancisAdmonition? found;
        for (final c in book.chapters) {
          if (c.chapter == chapter) {
            found = c;
            break;
          }
        }
        if (found == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Admonition not found.')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Admonition ${found.chapter} of ${book.chapters.length}',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            children: [
              Text(found.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              ReadingBody(text: found.textEn),
            ],
          ),
        );
      },
    );
  }
}
