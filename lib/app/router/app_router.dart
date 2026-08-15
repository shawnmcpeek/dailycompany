import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/features/hours/hours_screen.dart';
import 'package:benedictdaily/features/hub/hub_screen.dart';
import 'package:benedictdaily/features/lectio/lectio_screen.dart';
import 'package:benedictdaily/features/life/life_screen.dart';
import 'package:benedictdaily/features/medal/medal_screen.dart';
import 'package:benedictdaily/features/more/more_screen.dart';
import 'package:benedictdaily/features/onboarding/welcome_screen.dart';
import 'package:benedictdaily/features/today/today_screen.dart';
import 'package:benedictdaily/features/tools/tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen<AppSettings>(settingsProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
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
        parentNavigatorKey: _rootKey,
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'how',
            builder: (context, state) => const WelcomeHowScreen(),
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
                builder: (context, state) => const HubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hours',
                builder: (context, state) => const HoursScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => OfficeScreen(
                      officeId: state.pathParameters['id']!,
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
                builder: (context, state) => const LifeScreen(),
                routes: [
                  GoRoute(
                    path: ':chapter',
                    builder: (context, state) => LifeEpisodeScreen(
                      chapter: int.parse(state.pathParameters['chapter']!),
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
                builder: (context, state) => const ToolsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/more',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('More')),
          body: const MoreScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/lectio',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Lectio')),
          body: const LectioScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/medal',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('The Medal')),
          body: const MedalScreen(),
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
