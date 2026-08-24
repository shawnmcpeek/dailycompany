import 'package:dailycompany/app/theme/palette.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showReaderDisplaySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const ReaderDisplaySheet(),
  );
}

/// Libby-style quick controls for page color, size, and weight.
class ReaderDisplaySheet extends ConsumerWidget {
  const ReaderDisplaySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final ink = Theme.of(context).colorScheme.onSurface;
    final rule = Theme.of(context).dividerColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reading display',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ChromeLabel('Page color'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Swatch(
                label: 'Paper',
                fill: Paper.bg,
                border: Paper.rule,
                selected: settings.themeMode == 'paper',
                onTap: () => ctrl.setThemeMode('paper'),
              ),
              _Swatch(
                label: 'Vellum',
                fill: Vellum.bg,
                border: Vellum.rule,
                selected: settings.themeMode == 'vellum',
                onTap: () => ctrl.setThemeMode('vellum'),
              ),
              _Swatch(
                label: 'Compline',
                fill: Compline.bg,
                border: Compline.rule,
                selected: settings.themeMode == 'compline',
                onTap: () => ctrl.setThemeMode('compline'),
              ),
              _Swatch(
                label: 'System',
                fill: rule,
                border: ink.withValues(alpha: 0.35),
                selected: settings.themeMode == 'system',
                onTap: () => ctrl.setThemeMode('system'),
                system: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ChromeLabel('Text size'),
          Row(
            children: [
              const Text('A', style: TextStyle(fontFamily: 'EBGaramond', fontSize: 14)),
              Expanded(
                child: Slider(
                  value: settings.fontScale,
                  min: 0.85,
                  max: 1.45,
                  divisions: 12,
                  onChanged: ctrl.setFontScale,
                ),
              ),
              const Text('A', style: TextStyle(fontFamily: 'EBGaramond', fontSize: 22)),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bold reading text'),
            value: settings.boldReading,
            onChanged: ctrl.setBoldReading,
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.fill,
    required this.border,
    required this.selected,
    required this.onTap,
    this.system = false,
  });

  final String label;
  final Color fill;
  final Color border;
  final bool selected;
  final VoidCallback onTap;
  final bool system;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: system ? null : fill,
              gradient: system
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF3EDE1), Color(0xFF16130F)],
                    )
                  : null,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : border,
                width: selected ? 2.5 : 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}
