# Roleplay Scenario Format Guide

This is the format to use when writing new Passionate Roleplay scenarios by hand. Follow it exactly so entries can be dropped straight into `roleplay_scenarios_seed.json` (the file the app reads at runtime).

## How the feature works now

Passionate Roleplay is a spin-wheel game (same mechanic as Truth or Dare, recolored):

1. The couple spins the wheel. It lands on a **category**.
2. The app draws a random scenario from that category.
3. The app randomly decides which of the two real signed-up names plays `@CharacterA` and which plays `@CharacterB` (a fresh coin flip every spin).
4. The scenario is revealed on a solid-color card, with `@CharacterA` / `@CharacterB` replaced live by the couple's actual names (e.g. "You play The Hidden Host...").

So every entry needs a short **role label** for each side, plus one flowing **description** paragraph that reads naturally once the placeholders are swapped for real names.

## Hard rules (non-negotiable)

Entries that break any of these will be rejected outright, no exceptions:

1. **No family/relative pairings of any kind** — no step-relations, in-laws, cousins, aunts/uncles/nieces/nephews, guardians/wards, age-gap "parent-figure" dynamics, etc. Both roles must be unrelated adults.
2. **No coercion, fear, tears, "no becomes yes," or reluctance framed as arousing.** Both characters choose to be there and want to be there from the first line. Tension/nerves/butterflies are fine ("first date jitters"); fear, protest, or one side overriding the other's hesitation is not.
3. **No exploitation of vulnerability** — no power imbalance used as leverage (blackmail, "do this or else," trading survival/safety/documents/jobs for sex, employer-employee or teacher-student dynamics where one side can punish the other).
4. **No religious authority figures, rituals, religious dress/objects, or scripture used as a setting, character, or plot device**, in any faith. Skip clergy, religious teachers, houses of worship, religious ceremonies, and religious texts entirely.
5. **Both characters are clearly adults** with no age specified below adult, and nothing implying a power gap tied to age.

If you're unsure whether something crosses a line, leave it out and ask first.

## What's encouraged

Playful premises with a clear setting, a bit of tension, and mutual, obvious desire: strangers-to-something, fantasy/adventure roleplay, light power-play between equals (e.g. two secret agents, rival treasure hunters), romantic/nostalgic scenes, silly or theatrical setups. Look at the existing 42 scenarios in `roleplay_scenarios_seed.json` for tone — they're the safe baseline this replaces/extends.

## Entry format

Write each entry as plain text using this exact block shape — one blank line between entries:

```
### <Title>
category: <fantasy | romance | adventure>
tier: <cute | romantic | spicy | extreme>
roleA: <short role label for Character A, e.g. "The Hidden Host">
roleB: <short role label for Character B, e.g. "The Curious Guest">
premium: <true | false>
description: <One flowing paragraph. Use the literal tokens @CharacterA and @CharacterB
  anywhere you want a name inserted. Weave in both roles, the setting, and what the
  couple is meant to do or feel. 2-5 sentences.>
```

### Field reference

| Field | Notes |
|---|---|
| `category` | Pick one of the three existing categories. Ask if you want a new category added — it requires a small code change. |
| `tier` | Intensity, reused from the rest of the app: `cute` → `romantic` → `spicy` → `extreme`. `extreme` entries are gated behind Premium automatically, so also set `premium: true` for those. |
| `roleA` / `roleB` | Short in-world title, not a person's name (e.g. "The Getaway Driver", not "John"). This is what's shown before the couple's real names are assigned. |
| `premium` | `true` to lock the entry behind Veloura Premium, `false` for free. |
| `description` | The only place `@CharacterA` / `@CharacterB` should appear. Spell them exactly like that (case-sensitive) — anything else won't get replaced. Keep it a single paragraph; no line breaks inside it. |

### Worked example (safe, ready to use)

```
### The Late Shift Handoff
category: adventure
tier: spicy
roleA: The Outgoing Guard
roleB: The New Recruit
premium: false
description: @CharacterA has run this rooftop post alone for years and isn't used to
  company. @CharacterB just transferred in, eager to impress and openly curious about
  the rumors of a hidden signal only the outgoing guard knows how to read. As the city
  lights come up below them, @CharacterA finally decides the new recruit has earned
  the secret — and maybe something else too.
```

## Submitting entries

Send me a batch of entries in the block format above (any number at once). I'll validate each one against the rules, convert it into the JSON the app actually loads, and wire it into the wheel. I'll flag anything that needs a rewrite before it goes in — nothing gets added silently.
