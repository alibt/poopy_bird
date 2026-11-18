import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'live_config.dart';

/// One catalogued IAP offer shown in the shop.
enum IapProduct {
  coinsSmall(
    LiveConfig.coinsSmallId,
    title: 'Coin Pouch',
    description: '1,000 coins',
    coins: 1000,
    fallbackPrice: '\$0.99',
  ),
  coinsMedium(
    LiveConfig.coinsMediumId,
    title: 'Coin Bag',
    description: '3,000 coins (+20%)',
    coins: 3000,
    fallbackPrice: '\$2.99',
  ),
  coinsLarge(
    LiveConfig.coinsLargeId,
    title: 'Coin Chest',
    description: '8,000 coins (+60%)',
    coins: 8000,
    fallbackPrice: '\$6.99',
  ),
  removeAds(
    LiveConfig.removeAdsId,
    title: 'Remove Ads',
    description: 'Hide ads and auto-double run coins',
    coins: 0,
    fallbackPrice: '\$3.99',
    nonConsumable: true,
  ),
  starterPack(
    LiveConfig.starterPackId,
    title: 'Starter Pack',
    description: '2,000 coins + Golden poop',
    coins: 2000,
    fallbackPrice: '\$1.99',
    nonConsumable: true,
    cosmeticId: 'poop_gold',
  );

  const IapProduct(
    this.id, {
    required this.title,
    required this.description,
    required this.coins,
    required this.fallbackPrice,
    this.nonConsumable = false,
    this.cosmeticId,
  });

  final String id;
  final String title;
  final String description;
  final int coins;
  final String fallbackPrice;
  final bool nonConsumable;
  final String? cosmeticId;

  static IapProduct? byId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Result of a purchase attempt after local fulfillment.
class IapPurchaseResult {
  const IapPurchaseResult({
    required this.product,
    required this.orderId,
    this.ok = true,
    this.message,
  });

  final IapProduct product;
  final String orderId;
  final bool ok;
  final String? message;
}

/// Storefront for coin packs and non-consumables.
abstract interface class IapStore {
  Future<void> init();

  /// Latest store price label for [product], or the catalog fallback.
  String priceLabel(IapProduct product);

  /// Whether [product] can be bought right now.
  bool isAvailable(IapProduct product);

  Future<IapPurchaseResult?> purchase(IapProduct product);

  void dispose();
}

/// Debug / desktop store: grants instantly with a fake order id.
class DebugIapStore implements IapStore {
  DebugIapStore();

  int _n = 0;

  @override
  Future<void> init() async {}

  @override
  String priceLabel(IapProduct product) => product.fallbackPrice;

  @override
  bool isAvailable(IapProduct product) => true;

  @override
  Future<IapPurchaseResult?> purchase(IapProduct product) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _n++;
    return IapPurchaseResult(
      product: product,
      orderId: 'debug-$_n-${product.id}',
    );
  }

  @override
  void dispose() {}
}

/// No store (web / unsupported): every product unavailable.
class NoIapStore implements IapStore {
  const NoIapStore();

  @override
  Future<void> init() async {}

  @override
  String priceLabel(IapProduct product) => product.fallbackPrice;

  @override
  bool isAvailable(IapProduct product) => false;

  @override
  Future<IapPurchaseResult?> purchase(IapProduct product) async => null;

  @override
  void dispose() {}
}

/// Wraps `in_app_purchase` for Android / iOS. Fulfillment still happens in
/// [ProgressController] after a successful purchase (server verify later).
class PlatformIapStore implements IapStore {
  PlatformIapStore();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, ProductDetails> _products = {};
  Completer<IapPurchaseResult?>? _pending;
  bool _ready = false;

  @override
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      final available = await _iap.isAvailable();
      if (!available) return;
      _sub = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
      final response =
          await _iap.queryProductDetails(LiveConfig.iapProductIds.toSet());
      for (final p in response.productDetails) {
        _products[p.id] = p;
      }
      _ready = true;
    } catch (e, st) {
      debugPrint('PlatformIapStore init failed: $e\n$st');
      _ready = false;
    }
  }

  @override
  String priceLabel(IapProduct product) =>
      _products[product.id]?.price ?? product.fallbackPrice;

  @override
  bool isAvailable(IapProduct product) =>
      _ready && _products.containsKey(product.id);

  @override
  Future<IapPurchaseResult?> purchase(IapProduct product) async {
    final details = _products[product.id];
    if (details == null) return null;
    if (_pending != null) return null;
    _pending = Completer<IapPurchaseResult?>();
    final param = PurchaseParam(productDetails: details);
    final started = product.nonConsumable
        ? await _iap.buyNonConsumable(purchaseParam: param)
        : await _iap.buyConsumable(purchaseParam: param);
    if (!started) {
      _pending = null;
      return null;
    }
    return _pending!.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        _pending = null;
        return null;
      },
    );
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final product = IapProduct.byId(purchase.productID);
      if (product == null) continue;
      if (purchase.status == PurchaseStatus.pending) continue;
      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        _pending?.complete(IapPurchaseResult(
          product: product,
          orderId: purchase.purchaseID ?? 'err',
          ok: false,
          message: purchase.error?.message,
        ));
        _pending = null;
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _pending?.complete(IapPurchaseResult(
          product: product,
          orderId: purchase.purchaseID ??
              'iap-${purchase.productID}-${purchase.transactionDate}',
        ));
        _pending = null;
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
  }
}
