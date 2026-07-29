# Phase 2 — Lustful Rolls: 3D dice thrown on a board

Replaces the current Dice screen (the two flat boxes, the duplicated result line, the toggle row, the locked premium row and the inline roll history all come off the play surface).

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

## 1. What this game is

A **two-die action composer** for two players. Die A carries verbs, die B carries targets.
One throw produces one instruction for the active player to perform on their partner:

```
Anna → Daniel :  "Hold their neck"
```

Rules that follow from that, and must be implemented exactly:

- **One tap throws both cubes at once.** The player never picks twice, never picks a verb and then a
  target, never picks who performs it. Turn alternates automatically.
- The optional **third die** (intensity / duration) is OFF by default and lives only in
  `GamePreferencesSheet`. When ON, three cubes are thrown and the face size drops from 88 to 76.
- Rename the screen to **Lustful rolls** and route it at `/games/lustful-rolls`. Keep the module
  folder `lib/features/dice_game` and reuse the existing history repository.

---

## 2. Screen anatomy (390 x 844)

```
GameAppBar        back 22 · "Lustful rolls" · info 20
TurnChipBar       (A) Anna  ›  (D) Daniel
Expanded          RepaintBoundary > DiceBoard          ← the whole board area
footnote          "Tap the board or shake to throw"     caption · textLow · centered
                  (shown only until the first throw of the session)
PrimaryCta        casino icon 20 · "Throw"  →  "Throw again" once a result exists
bottomCtaInset
```

That is the entire screen. Nothing is rendered on the board except cubes and their shadows —
**no sentence text on the board, ever**. The result lives only in the sheet.

Moved out of this screen:
- third-die toggle and custom faces → `GamePreferencesSheet`
- roll history → Profile → Activity (keep persisting rolls; just stop rendering the list here)
- the favourite (heart) action → top-right of the result sheet, the only place it appears

---

## 3. Files

### Create
```
lib/features/dice_game/domain/dice_face.dart          // { String label; DiceKind kind; }
lib/features/dice_game/domain/dice_kind.dart          // enum DiceKind { verb, target, modifier }
lib/features/dice_game/domain/dice_deck.dart          // const face lists (see §6)
lib/features/dice_game/domain/dice_roll.dart          // { verb, target, modifier?, DateTime at }
lib/features/dice_game/presentation/lustful_rolls_screen.dart
lib/features/dice_game/presentation/dice_controller.dart
lib/features/dice_game/presentation/widgets/dice_board.dart
lib/features/dice_game/presentation/widgets/dice_3d_view.dart
lib/features/dice_game/presentation/widgets/dice_face_tile.dart
lib/features/dice_game/presentation/widgets/board_backdrop.dart
lib/features/dice_game/presentation/widgets/roll_result_sheet.dart

test/features/dice_game/dice_controller_test.dart
test/features/dice_game/dice_face_geometry_test.dart
```
### Modify
```
lib/config/router.dart                     // real screen at /games/lustful-rolls
lib/features/dice_game/provider.dart
lib/shared/widgets/game/game_backdrop.dart // wire board: true → BoardBackdrop felt layer
existing dice repository                   // keep writes, drop the screen-level history read
```

---

## 4. `BoardBackdrop` — the felt board

Layers, bottom → top:
1. `GameBackdrop` base gradient (from tokens).
2. **Table glow**: `Align(Alignment(0, 0.12))`, size `boardWidth * 0.92` x `boardWidth * 0.86`,
   `RadialGradient([#6B1C6F @ 42%, transparent])`, blurred with
   `ImageFiltered(ImageFilter.blur(sigmaX: 28, sigmaY: 28))`.
3. **Felt texture**: `assets/games/felt_noise.png`, `ImageRepeat.repeat`, opacity 0.05,
   `BlendMode.overlay`.
4. **Board frame**: rounded rect inset 16 from the board area, radius 28, 1px border
   `#FFFFFF @ 8%`; simulate an inner shadow with a second rrect painting `#000 @ 22%` at 12px blur
   along the top edge only.
5. Two faint rose glows at `Alignment(-0.70, -0.50)` and `Alignment(0.75, 0.40)`, radius 0.45,
   `rose @ 10%`, blur 40.

---

## 5. `Dice3DView` — the cube

```dart
Dice3DView({
  required List<String> faces,     // exactly 6 labels
  required int resultFaceIndex,    // the face that must end up facing the camera
  required Animation<double> t,    // 0..1 from the board's throw controller
  required double size,            // face edge: 88 for two dice, 76 for three
  required int spinSeed,           // per-throw randomness for turns and axis mix
})
```

### Face geometry
Local transform per face index, applied **before** the outward `translate(0, 0, size / 2)`:
```
0 front   identity
1 right   rotateY( pi/2)
2 back    rotateY( pi)
3 left    rotateY(-pi/2)
4 top     rotateX(-pi/2)
5 bottom  rotateX( pi/2)
```
Each face is built as:
```dart
Transform(
  alignment: Alignment.center,
  transform: Matrix4.identity()
    ..setEntry(3, 2, 0.0012)      // perspective
    ..rotateX(rx)..rotateY(ry)..rotateZ(rz)   // animated cube rotation
    ..multiply(faceLocal)
    ..translate(0.0, 0.0, size / 2),
  child: DiceFaceTile(label: faces[i], size: size, kind: kind),
)
```

**Back-face culling is mandatory.** Transform `Vector3(0, 0, 1)` by the face's rotation matrix; if
`normal.z <= 0.02`, return `const SizedBox.shrink()`. Skipping this produces mirrored ghost text —
the single most common way this effect looks broken. Then sort the visible faces by transformed `z`
ascending and stack them in that order.

### Rest-rotation table
`resultFaceIndex` → the `(rx, ry)` that brings that face to the front. `rz` at rest is always 0 so
the cube lands square to the camera:
```
0 → (0,      0)
1 → (0,     -pi/2)
2 → (0,      pi)
3 → (0,      pi/2)
4 → ( pi/2,  0)
5 → (-pi/2,  0)
```

### `DiceFaceTile` (pixel spec)
```
size x size, radius 14
gradient 145°: [#FBF1F6, #E4D2E0, #CDB6C8] stops [0, .55, 1]
borders: inner 1px #FFFFFF @ 70%, outer 1px #7A5C74 @ 30%
top highlight: top 40% LinearGradient([#FFFFFF @ 55%, transparent])
label: uppercase, Poppins w700, letterSpacing 0.4, textAlign center, maxLines 2, padding 8,
  fontSize = clamp(size * 0.20, 11, 18) wrapped in FittedBox(BoxFit.scaleDown)
  color: verb faces → roseDeep (#C81E67) · target and modifier faces → textOnLight (#2A0A2E)
```

### Throw animation — single 1800ms controller (`diceTumble`)
Derive everything per die from `spinSeed`:
- **Rotation**: `rx = lerp(startRx, restRx + 2*pi*turnsX, easeOutQuart(t))` with
  `turnsX ∈ {2,3}`, `turnsY ∈ {3,4,5}`; `rz` spins `turnsZ ∈ {1,2}` during flight and returns to
  exactly 0 at `t = 1`.
- **Position**: cubes enter from off-board. Die 1 starts at `Alignment(-1.35, -0.95)`, die 2 at
  `Alignment(1.35, -1.15)` and begins at `t = 0.06` (stagger). Path = quadratic Bézier to the rest
  position, control point 22% above the midpoint, evaluated at `easeOutCubic(t)`.
- **Rest positions** (board-relative): two dice → `(-0.30, 0.02)` and `(0.34, 0.16)`;
  three dice → `(-0.46, -0.04)`, `(0.06, 0.14)`, `(0.50, -0.02)`.
- **Bounce**: `TweenSequence` on vertical offset — arrive at t .62, overshoot +9px (t .62–.74),
  −4px (t .74–.86), settle 0 (t .86–1.0). Scale 1.06 → 1.00 across the last 300ms (`diceSettle`).
- **Contact shadow**: ellipse `size*1.15` x `size*0.42`, `#000 @ 38%`, blur 18, offset
  `+size*0.62` on Y; opacity `lerp(0.10, 0.38, 1 - flightHeight)` and scale
  `lerp(0.72, 1.00, 1 - flightHeight)` so it tightens as the die lands.
- **Haptics**: `lightImpact` at t=0 · `mediumImpact` at t=0.62 and t=0.78 · `heavyImpact` at t=1.0.

### Idle state (before the first throw)
Cubes rest on the board and breathe: `rotateY` ±0.06 rad and `rotateX` ±0.04 rad over 5200ms
(easeInOut, repeat reverse), static shadow. No prompts, no glow, no text.

---

## 6. Face decks (`dice_deck.dart`)

```
verbs     Kiss · Lick · Massage · Hold · Whisper to · Tease
targets   their neck · their lips · their thigh · their back · their ear · their hands
modifier  10s · 30s · 1 min · Slowly · Blindfolded · Their choice
```
Composition: `"$verb $target"` → "Kiss their neck", "Whisper to their ear".
With the third die: `"$verb $target — $modifier"`.
Premium "Custom dice faces" edits these lists; the entry point is the gear sheet only.

---

## 7. Controller

```dart
class DiceController extends Notifier<DiceState> {
  // DiceState { DiceRoll? roll, bool rolling, int throwCount, int spinSeed }
  Future<void> throwDice();
}
```
- Ignore taps while `rolling` is true.
- Draw faces with the injected `Random`; **never repeat the exact same verb+target pair twice in a
  row** — redraw up to 5 times, then accept.
- Persist each roll through the existing repository (Profile → Activity reads it).
- 240ms after settle, open `RollResultSheet`. The cubes stay visible above the sheet.
- **Shake to throw**: only if `sensors_plus` is already in `pubspec.yaml`. Do not add it in this
  phase. Tap-anywhere-on-the-board plus the CTA are sufficient; adjust the footnote copy to
  "Tap the board to throw" if shake is unavailable.

---

## 8. `RollResultSheet`

```
height 0.40 of screen (min 300) · sheet fill · radius 28 top · drag handle · padding 24
  top-right: favourite heart icon 22 (outline → filled rose on tap)
  "ANNA  →  DANIEL"                chipLabel · textLow · uppercase · letterSpacing 1.2
  12
  result sentence                  resultHero · centered
                                   verb rendered in rose, target in textHi (one RichText)
  14  (only when the third die is on)
  duration chip                    glass · radius 999 · height 28 · padding H 12 · caption
  Spacer
  PrimaryCta("Done")               → sessionController.nextTurn() → pop
  8
  SecondaryTextButton("Throw again") → pop → throwDice()
```

---

## 9. Acceptance criteria

- [ ] The cubes read as real 3D: at least 3 faces visible mid-flight, exactly 1 face front-facing
      at rest, and the resting face is always `resultFaceIndex`.
- [ ] No mirrored or ghost text at any frame — golden tests at t = 0.30, 0.60, 1.00.
- [ ] The board never renders sentence text; the result appears only in the sheet.
- [ ] Exactly one persistent CTA on the screen; zero toggles, lists or premium rows.
- [ ] Turn advances only when "Done" is tapped.
- [ ] Third-die mode throws three cubes at face size 76 without overlapping at 360x800.
- [ ] Profile-mode run on a mid-range Android: no more than 3 frames over 16ms during a throw.
- [ ] `disableAnimations` → cubes are already at rest and the sheet fades in over 220ms.
- [ ] Tests: seeded `Random` gives a deterministic roll · no immediate duplicate pair over 200
      seeded throws · the rest-rotation table maps all 6 face indices to the front (6 cases).
