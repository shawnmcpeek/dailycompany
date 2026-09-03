import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/liguori/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/liguori/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: 'liguori');
}

void main() {
  final calendar = loadFixture();

  test('ships exactly 31 visits', () {
    expect(calendar.entries.length, 31);
  });

  test('entry ids are contiguous 1..31', () {
    final ids = calendar.entries.map((e) => e.id).toList()..sort();
    expect(ids, List.generate(31, (i) => i + 1));
  });

  test('every day of a leap year resolves to exactly one visit', () {
    const year = 2024;
    expect(CycleCalendar.isLeapYear(year), isTrue);
    final seen = <int>{};
    for (
      var day = DateTime(year, 1, 1);
      !day.isAfter(DateTime(year, 12, 31));
      day = day.add(const Duration(days: 1))
    ) {
      final ids = calendar.resolveIdsFor(day);
      expect(ids, [day.day], reason: CycleCalendar.dateKey(day));
      seen.addAll(ids);
    }
    expect(seen.length, 31);
  });

  test('every day of a common year resolves to exactly one visit', () {
    const year = 2025;
    expect(CycleCalendar.isLeapYear(year), isFalse);
    final seen = <int>{};
    for (
      var day = DateTime(year, 1, 1);
      !day.isAfter(DateTime(year, 12, 31));
      day = day.add(const Duration(days: 1))
    ) {
      final ids = calendar.resolveIdsFor(day);
      expect(ids, [day.day], reason: CycleCalendar.dateKey(day));
      seen.addAll(ids);
    }
    expect(seen.length, 31);
  });

  test('short months omit 29–31; they are never merged', () {
    expect(calendar.resolveIdsFor(DateTime(2025, 2, 28)), [28]);
    expect(calendar.resolveIdsFor(DateTime(2024, 2, 28)), [28]);
    expect(calendar.resolveIdsFor(DateTime(2024, 2, 29)), [29]);
    expect(calendar.resolveIdsFor(DateTime(2025, 4, 30)), [30]);
    expect(calendar.resolveIdsFor(DateTime(2025, 1, 31)), [31]);
    expect(calendar.resolveIdsFor(DateTime(2025, 12, 31)), [31]);
  });

  test('each visit has non-empty English', () {
    for (final e in calendar.entries) {
      expect(e.textEn.trim(), isNotEmpty, reason: 'visit ${e.id}');
      expect(e.chapterTitle.toLowerCase(), contains('visit'));
    }
  });

  test('every visit has a calendar date in both year types', () {
    for (final e in calendar.entries) {
      expect(calendar.dateForEntry(e.id, 2024), isNotNull, reason: 'leap ${e.id}');
      expect(calendar.dateForEntry(e.id, 2025), isNotNull, reason: 'common ${e.id}');
    }
    expect(calendar.dateForEntry(28, 2025), DateTime(2025, 1, 28));
    expect(calendar.dateForEntry(29, 2024), DateTime(2024, 1, 29));
    expect(calendar.dateForEntry(29, 2025), DateTime(2025, 1, 29));
  });

  test('manner prayers are present', () {
    final manner = jsonDecode(
      File('assets/content/liguori/manner.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final key in [
      'actsBefore',
      'spiritualCommunion',
      'shorterAct',
      'closingMary',
    ]) {
      expect((manner[key] as String).trim(), isNotEmpty);
    }
  });
}
