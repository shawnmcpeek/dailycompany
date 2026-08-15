import 'package:benedictdaily/core/haptics/bell_haptics.dart';
import 'package:benedictdaily/core/iap/iap_controller.dart';
import 'package:benedictdaily/core/liturgical/liturgical_color.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/features/iap/oblate_paywall_screen.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:benedictdaily/shared/widgets/drop_cap_text.dart';
import 'package:benedictdaily/shared/widgets/reader_display_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    final day = ref.watch(selectedDayProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final readings = catalog.calendar.resolveFor(day);
        if (readings.isEmpty) {
          return const Center(child: Text('No reading for this day.'));
        }
        final accent = catalog.calendar.accentFor(day);
        final litColor = LiturgicalColorResolver.forDay(day);
        final dateLabel = DateFormat('EEEE, MMMM d').format(day);

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
            Text(dateLabel, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            Text(
              catalog.calendar.cycleLabel(day),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: accent,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              catalog.calendar.readingHeadline(readings.first),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (readings.length > 1) ...[
              const SizedBox(height: 4),
              Text(
                '+ ${readings.length - 1} more portion${readings.length > 2 ? 's' : ''} today',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 20),
            SectionRule(color: accent.withValues(alpha: 0.45)),
            const SizedBox(height: 24),
            for (var i = 0; i < readings.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: 12),
                SectionRule(color: accent.withValues(alpha: 0.35)),
                const SizedBox(height: 24),
                Text(
                  catalog.calendar.readingHeadline(readings[i]),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
              ],
              _ReadingBlock(
                text: readings[i].textEn,
                commentary: readings[i].commentary,
                latin: readings[i].textLa,
                litColor: litColor,
                animate: i == 0 && !reduceMotion,
                readingId: readings[i].id,
              ),
            ],
          ],
          ),
        );
      },
    );
  }
}

class _ReadingBlock extends ConsumerStatefulWidget {
  const _ReadingBlock({
    required this.text,
    required this.litColor,
    required this.animate,
    required this.readingId,
    this.latin,
    this.commentary,
  });

  final String text;
  final String? latin;
  final String? commentary;
  final Color litColor;
  final bool animate;
  final int readingId;

  @override
  ConsumerState<_ReadingBlock> createState() => _ReadingBlockState();
}

class _ReadingBlockState extends ConsumerState<_ReadingBlock> {
  bool _showLatin = false;
  bool _showCommentary = false;
  bool? _doAnimate;

  @override
  void initState() {
    super.initState();
    final unlocked = ref.read(oblateUnlockedProvider);
    _showLatin = unlocked && ref.read(settingsProvider).showLatin;
    if (!widget.animate) {
      _doAnimate = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prepareAnimation();
      });
    }
  }

  Future<void> _prepareAnimation() async {
    final day = ref.read(selectedDayProvider);
    final should =
        await ref.read(illuminatedDateProvider.notifier).shouldIlluminate(day);
    if (mounted) setState(() => _doAnimate = should);
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;
    final animate = _doAnimate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (animate == null)
          ReadingBody(text: widget.text, style: bodyStyle)
        else
          DropCapText(
            text: widget.text.replaceAll(RegExp(r'\n\s*\n'), '\n\n'),
            color: widget.litColor,
            style: bodyStyle,
            animate: animate,
          ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Commentary'),
              onPressed: () => setState(() => _showCommentary = !_showCommentary),
            ),
            ActionChip(
              label: Text(_showLatin ? 'Hide Latin' : 'Latin'),
              onPressed: () {
                final unlocked = ref.read(oblateUnlockedProvider);
                if (!unlocked) {
                  openOblatePaywall(context);
                  return;
                }
                setState(() => _showLatin = !_showLatin);
              },
            ),
            ActionChip(
              label: const Text('Lectio'),
              onPressed: () => context.push('/lectio'),
            ),
            ActionChip(
              label: const Text('Mark read'),
              onPressed: () async {
                final day = ref.read(selectedDayProvider);
                await ref.read(completionProvider.notifier).markRead(
                      day,
                      readingId: widget.readingId,
                    );
                if (ref.read(settingsProvider).hapticsEnabled) {
                  await BellHaptics.play(BellKind.complete);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reading acknowledged.')),
                  );
                }
              },
            ),
          ],
        ),
        if (_showCommentary) ...[
          const SizedBox(height: 16),
          Text(
            widget.commentary?.trim().isNotEmpty == true
                ? widget.commentary!
                : 'Commentary for this portion is not available yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
        if (_showLatin && widget.latin?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 20),
          ChromeLabel('Latin'),
          const SizedBox(height: 8),
          ReadingBody(text: widget.latin!),
        ],
      ],
    );
  }
}
