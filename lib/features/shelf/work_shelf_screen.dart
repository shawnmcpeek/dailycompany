import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/models/work_shelf.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/features/iap/paywall.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:dailycompany/shared/widgets/continue_reading.dart';
import 'package:dailycompany/shared/widgets/reading_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorkShelfScreen extends ConsumerWidget {
  const WorkShelfScreen({
    super.key,
    required this.assetPath,
    required this.module,
    required this.paywallHint,
  });

  final String assetPath;
  final String module;
  final String paywallHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workShelfProvider(assetPath));
    final portalId = ref.watch(currentPortalIdProvider);
    final unlocked = ref.watch(cycleUnlockedProvider);

    return async.when(
      loading: () => const EmptyLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (shelf) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            Text(shelf.label, style: Theme.of(context).textTheme.headlineMedium),
            if (shelf.intro.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(shelf.intro, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 20),
            ContinueReadingTile(module: module),
            if (!unlocked)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Unlock Companion'),
                subtitle: Text(paywallHint),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => openPaywall(context),
              )
            else if (shelf.books.length == 1)
              ..._chaptersOf(
                context,
                portalId,
                module,
                shelf.books.first,
              )
            else
              for (final book in shelf.books) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${book.parts.length} ${book.parts.length == 1 ? 'part' : 'parts'}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push(
                    PortalRoutes.shelfWork(portalId, module, book.id),
                  ),
                ),
                const SectionRule(),
              ],
          ],
        );
      },
    );
  }

  static List<Widget> _chaptersOf(
    BuildContext context,
    String portalId,
    String module,
    ShelfBook book,
  ) {
    return [
      for (final part in book.parts) ...[
        if (part.title.isNotEmpty && book.parts.length > 1) ...[
          Text(part.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        for (final chapter in part.chapters) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              chapter.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              'Chapter ${chapter.chapter}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push(
              PortalRoutes.shelfChapter(
                portalId,
                module,
                book.id,
                part.part,
                chapter.chapter,
              ),
            ),
          ),
          const SectionRule(),
        ],
        const SizedBox(height: 16),
      ],
    ];
  }
}

class WorkShelfBookScreen extends ConsumerWidget {
  const WorkShelfBookScreen({
    super.key,
    required this.assetPath,
    required this.module,
    required this.workId,
  });

  final String assetPath;
  final String module;
  final String workId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workShelfProvider(assetPath));
    final portalId = ref.watch(currentPortalIdProvider);
    final unlocked = ref.watch(cycleUnlockedProvider);

    if (!unlocked) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: TextButton(
            onPressed: () => openPaywall(context),
            child: const Text('Unlock Companion'),
          ),
        ),
      );
    }

    return async.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (shelf) {
        final book = shelf.byId(workId);
        if (book == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Work not found.')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(book.title)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
            children: WorkShelfScreen._chaptersOf(
              context,
              portalId,
              module,
              book,
            ),
          ),
        );
      },
    );
  }
}

class WorkShelfChapterScreen extends ConsumerWidget {
  const WorkShelfChapterScreen({
    super.key,
    required this.assetPath,
    required this.workId,
    required this.book,
    required this.chapter,
  });

  final String assetPath;
  final String workId;
  final int book;
  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workShelfProvider(assetPath));
    final unlocked = ref.watch(cycleUnlockedProvider);

    if (!unlocked) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: TextButton(
            onPressed: () => openPaywall(context),
            child: const Text('Unlock Companion'),
          ),
        ),
      );
    }

    return async.when(
      loading: () => const Scaffold(body: EmptyLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (shelf) {
        final work = shelf.byId(workId);
        final part = work?.partByNumber(book);
        final found = work?.chapter(book, chapter);
        if (work == null || part == null || found == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Chapter not found.')),
          );
        }
        return ReadingPage(
          title: '${work.title} · ${part.title}',
          snippet: found.textEn,
          children: [
            Text(
              'Chapter ${found.chapter}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(found.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            ReadingBody(text: found.textEn),
          ],
        );
      },
    );
  }
}
