# Phase 4.5 — Game Experience Layer

**This is a sub-plan of `docs/planning/VELOURA_BUILD_PLAN.md`. It is not a separate plan.**
It slots into the master build plan as **Phase 4.5**, between Phase 4 (Advanced Modules) and Phase 5
(Daily Challenge). Follow the master plan top to bottom; when you reach 4.5, work through the
sub-phases in this folder in order, then continue to Phase 5.

---

## 1. Why this phase exists

Phases 2–4 built **working engines with real content**: Dice, Truth or Dare (500 items), Challenge
Cards (256), Conversation Starters (320), and Roleplay. Phase 3.5 makes the dice *render* like real
dice.

What none of those phases did is make the games **feel** like a premium product. The shipped screens
are functional but text-heavy: a play surface carrying a settings toggle, a locked premium row, a
duplicated result line, and a history list all at once. Device review of the Dice screen found the
result printed twice, three secondary controls below the primary action, and no indication that two
people are playing.

Phase 4.5 is the **presentation layer** that fixes that across every game:

- one shared game shell, so every game looks like it belongs to the same app
- a two-player session, so both players are visible and turns alternate
- a signature hero interaction per game (thrown dice, card fan, spinning wheel, flicked dial, pulse ring)
- a hard cognitive-load contract that keeps play surfaces clean

## 2. What this phase is NOT

- **Not new content — with exactly one authorised exception.** The packs from Phase 3 and 4 are reused
  as-is. Where a new UI needs grouping (for example three intensity decks), it *derives* that grouping
  from the existing `Difficulty` enum and categories. See D-9 in the master plan.
  The exception is **4.5.5 Creative Positions**, which ships a closed 36-position pack because
  `lib/features/positions/` is an empty stub and there is nothing to reuse. That is ADR **D-10**;
  no other sub-phase may add content.
- **Not a rewrite of engines.** Controllers, repositories, models, Hive boxes, favourites, history and
  premium gating from earlier phases are untouched unless a sub-phase explicitly says otherwise.
- **Not a second dice renderer.** Phase 3.5 owns the cube. Sub-phase 4.5.2 owns the screen *around*
  the cube and must not reimplement it.
- **Not a second spin implementation.** 4.5.5 creates `lib/core/spin/` as the one spin engine (solver,
  velocity mapping, tick haptics, wobble, reduce-motion path). Spin the Bottle consumes it. Nobody
  writes a third one.

## 3. Sub-phase order

| Sub-phase | File | Depends on |
|---|---|---|
| 4.5.0 | `4.5.0_DESIGN_SYSTEM.md` — read-only reference, no code | — |
| 4.5.1 | `4.5.1_SHELL_SESSION_HUB.md` — game tokens, `GameShell`, 2-player session, Games hub grid | Phase 1 |
| 4.5.2 | `4.5.2_DICE_SCREEN.md` — Lustful Rolls screen: board, turn, result sheet | 4.5.1 + **Phase 3.5 merged** |
| 4.5.3 | `4.5.3_TRUTH_OR_DARE_WHEEL.md` — pinwheel spin over the existing T/D pack | 4.5.1 + Phase 3.1 |
| 4.5.4 | `4.5.4_CARD_CHALLENGE_FAN.md` — 3-card fan + flip over the existing challenge pack | 4.5.1 + Phase 3.2 |
| 4.5.5 | `4.5.5_CREATIVE_POSITIONS.md` — shared spin engine, position dial, held reveal, beat rail | 4.5.1 |
| 4.5.6 | `4.5.6_FOLLOW_THE_TEMPO.md` — new pulse-ring game | 4.5.1 |
| 4.5.7 | `4.5.7_PASSIONATE_ROLEPLAY.md` — scene carousel → role assign → beats | 4.5.1 + **Phase 4.1** |
| 4.5.8 | `4.5.8_CONVERSATION_SWIPE_STACK.md` — **deferred**; was 4.5.5 before the redefinition | 4.5.1 + Phase 3.3 |
| — | `AMENDMENTS_TO_LATER_PHASES.md` — what Phases 6, 7 and 9 must pick up | — |

**4.5.1 is blocking.** Everything else sits on its tokens, shell and session model.
After it merges, the remaining sub-phases are independent of each other and can be built in any order
or split across agents — with one ordering note: **4.5.5 should land before Spin the Bottle**, because
it creates the shared spin engine that Spin the Bottle is now specified to consume.

There is deliberately **no "polish" sub-phase** — those items are folded into the master plan's
existing Phases 6, 7 and 9 via `AMENDMENTS_TO_LATER_PHASES.md`, so nothing is duplicated.

One sub-phase = one branch = one PR, e.g. `phase/4.5.1-game-shell`.

## 4. Games catalog after this phase

| Tile | Route | Existing module reused |
|---|---|---|
| Lustful Rolls | `/games/lustful-rolls` | `lib/features/dice` |
| Card Challenge | `/games/card-challenge` | `lib/features/cards` |
| Truth or Dare | `/games/truth-or-dare` | `lib/features/truth_dare` |
| Creative Positions | `/games/creative-connections` | `lib/features/positions` (stub → built in 4.5.5) |
| Follow the Tempo | `/games/follow-the-tempo` | new: `lib/features/tempo` |
| Passionate Roleplay | `/games/passionate-roleplay` | `lib/features/roleplay` |

The fourth tile keeps its `creative_connections` id, route, gradient and art — only the display title
changes to **Creative Positions**. Renaming the route would break deep links and the hub's fixed tile
order for no benefit.

Conversation Starters keeps its existing Phase 3.3 screens and route; its hero swipe-stack treatment
is deferred to 4.5.8.

Position Library stays out of the grid — it remains feature-flagged off for v1 per D-3. 4.5.5 is a
*game* that happens to use position content; it does not unflag that feature.

## 5. The cognitive-load contract (enforced in every sub-phase gate)

1. One hero object, one primary CTA, at most two text blocks per play surface.
2. Zero toggles, zero lists, zero locked/premium rows on a play surface. Settings live in one gear
   sheet; history lives in Profile → Activity.
3. The result is the largest text on screen, shown once, after the animation, in a sheet.
4. Never render the same information twice.
5. Labels are chips and icons, not sentences. Supporting copy is one line or absent.
