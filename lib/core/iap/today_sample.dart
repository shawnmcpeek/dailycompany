import 'package:dailycompany/core/cycle/cycle_calendar.dart';

/// Seven morning pages per house, then Companion. No countdown.
abstract final class TodaySample {
  static const int daysPerHouse = 7;

  static String dateKey(DateTime day) => CycleCalendar.dateKey(day);

  /// [alreadyFree] is a chapter that stays open without Companion
  /// (Ignatius 1–3, Benedict Life 1–N). Those do not spend a sample.
  static bool allows({
    required bool unlocked,
    required List<String> sampled,
    required String dateKey,
    bool alreadyFree = false,
  }) {
    if (unlocked || alreadyFree) return true;
    if (sampled.contains(dateKey)) return true;
    return sampled.length < daysPerHouse;
  }

  static bool shouldRecord({
    required bool unlocked,
    required List<String> sampled,
    required String dateKey,
    bool alreadyFree = false,
  }) {
    if (unlocked || alreadyFree || dateKey.isEmpty) return false;
    if (sampled.contains(dateKey)) return false;
    return sampled.length < daysPerHouse;
  }
}
