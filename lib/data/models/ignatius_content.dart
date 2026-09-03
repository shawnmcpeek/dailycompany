import 'dart:convert';

import 'package:flutter/services.dart';

class IgnatiusRule {
  const IgnatiusRule({
    required this.chapter,
    required this.week,
    required this.title,
    required this.textEn,
  });

  final int chapter;
  final int week;
  final String title;
  final String textEn;

  factory IgnatiusRule.fromJson(Map<String, dynamic> json) {
    return IgnatiusRule(
      chapter: json['chapter'] as int,
      week: json['week'] as int,
      title: json['title'] as String,
      textEn: json['textEn'] as String,
    );
  }
}

class IgnatiusRules {
  const IgnatiusRules({required this.title, required this.chapters});

  final String title;
  final List<IgnatiusRule> chapters;

  static Future<IgnatiusRules> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/ignatius/rules.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final chapters = (json['chapters'] as List)
        .map((e) => IgnatiusRule.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.chapter.compareTo(b.chapter));
    return IgnatiusRules(
      title: json['title'] as String,
      chapters: chapters,
    );
  }
}

class IgnatiusProgramEntry {
  const IgnatiusProgramEntry({
    required this.id,
    required this.week,
    required this.day,
    required this.part,
    required this.title,
    required this.textEn,
    required this.isRepetition,
  });

  final int id;
  final int week;
  final int day;
  final int part;
  final String title;
  final String textEn;
  final bool isRepetition;

  factory IgnatiusProgramEntry.fromJson(Map<String, dynamic> json) {
    return IgnatiusProgramEntry(
      id: json['id'] as int,
      week: json['week'] as int,
      day: json['day'] as int,
      part: json['part'] as int,
      title: json['title'] as String,
      textEn: json['textEn'] as String,
      isRepetition: json['isRepetition'] as bool? ?? false,
    );
  }
}

class IgnatiusProgram {
  const IgnatiusProgram({
    required this.directorNote,
    required this.entries,
  });

  final String directorNote;
  final List<IgnatiusProgramEntry> entries;

  static const length = 210;

  IgnatiusProgramEntry? byId(int id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Sequential, not modulo. [elapsedDays] 0 = day 1.
  IgnatiusProgramEntry? forElapsed(int elapsedDays) {
    if (elapsedDays < 0) return null;
    final id = elapsedDays >= length ? length : elapsedDays + 1;
    return byId(id);
  }

  static Future<IgnatiusProgram> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/ignatius/exercises.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final entries = (json['entries'] as List)
        .map((e) => IgnatiusProgramEntry.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return IgnatiusProgram(
      directorNote: json['directorNote'] as String,
      entries: entries,
    );
  }
}

class IgnatiusPrayer {
  const IgnatiusPrayer({
    required this.id,
    required this.title,
    required this.textEn,
  });

  final String id;
  final String title;
  final String textEn;

  factory IgnatiusPrayer.fromJson(Map<String, dynamic> json) {
    return IgnatiusPrayer(
      id: json['id'] as String,
      title: json['title'] as String,
      textEn: json['textEn'] as String,
    );
  }
}

class IgnatiusPrayers {
  const IgnatiusPrayers({required this.prayers});

  final List<IgnatiusPrayer> prayers;

  static Future<IgnatiusPrayers> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/ignatius/prayers.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return IgnatiusPrayers(
      prayers: (json['prayers'] as List)
          .map((e) => IgnatiusPrayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
