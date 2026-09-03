import 'dart:convert';

import 'package:flutter/services.dart';

class FrancisCanticle {
  const FrancisCanticle({required this.title, required this.textEn});

  final String title;
  final String textEn;

  static Future<FrancisCanticle> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/content/francis/canticle.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return FrancisCanticle(
      title: json['title'] as String,
      textEn: json['textEn'] as String,
    );
  }
}
