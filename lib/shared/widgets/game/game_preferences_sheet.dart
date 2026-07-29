import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/dice/presentation/dice_controller.dart';
import 'package:veloura/features/premium/provider.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/features/session/presentation/who_is_playing_sheet.dart';
import 'package:veloura/shared/widgets/game/premium_lock_badge.dart';
import 'package:veloura/theme/game_tokens.dart';

/// The single settings surface for all game toggles.
class GamePreferencesSheet extends ConsumerStatefulWidget {
  const GamePreferencesSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const GamePreferencesSheet(),
  );

  @override
  ConsumerState<GamePreferencesSheet> createState() => _GamePreferencesSheetState();
}

class _GamePreferencesSheetState extends ConsumerState<GamePreferencesSheet> {
  var _loading = true;
  var _thirdDie = false;
  var _vibration = true;
  var _sound = false;
  var _soften = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _thirdDie = preferences.getBool('game_third_die') ?? false;
      _vibration = preferences.getBool('game_vibration') ?? true;
      _sound = preferences.getBool('game_sound') ?? false;
      _soften = preferences.getBool('game_soften_decks') ?? false;
      _loading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    await (await SharedPreferences.getInstance()).setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(isPremiumProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      decoration: const BoxDecoration(
        color: GameTokens.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: _loading
            ? const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Game preferences', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _toggle('Third die (intensity / duration)', _thirdDie, (value) {
                    setState(() => _thirdDie = value);
                    _set('game_third_die', value);
                    ref.read(diceControllerProvider.notifier).setThirdDie(value);
                  }),
                  _toggle('Vibration', _vibration, (value) {
                    setState(() => _vibration = value);
                    _set('game_vibration', value);
                  }),
                  _toggle('Sound', _sound, (value) {
                    setState(() => _sound = value);
                    _set('game_sound', value);
                  }),
                  _toggle('Soften decks (hide Superhot)', _soften, (value) {
                    setState(() => _soften = value);
                    _set('game_soften_decks', value);
                  }),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Custom dice faces'),
                    trailing: premium ? const Icon(Icons.chevron_right) : const PremiumLockBadge(),
                    onTap: premium
                        ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Custom face editor opens from Dice.')),
                          )
                        : () => openPremiumPaywall(
                            context,
                            source: 'dice_custom_faces',
                          ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Who's playing?"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final session = ref.read(sessionControllerProvider).asData?.value;
                      if (session != null) {
                        WhoIsPlayingSheet.show(context, session: session);
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) => SizedBox(
    height: 56,
    child: Row(
      children: [
        Expanded(child: Text(title)),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    ),
  );
}
