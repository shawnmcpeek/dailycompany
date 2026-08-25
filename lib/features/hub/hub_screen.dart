import 'package:dailycompany/app/brand.dart';
import 'package:dailycompany/core/cycle/life_track.dart';
import 'package:dailycompany/core/cycle/reading_calendar.dart';
import 'package:dailycompany/data/content_catalog.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/instrument_reading.dart';
import 'package:dailycompany/shared/widgets/medal_mark.dart';
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
        final todaySubtitle = _todaySubtitle(
          catalog: catalog,
          day: day,
          settings: settings,
          ruleReadings: readings,
        );
        final tool = catalog.toolForDay(day);
        final lifeCount = catalog.life.where((e) => e.chapter > 0).length;

        return ListView(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
          children: [
            Row(
              children: [
                SizedBox(
                  width: kMinInteractiveDimension,
                  height: kMinInteractiveDimension,
                  child: Tooltip(
                    message: 'The hallway',
                    child: GestureDetector(
                      onTap: () => context.go('/hallway'),
                      child: Center(
                        child: ExcludeSemantics(
                          child: Image.asset(
                            'assets/branding/app_logo.png',
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    Brand.appName,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: kMinInteractiveDimension,
                  height: kMinInteractiveDimension,
                  child: MedalMark(
                    asset: catalog.medalReverseAsset,
                    invite: !settings.medalOpened,
                    onTap: () {
                      ref.read(settingsProvider.notifier).markMedalOpened();
                      context.push('/medal');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The Rule, read as monks read it.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
            Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 28),
            InstrumentReading(tool: tool, total: catalog.tools.length),
            const SizedBox(height: 32),
            Text('Go to', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 12),
            HubNavButton(
              title: 'The hallway',
              subtitle: 'Choose whose house you keep',
              actionLabel: 'Leave',
              onPressed: () => context.go('/hallway'),
            ),
            const SizedBox(height: 10),
            HubNavButton(
              title: "Today's Rule",
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
              subtitle: 'All 72 instruments',
              onPressed: () => context.go('/tools'),
            ),
            const SizedBox(height: 10),
            HubNavButton(
              title: 'More',
              subtitle: 'Lectio, display, Sources',
              onPressed: () => context.push('/more'),
            ),
          ],
        );
      },
    );
  }
}

String _todaySubtitle({
  required ContentCatalog catalog,
  required DateTime day,
  required AppSettings settings,
  required List<RuleReading> ruleReadings,
}) {
  final track = settings.dailyTrack;
  String? lifeLine;
  if (track.includesLife && catalog.life.isNotEmpty) {
    final ep = LifeTrack.episodeFor(
      episodes: catalog.life,
      day: day,
      start: settings.lifeStart,
    );
    final numbered = catalog.life.where((e) => e.chapter > 0).length;
    lifeLine = 'Life · ${LifeTrack.headline(ep, numbered: numbered)}';
  }
  String? ruleLine;
  if (track.includesRule) {
    ruleLine = ruleReadings.isEmpty
        ? catalog.calendar.cycleLabel(day)
        : catalog.calendar.readingHeadline(ruleReadings.first);
  }
  if (lifeLine != null && ruleLine != null) return '$lifeLine · Rule';
  return lifeLine ?? ruleLine ?? 'Today’s reading';
}
