import 'package:dailycompany/app/router/app_router.dart';
import 'package:dailycompany/core/reading/reading_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingRoutes.isResumable', () {
    test('today and journey pages resume', () {
      expect(ReadingRoutes.isResumable('/p/desales/today'), isTrue);
      expect(ReadingRoutes.isResumable('/p/serra/journey'), isTrue);
      expect(ReadingRoutes.isResumable('/p/ignatius/exercises'), isTrue);
    });

    test('shelf lists do not resume; chapters do', () {
      expect(ReadingRoutes.isResumable('/p/benedict/life'), isFalse);
      expect(ReadingRoutes.isResumable('/p/benedict/life/5'), isTrue);
      expect(ReadingRoutes.isResumable('/p/desales/letters'), isFalse);
      expect(ReadingRoutes.isResumable('/p/desales/letters/1/12'), isTrue);
      expect(ReadingRoutes.isResumable('/p/john-cross/treatises'), isFalse);
      expect(
        ReadingRoutes.isResumable('/p/john-cross/treatises/ascent/1/3'),
        isTrue,
      );
      expect(ReadingRoutes.isResumable('/p/benedict/hours/compline'), isTrue);
    });

    test('paywall and more are not readings', () {
      expect(ReadingRoutes.isResumable('/p/desales/paywall'), isFalse);
      expect(ReadingRoutes.isResumable('/more'), isFalse);
      expect(ReadingRoutes.isResumable('/hallway'), isFalse);
    });

    test('portal filter rejects another house', () {
      expect(
        ReadingRoutes.isResumable('/p/desales/letters/1/1', 'benedict'),
        isFalse,
      );
      expect(
        ReadingRoutes.isResumable('/p/desales/letters/1/1', 'desales'),
        isTrue,
      );
    });
  });

  test('snippet collapses whitespace and trims', () {
    expect(ReadingRoutes.snippet('  a   b  '), 'a b');
    expect(
      ReadingRoutes.snippet('x' * 200).endsWith('…'),
      isTrue,
    );
    expect(ReadingRoutes.snippet('x' * 200).length, 141);
  });

  test('landing prefers a saved chapter over the house default', () {
    expect(
      portalLandingRoute(
        'desales',
        lastRoute: '/p/desales/letters/2/4',
      ),
      '/p/desales/letters/2/4',
    );
    expect(portalLandingRoute('desales'), '/p/desales/today');
    expect(portalLandingRoute('benedict'), '/hub');
    expect(
      portalLandingRoute('benedict', lastRoute: '/p/benedict/life/3'),
      '/p/benedict/life/3',
    );
    expect(
      portalLandingRoute('desales', lastRoute: '/p/desales/paywall'),
      '/p/desales/today',
    );
  });
}
