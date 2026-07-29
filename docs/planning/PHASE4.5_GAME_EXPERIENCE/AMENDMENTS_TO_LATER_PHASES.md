# Amendments to later phases

Phase 4.5 deliberately has **no "polish" sub-phase**. The items below would have been one, but the
master build plan already has the right homes for them. Duplicating a polish phase is how two competing
checklists appear — exactly the confusion Phase 4.5 exists to remove.

Add these to the named phases when you reach them.

---

## Phase 6 — Premium / Monetization

Additional gated surfaces created by Phase 4.5, all of which must swap from `isPremiumProvider` to the
real `subscriptionStatusProvider` **with zero call-site edits** (D-5):

- Card Challenge SUPERHOT deck (`Difficulty.extreme`) — 4.5.4
- Card Challenge "Swap card" — 4.5.4
- Truth or Dare "Superhot Roulette" (`Difficulty.extreme` in the wheel pool) — 4.5.3
- Passionate Roleplay premium packs — 4.5.7
- Custom dice faces (pre-existing, now reached from `GamePreferencesSheet`) — 4.5.1

Additional Phase 6 requirements:
- Every gated tap routes to the paywall with a `source` argument for analytics, e.g.
  `source: 'card_challenge_superhot'`. **No dead taps anywhere.**
- The paywall's per-tier value bullets must name these real gated features, not placeholders.
- Locked states use `PremiumLockBadge` only. Never grey out content and never render a locked list row
  on a play surface.

---

## Phase 7 — Profile, Settings, Statistics, Achievements

1. **Roll history moves here.** 4.5.2 removes the history list from the Dice screen but keeps writing
   `DiceRollRecord`. Profile → Activity must render it. If Phase 7 has not shipped when 4.5.2 lands,
   the 4.5.2 PR links this line as the tracked follow-up.
2. **Unified activity feed.** Every game writes a play event (`gameId`, timestamp, result label) so
   Activity shows one merged history instead of six. Read-only aggregation over existing repositories —
   do not create a new store (Phase 7's existing rule).
3. **Haptics setting governs game haptics.** The shared helper introduced in 4.5.0 §5 reads it. Resolve
   the Phase 3.5 `TODO(phase7)` at the dice landing call site at the same time.
4. **Statistics additions:** Follow the Tempo rounds completed, Roleplay scenes finished, wheel spins,
   cards drawn per intensity deck. All derived from existing data.
5. **Favourites:** the heart in every 4.5 result sheet writes through the existing per-module favourites
   API, so the Favorites tab needs no new store — only verification that all six games appear.
6. **Achievements:** candidates from Phase 4.5 — "Played all six games", "Completed a full tempo round",
   "Finished a roleplay scene". Rule-based over existing data, no new tracking.

---

## Phase 9 — Final Integration, Polish & Release QA

1. **Random-game FAB** now has six real destinations from `kGameCatalog` — wire it to pick from that
   list, excluding premium-locked entries when the user is not subscribed.
2. **Home featured / popular** rows should surface the new games using real favourite and
   recently-played counts.
3. **Audio pass:** hook the Phase 3.5 `onDieLanded` callback to a landing sound, plus card flip, wheel
   tick and tempo beat. All respect the Sound toggle, all under 200ms, all obeying the OS silent
   switch. The Sound row in `GamePreferencesSheet` is disabled with "Coming soon" until this ships.
4. **Golden tests** for the game surfaces: Games hub, card back and front per intensity deck, wheel at
   rest and mid-spin, scene card, tempo ring at max scale. Run at 390x844 and 360x800. Dice goldens
   belong to Phase 3.5.
5. **Cognitive-load regression tests:** for each of the six play screens, assert it contains exactly
   one `PrimaryCta`, zero `Switch`, and zero `ListView`. This is the cheapest possible guard against
   the text-heavy UI creeping back.
6. **Accessibility sweep:** verify all six games at `textScaleFactor` 1.3 — `resultHero` and
   `heroDisplay` must use `FittedBox(BoxFit.scaleDown)` and never overflow. Contrast: every text colour
   over its actual gradient clears 4.5:1 for body and 3:1 for display. Fix by darkening the scrim,
   never by adding a text shadow.
7. **Reduced-motion sweep:** dice at rest, wheel unrotated, cards crossfaded, stack crossfaded, ring
   colour-pulsing, beats crossfading.
8. **Performance sweep:** profile-mode run of all six games on a low-end physical Android. Budget: no
   more than 3 frames over 16ms per interaction. Confirm no `BackdropFilter` sits over any animating
   subtree and that every animated hero is inside a `RepaintBoundary`.

---

## Phase 10 — Release Compliance

Nothing in Phase 4.5 changes the content rating posture: it adds no new content and no explicit
material. The one relevant addition is the consent sheet from 4.5.4 ("Anything is skippable"), which
strengthens the §14 position rather than weakening it. Position Library remains out of the grid and
flag-gated off per D-3.
