# Phase 6 — Premium setup

## Billing decision

Veloura uses RevenueCat (`purchases_flutter`) as decided in D-2. RevenueCat delegates Android purchases to Google Play Billing and iOS purchases to StoreKit; no external checkout is implemented.

## Required dashboard setup

1. Create the `premium` entitlement in RevenueCat.
2. Attach monthly, annual, and lifetime store products to the current offering.
3. Build Android with `--dart-define=REVENUECAT_ANDROID_API_KEY=...`.
4. Build iOS with `--dart-define=REVENUECAT_IOS_API_KEY=...`.
5. Verify purchase and restore in Google Play / App Store sandbox accounts before release.

When keys are absent, the app remains usable and the paywall shows an explicit configuration notice. It never grants Premium locally.

## Entitlement contract

`subscriptionStatusProvider` is the source of truth. The original `isPremiumProvider` remains the bool projection consumed by all pre-Phase-6 call sites, so entitlement wiring requires no feature-level provider migration. `noAdsProvider` is the same projection reserved for future ad surfaces.

## Paywall source tags

Gated surfaces route to `/premium?source=...`. Current source tags include Games hub Superhot, custom dice faces, and premium Roleplay packs. Phase 8 analytics consumes the same source value without changing navigation call sites.

## Release blocker

Sandbox purchase and restore must be verified with real RevenueCat public SDK keys and configured store products. CI validates compilation and mock entitlement behavior but cannot complete a store transaction.
