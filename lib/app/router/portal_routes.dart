/// Path builders for the `/p/:portalId/...` shell — see portals-spec.md §5.
///
/// The one place that knows this path shape, so screens build links by
/// calling these instead of hardcoding a portal-scoped route string.
abstract final class PortalRoutes {
  static String today(String portalId) => '/p/$portalId/today';

  // Benedict only.
  static String hours(String portalId) => '/p/$portalId/hours';
  static String office(String portalId, String officeId) =>
      '/p/$portalId/hours/$officeId';
  static String life(String portalId) => '/p/$portalId/life';
  static String lifeEpisode(String portalId, int chapter) =>
      '/p/$portalId/life/$chapter';
  static String tools(String portalId) => '/p/$portalId/tools';
  static String medal(String portalId) => '/p/$portalId/medal';

  // de Sales only.
  static String meditations(String portalId) => '/p/$portalId/meditations';
  static String meditation(String portalId, int order) =>
      '/p/$portalId/meditations/$order';
  static String practice(String portalId) => '/p/$portalId/practice';
  static String letters(String portalId) => '/p/$portalId/letters';
  static String letter(String portalId, int book, int letter) =>
      '/p/$portalId/letters/$book/$letter';

  // Kempis / Francis.
  static String admonitions(String portalId) => '/p/$portalId/admonitions';
  static String admonition(String portalId, int chapter) =>
      '/p/$portalId/admonitions/$chapter';

  // Francis — Fioretti shelf.
  static String stories(String portalId) => '/p/$portalId/stories';
  static String story(String portalId, int chapter) =>
      '/p/$portalId/stories/$chapter';

  // Shared.
  static String lectio(String portalId) => '/p/$portalId/lectio';
  static String sources(String portalId) => '/p/$portalId/sources';
  static String index(String portalId) => '/p/$portalId/index';
  static String paywall(String portalId) => '/p/$portalId/paywall';
}
