import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

const _chrome = [
  'This document is from the C',
  'http://www.ccel.org',
  'PROJECT GUTENBERG',
  'Digitized by',
];

CycleCalendar loadHouse(String id) {
  final entries = jsonDecode(
    File('assets/content/$id/entries.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final calendar = jsonDecode(
    File('assets/content/$id/calendar.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return CycleCalendar.fromJson(entries, calendar, portalId: id);
}

void expectYearResolves(CycleCalendar calendar, int year) {
  for (
    var day = DateTime(year, 1, 1);
    !day.isAfter(DateTime(year, 12, 31));
    day = day.add(const Duration(days: 1))
  ) {
    expect(
      calendar.resolveIdsFor(day),
      isNotEmpty,
      reason: CycleCalendar.dateKey(day),
    );
  }
}

void main() {
  for (final id in [
    'ignatius',
    'therese',
    'catherine',
    'montfort',
    'scupoli',
    'lawrence',
    'cassian',
  ]) {
    group(id, () {
      final calendar = loadHouse(id);

      test('entry ids are contiguous 1..N', () {
        final ids = calendar.entries.map((e) => e.id).toList()..sort();
        expect(ids, List.generate(ids.length, (i) => i + 1));
      });

      test('every day of 2024 and 2025 resolves', () {
        expectYearResolves(calendar, 2024);
        expectYearResolves(calendar, 2025);
      });

      test('Today English has no chrome', () {
        for (final e in calendar.entries) {
          expect(e.textEn.trim(), isNotEmpty, reason: 'entry ${e.id}');
          for (final ban in _chrome) {
            expect(
              e.textEn.toLowerCase(),
              isNot(contains(ban.toLowerCase())),
              reason: '${e.id} $ban',
            );
          }
          expect(e.chapterTitle, isNot(matches(RegExp(r'^Chapter\s+\d+$'))));
          expect(RegExp(r'\btlie\b').hasMatch(e.textEn), isFalse, reason: '${e.id} tlie');
          expect(RegExp(r'\btbe\b').hasMatch(e.textEn), isFalse, reason: '${e.id} tbe');
        }
      });
    });
  }

  test('Therese is Taylor of the Pauline 1898, not shrine or 1956', () {
    final calendar = loadHouse('therese');
    expect(calendar.dailyCount, 366);
    for (final e in calendar.entries) {
      expect(e.textEn.toLowerCase(), isNot(contains('manuscrits autobiographiques')));
      expect(e.textEn.toLowerCase(), isNot(contains('office central de lisieux')));
      expect(e.textEn.toLowerCase(), isNot(contains('susan l. emery')));
      expect(e.textEn.toLowerCase(), isNot(contains('favors obtained')));
      expect(
        e.textEn,
        isNot(contains('This Prayer was found after the death')),
      );
      expect(e.textEn, isNot(contains('ENTRY INTO HEAVEN')));
      expect(e.textEn, isNot(contains('MY DAYS OF GRACE')));
    }
  });

  test('Ignatius autobiography does not calendar the Exercises', () {
    final calendar = loadHouse('ignatius');
    expect(calendar.entries.length, 60);
    for (final e in calendar.entries) {
      expect(e.textEn, isNot(contains('IHS')));
    }
  });

  test('Catherine is Thorold Dialogue', () {
    final e1 = loadHouse('catherine').entries.first;
    expect(e1.textEn, contains('cell of self-knowledge'));
  });

  test('Scupoli is not letter-salad', () {
    for (final e in loadHouse('scupoli').entries) {
      expect(e.textEn, isNot(contains('Gk)d')));
      expect(e.textEn, isNot(contains('Qt)d')));
    }
  });

  test('Lawrence is conversations and letters, not padded', () {
    expect(loadHouse('lawrence').entries.length, 19);
  });

  test('Cassian is Conferences, not Institutes', () {
    final calendar = loadHouse('cassian');
    expect(calendar.dailyCount, 366);
    expect(calendar.divisionNoun, 'Conference');
    final all = calendar.entries.map((e) => e.textEn.toLowerCase()).join(' ');
    expect(all, isNot(contains('the twelve books of john cassian on the institutes')));
  });
}
