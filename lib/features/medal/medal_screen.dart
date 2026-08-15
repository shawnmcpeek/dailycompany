import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MedalScreen extends ConsumerWidget {
  const MedalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final medal = catalog.medal;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text('The Medal', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Tap a legend below. Interactive medal art comes later.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            for (final region in medal.regions) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  region.label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        region.expansion,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        region.meaning,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SectionRule(),
            ],
            const SizedBox(height: 20),
            ChromeLabel('Blessing of the Medal'),
            const SizedBox(height: 10),
            Text(
              medal.blessingNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(medal.blessingEnglish, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            Text(
              medal.blessingLatin,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
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
