import 'package:dailycompany/core/iap/companion_feast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every open house has a feast or commemoration day', () {
    const houses = [
      'benedict',
      'kempis',
      'desales',
      'liguori',
      'francis',
      'john-cross',
      'gregory',
      'augustine',
      'teresa-avila',
      'ignatius',
      'therese',
      'catherine',
      'montfort',
      'scupoli',
      'lawrence',
      'cassian',
      'desert-fathers',
      'newman',
      'bernard',
      'serra',
    ];
    for (final id in houses) {
      expect(CompanionFeast.mmdd[id], isNotNull, reason: id);
      expect(
        RegExp(r'^\d{2}-\d{2}$').hasMatch(CompanionFeast.mmdd[id]!),
        isTrue,
      );
    }
  });

  test('Newman is 9 October; writers remember rather than feast', () {
    expect(
      CompanionFeast.isToday('newman', DateTime(2026, 10, 9)),
      isTrue,
    );
    expect(
      CompanionFeast.line('newman', DateTime(2026, 10, 9)),
      'Today is the feast of John Henry Newman.',
    );
    expect(
      CompanionFeast.line('kempis', DateTime(2026, 7, 25)),
      'Today the house remembers Thomas à Kempis.',
    );
    expect(CompanionFeast.line('newman', DateTime(2026, 10, 10)), isNull);
  });

  test('Teresa of Avila is 15 October', () {
    expect(
      CompanionFeast.isToday('teresa-avila', DateTime(2026, 10, 15)),
      isTrue,
    );
  });
}
