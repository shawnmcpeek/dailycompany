import 'dart:convert';

import 'package:flutter/services.dart';

/// A shelf of whole works — not a daily cut. Same shape as John's treatises.
class ShelfChapter {
  const ShelfChapter({
    required this.chapter,
    required this.title,
    required this.textEn,
  });

  final int chapter;
  final String title;
  final String textEn;

  factory ShelfChapter.fromJson(Map<String, dynamic> json) {
    return ShelfChapter(
      chapter: json['chapter'] as int,
      title: json['title'] as String,
      textEn: json['textEn'] as String,
    );
  }
}

class ShelfPart {
  const ShelfPart({
    required this.part,
    required this.title,
    required this.chapters,
  });

  final int part;
  final String title;
  final List<ShelfChapter> chapters;

  factory ShelfPart.fromJson(Map<String, dynamic> json) {
    return ShelfPart(
      part: json['part'] as int,
      title: json['title'] as String,
      chapters:
          (json['chapters'] as List)
              .map((e) => ShelfChapter.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.chapter.compareTo(b.chapter)),
    );
  }
}

class ShelfBook {
  const ShelfBook({
    required this.id,
    required this.title,
    required this.parts,
  });

  final String id;
  final String title;
  final List<ShelfPart> parts;

  factory ShelfBook.fromJson(Map<String, dynamic> json) {
    return ShelfBook(
      id: json['id'] as String,
      title: json['title'] as String,
      parts:
          (json['parts'] as List)
              .map((e) => ShelfPart.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.part.compareTo(b.part)),
    );
  }

  ShelfChapter? chapter(int book, int chapter) {
    for (final part in parts) {
      if (part.part != book) continue;
      for (final c in part.chapters) {
        if (c.chapter == chapter) return c;
      }
    }
    return null;
  }

  ShelfPart? partByNumber(int book) {
    for (final part in parts) {
      if (part.part == book) return part;
    }
    return null;
  }
}

class WorkShelf {
  const WorkShelf({
    required this.translator,
    required this.label,
    required this.intro,
    required this.books,
  });

  final String translator;
  final String label;
  final String intro;
  final List<ShelfBook> books;

  ShelfBook? byId(String id) {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }

  static Future<WorkShelf> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return WorkShelf(
      translator: json['translator'] as String? ?? '',
      label: json['label'] as String? ?? json['title'] as String? ?? 'Works',
      intro: json['intro'] as String? ?? '',
      books: (json['books'] as List)
          .map((e) => ShelfBook.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
