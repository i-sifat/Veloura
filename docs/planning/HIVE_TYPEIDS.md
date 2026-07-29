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

Truth or Dare, Challenge Cards, Conversation Starters, Roleplay Stories, Spin the Bottle, and Creative Positions load immutable seed JSON and persist only string/list/map flags through `shared_preferences` or `game_prefs_box`. They add no Hive adapters and therefore claim no type IDs.

Creative Positions (Phase 4.5.5) is explicitly included above: its round state, heat level and `usedIds` set are in-memory for the life of the session, and its consent + seen-id flags go to `game_prefs_box`. **It must not claim id 4.**

## Rules

- One row per adapter.
- Feature PRs update this file before adding annotated models.
- CI cannot detect semantic collisions, so every phase review must compare adapters to this table.
- Phase 8 performs the formal full registry audit.
