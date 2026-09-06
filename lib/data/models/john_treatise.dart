import 'dart:convert';

import 'package:flutter/services.dart';

class JohnTreatiseChapter {
  const JohnTreatiseChapter({
    required this.chapter,
    required this.title,
    required this.textEn,
  });

  final int chapter;
  final String title;
  final String textEn;

  factory JohnTreatiseChapter.fromJson(Map<String, dynamic> json) {
    return JohnTreatiseChapter(
      chapter: json['chapter'] as int,
      title: json['title'] as String,
      textEn: json['textEn'] as String,
    );
  }
}

class JohnTreatisePart {
  const JohnTreatisePart({
    required this.part,
    required this.title,
    required this.chapters,
  });

  final int part;
  final String title;
  final List<JohnTreatiseChapter> chapters;

  factory JohnTreatisePart.fromJson(Map<String, dynamic> json) {
    return JohnTreatisePart(
      part: json['part'] as int,
      title: json['title'] as String,
      chapters:
          (json['chapters'] as List)
              .map(
                (e) => JohnTreatiseChapter.fromJson(e as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => a.chapter.compareTo(b.chapter)),
    );
  }
}

class JohnTreatiseBook {
  const JohnTreatiseBook({
    required this.id,
    required this.title,
    required this.parts,
  });

  final String id;
  final String title;
  final List<JohnTreatisePart> parts;

  factory JohnTreatiseBook.fromJson(Map<String, dynamic> json) {
    return JohnTreatiseBook(
      id: json['id'] as String,
      title: json['title'] as String,
      parts:
          (json['parts'] as List)
              .map((e) => JohnTreatisePart.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.part.compareTo(b.part)),
    );
  }

  JohnTreatiseChapter? chapter(int book, int chapter) {
    for (final part in parts) {
      if (part.part != book) continue;
      for (final c in part.chapters) {
        if (c.chapter == chapter) return c;
      }
    }
    return null;
  }

  JohnTreatisePart? partByNumber(int book) {
    for (final part in parts) {
      if (part.part == book) return part;
    }
    return null;
  }
}

class JohnTreatises {
  const JohnTreatises({required this.translator, required this.books});

  final String translator;
  final List<JohnTreatiseBook> books;

  JohnTreatiseBook? byId(String id) {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }

  static Future<JohnTreatises> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/john-cross/treatises.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return JohnTreatises(
      translator: json['translator'] as String? ?? 'David Lewis (1864)',
      books: (json['books'] as List)
          .map((e) => JohnTreatiseBook.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
