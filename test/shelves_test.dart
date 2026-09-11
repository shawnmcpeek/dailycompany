import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:dailycompany/core/reading/reading_routes.dart';
import 'package:flutter_test/flutter_test.dart';

const _chrome = [
  'This document is from the C',
  'http://www.ccel.org',
  'PROJECT GUTENBERG',
  'Digitized by',
  'Susan L. Emery',
  'Thomas W. Tobin',
  'John K. Ryan',
  'Kavanaugh',
  'Qorirait',
  'FatJier',
  'ivith',
  'Spiritual Treatises. [PART',
];

Map<String, dynamic> loadShelf(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

Iterable<Map<String, dynamic>> chaptersOf(Map<String, dynamic> shelf) sync* {
  for (final book in shelf['books'] as List) {
    for (final part in (book as Map)['parts'] as List) {
      for (final chapter in (part as Map)['chapters'] as List) {
        yield chapter as Map<String, dynamic>;
      }
    }
  }
}

void expectClean(String path, {required int minChapters}) {
  final shelf = loadShelf(path);
  expect(shelf['translator'], isNotEmpty, reason: path);
  expect(shelf['label'], isNotEmpty, reason: path);
  final chapters = chaptersOf(shelf).toList();
  expect(chapters.length, greaterThanOrEqualTo(minChapters), reason: path);
  for (final c in chapters) {
    final text = c['textEn'] as String;
    expect(text.trim(), isNotEmpty, reason: '$path ${c['title']}');
    for (final ban in _chrome) {
      expect(
        text.toLowerCase(),
        isNot(contains(ban.toLowerCase())),
        reason: '$path ${c['title']} $ban',
      );
    }
  }
}

void main() {
  test('de Sales Conferences are Mackey’s twenty-one', () {
    expectClean('assets/content/desales/conferences.json', minChapters: 21);
    final shelf = loadShelf('assets/content/desales/conferences.json');
    expect(chaptersOf(shelf).length, 21);
    expect(shelf['translator'], contains('Mackey'));
    final titles = [for (final c in chaptersOf(shelf)) c['title'] as String];
    expect(titles[12], contains('Visitation'));
    expect(titles[20], contains('Refusing Nothing'));
  });

  test('Liguori works are Grimm Uniformity and Preparation for Death', () {
    expectClean('assets/content/liguori/works.json', minChapters: 40);
    final shelf = loadShelf('assets/content/liguori/works.json');
    final ids = [for (final b in shelf['books'] as List) (b as Map)['id']];
    expect(ids, ['uniformity', 'preparation']);
    expect(shelf['translator'], contains('Grimm'));
    final titles = [for (final c in chaptersOf(shelf)) c['title'] as String];
    expect(titles.where((t) => t.contains('Qorirait')), isEmpty);
    expect(titles.where((t) => t.contains('Praper')), isEmpty);
    expect(
      titles.firstWhere((t) => t.startsWith('Portrait')),
      contains('Other World'),
    );
  });

  test('Gregory Moralia is the opening books, not thirty-five', () {
    expectClean('assets/content/gregory/moralia.json', minChapters: 20);
    final shelf = loadShelf('assets/content/gregory/moralia.json');
    final parts = (shelf['books'] as List).first['parts'] as List;
    final nums = [for (final p in parts) (p as Map)['part']];
    expect(nums, isNot(contains(6)));
    expect(nums, containsAll([0, 1, 2, 3, 4, 5]));
    final epistle = (parts.first as Map)['chapters'] as List;
    final text = (epistle.first as Map)['textEn'] as String;
    expect(text, isNot(contains('forbecause')));
    expect(text, isNot(contains('wa8')));
    expect(text, isNot(contains('Chu-ch')));
  });

  test('Augustine homilies are Browne and MacMullen', () {
    expectClean('assets/content/augustine/homilies.json', minChapters: 50);
    final shelf = loadShelf('assets/content/augustine/homilies.json');
    expect(shelf['translator'], contains('Browne'));
    expect(shelf['translator'], contains('MacMullen'));
  });

  test('Teresa Life is Lewis, forty chapters and a prologue', () {
    expectClean('assets/content/teresa-avila/life.json', minChapters: 41);
    final shelf = loadShelf('assets/content/teresa-avila/life.json');
    expect(shelf['translator'], contains('Lewis'));
    expect(chaptersOf(shelf).length, 41);
  });

  test('Ignatius letters are O’Leary / Goodier 1914', () {
    expectClean('assets/content/ignatius/letters.json', minChapters: 20);
    final shelf = loadShelf('assets/content/ignatius/letters.json');
    expect(shelf['translator'], contains("O'Leary"));
    for (final c in chaptersOf(shelf)) {
      expect(c['textEn'], isNot(contains('IHS')));
    }
  });

  test('Thérèse letters are Taylor, without Emery poems', () {
    expectClean('assets/content/therese/letters.json', minChapters: 10);
    final shelf = loadShelf('assets/content/therese/letters.json');
    expect(shelf['translator'], contains('Taylor'));
  });

  test('Ignatius Autobiography chapters 1–3 stay free', () {
    expect(IapFlags.freeIgnatiusChapterMax, 3);
    expect(IapController.ignatiusChapterFree(1), isTrue);
    expect(IapController.ignatiusChapterFree(3), isTrue);
    expect(IapController.ignatiusChapterFree(4), isFalse);
    expect(IapController.ignatiusChapterFree(0), isFalse);
  });

  test('new shelves resume at chapter depth', () {
    expect(ReadingRoutes.isResumable('/p/desales/conferences'), isFalse);
    expect(
      ReadingRoutes.isResumable('/p/desales/conferences/conferences/1/1'),
      isTrue,
    );
    expect(ReadingRoutes.isResumable('/p/liguori/works'), isFalse);
    expect(
      ReadingRoutes.isResumable('/p/liguori/works/uniformity/1/1'),
      isTrue,
    );
    expect(
      ReadingRoutes.isResumable('/p/teresa-avila/life/life/1/3'),
      isTrue,
    );
    expect(
      ReadingRoutes.isResumable('/p/ignatius/letters/letters/1/2'),
      isTrue,
    );
  });
}
