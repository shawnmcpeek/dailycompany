import 'package:dailycompany/data/reading_memory.dart';
import 'package:dailycompany/shared/widgets/bookmark_button.dart';
import 'package:dailycompany/shared/widgets/reading_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Nested chapter page: back to the shelf, bookmark, remembered scroll.
class ReadingPage extends ConsumerWidget {
  const ReadingPage({
    super.key,
    required this.title,
    required this.snippet,
    required this.children,
    this.actions = const [],
  });

  final String title;
  final String snippet;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context).uri.path;
    final scroll =
        ref.watch(readingMemoryProvider).spots[route]?.scrollOffset ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...actions,
          BookmarkToggleButton(
            route: route,
            title: title,
            snippet: snippet,
            scrollOffset: scroll,
          ),
        ],
      ),
      body: ReadingScrollView(
        title: title,
        snippet: snippet,
        children: children,
      ),
    );
  }
}
