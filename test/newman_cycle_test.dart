import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/newman/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/newman/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: 'newman');
}

void main() {
  final calendar = loadFixture();

  test('daily year is 366; appendix keeps the rest of PPS', () {
    expect(calendar.dailyCount, 366);
    expect(calendar.entries.length, greaterThan(366));
    expect(calendar.divisionNoun, 'Volume');
  });

  test('eight volumes are present, 191 sermons, none glued', () {
    final parts = calendar.entries.map((e) => e.part).toSet();
    expect(parts, {1, 2, 3, 4, 5, 6, 7, 8});
    final sermons = {
      for (final e in calendar.entries) (e.part, e.chapter),
    };
    expect(sermons, hasLength(191));
    const expected = {1: 26, 2: 32, 3: 25, 4: 23, 5: 24, 6: 25, 7: 18, 8: 18};
    for (final vol in expected.keys) {
      final n = {
        for (final e in calendar.entries)
          if (e.part == vol) e.chapter,
      };
      expect(n, hasLength(expected[vol]), reason: 'volume $vol');
      expect(n, {for (var i = 1; i <= expected[vol]!; i++) i}, reason: 'volume $vol');
    }
    final titles = {
      for (final e in calendar.entries) e.chapterTitle,
    };
    expect(titles, contains('The Mind of Little Children'));
    expect(titles, contains('Jeroboam'));
    expect(titles, contains('The Strictness of the Law of Christ'));
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

  test('Works shelf includes Verses and the four treatises', () {
    final works = jsonDecode(
      File('assets/content/newman/works.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final ids = {
      for (final b in works['books'] as List) (b as Map)['id'] as String
    };
    expect(
      ids,
      containsAll({
        'meditations',
        'verses',
        'apologia',
        'idea',
        'grammar',
        'development',
      }),
    );
    final blob = jsonEncode(works).toLowerCase();
    expect(blob, contains('kindly light'));
    expect(blob, contains('pillar of the cloud'));
    expect(blob, isNot(contains('project gutenberg')));
    expect(blob, isNot(contains('newmanreader')));
  });

  test('daily cycle is PPS only, with no Gutenberg chrome', () {
    for (final e in calendar.entries) {
      expect(e.textEn.trim(), isNotEmpty, reason: 'entry ${e.id}');
      expect(e.partTitle, contains('Parochial and Plain Sermons'));
      expect(e.textEn, isNot(contains('PROJECT GUTENBERG')));
      expect(e.textEn.toLowerCase(), isNot(contains('newmanreader')));
      expect(e.textEn, isNot(contains('This document is from the C')));
    }
  });
}
