import 'dart:async';

import 'package:dailycompany/core/reading/reading_routes.dart';
import 'package:dailycompany/data/reading_memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// ListView that writes and restores scroll for the current reading route.
class ReadingScrollView extends ConsumerStatefulWidget {
  const ReadingScrollView({
    super.key,
    required this.title,
    required this.snippet,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 8, 24, 48),
    this.route,
  });

  final String title;
  final String snippet;
  final List<Widget> children;
  final EdgeInsets padding;
  final String? route;

  @override
  ConsumerState<ReadingScrollView> createState() => _ReadingScrollViewState();
}

class _ReadingScrollViewState extends ConsumerState<ReadingScrollView> {
  final _controller = ScrollController();
  Timer? _debounce;
  String? _route;
  var _restored = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route ??= widget.route ?? GoRouterState.of(context).uri.path;
    if (!_restored) {
      _restored = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
    }
  }

  Future<void> _restore() async {
    final route = _route;
    if (route == null || !ReadingRoutes.isResumable(route)) return;
    await ref.read(readingMemoryProvider.notifier).remember(
          route: route,
          title: widget.title,
          snippet: widget.snippet,
          scrollOffset:
              ref.read(readingMemoryProvider).spots[route]?.scrollOffset ?? 0,
        );
    if (!mounted) return;
    final offset = ref.read(readingMemoryProvider).spots[route]?.scrollOffset ?? 0;
    _jump(offset);
  }

  void _jump(double offset) {
    if (offset <= 0) return;
    var attempts = 0;
    void tryJump() {
      if (!mounted || !_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0 && attempts < 8) {
        attempts++;
        WidgetsBinding.instance.addPostFrameCallback((_) => tryJump());
        return;
      }
      _controller.jumpTo(offset.clamp(0, max));
    }

    tryJump();
  }

  void _onScroll() {
    final route = _route;
    if (route == null || !_controller.hasClients) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted || !_controller.hasClients) return;
      ref.read(readingMemoryProvider.notifier).remember(
            route: route,
            title: widget.title,
            snippet: widget.snippet,
            scrollOffset: _controller.offset,
          );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) _onScroll();
        return false;
      },
      child: ListView(
        controller: _controller,
        padding: widget.padding,
        children: widget.children,
      ),
    );
  }
}
