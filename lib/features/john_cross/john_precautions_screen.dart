import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/models/john_precaution.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JohnPrecautionsScreen extends ConsumerWidget {
  const JohnPrecautionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(johnPrecautionsProvider);
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
                'Precautions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Against the world, the devil, and the flesh — as he wrote them. '
                'Free, in any order.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              for (final c in book.chapters) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    c.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push(
                    PortalRoutes.precaution(portalId, c.chapter),
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

class JohnPrecautionScreen extends ConsumerWidget {
  const JohnPrecautionScreen({super.key, required this.chapter});

  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(johnPrecautionsProvider);

    return async.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (book) {
        JohnPrecaution? found;
        for (final c in book.chapters) {
          if (c.chapter == chapter) {
            found = c;
            break;
          }
        }
        if (found == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Precaution not found.')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(found.title)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            children: [
              ReadingBody(text: found.textEn),
            ],
          ),
        );
      },
    );
  }
}
