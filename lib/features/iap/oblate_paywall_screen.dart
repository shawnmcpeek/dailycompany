import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OblatePaywallScreen extends ConsumerStatefulWidget {
  const OblatePaywallScreen({super.key});

  @override
  ConsumerState<OblatePaywallScreen> createState() => _OblatePaywallScreenState();
}

class _OblatePaywallScreenState extends ConsumerState<OblatePaywallScreen> {
  bool _busy = false;

  Future<void> _buy() async {
    setState(() => _busy = true);
    final ok = await ref.read(iapControllerProvider.notifier).purchaseOblate();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oblate unlocked. Thank you.')),
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
        content: Text(ok ? 'Purchases restored.' : 'No Oblate purchase found.'),
      ),
    );
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final iap = ref.watch(iapControllerProvider);
    final price = iap.priceLabel ?? '\$4.99';

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
          'Latin side-by-side, and offline audio when it ships.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Compline, today’s Rule, Tools, and the Medal stay free.',
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
            child: Text(_busy ? 'Working…' : 'Unlock Oblate · $price'),
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
          'An independent app from Daddoo Dev. Not affiliated with any '
          'Benedictine house or the Order of Saint Benedict.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

Future<void> openOblatePaywall(BuildContext context) {
  final portalId = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(currentPortalIdProvider);
  return context.push(PortalRoutes.oblate(portalId));
}
