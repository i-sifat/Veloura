# Phase 8 — Hardening report

## Hive audit

The full adapter audit found three adapters and no collisions: `DiceRollRecord` = 1, `Player` = 2, `GameSession` = 3. The registry now rejects duplicate semantic IDs before boxes open. `HIVE_TYPEIDS.md` is the record of truth.

## Schema migrations

`SchemaMigrationService` stores an ordered integer version in `app_metadata`. Version 1 is the current baseline and requires no data rewrite because all existing adapters use stable numeric field indexes. Future changes add one ordered case and never reuse adapter IDs or field indexes.

## Seed bootstrap

`ContentSeedService` copies the four immutable JSON packs into `content_seed_cache` once per seed version. A second launch is a no-op. Existing repositories remain the only read boundaries, so the bootstrap adds migration readiness without coupling widgets to Hive.

## Localization

The app now registers Flutter Material/Cupertino/Widgets localization delegates and loads English shell strings from `lib/l10n/app_en.arb`. Navigation and application identity consume the facade. Feature copy remains represented in English and can move behind the same facade incrementally when translated content locales are commissioned; content-pack translation is explicitly outside Phase 8.

## Firebase

`initializeFirebaseSafely()` activates Analytics and Crashlytics only when native Firebase configuration exists. An unconfigured build catches initialization failure and runs with no-op services. Feature code depends only on `AnalyticsService` and `CrashReportingService`.

Currently wired funnel events:
- `paywall_viewed` with `source`
- `purchase_completed` with `package_id`

Onboarding does not exist yet, so no onboarding completion event is emitted. First-game analytics remains a Phase 9 integration point alongside unified game events.

## Required deployment configuration

- Android: add the real `google-services.json` and Google Services Gradle wiring.
- iOS: add the real `GoogleService-Info.plist`.
- Verify Analytics DebugView and a non-fatal Crashlytics test in configured internal builds.

None of these files or secrets are committed. Their absence is supported and tested by design.
