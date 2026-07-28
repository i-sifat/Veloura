# Veloura Architecture

Veloura is a local-first Flutter application organized by feature and governed by shared contracts.

## Layers

Each feature owns three layers:

1. `presentation/` — widgets and Riverpod controllers.
2. `domain/` — immutable models and repository interfaces.
3. `data/` — Hive-backed implementations and seed data.

Dependencies point inward: presentation → domain ← data. Widgets never access Hive directly.

## Shared structure

- `lib/core/` — `AppResult`, repository contracts, and reusable data boundaries.
- `lib/config/` — app routing and navigation shell.
- `lib/theme/` — Material 3 theme and semantic palette.
- `lib/models/` — stable cross-feature domain contracts.
- `lib/services/` — storage, adapter registration, and SDK-neutral service boundaries.
- `lib/shared/widgets/` — reusable UI primitives.
- `lib/features/` — isolated product modules, each with a `provider.dart` barrel.

## State management

Riverpod is the only application state-management system. Providers follow these names:

- `xxxRepositoryProvider` for data dependencies.
- `xxxControllerProvider` for user-flow coordinators.
- `xxxStateProvider` for read-only projections.

Use `Notifier` for synchronous initial state and `AsyncNotifier` when initialization requires I/O. Raw `setState` is limited to widget-local animation controllers.

## Navigation

`go_router` owns routing. A `StatefulShellRoute.indexedStack` preserves state across Home, Games, Daily, Favorites, and Profile. The centered FAB slot is reserved for the Phase 9 random-game action.

## Persistence

Hive CE is wrapped by `StorageService`. Every module owns its box, adapter registration, and type IDs. Claim IDs in `docs/planning/HIVE_TYPEIDS.md` before adding an adapter. Repositories convert storage failures into `AppResult`; exceptions do not cross into presentation.

## Content contract

All playable content implements `ContentItem` and is accessed through `ContentRepository<T extends ContentItem>`. The contract of record is copied in `docs/planning/CONTRACT_SNAPSHOT.md`. Changing it requires updating that snapshot and reviewing every downstream feature.

## Design system

Veloura is dark-first Material 3. Semantic colors live in `AppColors`, typography uses Poppins, and shared surfaces/actions come from `lib/shared/widgets/`. Light palette values are reserved but light mode is not exposed in v1.

## Generated source

Generated `*.g.dart` and `*.freezed.dart` files are committed. Run:

```sh
dart run build_runner build --delete-conflicting-outputs
```

CI verifies dependency resolution, the committed lockfile, analysis, tests, and an Android release build.
