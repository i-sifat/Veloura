# Onboarding flow

Onboarding was mentioned only as a lightweight Foundation flag and analytics funnel event; no implementation phase or screen specification existed. This flow closes that product gap before Phase 9.

## Experience

1. **Welcome** — explains Veloura as a private couples connection app.
2. **Privacy** — states that names, progress, favorites, and activity remain local by default.
3. **Shared turns** — explains that saved player names appear throughout games and turn tracking.
4. **Players** — captures two names and creates the shared `GameSession` used by every game.

The flow deliberately does not ask for notification or tracking permission. Daily reminders request permission contextually when enabled, and Firebase remains disabled when native configuration is absent.

## Persistence and migration

- Player names are saved in the local Hive-backed `GameSession` and are read by shared game turn UI.
- `onboarding_seen=true` marks completion.
- Existing installs with `session_players_configured=true` skip onboarding automatically.
- Completion writes both flags so the Games hub does not reopen its legacy player sheet.
- All protected routes redirect to `/onboarding` until setup is complete.

## Analytics

Completion emits `onboarding_complete` through `AnalyticsService`; unconfigured Firebase builds safely no-op.
