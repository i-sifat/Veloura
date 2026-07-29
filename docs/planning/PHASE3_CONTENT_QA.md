# Phase 3 Content QA

Generated deterministically and validated by `tools/generate_phase3_content.py`.

## Counts

- Truth or Dare: **500** (cute 130, romantic 150, spicy 150, extreme 70; even truth/dare per tier; all five categories in every tier).
- Challenge Cards: **256** (32 in each of exactly eight categories).
- Conversation Starters: **320** (Deep 70, Funny 70, Romantic 60, Future 60, Getting-to-Know-You-Again 60).
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
- `cv_0265` — What would you love me to understand about who you are becoming? What makes that answer true for you?
- `cv_0068` — What does a meaningful life look like to you right now? What is the most playful version of your answer?
- `cv_0235` — Which future version of us are you most curious to meet? What surprised you while thinking about it?
- `cv_0164` — Which future tradition would you love us to create? What is one small example from this month?
- `cv_0294` — What small preference of yours may have changed lately? What surprised you while thinking about it?
- `cv_0166` — Which moment with me felt unexpectedly romantic? How could the two of you explore that together?

## Editorial safeguards

- Spicy content is suggestive, not explicit.
- Extreme prompts emphasize consent, boundaries, and pause rights.
- Challenge prompts are specific and actionable.
- No anatomical instructions or non-consensual framing are present.
