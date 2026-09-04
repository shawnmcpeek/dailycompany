import 'package:dailycompany/core/reading/reading_routes.dart';
import 'package:dailycompany/data/isar/app_isar.dart';
import 'package:dailycompany/data/isar/bookmark.dart';
import 'package:dailycompany/data/isar/reading_spot.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

/// UI row for a pinned reading. Content itself stays in JSON.
class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.portalId,
    required this.route,
    required this.module,
    required this.title,
    required this.snippet,
    required this.scrollOffset,
    required this.createdAt,
  });

  final int id;
  final String portalId;
  final String route;
  final String module;
  final String title;
  final String snippet;
  final double scrollOffset;
  final DateTime createdAt;

  factory SavedPlace.fromIsar(Bookmark row) => SavedPlace(
        id: row.id,
        portalId: row.portalId,
        route: row.route,
        module: row.module,
        title: row.title,
        snippet: row.snippet,
        scrollOffset: row.scrollOffset,
        createdAt: row.createdAt,
      );
}

class LastReading {
  const LastReading({
    required this.route,
    required this.portalId,
    required this.module,
    required this.title,
    required this.snippet,
    required this.scrollOffset,
    required this.updatedAt,
  });

  final String route;
  final String portalId;
  final String module;
  final String title;
  final String snippet;
  final double scrollOffset;
  final DateTime updatedAt;

  factory LastReading.fromIsar(ReadingSpot row) => LastReading(
        route: row.route,
        portalId: row.portalId,
        module: row.module,
        title: row.title,
        snippet: row.snippet,
        scrollOffset: row.scrollOffset,
        updatedAt: row.updatedAt,
      );
}

class ReadingMemoryState {
  const ReadingMemoryState({
    this.bookmarks = const [],
    this.spots = const {},
  });

  final List<SavedPlace> bookmarks;
  final Map<String, LastReading> spots;

  bool isBookmarked(String route) =>
      bookmarks.any((b) => b.route == route);

  LastReading? lastFor({required String portalId, String? module}) {
    final matches = spots.values.where((s) {
      if (s.portalId != portalId) return false;
      if (module != null && s.module != module) return false;
      return ReadingRoutes.isResumable(s.route, portalId);
    });
    LastReading? latest;
    for (final s in matches) {
      if (latest == null || s.updatedAt.isAfter(latest.updatedAt)) {
        latest = s;
      }
    }
    return latest;
  }

  LastReading? lastChapterFor({
    required String portalId,
    required String module,
  }) {
    final last = lastFor(portalId: portalId, module: module);
    if (last == null) return null;
    if (ReadingRoutes.isShelfRoot(last.route)) return null;
    if (!ReadingRoutes.isResumable(last.route, portalId)) return null;
    if (ReadingRoutes.pageModules.contains(module)) return null;
    return last;
  }

  ReadingMemoryState copyWith({
    List<SavedPlace>? bookmarks,
    Map<String, LastReading>? spots,
  }) =>
      ReadingMemoryState(
        bookmarks: bookmarks ?? this.bookmarks,
        spots: spots ?? this.spots,
      );
}

final readingMemoryProvider =
    StateNotifierProvider<ReadingMemoryController, ReadingMemoryState>((ref) {
  return ReadingMemoryController(ref);
});

class ReadingMemoryController extends StateNotifier<ReadingMemoryState> {
  ReadingMemoryController(this._ref) : super(const ReadingMemoryState()) {
    _load();
  }

  final Ref _ref;
  Isar get _isar => _ref.read(isarProvider);

  Future<void> _load() async {
    if (!AppIsar.isOpen) return;
    try {
      final bookmarkRows =
          await _isar.bookmarks.where().sortByCreatedAtDesc().findAll();
      final spotRows = await _isar.readingSpots.where().findAll();
      state = ReadingMemoryState(
        bookmarks: bookmarkRows.map(SavedPlace.fromIsar).toList(),
        spots: {
          for (final row in spotRows) row.route: LastReading.fromIsar(row),
        },
      );
    } catch (_) {
      // Memory is optional chrome; empty state is safe.
    }
  }

  Future<void> remember({
    required String route,
    required String title,
    required String snippet,
    required double scrollOffset,
  }) async {
    if (!ReadingRoutes.isResumable(route)) return;
    final portalId = ReadingRoutes.portalId(route);
    final module = ReadingRoutes.module(route);
    if (portalId == null || module == null) return;
    if (!AppIsar.isOpen) return;

    final row = ReadingSpot()
      ..route = route
      ..portalId = portalId
      ..module = module
      ..title = title
      ..snippet = ReadingRoutes.snippet(snippet)
      ..scrollOffset = scrollOffset
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.readingSpots.putByRoute(row);
    });

    final next = Map<String, LastReading>.from(state.spots)
      ..[route] = LastReading.fromIsar(row);
    state = state.copyWith(spots: next);

    await _ref.read(settingsProvider.notifier).setLastReadingRoute(
          portalId,
          route,
        );
  }

  Future<void> applyScroll(String route, double scrollOffset) async {
    final existing = state.spots[route];
    if (existing == null) return;
    await remember(
      route: route,
      title: existing.title,
      snippet: existing.snippet,
      scrollOffset: scrollOffset,
    );
  }

  Future<void> toggleBookmark({
    required String route,
    required String title,
    required String snippet,
    required double scrollOffset,
  }) async {
    if (!ReadingRoutes.isResumable(route)) return;
    final portalId = ReadingRoutes.portalId(route);
    final module = ReadingRoutes.module(route);
    if (portalId == null || module == null) return;
    if (!AppIsar.isOpen) return;

    final existing = await _isar.bookmarks.getByRoute(route);
    if (existing != null) {
      await _isar.writeTxn(() async {
        await _isar.bookmarks.delete(existing.id);
      });
      await _load();
      return;
    }

    final row = Bookmark()
      ..portalId = portalId
      ..route = route
      ..module = module
      ..title = title
      ..snippet = ReadingRoutes.snippet(snippet)
      ..scrollOffset = scrollOffset
      ..createdAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.bookmarks.putByRoute(row);
    });
    await remember(
      route: route,
      title: title,
      snippet: snippet,
      scrollOffset: scrollOffset,
    );
    await _load();
  }

  Future<void> removeBookmark(int id) async {
    if (!AppIsar.isOpen) return;
    await _isar.writeTxn(() async {
      await _isar.bookmarks.delete(id);
    });
    await _load();
  }

  /// Point the stored scroll at this bookmark so the page opens there.
  Future<void> prepareJump(SavedPlace place) async {
    await remember(
      route: place.route,
      title: place.title,
      snippet: place.snippet,
      scrollOffset: place.scrollOffset,
    );
  }
}
