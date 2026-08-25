import 'package:isar_community/isar.dart';

part 'lectio_journal_entry.g.dart';

@collection
class LectioJournalEntry {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('readingId')])
  late String portalId;

  @Index()
  late int readingId;

  late String text;

  @Index()
  late DateTime createdAt;
}
