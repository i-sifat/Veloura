import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/premium/presentation/premium_controller.dart';

export 'domain/subscription.dart';
export 'presentation/paywall_navigation.dart';
export 'presentation/premium_controller.dart';

/// Shared gate retained at the original call sites.
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(subscriptionStatusProvider).asData?.value.status.isPremium ?? false,
);

/// Premium users never see ads when an ad surface is introduced.
final noAdsProvider = Provider<bool>((ref) => ref.watch(isPremiumProvider));
