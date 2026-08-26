import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DesalesCompanionPaywallScreen extends ConsumerStatefulWidget {
  const DesalesCompanionPaywallScreen({super.key});

  @override
  ConsumerState<DesalesCompanionPaywallScreen> createState() =>
      _DesalesCompanionPaywallScreenState();
}

class _DesalesCompanionPaywallScreenState
    extends ConsumerState<DesalesCompanionPaywallScreen> {
  bool _busy = false;

  Future<void> _buy() async {
    setState(() => _busy = true);
    final ok = await ref
        .read(iapControllerProvider.notifier)
        .purchaseDesalesCompanion();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Companion unlocked. Thank you.')),
      );
      context.pop();
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final ok = await ref.read(iapControllerProvider.notifier).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Purchases restored.' : 'No purchase found.'),
      ),
    );
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
          'Includes the year-long Devout Life cycle, Letters to Persons in '
          'the World, and Read Through mode.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'The Bouquet, the Meditations, the Morning Exercise, and the '
          'Evening Examination stay free.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        if (!IapFlags.enabled) ...[
          Text(
            'Store billing is feature-flagged off in this build. '
            'Flip IapFlags.enabled and pass REVENUECAT_API_KEY when ready.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          FilledButton(
            onPressed: _busy ? null : _buy,
            child: Text(_busy ? 'Working…' : 'Unlock Companion · $price'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : _restore,
            child: const Text('Restore purchases'),
          ),
          if (iap.error != null) ...[
            const SizedBox(height: 16),
            Text(
              iap.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
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
