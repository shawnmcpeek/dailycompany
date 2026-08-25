/// The portal registry — see portals-spec.md §5.
///
/// [SaintPortal.spine], [SaintPortal.anchor], and [SaintPortal.palette] from
/// the spec's full class are still not modelled: they need the
/// `Spine`/`AnchorPractice`/`PortalPalette` machinery the spec envisions as
/// shared infrastructure, which has no consumer yet — de Sales has content
/// (assets/content/desales/) and a registry entry, but no Today screen,
/// spine resolver, or anchor practice wired to it. Benedict keeps running
/// on the existing `ReadingCalendar` and palette/theme code untouched.
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
  /// tools/content/desales/. Translator attribution is UNVERIFIED — see
  /// portal.json's sourceNote. Cadence is 233 entries (not 365): the
  /// spec's ~120k-word estimate for this text was wrong (it's 78,600),
  /// and packing to 365 x 1 without splitting paragraphs isn't possible
  /// at that word count. No Today screen or spine resolver reads this
  /// yet — see the library comment above.
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
          'to these dates. We cut the book into 233 readings at '
          'paragraph and chapter boundaries so it could be kept company '
          'with daily.',
      'The text itself is unaltered — an English translation from the '
          '1880s; the exact edition and translator are still being '
          'confirmed.',
    ],
    disclaimer:
        'An independent app from Daddoo Dev. Not affiliated with, '
        'endorsed by, or produced by the Salesians of Don Bosco, the '
        'Order of the Visitation, any Salesian or Visitandine province '
        'or house, or any shrine or publisher associated with them.',
    modules: ['today', 'meditations', 'practice', 'letters'],
    unlockSku: 'desales_companion',
  );

  static const all = <SaintPortal>[benedict, desales];

  static SaintPortal? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
