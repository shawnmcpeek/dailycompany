import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/diagnostics/diagnostics_log.dart';
import 'package:dailycompany/core/diagnostics/journal_failure_reporter.dart';
import 'package:dailycompany/data/isar/bookmark.dart';
import 'package:dailycompany/data/isar/bouquet.dart';
import 'package:dailycompany/data/isar/lectio_journal_entry.dart';
import 'package:dailycompany/data/isar/reading_completion.dart';
import 'package:dailycompany/data/isar/reading_spot.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

abstract final class AppIsar {
  static Isar? _instance;

  static bool get isOpen => _instance != null && _instance!.isOpen;

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
      [
        LectioJournalEntrySchema,
        ReadingCompletionSchema,
        BouquetSchema,
        ReadingSpotSchema,
        BookmarkSchema,
      ],
      directory: dir.path,
      name: 'daily_company',
    );
    await _backfillPortalId();
    await _migrateJournalJsonIfNeeded(dir);
    return _instance!;
  }

  /// Rows written before the portal split have no `portalId` — Isar reads
  /// that back as `''`, not a null we could distinguish from "not set" any
  /// other way. Every one of them is Benedict's, since Benedict was the
  /// only portal that existed when they were written.
  static Future<void> _backfillPortalId() async {
    final isar = instance;
    try {
      final journalRows = await isar.lectioJournalEntrys
          .filter()
          .portalIdEqualTo('')
          .findAll();
      final completionRows = await isar.readingCompletions
          .filter()
          .portalIdEqualTo('')
          .findAll();
      if (journalRows.isEmpty && completionRows.isEmpty) return;

      await isar.writeTxn(() async {
        for (final row in journalRows) {
          row.portalId = 'benedict';
          await isar.lectioJournalEntrys.put(row);
        }
        for (final row in completionRows) {
          row.portalId = 'benedict';
          await isar.readingCompletions.put(row);
        }
      });
      await DiagnosticsLog.instance.record(
        operation: 'portal_id_backfill_ok',
        metadata: {
          'journal_rows': journalRows.length,
          'completion_rows': completionRows.length,
        },
      );
    } catch (e, st) {
      await JournalFailureReporter.report(
        key: 'portal_id_backfill_failed',
        characterCount: 0,
        error: e,
        stackTrace: st,
        asException: true,
      );
      // Leave rows as they are; nothing filters on portalId yet, so an
      // unbackfilled '' row is inert rather than a visible bug.
    }
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
            ..portalId = 'benedict'
            ..readingId = map['readingId'] as int
            ..text = map['text'] as String
            ..createdAt = DateTime.parse(map['createdAt'] as String);
          await isar.lectioJournalEntrys.put(entry);
        }
      });
      await file.rename('${file.path}.migrated');
      await DiagnosticsLog.instance.record(
        operation: 'journal_migrate_ok',
        metadata: {'imported_count': raw.length},
      );
    } catch (e, st) {
      await JournalFailureReporter.report(
        key: 'journal_migrate_failed',
        characterCount: 0,
        error: e,
        stackTrace: st,
        asException: true,
      );
      // Leave the JSON in place if migration fails; Isar stays usable empty.
    }
  }
}
