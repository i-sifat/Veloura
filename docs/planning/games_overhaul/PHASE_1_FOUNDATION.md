# Phase 1 — Foundation: tokens, game shell, 2-player session, Games hub

**Blocking phase. Nothing else starts until this is merged.**
Read `00_DESIGN_SYSTEM.md` first — it defines every value referenced here.

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

## 1. Goal

Three things ship together because every later phase needs all three:

1. `GameTokens` — the design system in code.
2. `GameShell` + shared game widgets — the frame every game screen sits in.
3. `GameSession` — two named players and whose turn it is, persisted and shared by all games.
   *This is the fix for "why does my app only show one player" — there was no session model.*

Plus the new **Games hub**: a 2-column gradient grid of six games.

---

## 2. Files

### Create
```
lib/theme/game_tokens.dart

lib/shared/widgets/game/game_backdrop.dart
lib/shared/widgets/game/game_app_bar.dart
lib/shared/widgets/game/turn_chip_bar.dart
lib/shared/widgets/game/primary_cta.dart
lib/shared/widgets/game/secondary_text_button.dart
lib/shared/widgets/game/result_sheet.dart
lib/shared/widgets/game/glass_panel.dart
lib/shared/widgets/game/premium_lock_badge.dart
lib/shared/widgets/game/game_tile_glyph.dart
lib/shared/widgets/game/game_preferences_sheet.dart
lib/shared/widgets/game/game_shell.dart

lib/features/session/domain/player.dart
lib/features/session/domain/game_session.dart
lib/features/session/domain/session_repository.dart
lib/features/session/data/session_repository_hive.dart
lib/features/session/presentation/session_controller.dart
lib/features/session/presentation/who_is_playing_sheet.dart
lib/features/session/provider.dart

lib/features/games_hub/domain/game_catalog_entry.dart
lib/features/games_hub/domain/game_catalog.dart
lib/features/games_hub/presentation/games_hub_screen.dart
lib/features/games_hub/presentation/widgets/game_tile.dart
lib/features/games_hub/provider.dart

lib/core/random_provider.dart          // randomProvider → Random(); overridable in tests

test/features/session/session_controller_test.dart
test/features/games_hub/games_hub_screen_test.dart
```

### Modify
```
lib/config/router.dart                 // Games branch root → GamesHubScreen; register 6 game routes
lib/services/storage_service.dart      // open session_box, register Player + GameSession adapters
docs/planning/HIVE_TYPEIDS.md          // reserve typeIds for Player and GameSession
pubspec.yaml                           // assets/games/**, assets/icons/**
```

### Routes to register (screens may be placeholders in this phase)
```
/games                          GamesHubScreen
/games/lustful-rolls            Phase 2
/games/card-challenge           Phase 3
/games/truth-or-dare            Phase 4
/games/creative-connections     Phase 5
/games/follow-the-tempo         Phase 6
/games/passionate-roleplay      Phase 7
```
Placeholders must be a `GameShell` with the correct title and a disabled CTA — never a blank screen
or a crash. Keep the existing `StatefulShellRoute.indexedStack` and the centered FAB slot intact.

---

## 3. Session model

```dart
// lib/features/session/domain/player.dart      Hive typeId: <next free>
class Player {
  final String id;          // uuid v4
  final String name;        // max 12 chars
  final int colorValue;     // ARGB int
  const Player({required this.id, required this.name, required this.colorValue});
}

// lib/features/session/domain/game_session.dart Hive typeId: <next free>
class GameSession {
  final Player a;
  final Player b;
  final int activeIndex;    // 0 => a's turn, 1 => b's turn
  final DateTime startedAt;

  Player get active  => activeIndex == 0 ? a : b;
  Player get passive => activeIndex == 0 ? b : a;
  GameSession advanced() => copyWith(activeIndex: 1 - activeIndex);
}
```

- `sessionRepositoryProvider` → `SessionRepositoryHive`, box `session_box`, single key `current`.
  Returns `AppResult<GameSession?>` for reads and `AppResult<void>` for writes.
- `sessionControllerProvider` → `AsyncNotifier<GameSession>` with `load()`, `setPlayers(a, b)`,
  `nextTurn()`, `resetTurns()`.
- `gameSessionStateProvider` → read-only projection consumed by `TurnChipBar` and every game.
- Defaults if nothing is stored: `Player("You", rose)` and `Player("Partner", #8E4BD1)`.
- **Turn contract: a game calls `nextTurn()` exactly once, when the player confirms the result
  ("Done"). Never on the roll/spin/draw itself.** Every later phase depends on this.

### `WhoIsPlayingSheet`
Bottom sheet, height 360, `sheet` fill, radius 28 top.
```
24 padding
"Who's playing?"                       screenTitle · textHi
20
Row per player (x2, 12 apart):
  44 circle avatar — fill = player color, initial `chipLabel` white; tap cycles 6 preset colors
    presets: #FF3366 · #8E4BD1 · #FF9F43 · #3ED598 · #4B9BFF · #FF6BD6
  12 gap
  Expanded TextField — filled `glass`, radius 14, height 52, hint "Name" (`chipLabel` textLow),
    maxLength 12, counter hidden, textCapitalization words
24
PrimaryCta("Start playing")   → setPlayers(...) then pop
```
No other copy on the sheet. On first run it is non-dismissible except via the CTA; afterwards it is
reachable from the hub's gear icon and is normally dismissible.

---

## 4. Games hub screen

```
GameBackdrop > SafeArea > Column
────────────────────────────────
Row (height 44, padding H 20):
  icon tune 22 textMid            → GamePreferencesSheet
  8
  icon lightbulb_outline 22 textMid → "How to play" sheet
  Spacer
  Premium pill: height 30, radius 15, gradient [rose, roseDeep], padding H 12,
    flame icon 14 white · 6 · "Superhot" 12/16 w600 white   → paywall
20
"SELECT A GAME"                   hubTitle · textHi · centered · uppercase
24
Expanded > GridView.count
  crossAxisCount 2
  crossAxisSpacing 12
  mainAxisSpacing 12
  childAspectRatio 0.84
  physics: BouncingScrollPhysics
  padding: fromLTRB(20, 0, 20, 24 + bottomNavHeight)
```

Tile order (fixed): Lustful Rolls · Card Challenge · Truth or Dare · Creative Connections ·
Follow the Tempo · Passionate Roleplay.

### `GameCatalogEntry`
```dart
class GameCatalogEntry {
  final String id;
  final String title;        // "Lustful Rolls"
  final String route;        // "/games/lustful-rolls"
  final String art;          // asset path
  final List<Color> gradient;
  final IconData fallbackIcon;
  final bool isPremium;      // true only for passionate_roleplay
}
```
`game_catalog.dart` exposes `const List<GameCatalogEntry> kGameCatalog` in display order.
`position_library` is **not** in the grid — it stays reachable from Home, keeping the grid at 6.

### `GameTile` (pixel spec)
```
ClipRRect radius 22
Stack:
 1. entry.gradient (135°) + inner top-left highlight (#FFFFFF @ 14% → transparent, stops 0 → .45)
 2. Bottom-aligned art: Image.asset(entry.art, fit: BoxFit.contain,
      alignment: Alignment.bottomCenter, height: tileHeight * 0.62)
      errorBuilder → GameTileGlyph(entry.fallbackIcon)
 3. Title: Padding(top 18, horizontal 14) — entry.title.toUpperCase(), tileTitle, textHi,
      textAlign center, maxLines 2, height 1.18, softWrap true
      (never hand-insert "\n"; let the 14pt side padding produce the two-line wrap)
 4. Legibility scrim: LinearGradient([transparent, #000 @ 22%], stops [.55, 1.0])
 5. if entry.isPremium → Positioned(top 10, right 10, PremiumLockBadge())
 6. 1px border #FFFFFF @ 10%
BoxShadow: tile
Interaction: GestureDetector + AnimatedScale(tapScale) → lightImpact → context.push(entry.route)
Semantics: label "${entry.title} game", button: true
```

---

## 5. `GameShell`

```dart
GameShell({
  required String title,
  required Widget hero,      // centered, expands, must be RepaintBoundary-wrapped internally
  Widget? headline,          // optional block above the hero
  Widget? footnote,          // exactly one caption line, or null
  required Widget cta,       // PrimaryCta, or SizedBox.shrink()
  bool board = false,        // felt backdrop (Phase 2)
  VoidCallback? onInfo,
  Widget? leading,           // defaults to a back button
})
```
Layout:
```
GameBackdrop(board: board) > SafeArea > Column [
  GameAppBar(title, leading, onInfo),
  TurnChipBar(),
  8,
  headline ?? nothing,
  Expanded(Center(RepaintBoundary(hero))),
  footnote ?? nothing,
  16,
  cta,
  bottomCtaInset,
]
```
`GameShell` asserts in debug that it received at most one `footnote` and exactly one `cta`.

---

## 6. `GamePreferencesSheet`

The only home for switches. Rows are 56 tall, label `bodyMid` `textHi`, `Switch.adaptive` with
`activeColor: rose`.
```
Third die (intensity / duration)     default OFF
Vibration                            default ON
Sound                                default OFF   (no audio ships until Phase 8)
Soften decks (hide Superhot)         default OFF
Custom dice faces          → premium row with PremiumLockBadge, pushes the paywall
Who's playing?             → opens WhoIsPlayingSheet
```
Persist via a small `gamePrefsRepositoryProvider` (box `game_prefs_box`, primitive keys — no new
typeIds needed).

---

## 7. Acceptance criteria

- [ ] Six tiles render in 2 columns with 12pt gutters, no clipped or 3-line titles at 360x800,
      390x844 and 430x932.
- [ ] Every tile navigates to its route; the premium tile shows `PremiumLockBadge`.
- [ ] Missing tile art renders `GameTileGlyph`, not an exception or a grey box.
- [ ] First visit to the Games tab opens `WhoIsPlayingSheet`; names and colors survive an app
      restart (verified against Hive, not in-memory state).
- [ ] `TurnChipBar` shows both players, active at 100% opacity, partner at 45%.
- [ ] No screen introduced in this phase contains a toggle, list, or premium row outside
      `GamePreferencesSheet`.
- [ ] `GameShell` placeholders exist for all six routes; tapping any tile never crashes.
- [ ] Tests: hub renders 6 `GameTile`s · missing asset falls back to glyph · `nextTurn()` flips
      `activeIndex` · repository maps a Hive failure to `AppResult.failure` · defaults are created
      when the box is empty.
- [ ] `HIVE_TYPEIDS.md` updated before adapters were written.
- [ ] `dart format` + `flutter analyze` clean, `flutter test` green, screenshots attached.
