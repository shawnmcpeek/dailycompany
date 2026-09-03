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
  }) => IapState(
    ready: ready ?? this.ready,
    entitlements: entitlements ?? this.entitlements,
    priceLabels: priceLabels ?? this.priceLabels,
    error: error,
  );
}

final iapControllerProvider = StateNotifierProvider<IapController, IapState>((
  ref,
) {
  return IapController()..bootstrap();
});

/// Effective unlock: when IAP is flagged off, everything is unlocked.
final oblateUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.entitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final desalesCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.desalesEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final kempisCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.kempisEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final liguoriCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.liguoriEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final francisCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.francisEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final johnCrossCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.johnCrossEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final gregoryCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.gregoryEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final augustineCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.augustineEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final teresaAvilaCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.teresaAvilaEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final ignatiusCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.ignatiusEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final thereseCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.thereseEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final catherineCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.catherineEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final montfortCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.montfortEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final scupoliCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.scupoliEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final lawrenceCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.lawrenceEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

final cassianCompanionUnlockedProvider = Provider<bool>((ref) {
  if (!IapFlags.enabled) return true;
  final iap = ref.watch(iapControllerProvider);
  return iap.has(IapFlags.cassianEntitlementId) ||
      iap.has(IapFlags.allSaintsEntitlementId);
});

class IapController extends StateNotifier<IapState> {
  IapController() : super(const IapState());

  Future<void> bootstrap() async {
    if (!IapFlags.enabled) {
      state = const IapState(
        ready: true,
        entitlements: {
          IapFlags.entitlementId,
          IapFlags.desalesEntitlementId,
          IapFlags.kempisEntitlementId,
          IapFlags.liguoriEntitlementId,
          IapFlags.francisEntitlementId,
          IapFlags.johnCrossEntitlementId,
          IapFlags.gregoryEntitlementId,
          IapFlags.augustineEntitlementId,
          IapFlags.teresaAvilaEntitlementId,
          IapFlags.ignatiusEntitlementId,
          IapFlags.thereseEntitlementId,
          IapFlags.catherineEntitlementId,
          IapFlags.montfortEntitlementId,
          IapFlags.scupoliEntitlementId,
          IapFlags.lawrenceEntitlementId,
          IapFlags.cassianEntitlementId,
          IapFlags.allSaintsEntitlementId,
        },
      );
      return;
    }

    if (IapFlags.apiKey.isEmpty) {
      state = const IapState(ready: true, error: 'REVENUECAT_API_KEY missing');
      return;
    }

    if (kIsWeb) {
      state = const IapState(ready: true, error: 'IAP not available on web');
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
        entitlements: {
          IapFlags.entitlementId,
          IapFlags.desalesEntitlementId,
          IapFlags.kempisEntitlementId,
          IapFlags.liguoriEntitlementId,
          IapFlags.francisEntitlementId,
          IapFlags.johnCrossEntitlementId,
          IapFlags.gregoryEntitlementId,
          IapFlags.augustineEntitlementId,
          IapFlags.teresaAvilaEntitlementId,
          IapFlags.ignatiusEntitlementId,
          IapFlags.thereseEntitlementId,
          IapFlags.catherineEntitlementId,
          IapFlags.montfortEntitlementId,
          IapFlags.scupoliEntitlementId,
          IapFlags.lawrenceEntitlementId,
          IapFlags.cassianEntitlementId,
          IapFlags.allSaintsEntitlementId,
        },
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
      final packages =
          offerings.current?.availablePackages ?? const <Package>[];
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

  Future<bool> purchaseKempisCompanion() =>
      _purchase(IapFlags.kempisProductId, IapFlags.kempisEntitlementId);

  Future<bool> purchaseLiguoriCompanion() =>
      _purchase(IapFlags.liguoriProductId, IapFlags.liguoriEntitlementId);

  Future<bool> purchaseFrancisCompanion() =>
      _purchase(IapFlags.francisProductId, IapFlags.francisEntitlementId);

  Future<bool> purchaseCompanion(String productId, String entitlementId) =>
      _purchase(productId, entitlementId);

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
