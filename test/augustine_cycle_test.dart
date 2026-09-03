import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/augustine/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/augustine/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: 'augustine');
}

void main() {
  final calendar = loadFixture();

  test('daily year is 366; appendix follows', () {
    expect(calendar.dailyCount, 366);
    expect(calendar.entries.length, greaterThan(366));
    expect(calendar.divisionNoun, 'Book');
  });

  test('entry ids are contiguous 1..N', () {
    final ids = calendar.entries.map((e) => e.id).toList()..sort();
    expect(ids, List.generate(ids.length, (i) => i + 1));
  });

  test('leap year maps I–X 1:1; appendix stays off the calendar', () {
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

  test('common-year Dec 31 merges the last two daily entries', () {
    expect(calendar.resolveIdsFor(DateTime(2025, 12, 31)), [365, 366]);
    expect(calendar.resolveIdsFor(DateTime(2024, 12, 31)), [366]);
  });

  test('appendix ids are not required on dates', () {
    for (final e in calendar.entries) {
      if (e.id <= calendar.dailyCount) {
        expect(calendar.dateForEntry(e.id, 2024), isNotNull, reason: '${e.id}');
      } else {
        expect(calendar.isAppendix(e), isTrue);
        expect(calendar.dateForEntry(e.id, 2024), isNull, reason: '${e.id}');
        expect(e.part, greaterThanOrEqualTo(11));
      }
    }
  });

  test('Books I–X are the daily cut; XI–XIII are appendix', () {
    final daily = calendar.entries.where((e) => e.id <= calendar.dailyCount);
    expect(daily.every((e) => e.part >= 1 && e.part <= 10), isTrue);
    final appendix = calendar.entries.where((e) => e.id > calendar.dailyCount);
    expect(appendix, isNotEmpty);
    expect(appendix.every((e) => e.part >= 11 && e.part <= 13), isTrue);
  });

  test('each entry has non-empty English', () {
    for (final e in calendar.entries) {
      expect(e.textEn.trim(), isNotEmpty, reason: 'entry ${e.id}');
      expect(e.textEn, isNot(contains('This document is from the C')));
      expect(e.textEn, isNot(contains('http://www.ccel.org')));
    }
  });
}
