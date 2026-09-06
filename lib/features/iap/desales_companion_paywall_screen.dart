import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:dailycompany/features/iap/paywall_actions.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DesalesCompanionPaywallScreen extends ConsumerWidget {
  const DesalesCompanionPaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iap = ref.watch(iapControllerProvider);
    final price = iap.priceLabels[IapFlags.desalesProductId] ?? '\$4.99';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text('Companion', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'A one-time unlock. No subscription.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Text(
          'Includes both year-long cycles — Devout Life and the Treatise '
          'on the Love of God — Letters to Persons in the World, and '
          'Read Through.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'The Bouquet, the Meditations, the Morning Exercise, and the '
          'Evening Examination stay free.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        if (!IapFlags.enabled)
          Text(
            'Store billing is feature-flagged off in this build. '
            'Flip IapFlags.enabled and pass REVENUECAT_API_KEY when ready.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          PaywallActions(
            onPurchase: () => ref
                .read(iapControllerProvider.notifier)
                .purchaseDesalesCompanion(),
            purchaseLabel: 'Unlock Companion · $price',
            unlockedMessage: 'Companion unlocked. Thank you.',
          ),
        const SizedBox(height: 28),
        const SectionRule(),
        const SizedBox(height: 16),
        Text(
          'An independent app from Daddoo Dev. Not affiliated with, '
          'endorsed by, or produced by the Salesians of Don Bosco, the '
          'Order of the Visitation, any Salesian or Visitandine province '
          'or house, or any shrine or publisher associated with them.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
