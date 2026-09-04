import 'package:dailycompany/data/companion.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/data/reading_memory.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(readingMemoryProvider).bookmarks;

    if (places.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          Text(
            'No bookmarks yet.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'While you read, tap the bookmark to keep a place — a chapter, '
            'or a passage you want to return to.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      );
    }

    final order = <String>[];
    final grouped = <String, List<SavedPlace>>{};
    for (final place in places) {
      if (!grouped.containsKey(place.portalId)) {
        order.add(place.portalId);
      }
      grouped.putIfAbsent(place.portalId, () => []).add(place);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        for (var i = 0; i < order.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          ChromeLabel(Companions.byId(order[i])?.name ?? order[i]),
          const SizedBox(height: 12),
          for (final place in grouped[order[i]]!) ...[
            Dismissible(
              key: ValueKey(place.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => ref
                  .read(readingMemoryProvider.notifier)
                  .removeBookmark(place.id),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(place.title),
                subtitle: place.snippet.isEmpty
                    ? null
                    : Text(
                        place.snippet,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () => _open(context, ref, place),
              ),
            ),
            const SectionRule(),
          ],
        ],
      ],
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    SavedPlace place,
  ) async {
    await ref.read(readingMemoryProvider.notifier).prepareJump(place);
    final current = ref.read(currentPortalIdProvider);
    if (current != place.portalId) {
      await ref.read(settingsProvider.notifier).setCompanion(place.portalId);
    }
    if (!context.mounted) return;
    context.go(place.route);
  }
}
