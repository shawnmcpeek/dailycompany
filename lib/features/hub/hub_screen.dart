import 'package:benedictdaily/app/brand.dart';
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
    final accent = Theme.of(context).colorScheme.primary;
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
        final compline = catalog.officeById('compline');

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
          children: [
            Text(
              Brand.studio.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 28),
            SectionRule(color: accent.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            _HubCard(
              title: 'Today',
              subtitle: todaySubtitle,
              onTap: () => context.go('/today'),
            ),
            _HubCard(
              title: 'Hours',
              subtitle: compline == null
                  ? 'The lay horarium'
                  : 'Compline · ${compline.defaultTime}',
              onTap: () => context.go('/hours'),
            ),
            _HubCard(
              title: 'Life',
              subtitle: 'Gregory · $lifeCount episodes',
              onTap: () => context.go('/life'),
            ),
            _HubCard(
              title: 'Tools',
              subtitle: 'Instrument ${tool.number} of ${catalog.tools.length}',
              onTap: () => context.go('/tools'),
            ),
            _HubCard(
              title: 'More',
              subtitle: 'Lectio, Medal, display, About',
              onTap: () => context.push('/more'),
            ),
          ],
        );
      },
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            const SectionRule(),
          ],
        ),
      ),
    );
  }
}
