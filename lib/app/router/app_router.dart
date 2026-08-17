import 'package:benedictdaily/app/router/page_turn.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/features/hours/hours_screen.dart';
import 'package:benedictdaily/features/hub/hub_screen.dart';
import 'package:benedictdaily/features/iap/oblate_paywall_screen.dart';
import 'package:benedictdaily/features/lectio/lectio_screen.dart';
import 'package:benedictdaily/features/life/life_screen.dart';
import 'package:benedictdaily/features/medal/medal_screen.dart';
import 'package:benedictdaily/features/more/more_screen.dart';
import 'package:benedictdaily/features/more/sources_screen.dart';
import 'package:benedictdaily/features/onboarding/welcome_screen.dart';
import 'package:benedictdaily/features/today/today_screen.dart';
import 'package:benedictdaily/features/tools/tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen<AppSettings>(settingsProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/hub',
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      if (!settings.ready) return null;

      final loc = state.matchedLocation;
      final onWelcome = loc.startsWith('/welcome');

      if (!settings.onboardingComplete && !onWelcome) {
        return '/welcome';
      }
      if (settings.onboardingComplete && onWelcome) {
        return '/hub';
      }
      return null;
    },
    routes: [
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/welcome',
        pageBuilder: (context, state) => PageTurn.of(
          key: state.pageKey,
          name: state.name,
          child: const WelcomeScreen(),
        ),
        routes: [
          GoRoute(
            path: 'how',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              name: state.name,
              child: const WelcomeHowScreen(),
            ),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hub',
                pageBuilder: (context, state) =>
                    PageTurn.of(key: state.pageKey, child: const HubScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                pageBuilder: (context, state) =>
                    PageTurn.of(key: state.pageKey, child: const TodayScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hours',
                pageBuilder: (context, state) =>
                    PageTurn.of(key: state.pageKey, child: const HoursScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) => PageTurn.of(
                      key: state.pageKey,
                      child: OfficeScreen(
                        officeId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/life',
                pageBuilder: (context, state) =>
                    PageTurn.of(key: state.pageKey, child: const LifeScreen()),
                routes: [
                  GoRoute(
                    path: ':chapter',
                    pageBuilder: (context, state) => PageTurn.of(
                      key: state.pageKey,
                      child: LifeEpisodeScreen(
                        chapter: int.parse(state.pathParameters['chapter']!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tools',
                pageBuilder: (context, state) =>
                    PageTurn.of(key: state.pageKey, child: const ToolsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/more',
        pageBuilder: (context, state) => PageTurn.of(
          key: state.pageKey,
          child: Scaffold(
            appBar: AppBar(title: const Text('More')),
            body: const MoreScreen(),
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/lectio',
        pageBuilder: (context, state) => PageTurn.of(
          key: state.pageKey,
          child: Scaffold(
            appBar: AppBar(title: const Text('Lectio')),
            body: const LectioScreen(),
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/medal',
        pageBuilder: (context, state) => PageTurn.of(
          key: state.pageKey,
          child: Scaffold(
            appBar: AppBar(title: const Text('The Medal')),
            body: const MedalScreen(),
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/sources',
        pageBuilder: (context, state) => PageTurn.of(
          key: state.pageKey,
          child: Scaffold(
            appBar: AppBar(title: const Text('Sources')),
            body: const SourcesScreen(),
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/oblate',
        pageBuilder: (context, state) => PageTurn.of(
          key: state.pageKey,
          child: Scaffold(
            appBar: AppBar(title: const Text('Oblate')),
            body: const OblatePaywallScreen(),
          ),
        ),
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Hours',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Life',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Tools',
          ),
        ],
      ),
    );
  }
}
