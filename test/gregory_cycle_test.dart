import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/gregory/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/gregory/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: 'gregory');
}

void main() {
  final calendar = loadFixture();

  test('ships 183 entries, twice a year', () {
    expect(calendar.entries.length, 183);
    expect(calendar.divisionNoun, 'Book');
  });

  test('entry ids are contiguous 1..N', () {
    final ids = calendar.entries.map((e) => e.id).toList()..sort();
    expect(ids, List.generate(183, (i) => i + 1));
  });

  test('every day of a leap year resolves to one reading; each appears twice', () {
    const year = 2024;
    expect(CycleCalendar.isLeapYear(year), isTrue);
    final seen = <int, int>{};
    for (
      var day = DateTime(year, 1, 1);
      !day.isAfter(DateTime(year, 12, 31));
      day = day.add(const Duration(days: 1))
    ) {
      final ids = calendar.resolveIdsFor(day);
      expect(ids, hasLength(1), reason: CycleCalendar.dateKey(day));
      seen[ids.first] = (seen[ids.first] ?? 0) + 1;
    }
    expect(seen.keys.toSet(), {for (var i = 1; i <= 183; i++) i});
    expect(seen.values.toSet(), {2});
  });

  test('every day of a common year resolves to one reading', () {
    const year = 2025;
    expect(CycleCalendar.isLeapYear(year), isFalse);
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
    expect(seen.length, 183);
  });

  test('Jan 1 is reading 1; the second pass begins at reading 1 again', () {
    expect(calendar.resolveIdsFor(DateTime(2024, 1, 1)), [1]);
    expect(calendar.resolveIdsFor(DateTime(2024, 7, 2)), [1]);
  });

  test('each reading has non-empty English', () {
    for (final e in calendar.entries) {
      expect(e.textEn.trim(), isNotEmpty, reason: 'entry ${e.id}');
    }
  });

  test('Dialogues Book II is not recut here', () {
    final all = calendar.entries.map((e) => e.textEn.toLowerCase()).join(' ');
    expect(all, isNot(contains('life of our most holy father st. benedict')));
  });
}
