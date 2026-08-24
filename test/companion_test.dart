import 'package:dailycompany/data/companion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Benedict is the only open house', () {
    final open = Companions.openHouses;
    expect(open, hasLength(1));
    expect(open.single.id, 'benedict');
    expect(Companions.byId('benedict')?.open, isTrue);
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
