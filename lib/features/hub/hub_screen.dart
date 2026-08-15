import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    final day = ref.watch(selectedDayProvider);
    final settings = ref.watch(settingsProvider);
    final dateLabel = DateFormat('EEEE, MMMM d').format(day);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final readings = catalog.calendar.resolveFor(day);
        final todaySubtitle = readings.isEmpty
            ? catalog.calendar.cycleLabel(day)
            : '${catalog.calendar.cycleLabel(day)} · ${catalog.calendar.readingHeadline(readings.first)}';
        final tool = catalog.toolForDay(day);
        final lifeCount = catalog.life.where((e) => e.chapter > 0).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
          children: [
            Text(
              'Benedict Daily',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 34,
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The Rule, read as monks read it.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 6),
            Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            Text(
              'Go to',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 12),
            HubNavButton(
              title: 'Today',
              subtitle: todaySubtitle,
              onPressed: () => context.go('/today'),
            ),
            const SizedBox(height: 10),
            HubNavButton(
              title: 'Hours',
              subtitle: settings.oraEtLabora
                  ? 'Ora et Labora · Terce ${settings.timeForOffice('terce')}'
                  : 'Compline · ${settings.timeForOffice('compline')}',
              onPressed: () => context.go('/hours'),
            ),
            const SizedBox(height: 10),
            HubNavButton(
              title: 'Life',
              subtitle: 'Gregory · $lifeCount episodes',
              onPressed: () => context.go('/life'),
            ),
            const SizedBox(height: 10),
            HubNavButton(
              title: 'Tools',
              subtitle: 'Instrument ${tool.number} of ${catalog.tools.length}',
              onPressed: () => context.go('/tools'),
            ),
            const SizedBox(height: 10),
            HubNavButton(
              title: 'More',
              subtitle: 'Lectio, Medal, display, Sources',
              onPressed: () => context.push('/more'),
            ),
          ],
        );
      },
    );
  }
}
