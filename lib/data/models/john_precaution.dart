import 'dart:convert';

import 'package:flutter/services.dart';

class JohnPrecaution {
  const JohnPrecaution({
    required this.chapter,
    required this.title,
    required this.textEn,
  });

  final int chapter;
  final String title;
  final String textEn;

  factory JohnPrecaution.fromJson(Map<String, dynamic> json) {
    return JohnPrecaution(
      chapter: json['chapter'] as int,
      title: json['title'] as String,
      textEn: json['textEn'] as String,
    );
  }
}

class JohnPrecautions {
  const JohnPrecautions({required this.title, required this.chapters});

  final String title;
  final List<JohnPrecaution> chapters;

  static Future<JohnPrecautions> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/john-cross/precautions.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final chapters = (json['chapters'] as List)
        .map((e) => JohnPrecaution.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.chapter.compareTo(b.chapter));
    return JohnPrecautions(
      title: json['title'] as String,
      chapters: chapters,
    );
  }
}
