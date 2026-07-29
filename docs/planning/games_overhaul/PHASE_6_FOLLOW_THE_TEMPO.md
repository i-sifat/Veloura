# Phase 6 — Follow the Tempo: pulse-ring pacing game

A new module. A pulsing ring sets a rhythm and the couple matches it. Three stages, one word of instruction at a time.

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
    two text blocks. Zero toggles, zero lists, zero locked/premium rows on the play surface.
    Never render the same information twice. Settings → gear sheet. History → Profile → Activity.
11. **Copy rules.** Second person, imperative, one action per line, 12 words maximum. Sensory and
    suggestive, never clinical or crude. Uppercase only for labels and chips, never for body copy.
12. **Definition of done.** `dart format .` applied, `flutter analyze` reports zero new issues,
    `flutter test` green, new tests added for the logic this phase introduces, and screenshots at
    390x844 and 360x800 attached to the PR. Commit style: `feat(games): ...`, `refactor(games): ...`,
    `docs: ...`.

---

## 1. Why this game exists

It is the only game in the set with no text to read during play — a pure rhythm/pacing hero. It
carries the "premium, low cognitive load" feel harder than anything else in the app.

## 2. Screen anatomy

```
GameAppBar   leading: home 22 · "Follow the tempo" · info 20
TurnChipBar
Expanded > Center > RepaintBoundary > PulseRing
  outer ring    240 diameter · 4px stroke rose @ 70%
  inner circle  132 diameter · RadialGradient([rose @ 26%, transparent])
  centre label  current instruction · 22/26 w700 uppercase · textHi · TWO WORDS MAX
16
Stage dots     3 dots of 8px, 8 apart — active rose, inactive #FFFFFF @ 24%
16
Footnote       "Match the pulse"   caption textLow   (stage 1 only)
16
PrimaryCta("Start")  →  while running becomes an outlined "Stop" (border 1.5px rose, transparent fill)
bottomCtaInset
```

## 3. `PulseRing` motion

Beat period = `60 / bpm` seconds. Per beat the ring scales `1.00 → 1.14 → 1.00`, spending 35% of the
period expanding (easeOutQuad) and 65% relaxing (easeInQuad). The inner glow opacity tracks the same
curve between 0.18 and 0.42. Drive it from a single `AnimationController` whose duration is reset
when the stage changes — never rebuild the widget per beat.

`lightImpact` on each beat, throttled to a maximum of 2 per second, and muted by the Vibration pref.

## 4. Round design (90 seconds + hold)

```
stage 1   30s   60 bpm    label "SLOW"
stage 2   30s   92 bpm    label "BUILD"
stage 3   30s   128 bpm   label "FASTER"
finale     3s   frozen at max scale, label "HOLD", heavyImpact, ring glow rose @ 55%
```
Each stage also draws one focus word from a small seed list, shown in place of the stage label for
its first 6 seconds: `HANDS · LIPS · NECK · SLOWER · CLOSER · EYES`. After that the stage label
returns. That is the only content in this game.

On finale: `nextTurn()` and open a minimal result sheet — "Round complete" (`resultHero`) +
`PrimaryCta("Again")` + `SecondaryTextButton("Done")`.

## 5. Files

### Create
```
lib/features/follow_the_tempo/domain/tempo_stage.dart     // { int bpm, Duration length, String label }
lib/features/follow_the_tempo/domain/tempo_round.dart     // const kDefaultRound
lib/features/follow_the_tempo/presentation/follow_the_tempo_screen.dart
lib/features/follow_the_tempo/presentation/tempo_controller.dart   // Notifier<TempoState> + Ticker
lib/features/follow_the_tempo/presentation/widgets/pulse_ring.dart
lib/features/follow_the_tempo/presentation/widgets/stage_dots.dart
lib/features/follow_the_tempo/provider.dart

test/features/follow_the_tempo/tempo_controller_test.dart
```
### Modify
`lib/config/router.dart` (`/games/follow-the-tempo`) · `lib/features/games_hub/domain/game_catalog.dart`
(the tile already exists from Phase 1 — just confirm the route resolves to the real screen now).

No Hive, no persistence, no new dependencies. State is entirely in memory.

## 6. Acceptance criteria

- [ ] Ring pulses at exactly the stage bpm (unit test: beat count over a simulated 30s stage).
- [ ] Stage transitions are seamless — no gap, no double beat, no jump in scale.
- [ ] Stopping mid-round cancels the ticker and haptics immediately, with no lingering callbacks.
- [ ] Backgrounding the app pauses the round (`AppLifecycleState.paused`) and resumes cleanly.
- [ ] Reduce motion: the ring does not scale; it pulses colour between `rose @ 30%` and `rose @ 70%`.
- [ ] The screen contains one hero, one CTA, at most one footnote, and never more than two words of
      instruction.
- [ ] No memory leaks: `Ticker` and `AnimationController` disposed (verified by a widget test that
      pumps and disposes).
