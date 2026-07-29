# Hive Type ID Registry

Claim the next free ID before implementing an adapter. IDs are permanent after release; never reuse a retired ID.

| ID | Model | Feature | Status |
|---:|---|---|---|
| 0 | Reserved foundation range | Foundation | Reserved |
| 1 | `DiceRollRecord` | Dice | Active |
| 2 | `Player` | Shared game session | Active |
| 3 | `GameSession` | Shared game session | Active |
| 4 | Unassigned | — | Available |

## Seeded content modules add no type IDs

Truth or Dare, Challenge Cards, Conversation Starters, Roleplay Stories, and Spin the Bottle load immutable seed JSON and persist only string/list/map flags through `shared_preferences` or `game_prefs_box`. They add no Hive adapters and therefore claim no type IDs.

## Rules

- One row per adapter.
- Feature PRs update this file before adding annotated models.
- CI cannot detect semantic collisions, so every phase review must compare adapters to this table.
- Phase 8 performs the formal full registry audit.
