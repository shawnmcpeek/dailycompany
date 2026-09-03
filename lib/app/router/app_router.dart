import 'package:dailycompany/app/router/page_turn.dart';
import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/models/portal.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/cycle/cycle_index_screen.dart';
import 'package:dailycompany/features/cycle/cycle_today_screen.dart';
import 'package:dailycompany/features/desales/desales_letters_screen.dart';
import 'package:dailycompany/features/desales/desales_meditations_screen.dart';
import 'package:dailycompany/features/desales/desales_practice_screen.dart';
import 'package:dailycompany/features/hallway/hallway_screen.dart';
import 'package:dailycompany/features/hours/hours_screen.dart';
import 'package:dailycompany/features/hub/hub_screen.dart';
import 'package:dailycompany/features/iap/cycle_companion_paywall_screen.dart';
import 'package:dailycompany/features/iap/desales_companion_paywall_screen.dart';
import 'package:dailycompany/features/iap/francis_companion_paywall_screen.dart';
import 'package:dailycompany/features/iap/kempis_companion_paywall_screen.dart';
import 'package:dailycompany/features/iap/liguori_companion_paywall_screen.dart';
import 'package:dailycompany/features/iap/oblate_paywall_screen.dart';
import 'package:dailycompany/features/augustine/augustine_practice_screen.dart';
import 'package:dailycompany/features/francis/francis_admonitions_screen.dart';
import 'package:dailycompany/features/francis/francis_practice_screen.dart';
import 'package:dailycompany/features/francis/francis_stories_screen.dart';
import 'package:dailycompany/features/gregory/gregory_practice_screen.dart';
import 'package:dailycompany/features/john_cross/john_practice_screen.dart';
import 'package:dailycompany/features/john_cross/john_precautions_screen.dart';
import 'package:dailycompany/features/kempis/kempis_admonitions_screen.dart';
import 'package:dailycompany/features/kempis/kempis_practice_screen.dart';
import 'package:dailycompany/features/liguori/liguori_practice_screen.dart';
import 'package:dailycompany/features/teresa/teresa_practice_screen.dart';
import 'package:dailycompany/features/therese/therese_practice_screen.dart';
import 'package:dailycompany/features/ignatius/ignatius_practice_screen.dart';
import 'package:dailycompany/features/ignatius/ignatius_discernment_screen.dart';
import 'package:dailycompany/features/ignatius/ignatius_exercises_screen.dart';
import 'package:dailycompany/features/cycle/simple_practice_screen.dart';
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
        _cycleShell(portalId),
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
        path: '/p/:portalId/index',
        pageBuilder: (context, state) => PageTurn.of(
          key: state.pageKey,
          child: Scaffold(
            appBar: AppBar(title: const Text('Readings')),
            body: const CycleIndexScreen(),
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
          final Widget child;
          final String title;
          if (id == 'desales') {
            child = const DesalesCompanionPaywallScreen();
            title = 'Companion';
          } else if (id == 'kempis') {
            child = const KempisCompanionPaywallScreen();
            title = 'Companion';
          } else if (id == 'liguori') {
            child = const LiguoriCompanionPaywallScreen();
            title = 'Companion';
          } else if (id == 'francis') {
            child = const FrancisCompanionPaywallScreen();
            title = 'Companion';
          } else if (id == 'john-cross' ||
              id == 'gregory' ||
              id == 'augustine' ||
              id == 'teresa-avila' ||
              id == 'ignatius' ||
              id == 'therese' ||
              id == 'catherine' ||
              id == 'montfort' ||
              id == 'scupoli' ||
              id == 'lawrence' ||
              id == 'cassian') {
            child = CycleCompanionPaywallScreen(portalId: id!);
            title = 'Companion';
          } else {
            child = const OblatePaywallScreen();
            title = 'Oblate';
          }
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

/// Today plus the house's own modules — not force-fit into Benedict's tabs.
StatefulShellRoute _cycleShell(String portalId) {
  final portal = PortalRegistry.byId(portalId);
  final modules = portal?.modules ?? const ['today'];
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell),
    branches: [for (final module in modules) _cycleBranch(portalId, module)],
  );
}

StatefulShellBranch _cycleBranch(String portalId, String module) {
  switch (module) {
    case 'meditations':
      return StatefulShellBranch(
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
      );
    case 'practice':
      return StatefulShellBranch(
        initialLocation: PortalRoutes.practice(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/practice',
            pageBuilder: (context, state) {
              final id = state.pathParameters['portalId'] ?? portalId;
              final Widget body;
              if (id == 'kempis') {
                body = const KempisPracticeScreen();
              } else if (id == 'liguori') {
                body = const LiguoriPracticeScreen();
              } else if (id == 'francis') {
                body = const FrancisPracticeScreen();
              } else if (id == 'john-cross') {
                body = const JohnPracticeScreen();
              } else if (id == 'gregory') {
                body = const GregoryPracticeScreen();
              } else if (id == 'augustine') {
                body = const AugustinePracticeScreen();
              } else if (id == 'teresa-avila') {
                body = const TeresaPracticeScreen();
              } else if (id == 'ignatius') {
                body = const IgnatiusPracticeScreen();
              } else if (id == 'therese') {
                body = const TheresePracticeScreen();
              } else if (id == 'catherine' ||
                  id == 'montfort' ||
                  id == 'scupoli' ||
                  id == 'lawrence' ||
                  id == 'cassian') {
                body = SimplePracticeScreen(portalId: id);
              } else {
                body = const DesalesPracticeScreen();
              }
              return PageTurn.of(
                key: state.pageKey,
                child: Scaffold(appBar: null, body: SafeArea(child: body)),
              );
            },
          ),
        ],
      );
    case 'letters':
      return StatefulShellBranch(
        initialLocation: PortalRoutes.letters(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/letters',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const Scaffold(
                body: SafeArea(child: DesalesLettersScreen()),
              ),
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
      );
    case 'admonitions':
      return StatefulShellBranch(
        initialLocation: PortalRoutes.admonitions(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/admonitions',
            pageBuilder: (context, state) {
              final id = state.pathParameters['portalId'] ?? portalId;
              final Widget child = id == 'francis'
                  ? const FrancisAdmonitionsScreen()
                  : const KempisAdmonitionsScreen();
              return PageTurn.of(key: state.pageKey, child: child);
            },
            routes: [
              GoRoute(
                path: ':chapter',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['portalId'] ?? portalId;
                  final chapter = int.parse(state.pathParameters['chapter']!);
                  final Widget child = id == 'francis'
                      ? FrancisAdmonitionScreen(chapter: chapter)
                      : KempisAdmonitionScreen(chapter: chapter);
                  return PageTurn.of(key: state.pageKey, child: child);
                },
              ),
            ],
          ),
        ],
      );
    case 'stories':
      return StatefulShellBranch(
        initialLocation: PortalRoutes.stories(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/stories',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const Scaffold(
                body: SafeArea(child: FrancisStoriesScreen()),
              ),
            ),
            routes: [
              GoRoute(
                path: ':chapter',
                pageBuilder: (context, state) => PageTurn.of(
                  key: state.pageKey,
                  child: FrancisStoryScreen(
                    chapter: int.parse(state.pathParameters['chapter']!),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    case 'precautions':
      return StatefulShellBranch(
        initialLocation: PortalRoutes.precautions(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/precautions',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const JohnPrecautionsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':chapter',
                pageBuilder: (context, state) => PageTurn.of(
                  key: state.pageKey,
                  child: JohnPrecautionScreen(
                    chapter: int.parse(state.pathParameters['chapter']!),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    case 'discernment':
      return StatefulShellBranch(
        initialLocation: PortalRoutes.discernment(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/discernment',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const IgnatiusDiscernmentScreen(),
            ),
            routes: [
              GoRoute(
                path: ':chapter',
                pageBuilder: (context, state) => PageTurn.of(
                  key: state.pageKey,
                  child: IgnatiusRuleScreen(
                    chapter: int.parse(state.pathParameters['chapter']!),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    case 'exercises':
      return StatefulShellBranch(
        initialLocation: PortalRoutes.exercises(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/exercises',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const Scaffold(
                body: SafeArea(child: IgnatiusExercisesScreen()),
              ),
            ),
          ),
        ],
      );
    case 'today':
    default:
      return StatefulShellBranch(
        initialLocation: PortalRoutes.today(portalId),
        routes: [
          GoRoute(
            path: '/p/:portalId/today',
            pageBuilder: (context, state) => PageTurn.of(
              key: state.pageKey,
              child: const CycleTodayScreen(),
            ),
          ),
        ],
      );
  }
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

  static NavigationDestination _destinationFor(
    String module, [
    String? portalId,
  ]) {
    if (module == 'practice' && portalId == 'liguori') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Visit',
      );
    }
    if (module == 'practice' && portalId == 'francis') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Canticle',
      );
    }
    if (module == 'practice' && portalId == 'augustine') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Evening',
      );
    }
    if (module == 'practice' && portalId == 'teresa-avila') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Recollection',
      );
    }
    if (module == 'practice' && portalId == 'ignatius') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Examen',
      );
    }
    if (module == 'practice' && portalId == 'therese') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Offering',
      );
    }
    if (module == 'practice' && portalId == 'catherine') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Requests',
      );
    }
    if (module == 'practice' && portalId == 'montfort') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Offering',
      );
    }
    if (module == 'practice' && portalId == 'scupoli') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Combat',
      );
    }
    if (module == 'practice' && portalId == 'lawrence') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Presence',
      );
    }
    if (module == 'practice' && portalId == 'cassian') {
      return const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Elder',
      );
    }
    return switch (module) {
      'today' => const NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: 'Today',
      ),
      'meditations' => const NavigationDestination(
        icon: Icon(Icons.self_improvement_outlined),
        selectedIcon: Icon(Icons.self_improvement),
        label: 'Meditations',
      ),
      'practice' => const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Practice',
      ),
      'letters' => const NavigationDestination(
        icon: Icon(Icons.mail_outline),
        selectedIcon: Icon(Icons.mail),
        label: 'Letters',
      ),
      'admonitions' => const NavigationDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt),
        label: 'Admonitions',
      ),
      'stories' => const NavigationDestination(
        icon: Icon(Icons.auto_stories_outlined),
        selectedIcon: Icon(Icons.auto_stories),
        label: 'Stories',
      ),
      'precautions' => const NavigationDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt),
        label: 'Cautions',
      ),
      'discernment' => const NavigationDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt),
        label: 'Rules',
      ),
      'exercises' => const NavigationDestination(
        icon: Icon(Icons.self_improvement_outlined),
        selectedIcon: Icon(Icons.self_improvement),
        label: 'Exercises',
      ),
      _ => const NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: 'Today',
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portalId = ref.watch(currentPortalIdProvider);
    final List<NavigationDestination> destinations;
    if (portalId == 'benedict') {
      destinations = _benedictDestinations;
    } else {
      final modules = PortalRegistry.byId(portalId)?.modules ?? const ['today'];
      destinations = [for (final m in modules) _destinationFor(m, portalId)];
    }

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
