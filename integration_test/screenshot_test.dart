// Store marketing captures. Names match real routes:
//   01_today              Today — daily Rule / Life reading
//   02_hallway            Hallway — saint houses
//   03_reading_calendar   More — year heatmap
//   04_life               Life of Benedict
//   05_more               More — theme / reading display
//
// Benedict chosen, onboarding done, calendar day 2026-03-21, heatmap filled.
// Does not call production main() (no Sentry). Bell scheduler is stubbed.

import 'dart:io';

import 'package:dailycompany/data/isar/app_isar.dart';
import 'package:dailycompany/data/isar/reading_completion.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/hallway/hallway_screen.dart';
import 'package:dailycompany/features/life/life_screen.dart';
import 'package:dailycompany/features/more/reading_heatmap.dart';
import 'package:dailycompany/features/today/today_screen.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _seedDay = DateTime(2026, 3, 21);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('store screenshots', (tester) async {
    await _seedPrefs();
    await AppIsar.open();
    await _seedCompletions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDayProvider.overrideWith((ref) => _seedDay),
          bellSyncProvider.overrideWith((ref) {}),
        ],
        child: const DailyCompanyApp(),
      ),
    );

    await _waitUntil(tester, find.byType(HallwayScreen));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(HallwayScreen), findsOneWidget);

    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }

    await _shot(
      tester,
      binding,
      name: '01_today',
      location: '/today',
      visible: find.widgetWithText(AppBar, 'Today'),
    );
    expect(find.byType(TodayScreen), findsWidgets);

    await _shot(
      tester,
      binding,
      name: '02_hallway',
      location: '/hallway',
      visible: find.textContaining('The hallway'),
    );

    await _go(tester, '/more');
    await _waitUntil(tester, find.byType(ReadingHeatmap));
    await tester.ensureVisible(find.byType(ReadingHeatmap));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03_reading_calendar');

    await _shot(
      tester,
      binding,
      name: '04_life',
      location: '/life',
      visible: find.text('Life of Benedict'),
    );
    expect(find.byType(LifeScreen), findsWidgets);

    await _go(tester, '/more');
    await _waitUntil(tester, find.text('Lectio Divina'));
    await tester.scrollUntilVisible(
      find.text('Page color'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05_more');
  });
}

Future<void> _shot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding, {
  required String name,
  required String location,
  required Finder visible,
}) async {
  await _go(tester, location);
  await _waitUntil(tester, visible);
  expect(visible, findsOneWidget);
  await binding.takeScreenshot(name);
}

Future<void> _go(WidgetTester tester, String location) async {
  final ctx = tester.element(find.byType(Navigator).first);
  GoRouter.of(ctx).go(location);
  await tester.pump();
}

Future<void> _waitUntil(WidgetTester tester, Finder visible) async {
  final deadline = DateTime.now().add(const Duration(seconds: 25));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    final loading = find.byType(EmptyLoading).evaluate().isNotEmpty;
    final spinner = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    if (!loading && !spinner && visible.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  expect(find.byType(EmptyLoading), findsNothing);
  expect(visible, findsOneWidget);
}

Future<void> _seedPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboardingComplete', true);
  await prefs.setString('companionId', 'benedict');
  await prefs.setString('themeMode', 'vellum');
  await prefs.setString('lifeTrackStart', '2026-01-01');
  await prefs.setBool('showReadingRun', true);
  await prefs.setBool('hapticsEnabled', false);
  await prefs.setBool('bellsEnabled', false);
  await prefs.setBool('medalOpened', true);
  await prefs.setString('dailyTrack', 'life');
}

Future<void> _seedCompletions() async {
  final year = DateTime.now().year;
  final isar = AppIsar.instance;
  await isar.writeTxn(() async {
    await isar.readingCompletions.clear();
    for (final month in [1, 2, 3, 4, 5, 6]) {
      for (final day in [1, 4, 7, 11, 14, 18, 21, 24, 28]) {
        if (month == 2 && day > 28) continue;
        final row = ReadingCompletion()
          ..dateKey =
              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}'
          ..completedAt = DateTime.now();
        await isar.readingCompletions.put(row);
      }
    }
  });
}
