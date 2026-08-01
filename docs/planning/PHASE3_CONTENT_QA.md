# Phase 3 Content QA

Generated deterministically and validated by `tools/generate_phase3_content.py`.

## Counts

- Truth or Dare: **500** (cute 130, romantic 150, spicy 150, extreme 70; even truth/dare per tier; all five categories in every tier).
- Challenge Cards: **256** (32 in each of exactly eight categories).
- Conversation Starters: **75** (15 per category: Deep, Funny, Romantic, Future, Getting-to-Know-You-Again). Hand-written, fully unique, short and easy-English prompts — no repeated template suffixes.
- IDs and all 500 Truth or Dare prompt strings are unique; all files are valid JSON.

## Deterministic 20-item spot read

- `td_0432` — Take turns naming one adventurous yes, one maybe, and one clear no. Focus on how you work as a team.
- `td_0218` — Look into your partner’s eyes and finish: “I choose you because…” Take a breath and answer honestly.
- `td_0345` — Which romantic tension in a movie reminds you of us? Let a shared memory guide your answer.
- `td_0243` — Which memory of us still gives you butterflies? Imagine without pressure to make it real.
- `td_0195` — When do you feel most emotionally close to me? Let a shared memory guide your answer.
- `td_0356` — Whisper a confident compliment and let the silence linger for five seconds. Let a shared memory guide your answer.
- `td_0424` — Create a secret flirt signal to use during your next date. Imagine without pressure to make it real.
- `td_0104` — Send your partner a message they can save for a difficult day. Imagine without pressure to make it real.
- `ch_0148` — Kindness spark 20 — Offer twenty minutes of practical help and finish by sharing what felt best. Keep the plan specific, mutual, and easy to complete.
- `ch_0123` — Playful spark 27 — Create a secret handshake using only what you already have. Keep the plan specific, mutual, and easy to complete.
- `ch_0089` — Connection spark 25 — Trade three thoughtful questions together tonight. Keep the plan specific, mutual, and easy to complete.
- `ch_0096` — Connection spark 32 — Name one way you can support each other and finish by sharing what felt best. Keep the plan specific, mutual, and easy to complete.
- `ch_0117` — Playful spark 21 — Invent a ridiculous contest together tonight. Keep the plan specific, mutual, and easy to complete.
- `ch_0144` — Kindness spark 16 — Offer twenty minutes of practical help and finish by sharing what felt best. Keep the plan specific, mutual, and easy to complete.
- `cv_0067` — What's a part of you I don't ask about enough?
- `cv_0017` — If we were a movie, what's the title?
- `cv_0059` — How do you want us to grow closer this year?
- `cv_0041` — What's the sexiest thing about our relationship?
- `cv_0042` — What's one thing you'd love us to try together?
- `cv_0045` — How do you want me to show love to you today?

## Editorial safeguards

- Spicy content is suggestive, not explicit.
- Extreme prompts emphasize consent, boundaries, and pause rights.
- Challenge prompts are specific and actionable.
- No anatomical instructions or non-consensual framing are present.
