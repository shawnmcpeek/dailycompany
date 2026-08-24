import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/reading_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

ReadingCalendar loadFixture() {
  final readings = jsonDecode(
    File('assets/content/rule_readings.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/reading_calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return ReadingCalendar.fromJson(readings, calendar);
}

void main() {
  final calendar = loadFixture();

  test('ships exactly 122 canonical readings', () {
    expect(calendar.readings.length, 122);
    expect(calendar.readings.map((r) => r.id).toSet().length, 122);
  });

  test('every day of a leap year resolves to at least one reading', () {
    const year = 2024;
    expect(ReadingCalendar.isLeapYear(year), isTrue);
    final seen = <int>{};
    for (var day = DateTime(year, 1, 1);
        !day.isAfter(DateTime(year, 12, 31));
        day = day.add(const Duration(days: 1))) {
      final ids = calendar.resolveIdsFor(day);
      expect(ids, isNotEmpty, reason: 'missing ${ReadingCalendar.dateKey(day)}');
      seen.addAll(ids);
    }
    expect(seen.length, 122, reason: 'not every reading reachable in leap year');
  });

  test('every day of a common year resolves to at least one reading', () {
    const year = 2025;
    expect(ReadingCalendar.isLeapYear(year), isFalse);
    final seen = <int>{};
    for (var day = DateTime(year, 1, 1);
        !day.isAfter(DateTime(year, 12, 31));
        day = day.add(const Duration(days: 1))) {
      final ids = calendar.resolveIdsFor(day);
      expect(ids, isNotEmpty, reason: 'missing ${ReadingCalendar.dateKey(day)}');
      seen.addAll(ids);
    }
    expect(
      seen.length,
      122,
      reason: 'not every reading reachable in common year',
    );
  });

  test('common-year Feb 24 stacks the leap-only portion with Feb 23 reading', () {
    final common = calendar.resolveIdsFor(DateTime(2025, 2, 24));
    final leap = calendar.resolveIdsFor(DateTime(2024, 2, 24));
    expect(leap, isNotEmpty);
    // In common years, Feb 24 carries the shifted Feb.24(25) reading,
    // and the leap-only portion is merged onto Feb 23.
    final feb23 = calendar.resolveIdsFor(DateTime(2025, 2, 23));
    expect(feb23.length, greaterThanOrEqualTo(2));
    expect(common, isNotEmpty);
    expect(common, isNot(equals(leap)));
  });

  test('cycle labels cover winter/summer/autumn ranges', () {
    expect(calendar.cycleNumber(DateTime(2026, 1, 1)), 1);
    expect(calendar.cycleNumber(DateTime(2026, 5, 1)), 1);
    expect(calendar.cycleNumber(DateTime(2026, 5, 2)), 2);
    expect(calendar.cycleNumber(DateTime(2026, 8, 31)), 2);
    expect(calendar.cycleNumber(DateTime(2026, 9, 1)), 3);
    expect(calendar.cycleNumber(DateTime(2026, 12, 31)), 3);
    expect(calendar.cycleLabel(DateTime(2026, 1, 18)), contains('Winter'));
  });
}
