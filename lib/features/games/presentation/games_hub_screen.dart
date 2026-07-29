import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/games/domain/game_catalog.dart';
import 'package:veloura/features/games/presentation/widgets/game_tile.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/features/session/presentation/who_is_playing_sheet.dart';
import 'package:veloura/shared/widgets/game/game_backdrop.dart';
import 'package:veloura/shared/widgets/game/game_preferences_sheet.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Premium six-game discovery grid and shared-session entry point.
class GamesHubScreen extends ConsumerStatefulWidget {
  const GamesHubScreen({super.key});

  @override
  ConsumerState<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends ConsumerState<GamesHubScreen> {
  var _checkedFirstRun = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isPremium = ref.watch(isPremiumProvider);
    if (!_checkedFirstRun && session.hasValue) {
      _checkedFirstRun = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showFirstRun(session.requireValue),
      );
    }

    return Scaffold(
      body: GameBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GameTokens.screenPadH,
                ),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Game preferences',
                        onPressed: () => GamePreferencesSheet.show(context),
                        icon: const Icon(Icons.tune, size: 22),
                      ),
                      IconButton(
                        tooltip: 'How to play',
                        onPressed: _showHowToPlay,
                        icon: const Icon(Icons.lightbulb_outline, size: 22),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Premium arrives in Phase 6.'),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: const LinearGradient(
                              colors: [GameTokens.rose, GameTokens.roseDeep],
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.local_fire_department, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Superhot',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SELECT A GAME',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  key: const ValueKey('games-grid'),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.84,
                  ),
                  itemCount: kGameCatalog.length,
                  itemBuilder: (context, index) {
                    final entry = kGameCatalog[index];
                    return GameTile(
                      entry: entry,
                      locked: entry.isPremium && !isPremium,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFirstRun(GameSession session) async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted ||
        (preferences.getBool('session_players_configured') ?? false)) {
      return;
    }
    await WhoIsPlayingSheet.show(
      context,
      session: session,
      dismissible: false,
    );
    await preferences.setBool('session_players_configured', true);
  }

  void _showHowToPlay() {
    final colors = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GameTokens.sheet,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose a game',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Play one round together, confirm the result, then pass the turn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
