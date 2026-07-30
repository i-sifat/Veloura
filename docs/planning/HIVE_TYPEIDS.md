# Hive Type ID Registry

Formal Phase 8 audit completed on 07/30/2026. IDs are permanent after release; never reuse a retired ID.

| ID | Model | Adapter file | Feature | Status |
|---:|---|---|---|---|
| 0 | Reserved foundation range | — | Foundation | Reserved |
| 1 | `DiceRollRecord` | `lib/features/dice/data/dice_roll_record_adapter.dart` | Dice | Active, verified |
| 2 | `Player` | `lib/features/session/data/player_adapter.dart` | Shared session | Active, verified |
| 3 | `GameSession` | `lib/features/session/data/game_session_adapter.dart` | Shared session | Active, verified |
| 4 | Unassigned | — | — | Available |

## Audit result

- No collisions found.
- `HiveAdapterRegistry` now rejects two adapter types claiming the same ID at startup.
- Seeded modules persist JSON/string/map data and claim no adapter IDs.
- `app_metadata` and `content_seed_cache` contain primitive values only and require no adapters.

## Schema strategy

`SchemaMigrationService` stores `schema_version` in `app_metadata` and applies ordered migrations before feature boxes are used. Version 1 is the existing baseline; future schema changes add a new ordered migration and never mutate an old adapter field index.
