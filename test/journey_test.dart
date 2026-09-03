import 'dart:convert';
import 'dart:io';

import 'package:dailycompany/data/models/place_saint.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceSaint loadSerra() {
  final missions = jsonDecode(
    File('assets/content/serra/missions.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final journey = jsonDecode(
    File('assets/content/serra/journey.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final prayers = jsonDecode(
    File('assets/content/serra/prayers.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final stops = (missions['stops'] as List)
      .map((e) => PlaceStop.fromJson(e as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  return PlaceSaint(
    saintId: 'serra',
    stops: stops,
    journey: Journey.fromJson(journey),
    prayers: (prayers['prayers'] as List)
        .map((e) => PlacePrayer.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

void main() {
  final place = loadSerra();

  test('twenty-one missions in three acts', () {
    expect(place.stops.length, 21);
    expect(place.stops.map((s) => s.order).toList(), List.generate(21, (i) => i + 1));
    expect(place.stops.where((s) => s.act == 1).length, 9);
    expect(place.stops.where((s) => s.act == 2).length, 9);
    expect(place.stops.where((s) => s.act == 3).length, 3);
    expect(place.stopByOrder(6)?.foundedBy, contains('Palóu'));
    expect(place.stopByOrder(8)?.foundedBy, contains('Peña'));
    expect(place.stopByOrder(21)?.foundedBy.toLowerCase(), contains('altimira'));
  });

  test('every day in the 1769 window resolves; outside it is quiet', () {
    final j = place.journey;
    expect(j.startDateKey, '03-28');
    expect(j.endDateKey, '07-01');
    for (var d = DateTime(2024, 3, 28);
        !d.isAfter(DateTime(2024, 7, 1));
        d = d.add(const Duration(days: 1))) {
      expect(j.isActiveOn(d), isTrue, reason: Journey.dateKey(d));
      expect(j.resolveFor(d), isNotNull, reason: Journey.dateKey(d));
      expect(j.resolveFor(d)!.location, isNotEmpty);
      expect(j.resolveFor(d)!.textEn.trim(), isNotEmpty);
      expect(j.resolveFor(d)!.textEn.toLowerCase(), isNot(contains('day 47')));
      expect(
        j.resolveFor(d)!.textEn,
        isNot(contains('Day ${j.resolveFor(d)!.dayIndex} of')),
      );
    }
    expect(j.days.length, 96);
    expect(j.isActiveOn(DateTime(2024, 3, 27)), isFalse);
    expect(j.resolveFor(DateTime(2024, 3, 27)), isNull);
    expect(j.isActiveOn(DateTime(2024, 7, 2)), isFalse);
    expect(j.resolveFor(DateTime(2025, 12, 25)), isNull);
    expect(j.quiet.textEn, contains('twenty-eighth of March'));
  });

  test('journey and missions stay off Tibesar and modern photos', () {
    final blob = [
      ...place.journey.days.map((d) => d.textEn),
      ...place.stops.map((s) => s.textEn),
      place.journey.quiet.textEn,
    ].join(' ');
    expect(blob.toLowerCase(), isNot(contains('tibesar')));
    expect(blob.toLowerCase(), isNot(contains('hackel')));
    expect(blob.toLowerCase(), isNot(contains('geiger')));
  });

  test('pins have coordinates', () {
    for (final s in place.stops) {
      expect(s.lat, inInclusiveRange(32.5, 42.0), reason: s.name);
      expect(s.lon, inInclusiveRange(-124.5, -114.0), reason: s.name);
    }
  });

  test('founding order zigzags; the Camino does not', () {
    final byOrder = {for (final s in place.stops) s.order: s};
    const camino = [
      1, 18, 7, 4, 17, 9, 10, 19, 11, 5, 16, 3, 13, 2, 15, 12, 8, 14, 6, 20, 21,
    ];
    expect(camino, isNot(equals(List.generate(21, (i) => i + 1))));
    // Serra’s second house is Carmel, far north of San Diego; his fourth
    // is San Gabriel, back in the south. Founding is not the road.
    expect(byOrder[2]!.lat, greaterThan(byOrder[1]!.lat + 2));
    expect(byOrder[4]!.lat, lessThan(byOrder[2]!.lat - 1));
  });

  test('prayers are the three named in the spec', () {
    expect(place.prayers.map((p) => p.key).toSet(), {'alabado', 'angelus', 'crown'});
    expect(place.prayer('alabado')?.textEs, contains('Alabado'));
    expect(place.prayer('crown')?.joys.length, 7);
  });
}
