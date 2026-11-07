import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

@immutable
class SubscriptionOption {
  const SubscriptionOption({
    required this.id,
    required this.title,
    required this.price,
    this.raw,
  });

  final String id;
  final String title;
  final String price;
  final Object? raw;
}

/// F-85: compras in-app (RevenueCat sobre Google Play Billing).
abstract interface class SubscriptionService {
  bool get isAvailable;
  Future<void> identify(String businessId);
  Future<List<SubscriptionOption>> options();
  Future<bool> purchase(SubscriptionOption option);
  Future<bool> restore();
}

/// Requiere `--dart-define=REVENUECAT_ANDROID_KEY=…`. Sin clave, la
/// suscripción se muestra como "no disponible" y Pro se activa desde el
/// backend (webhook o manualmente).
class RevenueCatSubscriptionService implements SubscriptionService {
  static const _apiKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const _entitlement = 'pro';
  bool _configured = false;

  @override
  bool get isAvailable =>
      _apiKey.isNotEmpty && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _ensure() async {
    if (_configured || !isAvailable) return;
    await Purchases.configure(PurchasesConfiguration(_apiKey));
    _configured = true;
  }

  @override
  Future<void> identify(String businessId) async {
    if (!isAvailable) return;
    await _ensure();
    await Purchases.logIn(businessId);
  }

  @override
  Future<List<SubscriptionOption>> options() async {
    if (!isAvailable) return const [];
    await _ensure();
    final offerings = await Purchases.getOfferings();
    final pkgs = offerings.current?.availablePackages ?? const <Package>[];
    return [
      for (final p in pkgs)
        SubscriptionOption(
          id: p.identifier,
          title: p.storeProduct.title,
          price: p.storeProduct.priceString,
          raw: p,
        ),
    ];
  }

  @override
  Future<bool> purchase(SubscriptionOption option) async {
    await _ensure();
    final result = await Purchases.purchase(
      PurchaseParams.package(option.raw! as Package),
    );
    return result.customerInfo.entitlements.active.containsKey(_entitlement);
  }

  @override
  Future<bool> restore() async {
    await _ensure();
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.containsKey(_entitlement);
  }
}
