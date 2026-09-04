import 'package:dailycompany/core/reading/reading_routes.dart';
import 'package:dailycompany/data/reading_memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BookmarkToggleButton extends ConsumerWidget {
  const BookmarkToggleButton({
    super.key,
    required this.route,
    required this.title,
    required this.snippet,
    this.scrollOffset = 0,
  });

  final String route;
  final String title;
  final String snippet;
  final double scrollOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ReadingRoutes.isResumable(route)) return const SizedBox.shrink();
    final saved = ref.watch(readingMemoryProvider).isBookmarked(route);
    return IconButton(
      tooltip: saved ? 'Remove bookmark' : 'Bookmark this place',
      onPressed: () => ref.read(readingMemoryProvider.notifier).toggleBookmark(
            route: route,
            title: title,
            snippet: snippet,
            scrollOffset: scrollOffset,
          ),
      icon: Icon(saved ? Icons.bookmark_added_outlined : Icons.bookmark_border),
      color: saved ? Theme.of(context).colorScheme.primary : null,
    );
  }
}

class BookmarksListButton extends StatelessWidget {
  const BookmarksListButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Bookmarks',
      onPressed: () => context.push('/bookmarks'),
      icon: const Icon(Icons.bookmarks_outlined),
    );
  }
}
