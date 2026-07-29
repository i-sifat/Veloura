# Phase 8 — Polish and hardening

Runs after Phases 2–7 and Phase 9 are merged. This is where the app stops looking good in screenshots and starts feeling premium in the hand.

Read `00_DESIGN_SYSTEM.md` first. Depends on: **Phase 1 (Foundation)**.

## 0. Non-negotiable rules (apply to this entire phase)

1. **Scope discipline.** Implement only what this phase file lists. Do not touch other phases'
   files. One phase = one pull request.
2. **Nothing is deleted unless this file says so.** Existing features keep working. The end state
   is the previous app plus this phase.
3. **Architecture** (`ARCHITECTURE.md` is binding):
   - Riverpod is the only state management. Provider names: `xxxRepositoryProvider` for data,
     `xxxControllerProvider` for flow coordinators, `xxxStateProvider` for read-only projections.
   - `Notifier` for synchronous initial state, `AsyncNotifier` when init needs I/O.
   - Feature layers: `presentation/` → `domain/` ← `data/`. Dependencies point inward.
   - Widgets never touch Hive. Repositories wrap Hive and return `AppResult`; exceptions never
     reach the presentation layer.
   - Every feature exposes its providers through its `provider.dart` barrel.
4. **No new dependencies** unless this phase file names one explicitly.
5. **No magic numbers.** Every color, size, radius, duration, curve and haptic comes from
   `GameTokens` (see `00_DESIGN_SYSTEM.md`) or `AppColors`. If a value is missing, add it to
   `GameTokens` and note the addition in the PR description.
6. **Hive discipline.** Reserve every new typeId in `docs/planning/HIVE_TYPEIDS.md` *before*
   writing adapters. Register boxes and adapters in `StorageService`. Seed data once and stamp it
   with a `seedVersion`; never re-seed on every launch.
7. **Randomness is injected.** Use a `randomProvider` exposing `Random` so tests can seed it.
   Never call `Random()` inside `build()`.
8. **Performance.** Wrap every animated hero widget in a `RepaintBoundary`. Animate the hero only,
   never the whole screen. Use `AnimatedBuilder` scoped to the smallest possible subtree.
9. **Accessibility / reduce motion.** If `MediaQuery.of(context).disableAnimations` is true,
   replace every long animation with a 220ms fade to the resolved state. Minimum tap target 44x44.
   Every icon-only button gets a `Semantics` label.
10. **Cognitive-load contract.** Each play screen shows: one hero object, one primary CTA, at most
    two text blocks. Zero toggles, zero lists, zero locked/premium rows on a play surface.
    Never render the same information twice. Settings → gear sheet. History → Profile → Activity.
11. **Copy rules.** Second person, imperative, one action per line, 12 words maximum. Sensory and
    suggestive, never clinical or crude. Uppercase only for labels and chips, never for body copy.
12. **Definition of done.** `dart format .` applied, `flutter analyze` reports zero new issues,
    `flutter test` green, new tests added for the logic this phase introduces, and screenshots at
    390x844 and 360x800 attached to the PR. Commit style: `feat(games): ...`, `refactor(games): ...`,
    `docs: ...`.

---

## 1. Premium gating pass

- One `premiumStateProvider` is the single source of truth. No feature checks entitlement on its own.
- Gated surfaces: Passionate Roleplay scenes 3–5 · Superhot deck · Superhot Roulette prompts ·
  Spin the Bottle `hot` prompts · custom dice faces. Everything else is free.
- Every gated tap routes to the same paywall route with a `source` argument for analytics
  (`source: 'card_challenge_superhot'` etc.). No dead taps anywhere.
- Locked states use `PremiumLockBadge` only. Never grey out content, never show a locked list row on
  a play surface.

## 2. Reduce motion + accessibility audit

- Verify every phase's `disableAnimations` path: dice at rest, wheel unrotated, cards crossfaded,
  ring colour-pulsing, beats crossfading, bottle already at its resolved angle with no wobble.
- All icon-only buttons have `Semantics` labels; all tap targets ≥ 44x44. The bottle's drag hit box
  is at least 44 wide and the CTA path must remain fully usable without the flick gesture.
- Text scaling: verify at `textScaleFactor` 1.3. `resultHero` and `heroDisplay` must use
  `FittedBox(BoxFit.scaleDown)` so they never overflow.
- Contrast: every text colour on its actual background must clear 4.5:1 for body and 3:1 for
  display sizes. Fix by darkening the scrim, never by adding a text shadow.

## 3. Sound (optional, default OFF)

- Only if a lightweight audio package is already in `pubspec.yaml`. If not, **skip sound entirely**
  and leave the pref row disabled with "Coming soon" — do not add a dependency for this.
- If shipped: dice contact click, card flip whoosh, wheel tick, bottle glass scrape, tempo
  metronome. All ≤ 200ms, all respecting the Sound pref and the OS silent switch.

## 4. Stats and history wiring

- Every game writes a `GamePlayEvent { gameId, at, resultLabel }` through one shared repository.
  Spin the Bottle doubles write one event whose label names both zones.
- Profile → Activity renders the unified history (this is where the old dice roll list now lives).
- `statistics` module reads counts per game; `achievements` unlocks stay driven off the same events.
- Favourites: the heart in any result sheet writes to one favourites store keyed by
  `gameId + resultId`, surfaced in the existing Favorites tab.

## 5. Test hardening

- Golden tests: Games hub (including the wide tile) · dice at t = 0.30/0.60/1.00 · card back and
  front per deck · wheel at rest and mid-spin · bottle at rest, mid-spin and landed · scene card.
  Run at 390x844 and 360x800.
- Copy-rule tests across every seed file: word limits, no double questions, no empty strings,
  unique ids, `seedVersion` present.
- Controller tests with a seeded `Random` for every game: no immediate repeats, pool exhaustion
  behaviour, turn advances exactly once per completed round.
- Distribution test for Spin the Bottle: uniform zone landing and ~8% seam doubles over 4000 seeded
  spins.
- Widget tests asserting the cognitive-load contract: each play screen contains exactly one
  `PrimaryCta`, zero `Switch`, zero `ListView`.

## 6. Performance pass

- Profile-mode run of every game on a mid-range Android. Budget: no more than 3 frames over 16ms per
  interaction — including a bottle drag, which must track the thumb without dropped frames.
- Confirm `RepaintBoundary` wraps every animated hero and that no `AnimatedBuilder` rebuilds a
  subtree containing the app bar or CTA.
- Replace any `Opacity` in an animation with `FadeTransition`, and any `Transform` rebuild with
  `AnimatedBuilder` + `Transform` on a cached child.
- Shader warm-up: verify no jank on the first dice throw, first wheel spin and first bottle spin
  after a cold start.

## 7. Documentation

- Update `README.md` (games list + screenshots) and `ARCHITECTURE.md` (new `session`, `games_hub`,
  `follow_the_tempo`, `spin_the_bottle` modules).
- Confirm `docs/planning/HIVE_TYPEIDS.md` and `CONTRACT_SNAPSHOT.md` match the shipped code.
- Add `docs/planning/games_overhaul/DONE.md` listing which phase shipped in which PR.

## 8. Acceptance criteria

- [ ] Every gated surface routes to the paywall with a source tag; zero dead taps.
- [ ] Reduce-motion and textScale 1.3 verified on all seven games.
- [ ] Unified history renders every game's events in Profile → Activity.
- [ ] Golden, copy-rule and distribution tests green in CI.
- [ ] Performance budget met on all seven games.
- [ ] Docs updated; `flutter analyze` zero issues; full `flutter test` green.
