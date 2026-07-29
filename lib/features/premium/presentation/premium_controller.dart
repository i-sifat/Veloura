import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/premium/data/revenuecat_premium_repository.dart';
import 'package:veloura/features/premium/domain/premium_repository.dart';
import 'package:veloura/features/premium/domain/subscription.dart';

final premiumRepositoryProvider = Provider<PremiumRepository>(
  (ref) => RevenueCatPremiumRepository(),
);

/// Owns offerings, purchases, restores, and the app-wide entitlement state.
class PremiumController extends AsyncNotifier<PremiumCatalog> {
  late PremiumRepository _repository;

  @override
  Future<PremiumCatalog> build() async {
    _repository = ref.watch(premiumRepositoryProvider);
    return _repository.load();
  }

  Future<void> purchase(String packageId) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = const AsyncLoading<PremiumCatalog>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final status = await _repository.purchase(packageId);
      return PremiumCatalog(status: status, packages: current.packages);
    });
  }

  Future<void> restore() async {
    final current = state.asData?.value;
    if (current == null) return;
    state = const AsyncLoading<PremiumCatalog>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final status = await _repository.restore();
      return PremiumCatalog(status: status, packages: current.packages);
    });
  }
}

final subscriptionStatusProvider =
    AsyncNotifierProvider<PremiumController, PremiumCatalog>(
      PremiumController.new,
    );
