import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/models/place_saint.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/iap/paywall.dart';
import 'package:dailycompany/features/serra/california_missions_map.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/continue_reading.dart';
import 'package:dailycompany/shared/widgets/reading_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SerraMissionsScreen extends ConsumerStatefulWidget {
  const SerraMissionsScreen({super.key});

  @override
  ConsumerState<SerraMissionsScreen> createState() =>
      _SerraMissionsScreenState();
}

class _SerraMissionsScreenState extends ConsumerState<SerraMissionsScreen> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(placeSaintProvider);
    final unlocked = ref.watch(cycleUnlockedProvider);
    final portalId = ref.watch(currentPortalIdProvider);

    return async.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (place) {
        final current = place.stopByOrder(_selected) ?? place.stops.first;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text('Missions', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              unlocked
                  ? '${place.stops.length} of ${place.stops.length} along the Camino'
                  : 'Serra’s nine stay free. Lasuén’s nine and the last three unlock.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const ContinueReadingTile(module: 'missions'),
            CaliforniaMissionsMap(
              stops: place.stops,
              unlocked: unlocked,
              selectedOrder: _selected,
              onSelect: (stop) {
                setState(() => _selected = stop.order);
                _open(context, portalId, stop, unlocked);
              },
            ),
            const SizedBox(height: 12),
            ChromeLabel('Founding order'),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous foundation',
                  onPressed: _selected > 1
                      ? () => setState(() => _selected -= 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _open(context, portalId, current, unlocked),
                    child: Column(
                      children: [
                        Text(
                          '${current.order} of ${place.stops.length}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          current.shortName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${current.foundedYear}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next foundation',
                  onPressed: _selected < place.stops.length
                      ? () => setState(() => _selected += 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a pin to read it. Step founding order to see the zigzag up '
              'and down the coast — the faint line is the Camino, south to north.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 24),
            for (final act in [1, 2, 3]) ...[
              ChromeLabel(_actLabel(act)),
              const SizedBox(height: 8),
              for (final s in place.stops.where((e) => e.act == act)) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${s.order} of ${place.stops.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  subtitle: Text(
                    s.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: (!unlocked && !s.free)
                      ? Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        )
                      : const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    setState(() => _selected = s.order);
                    _open(context, portalId, s, unlocked);
                  },
                ),
                const SectionRule(),
              ],
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  String _actLabel(int act) => switch (act) {
        1 => 'Act I · Serra’s nine',
        2 => 'Act II · Lasuén’s nine',
        _ => 'Act III · the last three',
      };

  void _open(
    BuildContext context,
    String portalId,
    PlaceStop stop,
    bool unlocked,
  ) {
    if (!unlocked && !stop.free) {
      openPaywall(context);
      return;
    }
    context.push(PortalRoutes.mission(portalId, stop.order));
  }
}

class SerraMissionScreen extends ConsumerWidget {
  const SerraMissionScreen({super.key, required this.order});

  final int order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(placeSaintProvider);
    final unlocked = ref.watch(cycleUnlockedProvider);

    return async.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (place) {
        final stop = place.stopByOrder(order);
        if (stop == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Mission not found.')),
          );
        }
        if (!unlocked && !stop.free) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: TextButton(
                onPressed: () => openPaywall(context),
                child: const Text('Unlock Companion'),
              ),
            ),
          );
        }
        return ReadingPage(
          title: '${stop.order} of ${place.stops.length}',
          snippet: stop.textEn,
          children: [
            Text(stop.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${stop.foundedYear} · ${stop.foundedBy}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            ReadingBody(text: stop.textEn),
          ],
        );
      },
    );
  }
}
