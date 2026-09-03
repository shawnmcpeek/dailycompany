import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/teresa-avila/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/teresa-avila/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: 'teresa-avila');
}

void main() {
  final calendar = loadFixture();

  test('ships exactly 366 entries', () {
    expect(calendar.entries.length, 366);
  });

  test('entry ids are contiguous 1..N', () {
    final ids = calendar.entries.map((e) => e.id).toList()..sort();
    expect(ids, List.generate(366, (i) => i + 1));
  });

  test('leap year is 1:1', () {
    const year = 2024;
    expect(CycleCalendar.isLeapYear(year), isTrue);
    final seen = <int>{};
    for (
      var day = DateTime(year, 1, 1);
      !day.isAfter(DateTime(year, 12, 31));
      day = day.add(const Duration(days: 1))
    ) {
      final ids = calendar.resolveIdsFor(day);
      expect(ids, hasLength(1), reason: CycleCalendar.dateKey(day));
      seen.addAll(ids);
    }
    expect(seen, {for (var i = 1; i <= 366; i++) i});
  });

  test('common-year Dec 31 merges the last two entries', () {
    expect(calendar.resolveIdsFor(DateTime(2025, 12, 31)), [365, 366]);
    expect(calendar.resolveIdsFor(DateTime(2024, 12, 31)), [366]);
  });

  test('Way is part 1; mansions are parts 2–8', () {
    final way = calendar.entries.where((e) => e.part == 1).toList();
    expect(way, isNotEmpty);
    expect(
      way.every((e) => e.partTitle.toLowerCase().contains('way of perfection')),
      isTrue,
    );
    final mansions = calendar.entries.where((e) => e.part >= 2).toList();
    expect(mansions, isNotEmpty);
    expect(mansions.every((e) => e.part >= 2 && e.part <= 8), isTrue);
    expect(
      mansions.every((e) => e.partTitle.toLowerCase().contains('mansion')),
      isTrue,
    );
    final parts = mansions.map((e) => e.part).toSet();
    expect(parts, {2, 3, 4, 5, 6, 7, 8});
  });

  test('a dwelling is never split across an entry', () {
    for (final e in calendar.entries) {
      expect(e.part, inInclusiveRange(1, 8), reason: 'entry ${e.id}');
    }
    for (
      var day = DateTime(2024, 1, 1);
      !day.isAfter(DateTime(2024, 12, 31));
      day = day.add(const Duration(days: 1))
    ) {
      final parts = calendar.resolveFor(day).map((e) => e.part).toSet();
      expect(parts, hasLength(1), reason: CycleCalendar.dateKey(day));
    }
  });

  test('each entry has non-empty English', () {
    for (final e in calendar.entries) {
      expect(e.textEn.trim(), isNotEmpty, reason: 'entry ${e.id}');
    }
  });

  test('chapter titles are the argument, not Chapter N stubs', () {
    final stubs = calendar.entries
        .where((e) => RegExp(r'^Chapter\s+\d+$').hasMatch(e.chapterTitle.trim()))
        .map((e) => e.id)
        .toList();
    expect(stubs, isEmpty);
  });

  test('the Castle does not ship the printer’s HERE ENDS line', () {
    for (final e in calendar.entries) {
      expect(e.textEn.toUpperCase(), isNot(contains('HERE ENDS')));
      expect(e.textEn, isNot(contains('This document is from the C')));
      expect(e.textEn, isNot(contains('ccel.org')));
    }
  });
}
