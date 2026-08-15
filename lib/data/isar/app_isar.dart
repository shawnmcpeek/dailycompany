import 'dart:convert';
import 'dart:io';

import 'package:benedictdaily/data/isar/lectio_journal_entry.dart';
import 'package:benedictdaily/data/isar/reading_completion.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

abstract final class AppIsar {
  static Isar? _instance;

  static Isar get instance {
    final isar = _instance;
    if (isar == null) {
      throw StateError('Isar has not been opened. Call AppIsar.open() first.');
    }
    return isar;
  }

  static Future<Isar> open() async {
    if (_instance != null) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [LectioJournalEntrySchema, ReadingCompletionSchema],
      directory: dir.path,
      name: 'benedict_daily',
    );
    await _migrateJournalJsonIfNeeded(dir);
    return _instance!;
  }

  /// One-shot import from the old `lectio_journal.json` file.
  static Future<void> _migrateJournalJsonIfNeeded(Directory dir) async {
    final file = File('${dir.path}/lectio_journal.json');
    if (!await file.exists()) return;

    final isar = instance;
    final existing = await isar.lectioJournalEntrys.count();
    if (existing > 0) {
      await file.rename('${file.path}.migrated');
      return;
    }

    try {
      final raw = jsonDecode(await file.readAsString()) as List;
      if (raw.isEmpty) {
        await file.rename('${file.path}.migrated');
        return;
      }

      await isar.writeTxn(() async {
        for (final e in raw) {
          final map = e as Map<String, dynamic>;
          final entry = LectioJournalEntry()
            ..readingId = map['readingId'] as int
            ..text = map['text'] as String
            ..createdAt = DateTime.parse(map['createdAt'] as String);
          await isar.lectioJournalEntrys.put(entry);
        }
      });
      await file.rename('${file.path}.migrated');
    } catch (_) {
      // Leave the JSON in place if migration fails; Isar stays usable empty.
    }
  }
}
