import 'package:benedictdaily/core/cycle/life_track.dart';
import 'package:benedictdaily/core/haptics/bell_haptics.dart';
import 'package:benedictdaily/core/iap/iap_controller.dart';
import 'package:benedictdaily/core/liturgical/liturgical_color.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/features/iap/oblate_paywall_screen.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:benedictdaily/shared/widgets/daily_track_toggle.dart';
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
    final settings = ref.watch(settingsProvider);
    final unlocked = ref.watch(oblateUnlockedProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final track = settings.dailyTrack;
        final ruleReadings = catalog.calendar.resolveFor(day);
        final life = track.includesLife && catalog.life.isNotEmpty
            ? LifeTrack.episodeFor(
                episodes: catalog.life,
                day: day,
                start: settings.lifeStart,
              )
            : null;
        final numberedLife = catalog.life.where((e) => e.chapter > 0).length;
        final lifeLocked = life != null &&
            !unlocked &&
            !IapController.lifeChapterFree(life.chapter);
        final showRule = track.includesRule;
        final accent = catalog.calendar.accentFor(day);
        final litColor = LiturgicalColorResolver.forDay(day);
        final dateLabel = DateFormat('EEEE, MMMM d').format(day);

        if (track.includesRule && ruleReadings.isEmpty && life == null) {
          return const Center(child: Text('No reading for this day.'));
        }

        var animateIndex = 0;
        if (life != null && lifeLocked && showRule) {
          animateIndex = 1;
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
              Text(dateLabel, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 12),
              DailyTrackToggle(
                value: track,
                onChanged: ref.read(settingsProvider.notifier).setDailyTrack,
              ),
              const SizedBox(height: 16),
              if (life != null) ...[
                Text(
                  LifeTrack.cycleLabel(
                    episodes: catalog.life,
                    day: day,
                    start: settings.lifeStart,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${LifeTrack.headline(life, numbered: numberedLife)} · ${life.title}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                SectionRule(color: accent.withValues(alpha: 0.45)),
                const SizedBox(height: 24),
                if (lifeLocked)
                  const _LifeLockedBlock()
                else
                  _ReadingBlock(
                    text: life.textEn,
                    litColor: litColor,
                    animate: animateIndex == 0 && !reduceMotion,
                    readingId: LifeTrack.journalId(life.chapter),
                  ),
              ],
              if (showRule) ...[
                if (life != null) ...[
                  const SizedBox(height: 36),
                  ChromeLabel('The Rule'),
                  const SizedBox(height: 12),
                ],
                if (ruleReadings.isEmpty)
                  Text(
                    'No Rule reading for this day.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...[
                  Text(
                    catalog.calendar.cycleLabel(day),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accent,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    catalog.calendar.readingHeadline(ruleReadings.first),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (ruleReadings.length > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+ ${ruleReadings.length - 1} more portion${ruleReadings.length > 2 ? 's' : ''} today',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SectionRule(color: accent.withValues(alpha: 0.45)),
                  const SizedBox(height: 24),
                  for (var i = 0; i < ruleReadings.length; i++) ...[
                    if (i > 0) ...[
                      const SizedBox(height: 12),
                      SectionRule(color: accent.withValues(alpha: 0.35)),
                      const SizedBox(height: 24),
                      Text(
                        catalog.calendar.readingHeadline(ruleReadings[i]),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _ReadingBlock(
                      text: ruleReadings[i].textEn,
                      commentary: ruleReadings[i].commentary,
                      latin: ruleReadings[i].textLa,
                      litColor: litColor,
                      animate: i == 0 &&
                          animateIndex == (life == null ? 0 : 1) &&
                          !reduceMotion,
                      readingId: ruleReadings[i].id,
                    ),
                  ],
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LifeLockedBlock extends StatelessWidget {
  const _LifeLockedBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'The rest of Benedict’s life unlocks with Oblate.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Today’s episode is waiting. A one-time unlock opens the whole book.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => openOblatePaywall(context),
          child: const Text('Unlock Oblate'),
        ),
      ],
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

  bool get _hasLatin => widget.latin?.trim().isNotEmpty == true;
  bool get _hasCommentary => widget.commentary != null;

  @override
  void initState() {
    super.initState();
    final unlocked = ref.read(oblateUnlockedProvider);
    _showLatin = unlocked && ref.read(settingsProvider).showLatin && _hasLatin;
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
    final paragraphs = widget.text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final first = paragraphs.isEmpty ? '' : paragraphs.first;
    final rest = paragraphs.skip(1).join('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (animate == null)
          ReadingBody(text: widget.text, style: bodyStyle)
        else ...[
          DropCapText(
            text: first,
            color: widget.litColor,
            style: bodyStyle,
            animate: animate,
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 14),
            ReadingBody(text: rest, style: bodyStyle),
          ],
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_hasCommentary)
              ActionChip(
                label: const Text('Commentary'),
                onPressed: () =>
                    setState(() => _showCommentary = !_showCommentary),
              ),
            if (_hasLatin)
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
        if (_showLatin && _hasLatin) ...[
          const SizedBox(height: 20),
          ChromeLabel('Latin'),
          const SizedBox(height: 8),
          ReadingBody(text: widget.latin!),
        ],
      ],
    );
  }
}
