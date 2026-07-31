import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Supplies Home values until profile and activity integration replaces them.
class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState(
    greeting: 'Angelina 💕',
    streakDays: 7,
    featuredTitle: 'Spice up\nyour connection',
    quote: 'Couples who play together, stay together.',
  );
}

/// Home shell controller provider.
final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
