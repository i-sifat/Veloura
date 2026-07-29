import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veloura/core/app_result.dart';
import 'package:veloura/features/session/data/session_repository_hive.dart';
import 'package:veloura/features/session/domain/game_session.dart';
import 'package:veloura/features/session/domain/player.dart';
import 'package:veloura/features/session/domain/session_repository.dart';
import 'package:veloura/services/storage_service.dart';

const _youColor = 0xFFFF4D6D;
const _partnerColor = 0xFF8E4BD1;

/// Session persistence dependency.
final sessionRepositoryProvider = FutureProvider<SessionRepository>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return SessionRepositoryHive(await storage.box<GameSession>('session_box'));
});

/// Creates stable local identifiers without adding a UUID dependency.
String newPlayerId(String seed) =>
    '${seed.toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}';

/// Coordinates shared player names and turn progression.
class SessionController extends AsyncNotifier<GameSession> {
  late SessionRepository _repository;

  @override
  Future<GameSession> build() async {
    _repository = await ref.watch(sessionRepositoryProvider.future);
    final result = await _repository.load();
    return switch (result) {
      AppSuccess<GameSession?>(:final value) => value ?? _defaults(),
      AppFailure<GameSession?>(:final message) => throw StateError(message),
    };
  }

  GameSession _defaults() => GameSession(
    a: Player(id: newPlayerId('you'), name: 'You', colorValue: _youColor),
    b: Player(
      id: newPlayerId('partner'),
      name: 'Partner',
      colorValue: _partnerColor,
    ),
    activeIndex: 0,
    startedAt: DateTime.now(),
  );

  Future<void> setPlayers({
    required String nameA,
    required int colorA,
    required String nameB,
    required int colorB,
  }) async {
    final current = state.asData?.value ?? _defaults();
    final updated = GameSession(
      a: current.a.copyWith(name: _clean(nameA, 'You'), colorValue: colorA),
      b: current.b.copyWith(name: _clean(nameB, 'Partner'), colorValue: colorB),
      activeIndex: 0,
      startedAt: current.startedAt,
    );
    await _persist(updated);
  }

  Future<void> nextTurn() async {
    final current = state.asData?.value;
    if (current != null) await _persist(current.advanced());
  }

  Future<void> resetTurns() async {
    final current = state.asData?.value;
    if (current != null) await _persist(current.copyWith(activeIndex: 0));
  }

  Future<void> _persist(GameSession value) async {
    final result = await _repository.save(value);
    switch (result) {
      case AppSuccess<void>():
        state = AsyncData(value);
      case AppFailure<void>(:final message, :final cause):
        state = AsyncError(message, StackTrace.fromString('$cause'));
    }
  }

  String _clean(String value, String fallback) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length <= 12 ? trimmed : trimmed.substring(0, 12);
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, GameSession>(
      SessionController.new,
    );

/// Read-only current session projection for shared widgets.
final gameSessionStateProvider = Provider<AsyncValue<GameSession>>(
  (ref) => ref.watch(sessionControllerProvider),
);
