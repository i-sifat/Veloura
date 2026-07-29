# 00 — Veloura Games Design System

Single source of truth for the Games experience. Implemented in **`lib/theme/game_tokens.dart`**
as a class `GameTokens` with `static const` members. Nothing below may be re-declared inline
in a widget.

Base grid = 4pt. Reference viewport = **390 x 844** (iPhone 14). Must also be verified at
**360 x 800** (small Android) and **430 x 932** (Pro Max).

---

## 1. Color palette — "plum noir + rose"

### Backdrop
```
bgTop        #1A0620
bgMid        #2B0B36
bgBottom     #47124F
bgVignette   #0B0210
```

### Surfaces
```
glass        #FFFFFF @ 6%     // panel fills
glassStrong  #FFFFFF @ 10%    // pressed / selected panels
hairline     #FFFFFF @ 12%    // 1px borders
sheet        #21082A          // bottom sheets (96% opaque)
scrim        #08010C @ 60%    // modal barrier
```

### Accents
```
rose         #FF3366   // primary action
roseLight    #FF6B9D   // highlights, active glow
roseDeep     #C81E67   // gradient end, pressed
gold         #F2C879   // premium only — never for normal actions
```

### Text
```
textHi       #FFFFFF
textMid      #FFFFFF @ 72%
textLow      #FFFFFF @ 48%
textOnLight  #2A0A2E   // text printed on dice faces / light cards
```

### Semantic
```
success      #3ED598
warning      #FFB020
```

### Screen backdrop recipe (`GameBackdrop`)
```
Stack, bottom → top:
1. LinearGradient(topLeft → bottomRight, [bgTop, bgMid, bgBottom], stops [0.0, 0.55, 1.0])
2. RadialGradient(center: Alignment(0, -0.35), radius 0.95, [#5B1668 @ 55%, transparent])
3. Vignette: RadialGradient(center: center, radius 1.05, [transparent, bgVignette])
```

### Tile / deck gradients (135°, topLeft → bottomRight)
```
lustfulRolls          #5B2A9D → #8E4BD1
cardChallenge         #B01047 → #E5326E
truthOrDare           #6C1450 → #A02268
creativeConnections   #7A1D8F → #B03CC0
followTheTempo        #22114A → #4B2B8F
passionateRoleplay    #8E0F3C → #C2185B
```
Every gradient surface also gets an inner top-left highlight:
`LinearGradient([#FFFFFF @ 14%, transparent], stops [0.0, 0.45])`.

### Card Challenge deck colors
```
Sensual    base #6A1B9A   glow #C77DFF   label "SENSUAL"    glyph heart_spark.svg
Sexy       base #C2185B   glow #FF5C8A   label "SEXY"       glyph chili.svg
Superhot   base #8E0B2E   glow #FF2D55   label "SUPERHOT"   glyph flame.svg
```

### Wheel palette (10 segments, in order)
```
1 #FF4D94   2 #F7E7EF   3 #FFA8CE   4 #FFFFFF   5 #FF6BA8
6 #F3DCE8   7 #FF4D94   8 #FFFFFF   9 #FFA8CE  10 #F7E7EF
hub: radial [rose → roseDeep], 3px white ring
```

---

## 2. Type scale (Poppins, inherited from the app theme)

| Token | Size / line-height | Weight | Letter-spacing | Use |
|---|---|---|---|---|
| `heroDisplay` | 32 / 36 | 700 | -0.4 | "SPIN THE WHEEL TO PLAY" |
| `resultHero` | 28 / 34 | 700 | -0.2 | roll / dare result sentence |
| `screenTitle` | 17 / 22 | 600 | 0 | app bar title |
| `hubTitle` | 15 / 20 | 700 | 1.6 | "SELECT A GAME" (uppercase) |
| `tileTitle` | 16 / 19 | 700 | 0.6 | grid tile name (uppercase, 2 lines) |
| `cardLabel` | 13 / 16 | 700 | 1.4 | SEXY / SUPERHOT / TRUTH (uppercase) |
| `promptBody` | 19 / 27 | 600 | 0 | card + question text |
| `bodyMid` | 15 / 22 | 400 | 0 | the one supporting line |
| `chipLabel` | 13 / 16 | 600 | 0.2 | player chips, duration chips |
| `caption` | 12 / 16 | 500 | 0.3 | footnotes, hints |
| `ctaLabel` | 16 / 20 | 600 | 0.4 | primary button |

Hard limit: **one** `bodyMid` line per screen. Longer explanations go in the info sheet.

---

## 3. Spacing, radii, shadows

```
space steps      4 · 8 · 12 · 16 · 20 · 24 · 32 · 40
screenPadH       20
gridGutter       12
sectionGap       24
bottomCtaInset   max(safeAreaBottom, 12) + 12

radii            chip 999 · card 18 · tile 22 · sheet 28 (top only) · cta 28 · diceFace 14

shadows
  tile      offset (0, 8)   blur 24   #000 @ 34%
  cta       offset (0, 6)   blur 18   rose @ 34%
  sheet     offset (0, -12) blur 32   #000 @ 40%
  cardGlow  offset (0, 0)   blur 18   spread -2   deckGlow @ 28%
```

---

## 4. Motion

| Token | Duration | Curve |
|---|---|---|
| `tapScale` | 110ms | easeOut (1.0 → 0.97) |
| `fade` | 220ms | easeOut |
| `sheetIn` | 320ms | easeOutCubic |
| `diceTumble` | 1800ms | easeOutQuart (rotation) + easeOutCubic (arc) |
| `diceSettle` | 260ms | easeOutBack (overshoot 0.06) |
| `cardFan` | 420ms | easeOutCubic, 60ms stagger |
| `cardFlip` | 620ms | easeInOutCubic |
| `wheelSpin` | 4200ms | `Cubic(0.12, 0.78, 0.06, 1.0)` |
| `pulseGlow` | 900ms | easeInOut, repeat reverse |
| `breathe` | 3200ms | easeInOut, repeat reverse |

Perspective for all 3D transforms: `Matrix4.identity()..setEntry(3, 2, 0.0012)`.

---

## 5. Haptics (`HapticFeedback` from `flutter/services`)

```
tile tap / CTA press        lightImpact
dice leaves the hand        lightImpact
dice contacts the board     mediumImpact   (max 2 contacts per throw)
dice settled / reveal       heavyImpact
wheel segment tick          selectionClick (throttle: min 45ms apart)
card flip completes         mediumImpact
tempo beat                  lightImpact    (max 2 per second)
```
A single "Vibration" switch in the gear sheet mutes all of it (default on).

---

## 6. Shared widgets — `lib/shared/widgets/game/`

| File | Widget | Spec |
|---|---|---|
| `game_backdrop.dart` | `GameBackdrop({child, board = false})` | §1 recipe; `board: true` adds the felt layer from Phase 2 |
| `game_app_bar.dart` | `GameAppBar({title, leading, onInfo})` | height 56; leading 44x44 tap target, icon 22 `textHi`; title `screenTitle` centered; trailing info 20 `textMid @ 70%` |
| `turn_chip_bar.dart` | `TurnChipBar()` | height 36; avatar 26 circle (player color + initial `chipLabel`) · 6 · name `chipLabel` `textHi` · 8 · chevron_right 14 `rose` · 8 · partner chip at 45% opacity |
| `primary_cta.dart` | `PrimaryCta({label, icon, onPressed, busy})` | width `screenWidth - 40`, height 56, radius 28, gradient `[rose, roseDeep]` 90°, shadow `cta`, `ctaLabel` white; disabled = 38% opacity, no shadow; press = `tapScale` |
| `secondary_text_button.dart` | `SecondaryTextButton({label, onTap})` | height 44, `caption` `textMid`, no background |
| `result_sheet.dart` | `ResultSheet.show(context, ...)` | modal bottom sheet; `sheet` fill; radius 28 top; drag handle 36x4 `#FFFFFF @ 24%` at 10 from top; padding 24; `isScrollControlled: true`; barrier `scrim`; `sheetIn` |
| `glass_panel.dart` | `GlassPanel({child, radius})` | `glass` fill + 1px `hairline` border + inner top highlight |
| `premium_lock_badge.dart` | `PremiumLockBadge()` | 22px pill, `gold @ 16%` fill, lock icon 12 `gold`, "PRO" 10/12 w700 `gold` |
| `game_tile_glyph.dart` | `GameTileGlyph({icon})` | fallback art: icon 44 `#FFFFFF @ 90%` over a `roseLight @ 18%` radial glow |
| `game_preferences_sheet.dart` | `GamePreferencesSheet.show(context)` | the ONLY place toggles live: third die, vibration, sound, custom faces (premium), soften decks |

---

## 7. Assets

```
assets/games/tiles/lustful_rolls.png          600x600 · transparent · art bleeds to the bottom edge
assets/games/tiles/card_challenge.png
assets/games/tiles/truth_or_dare.png
assets/games/tiles/creative_connections.png
assets/games/tiles/follow_the_tempo.png
assets/games/tiles/passionate_roleplay.png
assets/games/scenes/*.png                     880x1200 · roleplay scene art (Phase 7)
assets/games/felt_noise.png                   256x256 tileable mono noise, used at 5% opacity
assets/icons/chili.svg  flame.svg  heart_spark.svg  lips.svg
```
Register the folders in `pubspec.yaml` under `assets:`. **Every** `Image.asset` must supply an
`errorBuilder` that falls back to `GameTileGlyph` — a missing asset can never break the build or
render a grey box.
