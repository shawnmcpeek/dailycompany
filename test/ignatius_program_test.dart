import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/data/models/ignatius_content.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = jsonDecode(
    File('assets/content/ignatius/exercises.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final program = IgnatiusProgram(
    directorNote: json['directorNote'] as String,
    entries: (json['entries'] as List)
        .map((e) => IgnatiusProgramEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  test('exactly 210 sequential days', () {
    expect(program.entries.length, IgnatiusProgram.length);
    expect(program.entries.map((e) => e.id).toList(),
        List.generate(210, (i) => i + 1));
  });

  test('parts cover disposition through Fourth Week', () {
    expect(program.entries.any((e) => e.part == 0), isTrue);
    expect(program.entries.any((e) => e.part == 4), isTrue);
    expect(program.entries.every((e) => e.part >= 0 && e.part <= 4), isTrue);
  });

  test('repetitions reuse Mullan, they are not filler commentary', () {
    expect(program.entries.where((e) => e.isRepetition), isNotEmpty);
    for (final e in program.entries) {
      expect(e.textEn, isNot(contains('IHS')));
      expect(e.textEn, isNot(contains('ccel.org')));
      expect(e.textEn.trim(), isNotEmpty);
    }
  });

  test('director note is the required pastoral copy', () {
    expect(program.directorNote, contains('cannot listen to you'));
    expect(program.directorNote, contains('spiritual director'));
  });

  test('elapsed is sequential, freeze on pause, last day holds', () {
    const start = AppSettings(
      ignatiusProgramStart: '2026-01-01',
    );
    expect(start.ignatiusElapsedDays(DateTime(2026, 1, 1)), 0);
    expect(start.ignatiusElapsedDays(DateTime(2026, 1, 11)), 10);
    expect(program.forElapsed(0)?.id, 1);
    expect(program.forElapsed(209)?.id, 210);
    expect(program.forElapsed(400)?.id, 210);

    const paused = AppSettings(
      ignatiusProgramStart: '2026-01-01',
      ignatiusProgramPaused: true,
      ignatiusElapsedWhenPaused: 10,
    );
    expect(paused.ignatiusElapsedDays(DateTime(2026, 6, 1)), 10);
    expect(program.forElapsed(10)?.id, 11);

    const idle = AppSettings();
    expect(idle.ignatiusElapsedDays(DateTime(2026, 1, 1)), -1);
    expect(program.forElapsed(-1), isNull);
  });

  test('22 discernment rules, no chrome', () {
    final raw = jsonDecode(
      File('assets/content/ignatius/rules.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final chapters = raw['chapters'] as List;
    expect(chapters, hasLength(22));
    expect(chapters.where((e) => (e as Map)['week'] == 1), hasLength(14));
    expect(chapters.where((e) => (e as Map)['week'] == 2), hasLength(8));
    for (final e in chapters) {
      final text = (e as Map)['textEn'] as String;
      expect(text, isNot(contains('IHS')));
      expect(text, isNot(contains('ccel.org')));
    }
  });
}
