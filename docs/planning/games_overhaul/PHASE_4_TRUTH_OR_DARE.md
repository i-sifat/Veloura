# Phase 4 — Truth or Dare: pinwheel spin

The wheel replaces any button-based truth/dare picker. Ten curved petals, one spin, one reveal.

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

## 1. Screen anatomy

```
GameAppBar     leading: home 22 · "Truth or dare" · info 20
TurnChipBar
8
Headline (padding H 20, left aligned):
   "SPIN THE WHEEL"
   "TO PLAY"                heroDisplay · textHi · uppercase
   → fades out over 220ms when the spin starts, fades back in when the sheet closes
Expanded > Center > RepaintBoundary > SpinWheel
   diameter = min(screenWidth - 72, 320)
14
Premium row (centred, one line, the ONLY secondary element):
   flame 14 rose · 6 · "Superhot Roulette" chipLabel textMid · 6 · info 14 textLow  → paywall
16
PrimaryCta("Spin the wheel")      disabled at 38% while spinning
bottomCtaInset
```

---

## 2. `SpinWheel` rendering

- `CustomPaint` inside `Transform.rotate(angle: rotationRadians)`. 10 segments of 36°.
- **Pinwheel petals, not pie slices.** For each segment:
  `path.moveTo(center)` → `arcTo(outerRect, startAngle, sweep)` →
  `quadraticBezierTo(control, center)` where the control point sits at `radius * 0.55`, rotated
  `+13°` from the segment's start angle. That curve is what produces the swirl look.
- **Segment icons**: at `radius * 0.66`, inside a 30px circle `#FFFFFF @ 92%` with a 1px
  `#00000014` border; icon 16 in `#8E2A63`. Icons are **counter-rotated by `-rotation`** so they
  stay upright throughout the spin. Icon order:
  `[casino, water_drop, arrow_forward, music_note, lips.svg, star, casino, flame.svg, water_drop, arrow_forward]`
- **Rim**: 6px ring `#FFFFFF @ 85%` outside the petals, plus an outer glow `rose @ 22%` blur 24.
- **Hub**: 34px circle, radial `[rose, roseDeep]`, 3px white ring, 8px inner dot `#FFFFFF @ 85%`.
- **Pointer**: fixed at 12 o'clock above the wheel — rounded triangle 20 wide x 15 tall, fill
  `rose`, 1px `#FFFFFF @ 70%` stroke, shadow `0 2 6 #000 @ 40%`.
- **Idle**: the wheel breathes scale 1.000 ↔ 1.012 (`breathe`); the hub glow pulses (`pulseGlow`).

---

## 3. Spin mechanics

```dart
// Segment parity defines the type: even index => DARE, odd index => TRUTH (5 and 5).
final target        = random.nextInt(10);
final segmentCentre = target * 36 + 18;                     // degrees
final turns         = 4 + random.nextInt(3);                // 4..6 full rotations
final endDegrees    = turns * 360 + (360 - segmentCentre);  // puts the segment under the pointer
// AnimationController(duration: 4200ms), curve Cubic(0.12, 0.78, 0.06, 1.0)
```
- **Tick haptics**: in the animation listener compute `crossed = (degrees / 36).floor()`; when it
  changes, fire `HapticFeedback.selectionClick()`. Throttle to a minimum of 45ms between ticks so
  the early fast phase does not machine-gun.
- **Landing**: `heavyImpact`; the winning petal flashes `#FFFFFF @ 30%` fading over 260ms and the
  rim glow briefly rises to `rose @ 45%`.
- **Accuracy**: assert that `endDegrees % 360` maps back to `target` with < 0.5° error.
- 300ms after landing, open the result sheet.

### Result sheet
```
badge     height 28 · radius 14 · fill: TRUTH #4B2B8F @ 30% / DARE rose @ 22%
          label "TRUTH" or "DARE" · cardLabel · colour #B39CFF / rose
14
prompt    resultHero · textHi · centred · maxLines 4
Spacer
PrimaryCta("Done")               → nextTurn() → pop
SecondaryTextButton("Skip")      → pop → reopen with a new prompt of the same type
```

---

## 4. Files

### Create
```
lib/features/truth_or_dare/domain/tod_type.dart          // enum { truth, dare }
lib/features/truth_or_dare/domain/tod_heat.dart          // enum { mild, warm, hot }
lib/features/truth_or_dare/domain/tod_prompt.dart        // Hive typeId: <next free> if new
lib/features/truth_or_dare/data/seed/tod_seed.dart
lib/features/truth_or_dare/presentation/truth_or_dare_screen.dart
lib/features/truth_or_dare/presentation/wheel_controller.dart
lib/features/truth_or_dare/presentation/widgets/spin_wheel.dart
lib/features/truth_or_dare/presentation/widgets/wheel_painter.dart
lib/features/truth_or_dare/presentation/widgets/wheel_pointer.dart

test/features/truth_or_dare/wheel_landing_test.dart
```
### Modify
`lib/config/router.dart` · `lib/features/truth_or_dare/provider.dart` · existing repository
(reuse the prompt store if one already exists rather than creating a second one).

---

## 5. Content seed

Same copy rules as Phase 3. Ship 40 truths and 40 dares; the 24 below are the tone reference.

**Truths**
```
What did you first notice about me?
When did you last think about me at a bad time?
What's a compliment you've never said out loud?
Which of my outfits do you like me out of most?
What's one thing you want to try again?
Where do you most like being kissed?
What's the boldest thought you had today?
What do I do that always works on you?
Describe our best kiss in three words.
What's something you want but never ask for?
When did you last stare at me too long?
What would you change about tonight?
```
**Dares**
```
Kiss me somewhere new.
Whisper something you can't say loudly.
Hold my gaze for thirty seconds.
Give me a ten second shoulder massage.
Take off one thing of my choosing.
Kiss my neck until I laugh or stop you.
Slow dance with me, no music.
Trace a word on my back — I'll guess it.
Feed me something with your eyes closed.
Sit on my lap for one minute.
Compliment me three times without repeating.
Do the last dare again, slower.
```
`TodHeat.hot` prompts are only in the pool when the "Superhot Roulette" premium toggle is on.
Filter them out entirely — never render them greyed or locked.

---

## 6. Acceptance criteria

- [ ] Ten curved petals, upright icons at all rotations, white rim, rose hub, pointer at 12 o'clock.
- [ ] Headline fades out on spin and back in when the sheet closes.
- [ ] Tick haptics fire once per segment boundary and never exceed ~22 per second.
- [ ] Over 200 seeded spins the revealed prompt type always matches the petal under the pointer.
- [ ] Reduce motion: no rotation, prompt appears after a 220ms fade.
- [ ] One CTA, one secondary line, zero lists or toggles.
