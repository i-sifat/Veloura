import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloura/features/premium/domain/premium_repository.dart';
import 'package:veloura/features/premium/provider.dart';

class _FakePremiumRepository implements PremiumRepository {
  var purchased = false;

  @override
  Future<PremiumCatalog> load() async => const PremiumCatalog(
    status: SubscriptionStatus.free(),
    packages: [
      PremiumPackage(
        id: 'monthly',
        title: 'Monthly',
        price: r'$4.99',
        period: 'per month',
      ),
    ],
  );

  @override
  Future<SubscriptionStatus> purchase(String packageId) async {
    purchased = true;
    return const SubscriptionStatus(
      level: SubscriptionLevel.premium,
      configured: true,
    );
  }

  @override
  Future<SubscriptionStatus> restore() async => SubscriptionStatus(
    level: purchased ? SubscriptionLevel.premium : SubscriptionLevel.free,
    configured: true,
  );
}

void main() {
  test('shared premium gate updates after purchase without call-site changes', () async {
    final repository = _FakePremiumRepository();
    final container = ProviderContainer(
      overrides: [premiumRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(subscriptionStatusProvider.future);
    expect(container.read(isPremiumProvider), isFalse);

    await container
        .read(subscriptionStatusProvider.notifier)
        .purchase('monthly');

    expect(container.read(isPremiumProvider), isTrue);
    expect(container.read(noAdsProvider), isTrue);
  });

  test('restore preserves free status when no entitlement exists', () async {
    final container = ProviderContainer(
      overrides: [
        premiumRepositoryProvider.overrideWithValue(_FakePremiumRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(subscriptionStatusProvider.future);
    await container.read(subscriptionStatusProvider.notifier).restore();

    expect(container.read(isPremiumProvider), isFalse);
  });
}
