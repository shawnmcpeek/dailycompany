import 'package:dailycompany/data/companion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Benedict and de Sales are the open houses', () {
    final open = Companions.openHouses.map((c) => c.id).toSet();
    expect(open, {'benedict', 'desales'});
    expect(Companions.byId('benedict')?.open, isTrue);
    expect(Companions.byId('desales')?.open, isTrue);
  });

  test('every companion has a unique id', () {
    final ids = Companions.all.map((c) => c.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('closed houses stay listed', () {
    expect(Companions.closedHouses, isNotEmpty);
    expect(Companions.closedHouses.every((c) => !c.open), isTrue);
  });
}
