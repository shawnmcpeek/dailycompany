/// Master switch for store billing. Leave `false` until RevenueCat keys +
/// `benedict_daily_oblate` are live. While false, Oblate features stay unlocked.
abstract final class IapFlags {
  static const enabled = false;

  /// RevenueCat entitlement identifier.
  static const entitlementId = 'oblate';

  /// Store product / package id from the spec.
  static const productId = 'benedict_daily_oblate';

  /// Pass at build time when enabling IAP:
  /// `--dart-define=REVENUECAT_API_KEY=appl_...` (iOS) or `goog_...` (Android).
  /// For a single key across platforms, use RC's public SDK key for that store build.
  static const apiKey = String.fromEnvironment('REVENUECAT_API_KEY');

  /// Free Life episodes: Prologue (0) + chapters 1–5.
  static const freeLifeChapterMax = 5;
}
