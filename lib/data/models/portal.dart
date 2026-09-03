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

  static const johnCross = SaintPortal(
    id: 'john-cross',
    displayName: 'John of the Cross',
    tagline: 'There is no progress but in the imitation of Christ.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This cycle was made for this app. John did not arrange '
          'the sayings to be read one a day, and no order or '
          'published edition assigns these passages to these dates. '
          'Each saying stands alone — we do not bundle them to fill '
          'the page. The treatises are a later shelf, not this year. '
          'Two closing pieces sit in the index, off the calendar.',
      'The text itself is unaltered — David Lewis’s 1864 translation '
          'of the Precautions and Spiritual Maxims. It is not the '
          'Kavanaugh–Rodriguez ICS edition.',
      'If you’d rather read the sayings straight through as they '
          'stand, turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, '
        'endorsed by, or produced by the Order of Discalced Carmelites, '
        'any Carmelite province or house, ICS Publications, or any '
        'shrine or publisher associated with them.',
    modules: ['today', 'precautions', 'practice'],
    unlockSku: 'john-cross_companion',
  );

  static const gregory = SaintPortal(
    id: 'gregory',
    displayName: 'Gregory the Great',
    tagline: 'The government of souls is the art of arts.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This cycle was made for this app. Gregory did not write the '
          'Pastoral Rule to be read a page a day, and no edition '
          'assigns these passages to these dates. The book is read '
          'twice a year — thin days over padding.',
      'The text itself is unaltered — James Barmby’s translation in '
          'Nicene and Post-Nicene Fathers, Second Series, Volume 12 '
          '(1895). Dialogues Book II already ships as Benedict’s Life; '
          'it is not recut here.',
      'If you’d rather read the Rule straight through as it was '
          'written, turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, '
        'endorsed by, or produced by any diocese, papal household, '
        'or publisher associated with Gregory the Great.',
    modules: ['today', 'practice'],
    unlockSku: 'gregory_companion',
  );

  static const augustine = SaintPortal(
    id: 'augustine',
    displayName: 'Augustine of Hippo',
    tagline: 'Our heart is restless, until it repose in Thee.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This year-long cycle was made for this app. It is not a '
          'traditional division of the text: Augustine did not write '
          'the Confessions to be read a page a day, and no order or '
          'published edition assigns these passages to these dates. '
          'We cut Books I–X into 366 readings at paragraph and chapter '
          'boundaries so they could be kept company with daily.',
      'The text itself is unaltered — E. B. Pusey’s 1838 translation. '
          'Books XI–XIII are an appendix, reachable from the index and '
          'Read Through, not mapped onto the calendar. This is not '
          'City of God.',
      'If you’d rather read it straight through as it was written, '
          'turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, '
        'endorsed by, or produced by the Order of Saint Augustine, '
        'any Augustinian province or house, or any shrine or '
        'publisher associated with them.',
    modules: ['today', 'practice'],
    unlockSku: 'augustine_companion',
  );

  static const teresaAvila = SaintPortal(
    id: 'teresa-avila',
    displayName: 'Teresa of Avila',
    tagline: 'Let nothing disturb thee.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This year-long cycle was made for this app. It is not a '
          'traditional division of the text: Teresa did not write the '
          'Way of Perfection or the Interior Castle to be read a page '
          'a day, and no order or published edition assigns these '
          'passages to these dates. A dwelling is never split across '
          'a day’s entry. The seven mansions drive the accent.',
      'The text itself is unaltered — the Benedictines of Stanbrook, '
          'revised by Benedict Zimmerman (1911–12). It is not Peers, '
          'and it is not the ICS Kavanaugh–Rodriguez edition.',
      'If you’d rather read the books straight through as they were '
          'written, turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, '
        'endorsed by, or produced by the Order of Discalced Carmelites, '
        'any Carmelite province or house, ICS Publications, or any '
        'shrine or publisher associated with them.',
    modules: ['today', 'practice'],
    unlockSku: 'teresa-avila_companion',
  );

  static const ignatius = SaintPortal(
    id: 'ignatius',
    displayName: 'Ignatius of Loyola',
    tagline: 'Find God in all things.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'The Autobiography is cut for this app and repeats through '
          'the year. Ignatius did not arrange those chapters to be read '
          'a page a day. The Spiritual Exercises are not on that calendar: '
          'they run as a 210-day program, thirty weeks, because the Weeks '
          'are meant to do their work in order.',
      'The texts are unaltered — J. F. X. O’Conor’s Autobiography (1900) '
          'and Elder Mullan’s Spiritual Exercises (1914), from the Autograph. '
          'This is not Puhl, Ganss, or Fleming.',
      'If you’d rather read the Autobiography straight through, turn on '
          'Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, endorsed '
        'by, or produced by the Society of Jesus, any Jesuit province or '
        'house, or any Ignatian retreat centre or publisher.',
    modules: ['today', 'practice', 'discernment', 'exercises'],
    unlockSku: 'ignatius_companion',
  );

  static const therese = SaintPortal(
    id: 'therese',
    displayName: 'Thérèse of Lisieux',
    tagline: 'My vocation is love.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This year-long cycle was made for this app. Thérèse did not write '
          'the Story of a Soul to be read a page a day, and no edition '
          'assigns these passages to these dates.',
      'The text itself is unaltered — Thomas N. Taylor’s 1912 English of '
          'the 1898 Pauline Histoire d’une Âme. That is the historically '
          'famous edited Thérèse, not the 1956 manuscript restoration, '
          'not Clarke, and not Knox.',
      'If you’d rather read it straight through as it was written, '
          'turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, endorsed '
        'by, or produced by the Order of Discalced Carmelites, any Carmelite '
        'province or house, the shrine at Lisieux, the Office Central de '
        'Lisieux, ICS Publications, or any shrine or publisher associated '
        'with them.',
    modules: ['today', 'practice'],
    unlockSku: 'therese_companion',
  );

  static const catherine = SaintPortal(
    id: 'catherine',
    displayName: 'Catherine of Siena',
    tagline: 'Remain in the cell of self-knowledge.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This year-long cycle was made for this app. Catherine did not '
          'dictate the Dialogue to be read a page a day, and no edition '
          'assigns these passages to these dates.',
      'The text itself is unaltered — Algar Thorold’s 1907 translation.',
      'If you’d rather read it straight through as it was written, '
          'turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, endorsed '
        'by, or produced by the Dominican Order, the Order of Preachers, '
        'any Dominican province or house, or any shrine or publisher '
        'associated with them.',
    modules: ['today', 'practice'],
    unlockSku: 'catherine_companion',
  );

  static const montfort = SaintPortal(
    id: 'montfort',
    displayName: 'Louis de Montfort',
    tagline: 'It is by Mary that He has to reign in the world.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This cycle was made for this app. Montfort did not write True '
          'Devotion to be read a page a day. This is not a thirty-three-day '
          'consecration program.',
      'The text itself is unaltered — Frederick William Faber’s 1863 '
          'translation.',
      'If you’d rather read it straight through as it was written, '
          'turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, endorsed '
        'by, or produced by the Company of Mary, the Montfort Missionaries, '
        'the Daughters of Wisdom, any shrine or publisher associated with '
        'them.',
    modules: ['today', 'practice'],
    unlockSku: 'montfort_companion',
  );

  static const scupoli = SaintPortal(
    id: 'scupoli',
    displayName: 'Lorenzo Scupoli',
    tagline: 'Distrust yourself, and trust in God.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This cycle was made for this app. Scupoli did not write the '
          'Spiritual Combat to be read a page a day. The book is read in '
          'repeating passes rather than padded out.',
      'The text itself is unaltered — the anonymous 1875 Rivingtons '
          'translation (Library of Spiritual Works for English Catholics). '
          'The title page names no translator.',
      'If you’d rather read it straight through as it was written, '
          'turn on Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, endorsed '
        'by, or produced by the Theatines, any shrine, or any publisher of '
        'the Spiritual Combat.',
    modules: ['today', 'practice'],
    unlockSku: 'scupoli_companion',
  );

  static const lawrence = SaintPortal(
    id: 'lawrence',
    displayName: 'Brother Lawrence',
    tagline: 'Practice the presence of God.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This cycle was made for this app. The conversations and letters '
          'are short, so they repeat through the year rather than being '
          'padded out.',
      'The text itself is unaltered — the anonymous nineteenth-century '
          'English issued by Fleming H. Revell, translated from the French.',
      'If you’d rather read it straight through as it stands, turn on '
          'Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, endorsed '
        'by, or produced by the Order of Discalced Carmelites, any Carmelite '
        'province or house, or any shrine or publisher associated with them.',
    modules: ['today', 'practice'],
    unlockSku: 'lawrence_companion',
  );

  static const cassian = SaintPortal(
    id: 'cassian',
    displayName: 'John Cassian',
    tagline: 'Purity of heart is the goal.',
    provenance: CycleProvenance.constructed,
    provenanceTitle: 'About this reading cycle',
    provenanceParagraphs: [
      'This year-long cycle was made for this app. Cassian did not '
          'arrange the Conferences to be read a page a day, and no edition '
          'assigns these passages to these dates.',
          'The text itself is unaltered — Edgar C. S. Gibson’s translation in '
          'Nicene and Post-Nicene Fathers, Second Series, Volume 11 (1894). '
          'The Institutes and the work against Nestorius are not included. '
          'Gibson did not translate Conferences XII and XXII; they are not '
          'invented here.',
      'If you’d rather read the Conferences straight through, turn on '
          'Read Through under the reading.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, endorsed '
        'by, or produced by any diocese or publisher. Cassian predates the '
        'later religious orders; this app makes no imprimatur claim.',
    modules: ['today', 'practice'],
    unlockSku: 'cassian_companion',
  );

  static const serra = SaintPortal(
    id: 'serra',
    displayName: 'Junípero Serra',
    tagline: 'I have put all my trust in God.',
    provenance: CycleProvenance.traditional,
    provenanceTitle: 'About this journey',
    provenanceParagraphs: [
      'This is not a page-a-day of Serra’s letters. The journey follows '
          'the historical dates of the 1769 overland expedition from Loreto '
          'to San Diego: Palóu’s Relación Histórica in C. Scott Williams’s '
          '1913 English, and Portolá’s diary in Smith and Teggart’s 1909 '
          'Academy of Pacific Coast History text. The dates are the '
          'expedition’s, not ours.',
      'The twenty-one missions are a gallery, not a cycle. Engelhardt is '
          'a Franciscan partisan; that is named on Sources.',
      'After the first of July the journey sits quiet until the twenty-eighth '
          'of March. It does not loop.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, endorsed '
        'by, or produced by the Order of Friars Minor, the Franciscan Friars '
        'of California, Serra International, any California mission parish, '
        'or any shrine or publisher associated with them.',
    modules: ['journey', 'missions', 'practice'],
    unlockSku: 'serra_companion',
  );

  static const all = <SaintPortal>[
    benedict,
    desales,
    kempis,
    liguori,
    francis,
    johnCross,
    gregory,
    augustine,
    teresaAvila,
    ignatius,
    therese,
    catherine,
    montfort,
    scupoli,
    lawrence,
    cassian,
    serra,
  ];

  static SaintPortal? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
