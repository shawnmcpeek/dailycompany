import 'package:dailycompany/core/haptics/bell_haptics.dart';
import 'package:dailycompany/data/content_catalog.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/medal/medal_diagram.dart';
import 'package:dailycompany/features/medal/medal_hotspots.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MedalScreen extends ConsumerStatefulWidget {
  const MedalScreen({super.key});

  @override
  ConsumerState<MedalScreen> createState() => _MedalScreenState();
}

class _MedalScreenState extends ConsumerState<MedalScreen> {
  MedalFace _face = MedalFace.reverse;
  String? _selectedId;

  void _select(String id) {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      BellHaptics.play(BellKind.lectioTick);
    }
    setState(() => _selectedId = id);
  }

  void _setFace(MedalFace face) {
    if (face == _face) return;
    setState(() {
      _face = face;
      _selectedId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(contentCatalogProvider);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final medal = catalog.medal;
        final faceKey = _face == MedalFace.reverse ? 'reverse' : 'obverse';
        final regions = medal.regionsFor(faceKey);
        final selected = _selectedId == null
            ? null
            : medal.regionById(_selectedId!);

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text(
              'The Medal',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _face == MedalFace.reverse ? 'Tap a letter.' : 'Tap a figure.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _FaceButton(
                  label: 'Obverse',
                  selected: _face == MedalFace.obverse,
                  onPressed: () => _setFace(MedalFace.obverse),
                ),
                const SizedBox(width: 8),
                _FaceButton(
                  label: 'Reverse',
                  selected: _face == MedalFace.reverse,
                  onPressed: () => _setFace(MedalFace.reverse),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MedalDiagram(
              face: _face,
              selectedId: _selectedId,
              onSelect: _select,
            ),
            if (selected != null) ...[
              const SizedBox(height: 24),
              ChromeLabel(selected.label),
              const SizedBox(height: 8),
              Text(
                selected.expansion,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                selected.meaning,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 28),
            ChromeLabel(_face == MedalFace.reverse ? 'Letters' : 'Figures'),
            const SizedBox(height: 12),
            for (final region in regions)
              _LegendRow(
                region: region,
                selected: region.id == _selectedId,
                onTap: () => _select(region.id),
              ),
            const SizedBox(height: 20),
            ChromeLabel('Blessing of the Medal'),
            const SizedBox(height: 10),
            Text(
              medal.blessingNote,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              medal.blessingEnglish,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              medal.blessingLatin,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 28),
            ChromeLabel('Litany of St. Benedict'),
            const SizedBox(height: 12),
            for (final line in medal.litany)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge,
                    children: [
                      TextSpan(text: '${line.invocation}  '),
                      TextSpan(
                        text: line.response,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 28),
            ChromeLabel('History'),
            const SizedBox(height: 10),
            ReadingBody(text: medal.history),
          ],
        );
      },
    );
  }
}

class _FaceButton extends StatelessWidget {
  const _FaceButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Text(label);
    return Expanded(
      child: selected
          ? FilledButton(onPressed: onPressed, child: child)
          : OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.region,
    required this.selected,
    required this.onTap,
  });

  final MedalRegion region;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              region.label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 6),
            Text(
              region.expansion,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(region.meaning, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            const SectionRule(),
          ],
        ),
      ),
    );
  }
}
