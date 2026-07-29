# Veloura — Games Experience Overhaul

Author: Planning Pax · Created: 2026-07-29 · Repo: `i-sifat/Veloura`

This folder is the complete, self-contained plan for rebuilding the Games experience.

## How to use this folder

1. Read `00_DESIGN_SYSTEM.md` once. It is the single source of truth for every color, size,
   radius, duration, curve and haptic used by every phase.
2. Implement **one phase file per pull request**, in numeric order. Each phase file is a
   standalone prompt: it repeats the non-negotiable rules, lists exactly which files to create
   and modify, gives pixel-level specs, and ends with acceptance criteria + a done checklist.
3. Do not start Phase N+1 until Phase N is merged. Later phases assume earlier ones exist.
4. Nothing already shipped gets deleted unless a phase file explicitly says so. The end state is
   the previous app **plus** this overhaul.

## Files

| File | Scope |
|---|---|
| `00_DESIGN_SYSTEM.md` | Tokens, palette, type scale, motion, haptics, shared widgets, assets |
| `PHASE_1_FOUNDATION.md` | Design tokens, shared game shell, 2-player session, Games hub grid |
| `PHASE_2_LUSTFUL_ROLLS.md` | 3D dice thrown on a board (replaces the current Dice screen) |
| `PHASE_3_CARD_CHALLENGE.md` | 3-card fan + flip reveal + 45 seeded prompts |
| `PHASE_4_TRUTH_OR_DARE.md` | 10-petal pinwheel spin + 24 seeded prompts |
| `PHASE_5_CREATIVE_CONNECTIONS.md` | Swipe-stack question game (reskin of conversation_starters) |
| `PHASE_6_FOLLOW_THE_TEMPO.md` | New pacing game with a pulsing ring |
| `PHASE_7_PASSIONATE_ROLEPLAY.md` | Scene picker → role assign → beat-by-beat play (premium) |
| `PHASE_8_POLISH_AND_HARDENING.md` | Premium gating, reduce-motion, stats, golden tests, perf pass |

## Phase map

```
Phase 1  Foundation           ← blocking. Everything depends on it.
  ├── Phase 2  Lustful Rolls        (3D dice)
  ├── Phase 3  Card Challenge       (card fan)
  ├── Phase 4  Truth or Dare        (wheel)
  ├── Phase 5  Creative Connections (swipe stack)
  ├── Phase 6  Follow the Tempo     (pulse ring, new module)
  └── Phase 7  Passionate Roleplay  (scenes, premium)
Phase 8  Polish & hardening   ← after 2–7 are merged.
```

Phases 2–7 are independent of each other. They can be built in any order after Phase 1, but the
listed order ships the highest-value screens first.

## Product decisions already locked (do not re-litigate)

- The dice game is a **two-die action composer** for two players, not a board game. Die A = verb,
  Die B = target. One throw produces one instruction: `Anna → Daniel: "Hold their neck"`.
  It is renamed **Lustful Rolls**.
- **The player never makes two selections.** One tap throws both cubes at once. Who performs the
  action is not chosen either — it alternates by turn.
- The 3D cube is **pure Flutter** (6 transformed faces + perspective + back-face culling).
  No 3D engine, no physics engine, no WebView, no Rive.
- Every game shares one `GameSession` (two named players, active turn) so both players are always
  visible. This is why the current app only shows one player: there is no session model.
- **Cognitive-load contract** (enforced in every phase): one hero object, one primary CTA, at most
  two text blocks, and zero toggles / lists / locked rows on a play surface. Settings live in a
  gear sheet. History lives in Profile → Activity.
