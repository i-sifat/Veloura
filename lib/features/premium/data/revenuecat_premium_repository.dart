import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:veloura/features/premium/domain/premium_repository.dart';
import 'package:veloura/features/premium/domain/subscription.dart';

/// RevenueCat-backed billing using Play Billing / StoreKit.
///
/// API keys are supplied at build time and are intentionally not committed:
/// `--dart-define=REVENUECAT_ANDROID_API_KEY=...` and
/// `--dart-define=REVENUECAT_IOS_API_KEY=...`.
class RevenueCatPremiumRepository implements PremiumRepository {
  RevenueCatPremiumRepository();

  static const entitlementId = 'premium';
  static const _androidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );
  static const _iosKey = String.fromEnvironment('REVENUECAT_IOS_API_KEY');

  final Map<String, Package> _packages = {};
  bool _configured = false;

  String get _apiKey => switch (defaultTargetPlatform) {
    TargetPlatform.android => _androidKey,
    TargetPlatform.iOS || TargetPlatform.macOS => _iosKey,
    _ => '',
  };

  Future<bool> _configure() async {
    if (_configured) return true;
    if (_apiKey.isEmpty) return false;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    await Purchases.configure(PurchasesConfiguration(_apiKey));
    _configured = true;
    return true;
  }

  @override
  Future<PremiumCatalog> load() async {
    if (!await _configure()) {
      return const PremiumCatalog(
        status: SubscriptionStatus.free(configured: false),
        packages: [],
      );
    }
    final customer = await Purchases.getCustomerInfo();
    final offerings = await Purchases.getOfferings();
    final available = offerings.current?.availablePackages ?? const <Package>[];
    _packages
      ..clear()
      ..addEntries(available.map((value) => MapEntry(value.identifier, value)));
    return PremiumCatalog(
      status: _status(customer),
      packages: available.map(_package).toList(growable: false),
    );
  }

  @override
  Future<SubscriptionStatus> purchase(String packageId) async {
    if (!await _configure()) {
      return const SubscriptionStatus.free(configured: false);
    }
    final package = _packages[packageId];
    if (package == null) throw StateError('That purchase option is unavailable.');
    final result = await Purchases.purchase(
      PurchaseParams.package(package),
    );
    return _status(result.customerInfo);
  }

  @override
  Future<SubscriptionStatus> restore() async {
    if (!await _configure()) {
      return const SubscriptionStatus.free(configured: false);
    }
    return _status(await Purchases.restorePurchases());
  }

  PremiumPackage _package(Package value) => PremiumPackage(
    id: value.identifier,
    title: value.storeProduct.title,
    price: value.storeProduct.priceString,
    period: switch (value.packageType) {
      PackageType.monthly => 'per month',
      PackageType.annual => 'per year',
      PackageType.lifetime => 'one time',
      _ => value.storeProduct.description,
    },
  );

  SubscriptionStatus _status(CustomerInfo customer) => SubscriptionStatus(
    level: customer.entitlements.active.containsKey(entitlementId)
        ? SubscriptionLevel.premium
        : SubscriptionLevel.free,
    configured: true,
    managementUrl: customer.managementURL,
  );
}
