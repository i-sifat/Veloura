# Veloura — Flutter Prompt Bible
### A production-shipping playbook, not a code generator's checklist

---

## 0. How This Document Works

You are going to build Veloura across **17 sequential prompts**, each fed into an AI coding assistant (Claude Code, Cursor, etc.) as its own focused unit of work. This is deliberate, not lazy chunking:

- **Content generation and architecture generation are different cognitive tasks.** Every module that needs hundreds of Truths, Dares, or Roleplay scripts gets its UI/logic separated from its content pack. Bundling them produces shallow content because the model is context-switching between "write clean Riverpod code" and "write 500 original spicy dares" in the same breath.
- **One Foundation prompt is the contract everyone else obeys.** It defines the interfaces, folder structure, and models that every later prompt references. Do not let any later prompt invent its own version of `ContentItem`, `Repository<T>`, or `Category`. If a module needs something the Foundation doesn't have, that's a signal to update the Foundation, not to freelance.
- **Run prompts in fresh sessions, in order.** After each prompt, paste the *actual generated interfaces/models* (not my description of them) into the next prompt's context. This is what prevents the drift that kills 30-50-prompt approaches.
- **Every prompt ends with a Definition of Done.** Don't move to the next prompt until you've verified it. An AI assistant will tell you it's done; verify it actually is.

**Execution order:**

```
0. Persona / Operating Instructions (paste at the start of EVERY session)
1. Foundation & Architecture
2. Dice Game                              (no content pack — good early smoke test)
3a. Truth or Dare — Engine                 3b. Truth or Dare — Content Pack
4a. Challenge Cards — Engine               4b. Challenge Cards — Content Pack
5a. Conversation Starters — Engine         5b. Conversation Starters — Content Pack
6a. Position Library — Engine              6b. Position Library — Content Pack ⚠ policy-sensitive
7a. Roleplay Stories — Engine               7b. Roleplay Stories — Content Pack
8. Daily Challenge (engine + light content — pulls from existing pools)
9. Premium / Monetization
10. Profile, Settings, Statistics, Achievements
11. Data Hardening, Localization, Firebase Wiring
12. Final Integration, Polish & Release QA
```

That's 17 discrete prompts (1 + 1 + 10 + 5) instead of one giant spec or fifty micro-prompts.

---

## 1. Persona / Operating Instructions

Paste this at the top of **every single session**, before the module prompt. This is what keeps the AI acting like a product engineer instead of an autocomplete.

```
You are acting as the sole senior engineer responsible for shipping Veloura, a
premium Flutter couples app, to production on the Play Store. You are not a
code-completion tool — you own outcomes, not just output. Combine these
responsibilities as you work:

- Senior Flutter Developer (7+ yrs): write idiomatic, null-safe, performant
  Dart. Prefer composition over inheritance. No god-widgets. No business
  logic in build().
- Mobile Solution Architect: respect Clean Architecture boundaries
  (presentation / domain / data). Don't let UI code reach into Hive
  directly — go through a repository interface.
- Technical Product Manager: if a requirement is ambiguous or conflicts
  with something specified earlier, say so explicitly and propose the
  resolution you're using, rather than silently picking one.
- UI/UX Consultant: every screen must define its loading, empty, error,
  and populated states. Don't hand back a screen that only handles the
  happy path.
- Software Engineering Lead: leave the codebase easier to extend than you
  found it. Name things for what they mean, not what they do today.
- QA Engineer: after generating a module, self-review it against the
  Definition of Done at the end of the prompt before presenting it as
  complete. Call out anything you couldn't verify (e.g. "I haven't run
  this on a device, verify the dice animation timing manually").

Ground rules for this project:
1. Use ONLY the technology stack and interfaces defined in the Foundation
   prompt output. Do not introduce a new state management approach, a new
   storage mechanism, or a new naming convention for models.
2. Every module is self-contained enough to compile and be manually tested
   on its own, even before integration.
3. Flag anything with App Store / Play Store policy risk instead of
   quietly implementing it — I will decide how to handle it.
4. Do not pad output with placeholder TODOs presented as finished work.
   If something is genuinely out of scope for this prompt, say so and
   name which future prompt will cover it.
5. When generating written content (dares, prompts, roleplay beats),
   maintain a consistent brand voice: warm, playful, tasteful — editorial
   rather than clinical or crude, per the content style guide below.
```

---

## 2. Prompt 1 — Foundation & Architecture

**Why this one matters most:** every drift, every mismatched interface, every "wait, which repository pattern are we using" problem traces back to gaps in this prompt. Spend real time reviewing its output before moving on.

```
Build the foundational architecture for Veloura, a Flutter couples game app.
This prompt produces NO game screens yet — it produces the skeleton every
later module will plug into.

STACK
- Flutter 3.x, Dart 3.x null-safe
- Riverpod (use riverpod + riverpod_generator with code generation; avoid
  raw StatefulWidget except where genuinely needed for animation controllers)
- go_router for navigation
- Hive for persistence (local-first; Firebase-ready but not wired yet)
- SharedPreferences for lightweight flags (onboarding seen, theme, etc.)
- google_fonts (Poppins)
- flutter_animate + Lottie for motion
- cached_network_image
- Material 3, dark theme first (light theme is out of scope for now)

DELIVERABLES

1. Folder structure exactly as:
   lib/
     core/           (error handling, base classes, extensions, result types)
     config/         (env config, router config, DI setup)
     theme/          (colors, typography, spacing, shadows, component themes)
     constants/
     utils/
     models/         (shared domain models used across 2+ features)
     services/       (Hive boxes, analytics interface stub, storage service)
     features/
       home/
       truth_dare/
       dice/
       cards/
       positions/
       roleplay/
       conversation/
       daily/
       premium/
       profile/
     shared/
       widgets/      (reusable buttons, cards, app bars, empty states)

2. Theme system implementing this exact palette as ThemeExtension /
   ColorScheme (do not approximate — use these exact hex values):
   background #120B16, surface #1D1423, card #2A1D31, primary #FF4D6D,
   secondary #FF8FA3, accent #FFB703, success #54D67A, textPrimary
   #FFFFFF, textSecondary #B9B3C5, divider #392A42.
   Typography: Poppins, define a full TextTheme (display/headline/title/
   body/label at all sizes Material 3 expects). Define a soft pink-glow
   BoxShadow constant for cards. Provide light-mode stub values too, even
   if unused, so future theming isn't a rewrite.

3. Core domain contracts EVERY content module will implement. This is the
   most important deliverable in this prompt:
   - `ContentCategory` model: id, title, icon, gradient (two colors),
     description, difficulty enum, itemCount, isFavorite, progress (0-1).
   - `ContentItem` base model with a sealed-class or generic approach that
     specific modules (Dare, Challenge, ConversationPrompt, RoleplayStory,
     Position) can extend without duplicating id/category/difficulty/
     favorite/createdAt fields.
   - `Difficulty` enum shared across modules: cute, romantic, spicy,
     extreme (used contextually — not every module uses all four).
   - `ContentRepository<T extends ContentItem>` abstract interface:
     getAll(), getByCategory(), getFavorites(), toggleFavorite(id),
     getRandom(), search(query).
   - `HiveContentRepository<T>` base implementation other repos extend.
   - Result/Either-style wrapper (`AppResult<T>` or similar) for
     repository calls so UI can handle success/failure without try/catch
     sprawl in widgets.

4. Riverpod provider conventions doc (as code comments in
   core/riverpod_conventions.dart): naming pattern for providers
   (xxxRepositoryProvider, xxxControllerProvider, xxxStateProvider),
   where AsyncNotifier vs Notifier is used, how features expose their
   public provider API (a single `provider.dart` barrel file per feature).

5. go_router setup with:
   - Bottom nav shell route wrapping 5 tabs: Home, Games, Daily,
     Favorites, Profile.
   - Placeholder screens for each feature (just a Scaffold with the
     feature name — real screens come in later prompts).
   - A FAB slot reserved on the shell for "random game" (implement later,
     stub the button now).

6. Storage service abstraction: a `StorageService` that wraps Hive box
   initialization/registration so later prompts just call
   `storageService.box<Dare>()` instead of touching Hive directly. Include
   a `HiveAdapterRegistry` pattern so each feature registers its own
   TypeAdapters without editing a shared file (avoid merge-conflict-prone
   central registration).

7. Shared widget kit: PrimaryButton, GlassCard (blur+gradient per the
   "premium" brief), CategoryCard (icon/gradient/description/difficulty/
   progress/favorite/play-button layout), EmptyState, ErrorState,
   LoadingShimmer, SectionHeader with "see all" affordance.

8. Home screen SHELL (structure only, static/mock data acceptable):
   greeting, daily streak indicator, featured game card, popular games
   row, premium banner, quote of the day. Wire it to accept real data
   later via a HomeController — don't hardcode data access, hardcode the
   VALUES for now behind a provider that later prompts will replace.

CONSTRAINTS
- Riverpod only. No Provider package, no Bloc, no GetX.
- Every public repository method returns `AppResult<T>`, never throws
  past the repository boundary.
- Do not implement Truth or Dare, Dice, Positions, etc. content logic
  here — placeholder routes only.

DEFINITION OF DONE
[ ] flutter analyze passes with zero errors
[ ] App builds and launches to Home tab showing the shell layout
[ ] All 5 bottom nav tabs are reachable and show their placeholder screen
[ ] Theme colors match the hex values exactly (spot-check 3 widgets)
[ ] ContentCategory, ContentItem, ContentRepository<T>, Difficulty are
    defined and documented with doc comments explaining intended use
[ ] A short ARCHITECTURE.md is generated summarizing the conventions
    above, so future prompts (and future you) don't have to re-derive them
```

**After running this:** copy the generated `ContentItem`, `ContentCategory`, `ContentRepository<T>`, `Difficulty`, and `AppResult<T>` definitions somewhere safe. You'll paste them into every module prompt below.

---

## 3. Prompt 2 — Dice Game

Deliberately sequenced right after Foundation: it's self-contained, has no content-pack dependency, and is the fastest way to prove the architecture holds up before you invest in the bigger modules.

```
[Paste the Foundation's ContentItem / AppResult / provider conventions here]

Build the Dice Game module for Veloura at lib/features/dice/.

FUNCTIONAL REQUIREMENTS
- Two (configurable up to three) animated dice: Action die (e.g. kiss,
  touch, whisper, massage — tasteful action verbs) and Body-part/Location
  die. Support a third optional "intensity/time" die.
- Tap or shake-to-roll (use sensors_plus for shake detection, tap always
  works as fallback/primary).
- 3D-feeling roll animation using flutter_animate — physical-feeling
  tumble, not a simple fade/crossfade between faces.
- Roll history: last N rolls shown in a scrollable list with timestamp,
  tap to re-view a past combination.
- Custom dice: user can edit the face values/text for each die
  (persisted via Hive) — this is a premium-gated feature, gate it behind
  a `isPremiumProvider` boolean provider for now (real paywall logic
  comes in the Premium prompt — just check the flag).
- Save/favorite a specific roll combination.

TECHNICAL REQUIREMENTS
- DiceFace model + DiceSet model using the shared ContentItem patterns
  where sensible (history entries are ContentItem-like: id, createdAt,
  favorite).
- DiceController as Riverpod Notifier: rollState (idle/rolling/result),
  currentFaces, history.
- Hive box for roll history and custom dice sets, registered via the
  HiveAdapterRegistry pattern from Foundation.
- No blocking the UI thread during animation — use AnimationController
  correctly, dispose it, don't rebuild the whole screen every frame.

UI/UX REQUIREMENTS
- Loading state: N/A (local), but show a disabled state while `rolling`.
- Empty state for history ("No rolls yet — give it a shake").
- Respect reduced-motion accessibility setting if the OS reports it
  (shorten/skip the tumble animation).
- Haptic feedback on roll start and result land (light impact tiers).

DEFINITION OF DONE
[ ] Rolling produces visibly random, animated results, not instant swaps
[ ] History persists across app restart (Hive)
[ ] Custom dice editing is gated behind isPremiumProvider and shows an
    "upgrade" affordance when locked, without implementing real payments
[ ] flutter analyze passes; no business logic inside build()
[ ] Manually verified on at least one physical/emulated device for
    animation smoothness — note any jank you couldn't fully resolve
```

---

## 4. Truth or Dare — Engine + Content Pack

### 4a. Engine

```
[Paste Foundation interfaces]

Build the Truth or Dare engine at lib/features/truth_dare/. Content will
be supplied separately — for this prompt, seed with 15-20 sample items
per difficulty so the UI is testable, not the full pack.

FUNCTIONAL REQUIREMENTS
- Four difficulty levels: Cute, Romantic, Spicy, Extreme (use the shared
  Difficulty enum).
- Category filter: Relationship, Fantasy, Memories, Deep Talk, Playful
  (define as a TruthDareCategory enum or reuse ContentCategory).
- Truth vs Dare selector (toggle or swipe-to-choose-side interaction).
- Card-swipe mechanic: swipe to skip, tap to reveal, swipe-through
  animation between cards (this is the signature interaction — invest
  real effort in making it feel premium, not a basic PageView swap).
- Shuffle mode vs sequential mode.
- Per-session timer (optional, user-configurable countdown for
  answering/completing).
- Favorites (heart icon, persisted).
- Progress tracking: cards seen this session, completion count per
  category over time (for the Profile/Stats module later — just persist
  the data, don't build the stats UI here).

TECHNICAL REQUIREMENTS
- TruthDareItem extends the shared ContentItem: id, type (truth/dare),
  difficulty, category, prompt text, favorite, timesShown, createdAt.
- TruthDareRepository implements ContentRepository<TruthDareItem>.
- TruthDareController (Riverpod) owns session state: current deck
  (filtered+shuffled), current index, session stats.
- Deck building logic (filter by difficulty+category, shuffle, exclude
  recently-shown items using a rolling window) should be pure/testable —
  not embedded in a widget.

UI/UX REQUIREMENTS
- Full flow: category+difficulty picker → card session screen → session
  summary (X truths, Y dares completed, streak impact).
- Empty state if a filter combination has zero matching items.
- Card session screen states: card front (question mark/prompt),
  revealed, transitioning-to-next.

DEFINITION OF DONE
[ ] Full flow playable start to finish with sample content
[ ] Swipe gesture feels intentional (velocity-aware, not just a toggle)
[ ] Difficulty/category filters correctly narrow the deck
[ ] Favorites persist across restart
[ ] Session summary shows accurate counts
[ ] flutter analyze passes
```

### 4b. Content Pack

```
Generate the Truth or Dare content pack for Veloura as a JSON file
(lib/features/truth_dare/data/truth_dare_seed.json) matching the
TruthDareItem model fields exactly: id, type (truth/dare), difficulty
(cute/romantic/spicy/extreme), category (relationship/fantasy/memories/
deep_talk/playful), prompt.

TARGET VOLUME: 500+ items total, roughly balanced:
- ~130 Cute, ~150 Romantic, ~150 Spicy, ~70 Extreme
- Roughly even split between Truth and Dare within each difficulty
- All 5 categories represented in each difficulty tier

CONTENT STYLE GUIDE
- Voice: warm, playful, editorial — like a well-written couples app,
  not clinical and not crude. Think "confident and a little cheeky,"
  not vulgar.
- Cute/Romantic tiers: emotional connection, nostalgia, affection,
  light flirtation. Fully safe for a general-audience screenshot.
- Spicy tier: flirtatious and suggestive, can reference physical
  attraction and intimacy, but implies rather than graphically
  describes. This is the tier most likely to draw Play Store content
  review scrutiny — keep it suggestive, not explicit.
- Extreme tier: most physically/emotionally daring, but still not
  explicit sexual instruction. This is a prompt/dare generator, not
  an instructional text — "explicit anatomical how-to" content
  belongs nowhere in this pack.
- No content involving anything non-consensual-coded, degrading, or
  that could read as coercive even in a "just a game" framing.
- Every item must be genuinely original — do not lightly reword
  well-known meme/copypasta truth-or-dare lists.

OUTPUT
- Valid JSON array, one object per item, ids as td_0001, td_0002, etc.
- After the JSON, output a short QA summary: actual counts per
  difficulty and per type, so I can verify the balance without
  counting manually.
```

---

## 5. Challenge Cards — Engine + Content Pack

### 5a. Engine

```
[Paste Foundation interfaces + note that this reuses ContentRepository<T>
the same way Truth or Dare did]

Build the Challenge Cards module at lib/features/cards/. Seed with 3-4
sample challenges per category for testing.

FUNCTIONAL REQUIREMENTS
- Eight challenge categories (define them: e.g. Communication, Physical
  Touch, Adventure, Romance, Trust, Fun & Games, Deep Connection,
  Surprise — adjust naming to fit the brand, but ship exactly eight).
- Each card: title, challenge description, difficulty, estimated time
  (e.g. "5 min", "1 hour", "All day"), share option (share sheet with
  formatted text — use share_plus).
- Card states: locked (premium), available, in-progress, completed.
- Completion flow: mark complete → optional reflection note → reward
  (coin/streak tie-in, coordinate the data shape with Daily Challenge
  and Premium modules — use a shared `RewardEvent` model if Foundation
  doesn't already have one; if it doesn't, define it here and flag that
  Foundation should adopt it too).
- Favorites.

TECHNICAL / UI REQUIREMENTS: same bar as Truth or Dare — pure deck/filter
logic separated from widgets, full loading/empty/error states, Hive
persistence for completion + favorites, category browse screen using the
shared CategoryCard widget from Foundation's shared widget kit (don't
rebuild a bespoke card component here).

DEFINITION OF DONE
[ ] All 8 categories browsable with correct counts
[ ] Completion flow persists and is reflected in category progress %
[ ] Share sheet produces well-formatted output
[ ] Locked/premium cards show upgrade affordance, don't crash if tapped
[ ] flutter analyze passes
```

### 5b. Content Pack

```
Generate the Challenge Cards content pack (lib/features/cards/data/
challenge_seed.json) matching the ChallengeCard model: id, category
(one of the 8 defined in the engine prompt), title, challenge (the
instruction text), difficulty, estimatedTime.

TARGET VOLUME: 200-300 challenges, roughly 25-35 per category.

STYLE GUIDE: same warm/editorial tone as Truth or Dare. Challenges should
be genuinely completable — avoid vague prompts like "be romantic today";
prefer specific, actionable ones a couple could actually do (e.g. "Write
down three memories from your first month together and read them to each
other tonight"). Mix difficulty and time investment within each category
so the browse screen doesn't feel repetitive.

OUTPUT: valid JSON array, ids as ch_0001 etc., followed by a per-category
count summary.
```

---

## 6. Conversation Starters — Engine + Content Pack

### 6a. Engine

```
[Paste Foundation interfaces]

Build Conversation Starters at lib/features/conversation/. Seed with 5-6
sample prompts per category.

FUNCTIONAL REQUIREMENTS
- Categories: Deep, Funny, Romantic, Future, Getting-to-Know-You-Again
  (ship at least these five; you may add more if it strengthens variety).
- Random mode (single "next card" button, no deck browsing needed) and
  Browse mode (scroll a category's full list).
- Favorites.
- Optional: "answered together" checkbox per prompt so couples can track
  which ones they've discussed (simple boolean + timestamp, persisted).

This module is simpler than Truth or Dare — no swipe-deck mechanic
required, a clean single-card-at-a-time reveal is sufficient. Don't
over-engineer animation here; reuse existing shared transition patterns
from Foundation rather than inventing new ones.

DEFINITION OF DONE
[ ] Random mode never repeats within a short rolling window
[ ] Browse mode correctly filters by category
[ ] "Answered together" state persists
[ ] flutter analyze passes
```

### 6b. Content Pack

```
Generate the Conversation Starters content pack (lib/features/
conversation/data/conversation_seed.json): id, category, prompt text,
depth indicator (light/medium/deep — reuse Difficulty enum if it maps
cleanly, otherwise define a lightweight separate enum and say so).

TARGET VOLUME: 300+ prompts across the five categories, weighted so
"Deep" and "Funny" have the most (these get reused most in real usage),
~60-80 each, others ~40-60.

STYLE: genuinely thought-provoking or genuinely funny — avoid generic
icebreaker-list clichés ("what's your favorite color"). These should
feel like they were written for couples who already know each other,
not strangers on a first date.

OUTPUT: JSON array, ids as cv_0001 etc., plus per-category count summary.
```

---

## 7. Position Library — Engine + Content Pack ⚠

**Read this before running either prompt.** This module carries the highest App Store/Play Store policy risk in the whole app. Google Play's Sexual Content policy can require an 18+ content rating, restricted store visibility, or in stricter interpretations, rejection of the app entirely depending on how explicit the presentation is. Before you invest engineering time here, decide:
- Are you comfortable with an 18+/Mature rating and the distribution limitations that come with it (excluded from some regions, some device families, no ads network eligibility in many networks)?
- Do you want this gated entirely behind an in-app age confirmation + content warning, or excluded from the initial release and reconsidered later?

I've written the content prompt to stay on the "tasteful, editorial, non-explicit" side deliberately — but tasteful text descriptions of sexual positions is still Sexual Content by policy definition, not merely "mature themes." Treat the checklist in Section 13 as a gate before submission, not an afterthought.

### 7a. Engine

```
[Paste Foundation interfaces]

Build the Position Library module at lib/features/positions/. Seed with
4-5 sample entries across difficulty tiers for testing — do not generate
the full content pack in this prompt.

FUNCTIONAL REQUIREMENTS
- Filters: Beginner, Comfort, Advanced (and any additional tiers you
  think genuinely improve browsing — keep it to 3-4 total).
- Search functionality (by name/tag).
- Optional in-session timer (some apps pair this with a "try this
  tonight" flow — implement the timer as a generic reusable component,
  not bespoke to this screen).
- Favorites.
- Each entry: name, category/tier, short description, tags, and a
  PLACEHOLDER illustration slot (asset path field on the model) —
  do not attempt to source or generate actual illustrations in this
  prompt; that's a separate design-asset task outside AI code
  generation scope. Use a tasteful abstract placeholder (icon +
  gradient, consistent with the app's visual language) until real
  illustrations are commissioned.

GATING: this entire module should sit behind:
  1. A one-time in-app content warning / age confirmation dialog
     (persisted so it's not shown every launch).
  2. The existing isPremiumProvider flag (treat this as a premium-only
     section by default — flag this decision to me rather than assuming
     it, in case the product call is to make it free).

DEFINITION OF DONE
[ ] Age/content gate appears before first access, persists after
[ ] Filters and search work correctly against seed data
[ ] Placeholder illustrations render consistently (no broken asset
    states)
[ ] flutter analyze passes
```

### 7b. Content Pack

```
Generate the Position Library content pack (lib/features/positions/data/
positions_seed.json): id, name, tier (beginner/comfort/advanced), tags
(list of strings for search), description.

TARGET VOLUME: 40-60 entries, weighted toward Beginner/Comfort.

STRICT STYLE GUIDE (do not deviate):
- Descriptions are SHORT, editorial, and non-explicit — evocative naming
  and a one-to-two-sentence descriptive framing (mood, comfort level,
  what makes it worth trying), NOT step-by-step physical instruction and
  NOT explicit anatomical language. Think "how a tasteful lifestyle app
  would describe it," not a manual.
- No graphic/clinical anatomical detail.
- Every entry must read as consensual, comfortable, and positive in
  framing.

OUTPUT: JSON array, ids as ps_0001 etc., plus tier count summary. If you
find yourself needing more explicit language to make an entry
"complete," stop and keep the description at the level of naming +
mood/comfort framing only — flag any entry where you felt that tension
rather than pushing past it.
```

---

## 8. Roleplay Stories — Engine + Content Pack

### 8a. Engine

```
[Paste Foundation interfaces]

Build the Roleplay Stories module at lib/features/roleplay/. Seed with
2-3 sample stories.

FUNCTIONAL REQUIREMENTS
- Each story: title, two character roles (with short role descriptions
  so each partner knows who they're playing), setting/goal, 2-3 "twist"
  beats that can be revealed mid-story, estimated duration, difficulty/
  intensity tier, category (Fantasy, Romance, Adventure — matches the
  content organization tree from the brief).
- Randomizer: pick a random story matching selected category/tier.
- Packs: group stories into themed bundles (some free, some premium-
  gated) — reuse the premium-gating pattern from Dice/Positions rather
  than reinventing it.
- Favorites.
- A simple "story session" screen: shows role assignment (tap to pick
  who plays which role), setting/goal reveal, then twist beats revealed
  one at a time on demand (not automatically timed) so couples can pace
  themselves.

DEFINITION OF DONE
[ ] Random story selection respects category/tier filters
[ ] Twist beats reveal on-demand, not automatically
[ ] Pack grouping and premium gating render correctly
[ ] flutter analyze passes
```

### 8b. Content Pack

```
Generate the Roleplay Stories content pack (lib/features/roleplay/data/
roleplay_seed.json): id, title, category (fantasy/romance/adventure),
tier, characterA (name+role description), characterB (name+role
description), setting, goal, twists (list of 2-3 short beats), estimated
duration.

TARGET VOLUME: 40-50 stories across the three categories, roughly even
split, spanning light/playful to more intense tiers.

STYLE GUIDE: think community-theater-meets-date-night — playful
scenarios with a clear premise a couple can actually act out for 10-20
minutes (masquerade ball, stranded travelers, secret agents, etc.), not
literary erotica. Twists should escalate the fun/tension of the scenario
itself (a rival appears, a secret is revealed, the mission changes) not
graphic physical escalation — that's for the couple to improvise, not
for the app to script.

OUTPUT: JSON array, ids as rp_0001 etc., plus category count summary.
```

---

## 9. Prompt — Daily Challenge

```
[Paste Foundation interfaces + the RewardEvent model if one was defined
in the Challenge Cards prompt]

Build the Daily Challenge module at lib/features/daily/. This module
does NOT need its own large content pack — it selects/composes from
content already generated in Truth or Dare, Challenge Cards, and
Conversation Starters (via their repositories), plus a small set of
daily-specific "ritual" prompts you generate here (~30 originals, enough
to avoid obvious repetition across a month).

FUNCTIONAL REQUIREMENTS
- One challenge/prompt surfaced per day, deterministic per device+date
  (same challenge shown all day even across app restarts — seed the
  "random" pick from the date, not from app-launch time).
- Streak tracking: consecutive days completed, with grace-period logic
  you should specify explicitly (e.g. is a missed day a hard reset, or
  is there a once-a-week freeze? Pick one, document why, flag it for
  product sign-off).
- Calendar view showing completion history (simple month grid, filled
  vs empty days).
- Local notification reminder (flutter_local_notifications) — implement
  the trigger and permission request flow; actual copy/scheduling
  strategy should be configurable, not hardcoded to one message.
- Completion rewards (coins/badges — coordinate with whatever reward
  currency Premium module ends up defining; if Premium hasn't run yet,
  define a minimal `RewardCurrency` service here and flag it for reuse).

DEFINITION OF DONE
[ ] Same challenge shown consistently across the same calendar day
[ ] Streak increments/resets correctly including your documented
    grace-period rule
[ ] Calendar view accurately reflects completion history
[ ] Notification permission flow doesn't crash on denial
[ ] flutter analyze passes
```

---

## 10. Prompt — Premium / Monetization

```
[Paste Foundation interfaces + note every prior module's premium-gating
touchpoints: Dice custom sets, Challenge Cards locked cards, Position
Library, Roleplay premium packs]

Build the Premium module at lib/features/premium/.

FUNCTIONAL REQUIREMENTS
- Paywall screen: monthly / yearly / lifetime tiers, glass-blur+gradient
  visual treatment per the brand brief, clear value proposition per tier
  (list what unlocks — pull real examples from the gated features across
  modules, don't use generic placeholder bullet text).
- Integrate in_app_purchase (or revenuecat_purchases_flutter if you
  prefer a managed subscription backend — pick one, state which and
  why, don't half-implement both).
- Restore purchases flow.
- Feature gating source of truth: replace every module's temporary
  `isPremiumProvider` bool stub with a real
  `subscriptionStatusProvider` backed by purchase state, without
  changing the gating call sites in other modules (this is the payoff
  of using one shared flag consistently — verify it actually holds).
- Coin/currency system if used for non-subscription unlocks (align with
  whatever RewardCurrency shape the Daily Challenge module introduced).
- No-ads flag tied to premium status (even if ads aren't implemented
  yet, wire the flag so it's ready).

CRITICAL: Google Play requires all digital subscriptions/consumables
sold within the app to go through Google Play Billing — flag clearly if
any part of this implementation would violate that (e.g. don't route
payment through an external web checkout for in-app content).

DEFINITION OF DONE
[ ] Paywall renders correctly for each tier with real feature bullets
[ ] Purchase flow completes in sandbox/test mode
[ ] Restore purchases correctly re-unlocks gated content
[ ] Every previously-stubbed isPremiumProvider call site now reflects
    real subscription state without code changes at the call site
[ ] flutter analyze passes
```

---

## 11. Prompt — Profile, Settings, Statistics, Achievements

```
[Paste Foundation interfaces]

Build the Profile module at lib/features/profile/.

FUNCTIONAL REQUIREMENTS
- Couple profile: names/nicknames, relationship start date (used for
  "together for X days" stat), optional avatar/photo (local only for
  now — no upload backend yet).
- Aggregate statistics pulled from every module's persisted progress:
  Truth/Dare completion counts by difficulty, Challenge Cards completed
  by category, Daily Challenge streak, Roleplay stories played,
  favorites count across modules. Build this as a read-only aggregation
  layer over existing repositories — do not duplicate progress data into
  a new store.
- Achievements/badges: define 10-15 initial achievements tied to the
  stats above (e.g. "7-day streak", "Tried every category", "50 dares
  completed"). Simple rule-based unlock checked against existing data,
  not a new tracking system.
- Settings: theme (stub for future light mode), notification
  preferences, haptics on/off, sound on/off, language (stub for
  localization module), data export/clear, privacy policy + terms
  links (use placeholder URLs, flag that legal needs to provide real
  ones before release), account/subscription management (deep-link to
  Premium module's management screen).

DEFINITION OF DONE
[ ] Stats accurately reflect real data from at least 3 other modules
    (spot check against manually-completed items)
[ ] Achievements unlock correctly when criteria are met
[ ] Settings persist across restart
[ ] flutter analyze passes
```

---

## 12. Prompt — Data Hardening, Localization, Firebase Wiring

```
[Paste Foundation interfaces + list every Hive model/adapter generated
across all prior modules]

This is a hardening pass, not new feature work.

TASKS
1. Audit every Hive TypeAdapter generated so far for typeId collisions
   (this is the #1 way multi-prompt Hive codegen breaks) — list every
   typeId in use and flag any conflicts before proceeding.
2. Add a versioned migration strategy stub for Hive boxes (even a simple
   "schema version" field + migration function scaffold) so future
   content-pack updates don't corrupt existing user data.
3. Localization scaffolding using flutter_localizations + intl: extract
   all hardcoded UI strings (NOT content-pack strings — those are a
   separate, larger localization effort out of scope here) into ARB
   files, starting with English as the base locale.
4. Firebase readiness: add firebase_core initialization (guarded so the
   app still runs if no Firebase project is configured yet), stub
   Firebase Analytics event calls at key funnel points (onboarding
   complete, first game played, paywall viewed, purchase completed) via
   an AnalyticsService interface — don't hard-couple feature code to the
   Firebase SDK directly.
5. Crash reporting stub (Firebase Crashlytics) wired the same way.
6. Seed data loader: a single startup routine that loads all content
   JSON packs into Hive on first launch (idempotent — don't re-seed on
   every launch), with a visible progress state if it's slow enough to
   need one.

DEFINITION OF DONE
[ ] No Hive typeId collisions
[ ] App functions identically with Firebase config absent (no crash)
[ ] All hardcoded UI strings (not content) moved to ARB/intl
[ ] First-launch seeding is idempotent — verified by restarting twice
[ ] flutter analyze passes
```

---

## 13. Prompt — Final Integration, Polish & Release QA

```
[Paste Foundation interfaces + a list of every module built so far]

This is the integration and pre-release pass across the whole app.

TASKS
1. Wire the FAB "random game" action (stubbed in Foundation) to
   genuinely randomly launch into one of the game modules.
2. Verify the Home screen's featured/popular game sections pull real
   data (favorite counts, recently played) instead of the placeholder
   values from Foundation.
3. Full navigation audit: every route reachable from the shell, no dead
   ends, back-button behavior correct on Android (including from deep
   inside a card session back to the picker, not straight to Home).
4. Consistent state handling audit: spot-check that every screen touched
   across all 17 prompts has genuine loading/empty/error states, not
   just happy-path.
5. Performance pass: check for unnecessary rebuilds (use Riverpod's
   `select` where a widget only needs part of a large state object),
   verify list views use builders not eagerly-built children, verify
   images are cached appropriately.
6. Accessibility pass: semantic labels on icon-only buttons, sufficient
   contrast on text-over-gradient (double check accent/secondary colors
   against WCAG AA for body text sizes), reduced-motion respected.
7. App icon, splash screen, and store listing assets — flag these as
   design-asset work outside code-generation scope if not already
   provided.

DEFINITION OF DONE — full release checklist, verify each explicitly:
[ ] flutter analyze and flutter test (if tests exist) pass clean
[ ] No debug print/logging left in release-path code
[ ] All placeholder legal URLs replaced or explicitly flagged as
    blocking release
[ ] App Content Rating questionnaire drafted (see Section 14 below)
    reflecting the actual content shipped — not the friendliest
    plausible answer
[ ] Data Safety form drafted (what data is collected: none/local-only
    vs analytics/crash reporting if wired)
[ ] Privacy Policy exists and is linked (required for any app handling
    personal data, and mandatory for Sexual Content-flagged apps)
[ ] Release build (flutter build appbundle) succeeds and installs on a
    clean device
```

---

## 14. Release Compliance Checklist (Play Store, Sexual Content Policy)

Run this before you touch "Submit for review." This isn't code-generation work — it's product/legal judgment, which is exactly the kind of thing an AI coding assistant will happily skip past unless you make it a gate.

- [ ] **Content rating**: Complete Play Console's content rating questionnaire honestly for the Position Library and Extreme Truth-or-Dare tier. Expect a Mature 17+ or equivalent regional rating.
- [ ] **Sexual Content policy review**: Read Google Play's current Sexual Content policy in full (policy language changes — check the live Play Console policy center at submission time, not from memory) and confirm the Position Library's *text-only, non-explicit* framing is compliant, or budget time to redesign it if not.
- [ ] **Age-gating**: In-app age confirmation is necessary but may not be sufficient on its own for policy compliance — Play Console may require the store listing itself to be restricted from being served to users who haven't passed age verification at the account level.
- [ ] **Distribution scope**: Decide up front whether Position Library ships in v1 or is held back for a v1.1 after you've confirmed listing approval on the rest of the app — shipping the lower-risk 90% of the app first is a legitimate strategy.
- [ ] **Payments**: Confirm all premium unlocks route through Google Play Billing, not an external payment link (external links to non-Play billing are themselves a policy violation, separate from content).
- [ ] **Data Safety form**: matches what's actually implemented (Firebase Analytics/Crashlytics if wired, none if not).
- [ ] **Ad network eligibility**: if you add ads later, note that most mainstream ad networks (AdMob included) restrict or disallow serving ads against Sexual Content-rated apps/screens — budget for this if ad revenue is part of the monetization plan.

---

## 15. Quick Reference — What to Paste Between Prompts

After Prompt 1 (Foundation), keep these on hand and paste the relevant subset into every later prompt:
- `ContentItem`, `ContentCategory`, `Difficulty`, `ContentRepository<T>`, `AppResult<T>` — full generated code, not paraphrased
- Riverpod provider naming conventions (from ARCHITECTURE.md)
- Any shared model introduced mid-stream by a later module (`RewardEvent`, `RewardCurrency`, `AnalyticsService`) — the first module to invent one should have it promoted into `lib/models/` or `lib/services/`, and every prompt after that should reference the shared version.

If a later prompt genuinely needs something Foundation doesn't have, that's real signal — update Foundation's output and note the change, rather than letting five modules quietly diverge.
