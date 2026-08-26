/// Cycle arithmetic for the de Sales daily entries (366 entries — see
/// portals-spec.md discussion for why this isn't 365 x 1).
///
/// Nothing in the app reads this yet — no Today screen, no spine resolver.
/// It exists so the emitted content can be verified: every day resolves,
/// every entry is reachable. See test/desales_cycle_test.dart.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

class DesalesEntry {
  const DesalesEntry({
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

  factory DesalesEntry.fromJson(Map<String, dynamic> json) {
    return DesalesEntry(
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

class DesalesCalendar {
  DesalesCalendar({
    required this.entries,
    required this._byDateCommon,
    required this._byDateLeap,
  }) : _byId = {for (final e in entries) e.id: e};

  final List<DesalesEntry> entries;
  final Map<String, List<int>> _byDateCommon;
  final Map<String, List<int>> _byDateLeap;
  final Map<int, DesalesEntry> _byId;

  static Future<DesalesCalendar> loadFromAssets() async {
    final entriesRaw = await rootBundle.loadString(
      'assets/content/desales/entries.json',
    );
    final calendarRaw = await rootBundle.loadString(
      'assets/content/desales/calendar.json',
    );
    return DesalesCalendar.fromJson(
      jsonDecode(entriesRaw) as Map<String, dynamic>,
      jsonDecode(calendarRaw) as Map<String, dynamic>,
    );
  }

  factory DesalesCalendar.fromJson(
    Map<String, dynamic> entriesJson,
    Map<String, dynamic> calendarJson,
  ) {
    final entries = (entriesJson['entries'] as List)
        .map((e) => DesalesEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    Map<String, List<int>> parseMap(String key) {
      final raw = calendarJson[key] as Map<String, dynamic>;
      return {
        for (final e in raw.entries)
          e.key: (e.value as List).cast<int>(),
      };
    }

    return DesalesCalendar(
      entries: entries,
      byDateCommon: parseMap('byDateCommon'),
      byDateLeap: parseMap('byDateLeap'),
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

  List<DesalesEntry> resolveFor(DateTime d) =>
      resolveIdsFor(d).map((id) => _byId[id]!).toList();

  DesalesEntry? byId(int id) => _byId[id];
}
