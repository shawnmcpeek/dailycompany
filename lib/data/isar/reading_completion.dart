import 'package:isar_community/isar.dart';

part 'reading_completion.g.dart';

/// Quiet day-level “I read” marks for the heatmap under More.
@collection
class ReadingCompletion {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('dateKey')])
  late String portalId;

  /// `yyyy-MM-dd`
  @Index()
  late String dateKey;

  late DateTime completedAt;

  int? readingId;
}
