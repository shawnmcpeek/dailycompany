import 'package:dailycompany/core/iap/today_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same cycle date does not spend twice', () {
    const sampled = ['10-15'];
    expect(
      TodaySample.allows(
        unlocked: false,
        sampled: sampled,
        dateKey: '10-15',
      ),
      isTrue,
    );
    expect(
      TodaySample.shouldRecord(
        unlocked: false,
        sampled: sampled,
        dateKey: '10-15',
      ),
      isFalse,
    );
  });

  test('a new house has its own seven', () {
    expect(
      TodaySample.allows(
        unlocked: false,
        sampled: const [],
        dateKey: '10-15',
      ),
      isTrue,
    );
  });

  test('seven distinct dates then lock unsampled days', () {
    final sampled = [
      for (var d = 1; d <= TodaySample.daysPerHouse; d++)
        '10-${d.toString().padLeft(2, '0')}',
    ];
    expect(
      TodaySample.allows(
        unlocked: false,
        sampled: sampled,
        dateKey: '10-01',
      ),
      isTrue,
    );
    expect(
      TodaySample.allows(
        unlocked: false,
        sampled: sampled,
        dateKey: '11-01',
      ),
      isFalse,
    );
    expect(
      TodaySample.shouldRecord(
        unlocked: false,
        sampled: sampled,
        dateKey: '11-01',
      ),
      isFalse,
    );
  });

  test('purchase and already-free chapters skip the sample', () {
    expect(
      TodaySample.allows(
        unlocked: true,
        sampled: const [],
        dateKey: '10-15',
      ),
      isTrue,
    );
    expect(
      TodaySample.shouldRecord(
        unlocked: true,
        sampled: const [],
        dateKey: '10-15',
      ),
      isFalse,
    );
    expect(
      TodaySample.shouldRecord(
        unlocked: false,
        sampled: const [],
        dateKey: '10-15',
        alreadyFree: true,
      ),
      isFalse,
    );
  });
}
