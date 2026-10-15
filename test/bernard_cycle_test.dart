import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/bernard/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/bernard/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: 'bernard');
}

void main() {
  final calendar = loadFixture();

  test('daily year is 366; vol III and Cantica overflow sit in the appendix', () {
    expect(calendar.dailyCount, 366);
    expect(calendar.entries.length, greaterThan(366));
    expect(calendar.divisionNoun, 'Sermon');
  });

  test('liturgical sermons and Cantica are both present', () {
    final parts = calendar.entries.map((e) => e.part).toSet();
    expect(parts, containsAll({1, 2}));
    expect(
      calendar.entries.any((e) => e.part == 1),
      isTrue,
      reason: 'vol III De Tempore',
    );
    expect(
      calendar.entries.where((e) => e.part == 2),
      isNotEmpty,
      reason: 'vol IV Cantica',
    );
  });

  test('leap year maps daily entries 1:1; appendix stays off the calendar', () {
    const year = 2024;
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

  test('daily cycle is sermons, not letters or New Knighthood', () {
    for (final e in calendar.entries) {
      expect(e.textEn.trim(), isNotEmpty, reason: 'entry ${e.id}');
      expect(e.textEn.toLowerCase(), isNot(contains('cistercian publications')));
      expect(e.textEn.toLowerCase(), isNot(contains('bruno scott james')));
      expect(e.textEn, isNot(contains('PROJECT GUTENBERG')));
    }
  });

  test('Works shelf has On Loving God and the Eales letters', () {
    final works = jsonDecode(
      File('assets/content/bernard/works.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final ids = {
      for (final b in works['books'] as List) (b as Map)['id'] as String,
    };
    expect(ids, containsAll({'loving-god', 'letters'}));
    expect(jsonEncode(works).toLowerCase(), isNot(contains('greenia')));
  });
}
