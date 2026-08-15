import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(contentCatalogProvider);
    final day = ref.watch(selectedDayProvider);

    return catalogAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (catalog) {
        final today = catalog.toolForDay(day);
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text(
              'Tools of Good Works',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Rule of St. Benedict, chapter 4 · instrument ${today.number} of ${catalog.tools.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 36),
            Text(
              '№ ${today.number}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 12),
            Text(
              today.text,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () async {
                final share =
                    'Tool ${today.number} of Good Works\n\n${today.text}\n\n— Benedict Daily';
                await Clipboard.setData(ClipboardData(text: share));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied — ready to share.'),
                    ),
                  );
                }
              },
              child: const Text('Copy card'),
            ),
            const SizedBox(height: 36),
            ChromeLabel('All 72'),
            const SizedBox(height: 12),
            for (final tool in catalog.tools)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${tool.number}.  ${tool.text}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tool.number == today.number
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }
}
