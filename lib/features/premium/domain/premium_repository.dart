import 'package:veloura/features/premium/domain/subscription.dart';

/// Store-agnostic subscription boundary.
abstract interface class PremiumRepository {
  Future<PremiumCatalog> load();
  Future<SubscriptionStatus> purchase(String packageId);
  Future<SubscriptionStatus> restore();
}
