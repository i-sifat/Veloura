import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/features/daily/presentation/daily_controller.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';

/// Read model for the Home discovery shell.
class HomeState {
  const HomeState({
    required this.greeting,
    required this.streakDays,
    required this.featuredTitle,
    required this.quote,
  });

  final String greeting;
  final int streakDays;
  final String featuredTitle;
  final String quote;
}

/// Supplies Home values. The greeting uses the real onboarding name for the
/// "You" player (same session source Profile reads nameA/nameB from),
/// falling back to the session default ("You") until onboarding sets one.
class HomeController extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final session = await ref.watch(sessionControllerProvider.future);
    // Real consecutive-days streak from the daily challenge, computed live
    // from the completion history (not install/open days, not hardcoded).
    // Falls back to 0 if the daily source isn't ready yet.
    final daily = ref.watch(dailyControllerProvider);
    return HomeState(
      greeting: '${session.a.name} \u{1F495}',
      streakDays: daily.asData?.value.streak ?? 0,
      featuredTitle: 'Spice up\nyour connection',
      quote: 'Couples who play together, stay together.',
    );
  }
}

/// Home shell controller provider.
final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeState>(HomeController.new);
