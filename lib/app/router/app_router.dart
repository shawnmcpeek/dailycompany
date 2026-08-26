import 'package:dailycompany/app/router/page_turn.dart';
import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/desales/desales_letters_screen.dart';
import 'package:dailycompany/features/desales/desales_meditations_screen.dart';
import 'package:dailycompany/features/desales/desales_practice_screen.dart';
import 'package:dailycompany/features/desales/desales_today_screen.dart';
import 'package:dailycompany/features/hallway/hallway_screen.dart';
import 'package:dailycompany/features/hours/hours_screen.dart';
import 'package:dailycompany/features/hub/hub_screen.dart';
import 'package:dailycompany/features/iap/desales_companion_paywall_screen.dart';
import 'package:dailycompany/features/iap/oblate_paywall_screen.dart';
import 'package:dailycompany/features/lectio/lectio_screen.dart';
import 'package:dailycompany/features/life/life_screen.dart';
import 'package:dailycompany/features/medal/medal_screen.dart';
import 'package:dailycompany/features/more/more_screen.dart';
import 'package:dailycompany/features/more/sources_screen.dart';
import 'package:dailycompany/features/onboarding/welcome_screen.dart';
import 'package:dailycompany/features/today/today_screen.dart';
import 'package:dailycompany/features/tools/tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Where a portal's own landing screen is, once a house is chosen. Benedict
/// keeps its dashboard; every other portal goes straight to Today — Hub is
/// a Benedict-specific bonus screen, not part of the generic portal shape.
String portalLandingRoute(String portalId) =>
    portalId == 'benedict' ? '/hub' : PortalRoutes.today(portalId);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen<AppSettings>(settingsProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  // Watched (not read) — switching portals rebuilds the whole router, so
  // each portal's shell gets fresh branch locations instead of carrying
  // over the previous portal's. A full navigation reset on switch is the
  // right behaviour here: leaving one saint's house for another's is a
  // fresh start, not a sub-navigation within the same shell.
  final portalId = ref.watch(currentPortalIdProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/hallway',
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      if (!settings.ready) return null;

      final loc = state.matchedLocation;
      final onWelcome = loc.startsWith('/welcome');
      final onHallway = loc == '/hallway';

      if (!settings.onboardingComplete && !onWelcome) {
        return '/welcome';
      }
      if (settings.onboardingComplete && onWelcome) {
        return settings.companionId.isEmpty
            ? '/hallway'
            : portalLandingRoute(settings.companionId);
      }
      if (settings.onboardingComplete &&
          settings.companionId.isEmpty &&
          !onHallway) {
        return '/hallway';
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
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/hallway',
        pageBuilder: (context, state) =>
            PageTurn.of(key: state.pageKey, child: const HallwayScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/',
        redirect: (context, state) =>
            portalLandingRoute(ref.read(currentPortalIdProvider)),
      ),
      if (portalId == 'benedict')
        _benedictShell(portalId)
      else
        _desalesShell(portalId),
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
        path: '/p/:portalId/lectio',
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
        path: '/p/:portalId/medal',
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
        path: '/p/:portalId/sources',
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
        path: '/p/:portalId/paywall',
        pageBuilder: (context, state) {
          final id = state.pathParameters['portalId'];
          final child = id == 'desales'
              ? const DesalesCompanionPaywallScreen()
              : const OblatePaywallScreen();
          final title = id == 'desales' ? 'Companion' : 'Oblate';
          return PageTurn.of(
            key: state.pageKey,
            child: Scaffold(
              appBar: AppBar(title: Text(title)),
              body: child,
            ),
          );
        },
      ),
    ],
  );
});

/// Hub, Today, Hours, Life, Tools — unchanged from before de Sales existed.
StatefulShellRoute _benedictShell(String portalId) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell),
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
        initialLocation: PortalRoutes.today(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/today',
            pageBuilder: (context, state) =>
                PageTurn.of(key: state.pageKey, child: const TodayScreen()),
          ),
        ],
      ),
      StatefulShellBranch(
        initialLocation: PortalRoutes.hours(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/hours',
            pageBuilder: (context, state) =>
                PageTurn.of(key: state.pageKey, child: const HoursScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => PageTurn.of(
                  key: state.pageKey,
                  child: OfficeScreen(officeId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        initialLocation: PortalRoutes.life(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/life',
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
        initialLocation: PortalRoutes.tools(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/tools',
            pageBuilder: (context, state) =>
                PageTurn.of(key: state.pageKey, child: const ToolsScreen()),
          ),
        ],
      ),
    ],
  );
}

/// Today, Meditations, Practice, Letters — de Sales' own shape (spec §8.4),
/// not force-fit into Benedict's Hub/Hours/Life/Tools tabs.
StatefulShellRoute _desalesShell(String portalId) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        initialLocation: PortalRoutes.today(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/today',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const DesalesTodayScreen(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        initialLocation: PortalRoutes.meditations(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/meditations',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const DesalesMeditationsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':order',
                pageBuilder: (context, state) => PageTurn.of(
                  key: state.pageKey,
                  child: DesalesMeditationScreen(
                    order: int.parse(state.pathParameters['order']!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        initialLocation: PortalRoutes.practice(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/practice',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const Scaffold(
                appBar: null,
                body: SafeArea(child: DesalesPracticeScreen()),
              ),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        initialLocation: PortalRoutes.letters(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/letters',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const Scaffold(body: SafeArea(child: DesalesLettersScreen())),
            ),
            routes: [
              GoRoute(
                path: ':book/:letter',
                pageBuilder: (context, state) => PageTurn.of(
                  key: state.pageKey,
                  child: DesalesLetterScreen(
                    book: int.parse(state.pathParameters['book']!),
                    letter: int.parse(state.pathParameters['letter']!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _benedictDestinations = [
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
  ];

  static const _desalesDestinations = [
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Today',
    ),
    NavigationDestination(
      icon: Icon(Icons.self_improvement_outlined),
      selectedIcon: Icon(Icons.self_improvement),
      label: 'Meditations',
    ),
    NavigationDestination(
      icon: Icon(Icons.spa_outlined),
      selectedIcon: Icon(Icons.spa),
      label: 'Practice',
    ),
    NavigationDestination(
      icon: Icon(Icons.mail_outline),
      selectedIcon: Icon(Icons.mail),
      label: 'Letters',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portalId = ref.watch(currentPortalIdProvider);
    final destinations =
        portalId == 'benedict' ? _benedictDestinations : _desalesDestinations;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: destinations,
      ),
    );
  }
}
