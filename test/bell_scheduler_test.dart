import 'package:dailycompany/core/notifications/bell_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Angelus rides the office-bell scheduler, not a second one', () {
    expect(BellScheduler.angelusIds, [
      'angelus-dawn',
      'angelus-noon',
      'angelus-evening',
    ]);
    expect(BellScheduler.defaultTimes['angelus-dawn'], '06:00');
    expect(BellScheduler.defaultTimes['angelus-noon'], '12:00');
    expect(BellScheduler.defaultTimes['angelus-evening'], '18:00');
    for (final id in BellScheduler.angelusIds) {
      expect(BellScheduler.officeIds.contains(id), isFalse);
    }
  });
}
