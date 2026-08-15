import 'package:benedictdaily/app/brand.dart';
import 'package:benedictdaily/app/theme/palette.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final ink = Theme.of(context).colorScheme.onSurface;
    final rule = Theme.of(context).dividerColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Lectio Divina'),
          subtitle: const Text('Guided timer over today’s reading'),
          onTap: () => context.push('/lectio'),
        ),
        const SectionRule(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('The Medal'),
          subtitle: const Text('Letters, blessing, litany, history'),
          onTap: () => context.push('/medal'),
        ),
        const SectionRule(),
        const SizedBox(height: 20),
        ChromeLabel('Reading display'),
        const SizedBox(height: 14),
        Text(
          'Page color',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ThemeSwatch(
              label: 'Paper',
              fill: Paper.bg,
              border: Paper.rule,
              selected: settings.themeMode == 'paper',
              onTap: () => ctrl.setThemeMode('paper'),
            ),
            const SizedBox(width: 14),
            _ThemeSwatch(
              label: 'Vellum',
              fill: Vellum.bg,
              border: Vellum.rule,
              selected: settings.themeMode == 'vellum',
              onTap: () => ctrl.setThemeMode('vellum'),
            ),
            const SizedBox(width: 14),
            _ThemeSwatch(
              label: 'Compline',
              fill: Compline.bg,
              border: Compline.rule,
              selected: settings.themeMode == 'compline',
              onTap: () => ctrl.setThemeMode('compline'),
              dark: true,
            ),
            const SizedBox(width: 14),
            _ThemeSwatch(
              label: 'System',
              fill: rule,
              border: ink.withValues(alpha: 0.35),
              selected: settings.themeMode == 'system',
              onTap: () => ctrl.setThemeMode('system'),
              system: true,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Text size',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'A',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontFamily: 'EBGaramond',
                  ),
            ),
            Expanded(
              child: Slider(
                value: settings.fontScale,
                min: 0.85,
                max: 1.45,
                divisions: 12,
                label: '${(settings.fontScale * 100).round()}%',
                onChanged: ctrl.setFontScale,
              ),
            ),
            Text(
              'A',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 22,
                    fontFamily: 'EBGaramond',
                  ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Bold reading text'),
          subtitle: const Text('Heavier weight on Rule and offices'),
          value: settings.boldReading,
          onChanged: ctrl.setBoldReading,
        ),
        const SizedBox(height: 8),
        Text(
          'The Rule, written as monks read it — adjust until the page feels quiet.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        ChromeLabel('Settings'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Haptic bells'),
          subtitle: const Text('The signal for the Work of God'),
          value: settings.hapticsEnabled,
          onChanged: ctrl.setHaptics,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ora et Labora mode'),
          subtitle: const Text('Weekday little hours only'),
          value: settings.oraEtLabora,
          onChanged: ctrl.setOraEtLabora,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Prefer Latin side-by-side'),
          value: settings.showLatin,
          onChanged: ctrl.setShowLatin,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Replay welcome'),
          subtitle: const Text('Show the first-launch screens again'),
          onTap: () async {
            await ctrl.resetOnboarding();
            if (context.mounted) context.go('/welcome');
          },
        ),
        const SizedBox(height: 28),
        ChromeLabel('About'),
        const SizedBox(height: 10),
        Text(
          'An independent app from Daddoo Dev. Not affiliated with, endorsed by, '
          'or produced by any Benedictine monastery, abbey, congregation, or '
          'the Order of Saint Benedict.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Sources include Verheyen (Rule), Gardner (Dialogues II), '
          'Douay-Rheims Challoner (Psalter), Delatte/McCann (commentary research), '
          'and traditional medal texts. Doyle (Gutenberg #50040) supplied the date table only.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          Brand.copyrightNotice,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.label,
    required this.fill,
    required this.border,
    required this.selected,
    required this.onTap,
    this.dark = false,
    this.system = false,
  });

  final String label;
  final Color fill;
  final Color border;
  final bool selected;
  final VoidCallback onTap;
  final bool dark;
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
        ),
      ],
    );
  }
}
