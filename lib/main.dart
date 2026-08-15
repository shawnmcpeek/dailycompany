import 'package:benedictdaily/app/router/app_router.dart';
import 'package:benedictdaily/app/theme/app_theme.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BenedictDailyApp()));
}

class BenedictDailyApp extends ConsumerWidget {
  const BenedictDailyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final day = ref.watch(selectedDayProvider);
    final router = ref.watch(routerProvider);
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
        title: 'Benedict Daily',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Benedict Daily',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
