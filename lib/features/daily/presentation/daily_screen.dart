import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/daily/domain/daily_challenge.dart';
import 'package:veloura/features/daily/domain/daily_selector.dart';
import 'package:veloura/features/daily/presentation/daily_controller.dart';
import 'package:veloura/shared/widgets/error_state.dart';
import 'package:veloura/shared/widgets/game/game_backdrop.dart';
import 'package:veloura/shared/widgets/game/primary_cta.dart';
import 'package:veloura/theme/app_colors.dart';
import 'package:veloura/theme/game_tokens.dart';

/// Deterministic daily challenge, streak, history, and reminder surface.
class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyControllerProvider);
    return Scaffold(
      body: GameBackdrop(
        child: SafeArea(
          child: daily.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: '$error',
              onRetry: () => ref.invalidate(dailyControllerProvider),
            ),
            data: (state) => _DailyBody(state: state),
          ),
        ),
      ),
    );
  }
}

class _DailyBody extends ConsumerWidget {
  const _DailyBody({required this.state});

  final DailyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY CONNECTION',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.4,
                            color: colors.secondary,
                          ),
                        ),
                        Text(
                          'A moment for today',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Daily reminder',
                    onPressed: () => _ReminderSheet.show(context, ref, state.reminder),
                    icon: Icon(
                      state.reminder.enabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _StreakStrip(
                streak: state.streak,
                balance: state.rewardBalance,
              ),
              const SizedBox(height: 20),
              _DailyChallengeCard(challenge: state.challenge),
              const SizedBox(height: 16),
              PrimaryCta(
                label: state.completedToday
                    ? 'Completed today'
                    : 'Complete · +${DailyController.completionReward} sparks',
                icon: state.completedToday ? Icons.check_circle : Icons.auto_awesome,
                onPressed: state.completedToday
                    ? null
                    : ref.read(dailyControllerProvider.notifier).completeToday,
              ),
              const SizedBox(height: 28),
              _CalendarCard(state: state),
              const SizedBox(height: 12),
              Text(
                'Streak rule: a missed calendar day resets the count. No hidden freezes or currency are spent.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakStrip extends StatelessWidget {
  const _StreakStrip({required this.streak, required this.balance});

  final int streak;
  final int balance;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _MetricTile(
          icon: Icons.local_fire_department,
          label: '$streak day streak',
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _MetricTile(icon: Icons.auto_awesome, label: '$balance sparks'),
      ),
    ],
  );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: GameTokens.glassStrong,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GameTokens.hairline),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: GameTokens.roseLight),
        const SizedBox(width: 8),
        Flexible(child: Text(label, maxLines: 1)),
      ],
    ),
  );
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 260),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: GameTokens.creativeConnections,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0x1AFFFFFF)),
      boxShadow: const [GameTokens.tileShadow],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SourceChip(source: challenge.source),
            const Spacer(),
            if (challenge.estimatedMinutes case final minutes?)
              Text(
                '$minutes min',
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        const SizedBox(height: 34),
        Text(
          challenge.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          challenge.prompt,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final DailyChallengeSource source;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: GameTokens.glassStrong,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      switch (source) {
        DailyChallengeSource.ritual => 'RITUAL',
        DailyChallengeSource.truthDare => 'TRUTH OR DARE',
        DailyChallengeSource.challengeCard => 'CHALLENGE',
        DailyChallengeSource.conversation => 'CONVERSATION',
      },
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    ),
  );
}

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard({required this.state});

  final DailyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = state.displayedMonth;
    final firstWeekday = DateTime(month.year, month.month).weekday;
    final days = DateTime(month.year, month.month + 1, 0).day;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameTokens.glassStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GameTokens.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => ref
                    .read(dailyControllerProvider.notifier)
                    .changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_monthName(month.month)} ${month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => ref
                    .read(dailyControllerProvider.notifier)
                    .changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(child: Center(child: Text(label))),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: firstWeekday - 1 + days,
            itemBuilder: (context, index) {
              final dayNumber = index - firstWeekday + 2;
              if (dayNumber < 1) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, dayNumber);
              final completed = state.completionDates.contains(dateOnly(date));
              return Semantics(
                label: '$dayNumber ${completed ? 'completed' : 'not completed'}',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: completed ? GameTokens.rose : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed ? GameTokens.rose : GameTokens.hairline,
                    ),
                  ),
                  child: Center(child: Text('$dayNumber')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.ref, required this.initial});

  final WidgetRef ref;
  final DailyReminderSettings initial;

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    DailyReminderSettings initial,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: GameTokens.sheet,
    builder: (_) => _ReminderSheet(ref: ref, initial: initial),
  );

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late bool _enabled = widget.initial.enabled;
  late TimeOfDay _time = TimeOfDay(
    hour: widget.initial.hour,
    minute: widget.initial.minute,
  );
  var _saving = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Daily reminder', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
          title: const Text('Remind us'),
          subtitle: const Text('Permission is only requested when enabled.'),
        ),
        ListTile(
          enabled: _enabled,
          leading: const Icon(Icons.schedule),
          title: const Text('Reminder time'),
          trailing: Text(_time.format(context)),
          onTap: () async {
            final selected = await showTimePicker(
              context: context,
              initialTime: _time,
            );
            if (selected != null) setState(() => _time = selected);
          },
        ),
        const SizedBox(height: 16),
        PrimaryCta(
          label: 'Save reminder',
          busy: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    ),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    final settings = widget.initial.copyWith(
      enabled: _enabled,
      hour: _time.hour,
      minute: _time.minute,
    );
    final saved = await widget.ref
        .read(dailyControllerProvider.notifier)
        .updateReminder(settings);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are off. You can enable them in device settings.'),
        ),
      );
    }
  }
}

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
