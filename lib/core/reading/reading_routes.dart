/// Path helpers for resume and bookmarks. Content stays in JSON; this
/// only classifies `/p/:portalId/...` reading locations.
abstract final class ReadingRoutes {
  static const pageModules = {'today', 'journey', 'exercises'};

  static const shelfModules = {
    'life',
    'hours',
    'letters',
    'meditations',
    'admonitions',
    'stories',
    'precautions',
    'treatises',
    'discernment',
    'missions',
  };

  static List<String> parts(String route) =>
      Uri.parse(route).pathSegments.where((s) => s.isNotEmpty).toList();

  /// A place the app should reopen: a day's page, or a chapter inside a shelf.
  static bool isResumable(String route, [String? portalId]) {
    final p = parts(route);
    if (p.length < 3 || p.first != 'p') return false;
    if (portalId != null && p[1] != portalId) return false;
    final module = p[2];
    if (pageModules.contains(module)) return p.length == 3;
    if (shelfModules.contains(module)) return p.length > 3;
    return false;
  }

  static bool isShelfRoot(String route) {
    final p = parts(route);
    return p.length == 3 && p.first == 'p' && shelfModules.contains(p[2]);
  }

  static String? portalId(String route) {
    final p = parts(route);
    if (p.length >= 2 && p.first == 'p') return p[1];
    return null;
  }

  static String? module(String route) {
    final p = parts(route);
    if (p.length >= 3 && p.first == 'p') return p[2];
    return null;
  }

  static String snippet(String text, {int max = 140}) {
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= max) return collapsed;
    return '${collapsed.substring(0, max).trimRight()}…';
  }
}
