import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/models/desales_letter.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Letters to Persons in the World" (Mackey trans.), browsed by the
/// original 7 books. See tools/content/desales/parse_letters.py.
class DesalesLettersScreen extends ConsumerWidget {
  const DesalesLettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(desalesLettersProvider);
    final portalId = ref.watch(currentPortalIdProvider);

    return booksAsync.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (books) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text('Letters', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Selections from Letters to Persons in the World, grouped as '
              'the saint’s editors arranged them.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            for (final book in books) ...[
              Text(
                'Book ${book.book} · ${book.title}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              for (final letter in book.letters) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Letter ${letter.letter}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  subtitle: Text(
                    letter.description.isNotEmpty
                        ? letter.description
                        : 'To ${book.title.replaceFirst('Letters to ', '').replaceFirst('Various ', '').replaceFirst('Letters of the Saint about Himself', 'Himself')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push(
                    PortalRoutes.letter(portalId, book.book, letter.letter),
                  ),
                ),
                const SectionRule(),
              ],
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class DesalesLetterScreen extends ConsumerWidget {
  const DesalesLetterScreen({
    super.key,
    required this.book,
    required this.letter,
  });

  final int book;
  final int letter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(desalesLettersProvider);

    return booksAsync.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (books) {
        DesalesLetterBook? b;
        for (final candidate in books) {
          if (candidate.book == book) {
            b = candidate;
            break;
          }
        }
        DesalesLetter? l;
        if (b != null) {
          for (final candidate in b.letters) {
            if (candidate.letter == letter) {
              l = candidate;
              break;
            }
          }
        }
        if (b == null || l == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Letter not found.')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text('Book ${b.book} · Letter ${l.letter}')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
            children: [
              Text(b.title, style: Theme.of(context).textTheme.labelSmall),
              if (l.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  l.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 20),
              ReadingBody(text: l.textEn),
            ],
          ),
        );
      },
    );
  }
}
