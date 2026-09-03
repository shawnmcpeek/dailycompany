import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Spec §3.3 — every entry is reachable. Not a backlog.
class CycleIndexScreen extends ConsumerWidget {
  const CycleIndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portalId = ref.watch(currentPortalIdProvider);
    final calendarAsync = ref.watch(cycleCalendarProvider(portalId));

    return calendarAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (calendar) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
          itemCount: calendar.entries.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Any reading, any day. The calendar is the usual path, '
                  'not a gate.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            final entry = calendar.entries[i - 1];
            final subtitle = calendar.indexSubtitle(entry);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.chapterTitle),
              subtitle: Text(subtitle),
              onTap: () => _open(context, ref, calendar, entry),
            );
          },
        );
      },
    );
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    CycleCalendar calendar,
    CycleEntry entry,
  ) {
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    if (settings.readThroughFor(calendar.portalId)) {
      notifier.setReadThroughCursor(calendar.portalId, entry.id);
    } else {
      final now = DateTime.now();
      final date = calendar.dateForEntry(entry.id, now.year) ??
          calendar.dateForEntry(entry.id, now.year - 1);
      if (date != null) {
        ref.read(selectedDayProvider.notifier).state = date;
      } else {
        notifier.setReadThrough(calendar.portalId, true);
        notifier.setReadThroughCursor(calendar.portalId, entry.id);
      }
    }
    context.pop();
  }
}
