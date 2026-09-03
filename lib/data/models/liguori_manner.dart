import 'dart:convert';

import 'package:flutter/services.dart';

/// Shared prayers of the Visit — the free practice, not the day's Visit text.
class LiguoriManner {
  const LiguoriManner({
    required this.actsBefore,
    required this.spiritualCommunion,
    required this.shorterAct,
    required this.closingMary,
  });

  final String actsBefore;
  final String spiritualCommunion;
  final String shorterAct;
  final String closingMary;

  static Future<LiguoriManner> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/liguori/manner.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return LiguoriManner(
      actsBefore: json['actsBefore'] as String,
      spiritualCommunion: json['spiritualCommunion'] as String,
      shorterAct: json['shorterAct'] as String,
      closingMary: json['closingMary'] as String,
    );
  }
}
