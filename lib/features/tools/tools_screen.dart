import 'package:benedictdaily/data/providers.dart';
import 'package:benedictdaily/features/tools/tool_share.dart';
import 'package:benedictdaily/shared/widgets/common.dart';
import 'package:benedictdaily/shared/widgets/instrument_reading.dart';
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
              'Rule of St. Benedict, chapter 4',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 36),
            InstrumentReading(
              tool: today,
              total: catalog.tools.length,
              showLabel: false,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => ToolShare.showAndShare(
                context,
                tool: today,
                total: catalog.tools.length,
              ),
              child: const Text('Share image'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () async {
                final share = [
                  'Tool ${today.number} of Good Works',
                  '',
                  today.text,
                  if (today.hasScripture) ...[
                    '',
                    today.scripture!,
                    today.citation!,
                  ],
                  '',
                  '— Benedict Daily',
                ].join('\n');
                await Clipboard.setData(ClipboardData(text: share));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied — ready to share.'),
                    ),
                  );
                }
              },
              child: const Text('Copy text'),
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
