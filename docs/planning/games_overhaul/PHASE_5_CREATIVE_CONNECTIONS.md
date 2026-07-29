# Phase 5 — Creative Connections: swipe-stack questions

A reskin of the existing conversation_starters module into a card stack the couple swipes through. One question on screen, nothing else.

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
GameAppBar   leading: home 22 · "Creative connections" · info 20
TurnChipBar
Expanded > Center > RepaintBoundary > QuestionStack
16
Footnote     "Swipe when you've answered"   caption textLow   (hidden after the first swipe)
16
PrimaryCta("Next question")     — for people who would rather tap than swipe
bottomCtaInset
```

---

## 2. `QuestionStack` (pixel spec)

```
4 cards preloaded, 3 visible:
  i=0   offset (0,   0)   scale 1.00   opacity 1.00
  i=1   offset (0, -10)   scale 0.97   opacity 0.85
  i=2   offset (0, -20)   scale 0.94   opacity 0.60
  i=3   built but not painted (keeps the next swipe instant)
card 240 x 340 · radius 22
  gradient creativeConnections (135°) + inner top-left highlight
  1px border #FFFFFF @ 10% · shadow tile
  padding 24, column:
    category chip   glass · radius 999 · height 24 · padding H 10 · cardLabel textHi
    Spacer
    question        promptBody · textHi · centred · maxLines 6 · FittedBox(BoxFit.scaleDown)
    Spacer
    hint            "swipe" caption textLow + chevron_right 12   (top card only, first card only)
```

### Swipe interaction
- Horizontal drag: card follows `dx`, rotates `dx / 24` degrees, and starts fading past 96px.
- Release past 96px or with velocity > 700 → throw out over 320ms (easeOutCubic) to `dx.sign * 1.4 *
  screenWidth`; otherwise spring back over 220ms.
- `lightImpact` on a committed swipe. The next card promotes with a 220ms scale + offset tween.
- Both swipe directions do the same thing (next question). Do not build like/dislike semantics —
  there is nothing to teach the user.
- Every committed swipe or CTA tap calls `nextTurn()`, so partners alternate answering.

---

## 3. Files

### Create
```
lib/features/conversation_starters/domain/connection_category.dart  // enum { memory, future, desire, playful }
lib/features/conversation_starters/presentation/creative_connections_screen.dart
lib/features/conversation_starters/presentation/connections_controller.dart
lib/features/conversation_starters/presentation/widgets/question_stack.dart
lib/features/conversation_starters/presentation/widgets/question_card.dart
lib/features/conversation_starters/data/seed/connections_seed.dart

test/features/conversation_starters/connections_controller_test.dart
```
### Modify
`lib/config/router.dart` · `lib/features/conversation_starters/provider.dart` · the existing prompt
model (add `category`; migrate with a bumped `seedVersion`, do not wipe user data).

Controller: maintains a shuffled queue, refills when it drops below 4, and never repeats a question
until the pool is exhausted.

---

## 4. Content — 4 categories x 15 = 60 questions

Rules: ≤ 14 words, no yes/no questions, never two questions in one card, never a question that
requires a prop or a phone.

```
MEMORY   What moment with me do you replay the most?
MEMORY   Which of our firsts do you miss?
MEMORY   When did you first feel safe with me?
FUTURE   Where should we disappear to for a weekend?
FUTURE   What do you want more of from me next month?
FUTURE   What's one thing we should stop postponing?
DESIRE   What's something you've imagined but never said?
DESIRE   When do you find me most irresistible?
DESIRE   What's a look of mine that gets to you?
PLAYFUL  If I had to earn a kiss, what would you make me do?
PLAYFUL  Two truths, one lie — about tonight.
PLAYFUL  What nickname would you never admit you like?
```
Clone this tone to 15 per category.

---

## 5. Acceptance criteria

- [ ] Three cards visible in the stack at the specified offsets; the fourth is preloaded.
- [ ] Swipe follows the finger, rotates, and either throws out or springs back per the thresholds.
- [ ] Next card promotes with no visible pop or blank frame.
- [ ] No question repeats until the pool is exhausted (unit test over the full pool + 1).
- [ ] Reduce motion: swipe becomes an instant crossfade of 220ms.
- [ ] 60 seeded questions; unit test asserts ≤ 14 words and no "?" appearing twice in one string.
- [ ] One CTA, one footnote, no lists.
