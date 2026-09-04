import 'package:isar_community/isar.dart';

part 'reading_spot.g.dart';

/// Last scroll position for a reading route. One row per route.
@collection
class ReadingSpot {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String route;

  @Index()
  late String portalId;

  late String module;

  late String title;

  late String snippet;

  late double scrollOffset;

  @Index()
  late DateTime updatedAt;
}
