import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:veloura/features/dice/domain/dice_roll_record.dart';
import 'package:veloura/features/dice/presentation/dice_controller.dart';
import 'package:veloura/features/dice/presentation/dice_state.dart';
import 'package:veloura/features/dice/presentation/widgets/word_die.dart';
import 'package:veloura/shared/widgets/empty_state.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/glass_card.dart';
import 'package:veloura/shared/widgets/loading_shimmer.dart';
import 'package:veloura/theme/app_colors.dart';

/// Animated, shake-enabled Dice game.
class DiceScreen extends ConsumerStatefulWidget {
  const DiceScreen({super.key});

  @override
  ConsumerState<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends ConsumerState<DiceScreen> {
  StreamSubscription<AccelerometerEvent>? _shakeSubscription;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  final _actionDieKey = GlobalKey<WordDieState>();
  final _bodyDieKey = GlobalKey<WordDieState>();
  final _extraDieKey = GlobalKey<WordDieState>();

  @override
  void initState() {
    super.initState();
    _shakeSubscription = accelerometerEventStream().listen(
      _onAcceleration,
      onError: (_) {},
    );
  }

  void _onAcceleration(AccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final now = DateTime.now();
    if (magnitude > 22 &&
        now.difference(_lastShake) > const Duration(seconds: 2)) {
      _lastShake = now;
      unawaited(_rollAll());
    }
  }

  /// Rolls the shared record, then plays every enabled die's tumble
  /// animation in lockstep, each forced onto the word from that record so
  /// the cubes and the persisted result always agree.
  Future<void> _rollAll() async {
    final diceValue = ref.read(diceControllerProvider).asData?.value;
    if (diceValue == null || diceValue.status == DiceRollStatus.rolling) return;
    await HapticFeedback.mediumImpact();
    // Duration.zero: the *visual* roll duration now lives entirely in each
    // WordDie's own tumble animation, not an artificial controller delay.
    await ref.read(diceControllerProvider.notifier).roll(
      animationDuration: Duration.zero,
    );
    final record = ref.read(diceControllerProvider).asData?.value.current;
    if (record == null) return;
    final rolls = <Future<String>>[
      _actionDieKey.currentState?.roll(result: record.action) ??
          Future.value(record.action),
      _bodyDieKey.currentState?.roll(result: record.body) ??
          Future.value(record.body),
      if (record.extra != null)
        _extraDieKey.currentState?.roll(result: record.extra!) ??
            Future.value(record.extra),
    ];
    await Future.wait(rolls);
    await HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    unawaited(_shakeSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dice = ref.watch(diceControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dice')),
      body: dice.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(height: 280),
        ),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(diceControllerProvider),
        ),
        data: (state) => _DiceBody(
          state: state,
          onRollAll: _rollAll,
          actionDieKey: _actionDieKey,
          bodyDieKey: _bodyDieKey,
          extraDieKey: _extraDieKey,
        ),
      ),
    );
  }
}

class _DiceBody extends ConsumerWidget {
  const _DiceBody({
    required this.state,
    required this.onRollAll,
    required this.actionDieKey,
    required this.bodyDieKey,
    required this.extraDieKey,
  });

  final DiceState state;
  final Future<void> Function() onRollAll;
  final GlobalKey<WordDieState> actionDieKey;
  final GlobalKey<WordDieState> bodyDieKey;
  final GlobalKey<WordDieState> extraDieKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(diceControllerProvider.notifier);
    final premium = ref.watch(isPremiumProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        _DiceTray(
          state: state,
          actionDieKey: actionDieKey,
          bodyDieKey: bodyDieKey,
          extraDieKey: extraDieKey,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: state.status == DiceRollStatus.rolling ? null : onRollAll,
          icon: const Icon(Icons.casino),
          label: Text(
            state.status == DiceRollStatus.rolling ? 'Rolling…' : 'Roll dice',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap Roll or shake your phone',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Add intensity / time die'),
          subtitle: const Text('Roll three dice instead of two'),
          value: state.useThirdDie,
          onChanged: controller.setThirdDie,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(premium ? Icons.tune : Icons.lock_outline),
          title: const Text('Custom dice faces'),
          subtitle: Text(
            premium
                ? (state.customFacesEnabled
                      ? 'Custom set active'
                      : 'Create your own set')
                : 'Premium feature',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => premium
              ? _showCustomFaces(context, ref, state)
              : _showPremiumMessage(context),
        ),
        const SizedBox(height: 24),
        Text('Roll history', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (state.history.isEmpty)
          const EmptyState(
            title: 'No rolls yet',
            message: 'Give it a shake to create your first combination.',
            icon: Icons.casino_outlined,
          )
        else
          ...state.history.map(
            (record) => _HistoryTile(
              record: record,
              onTap: () => controller.selectRecord(record),
              onFavorite: () => controller.toggleFavorite(record.id),
            ),
          ),
      ],
    );
  }
}

/// Themed tray holding the two (or three) word cubes side by side.
class _DiceTray extends StatelessWidget {
  const _DiceTray({
    required this.state,
    required this.actionDieKey,
    required this.bodyDieKey,
    required this.extraDieKey,
  });

  final DiceState state;
  final GlobalKey<WordDieState> actionDieKey;
  final GlobalKey<WordDieState> bodyDieKey;
  final GlobalKey<WordDieState> extraDieKey;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final record = state.current;
    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.primary.withValues(alpha: 0.16),
                  colors.secondary.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                WordDie(
                  key: actionDieKey,
                  wordPool: state.actions,
                  initialWord: record?.action,
                ),
                WordDie(
                  key: bodyDieKey,
                  wordPool: state.bodies,
                  initialWord: record?.body,
                ),
                if (state.useThirdDie)
                  WordDie(
                    key: extraDieKey,
                    wordPool: state.extras,
                    initialWord: record?.extra,
                  ),
              ],
            ),
          ),
          if (state.status != DiceRollStatus.rolling && record != null) ...[
            const SizedBox(height: 20),
            Text(
              record.summary,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.record,
    required this.onTap,
    required this.onFavorite,
  });

  final DiceRollRecord record;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        record.summary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_formatTime(record.createdAt)),
      trailing: IconButton(
        tooltip: record.favorite ? 'Remove favorite' : 'Favorite roll',
        onPressed: onFavorite,
        icon: Icon(record.favorite ? Icons.favorite : Icons.favorite_border),
      ),
    );
  }

  static String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} · $hour:$minute $suffix';
  }
}

Future<void> _showPremiumMessage(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Create your own dice'),
    content: const Text(
      'Custom face sets are included with Veloura Premium. '
      'The full upgrade flow arrives in Phase 6.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Got it'),
      ),
    ],
  ),
);

Future<void> _showCustomFaces(
  BuildContext context,
  WidgetRef ref,
  DiceState state,
) async {
  final actions = TextEditingController(text: state.actions.join(', '));
  final bodies = TextEditingController(text: state.bodies.join(', '));
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Custom dice faces'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: actions,
            decoration: const InputDecoration(
              labelText: 'Actions, comma separated',
            ),
          ),
          TextField(
            controller: bodies,
            decoration: const InputDecoration(
              labelText: 'Places, comma separated',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await ref.read(diceControllerProvider.notifier).saveCustomFaces(
              actions.text.split(','),
              bodies.text.split(','),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  actions.dispose();
  bodies.dispose();
}
