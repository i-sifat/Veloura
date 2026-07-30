import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloura/features/onboarding/data/onboarding_repository.dart';
import 'package:veloura/features/session/presentation/session_controller.dart';
import 'package:veloura/services/analytics_service.dart';

class OnboardingController extends AsyncNotifier<bool> {
  late OnboardingRepository _repository;

  @override
  Future<bool> build() async {
    _repository = OnboardingRepository(await SharedPreferences.getInstance());
    return _repository.isComplete;
  }

  Future<void> finish({required String nameA, required String nameB}) async {
    final repository = OnboardingRepository(
      await SharedPreferences.getInstance(),
    );
    await ref.read(sessionControllerProvider.future);
    await ref.read(sessionControllerProvider.notifier).setPlayers(
      nameA: nameA,
      colorA: 0xFFFF4D6D,
      nameB: nameB,
      colorB: 0xFF8E4BD1,
    );
    await repository.complete();
    await ref.read(analyticsServiceProvider).track('onboarding_complete');
    state = const AsyncData(true);
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(
      OnboardingController.new,
    );
