# Phase 3 — Card Challenge: 3-card fan, flip reveal, and the content deck

Picking a card is picking an intensity. Three cards are dealt per turn, one from each deck: Sensual, Sexy, Superhot.

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
GameAppBar     leading: home icon 22 (pops to /games) · "Card challenge" · info 20
8
Turn header (padding H 20):
  Row: 30 circle avatar (active player color, initial 13/16 w700) · 8 · name chipLabel textHi
  10
  Instruction line — bodyMid textMid, player names in rose, ONE line:
     pre-deal   "Anna, turn around. Now ___."
     dealt      (this line is replaced by the hint under the fan)
Expanded > Center > RepaintBoundary > CardFan
18
Hint line — caption textLow, prefixed with a 4px rose dot:
     "Daniel, select one of the cards"      (disappears the moment a card is picked)
16
PrimaryCta — hidden while the fan is waiting for a pick; appears as "Done" on the revealed state
bottomCtaInset
```
At most two text blocks are on screen at any moment. Never instruction + hint + CTA together.

---

## 2. `CardFan` (pixel spec)

```
card 132 x 196 · radius 18
positions, relative to the fan centre:
  left    offset (-78, 14)   rotation -10°   scale 0.96   z 0
  centre  offset (  0,  0)   rotation   0°   scale 1.00   z 2
  right   offset ( 78, 14)   rotation +10°   scale 0.96   z 1
entry: staggered 60ms, slide up 24px + fade, cardFan (420ms easeOutCubic)
idle: the centre card floats ±3px vertically over 2600ms (breathe)
```
Deck order left → right is always Sensual · Sexy · Superhot, so the position itself communicates
escalation without any explanatory copy.

### Card back
```
gradient 150°: [deck.base, deck.base darkened 18%]
border 1.5px deck.glow @ 55%
outer glow: BoxShadow(deck.glow @ 28%, blur 18, spread -2)
inner hairline 1px #FFFFFF @ 10%, inset 5, radius 14
content (centred column, padding 14):
  deck label   cardLabel · #FFFFFF @ 92% · uppercase
  10
  deck glyph   30px svg (heart_spark / chili / flame) · #FFFFFF @ 88%
top-right: 3px rounded tick mark, deck.glow @ 40%
```

### Pick → reveal sequence
1. Tap → `lightImpact`. The two unpicked cards translate ±120px outward and fade to 0 over 260ms.
2. The picked card moves to centre and scales to 1.14 (300ms easeOutCubic).
3. Flip: `rotateY` 0 → `pi` over 620ms (`cardFlip`), perspective 0.0012. Swap the child at
   `t > 0.5` and counter-rotate the front child by `pi` so the text is not mirrored.
   `mediumImpact` on completion.
4. Revealed face:
```
208 x 300 · radius 20 · fill sheet (#21082A) · border 1px deck.glow @ 45% · cardGlow shadow
padding 20, column:
  deck chip     height 24 · radius 12 · deck.glow @ 18% fill · cardLabel in deck.glow
  Spacer
  prompt        promptBody · textHi · centred · maxLines 5 · FittedBox(BoxFit.scaleDown)
  Spacer
  duration chip (only when card.durationSec != null) — glass · caption · e.g. "30s"
```
5. Below the card, 20 gap: `PrimaryCta("Done")` → `nextTurn()` → re-deal with a 420ms riffle.
   `SecondaryTextButton("Skip")` is always present — no dialog, no penalty, re-deals and advances.
   `SecondaryTextButton("Swap card")` is premium-gated and allowed once per turn.

---

## 3. Files

### Create
```
lib/features/challenge_cards/domain/challenge_deck.dart      // enum { sensual, sexy, superhot }
lib/features/challenge_cards/domain/challenge_kind.dart      // enum { touch, tease, talk, move }
lib/features/challenge_cards/domain/challenge_card.dart      // Hive typeId: <next free>
lib/features/challenge_cards/domain/challenge_repository.dart
lib/features/challenge_cards/data/challenge_repository_hive.dart
lib/features/challenge_cards/data/seed/challenge_cards_seed.dart
lib/features/challenge_cards/presentation/card_challenge_screen.dart
lib/features/challenge_cards/presentation/challenge_controller.dart
lib/features/challenge_cards/presentation/widgets/card_fan.dart
lib/features/challenge_cards/presentation/widgets/challenge_card_back.dart
lib/features/challenge_cards/presentation/widgets/challenge_card_front.dart
lib/features/challenge_cards/presentation/widgets/consent_sheet.dart

test/features/challenge_cards/challenge_controller_test.dart
test/features/challenge_cards/seed_copy_rules_test.dart
```
### Modify
`lib/features/challenge_cards/provider.dart` · `lib/config/router.dart` ·
`docs/planning/HIVE_TYPEIDS.md` · `lib/services/storage_service.dart`

### Model
```dart
class ChallengeCard {
  final String id;             // "sen_01"
  final ChallengeDeck deck;
  final ChallengeKind kind;
  final String text;           // <= 90 chars AND <= 12 words
  final int? durationSec;      // 10 / 30 / 60 or null
  final bool needsProp;        // true only when the card names an object (max 15% per deck)
  final int seedVersion;       // 1
}
```

### Controller
```dart
Future<void> dealThree();   // one random card per deck, excluding session-used ids
```
`usedIds` is a per-session `Set<String>`. When one deck runs dry, reset only that deck's used set.
When "Soften decks" is on, or premium is inactive, the third card is drawn from Sexy instead of
Superhot and its back shows a `PremiumLockBadge`.

---

## 4. Content plan

### Writing rules (this is what makes it premium instead of crude)
1. Second person, imperative, **one** action per card, 12 words maximum.
2. Sensory verbs over anatomy. Suggestive, never clinical, never slang.
3. `needsProp = true` for at most 15% of a deck; nothing requires shopping.
4. Every card is completable in under 60 seconds; Sensual is fully clothed-compatible.
5. Escalation is the deck's job, not the sentence's. Sensual = connection · Sexy = flirtation and
   light touch · Superhot = intensity.
6. Ship **60 cards per deck**. The 45 below are the tone reference — clone the pattern to fill.

### Deck 1 — SENSUAL
```
sen_01  talk   Say one thing you noticed about them today.
sen_02  touch  Trace their palm slowly for thirty seconds.               30
sen_03  talk   Describe their smile without using the word "nice".
sen_04  touch  Rest your forehead against theirs and just breathe.       30
sen_05  move   Slow dance with them for one song.                        60
sen_06  tease  Whisper their name — nothing else.
sen_07  touch  Brush their hair back and hold their gaze.                10
sen_08  talk   Finish this: "I still think about the night we..."
sen_09  touch  Massage their shoulders while they close their eyes.      60
sen_10  tease  Compliment something only you would notice.
sen_11  move   Sit facing each other, knees touching, eyes open.         30
sen_12  talk   Name the first moment you wanted to kiss them.
sen_13  touch  Kiss the back of their hand, then their wrist.
sen_14  tease  Hold a hug ten seconds longer than comfortable.           10
sen_15  talk   Tell them one thing you want more of this week.
```

### Deck 2 — SEXY
```
sex_01  tease  Trail one finger from their collarbone to their shoulder.
sex_02  touch  Kiss their neck slowly, three times.
sex_03  move   Sit on their lap. Don't move for thirty seconds.          30
sex_04  tease  Whisper what you'd do if the lights went out.
sex_05  touch  Give them a slow kiss — no hands allowed.
sex_06  tease  Take off one item of their choosing.
sex_07  touch  Kiss along their jaw and stop at their ear.
sex_08  talk   Rate their kissing out of ten, then improve it.
sex_09  move   Pin their hands gently above their head for ten seconds.  10
sex_10  tease  Look them in the eyes and bite your lip. Hold it.
sex_11  touch  Run your nails lightly down their back.                   30
sex_12  tease  Say one thing you want them to do to you later.
sex_13  move   Kiss them somewhere you've never kissed them before.
sex_14  touch  Blindfold them with your hand and kiss them.
sex_15  tease  Set a thirty second timer. Tease, don't kiss.             30
```

### Deck 3 — SUPERHOT (premium + consent-gated)
```
hot_01  tease  Hold their gaze while you undo one button.
hot_02  touch  Kiss slowly down their neck. Don't stop for a minute.     60
hot_03  move   Lead them to another room. Say nothing.
hot_04  tease  Tell them exactly what happens next. In detail.
hot_05  touch  Trace where you want to be kissed. They follow.
hot_06  move   Take control for one minute. They stay still.             60
hot_07  tease  Ask for one thing you've never asked for.
hot_08  touch  Kiss their inner wrist, then their thigh.
hot_09  move   Swap roles: they lead, you obey. Thirty seconds.          30
hot_10  tease  Turn the lights off. Find them by touch only.
hot_11  touch  Hold their waist and press them against the wall.
hot_12  tease  Describe the last time you couldn't wait.
hot_13  move   One rule: hands only. One minute.                         60
hot_14  touch  Kiss them until they pull away.
hot_15  tease  Choose their next challenge for them.
```

### Consent UX (required, not optional)
`ConsentSheet` shows once per session, the first time a Superhot card is revealed:
```
"Anything is skippable."            screenTitle textHi
8
"Tap skip on any card. No score, no streak lost."   caption textMid
20
PrimaryCta("Got it")
SecondaryTextButton("Soften the deck")   → sets the pref, re-deals without Superhot
```

---

## 5. Acceptance criteria

- [ ] The fan renders exactly 3 cards, one per deck, at the specified offsets, rotations and scales.
- [ ] Unpicked cards leave the screen before the flip begins; the flip shows no mirrored text.
- [ ] No card repeats within a session until its deck is exhausted.
- [ ] At least 45 seeded cards; a unit test asserts every `text` is ≤ 12 words and ≤ 90 chars.
- [ ] With premium inactive or "Soften decks" on, Superhot never appears and the third card shows
      `PremiumLockBadge`.
- [ ] `ConsentSheet` appears once per session, never twice.
- [ ] Skip always works in one tap, with no dialog, and advances the turn.
- [ ] Never more than two text blocks on screen at once.
