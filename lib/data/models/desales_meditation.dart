import 'dart:convert';

import 'package:flutter/services.dart';

/// Part I's ten meditations — spec §8.4. Self-contained, shown whole (not
/// portioned by the daily cutter). See tools/content/desales/meditations.py.
class DesalesMeditation {
  const DesalesMeditation({
    required this.order,
    required this.title,
    required this.topic,
    required this.textEn,
  });

  final int order;
  final String title;
  final String topic;
  final String textEn;

  factory DesalesMeditation.fromJson(Map<String, dynamic> json) {
    return DesalesMeditation(
      order: json['order'] as int,
      title: json['title'] as String,
      topic: json['topic'] as String,
      textEn: json['textEn'] as String,
    );
  }

  static Future<List<DesalesMeditation>> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/desales/meditations.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['meditations'] as List)
        .map((e) => DesalesMeditation.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
