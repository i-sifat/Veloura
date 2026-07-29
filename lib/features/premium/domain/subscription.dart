/// Purchase lifecycle exposed to feature code without leaking a billing SDK.
enum SubscriptionLevel { free, premium }

/// Current entitlement state for the shared premium gate.
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.level,
    required this.configured,
    this.managementUrl,
  });

  const SubscriptionStatus.free({bool configured = true})
    : this(level: SubscriptionLevel.free, configured: configured);

  final SubscriptionLevel level;
  final bool configured;
  final String? managementUrl;

  bool get isPremium => level == SubscriptionLevel.premium;
}

/// Store package normalized for presentation.
class PremiumPackage {
  const PremiumPackage({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
  });

  final String id;
  final String title;
  final String price;
  final String period;
}

/// Available billing packages and entitlement state.
class PremiumCatalog {
  const PremiumCatalog({
    required this.status,
    required this.packages,
  });

  final SubscriptionStatus status;
  final List<PremiumPackage> packages;
}
