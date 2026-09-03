import 'dart:convert';

import 'package:flutter/services.dart';

class FrancisStory {
  const FrancisStory({
    required this.chapter,
    required this.title,
    required this.textEn,
  });

  final int chapter;
  final String title;
  final String textEn;

  factory FrancisStory.fromJson(Map<String, dynamic> json) {
    return FrancisStory(
      chapter: json['chapter'] as int,
      title: json['title'] as String,
      textEn: json['textEn'] as String,
    );
  }
}

class FrancisStories {
  const FrancisStories({required this.label, required this.chapters});

  final String label;
  final List<FrancisStory> chapters;

  static Future<FrancisStories> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/francis/stories.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final chapters =
        (json['chapters'] as List)
            .map((e) => FrancisStory.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.chapter.compareTo(b.chapter));
    return FrancisStories(
      label: json['label'] as String? ?? 'Stories told about him',
      chapters: chapters,
    );
  }
}
