/// Studio identity shown in About and legal chrome.
abstract final class Brand {
  static const appName = 'Daily Company';
  static const studio = 'Daddoo Dev';
  static const foundedYear = 2026;

  /// Updates with the calendar year. Uses a range once past the founding year.
  static String get copyrightNotice {
    final year = DateTime.now().year;
    if (year <= foundedYear) {
      return '© $foundedYear $studio';
    }
    return '© $foundedYear–$year $studio';
  }

  static String get copyrightNoticeFull =>
      '$copyrightNotice. All rights reserved.';
}
