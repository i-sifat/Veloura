# Phase 9 — Spin the Bottle: flick-driven bottle on a zone ring

A new module. A bottle lies on a table ring of eight action zones. You **flick it with your thumb** —
the harder you flick, the longer it spins. Where the neck stops decides what happens next.

Read `00_DESIGN_SYSTEM.md` first. Depends on: **Phase 1 (Foundation)**. Independent of Phases 2–7.
Build it after Phase 4 (the wheel teaches the tick-haptic and landing-accuracy patterns reused here)
and merge it **before Phase 8**, which audits it alongside the other games.

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
4. **No new dependencies** unless this phase file names one explicitly. This phase names none.
5. **No magic numbers.** Every color, size, radius, duration, curve and haptic comes from
   `GameTokens` (see `00_DESIGN_SYSTEM.md`) or `AppColors`. If a value is missing, add it to
   `GameTokens` and note the addition in the PR description.
6. **Hive discipline.** Reserve every new typeId in `docs/planning/HIVE_TYPEIDS.md` *before*
   writing adapters. Register boxes and adapters in `StorageService`. Seed data once and stamp it
   with a `seedVersion`; never re-seed on every launch. **This phase adds no adapters.**
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

## 1. Why this game exists (and why it is not the wheel again)

The wheel (Phase 4) is **tap → watch → read**. The bottle is **touch → throw → watch**. The whole
point of this module is that the player's own hand produces the motion: a flick's speed and
direction drive the spin, so no two spins feel identical. Strip that gesture out and this game is a
reskinned wheel and should not ship.

Three hard differentiators, all mandatory:

1. **Velocity input.** A drag/flick on the bottle sets rotation count and direction. The CTA is the
   accessible fallback, not the main path.
2. **A physical object with an asymmetric pointer.** The neck points; the base does not. Landing
   reads as physics, not as a chart segment.
3. **Eight zones, and the seam counts.** Roughly 1 spin in 12 stops on a seam between two pucks and
   resolves as a **double** — two instructions in one turn. Nothing else in the app can do that.

## 2. Screen anatomy

```
GameAppBar   leading: home 22 · "Spin the bottle" · info 20
TurnChipBar
8
Headline (padding H 20, left aligned):
   "FLICK THE BOTTLE"
   "TO PLAY"                    heroDisplay · textHi · uppercase
   → fades out over 220ms when the spin starts, fades back in when the sheet closes
Expanded > Center > RepaintBoundary > BottleTable
   size = min(screenWidth - 56, 340)
14
Footnote     "Flick it, or use the button"   caption · textLow
             (shown until the first completed spin of the session, then never again)
16
PrimaryCta("Spin the bottle")     disabled at 38% while spinning
bottomCtaInset
```

Use `GameShell(title: 'Spin the bottle', board: true, ...)`. If Phase 2's felt layer has not merged
yet, `board: true` degrades to the standard backdrop — the table disc below is drawn by this phase
regardless, so this phase never blocks on Phase 2.

## 3. `BottleTable` rendering

One square `SizedBox` of `size`, laid out as a `Stack`:

**Layer 1 — table disc.** Circle of `size`, `RadialGradient([#FFFFFF @ 8%, transparent], radius 0.9)`,
plus a 1px `hairline` rim and an inner shadow `0 6 18 #000 @ 30%`.

**Layer 2 — zone ring (`ZoneRing`).** Eight pucks centred on a circle of radius `size * 0.40`, at
`i * 45°` clockwise from 12 o'clock, `i = 0..7`, in the palette order defined in
`00_DESIGN_SYSTEM.md` §1 "Bottle zone palette".

```
puck idle      44 circle · fill zone @ 18% · border 1.5px zone @ 55% · icon 18 zone
puck dimmed    same, whole puck at 45% opacity   (all non-winning pucks after landing)
puck landed    scale 1.16 (bottleSettle) · fill zone @ 32% · border 1.5px zone · glow blur 18 zone @ 40%
```

Pucks are **icons only** — no labels. The zone name appears exactly once, in the result sheet badge.
Each puck gets `Semantics(label: '<Zone name> zone')`. Pucks never rotate.

**Layer 3 — the bottle (`BottlePainter`, inside `Transform.rotate`).** Painted, not an asset: it
stays crisp at every size, cannot 404, and matches the "pure Flutter" rule the dice set.

```
bottleHeight = size * 0.62        bottleWidth = bottleHeight * 0.26
rotation origin = the bottle's geometric centre (it spins on the table, it does not orbit)
neck points to 12 o'clock at rotation 0

body        RRect radius 12, height 62% of bottleHeight, horizontal glass gradient
            [#5A1030, #8E1E4A, #5A1030] stops [0.0, 0.42, 1.0]
shoulder    quadratic taper from body width to neck width over 14% of bottleHeight
neck        RRect radius 6, width 34% of bottleWidth, remaining 24% of bottleHeight
cap         RRect radius 4, height 6% of bottleHeight, fill gold, 1px #000 @ 25% underline
specular    vertical stripe #FFFFFF @ 30%, width 18% of bottleWidth, at 24% from the left,
            blurred sigma 1.2, clipped to the body+neck path
label patch centred on the body: RRect 999 radius, 68% of bottleWidth wide, 22% of body tall,
            fill #F7E7EF @ 92%, heart glyph 10 in roseDeep
contact     ellipse under the bottle, 1.05x bottleWidth by 0.16x bottleWidth,
            #000 @ 45%, blur 12, drawn in the un-rotated layer so it never spins
```

**Layer 4 — idle affordance.** At rest the bottle breathes scale 1.000 ↔ 1.012 (`breathe`) and the
cap glow pulses (`pulseGlow`). Breathing stops the instant a drag begins.

## 4. Input

### Flick (primary)

`GestureDetector` on the bottle's 88x`bottleHeight` hit box (never smaller than 44 wide):

- `onPanStart` — cancel breathing, `selectionClick`, record the pointer's angle around the centre.
- `onPanUpdate` — rotate the bottle 1:1 with the pointer's angular delta. This is direct
  manipulation: the bottle must feel stuck to the thumb.
- `onPanEnd` — compute angular velocity `ω` (rad/s) from the last 100ms of samples.
  - `|ω| < 1.5` → **rejected**: spring back 0.4 rad and settle with `bottleNudge`, fire
    `selectionClick`, change no state, show no result.
  - otherwise → `turns = (|ω| / 3.2).round().clamp(2, 7)`, direction `= ω.sign`, and the spin runs.

### CTA (fallback, always available)

`PrimaryCta("Spin the bottle")` → `lightImpact` → `turns = 3 + random.nextInt(3)`, direction
clockwise. Required for reduce-motion, screen-reader and one-handed use — it is never hidden.

## 5. Spin mechanics

The flick decides *how it spins*; `Random` decides *where it lands*. That split is deliberate: real
friction would silently bias outcomes toward whichever zone sits opposite the flick, and a rigged
feel is worse than an honest one. Put this comment in `bottle_spin_solver.dart` so nobody
"fixes" it later.

```dart
// bottle_spin_solver.dart — pure functions, no Flutter imports, fully unit-testable.
const zoneCount = 8;
const zoneSweep = 360 / zoneCount;                 // 45°

SpinSolution solve({required Random random, required int turns, required int direction}) {
  final isDouble = random.nextDouble() < 0.08;     // ~1 spin in 12 lands on a seam
  final target   = random.nextInt(zoneCount);      // uniform over the 8 zones
  final offset   = isDouble ? zoneSweep / 2 : 0;   // seam = exactly between target and target+1
  final endDeg   = direction * (turns * 360 + target * zoneSweep + offset);
  return SpinSolution(endDegrees: endDeg, target: target, isDouble: isDouble);
}

// Inverse, used by tests and by the landed-puck highlight:
int zoneForDegrees(double deg) => (((deg % 360) + 360) % 360 / zoneSweep).round() % zoneCount;
```

- `AnimationController(duration: bottleSpin)` with curve `Cubic(0.16, 0.84, 0.04, 1.0)`, then a
  chained `bottleSettle` wobble: two damped oscillations of ±3.5° around the final angle
  (`easeOutSine`), amplitude halving each pass.
- **Tick haptics.** In the listener compute `crossed = (degrees / zoneSweep).floor()`; on change fire
  `HapticFeedback.selectionClick()`, throttled to a minimum of 45ms apart.
- **Landing.** `heavyImpact`; the winning puck animates to its landed state, all other pucks dim to
  45%. Doubles fire `heavyImpact` then `mediumImpact` 120ms later, and **both** pucks light up.
- **Accuracy.** Assert the resolved angle maps back to `target` (or to the `target` / `target + 1`
  seam) with < 0.5° error.
- 300ms after the wobble settles, open the result sheet.
- **Lifecycle.** On `AppLifecycleState.paused` cancel the controller and jump to the resolved angle;
  on resume the state is already final. Never leave a half-spun bottle on screen.

## 6. Result sheet

```
zone badge   height 28 · radius 14 · fill zone @ 22% · icon 14 zone · 6 · label cardLabel zone
             double: two badges, 8 apart, with a "+" 14 textLow between them
14
prompt       resultHero · textHi · centred · maxLines 4
             double: prompt A, then "Then " + prompt B lowercased-first, as one block
Spacer
PrimaryCta("Done")               → nextTurn() → pop
SecondaryTextButton("Spin again") → pop → start a new spin immediately (no turn change)
```

`nextTurn()` is called **once**, on "Done" — never on the spin itself. Same contract as every other
game (Phase 1 §3).

## 7. Games hub: the seventh tile

Seven games in a 2-column grid leaves an orphan half tile. Do not pad it with a placeholder and do
not promote `position_library` to fill it. Instead, Spin the Bottle ships as a **full-width wide
tile at the bottom of the grid** — it reads as the newest, most physical game rather than as a
leftover.

```dart
// game_catalog_entry.dart — add one field, default preserves existing behaviour
enum GameTileSpan { half, full }
final GameTileSpan span;   // default GameTileSpan.half; spin_the_bottle => full
```

`games_hub_screen.dart` becomes a `CustomScrollView`:

```
SliverGrid(crossAxisCount 2, spacing 12, childAspectRatio 0.84)  ← all half entries, existing order
SliverToBoxAdapter(SizedBox(height 12))
SliverToBoxAdapter(WideGameTile)                                  ← full entries
SliverPadding(bottom: 24 + bottomNavHeight)
```

No new dependency — do **not** reach for a staggered-grid package.

```
WideGameTile
  height 148 · ClipRRect radius 22 · gradient spinTheBottle (135°) + inner top-left highlight
  art     Image.asset('assets/games/tiles/spin_the_bottle.png', fit: BoxFit.contain,
          alignment: Alignment.centerRight, width: tileWidth * 0.46)
          errorBuilder → GameTileGlyph(Icons.wine_bar)
  title   left aligned, padding L 18, "SPIN THE BOTTLE" tileTitle textHi maxLines 2
  sub     none. The tile carries no body copy.
  NEW chip  Positioned(top 10, left 18): height 20 · radius 10 · fill roseLight @ 18% ·
            "NEW" 10/12 w700 roseLight — hidden permanently once the game has been played once
            (flag in game_prefs_box, no new typeId)
  scrim   LinearGradient([transparent, #000 @ 22%], stops [.55, 1.0])
  border  1px #FFFFFF @ 10% · shadow tile · AnimatedScale(tapScale) · lightImpact → push route
  Semantics: label "Spin the Bottle game", button: true
```

Free game — no `PremiumLockBadge`. `BottleHeat.hot` prompts are the only gated part (see §9).

## 8. Files

### Create
```
lib/features/spin_the_bottle/domain/bottle_zone.dart          // enum + label/icon/colorValue metadata
lib/features/spin_the_bottle/domain/bottle_prompt.dart        // { id, zone, heat, text }
lib/features/spin_the_bottle/domain/bottle_heat.dart          // enum { mild, warm, hot }
lib/features/spin_the_bottle/domain/spin_solution.dart        // { endDegrees, target, isDouble }
lib/features/spin_the_bottle/domain/bottle_spin_solver.dart   // pure math, no Flutter imports
lib/features/spin_the_bottle/domain/bottle_prompt_repository.dart  // interface → AppResult
lib/features/spin_the_bottle/data/bottle_seed.json            // 64 prompts + seedVersion
lib/features/spin_the_bottle/data/bottle_prompt_repository_asset.dart
lib/features/spin_the_bottle/presentation/spin_the_bottle_screen.dart
lib/features/spin_the_bottle/presentation/bottle_controller.dart   // Notifier<BottleState>
lib/features/spin_the_bottle/presentation/widgets/bottle_table.dart
lib/features/spin_the_bottle/presentation/widgets/bottle_painter.dart
lib/features/spin_the_bottle/presentation/widgets/zone_ring.dart
lib/features/spin_the_bottle/provider.dart

lib/features/games_hub/presentation/widgets/wide_game_tile.dart

test/features/spin_the_bottle/bottle_spin_solver_test.dart
test/features/spin_the_bottle/bottle_controller_test.dart
test/features/spin_the_bottle/bottle_seed_test.dart
```

### Modify
```
lib/config/router.dart                                  // /games/spin-the-bottle
lib/features/games_hub/domain/game_catalog_entry.dart    // + GameTileSpan span
lib/features/games_hub/domain/game_catalog.dart          // + spin_the_bottle entry (span: full)
lib/features/games_hub/presentation/games_hub_screen.dart// CustomScrollView + wide tile sliver
pubspec.yaml                                             // bottle_seed.json asset
docs/planning/HIVE_TYPEIDS.md                            // note: no adapters added
```

No Hive box, no adapter, no type ID. Prompt-exhaustion state lives in `game_prefs_box` as a string
list of seen ids, exactly like the other seeded games.

## 9. Content seed

`bottle_seed.json`: `{ "seedVersion": 1, "prompts": [...] }` — **64 prompts, 8 per zone**, each
`{ id, zone, heat, text }`. Ids are `bottle_<zone>_<nn>`. Copy rules from §0.11: second person,
imperative, 12 words max, sensory not clinical.

Zone order and tone, with the reference lines to match (ship 8 per zone):

**KISS**
```
Kiss me somewhere you have not kissed tonight.
Kiss me for ten seconds without using your hands.
Kiss my shoulder, then stop and wait.
```
**TOUCH**
```Trace my spine slowly with two fingers.
Hold my waist and pull me closer.
Warm my hands with yours for one minute.
```
**WHISPER**
```
Whisper what you noticed about me first.
Whisper the thing you almost said earlier.
Whisper a number, and tell me nothing else.
```
**TEASE**
```
Get close enough to kiss me, then wait.
Compliment me while keeping your hands behind your back.
Promise me something for later, out loud.
```
**TASTE**
```
Feed me something with my eyes closed.
Share one sip, no hands for me.
Pick a flavour and put it on my lips.
```
**REVEAL**
```
Show me your favourite part of me.
Take off one thing of my choosing.
Undo one button, slowly, and stop.
```
**TRUTH**
```
Tell me what you were thinking during that spin.
Name the moment tonight you wanted more.
Tell me one thing you have never asked for.
```
**WILD**
```
Redo the last instruction, twice as slowly.
Swap places and let me lead for one minute.
You choose: repeat any zone you like.
```

- `BottleHeat.hot` prompts are excluded from the pool unless the Superhot premium entitlement is on.
  Filter them out of the list entirely — never render them greyed, locked or counted.
- "Soften decks" in `GamePreferencesSheet` drops `warm` and `hot`, leaving `mild` only.
- No repeats until a zone's pool is exhausted, then reshuffle that zone and continue.

## 10. Acceptance criteria

- [ ] Dragging the bottle rotates it 1:1 with the thumb; releasing spins it in the flick's direction.
- [ ] Flick strength changes rotation count (2–7 turns) while landing stays uniform: over 4000 seeded
      spins every zone lands within ±2% of 12.5%.
- [ ] Seam doubles occur on 8% ±1.5% of seeded spins and always light up exactly two pucks.
- [ ] A weak flick (`|ω| < 1.5`) springs back, changes nothing, and opens no sheet.
- [ ] Resolved angle maps back to the intended zone (or seam) with < 0.5° error, verified over 500
      seeded spins.
- [ ] Tick haptics fire once per puck boundary and never exceed ~22 per second.
- [ ] `nextTurn()` fires exactly once per completed round, on "Done" only — never on "Spin again".
- [ ] Backgrounding mid-spin resolves cleanly; no half-spun bottle, no lingering callbacks, no leak
      (widget test pumps and disposes).
- [ ] Reduce motion: no rotation, no wobble; the bottle appears at the resolved angle after a 220ms
      fade, tick haptics suppressed, sheet opens straight after.
- [ ] Missing wide-tile art renders `GameTileGlyph`, never a grey box or an exception.
- [ ] Hub shows six half tiles plus one full-width tile with no orphan gap at 360x800, 390x844 and
      430x932; existing tile order is unchanged.
- [ ] Play surface holds one hero, one CTA, one footnote, zero toggles, zero lists.
- [ ] Seed test: 64 prompts, 8 per zone, unique ids, `seedVersion` present, every line ≤ 12 words.
- [ ] `dart format` + `flutter analyze` clean, `flutter test` green, screenshots attached.
