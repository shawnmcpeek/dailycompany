import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

CycleCalendar loadFixture() {
  final entries = jsonDecode(
    File('assets/content/francis/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/francis/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: 'francis');
}

void main() {
  final calendar = loadFixture();
  final n = calendar.entries.length;

  test('ships natural writings, not a padded year', () {
    expect(n, lessThan(366));
    expect(n, greaterThan(28));
  });

  test('entry ids are contiguous 1..N', () {
    final ids = calendar.entries.map((e) => e.id).toList()..sort();
    expect(ids, List.generate(n, (i) => i + 1));
  });

  test('every day of a leap year resolves to exactly one writing', () {
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
    expect(seen, {for (var i = 1; i <= n; i++) i});
  });

  test('every day of a common year resolves to exactly one writing', () {
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
    expect(seen.length, n);
  });

  test('the cycle repeats; Jan 1 is writing 1 and day N+1 is writing 1 again', () {
    expect(calendar.resolveIdsFor(DateTime(2024, 1, 1)), [1]);
    expect(
      calendar.resolveIdsFor(DateTime(2024, 1, 1).add(Duration(days: n))),
      [1],
    );
    expect(calendar.resolveIdsFor(DateTime(2025, 1, 1)), [1]);
  });

  test('each writing has non-empty English', () {
    for (final e in calendar.entries) {
      expect(e.textEn.trim(), isNotEmpty, reason: 'entry ${e.id}');
    }
  });

  test('Admonitions are the first twenty-eight entries', () {
    for (var i = 1; i <= 28; i++) {
      final e = calendar.byId(i)!;
      expect(e.part, 1);
      expect(e.chapter, i);
    }
  });

  test('Office of the Passion is five seasons, not mashed hours', () {
    final office = calendar.entries.where((e) => e.part == 7).toList();
    expect(office, hasLength(5));
    expect(
      office.map((e) => e.chapterTitle).toList(),
      [
        'Office of the Passion — Maundy Thursday',
        'Office of the Passion — Easter',
        'Office of the Passion — Sundays and feasts',
        'Office of the Passion — Advent',
        'Office of the Passion — Christmas',
      ],
    );
    for (final e in office) {
      expect(e.chapterTitle, isNot(contains(';')));
      expect(e.textEn.toLowerCase(), isNot(contains('as above')));
    }
  });

    test('Fioretti stay off the daily spine', () {
      final stories = jsonDecode(
        File('assets/content/francis/stories.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(stories['label'], 'Stories told about him');
      expect((stories['chapters'] as List).length, greaterThan(50));
      final daily = calendar.entries.map((e) => e.textEn).join(' ');
      expect(daily.toLowerCase(), isNot(contains('little flowers')));
    });

    test('Fioretti titles are full stories, not scrape stubs', () {
      final stories = jsonDecode(
        File('assets/content/francis/stories.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final chapters = (stories['chapters'] as List).cast<Map<String, dynamic>>();
      expect(chapters, isNotEmpty);
      final titles = [
        for (final c in chapters) (c['title'] as String).trim(),
      ];
      for (var i = 0; i < titles.length; i++) {
        final title = titles[i];
        expect(title.length, greaterThan(11), reason: 'story ${i + 1}');
        expect(title, isNot(contains('. . .')), reason: 'story ${i + 1}');
        expect(title.toLowerCase(), isNot(equals('introduction')));
        expect(
          RegExp(r'^Chapter\s+[IVXLCDM]+\.?$', caseSensitive: false).hasMatch(title),
          isFalse,
          reason: 'story ${i + 1}: $title',
        );
      }
      expect(titles.first.toLowerCase(), contains('crucified'));
      expect(
        titles.any((t) => t.toLowerCase().contains('turtle-doves')),
        isTrue,
      );
      expect(
        titles.any((t) => t.toLowerCase().contains('received into the order')),
        isTrue,
      );
      expect(
        titles.any((t) => t.toLowerCase().contains('most holy stigmata')),
        isTrue,
      );
    });

  test('Canticle is present as its own practice text', () {
    final canticle = jsonDecode(
      File('assets/content/francis/canticle.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect((canticle['textEn'] as String).toLowerCase(), contains('brother sun'));
  });

  test('twenty-eight Admonitions ship as a free shelf', () {
    final admon = jsonDecode(
      File('assets/content/francis/admonitions.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect((admon['chapters'] as List).length, 28);
  });
}
