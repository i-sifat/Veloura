import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/games/domain/game_catalog_entry.dart';
import 'package:veloura/features/home/presentation/home_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/section_header.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/app_design_tokens.dart';

/// Returns a rotating, deterministic set of four games for the current day.
List<GameCatalogEntry> popularGamesFor(DateTime date) {
  final day = DateTime(date.year, date.month, date.day)
      .difference(DateTime(date.year))
      .inDays;
  return List.generate(
    4,
    (index) => kGameCatalog[(day + index) % kGameCatalog.length],
    growable: false,
  );
}

/// Home discovery shell renovated from the approved visual direction.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final colors = AppColors.of(context);
    final games = popularGamesFor(DateTime.now());

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: homeState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: '$error',
            onRetry: () => ref.invalidate(homeControllerProvider),
          ),
          data: (state) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.spaceXxl,
              AppDesignTokens.spaceXxl,
              AppDesignTokens.spaceXxl,
              AppDesignTokens.spaceXxxl,
            ),
            children: [
              _Greeting(greeting: state.greeting, streak: state.streakDays),
              const SizedBox(height: AppDesignTokens.spaceXxl),
              const _TonightCard(),
              const SizedBox(height: AppDesignTokens.spaceXxl),
              SectionHeader(
                title: 'Popular games',
                onSeeAll: () => context.go('/games'),
              ),
              const SizedBox(height: AppDesignTokens.spaceSm),
              _PopularRow(games: games),
              const SizedBox(height: AppDesignTokens.spaceXxl),
              _ScienceCard(quote: state.quote),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.streak});

  final String greeting;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good evening', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppDesignTokens.spaceXs),
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: AppDesignTokens.letterSpacingTight,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          label: '$streak day streak',
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surface,
                  border: Border.all(color: colors.primary.withValues(alpha: .55)),
                ),
                child: Text(
                  '\u{1F525} $streak',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceSm),
              Text('Day streak', style: TextStyle(color: colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-bleed "Spice up your connection" hero. Sizes itself to the
/// artwork's own aspect ratio (instead of a fixed height) so the image is
/// never stretched or cropped on any side: whatever the artwork's real
/// proportions are, the card's height follows them exactly.
class _TonightCard extends StatefulWidget {
  const _TonightCard();

  @override
  State<_TonightCard> createState() => _TonightCardState();
}

class _TonightCardState extends State<_TonightCard> {
  static const _heroAsset = 'assets/homescreen/spice_up_your_connection_bg.png';

  // Placeholder ratio matching the card's previous footprint, used only
  // until the artwork's real dimensions resolve (avoids a layout jump).
  double _aspectRatio = 328 / 296;
  ImageStream? _stream;
  late final ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(_onImage, onError: _onImageError);
  }

  void _onImage(ImageInfo info, bool _) {
    final height = info.image.height;
    if (height == 0) return;
    final ratio = info.image.width / height;
    // ImageStream.addListener() calls this *synchronously* when the image
    // is already in the global imageCache (e.g. every widget test after
    // the first one that resolves this asset). Deferring to a microtask
    // guarantees setState always runs after the current
    // build/didChangeDependencies pass finishes, instead of risking
    // "setState() called during build" when this fires synchronously.
    scheduleMicrotask(() {
      if (!mounted || ratio == _aspectRatio) return;
      setState(() => _aspectRatio = ratio);
    });
  }

  // Falls back to the placeholder ratio (and the Image.asset errorBuilder's
  // gradient) instead of letting a decode failure surface as an unhandled
  // FlutterError.
  void _onImageError(Object exception, StackTrace? stackTrace) {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(_heroAsset).resolve(
      createLocalImageConfiguration(context),
    );
    if (stream.key != _stream?.key) {
      _stream?.removeListener(_listener);
      _stream = stream..addListener(_listener);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AspectRatio(
      // The box's shape now always matches the artwork's native shape, so
      // BoxFit.cover below never has to crop anything to fill it — every
      // edge of the image stays fully visible, edge to edge.
      aspectRatio: _aspectRatio,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius),
          border: Border.all(color: colors.primary.withValues(alpha: .35)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _heroAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF371122), Color(0xFF1B101C)],
                  ),
                ),
              ),
            ),
            // Bottom-left scrim so the CTA stays legible over any artwork.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xB3000000), Color(0x00000000)],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppDesignTokens.spaceXxl),
                // No fixed width here: FilledButton.icon's row already
                // sizes to MainAxisSize.min, so the smaller padding/icon
                // below are what shrink it (~18% vs. the old 168px-wide
                // button) without risking a RenderFlex overflow at wider
                // text scales.
                child: FilledButton.icon(
                  // Routes straight into the Creative Connections flow
                  // rather than the generic Games hub, matching what this
                  // card actually promises ("spice up your connection").
                  onPressed: () => context.push('/home/conversation'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.spaceMd,
                      vertical: AppDesignTokens.spaceSm,
                    ),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text("Let's play"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.games});

  final List<GameCatalogEntry> games;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 174,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: games.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppDesignTokens.spaceMd),
      itemBuilder: (_, index) => _PopularTile(game: games[index]),
    ),
  );
}

class _PopularTile extends StatelessWidget {
  const _PopularTile({required this.game});

  final GameCatalogEntry game;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final title = game.id == 'lustful_rolls' ? 'Love Dice' : game.title;
    return Semantics(
      button: true,
      label: 'Open $title',
      child: InkWell(
        key: ValueKey('popular-${game.id}'),
        onTap: () => context.push(game.route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 118,
          padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.spaceSm,
            AppDesignTokens.spaceSm,
            AppDesignTokens.spaceSm,
            AppDesignTokens.spaceMd,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  game.art,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    game.fallbackIcon,
                    size: 58,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spaceSm),
              Text(title, textAlign: TextAlign.center, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScienceCard extends StatelessWidget {
  const _ScienceCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.spaceXl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology_outlined, color: colors.primary, size: 40),
          const SizedBox(width: AppDesignTokens.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Science says',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spaceXs),
                Text(quote, style: TextStyle(color: colors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textSecondary),
        ],
      ),
    );
  }
}
