import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/models/ignatius_content.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/continue_reading.dart';
import 'package:dailycompany/shared/widgets/reading_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IgnatiusDiscernmentScreen extends ConsumerWidget {
  const IgnatiusDiscernmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ignatiusRulesProvider);
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
                'Discernment',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Twenty-two rules, as he numbered them. Fourteen for the '
                'First Week, eight for the Second. Free, in any order.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              const ContinueReadingTile(module: 'discernment'),
              for (final c in book.chapters) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Week ${c.week} · ${c.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push(
                    PortalRoutes.discernmentRule(portalId, c.chapter),
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

class IgnatiusRuleScreen extends ConsumerWidget {
  const IgnatiusRuleScreen({super.key, required this.chapter});

  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ignatiusRulesProvider);

    return async.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (book) {
        IgnatiusRule? found;
        for (final c in book.chapters) {
          if (c.chapter == chapter) {
            found = c;
            break;
          }
        }
        if (found == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Rule not found.')),
          );
        }
        return ReadingPage(
          title: found.title,
          snippet: found.textEn,
          children: [
            ReadingBody(text: found.textEn),
          ],
        );
      },
    );
  }
}
