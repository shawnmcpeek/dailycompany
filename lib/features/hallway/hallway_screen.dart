import 'package:dailycompany/app/brand.dart';
import 'package:dailycompany/app/router/app_router.dart';
import 'package:dailycompany/data/companion.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HallwayScreen extends ConsumerWidget {
  const HallwayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final chosen = Companions.byId(settings.companionId);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
          children: [
            Text(
              Brand.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The hallway. Choose whose house you will keep.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 28),
            ChromeLabel('Open'),
            const SizedBox(height: 12),
            for (final house in Companions.openHouses) ...[
              HubNavButton(
                title: house.name,
                subtitle: house.work,
                actionLabel: chosen?.id == house.id ? 'Here' : 'Enter',
                onPressed: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setCompanion(house.id);
                  if (context.mounted) {
                    context.go(portalLandingRoute(house.id));
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 18),
            ChromeLabel('Not yet open'),
            const SizedBox(height: 12),
            for (final house in Companions.closedHouses) ...[
              HubNavButton(
                title: house.name,
                subtitle: house.work,
                actionLabel: 'Soon',
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
