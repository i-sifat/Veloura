# Phase 7 — Passionate Roleplay: scenes, roles, beats

A reskin of roleplay_stories into three single-decision steps. Premium tile. One beat on screen at a time — never a wall of story text.

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

## 1. Flow — three steps, one decision each

```
Step 1  Choose the scene      (horizontal card carousel)
Step 2  Assign roles          (two role cards, one tap)
Step 3  Play                  (one beat + one "Next" CTA, 6 beats per scene)
```
No step ever shows more than one decision. Nothing is scrollable except the carousel.

### Step 1 — scene picker
```
GameAppBar    leading: home 22 · "Passionate roleplay" · info 20
TurnChipBar
8
"CHOOSE A SCENE"      hubTitle · textHi · centred
20
Expanded > PageView.builder
  viewportFraction 0.78 · clipBehavior none
  card 280 x 400 · radius 24
    full-bleed scene art (assets/games/scenes/*.png, BoxFit.cover)
    bottom scrim LinearGradient([transparent, #000 @ 72%], stops [.45, 1])
    padding 20, bottom-aligned column:
      title      screenTitle · textHi · uppercase
      6
      teaser     bodyMid · textMid · max 9 words · maxLines 1 · ellipsis
      10
      chips row  duration chip "~15 min" (glass · caption) · if premium: PremiumLockBadge
  side cards: scale 0.92 · opacity 0.60 (animate from the PageController offset)
16
PrimaryCta("Choose this scene")
```

### Step 2 — role assign
```
"WHO IS WHO"          hubTitle · centred
20
Row, 12 gap, centred: two role cards 156 x 210 · radius 20
  fill glass · border 1px hairline · selected: border 1.5px rose + glassStrong fill
  padding 16, column:
    role glyph 28 (#FFFFFF @ 88%)
    Spacer
    role name        cardLabel · textHi · uppercase
    4
    one-line hook    caption · textLow · max 8 words · maxLines 2
Tapping a card assigns it to the ACTIVE player; the other role auto-assigns to the partner and
shows the partner's avatar in its top-right corner.
16
PrimaryCta("Begin")      disabled until a role is picked
```

### Step 3 — play
```
Full-screen GameShell (board: false), app bar title = scene title, leading = close (X) 22
Beat counter: 6 dots of 6px under the app bar, active rose
Expanded > Center:
  beat line       resultHero · textHi · centred · padding H 28 · maxLines 5
  12
  speaker chip    "ANNA" or "DANIEL" · cardLabel · textLow (whose line/action this beat is)
PrimaryCta("Next")   → advances one beat; on the last beat becomes "Finish"
SecondaryTextButton("End scene")
Transitions between beats: 220ms fade + 8px slide up. Never a page push.
```
"Finish" calls `nextTurn()` and pops to the hub with a 1-line snack-free confirmation sheet
("Scene complete" + `PrimaryCta("Back to games")`).

---

## 2. Files

### Create
```
lib/features/roleplay_stories/domain/roleplay_scene.dart   // Hive typeId: <next free>
lib/features/roleplay_stories/domain/roleplay_role.dart
lib/features/roleplay_stories/domain/roleplay_beat.dart
lib/features/roleplay_stories/data/seed/roleplay_seed.dart
lib/features/roleplay_stories/presentation/roleplay_flow_screen.dart      // owns the 3 steps
lib/features/roleplay_stories/presentation/roleplay_controller.dart
lib/features/roleplay_stories/presentation/widgets/scene_carousel.dart
lib/features/roleplay_stories/presentation/widgets/scene_card.dart
lib/features/roleplay_stories/presentation/widgets/role_pick_row.dart
lib/features/roleplay_stories/presentation/widgets/beat_view.dart

test/features/roleplay_stories/roleplay_controller_test.dart
```
### Modify
`lib/config/router.dart` (`/games/passionate-roleplay`) · `provider.dart` ·
`docs/planning/HIVE_TYPEIDS.md` · `lib/services/storage_service.dart` · `pubspec.yaml` (scene art).

### Models
```dart
class RoleplayScene {
  final String id, title, teaser, art;
  final List<RoleplayRole> roles;   // exactly 2
  final List<RoleplayBeat> beats;   // exactly 6
  final int estMinutes;             // 15
  final bool isPremium;
  final int seedVersion;
}
class RoleplayRole { final String name, hook; final String glyph; }
class RoleplayBeat { final int roleIndex; final String line; }  // line <= 16 words
```
The flow state (`selectedScene`, `roleAssignment`, `beatIndex`) lives in
`roleplayControllerProvider` — a single `Notifier`, not three screens with their own state.

---

## 3. Content — 5 scenes v1

```
1  Strangers at the bar     free      roles: The Regular / The Newcomer
2  Late checkout            free      roles: The Guest / The Concierge
3  The interview            premium   roles: The Candidate / The Boss
4  The photographer         premium   roles: The Muse / The Photographer
5  Old flames               premium   roles: The One Who Left / The One Who Stayed
```
Each scene = 6 beats, alternating roles, each beat ≤ 16 words, imperative or a spoken line.
Reference beats for "Strangers at the bar":
```
1 (Regular)   You noticed them the moment they walked in. Say so.
2 (Newcomer)  Pretend you don't care. Ask what they're drinking.
3 (Regular)   Move one seat closer. Don't explain why.
4 (Newcomer)  Tell them the real reason you came out tonight.
5 (Regular)   Lean in and lower your voice. Make an offer.
6 (Newcomer)  Decide: leave together, or make them wait.
```
Premium scenes are visible in the carousel with `PremiumLockBadge` and route to the paywall on
"Choose this scene" — never a dead tap, never hidden entirely.

---

## 4. Acceptance criteria

- [ ] Carousel shows one centred card with scaled/faded neighbours; art fills the card with no
      letterboxing at 360x800 and 430x932.
- [ ] Role assignment always leaves exactly one role per player; "Begin" is disabled until picked.
- [ ] Play step shows exactly one beat, one CTA, and one speaker chip — never two beats at once.
- [ ] Beat transitions are fades within one route; no route push per beat, back button exits the
      scene once (not beat by beat).
- [ ] Premium scenes show the badge and route to the paywall; free scenes play fully.
- [ ] Missing scene art falls back to the tile gradient plus `GameTileGlyph`.
- [ ] 5 scenes x 6 beats seeded; unit test asserts every beat ≤ 16 words and every scene has
      exactly 2 roles and 6 beats.
