import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/john-cross/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/john-cross/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: 'john-cross');
}

final _runningHead = RegExp(r'[A-Z][A-Z0-9 ,;:\-]{10,}\.\s*\d{2,4}');

void main() {
  final calendar = loadFixture();

  test('daily year is 366; overflow sits off the calendar', () {
    expect(calendar.dailyCount, 366);
    expect(calendar.entries.length, greaterThanOrEqualTo(366));
  });

  test('entry ids are contiguous 1..N', () {
    final ids = calendar.entries.map((e) => e.id).toList()..sort();
    expect(ids, List.generate(ids.length, (i) => i + 1));
  });

  test('leap year maps the daily sayings 1:1', () {
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
      for (final id in ids) {
        expect(id, lessThanOrEqualTo(calendar.dailyCount));
      }
      seen.addAll(ids);
    }
    expect(seen, {for (var i = 1; i <= calendar.dailyCount; i++) i});
  });

  test('common-year Dec 31 merges the last two daily sayings', () {
    expect(calendar.resolveIdsFor(DateTime(2025, 12, 31)), [365, 366]);
    expect(calendar.resolveIdsFor(DateTime(2024, 12, 31)), [366]);
  });

  test('overflow ids are not required on dates', () {
    for (final e in calendar.entries) {
      if (e.id <= calendar.dailyCount) {
        expect(calendar.dateForEntry(e.id, 2024), isNotNull);
      } else {
        expect(calendar.isAppendix(e), isTrue);
        expect(calendar.dateForEntry(e.id, 2024), isNull);
      }
    }
  });

  test('each saying has non-empty English without djvu trash', () {
    for (final e in calendar.entries) {
      final text = e.textEn.trim();
      expect(text, isNotEmpty, reason: 'entry ${e.id}');
      expect(_runningHead.hasMatch(text), isFalse, reason: 'entry ${e.id}');
      expect(text, isNot(contains('Hinr')));
      expect(text, isNot(contains('Digitized by')));
      expect(text, isNot(contains('oo5Le')));
      expect(text, isNot(contains('Gop')));
      expect(text.toLowerCase(), isNot(contains(' ee a i ee')));
      expect(text, isNot(contains('bea a a sera')));
      expect(text, isNot(contains('Peaks their')));
      expect(text, isNot(contains('dasieey')));
    }
    final all = calendar.entries.map((e) => e.textEn).join('\n');
    expect(all, contains("God for God's sake"));
    expect(all.toLowerCase(), contains('ready for talking'));
    expect(all, contains('value of my soul'));
  });

  test('Precautions open the year: address plus nine cautions', () {
    final cautions = calendar.entries.where((e) => e.part == 1).toList();
    expect(cautions.length, 10);
    expect(cautions[2].chapterTitle.toLowerCase(), contains('second'));
    expect(cautions[2].chapterTitle.toLowerCase(), contains('world'));
    final last = cautions.last.textEn;
    expect(last.toUpperCase(), isNot(contains('LETTERS')));
    expect(last.toLowerCase(), isNot(contains('mother catherine')));
  });

  test('Precautions ship as a free shelf of ten cautions', () {
    final raw = jsonDecode(
      File('assets/content/john-cross/precautions.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final chapters = (raw['chapters'] as List).cast<Map<String, dynamic>>();
    expect(chapters.length, 10);
    expect(
      (chapters[2]['title'] as String).toLowerCase(),
      contains('second'),
    );
    expect(
      (chapters[2]['textEn'] as String).toLowerCase(),
      contains('worldly goods'),
    );
  });

  test('treatises stay off the daily spine', () {
    final all = calendar.entries.map((e) => e.textEn.toLowerCase()).join(' ');
    expect(all, isNot(contains('dark night of the soul')));
    expect(all, isNot(contains('ascent of mount carmel')));
  });
}
