import 'package:dailycompany/data/companion.dart';

/// US Roman calendar memorial / solemnity (or death day for writers).
/// Apple drops the house SKU by $1 on this date; Play cannot.
abstract final class CompanionFeast {
  static const Map<String, String> mmdd = {
    'benedict': '07-11',
    'kempis': '07-25',
    'desales': '01-24',
    'liguori': '08-01',
    'francis': '10-04',
    'john-cross': '12-14',
    'gregory': '09-03',
    'augustine': '08-28',
    'teresa-avila': '10-15',
    'ignatius': '07-31',
    'therese': '10-01',
    'catherine': '04-29',
    'montfort': '04-28',
    'scupoli': '11-28',
    'lawrence': '02-12',
    'cassian': '07-23',
    'desert-fathers': '01-17',
    'newman': '10-09',
    'bernard': '08-20',
    'serra': '07-01',
  };

  static bool isToday(String portalId, [DateTime? now]) {
    final key = mmdd[portalId];
    if (key == null) return false;
    final day = now ?? DateTime.now();
    final parts = key.split('-');
    return day.month == int.parse(parts[0]) && day.day == int.parse(parts[1]);
  }

  static String? line(String portalId, [DateTime? now]) {
    if (!isToday(portalId, now)) return null;
    final house = Companions.byId(portalId);
    if (house == null) return null;
    return house.kind == HouseKind.writer
        ? 'Today the house remembers ${house.name}.'
        : 'Today is the feast of ${house.name}.';
  }
}
