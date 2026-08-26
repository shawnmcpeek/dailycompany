import 'package:dailycompany/data/models/portal.dart';

/// A writer whose house you can keep. Only [open] houses have a daily cycle yet.
class Companion {
  const Companion({required this.id, required this.name, required this.work});

  final String id;
  final String name;
  final String work;

  /// True once this house has a [SaintPortal] in the registry.
  bool get open => PortalRegistry.byId(id) != null;
}

abstract final class Companions {
  static const benedict = Companion(
    id: 'benedict',
    name: 'Benedict of Nursia',
    work: 'The Rule',
  );

  static const all = <Companion>[
    benedict,
    Companion(
      id: 'kempis',
      name: 'Thomas à Kempis',
      work: 'The Imitation of Christ',
    ),
    Companion(
      id: 'desales',
      name: 'Francis de Sales',
      work: 'Introduction to the Devout Life',
    ),
    Companion(
      id: 'ignatius',
      name: 'Ignatius of Loyola',
      work: 'The Spiritual Exercises',
    ),
    Companion(
      id: 'augustine',
      name: 'Augustine of Hippo',
      work: 'The Confessions',
    ),
    Companion(
      id: 'francis',
      name: 'Francis of Assisi',
      work: 'Rule, Testament, Admonitions',
    ),
    Companion(
      id: 'teresa-avila',
      name: 'Teresa of Avila',
      work: 'The Way of Perfection',
    ),
    Companion(id: 'gregory', name: 'Gregory the Great', work: 'Pastoral Care'),
    Companion(
      id: 'liguori',
      name: 'Alphonsus Liguori',
      work: 'Uniformity with God’s Will',
    ),
    Companion(
      id: 'therese',
      name: 'Thérèse of Lisieux',
      work: 'Story of a Soul',
    ),
    Companion(
      id: 'john-cross',
      name: 'John of the Cross',
      work: 'The Ascent of Mount Carmel',
    ),
    Companion(
      id: 'catherine',
      name: 'Catherine of Siena',
      work: 'The Dialogue',
    ),
    Companion(
      id: 'montfort',
      name: 'Louis de Montfort',
      work: 'True Devotion to Mary',
    ),
    Companion(
      id: 'scupoli',
      name: 'Lorenzo Scupoli',
      work: 'The Spiritual Combat',
    ),
    Companion(
      id: 'lawrence',
      name: 'Brother Lawrence',
      work: 'The Practice of the Presence of God',
    ),
    Companion(id: 'cassian', name: 'John Cassian', work: 'The Conferences'),
  ];

  static Companion? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<Companion> get openHouses =>
      all.where((c) => c.open).toList(growable: false);

  static List<Companion> get closedHouses =>
      all.where((c) => !c.open).toList(growable: false);
}
