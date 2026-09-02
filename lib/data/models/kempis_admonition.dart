import 'dart:convert';

import 'package:flutter/services.dart';

class KempisAdmonition {
  const KempisAdmonition({
    required this.chapter,
    required this.title,
    required this.textEn,
  });

  final int chapter;
  final String title;
  final String textEn;

  factory KempisAdmonition.fromJson(Map<String, dynamic> json) {
    return KempisAdmonition(
      chapter: json['chapter'] as int,
      title: json['title'] as String,
      textEn: json['textEn'] as String,
    );
  }
}

class KempisAdmonitions {
  const KempisAdmonitions({required this.title, required this.chapters});

  final String title;
  final List<KempisAdmonition> chapters;

  static Future<KempisAdmonitions> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/kempis/admonitions.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final chapters = (json['chapters'] as List)
        .map((e) => KempisAdmonition.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.chapter.compareTo(b.chapter));
    return KempisAdmonitions(
      title: json['title'] as String,
      chapters: chapters,
    );
  }
}
