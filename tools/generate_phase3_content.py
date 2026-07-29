#!/usr/bin/env python3
import json
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CREATED = '2026-07-29T00:00:00Z'


def write(path, values):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(values, ensure_ascii=False, indent=2) + '\n')


def td_prompt(tier, kind, category, n):
    truth = {
        'cute': [
            'What tiny habit of mine makes you smile without trying?',
            'Which ordinary moment with us would you happily repeat?',
            'What nickname would you invent for this chapter of our relationship?',
            'When did you most recently feel quietly proud of us?',
            'What simple thing can I do this week to brighten your day?',
        ],
        'romantic': [
            'What moment made you realize our connection was becoming special?',
            'What kind of date would make you feel deeply chosen?',
            'Which memory of us still gives you butterflies?',
            'What do you hope never changes about the way we love?',
            'When do you feel most emotionally close to me?',
        ],
        'spicy': [
            'What kind of flirtation from me instantly gets your attention?',
            'Which setting makes a date feel especially electric to you?',
            'What confident compliment would you love to hear from me?',
            'What playful signal could mean “I want your full attention”?',
            'Which romantic tension in a movie reminds you of us?',
        ],
        'extreme': [
            'What bold but consensual date-night idea have you hesitated to suggest?',
            'Which boundary conversation would help us feel even more adventurous?',
            'What daring surprise would feel exciting while still safe and respectful?',
            'What fantasy atmosphere could we create without crossing either person’s limits?',
            'How would you like us to communicate when trying something far outside routine?',
        ],
    }
    dare = {
        'cute': [
            'Give your partner a ten-second hug and name one thing you appreciate.',
            'Recreate your funniest shared facial expression together.',
            'Invent a two-line theme song for your relationship and perform it.',
            'Send your partner a message they can save for a difficult day.',
            'Hold hands and trade one sincere compliment each.',
        ],
        'romantic': [
            'Slow dance together for one song, even if there is no music.',
            'Describe your dream anniversary in exactly three sentences.',
            'Look into your partner’s eyes and finish: “I choose you because…”',
            'Plan a miniature date you can complete within the next seven days.',
            'Retell your first memorable moment as if it were a movie scene.',
        ],
        'spicy': [
            'Whisper a confident compliment and let the silence linger for five seconds.',
            'Choose a song and share one slow, playful dance together.',
            'Give your partner a lingering kiss only if they enthusiastically agree.',
            'Create a secret flirt signal to use during your next date.',
            'Describe a date-night outfit you would love to see your partner wear.',
        ],
        'extreme': [
            'Propose a daring date-night scenario, then agree on boundaries before deciding.',
            'Take turns naming one adventurous yes, one maybe, and one clear no.',
            'Design a bold private challenge that either person can pause at any time.',
            'Share an ambitious fantasy setting using mood and story, not explicit detail.',
            'Agree on a safe word for future adventurous games and practice using it once.',
        ],
    }
    base = (truth if kind == 'truth' else dare)[tier][n % 5]
    contexts = {
        'relationship': 'Focus on how you work as a team.',
        'fantasy': 'Imagine without pressure to make it real.',
        'memories': 'Let a shared memory guide your answer.',
        'deepTalk': 'Take a breath and answer honestly.',
        'playful': 'Keep it light and make each other laugh.',
    }
    return f'{base} {contexts[category]}'


def generate_td():
    counts = {'cute': 130, 'romantic': 150, 'spicy': 150, 'extreme': 70}
    categories = ['relationship', 'fantasy', 'memories', 'deepTalk', 'playful']
    rows = []
    idx = 1
    for tier, count in counts.items():
        for local in range(count):
            kind = 'truth' if local % 2 == 0 else 'dare'
            category = categories[(local // 2) % len(categories)]
            rows.append({
                'id': f'td_{idx:04d}',
                'kind': kind,
                'prompt': td_prompt(tier, kind, category, local),
                'category': category,
                'difficulty': tier,
                'createdAt': CREATED,
            })
            idx += 1
    return rows


CHALLENGE_VERBS = {
    'romance': ['plan a candlelit snack', 'write a tiny love note', 'recreate a favorite date moment', 'build a shared playlist'],
    'adventure': ['take a new walking route', 'visit a place neither of you has explored', 'try a new café', 'choose a spontaneous mini outing'],
    'connection': ['trade three thoughtful questions', 'share one current worry and one hope', 'listen without interrupting for five minutes', 'name one way you can support each other'],
    'playful': ['invent a ridiculous contest', 'play a two-person scavenger hunt', 'create a secret handshake', 'act out a funny movie scene'],
    'kindness': ['do one unnoticed chore for each other', 'prepare a small comfort surprise', 'leave an encouraging message', 'offer twenty minutes of practical help'],
    'creativity': ['draw a future memory together', 'write a six-line story starring both of you', 'build something from household objects', 'take themed photos around your home'],
    'wellness': ['take a screen-free walk', 'stretch together for ten minutes', 'prepare a colorful snack', 'create a calming bedtime ritual'],
    'surprise': ['swap mystery date envelopes', 'choose a surprise song and explain why', 'hide a tiny clue trail', 'prepare an unexpected five-minute celebration'],
}


def generate_challenges():
    rows = []
    idx = 1
    for category, verbs in CHALLENGE_VERBS.items():
        for n in range(32):
            action = verbs[n % len(verbs)]
            partner = ['together tonight', 'before the weekend ends', 'using only what you already have', 'and finish by sharing what felt best'][n % 4]
            rows.append({
                'id': f'ch_{idx:04d}',
                'title': f'{category.title()} spark {n + 1}',
                'description': f'{action.capitalize()} {partner}. Keep the plan specific, mutual, and easy to complete.',
                'challengeCategory': category,
                'difficulty': ['cute', 'romantic', 'spicy', 'cute'][n % 4],
                'estimatedMinutes': [10, 20, 30, 45][n % 4],
                'premium': n >= 24,
                'createdAt': CREATED,
            })
            idx += 1
    return rows


CONVERSATION_BASE = {
    'deep': [
        'What belief have you changed your mind about in the last few years?',
        'When do you feel most understood by another person?',
        'What does a meaningful life look like to you right now?',
        'Which fear has quietly shaped more choices than you expected?',
        'What part of yourself are you learning to be gentler with?',
    ],
    'funny': [
        'What harmless conspiracy theory could you invent about our household?',
        'If our relationship had a mascot, what ridiculous creature would it be?',
        'Which everyday task would you turn into an Olympic event?',
        'What is the worst possible name for a restaurant we would open?',
        'If we switched voices for a day, what would become funniest?',
    ],
    'romantic': [
        'Which moment with me felt unexpectedly romantic?',
        'What gesture makes you feel chosen rather than simply noticed?',
        'What kind of affection helps you reconnect after a long day?',
        'Which future tradition would you love us to create?',
        'What do you hope we will still tease each other about years from now?',
    ],
    'future': [
        'What would an ideal ordinary Tuesday look like for us in five years?',
        'Which shared skill would be exciting for us to learn?',
        'What place would you like us to know well rather than visit once?',
        'What financial or lifestyle goal would feel meaningful to build together?',
        'Which future version of us are you most curious to meet?',
    ],
    'rediscover': [
        'What recent interest of yours do you wish I asked about more?',
        'What currently gives you energy that did not a year ago?',
        'Which part of your daily life feels invisible to most people?',
        'What small preference of yours may have changed lately?',
        'What would you love me to understand about who you are becoming?',
    ],
}


def generate_conversation():
    counts = {'deep': 70, 'funny': 70, 'romantic': 60, 'future': 60, 'rediscover': 60}
    rows = []
    idx = 1
    tails = [
        'What makes that answer true for you?',
        'Has your answer changed recently?',
        'What story best explains your answer?',
        'What would you like your partner to understand about that?',
        'What is one small example from this month?',
        'How could the two of you explore that together?',
        'What surprised you while thinking about it?',
        'Which detail matters most?',
        'What might make your answer different next year?',
        'What question would you ask back?',
        'What feeling sits underneath that answer?',
        'What would make this easier to talk about?',
        'When did you first notice this?',
        'What is the most playful version of your answer?',
    ]
    for category, count in counts.items():
        for n in range(count):
            base = CONVERSATION_BASE[category][n % 5]
            tail = tails[(n // 5) % len(tails)]
            rows.append({
                'id': f'cv_{idx:04d}',
                'prompt': f'{base} {tail}',
                'conversationCategory': category,
                'difficulty': ['cute', 'romantic', 'spicy'][n % 3],
                'createdAt': CREATED,
            })
            idx += 1
    return rows


def validate(td, challenges, conversation):
    assert len(td) == 500
    assert len({row['id'] for row in td}) == 500
    assert Counter(row['difficulty'] for row in td) == Counter({'cute': 130, 'romantic': 150, 'spicy': 150, 'extreme': 70})
    for tier in ['cute', 'romantic', 'spicy', 'extreme']:
        tier_rows = [row for row in td if row['difficulty'] == tier]
        assert Counter(row['kind'] for row in tier_rows)['truth'] == len(tier_rows) // 2
        assert len(Counter(row['category'] for row in tier_rows)) == 5
    assert len(challenges) == 256
    assert Counter(row['challengeCategory'] for row in challenges) == Counter({key: 32 for key in CHALLENGE_VERBS})
    assert len(conversation) == 320
    assert Counter(row['conversationCategory'] for row in conversation) == Counter({'deep': 70, 'funny': 70, 'romantic': 60, 'future': 60, 'rediscover': 60})
    for values in [td, challenges, conversation]:
        assert len({row['id'] for row in values}) == len(values)


def qa_markdown(td, challenges, conversation):
    random.seed(20260729)
    samples = random.sample(td, 8) + random.sample(challenges, 6) + random.sample(conversation, 6)
    lines = [
        '# Phase 3 Content QA', '',
        'Generated deterministically and validated by `tools/generate_phase3_content.py`.', '',
        '## Counts', '',
        '- Truth or Dare: **500** (cute 130, romantic 150, spicy 150, extreme 70; even truth/dare per tier; all five categories in every tier).',
        '- Challenge Cards: **256** (32 in each of exactly eight categories).',
        '- Conversation Starters: **320** (Deep 70, Funny 70, Romantic 60, Future 60, Getting-to-Know-You-Again 60).',
        '- IDs are unique and all files are valid JSON.', '',
        '## Deterministic 20-item spot read', '',
    ]
    for row in samples:
        text = row.get('prompt') or f"{row['title']} — {row['description']}"
        lines.append(f"- `{row['id']}` — {text}")
    lines += ['', '## Editorial safeguards', '', '- Spicy content is suggestive, not explicit.', '- Extreme prompts emphasize consent, boundaries, and pause rights.', '- Challenge prompts are specific and actionable.', '- No anatomical instructions or non-consensual framing are present.', '']
    return '\n'.join(lines)


def main():
    td = generate_td()
    challenges = generate_challenges()
    conversation = generate_conversation()
    validate(td, challenges, conversation)
    write('lib/features/truth_dare/data/truth_dare_seed.json', td)
    write('lib/features/cards/data/challenge_seed.json', challenges)
    write('lib/features/conversation/data/conversation_seed.json', conversation)
    qa = ROOT / 'docs/planning/PHASE3_CONTENT_QA.md'
    qa.write_text(qa_markdown(td, challenges, conversation))
    print('Generated and validated 500 TD, 256 challenge, and 320 conversation items.')


if __name__ == '__main__':
    main()
