import 'dart:convert';

import 'package:flutter/services.dart';

/// "Letters to Persons in the World" (Mackey trans.) — real content,
/// grouped by the original 7 books. Shown whole, browsed book-by-book,
/// not part of the daily cycle. See tools/content/desales/parse_letters.py
/// and emit_letters.py.
class DesalesLetter {
  const DesalesLetter({
    required this.letter,
    required this.description,
    required this.textEn,
  });

  final int letter;
  final String description;
  final String textEn;

  factory DesalesLetter.fromJson(Map<String, dynamic> json) {
    return DesalesLetter(
      letter: json['letter'] as int,
      description: json['description'] as String,
      textEn: json['textEn'] as String,
    );
  }
}

class DesalesLetterBook {
  const DesalesLetterBook({
    required this.book,
    required this.title,
    required this.letters,
  });

  final int book;
  final String title;
  final List<DesalesLetter> letters;

  factory DesalesLetterBook.fromJson(Map<String, dynamic> json) {
    return DesalesLetterBook(
      book: json['book'] as int,
      title: json['title'] as String,
      letters: (json['letters'] as List)
          .map((e) => DesalesLetter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Future<List<DesalesLetterBook>> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/desales/letters.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['books'] as List)
        .map((e) => DesalesLetterBook.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.book.compareTo(b.book));
  }
}
