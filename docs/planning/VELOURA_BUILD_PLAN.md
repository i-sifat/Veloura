# Veloura — Production Build Plan

**From current state → Play Store release.** This is the executable phase map that operationalizes `veloura-prompt-bible.md`. The Bible defines *what* to build and the *voice/compliance* rules; this document defines the *order, dependencies, exact stack, commands, and gates* so an AI or human developer can execute phase-by-phase without re-deriving decisions.

> **How to use this doc:** Work top to bottom. Do not start a phase until its "Blocked by" phases are ✅ complete and their Exit Gate passed. Each phase maps to one or more Bible prompts — run the Bible's Persona block (Section 1) at the top of every AI session, then the module prompt, then verify against the Exit Gate here. When a phase says "commit", make the commit before moving on.

---

## 0. Current State (verified 2026-07-28)

| Area | State |
|------|-------|
| Scaffold | Default `flutter create` output. `lib/main.dart` is still the counter demo (`MyApp`/`MyHomePage`). |
| `pubspec.yaml` | Only `cupertino_icons` + `flutter_lints`. **None** of the target stack installed. |
| Dart/Flutter SDK | `sdk: ^3.12.2` (Dart 3.12+). |
| Lints | `flutter_lints` default set via `analysis_options.yaml`. |
| Platforms present | `android/`, `ios/`, `web/`. **No `macos/`, `windows/`, `linux/`** — mobile is the target; leave it that way. |
| Tests | Empty `test/`. |
| Docs | `README.md` (default), `veloura-prompt-bible.md` (the vision/spec). |

**Net:** greenfield. Nothing to refactor, everything to build. The counter app gets deleted in Phase 0.

---

## 1. Target Architecture (the contract)

Locked decisions. Every phase obeys these — do not introduce alternatives mid-stream.

- **Language/SDK:** Dart 3.12+ null-safe, Flutter 3.x, Material 3, **dark theme first** (light is stubbed, not built).
- **State management:** **Riverpod + code generation** (`riverpod_annotation` / `riverpod_generator`). No Provider, Bloc, GetX, or raw `setState` except for local `AnimationController`s.
- **Navigation:** `go_router` with a `StatefulShellRoute` bottom-nav shell (5 tabs: Home, Games, Daily, Favorites, Profile) + a reserved FAB slot for "random game".
- **Persistence:** local-first via **Hive** (see decision D-1 below), `shared_preferences` for lightweight flags. Firebase-ready but not wired until Phase 8.
- **Repository boundary:** UI never touches Hive directly. Every content module implements `ContentRepository<T extends ContentItem>` and returns `AppResult<T>` — repositories never throw past their boundary.
- **Clean Architecture layering** per feature: `presentation/` (widgets + controllers) → `domain/` (models + repository interfaces) → `data/` (Hive-backed repo impls + seed JSON).
- **Folder structure:** exactly as specified in Bible §2 Prompt 1, Deliverable 1.

### Architecture Decision Records (opinionated calls — override only with a reason)

- **D-1 — Use `hive_ce` (Community Edition), not legacy `hive`.** The original `hive`/`hive_generator` packages are effectively unmaintained and have known issues on current Dart. `hive_ce` + `hive_ce_generator` are drop-in, actively maintained, and support the same box/adapter model. If you insist on legacy `hive`, pin `hive ^2.2.3` / `hive_generator ^2.0.1` and accept the risk. **Recommendation: `hive_ce`.**
- **D-2 — Monetization: RevenueCat (`purchases_flutter`), not raw `in_app_purchase`.** Managing subscription state, restore, and cross-store entitlements by hand with `in_app_purchase` is a maintenance trap. RevenueCat gives you a single `subscriptionStatusProvider` source of truth and sandbox testing with far less glue. Both still route through Google Play Billing (policy-compliant). **Recommendation: RevenueCat.** Decide before Phase 6.
- **D-3 — Position Library (Bible §7) ships in v1.1, NOT v1.** Ship the lower-risk ~90% of the app first, confirm Play Store listing approval, then add the Sexual-Content-policy-flagged module. Build the module (Phase 4) behind a compile-time/remote feature flag so it can be excluded from the v1 bundle. This is a product/legal call — flagged for sign-off, defaulting to "hold for v1.1".
- **D-4 — Models: use `freezed` for immutable domain models + `json_serializable` for seed-pack parsing.** Keeps `ContentItem` subclasses boilerplate-free and gives you copyWith/equality for free. Hive adapters are generated separately (see D-1).
- **D-5 — One shared premium flag.** Every module gates on a single `isPremiumProvider` bool during Phases 2–5, which Phase 6 swaps for a real `subscriptionStatusProvider` **without changing call sites**. Enforce this — divergent gating is the most expensive thing to unwind late.

---

## 2. Dependency Map (install in Phase 0)

Versions are indicative of the latest stable line compatible with Dart 3.12 — pin the exact latest at install time with `flutter pub add` and commit the resolved `pubspec.lock`. Do **not** hand-edit versions to older majors.

**Runtime**

| Package | Purpose | Introduced |
|---------|---------|-----------|
| `flutter_riverpod` `^2.6` | State management | Phase 1 |
| `riverpod_annotation` `^2.6` | Codegen annotations | Phase 1 |
| `go_router` `^14` | Navigation shell + routes | Phase 1 |
| `hive_ce` `^2` + `hive_ce_flutter` `^2` | Local persistence (see D-1) | Phase 1 |
| `shared_preferences` `^2.3` | Lightweight flags | Phase 1 |
| `google_fonts` `^6.2` | Poppins typography | Phase 1 |
| `flutter_animate` `^4.5` | Motion/transitions | Phase 1 |
| `lottie` `^3` | Lottie animations | Phase 1 |
| `cached_network_image` `^3.4` | Image caching | Phase 1 |
| `sensors_plus` `^6` | Shake-to-roll (Dice) | Phase 2 |
| `share_plus` `^10` | Share sheet (Challenge Cards) | Phase 3 |
| `flutter_local_notifications` `^18` | Daily reminder | Phase 5 |
| `purchases_flutter` `^8` (RevenueCat, D-2) | Subscriptions | Phase 6 |
| `flutter_localizations` (SDK) + `intl` | Localization scaffolding | Phase 8 |
| `firebase_core` `^3` | Firebase init (guarded) | Phase 8 |
| `firebase_analytics` `^11` | Analytics events | Phase 8 |
| `firebase_crashlytics` `^4` | Crash reporting | Phase 8 |

**Dev / codegen**

| Package | Purpose |
|---------|---------|
| `build_runner` `^2.4` | Runs all codegen |
| `riverpod_generator` `^2.6` | Provider codegen |
| `riverpod_lint` + `custom_lint` | Riverpod-aware lints |
| `freezed` `^2.5` + `freezed_annotation` | Immutable models (D-4) |
| `json_serializable` `^6` + `json_annotation` | Seed JSON parsing |
| `hive_ce_generator` `^2` | Hive TypeAdapters (D-1) |

> **Codegen command (memorize it):** `dart run build_runner build --delete-conflicting-outputs`. Run after any change to a `@riverpod`, `@freezed`, `@JsonSerializable`, or Hive-annotated class.

---

## 3. Global Conventions (apply in every phase)

- **Branching:** one feature branch per phase, e.g. `phase/01-foundation`, `phase/02-dice`. PR into `main`. Docs-only changes may go straight to `main`. Always pull before push.
- **Commits:** conventional style — `feat(dice): …`, `fix(td): …`, `chore(deps): …`, `docs: …`.
- **Definition of Done (every phase, non-negotiable):**
  1. `flutter analyze` → **zero** errors/warnings.
  2. `dart run build_runner build --delete-conflicting-outputs` → clean, no conflicts.
  3. App **compiles and launches** on an emulator/device.
  4. No business logic in `build()`; no `print()` in release-path code.
  5. Every new screen handles **loading / empty / error / populated** states (not just happy path).
  6. Phase-specific Exit Gate (below) fully checked.
- **Testing baseline:** from Phase 1 on, add unit tests for pure logic (deck building, streak rules, reward math) and a smoke `widget_test` per feature entry screen. Target: pure logic covered, not 100% coverage theater.
- **typeId registry:** maintain a running list of Hive `typeId`s in `docs/planning/HIVE_TYPEIDS.md` (create in Phase 1). Every new adapter claims the next free id here **before** coding it. This prevents the #1 multi-module Hive failure (id collisions), audited formally in Phase 8.

---

## 4. Phases

### Phase 0 — Bootstrap & Tooling
**Maps to:** (pre-Bible setup) · **Blocked by:** nothing · **Est:** 0.5 day

**Goal:** kill the demo app, install the full stack, lock tooling, so Phase 1 starts on a clean, codegen-ready base.

**Tasks**
1. Delete counter code from `lib/main.dart`; replace with a minimal `runApp(const ProviderScope(child: VelouraApp()))` placeholder (`VelouraApp` = bare `MaterialApp` with dark `ThemeData`).
2. `flutter pub add` all Phase-1 runtime deps + all dev/codegen deps from §2 (defer platform-only packages like `sensors_plus`, `purchases_flutter`, `firebase_*` to their phases to keep early builds light).
3. Add `build.yaml` if needed for freezed/riverpod generators.
4. Harden `analysis_options.yaml`: keep `flutter_lints`, add `custom_lint` + `riverpod_lint` under `analyzer.plugins`, enable `prefer_single_quotes`, treat unused imports as warnings.
5. Update `README.md` with real project intro (name, one-liner, "see docs/planning/").
6. Confirm `.gitignore` covers `**/*.g.dart`? → **No — commit generated files** for reproducible CI; instead ensure `.dart_tool/`, build artifacts, and `*.freezed.dart`/`*.g.dart` policy is decided: **commit them** (simpler for this project). Document the choice.
7. (Optional but recommended) add a GitHub Actions workflow `.github/workflows/ci.yaml`: `flutter pub get` → `build_runner build` → `flutter analyze` → `flutter test`.

**Exit Gate**
- [ ] Counter demo gone; app launches to an empty dark scaffold.
- [ ] `flutter pub get` resolves; `pubspec.lock` committed.
- [ ] `dart run build_runner build` runs clean (even with nothing to generate yet).
- [ ] `flutter analyze` clean.
- [ ] Commit: `chore: bootstrap stack, remove demo app`.

---

### Phase 1 — Foundation & Architecture ⭐
**Maps to:** Bible Prompt 1 · **Blocked by:** Phase 0 · **Est:** 3–4 days

**Goal:** produce the skeleton every module plugs into. **This is the highest-leverage phase — review its output harder than any other.** No game logic yet.

**Deliverables (files)**
- Folder tree exactly per Bible §2 D-1 under `lib/` (`core/`, `config/`, `theme/`, `constants/`, `utils/`, `models/`, `services/`, `features/{home,truth_dare,dice,cards,positions,roleplay,conversation,daily,premium,profile}/`, `shared/widgets/`).
- `theme/` — exact palette as `ThemeExtension`/`ColorScheme`: `background #120B16`, `surface #1D1423`, `card #2A1D31`, `primary #FF4D6D`, `secondary #FF8FA3`, `accent #FFB703`, `success #54D67A`, `textPrimary #FFFFFF`, `textSecondary #B9B3C5`, `divider #392A42`. Full Poppins `TextTheme` (all M3 sizes). Pink-glow `BoxShadow` constant. Light-mode stub values present.
- `models/` — **the contract**: `ContentCategory`, `ContentItem` (sealed/generic base: id, category, difficulty, favorite, createdAt), `Difficulty` enum (`cute, romantic, spicy, extreme`).
- `core/` — `ContentRepository<T extends ContentItem>` interface (`getAll, getByCategory, getFavorites, toggleFavorite, getRandom, search`); `AppResult<T>` Either-style wrapper; `HiveContentRepository<T>` base impl; `riverpod_conventions.dart` documenting provider naming (`xxxRepositoryProvider`, `xxxControllerProvider`, `xxxStateProvider`) and Notifier vs AsyncNotifier rules + one `provider.dart` barrel per feature.
- `services/` — `StorageService` wrapping Hive init/box access (`storageService.box<T>()`); `HiveAdapterRegistry` pattern so each feature self-registers adapters (no shared central file → no merge conflicts); analytics interface **stub** only.
- `config/` — `go_router` `StatefulShellRoute` with 5 tabs + placeholder Scaffolds per feature + reserved (stubbed) FAB.
- `shared/widgets/` — `PrimaryButton`, `GlassCard` (blur+gradient), `CategoryCard`, `EmptyState`, `ErrorState`, `LoadingShimmer`, `SectionHeader` (with "see all").
- `home/` — Home **shell** (structure + mock values behind a `HomeController` provider): greeting, streak indicator, featured card, popular row, premium banner, quote of the day.
- `ARCHITECTURE.md` at repo root — summarizes conventions so nobody re-derives them.
- `docs/planning/HIVE_TYPEIDS.md` — start the typeId registry.

**Exit Gate** (Bible Prompt 1 DoD + ours)
- [ ] `flutter analyze` zero errors.
- [ ] App launches to Home tab showing the shell; all 5 tabs reachable to their placeholder.
- [ ] Theme hex values exact (spot-check 3 widgets).
- [ ] `ContentCategory`, `ContentItem`, `ContentRepository<T>`, `Difficulty`, `AppResult<T>` defined + doc-commented.
- [ ] `ARCHITECTURE.md` generated and accurate.
- [ ] **Snapshot the generated `ContentItem` / `ContentCategory` / `ContentRepository<T>` / `Difficulty` / `AppResult<T>` code** into `docs/planning/CONTRACT_SNAPSHOT.md` — this is what you paste into every later module session.
- [ ] Commit + PR: `feat(foundation): architecture, theme, contracts, shell`.

> ⚠ **Do not proceed to Phase 2 until the contract snapshot exists.** Every downstream phase depends on pasting these exact definitions.

---

### Phase 2 — Dice Game (architecture smoke test)
**Maps to:** Bible Prompt 2 · **Blocked by:** Phase 1 · **Est:** 2–3 days

**Goal:** prove the architecture holds with a self-contained module that needs **no content pack**. If something in the Foundation is wrong, you find it here cheaply.

**Add deps:** `sensors_plus`.

**Key requirements** (full detail in Bible §3)
- 2 (configurable to 3) animated dice: Action die + Body-part/Location die + optional Intensity/Time die. Tasteful action verbs.
- Tap-to-roll (primary) + shake-to-roll (`sensors_plus`, fallback). 3D-feeling tumble via `flutter_animate` (not a crossfade).
- Roll history (Hive-persisted, timestamped, tap to re-view) with empty state ("No rolls yet — give it a shake").
- Custom dice faces — **premium-gated behind `isPremiumProvider`** (stub flag, D-5), shows upgrade affordance when locked.
- Favorite a roll combination.
- `DiceController` as Riverpod `Notifier` (rollState idle/rolling/result, currentFaces, history). Hive box registered via `HiveAdapterRegistry`. Claim typeId(s) in the registry first.
- Respect OS reduced-motion; haptics on roll start + land. Dispose `AnimationController`s; no full-screen rebuild per frame.

**Exit Gate** (Bible Prompt 2 DoD)
- [ ] Rolls are visibly random + animated, not instant swaps.
- [ ] History persists across restart.
- [ ] Custom dice gated behind `isPremiumProvider` with upgrade affordance; no real payments.
- [ ] `flutter analyze` clean; no logic in `build()`.
- [ ] Verified on device for animation smoothness (note any residual jank).
- [ ] Commit + PR: `feat(dice): dice game module`.

---

### Phase 3 — Core Content Modules (engines + packs)
**Maps to:** Bible Prompts 3, 4, 5 · **Blocked by:** Phase 2 · **Est:** 6–9 days

**Goal:** the three highest-value, general-audience-safe content modules. Each is a two-step: build the **engine** (seed with 15–20 sample items so UI is testable), then generate the **content pack** in a *separate* session (content generation ≠ architecture generation — keep them apart per Bible §0).

Run in this sub-order:

**3.1 Truth or Dare** (Bible §4)
- Engine: 4 difficulties (shared `Difficulty`), categories (Relationship/Fantasy/Memories/Deep Talk/Playful), Truth/Dare selector, **signature card-swipe** (velocity-aware, not a PageView swap), shuffle vs sequential, optional per-session timer, favorites, progress tracking persisted (stats UI is Phase 7). `TruthDareItem extends ContentItem`; `TruthDareRepository implements ContentRepository<TruthDareItem>`; pure/testable deck-building (filter + shuffle + recently-shown rolling window).
- Content pack → `lib/features/truth_dare/data/truth_dare_seed.json`: **500+ items** (~130 cute / ~150 romantic / ~150 spicy / ~70 extreme, even truth/dare split, all 5 categories per tier), ids `td_0001…`. Voice per Bible content style guide. **Spicy = suggestive not explicit; Extreme = daring not instructional.** Output a QA count summary.

**3.2 Challenge Cards** (Bible §5)
- Engine: **exactly 8** categories, each card (title, description, difficulty, estimated time, share via `share_plus`), states locked/available/in-progress/completed, completion flow → optional reflection note → reward event, favorites. Reuse Foundation `CategoryCard`. If a shared `RewardEvent` model is needed and Foundation lacks it, define it now and **flag Foundation to adopt it** (promote to `lib/models/`).
- Content pack → `lib/features/cards/data/challenge_seed.json`: **200–300** challenges (~25–35/category), specific + actionable (not "be romantic today"), ids `ch_0001…`, per-category summary.

**3.3 Conversation Starters** (Bible §6)
- Engine (simpler — no swipe deck; clean single-card reveal, reuse shared transitions): categories Deep/Funny/Romantic/Future/Getting-to-Know-You-Again, Random + Browse modes, favorites, optional "answered together" boolean+timestamp persisted. Random mode must not repeat within a rolling window.
- Content pack → `lib/features/conversation/data/conversation_seed.json`: **300+** prompts (Deep & Funny weighted ~60–80 each, others ~40–60), genuinely thought-provoking/funny, ids `cv_0001…`, per-category summary. Depth indicator: reuse `Difficulty` if it maps, else a small separate enum (say which).

**Add deps:** `share_plus`.

**Exit Gate**
- [ ] All three full flows playable start→finish with real packs loaded.
- [ ] T/D swipe feels intentional (velocity-aware); filters narrow the deck; session summary counts accurate.
- [ ] Challenge Cards: 8 categories browsable w/ correct counts; completion persists → category progress %; share output well-formatted; locked cards don't crash.
- [ ] Conversation: random no-repeat window works; browse filters correctly; "answered together" persists.
- [ ] Favorites persist across restart in all three.
- [ ] typeIds registered; content packs validated as parseable JSON with QA summaries recorded.
- [ ] `flutter analyze` clean. Commit each module separately: `feat(td|cards|conversation): …`.

> **Content QA rule:** after each pack, spot-read 20 random items for voice + policy drift before accepting. An AI will happily claim balance it didn't hit — verify the QA summary against an actual count.

---

### Phase 4 — Advanced / Policy-Sensitive Modules
**Maps to:** Bible Prompts 6 (Positions ⚠) + 7 (Roleplay) · **Blocked by:** Phase 3 · **Est:** 5–7 days

**Goal:** the two richer modules. **Position Library carries the highest Play Store policy risk in the app** and per **D-3 is built now but excluded from the v1 bundle behind a feature flag.**

**4.1 Roleplay Stories** (Bible §8, lower risk — do first)
- Engine: story = title, 2 character roles (+ short descriptions), setting/goal, 2–3 on-demand twist beats, duration, tier, category (Fantasy/Romance/Adventure). Randomizer by category/tier. Themed packs (some premium-gated — reuse the gating pattern, don't reinvent). Favorites. Story-session screen: role assignment → setting/goal reveal → twist beats revealed **on demand** (not auto-timed).
- Content pack → `lib/features/roleplay/data/roleplay_seed.json`: **40–50** stories (even across 3 categories), community-theater-meets-date-night tone (masquerade ball, stranded travelers, secret agents), twists escalate scenario tension not graphic physical detail, ids `rp_0001…`, per-category summary.

**4.2 Position Library** ⚠ (Bible §7 — read Bible §7 preamble + §14 first)
- Engine: tiers Beginner/Comfort/Advanced (3–4 max), search by name/tag, optional reusable in-session timer component, favorites. Each entry: name, tier, short description, tags, **placeholder illustration slot** (asset-path field — real art is a separate design task, use tasteful icon+gradient placeholder). **Gate behind (1) one-time age/content-warning dialog (persisted) AND (2) `isPremiumProvider`** — flag the premium-by-default decision for product sign-off.
- **Feature-flag the entire module** (e.g. `kEnablePositionLibrary` compile-time const default `false`, or a remote flag) so v1 ships without it. Wire the flag so enabling it in v1.1 is a one-line change, not a re-integration.
- Content pack → `lib/features/positions/data/positions_seed.json`: **40–60** entries (weighted Beginner/Comfort), **STRICT** non-explicit editorial framing — evocative naming + 1–2 sentence mood/comfort framing, **no step-by-step, no anatomical detail**, all consensual/positive. ids `ps_0001…`. If an entry "needs" more explicit language to feel complete → stop and keep it at naming+mood level; flag the tension.

**Exit Gate**
- [ ] Roleplay: random selection respects filters; twist beats on-demand; pack grouping + premium gating render.
- [ ] Positions: age/content gate shows before first access + persists; filters/search work; placeholders render (no broken assets); module fully excludable via feature flag (verify a v1-config build has no Positions entry point).
- [ ] Both packs validated + QA summaries recorded; §14 compliance items acknowledged for Positions.
- [ ] `flutter analyze` clean. Commits: `feat(roleplay): …`, `feat(positions): … (flagged off for v1)`.

---

### Phase 5 — Daily Challenge
**Maps to:** Bible Prompt 8 · **Blocked by:** Phases 3 (+4 for roleplay pool) · **Est:** 3–4 days

**Goal:** a daily surface that composes from existing repositories (T/D, Cards, Conversation) plus ~30 original "ritual" prompts. No large new pack.

**Add deps:** `flutter_local_notifications`.

**Key requirements** (Bible §9)
- One challenge/day, **deterministic per device+date** (seed the pick from the date, not launch time — same all day across restarts).
- Streak tracking with an **explicitly documented grace-period rule** (pick one: hard reset vs once-a-week freeze; document why; flag for product sign-off).
- Calendar month-grid completion history (filled vs empty).
- Local notification reminder: implement permission request + trigger; copy/schedule **configurable**, not hardcoded. Must not crash on permission denial.
- Completion rewards: coordinate currency shape with Premium (Phase 6). If Premium hasn't run, define a minimal `RewardCurrency` service here and flag it for reuse.

**Exit Gate** (Bible Prompt 8 DoD)
- [ ] Same challenge consistent across a calendar day.
- [ ] Streak increments/resets per documented grace rule.
- [ ] Calendar reflects history accurately.
- [ ] Notification permission flow safe on denial.
- [ ] `flutter analyze` clean. Commit: `feat(daily): daily challenge + streaks`.

---

### Phase 6 — Premium / Monetization
**Maps to:** Bible Prompt 9 · **Blocked by:** Phases 2–5 (all gating touchpoints exist) · **Est:** 3–5 days

**Goal:** replace every stub `isPremiumProvider` with a real `subscriptionStatusProvider` **without changing any call site** (the payoff of D-5). Build the paywall.

**Add deps:** `purchases_flutter` (RevenueCat, D-2) — or `in_app_purchase` if D-2 is overridden.

**Key requirements** (Bible §10)
- Paywall: monthly/yearly/lifetime tiers, glass-blur+gradient treatment, **real** per-tier value bullets pulled from actual gated features (Dice custom sets, Challenge locked cards, Roleplay premium packs, Positions if enabled) — no placeholder bullets.
- Restore purchases flow.
- Single entitlement source of truth backing `subscriptionStatusProvider`; verify every prior stub call site now reflects real state with zero call-site edits.
- Coin/currency system if used, aligned with Daily's `RewardCurrency`.
- No-ads flag wired to premium (even if ads unbuilt).
- **Compliance:** all digital purchases route through Google Play Billing — flag any external-checkout path as a violation.

**Exit Gate** (Bible Prompt 9 DoD)
- [ ] Paywall renders per tier with real bullets.
- [ ] Purchase completes in sandbox/test.
- [ ] Restore re-unlocks gated content.
- [ ] Every previously-stubbed `isPremiumProvider` site reflects real subscription state, unchanged at the call site.
- [ ] `flutter analyze` clean. Commit: `feat(premium): paywall + entitlements`.

---

### Phase 7 — Profile, Settings, Statistics, Achievements
**Maps to:** Bible Prompt 10 · **Blocked by:** Phases 3–6 (data to aggregate) · **Est:** 3–4 days

**Goal:** a read-only aggregation layer over existing repositories + settings. **Do not duplicate progress data into a new store.**

**Key requirements** (Bible §11)
- Couple profile: names/nicknames, relationship start date ("together for X days"), optional local avatar (no upload backend).
- Aggregate stats from ≥3 modules (T/D completion by difficulty, Cards by category, Daily streak, Roleplay plays, favorites count) — read-only over existing repos.
- 10–15 rule-based achievements checked against existing data (e.g. "7-day streak", "Tried every category", "50 dares completed") — no new tracking system.
- Settings: theme (light-mode stub), notification prefs, haptics on/off, sound on/off, language (localization stub), data export/clear, privacy/terms links (**placeholder URLs, flagged as release-blocking until legal provides real ones**), subscription management deep-link to Premium.

**Exit Gate** (Bible Prompt 10 DoD)
- [ ] Stats accurately reflect real data from ≥3 modules (spot-check vs manually completed items).
- [ ] Achievements unlock correctly on criteria.
- [ ] Settings persist across restart.
- [ ] `flutter analyze` clean. Commit: `feat(profile): profile, settings, stats, achievements`.

---

### Phase 8 — Data Hardening, Localization, Firebase Wiring
**Maps to:** Bible Prompt 11 · **Blocked by:** Phase 7 · **Est:** 3–4 days

**Goal:** hardening pass, not new features.

**Add deps:** `flutter_localizations` (SDK), `intl`, `firebase_core`, `firebase_analytics`, `firebase_crashlytics`.

**Tasks** (Bible §12)
1. **Audit every Hive `typeId`** against `docs/planning/HIVE_TYPEIDS.md` — list all in use, resolve any collision **before** anything else.
2. Versioned Hive migration stub (schema-version field + migration function scaffold) so future pack updates don't corrupt user data.
3. Localization scaffolding: `flutter_localizations` + `intl`, extract **UI strings only** (not content-pack strings — that's a separate later effort) into ARB files, English base.
4. Firebase readiness: `firebase_core` init **guarded** (app still runs with no Firebase project); stub `AnalyticsService` events at funnel points (onboarding complete, first game played, paywall viewed, purchase completed) — no direct SDK coupling in feature code.
5. Crashlytics stub wired the same indirect way.
6. Idempotent first-launch **seed loader**: loads all content JSON into Hive once (not per launch), with a visible progress state if slow.

**Exit Gate** (Bible Prompt 11 DoD)
- [ ] No Hive typeId collisions.
- [ ] App runs identically with Firebase config absent (no crash).
- [ ] All hardcoded UI strings moved to ARB/intl.
- [ ] First-launch seeding idempotent (verified across two restarts).
- [ ] `flutter analyze` clean. Commit: `chore(hardening): hive migration, l10n, firebase wiring`.

---

### Phase 9 — Final Integration, Polish & Release QA
**Maps to:** Bible Prompt 12 · **Blocked by:** Phase 8 · **Est:** 4–6 days

**Goal:** whole-app integration + pre-release quality pass.

**Tasks** (Bible §13)
1. Wire the FAB "random game" (stubbed in Phase 1) to randomly launch a game module.
2. Home featured/popular sections pull **real** data (favorite counts, recently played), not Phase-1 mock values.
3. Full navigation audit: every route reachable, no dead ends, correct Android back behavior (card session → picker, not straight Home).
4. State-handling audit: every screen has genuine loading/empty/error states.
5. Performance: Riverpod `select` to kill needless rebuilds, builder-based lists, cached images.
6. Accessibility: semantic labels on icon-only buttons, WCAG AA contrast for text-over-gradient (double-check accent/secondary), reduced-motion respected.
7. App icon, splash, store assets — flag as design work outside codegen if not provided.

**Exit Gate** (Bible Prompt 12 DoD)
- [ ] `flutter analyze` + `flutter test` pass clean.
- [ ] No debug print/logging in release-path code.
- [ ] Placeholder legal URLs replaced or explicitly flagged as release-blocking.
- [ ] `flutter build appbundle` succeeds and installs on a clean device.
- [ ] Commit: `chore(release): integration, polish, QA pass`.

---

### Phase 10 — Release Compliance & Play Store Submission
**Maps to:** Bible §14 · **Blocked by:** Phase 9 · **Est:** 2–4 days (+ review latency)

**Goal:** clear the Play Store gate. This is product/legal judgment, not code — treat it as a hard gate before "Submit for review."

**Checklist** (Bible §14)
- [ ] **Content rating** questionnaire completed honestly (expect Mature 17+ if Positions/Extreme ship).
- [ ] **Sexual Content policy** re-read live at submission time; confirm compliance or hold Positions (per D-3, Positions is out of v1 → v1 should clear standard review far more easily).
- [ ] **Age-gating** at both in-app and (if required) account/listing level.
- [ ] **Distribution scope** decided — v1 ships without Positions (D-3); Positions revisited for v1.1 after listing approval.
- [ ] **Payments** all via Google Play Billing (no external checkout).
- [ ] **Data Safety form** matches reality (Analytics/Crashlytics if wired, else local-only).
- [ ] **Privacy Policy** live + linked (mandatory; doubly so for any Sexual-Content-rated release).
- [ ] **Ad networks:** if ads added later, note most (AdMob incl.) restrict Sexual-Content-rated apps — budget accordingly.

**Exit Gate**
- [ ] Signed release `appbundle` uploaded to a Play Console internal-testing track.
- [ ] All §14 items green or explicitly deferred with sign-off.
- [ ] Tag release `v1.0.0`. Commit: `chore(release): v1.0.0 submission`.

---

## 5. Critical Path & Sequencing Notes

```
0 Bootstrap → 1 Foundation ⭐ → 2 Dice (smoke test)
                                   → 3 Core content (TD, Cards, Conversation)
                                       → 4 Advanced (Roleplay; Positions ⚠ flagged off)
                                       → 5 Daily
                                           → 6 Premium (swaps stub flag)
                                               → 7 Profile/Stats
                                                   → 8 Hardening/L10n/Firebase
                                                       → 9 Integration/QA
                                                           → 10 Compliance/Submit
```

- **Phase 1 is the bottleneck.** A weak Foundation contract makes Phases 2–7 diverge. Over-invest here; snapshot the contract.
- **Phases 3.1/3.2/3.3 can parallelize** across developers/agents *if* Phase 2 validated the architecture — each is independent and only depends on the Foundation contract. Content-pack generation for all of them can run in parallel background sessions.
- **Phase 6 must come after all gating touchpoints exist** (2–5) or you'll retrofit call sites — exactly what D-5 exists to prevent.
- **Positions (Phase 4.2)** is built but flag-gated off; it does not block the v1 critical path and does not gate Phase 5+.

**Rough total:** ~35–50 working days for a single focused engineer/agent; less with content packs parallelized.

---

## 6. Top Risks (and the mitigation baked into the plan)

<table>
<tr><th>Risk</th><th>Mitigation</th></tr>
<tr><td>Interface drift across 10 modules</td><td>One Foundation contract + `CONTRACT_SNAPSHOT.md` pasted into every session (Phase 1 gate)</td></tr>
<tr><td>Hive typeId collisions (the classic multi-module Hive failure)</td><td>Running <code>HIVE_TYPEIDS.md</code> registry from Phase 1; formal audit in Phase 8</td></tr>
<tr><td>Premium gating retrofit pain</td><td>Single <code>isPremiumProvider</code> stub (D-5) swapped once in Phase 6, zero call-site edits</td></tr>
<tr><td>Play Store rejection over Sexual Content</td><td>Positions held for v1.1 (D-3), text-only non-explicit framing, §14 gate before submit</td></tr>
<tr><td>Shallow content packs</td><td>Content generated in separate sessions from code; 20-item spot-read + QA-count verification per pack</td></tr>
<tr><td>Payment policy violation</td><td>Google Play Billing only (RevenueCat/D-2); external-checkout flagged as violation in Phase 6</td></tr>
</table>

---

## 7. Companion Docs to Create as You Go

- `ARCHITECTURE.md` (Phase 1) — conventions of record.
- `docs/planning/CONTRACT_SNAPSHOT.md` (Phase 1) — the exact generated contract code to paste between prompts.
- `docs/planning/HIVE_TYPEIDS.md` (Phase 1, maintained throughout) — typeId registry.
- Per-phase PR descriptions doubling as changelog entries.

---

*This plan operationalizes `veloura-prompt-bible.md`. Where the Bible and this plan differ in emphasis, the Bible governs content voice and compliance; this plan governs order, dependencies, stack versions, and gates. Update this file (don't fork decisions silently) whenever a phase forces a change to the Foundation contract.*
