/// Master switch for store billing. Leave `false` until RevenueCat keys +
/// products are live. While false, everything stays unlocked.
abstract final class IapFlags {
  static const enabled = false;

  /// RevenueCat entitlement identifier — Benedict's Oblate unlock.
  static const entitlementId = 'oblate';

  /// Store product / package id from the spec.
  static const productId = 'benedict_daily_oblate';

  /// RevenueCat entitlement identifier — de Sales' Companion unlock.
  static const desalesEntitlementId = 'desales_companion';

  /// Store product / package id — portals-spec.md §8.4.
  static const desalesProductId = 'desales_companion';

  /// RevenueCat entitlement — Kempis' Companion unlock.
  static const kempisEntitlementId = 'kempis_companion';

  /// Store product / package id — portals-spec.md §9.5.
  static const kempisProductId = 'kempis_companion';

  /// RevenueCat entitlement — Liguori's Companion unlock.
  static const liguoriEntitlementId = 'liguori_companion';

  /// Store product / package id.
  static const liguoriProductId = 'liguori_companion';

  /// RevenueCat entitlement — Francis' Companion unlock.
  static const francisEntitlementId = 'francis_companion';

  /// Store product / package id.
  static const francisProductId = 'francis_companion';

  static const johnCrossEntitlementId = 'john-cross_companion';
  static const johnCrossProductId = 'john-cross_companion';

  static const gregoryEntitlementId = 'gregory_companion';
  static const gregoryProductId = 'gregory_companion';

  static const augustineEntitlementId = 'augustine_companion';
  static const augustineProductId = 'augustine_companion';

  static const teresaAvilaEntitlementId = 'teresa-avila_companion';
  static const teresaAvilaProductId = 'teresa-avila_companion';

  /// Bundle entitlement covering every open house. Scaffolded now so
  /// individual SKUs can later grant this without a migration fight.
  static const allSaintsEntitlementId = 'all_saints';

  /// Pass at build time when enabling IAP:
  /// `--dart-define=REVENUECAT_API_KEY=appl_...` (iOS) or `goog_...` (Android).
  /// For a single key across platforms, use RC's public SDK key for that store build.
  static const apiKey = String.fromEnvironment('REVENUECAT_API_KEY');

  /// Free Life episodes: Prologue (0) + chapters 1–5.
  static const freeLifeChapterMax = 5;
}
