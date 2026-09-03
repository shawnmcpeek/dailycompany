import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:dailycompany/data/models/portal.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LiguoriCompanionPaywallScreen extends ConsumerStatefulWidget {
  const LiguoriCompanionPaywallScreen({super.key});

  @override
  ConsumerState<LiguoriCompanionPaywallScreen> createState() =>
      _LiguoriCompanionPaywallScreenState();
}

class _LiguoriCompanionPaywallScreenState
    extends ConsumerState<LiguoriCompanionPaywallScreen> {
  bool _busy = false;

  Future<void> _buy() async {
    setState(() => _busy = true);
    final ok = await ref
        .read(iapControllerProvider.notifier)
        .purchaseLiguoriCompanion();
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
    final price = iap.priceLabels[IapFlags.liguoriProductId] ?? '\$4.99';

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
          'Includes the thirty-one Visits on the day of the month, and Read Through.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'The Visit — the manner, the spiritual communion, the hour — stays free.',
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
          PortalRegistry.liguori.disclaimer,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
