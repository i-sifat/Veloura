# Hive Type ID Registry

Claim the next free ID before implementing an adapter. IDs are permanent after release; never reuse a retired ID.

| ID | Model | Feature | Status |
|---:|---|---|---|
| 0 | Reserved foundation range | Foundation | Reserved |
| 1 | Unassigned | — | Available |

## Rules

- One row per adapter.
- Feature PRs update this file before adding annotated models.
- CI cannot detect semantic collisions, so every phase review must compare adapters to this table.
- Phase 8 performs the formal full registry audit.
