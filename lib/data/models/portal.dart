/// The portal registry — see portals-spec.md §5.
///
/// [SaintPortal.spine], [SaintPortal.anchor], and [SaintPortal.palette] from
/// the spec's full class are deliberately not modelled yet: they need the
/// `Spine`/`AnchorPractice`/`PortalPalette` machinery the spec defers to
/// portal #2 (de Sales), and this task's non-goals exclude building that
/// machinery ahead of a consumer. Benedict keeps running on the existing
/// `ReadingCalendar` and palette/theme code untouched.
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

  static const all = <SaintPortal>[benedict];

  static SaintPortal? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
