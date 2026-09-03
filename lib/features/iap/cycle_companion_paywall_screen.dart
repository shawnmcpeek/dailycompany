import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:dailycompany/data/models/portal.dart';
import 'package:dailycompany/shared/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CycleCompanionPaywallScreen extends ConsumerStatefulWidget {
  const CycleCompanionPaywallScreen({super.key, required this.portalId});

  final String portalId;

  @override
  ConsumerState<CycleCompanionPaywallScreen> createState() =>
      _CycleCompanionPaywallScreenState();
}

class _Copy {
  const _Copy({
    required this.includes,
    required this.staysFree,
    required this.productId,
    required this.entitlementId,
  });

  final String includes;
  final String staysFree;
  final String productId;
  final String entitlementId;
}

_Copy _copyFor(String id) => switch (id) {
      'john-cross' => const _Copy(
          includes:
              'Includes the sayings on a repeating cycle, and Read Through.',
          staysFree: 'The Precautions stay free.',
          productId: IapFlags.johnCrossProductId,
          entitlementId: IapFlags.johnCrossEntitlementId,
        ),
      'gregory' => const _Copy(
          includes:
              'Includes the Pastoral Rule twice a year, and Read Through.',
          staysFree: 'Sitting with today’s counsel stays free.',
          productId: IapFlags.gregoryProductId,
          entitlementId: IapFlags.gregoryEntitlementId,
        ),
      'augustine' => const _Copy(
          includes:
              'Includes Confessions I–X through the year, Books XI–XIII from '
              'the index, and Read Through.',
          staysFree: 'Evening reading stays free.',
          productId: IapFlags.augustineProductId,
          entitlementId: IapFlags.augustineEntitlementId,
        ),
      'teresa-avila' => const _Copy(
          includes:
              'Includes the Way of Perfection and the Interior Castle through '
              'the year, and Read Through.',
          staysFree: 'Recollection stays free.',
          productId: IapFlags.teresaAvilaProductId,
          entitlementId: IapFlags.teresaAvilaEntitlementId,
        ),
      'ignatius' => const _Copy(
          includes:
              'Includes the Autobiography through the year, the 210-day '
              'Exercises, and Read Through.',
          staysFree: 'The Examen, the 22 rules, and the prayers stay free.',
          productId: IapFlags.ignatiusProductId,
          entitlementId: IapFlags.ignatiusEntitlementId,
        ),
      'therese' => const _Copy(
          includes:
              'Includes Story of a Soul through the year, and Read Through.',
          staysFree: 'The offering stays free.',
          productId: IapFlags.thereseProductId,
          entitlementId: IapFlags.thereseEntitlementId,
        ),
      'catherine' => const _Copy(
          includes: 'Includes the Dialogue through the year, and Read Through.',
          staysFree: 'The four requests stay free.',
          productId: IapFlags.catherineProductId,
          entitlementId: IapFlags.catherineEntitlementId,
        ),
      'montfort' => const _Copy(
          includes:
              'Includes True Devotion through the year, and Read Through.',
          staysFree: 'The offering stays free.',
          productId: IapFlags.montfortProductId,
          entitlementId: IapFlags.montfortEntitlementId,
        ),
      'scupoli' => const _Copy(
          includes:
              'Includes the Spiritual Combat through the year, and Read Through.',
          staysFree: 'The combat stays free.',
          productId: IapFlags.scupoliProductId,
          entitlementId: IapFlags.scupoliEntitlementId,
        ),
      'lawrence' => const _Copy(
          includes:
              'Includes the conversations and letters through the year, and '
              'Read Through.',
          staysFree: 'The presence stays free.',
          productId: IapFlags.lawrenceProductId,
          entitlementId: IapFlags.lawrenceEntitlementId,
        ),
      'cassian' => const _Copy(
          includes:
              'Includes the Conferences through the year, and Read Through.',
          staysFree: 'Sitting with the elder stays free.',
          productId: IapFlags.cassianProductId,
          entitlementId: IapFlags.cassianEntitlementId,
        ),
      _ => const _Copy(
          includes: 'Includes the year-long cycle and Read Through.',
          staysFree: 'Practice stays free.',
          productId: IapFlags.desalesProductId,
          entitlementId: IapFlags.desalesEntitlementId,
        ),
    };

class _CycleCompanionPaywallScreenState
    extends ConsumerState<CycleCompanionPaywallScreen> {
  bool _busy = false;

  Future<void> _buy() async {
    final copy = _copyFor(widget.portalId);
    setState(() => _busy = true);
    final ok = await ref
        .read(iapControllerProvider.notifier)
        .purchaseCompanion(copy.productId, copy.entitlementId);
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
    final copy = _copyFor(widget.portalId);
    final portal = PortalRegistry.byId(widget.portalId);
    final price = iap.priceLabels[copy.productId] ?? '\$4.99';

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
        Text(copy.includes, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        Text(copy.staysFree, style: Theme.of(context).textTheme.bodyMedium),
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
          portal?.disclaimer ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
