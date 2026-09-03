/// The portal registry — see portals-spec.md §5.
///
/// Spine / AnchorPractice / PortalPalette from the spec's full class are
/// still not modelled. Benedict keeps [ReadingCalendar]. Constructed
/// houses share [CycleCalendar].
library;

/// Whether a portal's reading cycle is the saint's own historical practice
/// or one this app constructed to fit a corpus to a calendar.
enum CycleProvenance { traditional, constructed, partlyTraditional }

class SaintPortal {
  const SaintPortal({
    required this.id,
    required this.displayName,
    required this.tagline,
    required this.provenance,
    required this.provenanceTitle,
    required this.provenanceParagraphs,
    required this.disclaimer,
    required this.modules,
    this.unlockSku,
  });

  /// Matches this portal's content folder name (see the loader).
  final String id;
  final String displayName;
  final String tagline;
  final CycleProvenance provenance;

  /// Heading for the "about this reading cycle" sheet — spec §4.
  final String provenanceTitle;

  /// Body paragraphs for that sheet, verbatim, already substituted for
  /// this portal's saint/work/translator.
  final List<String> provenanceParagraphs;

  /// Verbatim, store description + About.
  final String disclaimer;
  final List<String> modules;
  final String? unlockSku;
}

abstract final class PortalRegistry {
  static const benedict = SaintPortal(
    id: 'benedict',
    displayName: 'Benedict of Nursia',
    tagline: 'Keep company with a saint.',
    provenance: CycleProvenance.traditional,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This cycle is traditional. The Rule has been read in this '
          'division — the whole of it three times a year, on these '
          'dates — in monastic houses for centuries. The dates are '
          'that custom’s, not ours.',
      'The translation is Boniface Verheyen’s, 1902.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, endorsed '
        'by, or produced by any Benedictine monastery, abbey, congregation, '
        'or the Order of Saint Benedict.',
    modules: ['today', 'hours', 'life', 'tools', 'medal', 'lectio'],
    unlockSku: 'benedict_daily_oblate',
  );

  /// Content is real (assets/content/desales/), cut from the CCEL text by
  /// tools/content/desales/. Edition is the anonymous 1876 Rivingtons
  /// "Library of Spiritual Works for English Catholics" — not Mackey.
  /// Cadence is 366 entries, not 365 x 1 as the
  /// spec's table states: the spec's ~120k-word estimate for this text was
  /// wrong (it's 78,600), and packing to 365 without splitting paragraphs
  /// meant accepting some entries under the 150-word hard minimum — a
  /// deliberate call for daily freshness over merging thin days into their
  /// neighbor. 366 lands a clean 1:1 on a leap year; common years merge the
  /// last two entries onto Dec 31 (see calendar.json), mirroring Benedict's
  /// own leap-day handling with the common/leap roles swapped. No Today
  /// screen or spine resolver reads this yet — see the library comment
  /// above.
  static const desales = SaintPortal(
    id: 'desales',
    displayName: 'Francis de Sales',
    tagline: 'Be who you are, and be that well.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This year-long cycle was made for this app. It is not a '
          'traditional division of the text: Francis de Sales did not '
          'write the Devout Life to be read a page a day, and no '
          'religious order or published edition assigns these passages '
          'to these dates. We cut the book into 366 readings at '
          'paragraph and chapter boundaries so it could be kept company '
          'with daily.',
      'The text itself is unaltered — the 1876 Rivingtons edition '
          '(Library of Spiritual Works for English Catholics). The '
          'title page names no translator. It is not Mackey’s, and '
          'it is not John K. Ryan’s 1950 version.',
      'If you’d rather read it straight through as it was written, '
          'turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, '
        'endorsed by, or produced by the Salesians of Don Bosco, the '
        'Order of the Visitation, any Salesian or Visitandine province '
        'or house, or any shrine or publisher associated with them.',
    modules: ['today', 'meditations', 'practice', 'letters'],
    unlockSku: 'desales_companion',
  );

  static const kempis = SaintPortal(
    id: 'kempis',
    displayName: 'Thomas à Kempis',
    tagline: 'Love God, and serve Him only.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This year-long cycle was made for this app. It is not a '
          'traditional division of the text: Thomas à Kempis did not '
          'write the Imitation of Christ to be read a page a day, and '
          'no religious order or published edition assigns these '
          'passages to these dates. We cut the book into 366 readings '
          'at paragraph and chapter boundaries so it could be kept '
          'company with daily.',
      'The text itself is unaltered — Rev. William Benham’s 1886 '
          'translation, complete, all four books.',
      'If you’d rather read it straight through as it was written, '
          'turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, '
        'endorsed by, or produced by the Canons Regular of St. Augustine, '
        'the Congregation of Windesheim, the Brothers of the Common Life, '
        'any house associated with them, or any shrine or publisher of '
        'the Imitation.',
    modules: ['today', 'admonitions', 'practice'],
    unlockSku: 'kempis_companion',
  );

  static const liguori = SaintPortal(
    id: 'liguori',
    displayName: 'Alphonsus Liguori',
    tagline: 'My Jesus, I will love Thee only.',
    provenance: CycleProvenance.partlyTraditional,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'Alphonsus wrote thirty-one Visits to the Blessed Sacrament, '
          'one for each day of the month. Those thirty-one are his. '
          'Mapping them onto every calendar month is ours: the first '
          'of the month is always the First Visit, and so on. Months '
          'that end before the 29th, 30th, or 31st simply omit those '
          'Visits. We do not fold them onto the last day.',
      'The text itself is unaltered — Eugene Grimm’s translation in '
          'the Centenary Edition (Benziger, 1887), from The Holy '
          'Eucharist, Volume VI of the Complete Ascetical Works.',
      'If you’d rather read the thirty-one Visits straight through, '
          'turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, '
        'endorsed by, or produced by the Congregation of the Most '
        'Holy Redeemer, Liguori Publications, any Redemptorist '
        'province or house, or any shrine or publisher associated '
        'with them.',
    modules: ['today', 'practice'],
    unlockSku: 'liguori_companion',
  );

  static const francis = SaintPortal(
    id: 'francis',
    displayName: 'Francis of Assisi',
    tagline: 'Most high, omnipotent, good Lord.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This cycle was made for this app. Francis did not arrange '
          'his writings to be read a page a day, and no order or '
          'published edition assigns these passages to these dates. '
          'The corpus is short, so the writings repeat '
          'through the year rather than being padded out.',
      'The text itself is unaltered — Paschal Robinson’s 1905 '
          'translation of the authentic writings. The Little Flowers '
          'are stories told about him; they live on their own shelf, '
          'never mixed into the daily readings.',
      'If you’d rather read the writings straight through as they '
          'stand, turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, '
        'endorsed by, or produced by the Order of Friars Minor, the '
        'Capuchins, the Conventuals, any Franciscan province or house, '
        'or any shrine or publisher associated with them.',
    modules: ['today', 'admonitions', 'stories', 'practice'],
    unlockSku: 'francis_companion',
  );

  static const all = <SaintPortal>[benedict, desales, kempis, liguori, francis];

  static SaintPortal? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
