import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/kempis/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/kempis/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: 'kempis');
}

void main() {
  final calendar = loadFixture();

  test('ships exactly 366 entries', () {
    expect(calendar.entries.length, 366);
  });

  test('entry ids are contiguous 1..N with no gaps', () {
    final ids = calendar.entries.map((e) => e.id).toList()..sort();
    expect(ids, List.generate(ids.length, (i) => i + 1));
  });

  test('every day of a leap year resolves to an entry, all 366 reachable', () {
    const year = 2024;
    expect(CycleCalendar.isLeapYear(year), isTrue);
    final seen = <int>{};
    for (
      var day = DateTime(year, 1, 1);
      !day.isAfter(DateTime(year, 12, 31));
      day = day.add(const Duration(days: 1))
    ) {
      final ids = calendar.resolveIdsFor(day);
      expect(ids, isNotEmpty, reason: 'missing ${CycleCalendar.dateKey(day)}');
      seen.addAll(ids);
    }
    expect(seen.length, calendar.entries.length,
        reason: 'not every entry reachable in leap year');
  });

  test('every day of a common year resolves to an entry, all 366 reachable', () {
    const year = 2025;
    expect(CycleCalendar.isLeapYear(year), isFalse);
    final seen = <int>{};
    for (
      var day = DateTime(year, 1, 1);
      !day.isAfter(DateTime(year, 12, 31));
      day = day.add(const Duration(days: 1))
    ) {
      final ids = calendar.resolveIdsFor(day);
      expect(ids, isNotEmpty, reason: 'missing ${CycleCalendar.dateKey(day)}');
      seen.addAll(ids);
    }
    expect(seen.length, calendar.entries.length,
        reason: 'not every entry reachable in common year');
  });

  test('common-year Dec 31 merges the last two entries', () {
    final dec31 = calendar.resolveIdsFor(DateTime(2025, 12, 31));
    expect(dec31.length, 2);
    expect(dec31, [365, 366]);

    final leapDec31 = calendar.resolveIdsFor(DateTime(2024, 12, 31));
    expect(leapDec31, [366]);
  });

  test('concatenating all entries yields a coherent non-empty stream', () {
    final byId = [
      for (var i = 1; i <= calendar.entries.length; i++) calendar.byId(i)!,
    ];
    for (final e in byId) {
      expect(e.textEn.trim(), isNotEmpty, reason: 'entry ${e.id} has empty text');
    }
    final allText = byId.map((e) => e.textEn).join('\n\n');
    expect(allText.length, greaterThan(40000));
  });

  test('every book starts at chapter 1 (no mislabeled part boundary)', () {
    final seenParts = <int>[];
    for (final e in calendar.entries) {
      if (seenParts.isEmpty || seenParts.last != e.part) {
        expect(e.chapter, 1,
            reason: 'Book ${e.part} first appears at chapter ${e.chapter}, '
                'not 1 — a part-boundary label bug');
        seenParts.add(e.part);
      }
    }
    expect(seenParts, [1, 2, 3, 4]);
  });

  test('every entry has a calendar date in both year types', () {
    for (final e in calendar.entries) {
      expect(calendar.dateForEntry(e.id, 2024), isNotNull, reason: 'leap ${e.id}');
      expect(calendar.dateForEntry(e.id, 2025), isNotNull, reason: 'common ${e.id}');
    }
  });

  test('division noun is Book', () {
    expect(calendar.divisionNoun, 'Book');
  });
}
