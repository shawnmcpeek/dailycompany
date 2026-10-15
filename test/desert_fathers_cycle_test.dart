import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/desert-fathers/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/desert-fathers/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(
    entries,
    calendar,
    portalId: 'desert-fathers',
  );
}

void main() {
  final calendar = loadFixture();

  test('daily year is 366; appendix keeps the rest of Budge', () {
    expect(calendar.dailyCount, 366);
    expect(calendar.entries.length, greaterThan(366));
    expect(calendar.divisionNoun, 'Book');
  });

  test('the named edition is present: Anthony, Palladius, sayings', () {
    final parts = calendar.entries.map((e) => e.part).toSet();
    expect(parts, containsAll([1, 2, 3, 4, 5]));
    final blob = calendar.entries
        .map((e) => '${e.chapterTitle} ${e.part}')
        .join(' ')
        .toLowerCase();
    expect(blob, contains('anthony'));
    final words = calendar.entries.fold<int>(
      0,
      (n, e) => n + e.textEn.split(RegExp(r'\s+')).length,
    );
    expect(words, greaterThan(200000));
  });

  test('leap year maps daily entries 1:1; appendix stays off the calendar', () {
    const year = 2024;
    expect(CycleCalendar.isLeapYear(year), isTrue);
    final seen = <int>{};
    for (
      var day = DateTime(year, 1, 1);
      !day.isAfter(DateTime(year, 12, 31));
      day = day.add(const Duration(days: 1))
    ) {
      final ids = calendar.resolveIdsFor(day);
      expect(ids, isNotEmpty, reason: CycleCalendar.dateKey(day));
      for (final id in ids) {
        expect(id, lessThanOrEqualTo(calendar.dailyCount));
      }
      seen.addAll(ids);
    }
    expect(seen, {for (var i = 1; i <= calendar.dailyCount; i++) i});
  });

  test('week-strip titles are sentences, not saying numbers or drop-caps', () {
    for (final e in calendar.entries) {
      expect(
        e.chapterTitle,
        isNot(matches(RegExp(r'^\d+$'))),
        reason: '${e.id}',
      );
      expect(
        e.chapterTitle,
        isNot(startsWith('ND ')),
        reason: '${e.id}',
      );
      expect(
        e.chapterTitle,
        isNot(startsWith('BBA ')),
        reason: '${e.id}',
      );
      expect(
        e.chapterTitle,
        isNot(matches(RegExp(r'\bAbbd\b'))),
        reason: '${e.id}',
      );
      expect(
        e.chapterTitle,
        isNot(matches(RegExp(r'\bAbbi\b'))),
        reason: '${e.id}',
      );
      expect(e.chapterTitle.length, greaterThan(8), reason: '${e.id}');
    }
    final oct = calendar.resolveFor(DateTime(2026, 10, 15)).first;
    expect(oct.chapterTitle.toLowerCase(), contains('abba'));
    expect(oct.chapterTitle.toLowerCase(), isNot(startsWith('bba')));
  });

  test('appendix ids are not required on dates', () {
    for (final e in calendar.entries) {
      if (e.id <= calendar.dailyCount) {
        expect(calendar.dateForEntry(e.id, 2024), isNotNull, reason: '${e.id}');
      } else {
        expect(calendar.isAppendix(e), isTrue);
        expect(calendar.dateForEntry(e.id, 2024), isNull, reason: '${e.id}');
      }
    }
  });
}
