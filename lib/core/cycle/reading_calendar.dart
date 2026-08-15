/// Cycle arithmetic for the Rule reading calendar (122 portions × 3 cycles).
library;

import 'dart:convert';

import 'package:flutter/services.dart';

class RuleReading {
  const RuleReading({
    required this.id,
    required this.chapter,
    required this.chapterTitle,
    required this.portionInChapter,
    required this.portionsInChapter,
    required this.dateKeysCommon,
    required this.dateKeysLeap,
    required this.mergeIntoPreviousOnCommon,
    required this.textEn,
    required this.textLa,
    this.commentary,
    this.audioKeyEn,
  });

  final int id;
  final int chapter;
  final String chapterTitle;
  final int portionInChapter;
  final int portionsInChapter;
  final List<String> dateKeysCommon;
  final List<String> dateKeysLeap;
  final bool mergeIntoPreviousOnCommon;
  final String textEn;
  final String textLa;
  final String? commentary;
  final String? audioKeyEn;

  factory RuleReading.fromJson(Map<String, dynamic> json) {
    return RuleReading(
      id: json['id'] as int,
      chapter: json['chapter'] as int,
      chapterTitle: json['chapterTitle'] as String,
      portionInChapter: json['portionInChapter'] as int,
      portionsInChapter: json['portionsInChapter'] as int,
      dateKeysCommon: (json['dateKeysCommon'] as List).cast<String>(),
      dateKeysLeap: (json['dateKeysLeap'] as List).cast<String>(),
      mergeIntoPreviousOnCommon:
          json['mergeIntoPreviousOnCommon'] as bool? ?? false,
      textEn: json['textEn'] as String,
      textLa: json['textLa'] as String,
      commentary: json['commentary'] as String?,
      audioKeyEn: json['audioKeyEn'] as String?,
    );
  }
}

class ReadingCalendar {
  ReadingCalendar({
    required this.readings,
    required this._byDateCommon,
    required this._byDateLeap,
  }) : _byId = {for (final r in readings) r.id: r};

  final List<RuleReading> readings;
  final Map<String, List<int>> _byDateCommon;
  final Map<String, List<int>> _byDateLeap;
  final Map<int, RuleReading> _byId;

  static Future<ReadingCalendar> loadFromAssets() async {
    final readingsRaw = await rootBundle.loadString(
      'assets/content/rule_readings.json',
    );
    final calendarRaw = await rootBundle.loadString(
      'assets/content/reading_calendar.json',
    );
    return ReadingCalendar.fromJson(
      jsonDecode(readingsRaw) as Map<String, dynamic>,
      jsonDecode(calendarRaw) as Map<String, dynamic>,
    );
  }

  factory ReadingCalendar.fromJson(
    Map<String, dynamic> readingsJson,
    Map<String, dynamic> calendarJson,
  ) {
    final readings = (readingsJson['readings'] as List)
        .map((e) => RuleReading.fromJson(e as Map<String, dynamic>))
        .toList();
    Map<String, List<int>> parseMap(String key) {
      final raw = calendarJson[key] as Map<String, dynamic>;
      return {
        for (final entry in raw.entries)
          entry.key: (entry.value as List).cast<int>(),
      };
    }

    return ReadingCalendar(
      readings: readings,
      byDateCommon: parseMap('byDateCommon'),
      byDateLeap: parseMap('byDateLeap'),
    );
  }

  static bool isLeapYear(int year) =>
      (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));

  static String dateKey(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 1 = Winter (Jan 1–May 1), 2 = Summer (May 2–Aug 31), 3 = Autumn (Sep 1–Dec 31).
  int cycleNumber(DateTime d) {
    final ordinal = _dayOfYear(d);
    final may1 = _dayOfYear(DateTime(d.year, 5, 1));
    final aug31 = _dayOfYear(DateTime(d.year, 8, 31));
    if (ordinal <= may1) return 1;
    if (ordinal <= aug31) return 2;
    return 3;
  }

  String cycleLabel(DateTime d) {
    final n = cycleNumber(d);
    final name = switch (n) {
      1 => 'Winter',
      2 => 'Summer',
      _ => 'Autumn',
    };
    final leap = isLeapYear(d.year);
    final cycleDays = switch (n) {
      1 => leap ? 122 : 121,
      _ => 122,
    };
    final start = switch (n) {
      1 => DateTime(d.year, 1, 1),
      2 => DateTime(d.year, 5, 2),
      _ => DateTime(d.year, 9, 1),
    };
    final dayInCycle = d.difference(start).inDays + 1;
    return '$name cycle · day $dayInCycle of $cycleDays';
  }

  List<int> resolveIdsFor(DateTime d) {
    final key = dateKey(d);
    final table = isLeapYear(d.year) ? _byDateLeap : _byDateCommon;
    return List<int>.from(table[key] ?? const <int>[]);
  }

  List<RuleReading> resolveFor(DateTime d) =>
      resolveIdsFor(d).map((id) => _byId[id]!).toList();

  RuleReading? byId(int id) => _byId[id];

  static Color accentForStatic(DateTime d) {
    final ordinal = d.difference(DateTime(d.year, 1, 1)).inDays + 1;
    final may1 = DateTime(d.year, 5, 1).difference(DateTime(d.year, 1, 1)).inDays + 1;
    final aug31 =
        DateTime(d.year, 8, 31).difference(DateTime(d.year, 1, 1)).inDays + 1;
    if (ordinal <= may1) return const Color(0xFF4A4266);
    if (ordinal <= aug31) return const Color(0xFF4F6146);
    return const Color(0xFF7A3A2C);
  }

  Color accentFor(DateTime d) => accentForStatic(d);

  String readingHeadline(RuleReading r) {
    final ch = r.chapter == 0 ? 'Prologue' : 'Chapter ${r.chapter}';
    final title = r.chapterTitle;
    final portion = r.portionsInChapter > 1
        ? ' · reading ${r.portionInChapter} of ${r.portionsInChapter}'
        : '';
    return '$ch, $title$portion';
  }

  static int _dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year, 1, 1)).inDays + 1;
}
