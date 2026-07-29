# Phase 5 — Daily Challenge decisions

## Streak rule: hard reset

A missed calendar day resets the streak. A streak completed through yesterday remains visible during the current day, then resets if today expires without completion.

**Why:** this is transparent and local-first. A weekly freeze would require hidden state, recovery rules, and a future decision about whether freezes are earned or monetized. Phase 5 does not silently spend reward currency. This rule is implemented and tested, but remains flagged for product sign-off before release.

## Reward currency

Daily completion awards **10 sparks**, once per local date. `RewardCurrencyService` is the shared minimal contract; Phase 6 must reuse or extend it instead of creating a second balance.

## Reminder scheduling

Reminder copy and time are persisted configuration. Permission is requested only when reminders are enabled, and denial leaves the feature disabled without throwing. Seven one-shot local notifications are refreshed on app launch/settings changes so local wall-clock time is preserved without adding a device-timezone discovery dependency. Android boot/package-replacement receivers preserve scheduled notifications across restarts.

## Content composition

The deterministic pool combines:

- 30 authored daily rituals
- non-Extreme Truth or Dare items
- non-premium Challenge Cards
- Conversation Starters

Selection uses a stable device seed plus local calendar date, so the challenge does not change during the day or across app restarts.
