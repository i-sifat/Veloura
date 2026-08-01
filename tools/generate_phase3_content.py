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


# Curated, hand-written prompts (no shared templated suffixes). Each entry is
# (prompt, difficulty). 15 unique prompts per category, short and easy to
# read for non-native English speakers, with the "spicy" tier leaning
# flirtier/bolder.
CONVERSATION_CURATED = {
    'deep': [
        ("What's one secret that would surprise me?", 'spicy'),
        ('When did you last feel truly desired?', 'spicy'),
        ('What do you need more of from me?', 'romantic'),
        ("What's a fear you've never told me?", 'cute'),
        ('What makes you feel safest with me?', 'romantic'),
        ("What's something you love about yourself?", 'cute'),
        ('When do you feel most in love with me?', 'romantic'),
        ("What's a memory of us you replay often?", 'romantic'),
        ('What do you wish I noticed more?', 'spicy'),
        ("What's the boldest thing you've dreamed about us doing?", 'spicy'),
        ('What part of your day do you wish I was part of?', 'cute'),
        ("What's something you're proud of but never said out loud?", 'cute'),
        ('What do you crave from me right now?', 'spicy'),
        ("What's a feeling you have but rarely share?", 'romantic'),
        ('What would you want to know about my past?', 'cute'),
    ],
    'funny': [
        ("What's the weirdest nickname you'd give me?", 'cute'),
        ("If we were a movie, what's the title?", 'cute'),
        ("What's my most annoying cute habit?", 'cute'),
        ('What silly thing do I do that you secretly love?', 'romantic'),
        ('If you could prank me right now, what would you do?', 'spicy'),
        ("What's the funniest thing that's happened on a date with me?", 'cute'),
        ('What superhero name fits me best?', 'cute'),
        ("What's one thing I do that makes you laugh every time?", 'romantic'),
        ("If our love story was a song, what's the title?", 'romantic'),
        ("What's the boldest dare you'd give me tonight?", 'spicy'),
        ("What's a silly rule our relationship secretly has?", 'cute'),
        ("What's the most ridiculous thing you'd do to impress me?", 'spicy'),
        ('What emoji describes me best right now?', 'cute'),
        ("What's your favorite way to tease me?", 'spicy'),
        ("If we swapped bodies for a day, what's the first thing you'd do?", 'spicy'),
    ],
    'romantic': [
        ("What's your favorite place to be kissed?", 'spicy'),
        ('What moment made you fall harder for me?', 'romantic'),
        ("What's something you find irresistible about me?", 'spicy'),
        ('How do you want tonight to end?', 'spicy'),
        ("What's the most romantic thing I've done for you?", 'romantic'),
        ('What do you love most about how I touch you?', 'spicy'),
        ("What's a compliment you wish I gave more often?", 'cute'),
        ('What makes you feel wanted by me?', 'spicy'),
        ("What's your favorite way for me to hold you?", 'romantic'),
        ('What do you think about right before we kiss?', 'spicy'),
        ("What's the sexiest thing about our relationship?", 'spicy'),
        ("What's one thing you'd love us to try together?", 'spicy'),
        ("What's your love language, and am I speaking it enough?", 'cute'),
        ("What's the best surprise I could give you tonight?", 'spicy'),
        ('How do you want me to show love to you today?', 'romantic'),
    ],
    'future': [
        ('Where do you picture us five years from now?', 'cute'),
        ('What adventure do you want us to have together?', 'romantic'),
        ("What's one thing you want to try with me before we're old?", 'spicy'),
        ('What tradition should we start this year?', 'cute'),
        ("What's your dream date we haven't done yet?", 'romantic'),
        ("What's a goal you want us to chase together?", 'cute'),
        ('Where would you love to travel with just the two of us?', 'romantic'),
        ("What's something new you want us to try in bed?", 'spicy'),
        ('What kind of home do you picture us building?', 'cute'),
        ("What's a wild idea you have for our future?", 'spicy'),
        ('What would our perfect anniversary look like?', 'romantic'),
        ("What's one promise you want us to keep forever?", 'romantic'),
        ("What's something you want us to be brave enough to try?", 'spicy'),
        ('How do you want us to grow closer this year?', 'cute'),
        ("What's a memory you want us to make together soon?", 'romantic'),
    ],
    'rediscover': [
        ("What's something new about you I might not know?", 'cute'),
        ("What's changed about what turns you on lately?", 'spicy'),
        ("What's a new interest you've picked up recently?", 'cute'),
        ("What do you need from me that's different now?", 'romantic'),
        ("What's something you've been afraid to tell me?", 'spicy'),
        ('How have your feelings for me changed lately?', 'romantic'),
        ("What's a part of you I don't ask about enough?", 'cute'),
        ("What's something you want me to understand about you now?", 'romantic'),
        ("What's a new fantasy you've been curious about?", 'spicy'),
        ("What's something small that made you happy this week?", 'cute'),
        ('What do you wish we talked about more?', 'romantic'),
        ("What's a version of you I haven't met yet?", 'cute'),
        ("What's something you want to explore about us physically?", 'spicy'),
        ("What's one way I could love you better right now?", 'romantic'),
        ("What's a question you wish I'd ask you more?", 'cute'),
    ],
}


def generate_conversation():
    rows = []
    idx = 1
    for category in ['deep', 'funny', 'romantic', 'future', 'rediscover']:
        for prompt, difficulty in CONVERSATION_CURATED[category]:
            rows.append({
                'id': f'cv_{idx:04d}',
                'prompt': prompt,
                'conversationCategory': category,
                'difficulty': difficulty,
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
    assert len(conversation) == 75
    assert Counter(row['conversationCategory'] for row in conversation) == Counter({
        'deep': 15, 'funny': 15, 'romantic': 15, 'future': 15, 'rediscover': 15,
    })
    for values in [td, challenges, conversation]:
        assert len({row['id'] for row in values}) == len(values)
    conversation_prompts = [row['prompt'] for row in conversation]
    assert len(conversation_prompts) == len(set(conversation_prompts)), 'Conversation prompts must be unique'


def qa_markdown(td, challenges, conversation):
    random.seed(20260729)
    samples = random.sample(td, 8) + random.sample(challenges, 6) + random.sample(conversation, 6)
    lines = [
        '# Phase 3 Content QA', '',
        'Generated deterministically and validated by `tools/generate_phase3_content.py`.', '',
        '## Counts', '',
        '- Truth or Dare: **500** (cute 130, romantic 150, spicy 150, extreme 70; even truth/dare per tier; all five categories in every tier).',
        '- Challenge Cards: **256** (32 in each of exactly eight categories).',
        '- Conversation Starters: **75** (15 per category: Deep, Funny, Romantic, Future, Getting-to-Know-You-Again). Hand-written, fully unique, short and easy-English prompts — no repeated template suffixes.',
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
    print('Generated and validated 500 TD, 256 challenge, and 75 conversation items.')


if __name__ == '__main__':
    main()
