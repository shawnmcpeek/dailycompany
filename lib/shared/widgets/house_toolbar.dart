import 'package:dailycompany/core/reading/reading_routes.dart';
import 'package:dailycompany/data/reading_memory.dart';
import 'package:dailycompany/shared/widgets/bookmark_button.dart';
import 'package:dailycompany/shared/widgets/hallway_back_button.dart';
import 'package:dailycompany/shared/widgets/reader_display_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Chrome for house tab roots: back to the hallway, optional bookmark, More.
class HouseToolbar extends ConsumerWidget {
  const HouseToolbar({
    super.key,
    this.showMore = true,
    this.showDisplay = false,
  });

  final bool showMore;
  final bool showDisplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context).uri.path;
    final spot = ref.watch(readingMemoryProvider).spots[route];
    final canBookmark = ReadingRoutes.isResumable(route);

    return Row(
      children: [
        const HallwayBackButton(),
        const Spacer(),
        if (showDisplay)
          IconButton(
            tooltip: 'Reading display',
            onPressed: () => showReaderDisplaySheet(context),
            icon: Text('Aa', style: Theme.of(context).textTheme.titleMedium),
          ),
        if (canBookmark)
          BookmarkToggleButton(
            route: route,
            title: spot?.title ?? 'Reading',
            snippet: spot?.snippet ?? '',
            scrollOffset: spot?.scrollOffset ?? 0,
          ),
        const BookmarksListButton(),
        if (showMore)
          IconButton(
            tooltip: 'More',
            onPressed: () => context.push('/more'),
            icon: const Icon(Icons.more_horiz),
          ),
      ],
    );
  }
}
