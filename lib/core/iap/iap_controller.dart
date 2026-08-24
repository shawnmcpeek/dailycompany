import 'package:dailycompany/core/iap/iap_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class IapState {
  const IapState({
    this.ready = false,
    this.hasOblate = false,
    this.priceLabel,
    this.error,
  });

  final bool ready;
  final bool hasOblate;
  final String? priceLabel;
  final String? error;

  IapState copyWith({
    bool? ready,
    bool? hasOblate,
    String? priceLabel,
    String? error,
  }) =>
      IapState(
        ready: ready ?? this.ready,
        hasOblate: hasOblate ?? this.hasOblate,
        priceLabel: priceLabel ?? this.priceLabel,
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
  return ref.watch(iapControllerProvider).hasOblate;
});

class IapController extends StateNotifier<IapState> {
  IapController() : super(const IapState());

  Future<void> bootstrap() async {
    if (!IapFlags.enabled) {
      state = const IapState(ready: true, hasOblate: true);
      return;
    }

    if (IapFlags.apiKey.isEmpty) {
      state = const IapState(
        ready: true,
        hasOblate: false,
        error: 'REVENUECAT_API_KEY missing',
      );
      return;
    }

    if (kIsWeb) {
      state = const IapState(
        ready: true,
        hasOblate: false,
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
      state = IapState(ready: true, hasOblate: false, error: '$e');
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    state = state.copyWith(
      ready: true,
      hasOblate: _entitled(info),
      error: null,
    );
  }

  bool _entitled(CustomerInfo info) =>
      info.entitlements.active.containsKey(IapFlags.entitlementId);

  Future<void> refresh() async {
    if (!IapFlags.enabled) {
      state = const IapState(ready: true, hasOblate: true);
      return;
    }
    try {
      final info = await Purchases.getCustomerInfo();
      state = state.copyWith(
        ready: true,
        hasOblate: _entitled(info),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }

  Future<void> _loadOfferings() async {
    try {
      final pkg = await _oblatePackage();
      final price = pkg?.storeProduct.priceString;
      if (price != null) {
        state = state.copyWith(priceLabel: price);
      }
    } catch (_) {}
  }

  Future<Package?> _oblatePackage() async {
    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? const <Package>[];
    for (final p in packages) {
      if (p.storeProduct.identifier == IapFlags.productId) return p;
    }
    return packages.isEmpty ? null : packages.first;
  }

  Future<bool> purchaseOblate() async {
    if (!IapFlags.enabled) return true;
    try {
      final target = await _oblatePackage();
      if (target == null) {
        state = state.copyWith(error: 'Oblate product not found in offerings');
        return false;
      }
      final result = await Purchases.purchase(PurchaseParams.package(target));
      final ok = _entitled(result.customerInfo);
      state = state.copyWith(hasOblate: ok, error: null);
      return ok;
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

  Future<bool> restore() async {
    if (!IapFlags.enabled) return true;
    try {
      final info = await Purchases.restorePurchases();
      final ok = _entitled(info);
      state = state.copyWith(hasOblate: ok, error: null);
      return ok;
    } catch (e) {
      state = state.copyWith(error: '$e');
      return false;
    }
  }

  static bool lifeChapterFree(int chapter) =>
      chapter <= IapFlags.freeLifeChapterMax;
}
