import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:dailycompany/data/models/portal.dart';
import 'package:dailycompany/features/iap/paywall_actions.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FrancisCompanionPaywallScreen extends ConsumerWidget {
  const FrancisCompanionPaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iap = ref.watch(iapControllerProvider);
    final price = iap.priceLabels[IapFlags.francisProductId] ?? '\$4.99';

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
          'Includes the authentic writings on a repeating cycle, Read Through, '
          'and the Little Flowers — stories told about him.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'The twenty-eight Admonitions and the Canticle of the Creatures stay free.',
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
                .purchaseFrancisCompanion(),
            purchaseLabel: 'Unlock Companion · $price',
            unlockedMessage: 'Companion unlocked. Thank you.',
          ),
        const SizedBox(height: 28),
        const SectionRule(),
        const SizedBox(height: 16),
        Text(
          PortalRegistry.francis.disclaimer,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
