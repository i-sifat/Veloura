# Phase 3.5 — Dice Realism & Roll Feel (3D cube)

**Status:** planned · **Blocked by:** Phase 3 ✅ · **Blocks:** nothing (Phase 4 may run in parallel) · **Est:** 1.5–2 days · **Branch:** `phase/3.5-dice-realism`

> **Why this exists as its own phase.** The Phase 2 dice shipped functionally correct but visually flat: each die is a single rounded `Container` with one text label, spun on X/Y by a `TweenAnimationBuilder`, showing `…` while rolling. It reads as a *spinning card*, not a *thrown die*. The Dice game is the app's first-impression toy — the thing a new user taps within 30 seconds. Leaving it to the broad Phase 9 polish pass means shipping four more modules on top of a weak core interaction and then trying to retrofit motion into a screen nobody wants to reopen. Fix it now, as a small, self-contained, reviewable unit.
>
> **Scope discipline:** this phase changes *presentation only*. `DiceController`, `DiceState`, `DiceRollRecord`, the Hive box, favorites, history, premium gating, and shake-to-roll all keep their current behaviour and public API. If you find yourself editing `dice_controller.dart` for anything other than exposing a landing callback, stop — you have left the scope.

---

## 1. Current state (verified against `main` @ Phase 3 merge)

| File | What it does today | Problem |
|------|--------------------|---------|
| `lib/features/dice/presentation/dice_screen.dart` → `_AnimatedDie` | One `Container` (92×92, radius 20, single `BoxShadow`) with one `Text`. `TweenAnimationBuilder` drives `rotateX(angle)` + `rotateY(angle * 0.72)` over 700 ms, `Curves.easeOutBack`, perspective `setEntry(3, 2, 0.0015)`. | A cube has six faces; this has one. Spinning a single plane reads as a flipping card. No shading, no contact shadow, no impact, no settle, no per-die variation — every roll animates identically. |
| `_DiceStage` | Shows `…` per die while `status == rolling`, then swaps to the result string. | The `…` placeholder is the tell that this is a loading spinner wearing a die costume. Real dice show *plausible faces* mid-flight. |
| `_DiceStage` wrapper | Wrapped in `GlassCard`. | `GlassCard` applies `BackdropFilter(ImageFilter.blur(sigma 14))`. Blurring a subtree that repaints every frame is one of the most reliable ways to blow the 16 ms frame budget in Flutter. **This must be swapped for a non-blur surface.** |
| Dice stage position | Inside the page `ListView`, above the controls. | Stage height changes when the third die toggles on → the list reflows under the user's thumb. |
| Haptics | `mediumImpact` before the roll, `selectionClick` after. | Fires on *state change*, not on visual landing, and once for all dice regardless of count. |

**What is already right and must not regress:** result randomness lives in the controller (not the view), reduced-motion is respected via `MediaQuery.disableAnimationsOf`, the shake listener is debounced (2 s) and disposed, history persists, and premium gating uses the shared `isPremiumProvider`.

---

## 2. How the industry actually does 3D dice

Three approaches dominate shipped games. They are not equally appropriate here.

### Approach A — Real rigid-body physics in a 3D scene
A physics engine tumbles actual cube meshes in a bounded tray with a camera, directional light, and real shadow maps. Used by dedicated dice apps and board-game ports (RPG dice rollers, backgammon/Yahtzee ports, Monopoly-style titles) — anything built in Unity/Unreal, or on the web with three.js + cannon/ammo.

- ✅ Unbeatable realism; dice collide with each other and the walls.
- ❌ In Flutter there is no first-class 3D + rigid-body stack. You would take on `three_js`/`flutter_gl`, an experimental `flame_3d`, or embed Unity — hundreds of KB to MB of binary, platform channel risk, and a second rendering pipeline to keep alive for one screen.
- ❌ **Deal-breaker for Veloura: our faces are words, and premium users author their own.** Textured meshes mean generating a texture atlas at runtime from arbitrary user strings, per roll. That is a real feature, and it is not worth it for a two-die toy.

### Approach B — Pre-rendered tumble (Blender/AE → Rive, Lottie, or sprite sheet)
An artist renders a beautiful physically-lit tumble once; the app plays it back and reveals the result. This is what most polished casual mobile games actually ship, because playback is nearly free.

- ✅ Best-looking result per runtime millisecond. Real ray-traced lighting, motion blur, soft shadows.
- ❌ The animation is baked, so **the faces are baked too**. Dynamic words force an ugly hybrid: play the pre-rendered tumble with blank faces, then hand off to a live widget on the final frame and hope the position/rotation match. The seam is visible, and it breaks entirely for the 3-die layout.
- ❌ Requires a designer and an asset pipeline we do not have today.
- ➡️ **Keep as the Phase 9 upgrade path** if a designer produces a Rive tumble; the widget API below is designed so it can be swapped behind `DiceCube` without touching the controller.

### Approach C — Transform-composed cube with live text faces ✅ **chosen**
Six real face widgets positioned in 3D with `Matrix4`, rotated as a rigid unit under a perspective transform, with per-face Lambert shading, depth sorting, back-face culling, a separate ground-contact shadow, and a physics-*plausible* (not physics-*simulated*) motion curve. This is the technique behind every good CSS 3D dice demo, and it is what word-dice games ship — Rory's Story Cubes-style apps, Boggle-likes, party-game word dice. That family has exactly our constraint: **arbitrary text on faces**, so the faces must stay live text.

- ✅ Zero new heavy dependencies; pure Flutter widgets and transforms.
- ✅ Custom premium faces work for free — they are just strings.
- ✅ Text is real text: crisp, themed, localizable, accessible to screen readers.
- ✅ Cheap enough to hit 60 fps on low-end Android with 3 dice.
- ⚠️ Flutter has no depth buffer and no automatic back-face culling, so *you* must cull and sort faces per frame. This is the one part naive implementations get wrong (back faces painting over front faces). Handled explicitly in §5.
- ⚠️ The cube silhouette has hard corners; true beveled geometry is not achievable. At 96 px with a large per-face corner radius plus shading, it reads as a rounded die. Do not chase real bevels.

### Decision records

- **D-6 — Dice are rendered as a transform-composed six-face cube with live text faces (Approach C). No 3D engine, no physics engine, no baked animation.** Realism comes from *motion and light*, not geometry: staggered landings, decaying wobble, impact squash, per-face shading, and a contact shadow. Revisit only if a designer delivers a Rive tumble, in which case swap the internals of `DiceCube` and keep its public API.
- **D-7 — The roll happens in place, in a contained tray on the Dice screen. No new route, no full-screen modal.** Industry practice splits by whether the roll *is* the game moment: turn-based board games (Monopoly-likes, Ludo) take over the screen because the throw decides the turn and needs drama. Tray-based rollers (Yahtzee, backgammon, RPG dice tools, word-dice/Story-Cubes apps) roll in place, because the player rolls repeatedly and a modal per roll becomes friction fast. Veloura is the second kind — the user is already *on* the Dice screen, rolls repeatedly, and needs the result phrase and history in the same view. A modal would add a dismiss tap to every single roll. **A full-screen "focus roll" is a defensible optional extra later; it is explicitly out of scope for this phase.**

---

## 3. What actually sells "real die" (rank-ordered)

Implement in this order. If you run out of time, the top items carry most of the effect.

1. **A grounded contact shadow.** An ellipse under each die that tightens and darkens as the die falls and spreads/fades as it rises. This is the single strongest depth cue — stronger than the cube itself. A cube with no shadow floats; a flat card with a good shadow already reads 3D.
2. **Per-face directional shading.** Side faces darker than the front face, from one fixed light. Without this, six faces read as flat coloured rectangles taped together.
3. **Landing snap to an axis-aligned face.** Final rotation must be an exact multiple of π/2 on both axes so a face is dead-on to camera. Dice that settle at a lazy 7° angle instantly read as fake.
4. **Non-uniform speed.** Real dice never rotate at constant velocity: fast tumble → decelerate → small overshoot → settle. A linear or single-eased spin is the second-biggest tell after the missing shadow.
5. **Per-die stagger and per-die variation.** Dice do not land in unison, and no two throws look alike. Randomise per die: start delay, rotation axis weighting, number of turns, lift height, landing face. This is a large realism win for very little code.
6. **Impact squash + micro-bounces.** ~90 ms of scaleY 0.88 / scaleX 1.08 on contact, easing out through two decaying bounces. Sells weight.
7. **Plausible faces in flight, not `…`.** During the tumble the user should glimpse other real face words flying past. Removing the `…` placeholder is a one-line change with an outsized payoff.
8. **Motion blur on fast rotation.** Blur + reduced opacity on face text while angular velocity is high. Bonus: it resolves the readability tension — words are impressionistic in motion and crisp at rest, exactly like a real die.
9. **Haptics on each landing.** One light impact per die as it lands (three dice → three taps), medium impact on the throw. Timed to the *visual*, not to the state change.

---

## 4. Motion specification (use these numbers)

Per-die timeline, driven by a **single** `AnimationController` shared by all dice (sub-ranges via `Interval`):

| Stage | Local window | Duration | Curve / formula |
|-------|--------------|----------|-----------------|
| Wind-up | 0.00 → 0.08 | 90 ms | `Curves.easeOut`; die dips 4 px, scale 0.97 |
| Tumble (fast spin, blurred, lifted) | 0.08 → 0.62 | 620 ms | `Cubic(0.15, 0.85, 0.10, 1.00)` on total angle |
| Decelerate + snap to face | 0.62 → 0.85 | 260 ms | `Curves.easeOutCubic` + decaying wobble `sin(t·6π)·(1−t)³·0.09 rad` |
| Impact squash + 2 micro-bounces | 0.85 → 1.00 | 180 ms | `Curves.easeOutBack`; scaleY 0.88/scaleX 1.08 → 1.0; translateY 0 → −6 → 0 → −2 → 0 |
| Result phrase reveal | after last die lands | 220 ms | `Curves.easeOut`; fade + slide up 12 px |

- **Controller duration:** 1150 ms. **Stagger:** die *i* starts at `i × 70 ms + Random().nextInt(40) ms`. Three dice → last landing ≈ 1.29 s. **Hard ceiling: never exceed 1.4 s to last landing** — past that a repeat-roll toy feels sluggish.
- **Flight height** `h(t) = sin(t · π)` (0 at start and landing, 1 at apex). Drives `scale = 1 + lift · h` with `lift ∈ [0.06, 0.12]`, and `translateY = −liftPx · h` with `liftPx ∈ [10, 18]`.
- **Contact shadow:** `width = size × (0.55 + 0.35 × (1 − h))`, `blurRadius = 6 + 18 × h`, `opacity = 0.34 × (1 − 0.7 × h)`. Shadow never rotates and never scales with the cube — it is a separate widget below it in the stack.
- **Perspective:** `Matrix4..setEntry(3, 2, 0.0012)` at a 96 px face. Do not increase; heavier perspective on a small cube looks fish-eyed.
- **Total turns per die:** `Random().nextDouble() × 1.5 + 2.0` (2.0–3.5 turns), distributed across X and Y by a random axis weighting where `weightX + weightY = 1` and neither is below 0.25 (a pure single-axis spin looks mechanical).
- **Landing:** pick `landingFaceIndex` first, look up its axis-aligned orientation, then add whole turns on top so the animation *ends exactly* on that orientation. Never ease toward an approximate angle.

### Decoupling the visual from the result — read this twice

The result is already decided by `DiceController.roll()`. The animation's only job is to **land on the face that shows that result**. So, per die, per roll:

1. Take the result string for that die from the controller.
2. Pick `landingFaceIndex` in `0..5` at random.
3. Build a 6-entry face list: the result string at `landingFaceIndex`, and five *decoys* sampled from that die's face pool (`state.actions` / `state.bodies` / `state.extras`), excluding the result, without repeats where the pool allows.
4. Animate to `landingFaceIndex`'s orientation.

This is what replaces `…` and makes the tumble read as a die rather than a spinner. **The controller stays the single source of truth for the result; the view must never derive a result from the animation.**

---

## 5. Implementation — file by file

### 5.1 `pubspec.yaml`
Add `vector_math` explicitly (already present transitively via Flutter; do not rely on a transitive dep):

```
flutter pub add vector_math
```

Commit the refreshed `pubspec.lock` — CI verifies it. No other new dependencies. If you find yourself adding a 3D or physics package, you have violated D-6.

### 5.2 NEW `lib/features/dice/presentation/widgets/die_face.dart`

A single shaded face. Stateless, no animation logic.

- Props: `label`, `size`, `brightness` (0..1 from shading), `blurSigma`, `textOpacity`.
- Decoration: `borderRadius: size * 0.18`; base colour `AppColors.of(context).card` multiplied by `brightness` (use `Color.lerp(card, Colors.black, 1 - brightness)`); 1 px border `secondary` at 30 % alpha; a `RadialGradient` specular blob near the top-left at 8 % white with `radius: 0.9`, `center: Alignment(-0.5, -0.6)`.
- Label: `FittedBox(fit: BoxFit.scaleDown)` around `Text(label, maxLines: 2, textAlign: TextAlign.center)` using `textTheme.titleSmall`, `letterSpacing: 0.2`. Never let a long custom face string overflow — premium users will type long words.
- When `blurSigma > 0`, wrap the label in `ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma))` and apply `textOpacity`. **Only apply the filter while blur is actually needed** — an `ImageFiltered` with sigma 0 still costs a layer.

### 5.3 NEW `lib/features/dice/presentation/widgets/dice_cube.dart`

The cube. Stateless and *pure*: given rotation, it renders. No `AnimationController` here.

- Props: `faces` (exactly 6 strings — assert it), `rotationX`, `rotationY`, `size`, `blurSigma`, `textOpacity`.
- Local face definitions, cube half-extent `h = size / 2`. Each face has a **local normal** and a **placement transform**:

| Index | Face | Local normal | Placement `(yaw, pitch)` |
|-------|------|--------------|--------------------------|
| 0 | front | `(0, 0, 1)` | `(0, 0)` |
| 1 | back | `(0, 0, -1)` | `(π, 0)` |
| 2 | right | `(1, 0, 0)` | `(π/2, 0)` |
| 3 | left | `(-1, 0, 0)` | `(-π/2, 0)` |
| 4 | top | `(0, -1, 0)` | `(0, π/2)` |
| 5 | bottom | `(0, 1, 0)` | `(0, -π/2)` |

  Placement = `Matrix4.identity()..rotateY(yaw)..rotateX(pitch)..translate(0.0, 0.0, h)`. Note Flutter's y-axis grows downward, and the sign of the z translation depends on whether the perspective entry pushes +z toward or away from the viewer.

  > **Do this first, before any animation:** render the cube static at `rotationX = 0.5, rotationY = 0.6` and confirm you see exactly three faces, that they are the ones you expect, and that the *nearest* face is on top. If the signs are inverted you will see the inside of the cube. Fix the signs here; do not "fix" it later with hacks in the motion code.

- **Culling + depth sorting (the part that is easy to get wrong).** Flutter's `Stack` paints in list order with no depth buffer, so a back face declared later will paint over a front face.
  1. Build `rotationOnly = Matrix4.identity()..rotateX(rotationX)..rotateY(rotationY)` (no perspective, no translation).
  2. For each face, transform its local normal: `final n = rotationOnly.transformed3(localNormal)`.
  3. **Cull** faces pointing away from the camera (`n.z <= 0.0` under the convention you verified above). At most three faces survive for any rotation.
  4. **Sort** the survivors by transformed face-centre z ascending, so the nearest face is added to the `Stack` last.
- **Shading.** `lightDir = Vector3(-0.35, -0.55, 0.76).normalized()` (up-left-front). `lambert = max(0, n.dot(lightDir))`, `brightness = 0.42 + 0.58 × lambert`. The 0.42 ambient floor keeps grazing faces from going pure black. Pass `brightness` into `DieFace`.
- Wrap the whole cube in the perspective transform: `Matrix4.identity()..setEntry(3, 2, 0.0012)..rotateX(rotationX)..rotateY(rotationY)`, `alignment: Alignment.center`.
- Wrap in `RepaintBoundary`.

### 5.4 NEW `lib/features/dice/presentation/widgets/die_motion.dart`

Pure, testable motion model — **no Flutter widget imports beyond `Curves`**. This is where the physics-plausible feel lives, and it must be unit-testable without pumping a widget.

- `class DieMotion` with fields: `delay`, `turnsX`, `turnsY`, `landingFaceIndex`, `lift`, `liftPx`, `wobbleAmplitude`.
- `factory DieMotion.random(Random rng, {required int dieIndex})` — applies the §4 ranges and the `i × 70 ms + jitter` stagger.
- `static (double, double) orientationForFace(int index)` — a `const` table of the six `(rotX, rotY)` pairs in multiples of π/2 that bring face *index* dead-on to camera. Derive these from the §5.3 placement table; assert every value is an exact multiple of π/2.
- `DieFrame at(double globalT)` returning a small value class: `rotationX`, `rotationY`, `scaleX`, `scaleY`, `translateY`, `shadowWidthFactor`, `shadowBlur`, `shadowOpacity`, `blurSigma`, `textOpacity`, `hasLanded`.
  - Map `globalT` through the die's delay into a local `t`, clamped to `[0, 1]`.
  - Angles: `orientationForFace(landingFaceIndex) + turns × 2π`, eased per the §4 stage table, plus the decaying wobble term.
  - **Assert in a test that at `t == 1.0` both angles are within 1e-9 of a multiple of π/2.**
  - `blurSigma`: ramp `0 → 2.6` over the tumble, back to `0` by `t = 0.75`. `textOpacity`: `1.0 → 0.55 → 1.0` on the same schedule.
  - `hasLanded` flips true exactly once, at the start of the impact stage — this is the haptic/sound trigger.

### 5.5 NEW `lib/features/dice/presentation/widgets/dice_tray.dart`

The surface the dice land on. **Replaces the `GlassCard` around the stage** (see §1 — do not nest an animating subtree inside `BackdropFilter`).

- **Fixed height 260** so toggling the third die never reflows the page under the user's thumb.
- Felt/table look: `LinearGradient` `surface → background` top-to-bottom, `borderRadius: 28`, 1 px `divider` border, plus a soft radial vignette overlay (`RadialGradient` to `background` at 35 % alpha) and a subtle inset top shadow. No `BackdropFilter` anywhere inside.
- The entire tray is a roll affordance: `GestureDetector(onTap: onRoll)` wrapped in `Semantics(button: true, label: 'Roll dice')`. Keep the explicit `FilledButton` too — discoverability and screen-reader/switch-access users.
- Dice laid out in a centred `Row` with `MainAxisAlignment.center` and 12 px gaps (not `Wrap` — at three dice `Wrap` can break to a second line on narrow screens and wreck the composition; scale die size down to fit instead: 96 px for two dice, 84 px for three).
- Wrap in `RepaintBoundary`.

### 5.6 REWRITE `_DiceStage` in `lib/features/dice/presentation/dice_screen.dart`

Convert to a `StatefulWidget` (`_DiceStage` → `_DiceStageState with SingleTickerProviderStateMixin`).

- One `AnimationController(duration: 1150 ms, vsync: this)`; **dispose it**.
- Hold `List<DieMotion> _motions` and `List<List<String>> _faces` (6 strings per die), regenerated on every roll.
- Drive rendering with a single `AnimatedBuilder` around the tray. Do **not** call `setState` per frame, and do not let the animation rebuild the page `ListView` — that is what the `RepaintBoundary`s and the isolated stage widget are for.
- Listen for `DiceRollStatus` transitions via `ref.listen` on `diceControllerProvider`: on `idle/result → rolling`, build motions + face lists and `forward(from: 0)`.
- Per-die landing: when a die's `hasLanded` flips true, fire `HapticFeedback.lightImpact()` once for that die. Keep `mediumImpact` on the throw. Remove the trailing `selectionClick`. Guard all haptics behind the existing settings flag if one exists by the time you build this; if not, leave a `TODO(phase7)` referencing the haptics toggle in Settings.
- Delete the `rolling ? '…' : value` logic — faces now always carry real strings (§4).
- Reveal the combined `record.summary` **only after the last die lands**, with the 220 ms fade + 12 px slide.
- **Reduced motion** (`MediaQuery.disableAnimationsOf(context) == true`): skip the tumble entirely. Render the cube static at `orientationForFace(landingFaceIndex)`, cross-fade the result over 150 ms, fire one `selectionClick`, draw the shadow at its grounded values. Do not simply set the duration to zero and run the same code path — verify the result appears with no spin.
- Keep the existing `_roll()` behaviour, shake handling, debounce, and the `rolling` guard exactly as they are.

### 5.7 `lib/features/dice/presentation/dice_controller.dart`

Ideally **untouched**. The only acceptable change is exposing per-die result strings if the view currently has to re-split `record.summary` to get them — in which case add explicit `action` / `body` / `extra` accessors (they already exist on `DiceRollRecord`) rather than parsing strings in the view. No behavioural changes, no new state fields.

---

## 6. Performance budget and how to verify it

- **Target:** ≤ 16 ms frames with three dice rolling on a low-end physical Android device. Not an emulator — emulators lie in both directions.
- `RepaintBoundary` on each cube, on the tray, and on the shadow layer.
- **One** `AnimationController` for all dice. Three controllers means three tickers fighting for the same frame.
- `ImageFiltered` blur only while `blurSigma > 0` (ends at `t = 0.75`). Blur is the most expensive thing in this phase — if profiling shows it costing frames, drop the sigma cap from 2.6 to 1.8 before dropping anything else in §3.
- No `BackdropFilter` in the dice stage subtree. This is non-negotiable and is why `GlassCard` is being swapped out.
- Verify with `flutter run --profile` + DevTools Performance timeline: record one three-die roll and confirm no frame exceeds the budget. **Paste the observed worst-frame time into the PR description.** "Feels smooth" is not a measurement.

---

## 7. Accessibility

- Reduced motion path per §5.6 — and confirm the *result is never gated behind the animation*.
- `Semantics` on the tray: `button: true`, `label: 'Roll dice'`. Each cube exposes only its front-face label to the semantics tree; the five decoy faces must be `ExcludeSemantics` or the screen reader will read six words per die.
- Announce the outcome once settled — `SemanticsService.announce(record.summary, TextDirection.ltr)` on landing. A blind user gets nothing from a tumble.
- Face text must clear WCAG AA against the *shaded* face colour, not just the base `card` colour. The 0.42 ambient floor exists partly for this — spot-check the darkest visible face with a contrast checker.

---

## 8. Tests (`test/features/dice/`)

Pure-logic tests carry the weight here; the visuals get a smoke test.

- `die_motion_test.dart`
  - `orientationForFace(i)` returns exact multiples of π/2 for all six faces.
  - `at(1.0)` rotation angles are within 1e-9 of a multiple of π/2, for all six landing faces.
  - Flight height is 0 at `t = 0` and `t = 1`, and peaks near `t = 0.5`.
  - No `NaN`/`Infinity` in any `DieFrame` field across `t` sampled at 0.00…1.00 step 0.01.
  - Two `DieMotion.random()` draws with different seeds differ in at least one field (no accidental determinism).
  - `hasLanded` is false at `t = 0`, true at `t = 1`, and flips exactly once.
- `dice_cube_test.dart`
  - For a sample of rotations, the visible-face set is non-empty, has ≤ 3 members, and contains no face whose transformed normal points away from the camera.
  - Visible faces are ordered nearest-last.
  - `brightness` is monotonic as a face rotates toward the light, and never below the 0.42 floor.
- `dice_screen_test.dart` (extend existing)
  - Tap Roll → `pump` past 1.4 s → result summary is present, and exactly one label per die is in the semantics tree.
  - With `disableAnimations: true`, the result is present within 200 ms.
  - Toggling the third die does not change the tray's height (guards §5.5).
  - Existing history/favorites/premium-gating tests still pass unchanged — proof the phase was presentation-only.

---

## 9. Exit Gate

- [ ] Each die renders as a six-faced cube: three faces visible at rest, side faces visibly darker than the front face, nearest face painted on top (no back-face bleed-through at any rotation).
- [ ] Contact shadow tightens/darkens on landing and spreads/fades at apex.
- [ ] Final rotation lands dead-on an axis-aligned face every roll — no lazy resting angles. Verified across 20 consecutive rolls.
- [ ] Motion is non-uniform: fast tumble → decel → overshoot → squash → settle. Not a single eased spin.
- [ ] Dice land staggered, and **no two consecutive rolls animate identically** (different axes, turns, lift, landing face).
- [ ] Decoy face words are visible mid-tumble; the `…` placeholder is gone.
- [ ] Words are crisp at rest and blurred/dimmed only while spinning fast.
- [ ] One light haptic per die landing; medium impact on throw.
- [ ] Result phrase reveals only after the last die lands.
- [ ] Reduced-motion: no tumble, result appears immediately, no haptic spam.
- [ ] `GlassCard` no longer wraps the animating dice stage; no `BackdropFilter` in the stage subtree.
- [ ] Tray height is fixed; toggling the third die does not reflow the page.
- [ ] Profiled on a low-end physical Android device with three dice; worst frame time recorded in the PR description.
- [ ] `DiceController` / `DiceState` / `DiceRollRecord` / Hive box / typeIds unchanged; all pre-existing dice tests pass untouched.
- [ ] `flutter analyze` zero errors/warnings; `dart run build_runner build --delete-conflicting-outputs` clean; `flutter test` green.
- [ ] `pubspec.lock` committed after `flutter pub add vector_math`.
- [ ] Commit + PR: `feat(dice): realistic 3D cube rendering and roll physics feel`.

---

## 10. Explicitly out of scope

Do not let this phase grow. Each of these is a separate decision, not a freebie:

- Real physics simulation, dice-to-dice collision, or wall bounces (D-6).
- Any 3D engine, Rive/Lottie tumble, or baked animation asset (D-6; revisit in Phase 9 only with designer assets in hand).
- A full-screen or modal roll experience (D-7).
- Dice **sound** (clack on landing). Wire the `onDieLanded` callback now, leave the audio for the Phase 9 audio pass — adding an audio dependency here breaks scope.
- Custom face *colours*, materials, or per-set skins. That is a premium content design task, not a rendering task.
- Any change to the roll result distribution, the premium gate, or the history model.
