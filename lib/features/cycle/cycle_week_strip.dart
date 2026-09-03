import 'package:dailycompany/core/cycle/cycle_calendar.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Spec §3.2 — last week as a shelf, never a ledger.
class CycleWeekStrip extends ConsumerWidget {
  const CycleWeekStrip({
    super.key,
    required this.calendar,
  });

  final CycleCalendar calendar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDayProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final entries = calendar.resolveFor(day);
          final title = entries.isEmpty
              ? ''
              : entries.first.chapterTitle;
          final isSelected = day.year == selected.year &&
              day.month == selected.month &&
              day.day == selected.day;
          return InkWell(
            onTap: () => ref.read(selectedDayProvider.notifier).state = day,
            child: SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE d').format(day),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected ? ink : muted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? ink : muted,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
