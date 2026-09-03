/// Shared cycle arithmetic for constructed year-portals (de Sales, Kempis, …).
///
/// Reads `assets/content/{portalId}/entries.json` + `calendar.json`.
/// Benedict keeps [ReadingCalendar] — this is not that spine.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

class CycleEntry {
  const CycleEntry({
    required this.id,
    required this.part,
    required this.partTitle,
    required this.chapter,
    required this.chapterTitle,
    required this.portionInChapter,
    required this.portionsInChapter,
    required this.textEn,
  });

  final int id;
  final int part;
  final String partTitle;
  final int chapter;
  final String chapterTitle;
  final int portionInChapter;
  final int portionsInChapter;
  final String textEn;

  factory CycleEntry.fromJson(Map<String, dynamic> json) {
    return CycleEntry(
      id: json['id'] as int,
      part: json['part'] as int,
      partTitle: json['partTitle'] as String,
      chapter: json['chapter'] as int,
      chapterTitle: json['chapterTitle'] as String,
      portionInChapter: json['portionInChapter'] as int,
      portionsInChapter: json['portionsInChapter'] as int,
      textEn: json['textEn'] as String,
    );
  }
}

class CycleCalendar {
  CycleCalendar({
    required this.portalId,
    required this.entries,
    required Map<String, List<int>> byDateCommon,
    required Map<String, List<int>> byDateLeap,
    int? dailyCount,
  })  : _byDateCommon = byDateCommon,
        _byDateLeap = byDateLeap,
        dailyCount = dailyCount ?? entries.length,
        _byId = {for (final e in entries) e.id: e};

  final String portalId;
  final List<CycleEntry> entries;

  /// Calendar-mapped count. Augustine's appendix lives past this.
  final int dailyCount;
  final Map<String, List<int>> _byDateCommon;
  final Map<String, List<int>> _byDateLeap;
  final Map<int, CycleEntry> _byId;

  /// "Book" for Kempis / Augustine / Gregory, "Part" otherwise.
  String get divisionNoun => switch (portalId) {
        'kempis' || 'augustine' || 'gregory' => 'Book',
        'john-cross' => 'Saying',
        'cassian' => 'Conference',
        _ => 'Part',
      };

  bool isAppendix(CycleEntry entry) => entry.id > dailyCount;

  String indexSubtitle(CycleEntry entry) {
    if (portalId == 'liguori') {
      return 'Visit ${entry.id} of ${entries.length}';
    }
    if (portalId == 'john-cross') {
      return 'Saying ${entry.id} of $dailyCount';
    }
    if (isAppendix(entry)) {
      return 'Appendix · Book ${entry.part} · Chapter ${entry.chapter}';
    }
    if (portalId == 'teresa-avila') {
      return '${entry.partTitle} · Chapter ${entry.chapter}';
    }
    if (portalId == 'cassian') {
      return 'Conference ${entry.part} · Chapter ${entry.chapter}';
    }
    return '$divisionNoun ${entry.part} · Chapter ${entry.chapter}';
  }

  String progressLabel(CycleEntry entry, {required bool readThrough}) {
    if (isAppendix(entry)) {
      return 'Appendix · Book ${entry.part} · Chapter ${entry.chapter}';
    }
    if (portalId == 'liguori') {
      return 'Visit ${entry.id} of ${entries.length}';
    }
    if (portalId == 'john-cross') {
      return 'Saying ${entry.id} of $dailyCount';
    }
    final total = readThrough ? entries.length : dailyCount;
    return 'Day ${entry.id} of $total';
  }

  static Future<CycleCalendar> load(String portalId) async {
    final entriesRaw = await rootBundle.loadString(
      'assets/content/$portalId/entries.json',
    );
    final calendarRaw = await rootBundle.loadString(
      'assets/content/$portalId/calendar.json',
    );
    return CycleCalendar.fromJson(
      jsonDecode(entriesRaw) as Map<String, dynamic>,
      jsonDecode(calendarRaw) as Map<String, dynamic>,
      portalId: portalId,
    );
  }

  factory CycleCalendar.fromJson(
    Map<String, dynamic> entriesJson,
    Map<String, dynamic> calendarJson, {
    String portalId = '',
  }) {
    final entries = (entriesJson['entries'] as List)
        .map((e) => CycleEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    Map<String, List<int>> parseMap(String key) {
      final raw = calendarJson[key] as Map<String, dynamic>;
      return {
        for (final e in raw.entries) e.key: (e.value as List).cast<int>(),
      };
    }

    return CycleCalendar(
      portalId: portalId,
      entries: entries,
      byDateCommon: parseMap('byDateCommon'),
      byDateLeap: parseMap('byDateLeap'),
      dailyCount: entriesJson['dailyEntries'] as int?,
    );
  }

  static bool isLeapYear(int year) =>
      (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));

  static String dateKey(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<int> resolveIdsFor(DateTime d) {
    final table = isLeapYear(d.year) ? _byDateLeap : _byDateCommon;
    return List<int>.from(table[dateKey(d)] ?? const <int>[]);
  }

  List<CycleEntry> resolveFor(DateTime d) =>
      resolveIdsFor(d).map((id) => _byId[id]!).toList();

  CycleEntry? byId(int id) => _byId[id];

  int chapterCountFor(int part) {
    final chapters = <int>{};
    for (final e in entries) {
      if (e.part == part) chapters.add(e.chapter);
    }
    return chapters.length;
  }

  /// First calendar date in [year] that carries this entry, if any.
  DateTime? dateForEntry(int id, int year) {
    final table = isLeapYear(year) ? _byDateLeap : _byDateCommon;
    for (final e in table.entries) {
      if (!e.value.contains(id)) continue;
      final parts = e.key.split('-');
      return DateTime(year, int.parse(parts[0]), int.parse(parts[1]));
    }
    return null;
  }
}
