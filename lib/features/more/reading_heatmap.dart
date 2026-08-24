import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Quiet year calendar of days marked read — no streak guilt chrome.
class ReadingHeatmap extends ConsumerWidget {
  const ReadingHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(completionProvider);
    final showRun = ref.watch(settingsProvider).showReadingRun;
    final now = DateTime.now();
    final year = now.year;
    final gold = Theme.of(context).colorScheme.secondary;
    final rule = Theme.of(context).dividerColor;
    final secondary = Theme.of(context).textTheme.bodySmall?.color;

    final markedThisYear = completed.where((k) => k.startsWith('$year-')).length;
    final present = CompletionController.presentRun(completed, now);
    final longest = CompletionController.longestRun(completed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChromeLabel('Reading calendar'),
        const SizedBox(height: 8),
        Text(
          'Days you marked read. A memory, not a score.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        Text(
          '$year',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 10),
        _YearGrid(
          year: year,
          completed: completed,
          filled: gold,
          empty: rule,
          today: now,
        ),
        const SizedBox(height: 14),
        Text(
          markedThisYear == 0
              ? 'No days marked yet — use Mark read on Today when you finish.'
              : '$markedThisYear day${markedThisYear == 1 ? '' : 's'} marked this year',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (showRun && markedThisYear > 0) ...[
          const SizedBox(height: 6),
          Text(
            present > 0
                ? 'Present run · $present day${present == 1 ? '' : 's'}'
                    '${longest > present ? '  ·  Longest · $longest' : ''}'
                : longest > 0
                    ? 'Longest run · $longest day${longest == 1 ? '' : 's'}'
                    : '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: secondary,
                ),
          ),
        ],
      ],
    );
  }
}

class _YearGrid extends StatelessWidget {
  const _YearGrid({
    required this.year,
    required this.completed,
    required this.filled,
    required this.empty,
    required this.today,
  });

  final int year;
  final Set<String> completed;
  final Color filled;
  final Color empty;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => i + 1);
    return Column(
      children: [
        for (var row = 0; row < 4; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: 10),
                Expanded(
                  child: _MonthCell(
                    year: year,
                    month: months[row * 3 + col],
                    completed: completed,
                    filled: filled,
                    empty: empty,
                    today: today,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.year,
    required this.month,
    required this.completed,
    required this.filled,
    required this.empty,
    required this.today,
  });

  final int year;
  final int month;
  final Set<String> completed;
  final Color filled;
  final Color empty;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 1 … Sunday = 7 → column 0–6 with Monday first.
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon
    final leading = firstWeekday - 1;
    final label = DateFormat('MMM').format(DateTime(year, month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SpecGridDelegate(),
          itemCount: leading + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leading) {
              return const SizedBox.shrink();
            }
            final day = index - leading + 1;
            final date = DateTime(year, month, day);
            final key = CompletionController.keyFor(date);
            final marked = completed.contains(key);
            final isFuture = date.isAfter(today);
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: isFuture
                    ? Colors.transparent
                    : marked
                        ? filled.withValues(alpha: 0.72)
                        : empty.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(1),
                border: isToday
                    ? Border.all(
                        color: filled.withValues(alpha: 0.9),
                        width: 1,
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Compact 7-column day cells for a month strip.
class SpecGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  const SpecGridDelegate()
      : super(
          crossAxisCount: 7,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1,
        );
}
