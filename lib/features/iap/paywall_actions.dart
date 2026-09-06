import 'package:dailycompany/core/iap/iap_controller.dart';
import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// House unlock, All Saints bundle, and restore — shared by every paywall.
class PaywallActions extends ConsumerStatefulWidget {
  const PaywallActions({
    super.key,
    required this.onPurchase,
    required this.purchaseLabel,
    this.unlockedMessage = 'Unlocked. Thank you.',
  });

  final Future<bool> Function() onPurchase;
  final String purchaseLabel;
  final String unlockedMessage;

  @override
  ConsumerState<PaywallActions> createState() => _PaywallActionsState();
}

class _PaywallActionsState extends ConsumerState<PaywallActions> {
  bool _busy = false;

  Future<void> _run(
    Future<bool> Function() action, {
    required String okMessage,
    String? missMessage,
  }) async {
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(okMessage)),
      );
      context.pop();
      return;
    }
    if (missMessage != null &&
        ref.read(iapControllerProvider).error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(missMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iap = ref.watch(iapControllerProvider);
    final allPrice = iap.priceLabels[IapFlags.allSaintsProductId] ?? '\$14.99';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(
                    widget.onPurchase,
                    okMessage: widget.unlockedMessage,
                  ),
          child: Text(_busy ? 'Working…' : widget.purchaseLabel),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(
                    () => ref
                        .read(iapControllerProvider.notifier)
                        .purchaseAllSaints(),
                    okMessage: 'All Saints unlocked. Thank you.',
                  ),
          child: Text(_busy ? 'Working…' : 'Unlock All Saints · $allPrice'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(
                    () => ref.read(iapControllerProvider.notifier).restore(),
                    okMessage: 'Purchases restored.',
                    missMessage: 'No purchase found.',
                  ),
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
    );
  }
}
