import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/data/reading_memory.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ContinueReadingTile extends ConsumerWidget {
  const ContinueReadingTile({super.key, required this.module});

  final String module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portalId = ref.watch(currentPortalIdProvider);
    final last = ref.watch(readingMemoryProvider).lastChapterFor(
          portalId: portalId,
          module: module,
        );
    if (last == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: HubNavButton(
        title: 'Continue',
        subtitle: last.title,
        actionLabel: 'Resume',
        onPressed: () => context.push(last.route),
      ),
    );
  }
}
