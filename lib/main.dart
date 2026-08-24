import 'package:dailycompany/app/brand.dart';
import 'package:dailycompany/app/router/app_router.dart';
import 'package:dailycompany/app/theme/app_theme.dart';
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
    ref.watch(iapControllerProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final theme = themeForReadingSurface(
      surface: settings.themeMode,
      day: day,
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
 * St Carlo Acutis, pray for us
 * Bl Michael McGivney, pray for us
 */
