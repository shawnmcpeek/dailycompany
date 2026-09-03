import 'package:dailycompany/data/companion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every companion house is open', () {
    final open = Companions.openHouses.map((c) => c.id).toSet();
    expect(open, {
      'benedict',
      'desales',
      'kempis',
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
      'serra',
    });
    expect(Companions.byId('benedict')?.open, isTrue);
    expect(Companions.byId('desales')?.open, isTrue);
    expect(Companions.byId('kempis')?.open, isTrue);
    expect(Companions.byId('liguori')?.open, isTrue);
    expect(Companions.byId('francis')?.open, isTrue);
    expect(Companions.byId('john-cross')?.open, isTrue);
    expect(Companions.byId('gregory')?.open, isTrue);
    expect(Companions.byId('augustine')?.open, isTrue);
    expect(Companions.byId('teresa-avila')?.open, isTrue);
    expect(Companions.byId('ignatius')?.open, isTrue);
    expect(Companions.byId('therese')?.open, isTrue);
    expect(Companions.byId('catherine')?.open, isTrue);
    expect(Companions.byId('montfort')?.open, isTrue);
    expect(Companions.byId('scupoli')?.open, isTrue);
    expect(Companions.byId('lawrence')?.open, isTrue);
    expect(Companions.byId('cassian')?.open, isTrue);
    expect(Companions.byId('serra')?.open, isTrue);
  });

  test('every companion has a unique id', () {
    final ids = Companions.all.map((c) => c.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('closed houses stay listed', () {
    expect(Companions.closedHouses, isEmpty);
  });

  test('Kempis is a writer, never a saint in chrome', () {
    final kempis = Companions.byId('kempis')!;
    expect(kempis.kind, HouseKind.writer);
    expect(kempis.name.toLowerCase(), isNot(contains('saint')));
    expect(kempis.name.toLowerCase(), isNot(contains('st.')));
    expect(kempis.hallwaySubtitle, startsWith('Writer ·'));
  });

  test('writers in the hallway are labeled', () {
    final writers = Companions.all.where((c) => c.kind == HouseKind.writer);
    expect(writers.map((c) => c.id).toSet(), {'kempis', 'scupoli', 'lawrence'});
    for (final w in writers) {
      expect(w.hallwaySubtitle, startsWith('Writer ·'));
    }
  });

  test('Serra is a place house, never a writer cycle', () {
    final serra = Companions.byId('serra')!;
    expect(serra.kind, HouseKind.place);
    expect(serra.hallwaySubtitle, startsWith('Place ·'));
    expect(serra.hallwaySubtitle, contains('California Missions'));
  });
}
