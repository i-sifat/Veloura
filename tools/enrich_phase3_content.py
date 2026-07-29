#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / 'lib/features/truth_dare/data/truth_dare_seed.json'
NUANCES = [
    'Answer with the first specific detail that comes to mind.',
    'Include one detail your partner may not expect.',
    'Connect your answer to something that happened this month.',
    'Say what would make this feel meaningful for both of you.',
    'Add one small example from an ordinary day.',
    'Explain what feeling sits underneath your answer.',
    'Share how your answer has changed over time.',
    'Name one thing your partner could do with this answer.',
    'Keep the response honest, kind, and concrete.',
    'Describe the moment as if it were a scene in a film.',
    'Include one sound, place, or tiny detail you remember.',
    'Finish by asking your partner the same question.',
    'Choose the version that would make both of you smile.',
    'Take turns adding one sentence to the answer.',
    'End with one idea you could try together soon.',
]

rows = json.loads(PATH.read_text())
for index, row in enumerate(rows):
    tier_start = {'cute': 0, 'romantic': 130, 'spicy': 280, 'extreme': 430}[row['difficulty']]
    local = index - tier_start
    row['prompt'] = f"{row['prompt']} {NUANCES[(local // 10) % len(NUANCES)]}"
prompts = [row['prompt'] for row in rows]
assert len(prompts) == len(set(prompts)), 'Truth or Dare prompts must be unique'
PATH.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n')
qa = ROOT / 'docs/planning/PHASE3_CONTENT_QA.md'
text = qa.read_text()
text = text.replace(
    '- IDs are unique and all files are valid JSON.',
    '- IDs and all 500 Truth or Dare prompt strings are unique; all files are valid JSON.',
)
qa.write_text(text)
print('Enriched and validated 500 unique Truth or Dare prompts.')
