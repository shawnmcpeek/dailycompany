import 'package:dailycompany/app/theme/palette.dart';
import 'package:dailycompany/core/cycle/desales_calendar.dart';
import 'package:dailycompany/core/haptics/bell_haptics.dart';
import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/data/isar/bouquet.dart';
import 'package:dailycompany/data/models/portal.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/desales/desales_reading_body.dart';
import 'package:dailycompany/features/iap/paywall.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/cycle_provenance.dart';
import 'package:dailycompany/shared/widgets/drop_cap_text.dart';
import 'package:dailycompany/shared/widgets/reader_display_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _romanNumerals = ['', 'I', 'II', 'III', 'IV', 'V'];
String _roman(int part) => _romanNumerals[part.clamp(0, 5)];

const _chapterCounts = {1: 24, 2: 21, 3: 41, 4: 15, 5: 18};
int _chapterCountForPart(int part) => _chapterCounts[part] ?? 0;

class DesalesTodayScreen extends ConsumerWidget {
  const DesalesTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(desalesCalendarProvider);
    final day = ref.watch(selectedDayProvider);
    final unlocked = ref.watch(desalesCompanionUnlockedProvider);
    final settings = ref.watch(settingsProvider);
    final readThrough = unlocked && settings.desalesReadThrough;
    final portal = PortalRegistry.byId('desales')!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final dateLabel = DateFormat('EEEE, MMMM d').format(day);

    return calendarAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (calendar) {
        final cursor = settings.desalesReadThroughCursor.clamp(
          1,
          calendar.entries.length,
        );
        final entries = readThrough
            ? [
                calendar.byId(cursor) ?? calendar.entries.first,
              ]
            : calendar.resolveFor(day);
        if (entries.isEmpty) {
          return const Center(child: Text('No reading for this day.'));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Today'),
            actions: [
              IconButton(
                tooltip: 'Reading display',
                onPressed: () => showReaderDisplaySheet(context),
                icon: const Text(
                  'Aa',
                  style: TextStyle(
                    fontFamily: 'EBGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            children: [
              Text(
                readThrough ? 'Read Through' : dateLabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 16),
              if (!readThrough) _BouquetPin(day: day),
              if (!unlocked)
                const _LockedBlock()
              else ...[
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 12),
                    SectionRule(
                      color: DesalesAccent.forPart(entries[i].part)
                          .withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _EntryBlock(
                    entry: entries[i],
                    portal: portal,
                    day: day,
                    animate: i == 0 && !reduceMotion && !readThrough,
                    readThrough: readThrough,
                  ),
                ],
                const SizedBox(height: 24),
                if (readThrough)
                  _ReadThroughNav(
                    cursor: cursor,
                    total: calendar.entries.length,
                  ),
                const SizedBox(height: 12),
                _ReadThroughToggle(readThrough: readThrough),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReadThroughToggle extends ConsumerWidget {
  const _ReadThroughToggle({required this.readThrough});

  final bool readThrough;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref
          .read(settingsProvider.notifier)
          .setDesalesReadThrough(!readThrough),
      child: Text(
        readThrough
            ? 'Reading straight through · switch to the calendar'
            : 'Reading by calendar · switch to Read Through',
        style: muted,
      ),
    );
  }
}

class _ReadThroughNav extends ConsumerWidget {
  const _ReadThroughNav({required this.cursor, required this.total});

  final int cursor;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void go(int next) => ref
        .read(settingsProvider.notifier)
        .setDesalesReadThroughCursor(next.clamp(1, total));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          onPressed: cursor > 1 ? () => go(cursor - 1) : null,
          child: const Text('Previous'),
        ),
        Text(
          '$cursor of $total',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        OutlinedButton(
          onPressed: cursor < total ? () => go(cursor + 1) : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _LockedBlock extends StatelessWidget {
  const _LockedBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'The year-long cycle unlocks with Companion.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Today’s reading is waiting. The Meditations and Practice stay free.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => openPaywall(context),
          child: const Text('Unlock Companion'),
        ),
      ],
    );
  }
}

class _BouquetPin extends ConsumerWidget {
  const _BouquetPin({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bouquets = ref.watch(bouquetProvider);
    Bouquet? kept;
    for (final b in bouquets) {
      if (b.dateKey == BouquetController.keyFor(day) &&
          b.createdAt.year == day.year &&
          b.createdAt.month == day.month &&
          b.createdAt.day == day.day) {
        kept = b;
        break;
      }
    }
    if (kept == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromeLabel('Your bouquet'),
          const SizedBox(height: 8),
          Text(
            kept.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

class _EntryBlock extends ConsumerStatefulWidget {
  const _EntryBlock({
    required this.entry,
    required this.portal,
    required this.day,
    required this.animate,
    required this.readThrough,
  });

  final DesalesEntry entry;
  final SaintPortal portal;
  final DateTime day;
  final bool animate;
  final bool readThrough;

  @override
  ConsumerState<_EntryBlock> createState() => _EntryBlockState();
}

class _EntryBlockState extends ConsumerState<_EntryBlock> {
  bool? _doAnimate;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _doAnimate = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prepareAnimation();
      });
    }
  }

  Future<void> _prepareAnimation() async {
    final should = await ref
        .read(illuminatedDateProvider.notifier)
        .shouldIlluminate(widget.day);
    if (mounted) setState(() => _doAnimate = should);
  }

  void _keep(String text) {
    ref.read(bouquetProvider.notifier).keep(widget.day, text);
    if (ref.read(settingsProvider).hapticsEnabled) {
      BellHaptics.play(BellKind.lectioTick);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kept for your bouquet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final accent = DesalesAccent.forPart(entry.part);
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;
    final animate = _doAnimate;

    final paragraphs = entry.textEn
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final first = paragraphs.isEmpty ? '' : paragraphs.first;
    final rest = paragraphs.skip(1).join('\n\n');

    final portion = entry.portionsInChapter > 1
        ? ' · reading ${entry.portionInChapter} of ${entry.portionsInChapter}'
        : '';
    final partChapter = 'Part ${_roman(entry.part)} · Chapter ${entry.chapter} '
        'of ${_chapterCountForPart(entry.part)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CycleProvenanceLine(
          label: widget.readThrough ? partChapter : 'Day ${entry.id} of 366',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: accent,
              ),
          sheetTitle: widget.portal.provenanceTitle,
          sheetParagraphs: widget.portal.provenanceParagraphs,
        ),
        const SizedBox(height: 8),
        Text(
          widget.readThrough
              ? '${entry.chapterTitle}$portion'
              : '$partChapter · ${entry.chapterTitle}$portion',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        SectionRule(color: accent.withValues(alpha: 0.45)),
        const SizedBox(height: 24),
        if (animate == null)
          BouquetReadingBody(text: entry.textEn, onKeep: _keep, style: bodyStyle)
        else ...[
          DropCapText(
            text: first,
            color: accent,
            style: bodyStyle,
            animate: animate,
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 14),
            BouquetReadingBody(text: rest, onKeep: _keep, style: bodyStyle),
          ],
        ],
      ],
    );
  }
}
