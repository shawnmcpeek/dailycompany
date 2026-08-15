import 'package:benedictdaily/core/haptics/bell_haptics.dart';
import 'package:benedictdaily/data/content_catalog.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HoursScreen extends ConsumerWidget {
  const HoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    final settings = ref.watch(settingsProvider);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        var offices = catalog.offices;
        if (settings.oraEtLabora) {
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
              settings.oraEtLabora
                  ? 'Ora et Labora — the little hours only.'
                  : 'A lay-scaled horarium. Compline is the anchor.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(catalog.psalterNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            for (final office in offices) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  office.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${office.defaultTime} · ${office.psalmNumbers.map((n) => 'Ps $n').join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => context.push('/hours/${office.id}'),
              ),
              const SectionRule(),
            ],
          ],
        );
      },
    );
  }
}

class OfficeScreen extends ConsumerWidget {
  const OfficeScreen({super.key, required this.officeId});

  final String officeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          appBar: AppBar(title: Text(office.label)),
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
                  if (officeId == 'compline' && settings.oraEtLabora == false) {
                    // closing bell
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
