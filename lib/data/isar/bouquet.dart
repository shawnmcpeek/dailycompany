import 'package:isar_community/isar.dart';

part 'bouquet.g.dart';

/// A kept line from de Sales' own instruction (Part II, ch. 7): after the
/// day's reading, pick one or two thoughts and carry them through the day.
/// Saved against the calendar date it was kept on ("MM-DD"), so it can
/// resurface a year later on the same day — a different query shape from
/// the cross-cycle journal (same content id, cycle apart), so this is its
/// own collection rather than an overload of LectioJournalEntry.
@collection
class Bouquet {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('dateKey')])
  late String portalId;

  /// `MM-DD` — the calendar day it was kept on, any year.
  @Index()
  late String dateKey;

  late String text;

  late DateTime createdAt;
}
