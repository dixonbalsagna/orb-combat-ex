#!/usr/bin/env python3
"""Lists every player-facing string in ui/data by where it shows, in batches of ten, for Orb to mark and Narrative to work from.

    python ui/tools/strings_inventory.py > docs/ui/strings.md

Run from the repository root. It reads ui/data/*.json only; nothing here is a source of truth (the JSON is). Ids, colours, notes, paths and one-word identifiers are left out.
"""
import json
import re
import sys

DATA = 'ui/data/'
SKIP_KEYS = {'note', '_note', 'schema', 'id', 'art', 'icon', 'col', 'path', 'scheme', 'group', 'default', 'action', 'actions', 'cell', 'kind', 'type', 'needs', 'choices',
             'hidden', 'hidden_note', '_live', 'live', 'profile', 'ids', 'pair_note', '_windup_ticks', 'min', 'max', 'step', 'accessibility', 'url', 'repo', 'style', 'align',
             'stance_ids'}


def keep(s):
    if re.fullmatch(r'#[0-9a-fA-F]{6}', s):
        return False
    if re.fullmatch(r'[a-z0-9_\-\.:/]+', s) and ' ' not in s:
        return False
    if s.startswith('res://') or s.startswith('http') or len(s) < 2:
        return False
    return True


rows = []


def walk(o, path, f):
    if isinstance(o, str):
        if keep(o):
            rows.append((f, path, o))
    elif isinstance(o, dict):
        for k, v in o.items():
            if k in SKIP_KEYS:
                continue
            walk(v, path + [str(k)], f)
    elif isinstance(o, list):
        for i, v in enumerate(o):
            walk(v, path + [str(i)], f)


FILES = ['terms', 'howto', 'hints', 'stances', 'settings', 'options', 'feedback', 'send', 'reads', 'fighter_names', 'readout_profiles']
docs = {}
for f in FILES:
    with open(DATA + f + '.json', encoding='utf-8') as fh:
        d = json.load(fh)
    docs[f] = d
    walk(d, [], f)

PAGES = [p.get('title', '') for p in docs['howto'].get('pages', [])]
SETTINGS_SECTIONS = {s['id']: s['title'] for s in docs['settings'].get('sections', [])}
OPTIONS = docs['options'].get('options', {})

ORDER = [
    'The flashing-effects gate (the first thing in a session)',
    'The turn-your-phone card',
    'How to play (cards, first run and from the pause menu)',
    'Plates: names, tiers and meters',
    'Plates: state chips and badges',
    'Wound cards, the body figure and set-piece cards',
    'Banners and the toll chip',
    'Button prompts and touch captions',
    'The control legend',
    'Reads: telegraphs, hints and the finisher struggle',
    'Sound captions on barks',
    'The pause menu',
    'Settings: rows and their help',
    'Settings and Remap: the screens\' own words',
    'Send feedback',
    'The planet strip: place names',
    'Fighter names and titles',
    'Other',
]


def where(f, path):
    p = '.'.join(path)
    if f == 'terms':
        g = path[0]
        if g == 'prompt':
            k = path[1] if len(path) > 1 else ''
            if k.startswith('photo_'):
                return ORDER[0]
            if k.startswith('turn_'):
                return ORDER[1]
            if k.startswith('pause_') or k.startswith('confirm') or k.startswith('menu'):
                return ORDER[11]
            return ORDER[7]
        if g in ('tier', 'meter'):
            return ORDER[3]
        if g in ('stance', 'state', 'chip_stage'):
            return ORDER[4]
        if g in ('region', 'stage', 'internal_stage', 'card', 'station'):
            return ORDER[5]
        if g in ('toll', 'banner_rename'):
            return ORDER[6]
        if g == 'caption':
            return ORDER[10]
        if g in ('planet', 'places'):
            return ORDER[15]
        return ORDER[17]
    if f == 'howto':
        if path[0] == 'pages' and len(path) > 1 and path[1].isdigit():
            return 'How to play, page %d: %s' % (int(path[1]) + 1, PAGES[int(path[1])] if int(path[1]) < len(PAGES) else '')
        return ORDER[2]
    if f == 'hints':
        if path[0] == 'you':
            return ORDER[8]
        if path[0] == 'schemes' and len(path) > 1:
            return 'The control legend (%s layout)' % path[1]
        return ORDER[8]
    if f == 'stances':
        if path[0] == 'stances' and len(path) > 1:
            return 'Stances: %s (the stance page, the legend and the remap screen)' % path[1]
        return 'Stances: the armed badge and the page\'s shared words'
    if f == 'settings':
        if path[0] == 'sections':
            return 'Settings: the section and row names'
        if path[0] == 'remap':
            return 'The Remap controls screen'
        return ORDER[13]
    if f == 'options':
        return ORDER[12]
    if f in ('feedback', 'send'):
        return ORDER[14]
    if f == 'reads':
        return ORDER[9]
    if f in ('fighter_names', 'readout_profiles'):
        return ORDER[16]
    return ORDER[17]


NARRATIVE = ('b7.nudge', 'b5.done', 'boiled', 'boil')   # lines Narrative named in docs/narrative/writing-quality.md

by = {}
for f, path, s in rows:
    w = where(f, path)
    by.setdefault(w, []).append((f, '.'.join(path), s))


def order_key(w):
    for i, o in enumerate(ORDER):
        if w == o:
            return (i, w)
    if w.startswith('How to play, page'):
        return (2, w)
    if w.startswith('The control legend ('):
        return (8, w)
    if w.startswith('Stances:'):
        return (8, w)
    if w.startswith('Settings:') or w.startswith('The Remap'):
        return (12, w)
    return (99, w)


out = []
total = sum(len(v) for v in by.values())
out.append('# Every player-facing string in ui/data, by where it shows')
out.append('')
out.append('Generated by `python ui/tools/strings_inventory.py` (UI & UX, 2026-10-12) from `ui/data/*.json`. **%d strings in batches of ten**, one surface at a time, so Orb can mark a batch and Narrative can work from it. '
           'Ids, colours, notes and one-word identifiers are left out. The JSON stays the source: a rewrite goes into the data file named in the key column, and `hud_check` compares some of these word for word (the gate, the About page), so a change to those is made with its test. **Nothing new ships unmarked.**' % total)
out.append('')
out.append('Mark column: **keep**, **rewrite** (Narrative drafts), or **cut**. A flag in the key column (**N**) is a line Narrative\'s `docs/narrative/writing-quality.md` names.')
out.append('')
n = 0
batch = 0
for w in sorted(by.keys(), key=order_key):
    items = by[w]
    for i in range(0, len(items), 10):
        batch += 1
        out.append('## Batch %d: %s (%d to %d of %d on this surface)' % (batch, w, i + 1, min(i + 10, len(items)), len(items)))
        out.append('')
        out.append('| # | Text | Key | Mark |')
        out.append('| ---: | :-- | :-- | :-- |')
        for f, k, s in items[i:i + 10]:
            n += 1
            flag = ' **N**' if any(t in k.lower() for t in NARRATIVE) else ''
            text = s.replace('|', '\\|').replace('\n', ' ')
            out.append('| %d | %s | `%s:%s`%s | |' % (n, text, f, k, flag))
        out.append('')
sys.stdout.reconfigure(encoding='utf-8')
print('\n'.join(out))
