import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class IapState {
  const IapState({
    this.ready = false,
    this.entitlements = const {},
    this.priceLabels = const {},
    this.error,
  });

  final bool ready;

  /// Active RevenueCat entitlement identifiers.
  final Set<String> entitlements;

  /// productId -> store price string, filled in as offerings load.
  final Map<String, String> priceLabels;
  final String? error;

  bool has(String entitlementId) => entitlements.contains(entitlementId);

  IapState copyWith({
    bool? ready,
    Set<String>? entitlements,
    Map<String, String>? priceLabels,
    String? error,
  }) =>
      IapState(
        ready: ready ?? this.ready,
        entitlements: entitlements ?? this.entitlements,
        priceLabels: priceLabels ?? this.priceLabels,
        error: error,
      );
}

final iapControllerProvider =
    StateNotifierProvider<IapController, IapState>((ref) {
  return IapController()..bootstrap();
});

/// Effective unlock: when IAP is flagged off, everything is unlocked.
final oblateUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  return ref.watch(iapControllerProvider).has(IapFlags.entitlementId);
});

final desalesCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  return ref
      .watch(iapControllerProvider)
      .has(IapFlags.desalesEntitlementId);
});

class IapController extends StateNotifier<IapState> {
  IapController() : super(const IapState());

  Future<void> bootstrap() async {
    if (!IapFlags.enabled) {
      state = const IapState(
        ready: true,
        entitlements: {IapFlags.entitlementId, IapFlags.desalesEntitlementId},
      );
      return;
    }

    if (IapFlags.apiKey.isEmpty) {
      state = const IapState(
        ready: true,
        error: 'REVENUECAT_API_KEY missing',
      );
      return;
    }

    if (kIsWeb) {
      state = const IapState(
        ready: true,
        error: 'IAP not available on web',
      );
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(IapFlags.apiKey));
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      await refresh();
      await _loadOfferings();
    } catch (e) {
      state = IapState(ready: true, error: '$e');
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    state = state.copyWith(
      ready: true,
      entitlements: _activeEntitlements(info),
      error: null,
    );
  }

  Set<String> _activeEntitlements(CustomerInfo info) =>
      info.entitlements.active.keys.toSet();

  Future<void> refresh() async {
    if (!IapFlags.enabled) {
      state = const IapState(
        ready: true,
        entitlements: {IapFlags.entitlementId, IapFlags.desalesEntitlementId},
      );
      return;
    }
    try {
      final info = await Purchases.getCustomerInfo();
      state = state.copyWith(
        ready: true,
        entitlements: _activeEntitlements(info),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const <Package>[];
      final labels = <String, String>{};
      for (final p in packages) {
        labels[p.storeProduct.identifier] = p.storeProduct.priceString;
      }
      if (labels.isNotEmpty) {
        state = state.copyWith(priceLabels: {...state.priceLabels, ...labels});
      }
    } catch (_) {}
  }

  Future<Package?> _packageFor(String productId) async {
    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? const <Package>[];
    for (final p in packages) {
      if (p.storeProduct.identifier == productId) return p;
    }
    return null;
  }

  Future<bool> _purchase(String productId, String entitlementId) async {
    if (!IapFlags.enabled) return true;
    try {
      final target = await _packageFor(productId);
      if (target == null) {
        state = state.copyWith(error: '$productId not found in offerings');
        return false;
      }
      final result = await Purchases.purchase(PurchaseParams.package(target));
      final active = _activeEntitlements(result.customerInfo);
      state = state.copyWith(entitlements: active, error: null);
      return active.contains(entitlementId);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return false;
      state = state.copyWith(error: e.message ?? code.toString());
      return false;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return false;
    }
  }

  Future<bool> purchaseOblate() =>
      _purchase(IapFlags.productId, IapFlags.entitlementId);

  Future<bool> purchaseDesalesCompanion() =>
      _purchase(IapFlags.desalesProductId, IapFlags.desalesEntitlementId);

  Future<bool> restore() async {
    if (!IapFlags.enabled) return true;
    try {
      final info = await Purchases.restorePurchases();
      final active = _activeEntitlements(info);
      state = state.copyWith(entitlements: active, error: null);
      return active.isNotEmpty;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return false;
    }
  }

  static bool lifeChapterFree(int chapter) =>
      chapter <= IapFlags.freeLifeChapterMax;
}
