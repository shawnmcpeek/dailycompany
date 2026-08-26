import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/core/haptics/bell_haptics.dart';
import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/data/content_catalog.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/iap/paywall.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HoursScreen extends ConsumerWidget {
  const HoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final unlocked = ref.watch(oblateUnlockedProvider);
    final portalId = ref.watch(currentPortalIdProvider);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        var offices = catalog.offices;
        if (!unlocked) {
          offices = offices.where((o) => o.id == 'compline').toList();
        } else if (settings.oraEtLabora) {
          offices = offices
              .where((o) => {'terce', 'sext', 'none'}.contains(o.id))
              .toList();
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text('The Hours', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              !unlocked
                  ? 'Compline is free. The full horarium unlocks with Oblate.'
                  : settings.oraEtLabora
                      ? 'Ora et Labora — the little hours only.'
                      : 'A lay-scaled horarium. Compline is the anchor.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!unlocked) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => openPaywall(context),
                child: const Text('Unlock full Hours · Oblate'),
              ),
            ],
            const SizedBox(height: 12),
            Text(catalog.psalterNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bell notifications'),
              subtitle: Text(
                unlocked
                    ? 'Daily signal at each office time. Tap the clock to change.'
                    : 'Compline bell only until Oblate is unlocked.',
              ),
              value: settings.bellsEnabled,
              onChanged: ctrl.setBellsEnabled,
            ),
            const SizedBox(height: 8),
            for (final office in offices) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  office.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${settings.timeForOffice(office.id)} · ${office.psalmNumbers.map((n) => 'Ps $n').join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Set time',
                      icon: const Icon(Icons.schedule, size: 20),
                      onPressed: () => _pickTime(context, ref, office.id),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: () =>
                    context.push(PortalRoutes.office(portalId, office.id)),
              ),
              const SectionRule(),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    String officeId,
  ) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.timeForOffice(officeId).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 12,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setOfficeTime(
          officeId,
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }
}

class OfficeScreen extends ConsumerWidget {
  const OfficeScreen({super.key, required this.officeId});

  final String officeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(oblateUnlockedProvider);
    if (!unlocked && officeId != 'compline') {
      return Scaffold(
        appBar: AppBar(title: const Text('Hours')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This office is part of Oblate.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Compline remains free. Unlock the full horarium when you are ready.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => openPaywall(context),
                child: const Text('Unlock Oblate'),
              ),
            ],
          ),
        ),
      );
    }

    final catalogAsync = ref.watch(contentCatalogProvider);
    final settings = ref.watch(settingsProvider);

    return catalogAsync.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (catalog) {
        final office = catalog.officeById(officeId);
        if (office == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Office')),
            body: const Center(child: Text('Unknown office.')),
          );
        }
        final psalms = [
          for (final n in office.psalmNumbers)
            if (catalog.psalms[n] != null) catalog.psalms[n]!,
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(office.label),
            actions: [
              TextButton(
                onPressed: () => _pickTime(context, ref, officeId),
                child: Text(settings.timeForOffice(officeId)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            children: [
              _LineBlock(line: office.opening),
              _LineBlock(line: office.response),
              const SizedBox(height: 8),
              _LineBlock(line: office.gloryBe),
              const SizedBox(height: 20),
              for (final psalm in psalms) ...[
                ChromeLabel('Psalm ${psalm.number} · ${psalm.title}'),
                const SizedBox(height: 10),
                for (final v in psalm.verses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${v.n}.  ${v.text}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                const SizedBox(height: 8),
                _LineBlock(line: office.gloryBe),
                const SizedBox(height: 16),
              ],
              _LineBlock(line: office.closing),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () async {
                  if (settings.hapticsEnabled) {
                    await BellHaptics.play(_bellFor(office.haptic));
                  }
                  if (context.mounted) {
                    if (settings.oraEtLabora &&
                        {'terce', 'sext', 'none'}.contains(officeId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Return to your work.'),
                        ),
                      );
                    }
                    context.pop();
                  }
                },
                child: Text(
                  settings.oraEtLabora &&
                          {'terce', 'sext', 'none'}.contains(officeId)
                      ? 'Return to work'
                      : 'Amen',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    String officeId,
  ) async {
    final settings = ref.read(settingsProvider);
    final raw = settings.timeForOffice(officeId).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 12,
      minute: int.tryParse(raw.length > 1 ? raw[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setOfficeTime(
          officeId,
          TimeOfDayCompat(hour: picked.hour, minute: picked.minute),
        );
  }

  BellKind _bellFor(String haptic) {
    return switch (haptic) {
      'compline' => BellKind.compline,
      'major' => BellKind.major,
      _ => BellKind.little,
    };
  }
}

class _LineBlock extends StatelessWidget {
  const _LineBlock({required this.line});

  final OfficeLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(line.english, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 2),
          Text(
            line.latin,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'EBGaramond',
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }
}
