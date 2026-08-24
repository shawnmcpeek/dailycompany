import 'dart:io';

import 'package:dailycompany/core/cycle/life_track.dart';
import 'package:dailycompany/core/diagnostics/diagnostics_log.dart';
import 'package:dailycompany/core/diagnostics/journal_failure_reporter.dart';
import 'package:dailycompany/data/content_catalog.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Plain-text Lectio journal export — file + system share sheet only.
abstract final class JournalExport {
  static Future<void> share(
    BuildContext context, {
    required List<JournalEntry> entries,
    ContentCatalog? catalog,
  }) async {
    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No journal entries to export.')),
        );
      }
      return;
    }

    try {
      final body = format(entries, catalog: catalog);
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final file = File('${dir.path}/benedict_lectio_journal_$stamp.txt');
      await file.writeAsString(body);

      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box == null ? null : box.localToGlobal(Offset.zero) & box.size;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'text/plain',
              name: 'benedict_lectio_journal_$stamp.txt',
            ),
          ],
          text: 'Daily Company · Lectio journal',
          sharePositionOrigin: origin,
        ),
      );
      await DiagnosticsLog.instance.record(
        operation: 'journal_export_ok',
        metadata: {'entry_count': entries.length},
      );
    } catch (e, st) {
      await JournalFailureReporter.report(
        key: 'journal_export_failed',
        characterCount: 0,
        error: e,
        stackTrace: st,
        asException: true,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export journal.')),
        );
      }
    }
  }

  static String format(
    List<JournalEntry> entries, {
    ContentCatalog? catalog,
  }) {
    final sorted = [...entries]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final buf = StringBuffer()
      ..writeln('Daily Company — Lectio journal')
      ..writeln('Exported ${DateFormat('yyyy-MM-dd').format(DateTime.now())}')
      ..writeln()
      ..writeln('---')
      ..writeln();

    for (final e in sorted) {
      final rule = catalog?.calendar.byId(e.readingId);
      String label;
      if (rule != null) {
        label = catalog!.calendar.readingHeadline(rule);
      } else if (LifeTrack.isJournalId(e.readingId) && catalog != null) {
        final chapter = e.readingId - LifeTrack.journalIdBase;
        LifeEpisode? ep;
        for (final item in catalog.life) {
          if (item.chapter == chapter) {
            ep = item;
            break;
          }
        }
        if (ep == null) {
          label = 'Life · chapter $chapter';
        } else {
          final numbered = catalog.life.where((x) => x.chapter > 0).length;
          label =
              'Life · ${LifeTrack.headline(ep, numbered: numbered)} · ${ep.title}';
        }
      } else {
        label = 'Reading ${e.readingId}';
      }
      buf
        ..writeln(dateFmt.format(e.createdAt.toLocal()))
        ..writeln(label)
        ..writeln()
        ..writeln(e.text.trim())
        ..writeln()
        ..writeln('---')
        ..writeln();
    }
    return buf.toString();
  }
}
