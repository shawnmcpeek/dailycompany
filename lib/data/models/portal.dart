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
    required this.disclaimer,
    required this.modules,
    this.unlockSku,
  });

  /// Matches the folder name under `assets/content/`.
  final String id;
  final String displayName;
  final String tagline;
  final CycleProvenance provenance;

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
