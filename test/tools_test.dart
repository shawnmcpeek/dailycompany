import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final raw = jsonDecode(
    File('assets/content/tools_of_good_works.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final tools = (raw['tools'] as List).cast<Map<String, dynamic>>();

  test('there are seventy-two instruments', () {
    expect(tools, hasLength(72));
    expect(tools.map((t) => t['number']), List.generate(72, (i) => i + 1));
  });

  test('scripture and citation travel together', () {
    for (final t in tools) {
      final scripture = (t['scripture'] as String?)?.trim() ?? '';
      final citation = (t['citation'] as String?)?.trim() ?? '';
      if (scripture.isEmpty) {
        expect(citation, isEmpty, reason: 'tool ${t['number']}');
      } else {
        expect(citation, isNotEmpty, reason: 'tool ${t['number']}');
      }
      expect((t['gloss'] as String?)?.trim(), isNotEmpty, reason: 'tool ${t['number']}');
    }
  });

  test('dashing thoughts against the rock is not left without Christ', () {
    final t50 = tools[49];
    expect(t50['number'], 50);
    expect(t50['citation'], 'Psalm 136:9');
    expect((t50['gloss'] as String).toLowerCase(), contains('christ'));
  });
}
