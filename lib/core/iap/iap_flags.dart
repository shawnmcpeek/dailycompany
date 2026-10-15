/// Master switch for store billing. While false, everything stays unlocked.
abstract final class IapFlags {
  static const enabled = true;

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
  static const johnCrossProductId = 'john_cross_companion';

  static const gregoryEntitlementId = 'gregory_companion';
  static const gregoryProductId = 'gregory_companion';

  static const augustineEntitlementId = 'augustine_companion';
  static const augustineProductId = 'augustine_companion';

  static const teresaAvilaEntitlementId = 'teresa-avila_companion';
  static const teresaAvilaProductId = 'teresa_avila_companion';

  static const ignatiusEntitlementId = 'ignatius_companion';
  static const ignatiusProductId = 'ignatius_companion';

  static const thereseEntitlementId = 'therese_companion';
  static const thereseProductId = 'therese_companion';

  static const catherineEntitlementId = 'catherine_companion';
  static const catherineProductId = 'catherine_companion';

  static const montfortEntitlementId = 'montfort_companion';
  static const montfortProductId = 'montfort_companion';

  static const scupoliEntitlementId = 'scupoli_companion';
  static const scupoliProductId = 'scupoli_companion';

  static const lawrenceEntitlementId = 'lawrence_companion';
  static const lawrenceProductId = 'lawrence_companion';

  static const cassianEntitlementId = 'cassian_companion';
  static const cassianProductId = 'cassian_companion';

  static const desertFathersEntitlementId = 'desert-fathers_companion';
  static const desertFathersProductId = 'desert_fathers_companion';

  static const serraEntitlementId = 'serra_companion';
  static const serraProductId = 'serra_companion';

  static const newmanEntitlementId = 'newman_companion';
  static const newmanProductId = 'newman_companion';

  static const bernardEntitlementId = 'bernard_companion';
  static const bernardProductId = 'bernard_companion';

  /// Bundle entitlement covering every open house. Scaffolded now so
  /// individual SKUs can later grant this without a migration fight.
  static const allSaintsEntitlementId = 'all_saints';
  static const allSaintsProductId = 'all_saints';

  /// Optional override. Otherwise the public SDK key for this store is used.
  static const apiKey = String.fromEnvironment('REVENUECAT_API_KEY');

  static const appleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_API_KEY',
    defaultValue: 'appl_jdmGaDWwQuPRjJxjnZOfZYRNErM',
  );

  static const googleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
    defaultValue: 'goog_ULoXgURVzGrxAFLokjNHtMfLcsb',
  );

  /// Free Life episodes: Prologue (0) + chapters 1–5.
  static const freeLifeChapterMax = 5;

  /// Ignatius Autobiography: first three chapters stay free.
  static const freeIgnatiusChapterMax = 3;
}
