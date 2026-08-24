import 'package:dailycompany/app/theme/palette.dart';
import 'package:flutter/material.dart';

/// v1 liturgical color resolver — seasons + a few fixed feasts. No full Ordo.
abstract final class LiturgicalColorResolver {
  static Color forDay(DateTime d) {
    final key = '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    // Fixed solemnities this audience cares about.
    const goldDays = {
      '12-25', // Christmas
      '01-01', // Mary / Octave of Christmas (gold)
      '01-06', // Epiphany
      '02-10', // Scholastica
      '03-21', // Passing of Benedict
      '03-25', // Annunciation
      '07-11', // Solemnity of Benedict
      '08-15', // Assumption
      '11-01', // All Saints
    };
    if (goldDays.contains(key)) return LiturgicalColor.gold;
    if (key == '11-02') return LiturgicalColor.black; // All Souls

    final easter = _easter(d.year);
    final ashWednesday = easter.subtract(const Duration(days: 46));
    final palmSunday = easter.subtract(const Duration(days: 7));
    final goodFriday = easter.subtract(const Duration(days: 2));
    final pentecost = easter.add(const Duration(days: 49));
    final adventStart = _adventStart(d.year);

    final day = DateTime(d.year, d.month, d.day);

    if (_same(day, palmSunday) || _same(day, goodFriday) || _same(day, pentecost)) {
      return LiturgicalColor.red;
    }
    // Gaudete / Laetare (3rd Advent / 4th Lent Sunday) — approximate by range midpoints.
    final gaudete = adventStart.add(const Duration(days: 14));
    final laetare = ashWednesday.add(const Duration(days: 21));
    if (_same(day, gaudete) || _same(day, laetare)) return LiturgicalColor.rose;

    if (!day.isBefore(adventStart) && day.isBefore(DateTime(d.year, 12, 25))) {
      return LiturgicalColor.violet;
    }
    if (!day.isBefore(DateTime(d.year, 12, 25)) ||
        day.isBefore(DateTime(d.year, 1, 7))) {
      return LiturgicalColor.gold; // Christmas season through Epiphany
    }
    if (!day.isBefore(ashWednesday) && day.isBefore(easter)) {
      return LiturgicalColor.violet;
    }
    if (!day.isBefore(easter) && day.isBefore(pentecost.add(const Duration(days: 1)))) {
      return LiturgicalColor.gold;
    }
    return LiturgicalColor.green;
  }

  /// Meeus/Jones/Butcher computus for Gregorian Easter.
  static DateTime _easter(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  static DateTime _adventStart(int year) {
    // Fourth Sunday before Christmas.
    var christmas = DateTime(year, 12, 25);
    var weekday = christmas.weekday; // Mon=1 … Sun=7
    var christmasSundayOffset = weekday % 7; // days since Sunday
    var fourthSunday = christmas.subtract(Duration(days: christmasSundayOffset));
    return fourthSunday.subtract(const Duration(days: 21));
  }

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
