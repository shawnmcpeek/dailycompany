import 'dart:convert';

import 'package:flutter/services.dart';

class PlaceStop {
  const PlaceStop({
    required this.order,
    required this.name,
    required this.shortName,
    required this.foundedYear,
    required this.founded,
    required this.foundedBy,
    required this.act,
    required this.textEn,
    required this.lat,
    required this.lon,
    this.prayerKey,
  });

  final int order;
  final String name;
  final String shortName;
  final int foundedYear;
  final String founded;
  final String foundedBy;
  final int act;
  final String textEn;
  final double lat;
  final double lon;
  final String? prayerKey;

  bool get free => act <= 1;

  factory PlaceStop.fromJson(Map<String, dynamic> json) {
    return PlaceStop(
      order: json['order'] as int,
      name: json['name'] as String,
      shortName: json['shortName'] as String? ?? json['name'] as String,
      foundedYear: json['foundedYear'] as int,
      founded: json['founded'] as String? ?? '${json['foundedYear']}',
      foundedBy: json['foundedBy'] as String,
      act: json['act'] as int,
      textEn: json['textEn'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      prayerKey: json['prayerKey'] as String?,
    );
  }
}

class JourneyDay {
  const JourneyDay({
    required this.dayIndex,
    required this.dateKey,
    required this.location,
    required this.textEn,
    this.prayerKey,
  });

  final int dayIndex;
  final String dateKey;
  final String location;
  final String textEn;
  final String? prayerKey;

  factory JourneyDay.fromJson(Map<String, dynamic> json) {
    return JourneyDay(
      dayIndex: json['dayIndex'] as int,
      dateKey: json['dateKey'] as String,
      location: json['location'] as String,
      textEn: json['textEn'] as String,
      prayerKey: json['prayerKey'] as String?,
    );
  }
}

class JourneyQuiet {
  const JourneyQuiet({
    required this.title,
    required this.location,
    required this.textEn,
  });

  final String title;
  final String location;
  final String textEn;

  factory JourneyQuiet.fromJson(Map<String, dynamic> json) {
    return JourneyQuiet(
      title: json['title'] as String,
      location: json['location'] as String? ?? '',
      textEn: json['textEn'] as String,
    );
  }
}

class Journey {
  const Journey({
    required this.saintId,
    required this.startDateKey,
    required this.endDateKey,
    required this.days,
    required this.quiet,
  });

  final String saintId;
  final String startDateKey;
  final String endDateKey;
  final List<JourneyDay> days;
  final JourneyQuiet quiet;

  static String dateKey(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isActiveOn(DateTime d) {
    final key = dateKey(d);
    return key.compareTo(startDateKey) >= 0 && key.compareTo(endDateKey) <= 0;
  }

  JourneyDay? resolveFor(DateTime d) {
    if (!isActiveOn(d)) return null;
    final key = dateKey(d);
    for (final day in days) {
      if (day.dateKey == key) return day;
    }
    return null;
  }

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      saintId: json['saintId'] as String,
      startDateKey: json['startDateKey'] as String,
      endDateKey: json['endDateKey'] as String,
      days: (json['days'] as List)
          .map((e) => JourneyDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      quiet: JourneyQuiet.fromJson(json['quiet'] as Map<String, dynamic>),
    );
  }
}

class PlacePrayer {
  const PlacePrayer({
    required this.key,
    required this.title,
    required this.note,
    this.textEn,
    this.textEs,
    this.joys = const [],
  });

  final String key;
  final String title;
  final String note;
  final String? textEn;
  final String? textEs;
  final List<PlacePrayerJoy> joys;

  factory PlacePrayer.fromJson(Map<String, dynamic> json) {
    return PlacePrayer(
      key: json['key'] as String,
      title: json['title'] as String,
      note: json['note'] as String? ?? '',
      textEn: json['textEn'] as String?,
      textEs: json['textEs'] as String?,
      joys: (json['joys'] as List? ?? [])
          .map((e) => PlacePrayerJoy.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlacePrayerJoy {
  const PlacePrayerJoy({
    required this.order,
    required this.title,
    required this.prompt,
  });

  final int order;
  final String title;
  final String prompt;

  factory PlacePrayerJoy.fromJson(Map<String, dynamic> json) {
    return PlacePrayerJoy(
      order: json['order'] as int,
      title: json['title'] as String,
      prompt: json['prompt'] as String,
    );
  }
}

class PlaceSaint {
  const PlaceSaint({
    required this.saintId,
    required this.stops,
    required this.journey,
    required this.prayers,
  });

  final String saintId;
  final List<PlaceStop> stops;
  final Journey journey;
  final List<PlacePrayer> prayers;

  PlaceStop? stopByOrder(int order) {
    for (final s in stops) {
      if (s.order == order) return s;
    }
    return null;
  }

  PlacePrayer? prayer(String key) {
    for (final p in prayers) {
      if (p.key == key) return p;
    }
    return null;
  }

  static Future<PlaceSaint> load(String saintId) async {
    final missionsRaw = await rootBundle.loadString(
      'assets/content/$saintId/missions.json',
    );
    final journeyRaw = await rootBundle.loadString(
      'assets/content/$saintId/journey.json',
    );
    final prayersRaw = await rootBundle.loadString(
      'assets/content/$saintId/prayers.json',
    );
    final missions = jsonDecode(missionsRaw) as Map<String, dynamic>;
    final journey = jsonDecode(journeyRaw) as Map<String, dynamic>;
    final prayers = jsonDecode(prayersRaw) as Map<String, dynamic>;
    final stops = (missions['stops'] as List)
        .map((e) => PlaceStop.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return PlaceSaint(
      saintId: saintId,
      stops: stops,
      journey: Journey.fromJson(journey),
      prayers: (prayers['prayers'] as List)
          .map((e) => PlacePrayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
