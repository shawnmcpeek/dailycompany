import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:dailycompany/features/iap/paywall_actions.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OblatePaywallScreen extends ConsumerWidget {
  const OblatePaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iap = ref.watch(iapControllerProvider);
    final price = iap.priceLabels[IapFlags.productId] ?? '\$4.99';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      children: [
        Text('Oblate', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'A one-time unlock. No subscription.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Text(
          'Includes the full lay horarium and bells, Life of Benedict beyond '
          'the first five episodes, Lectio journal with cross-cycle memory, '
          'and Latin side-by-side.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Compline, today’s Rule, Tools, and the Medal stay free.',
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
            onPurchase: () =>
                ref.read(iapControllerProvider.notifier).purchaseOblate(),
            purchaseLabel: 'Unlock Oblate · $price',
            unlockedMessage: 'Oblate unlocked. Thank you.',
          ),
        const SizedBox(height: 28),
        const SectionRule(),
        const SizedBox(height: 16),
        Text(
          'An independent app from Daddoo Dev. Not affiliated with any '
          'Benedictine house or the Order of Saint Benedict.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
