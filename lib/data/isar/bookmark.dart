import 'package:isar_community/isar.dart';

part 'bookmark.g.dart';

/// A place the reader pinned. One bookmark per route; re-pinning updates it.
@collection
class Bookmark {
  Id id = Isar.autoIncrement;

  @Index()
  late String portalId;

  @Index(unique: true, replace: true)
  late String route;

  late String module;

  late String title;

  late String snippet;

  late double scrollOffset;

  @Index()
  late DateTime createdAt;
}
