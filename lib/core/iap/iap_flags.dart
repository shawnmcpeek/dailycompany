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

  /// Pass at build time when enabling IAP:
  /// `--dart-define=REVENUECAT_API_KEY=appl_...` (iOS) or `goog_...` (Android).
  /// For a single key across platforms, use RC's public SDK key for that store build.
  static const apiKey = String.fromEnvironment('REVENUECAT_API_KEY');

  /// Free Life episodes: Prologue (0) + chapters 1–5.
  static const freeLifeChapterMax = 5;
}
