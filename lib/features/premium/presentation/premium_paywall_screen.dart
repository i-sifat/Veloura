import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/premium/domain/subscription.dart';
import 'package:veloura/features/premium/presentation/premium_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_backdrop.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

class PremiumPaywallScreen extends ConsumerWidget {
  const PremiumPaywallScreen({required this.source, super.key});
  final String source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(paywallViewedProvider(source));
    final premium = ref.watch(subscriptionStatusProvider);
    return Scaffold(
      body: GameBackdrop(
        child: SafeArea(
          child: premium.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: '$error',
              onRetry: () => ref.invalidate(subscriptionStatusProvider),
            ),
            data: (catalog) => _PaywallBody(source: source, catalog: catalog),
          ),
        ),
      ),
    );
  }
}

class _PaywallBody extends ConsumerWidget {
  const _PaywallBody({required this.source, required this.catalog});
  final String source;
  final PremiumCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: context.pop,
              icon: const Icon(Icons.arrow_back, size: 22),
            ),
            const Spacer(),
            TextButton(
              onPressed: ref
                  .read(subscriptionStatusProvider.notifier)
                  .restore,
              child: const Text('Restore purchases'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Icon(
          Icons.workspace_premium,
          size: 54,
          color: GameTokens.roseLight,
        ),
        const SizedBox(height: 12),
        Text(
          catalog.status.isPremium
              ? 'Veloura Premium is active'
              : 'More ways to connect',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'Unlock the most playful decks and make every game your own.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        const _Benefit(
          icon: Icons.casino,
          text: 'Create custom dice faces',
        ),
        const _Benefit(
          icon: Icons.local_fire_department,
          text: 'Play Superhot cards and roulette',
        ),
        const _Benefit(
          icon: Icons.theater_comedy,
          text: 'Unlock premium roleplay packs',
        ),
        const _Benefit(
          icon: Icons.swap_horiz,
          text: 'Swap challenge cards without ending a turn',
        ),
        const _Benefit(
          icon: Icons.block,
          text: 'Enjoy the future ad-free experience',
        ),
        const SizedBox(height: 24),
        if (!catalog.status.configured)
          _Notice(
            icon: Icons.settings_outlined,
            text: 'Store setup is not configured in this build. Source: $source',
          )
        else if (catalog.status.isPremium)
          const _Notice(
            icon: Icons.verified,
            text: 'All Premium experiences are unlocked on this account.',
          )
        else if (catalog.packages.isEmpty)
          const _Notice(
            icon: Icons.info_outline,
            text: 'Purchase options are temporarily unavailable.',
          )
        else
          for (final package in catalog.packages) ...[
            _PackageCard(package: package),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 16),
        Text(
          'Subscriptions and digital unlocks are processed by Google Play or the App Store.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, color: GameTokens.roseLight),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
        const Icon(Icons.check_circle, color: GameTokens.rose, size: 18),
      ],
    ),
  );
}

class _PackageCard extends ConsumerWidget {
  const _PackageCard({required this.package});
  final PremiumPackage package;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [GameTokens.roseDeep, GameTokens.rose],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [GameTokens.ctaShadow],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                package.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text('${package.price}\n${package.period}', textAlign: TextAlign.end),
          ],
        ),
        const SizedBox(height: 14),
        PrimaryCta(
          label: 'Choose ${package.title}',
          onPressed: () => ref
              .read(subscriptionStatusProvider.notifier)
              .purchase(package.id),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: GameTokens.glassStrong,
      border: Border.all(color: GameTokens.hairline),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, color: GameTokens.roseLight),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
