import 'package:dailycompany/app/brand.dart';
import 'package:dailycompany/app/router/app_router.dart';
import 'package:dailycompany/app/theme/app_theme.dart';
import 'package:dailycompany/app/theme/palette.dart';
import 'package:dailycompany/core/cycle/reading_calendar.dart';
import 'package:dailycompany/core/diagnostics/diagnostics_log.dart';
import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/notifications/bell_scheduler.dart';
import 'package:dailycompany/core/sentry/sentry_privacy.dart';
import 'package:dailycompany/data/isar/app_isar.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final packageInfo = await PackageInfo.fromPlatform();
  final release =
      '${packageInfo.packageName}@${packageInfo.version}+${packageInfo.buildNumber}';

  await SentryFlutter.init(
    (options) => configureDailyCompanySentryOptions(options, release: release),
    appRunner: () async {
      await AppIsar.open();
      await DiagnosticsLog.instance.ensureLoaded();
      await BellScheduler.instance.init();
      runApp(const ProviderScope(child: DailyCompanyApp()));
    },
  );
}

class DailyCompanyApp extends ConsumerWidget {
  const DailyCompanyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final day = ref.watch(selectedDayProvider);
    final router = ref.watch(routerProvider);
    ref.watch(bellSyncProvider);
    ref.watch(desalesAspirationSyncProvider);
    ref.watch(kempisCellSyncProvider);
    ref.watch(liguoriVisitSyncProvider);
    ref.watch(francisCanticleSyncProvider);
    ref.watch(cycleReminderSyncProvider);
    ref.watch(iapControllerProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    // Accent driver is per-portal (spec §6): Benedict's is date-driven,
    // de Sales' is Part-driven, Kempis' is Book-driven.
    final portalId = ref.watch(currentPortalIdProvider);
    Color accent;
    if (portalId == 'serra') {
      accent = portalAccent(portalId, 0);
    } else if (portalId == 'desales' ||
        portalId == 'kempis' ||
        portalId == 'liguori' ||
        portalId == 'francis' ||
        portalId == 'john-cross' ||
        portalId == 'gregory' ||
        portalId == 'augustine' ||
        portalId == 'teresa-avila' ||
        portalId == 'ignatius' ||
        portalId == 'therese' ||
        portalId == 'catherine' ||
        portalId == 'montfort' ||
        portalId == 'scupoli' ||
        portalId == 'lawrence' ||
        portalId == 'cassian') {
      if (portalId == 'ignatius') {
        final program =
            ref.watch(ignatiusProgramProvider).valueOrNull;
        final elapsed = settings.ignatiusElapsedDays(day);
        final part = program?.forElapsed(elapsed)?.part ?? 0;
        accent = portalAccent(portalId, part);
      } else {
        final todaysEntries =
            ref.watch(cycleCalendarProvider(portalId)).valueOrNull?.resolveFor(day) ??
                const [];
        final part = todaysEntries.isEmpty ? 1 : todaysEntries.first.part;
        accent = portalAccent(portalId, part);
      }
    } else {
      accent = ReadingCalendar.accentForStatic(day);
    }

    final theme = themeForReadingSurface(
      surface: settings.themeMode,
      accent: accent,
      fontScale: settings.fontScale,
      boldReading: settings.boldReading,
      platformBrightness: platformBrightness,
    );

    if (!settings.ready) {
      return MaterialApp(
        title: Brand.appName,
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: Brand.appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}

/**
 * St Michael the Archangel, pray for us
 * St Benedict, pray for us
 * Mary, Mother of God, pray for us
 * St Joseph, terror of demons, pray for us
 * St Gregory the Great, pray for us
 * St Ignatius of Loyola, pray for us
 * St Augustine, pray for us
 * St Francis of Assisi, pray for us
 * St Teresa of Avila, pray for us
 * St Francis de Sales, pray for us
 * St Alphonsus Liguori, pray for us
 * St Thérèse of Lisieux, pray for us
 * St John of the Cross, pray for us
 * St Catherine of Siena, pray for us
 * St Louis de Montfort, pray for us
 * St John Cassian, pray for us
 * Thomas à Kempis, pray for us
 * Lorenzo Scupoli, pray for us
 * Brother Lawrence, pray for us
 * St Carlo Acutis, pray for us
 * Bl Michael McGivney, pray for us
 * Ven Fulton Sheen, pray for us
 */
