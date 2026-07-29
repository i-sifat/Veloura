import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read model for the Phase 1 Home shell.
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

/// Supplies mock Home values until integration replaces them in Phase 9.
class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState(
    greeting: 'Make time for each other',
    streakDays: 0,
    featuredTitle: 'A little spark for tonight',
    quote: 'Connection grows in the moments you choose together.',
  );
}

/// Home shell controller provider.
final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
