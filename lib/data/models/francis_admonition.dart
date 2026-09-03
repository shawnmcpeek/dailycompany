import 'dart:convert';

import 'package:flutter/services.dart';

class FrancisAdmonition {
  const FrancisAdmonition({
    required this.chapter,
    required this.title,
    required this.textEn,
  });

  final int chapter;
  final String title;
  final String textEn;

  factory FrancisAdmonition.fromJson(Map<String, dynamic> json) {
    return FrancisAdmonition(
      chapter: json['chapter'] as int,
      title: json['title'] as String,
      textEn: json['textEn'] as String,
    );
  }
}

class FrancisAdmonitions {
  const FrancisAdmonitions({required this.title, required this.chapters});

  final String title;
  final List<FrancisAdmonition> chapters;

  static Future<FrancisAdmonitions> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/francis/admonitions.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final chapters =
        (json['chapters'] as List)
            .map((e) => FrancisAdmonition.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.chapter.compareTo(b.chapter));
    return FrancisAdmonitions(
      title: json['title'] as String,
      chapters: chapters,
    );
  }
}
