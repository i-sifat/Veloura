# Veloura

> A private, playful couples app — built by one dev, for two people.

Veloura is a small corner of the internet where you and your partner can put the
phones down and actually connect. Six little games, a shared local device, and
zero judgment.

Everything lives on your phone. No accounts, no cloud, no strangers — just the
two of you.

---

## The Games

| Game | Vibe |
|---|---|
| **Love Dice** | Let fate decide — roll action, place, and twist. |
| **Card Challenge** | Flip a mystery card and reveal a desire. |
| **Truth or Dare** | The classic, spun up with a real wheel. |
| **Creative Positions** | Spin a zone, hold the position as the ring counts down. |
| **Follow the Tempo** | Move together, one pulse at a time. |
| **Passionate Roleplay** | Become someone else for a night. |

Every game is two-player, local-first, and tuned to feel good in the moment —
not like a productivity dashboard.

---

## Built With Care

- **Flutter** — one codebase, dark-first Material 3 design.
- **Riverpod** — clean, testable state without the ceremony.
- **go_router** — navigation that doesn't get in the way.
- **Hive CE** — fast, private, on-device persistence.
- **No backend.** Your data never leaves the device.

The whole thing is hand-rolled and open — no templates, no black boxes. If it
breaks, one dev fixes it. Usually that dev is drinking coffee at 2am.

---

## Running It

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

Generated `*.g.dart` / `*.freezed.dart` files are committed so local builds and
CI stay in lockstep.

---

## Architecture (the short version)

- `lib/core/` — app results, shared contracts, and reusable boundaries.
- `lib/config/` — routing and the four-tab navigation shell.
- `lib/features/` — isolated modules, each with presentation / domain / data.
- `lib/models/` — stable cross-feature contracts.
- `lib/services/` — storage, adapter registration, and SDK-neutral services.
- `lib/shared/widgets/` — the design system: glass panels, shells, chips.
- `lib/theme/` — the semantic palette and game tokens.

Dependencies point inward, widget trees stay small, and business logic lives
where you can actually test it.

---

## License

Private project. Made for two. If you're one of those two — enjoy.
