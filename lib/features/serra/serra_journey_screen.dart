import 'package:dailycompany/core/liturgical/liturgical_color.dart';
import 'package:dailycompany/data/models/portal.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/cycle_provenance.dart';
import 'package:dailycompany/shared/widgets/drop_cap_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SerraJourneyScreen extends ConsumerWidget {
  const SerraJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(placeSaintProvider);
    final day = ref.watch(selectedDayProvider);
    final portal = PortalRegistry.byId('serra')!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final litColor = LiturgicalColorResolver.forDay(day);
    final dateLabel = DateFormat('EEEE, MMMM d').format(day);

    return async.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (place) {
        final active = place.journey.isActiveOn(day);
        final leg = place.journey.resolveFor(day);
        final title = active ? (leg?.location ?? '') : place.journey.quiet.title;
        final body = active
            ? (leg?.textEn ?? place.journey.quiet.textEn)
            : place.journey.quiet.textEn;
        final first = body.trim();
        final restSplit = first.indexOf('\n\n');
        final lead = restSplit > 0 ? first.substring(0, restSplit) : first;
        final rest = restSplit > 0 ? first.substring(restSplit).trim() : '';
        final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text('Journey', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            CycleProvenanceLine(
              label: active ? title : place.journey.quiet.location,
              style: Theme.of(context).textTheme.bodySmall,
              sheetTitle: portal.provenanceTitle,
              sheetParagraphs: portal.provenanceParagraphs,
            ),
            const SizedBox(height: 8),
            Text(
              active ? title : place.journey.quiet.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            const SectionRule(),
            const SizedBox(height: 24),
            DropCapText(
              text: lead,
              color: litColor,
              style: bodyStyle,
              animate: !reduceMotion && active,
            ),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 14),
              ReadingBody(text: rest),
            ],
          ],
        );
      },
    );
  }
}
