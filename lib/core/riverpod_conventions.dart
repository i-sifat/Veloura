/// Riverpod naming and lifecycle conventions used across Veloura.
///
/// * Repositories: `xxxRepositoryProvider`.
/// * Coordinators: `xxxControllerProvider`.
/// * Read-only projections: `xxxStateProvider`.
/// * Use `Notifier` for synchronous state and `AsyncNotifier` when initial state
///   requires I/O.
/// * Widgets call controllers; they never access Hive or repositories directly.
library;
