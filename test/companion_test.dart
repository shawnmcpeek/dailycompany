import 'package:dailycompany/data/companion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Benedict, de Sales, and Kempis are the open houses', () {
    final open = Companions.openHouses.map((c) => c.id).toSet();
    expect(open, {'benedict', 'desales', 'kempis'});
    expect(Companions.byId('benedict')?.open, isTrue);
    expect(Companions.byId('desales')?.open, isTrue);
    expect(Companions.byId('kempis')?.open, isTrue);
  });

  test('every companion has a unique id', () {
    final ids = Companions.all.map((c) => c.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('closed houses stay listed', () {
    expect(Companions.closedHouses, isNotEmpty);
    expect(Companions.closedHouses.every((c) => !c.open), isTrue);
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
}
