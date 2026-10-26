# GRANT (Tools' files, for Audio's water v2 park): audio/data/world_cues.json gains a top-level `water` (the settings of the three sounds of World's water v2:
# the fill, the wave, the douse), so the closed schema needs the block, the cross-reference rule needs to count the water sounds as used (every sound must
# belong to a surface or to `water`) and check they exist, and the fixtures get a few cases. Apply AFTER the fine-biome park's grant (the schema it
# changes already holds `ground`). Usage: python grant_tools.py <root> [--check]      (a scratch export first; the repo root only for the EP's apply)
import json, os, sys
root = sys.argv[1]
check = '--check' in sys.argv[2:]
os.chdir(root)
problems = []


def read(p):
    raw = open(p, encoding='utf-8', newline='').read()
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def write(p, t, crlf):
    if not check:
        open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', '\r\n') if crlf else t)


def num(lo=None, hi=None, ex_lo=None, desc=None):
    d = {'type': 'number'}
    if lo is not None: d['minimum'] = lo
    if ex_lo is not None: d['exclusiveMinimum'] = ex_lo
    if hi is not None: d['maximum'] = hi
    if desc: d['description'] = desc
    return d


def integer(lo, hi, desc=None):
    d = {'type': 'integer', 'minimum': lo, 'maximum': hi}
    if desc: d['description'] = desc
    return d


SOUND = {'type': 'string', 'pattern': '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$', 'description': 'A sound of `sounds` (rule world-cues-water).'}
CLS = {'type': 'string', 'pattern': '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$', 'description': 'The voice class the cap counts.'}
PRIORITY = integer(0, 100, 'Voice priority (higher wins).')
CAP = integer(1, 16, 'The most voices of the class at once.')
GAIN = num(-60, 12)


def block(props, desc):
    return {'type': 'object', 'required': list(props.keys()), 'properties': props, 'additionalProperties': False, 'patternProperties': {'^_': True}, 'description': desc}


WATER = {
    'type': 'object',
    'required': ['fill', 'wave', 'douse'],
    'properties': {
        'fill': block({
            'sound': SOUND, 'seep': SOUND, 'gain_db': GAIN, 'seep_db': num(-60, 12, desc="Added for a table's seep (a quiet trickle)."),
            'ref_amount': num(None, 100000, 0, 'The dig depth at which the level is gain_db.'), 'gain_db_per_ln': num(0, 60), 'gain_db_min': GAIN, 'gain_db_max': GAIN,
            'pitch_exp': num(-2, 2), 'pitch_min': num(0.25, 4), 'pitch_max': num(0.25, 4),
            'min_s': num(0, 10, None, 'The shortest the swell is held, seconds.'), 'max_s': num(None, 10, 0, 'The longest the swell is held, seconds (the sound itself is about this long).'),
            'stop_ms': integer(0, 5000, 'The fade when the swell is cut at the fill\'s end.'), 'groups': integer(1, 8, 'Voice groups the fills sounding take in turn.'),
            'priority': PRIORITY, 'cls': CLS, 'cap': CAP}, 'A hole the fight dug fills (water_fill): a rushing swell, a trickle for a table.'),
        'wave': block({'sound': SOUND, 'gain_db': GAIN, 'priority': PRIORITY, 'cls': CLS, 'cap': CAP}, 'A slam into deep water sends a ring wave (water_wave): one heavy slosh.'),
        'douse': block({
            'sound': SOUND, 'gain_db': GAIN, 'ref_n': num(None, 1000, 0), 'gain_db_per_ln': num(0, 60), 'gain_db_min': GAIN, 'gain_db_max': GAIN,
            'priority': PRIORITY, 'cls': CLS, 'cap': CAP}, 'Water reaches a scorched column (water_douse): a short hiss.'),
    },
    'additionalProperties': False,
    'patternProperties': {'^_': True},
    'description': "World's water v2 sounds (sim/world/fill.gd): the settings of the fill, the wave and the douse; their sounds are in `sounds` (rule world-cues-water).",
}

# 1. the schema: `water` after `step`, and required
p = 'tools/schemas/audio-world-cues.schema.json'
t, crlf = read(p)
d = json.loads(t)
if 'water' in d['properties']:
    problems.append(p + ': water is already there')
elif 'ground' not in d['properties']:
    problems.append(p + ': apply the fine-biome park\'s grant first (no `ground` yet)')
else:
    props = {}
    for k, v in d['properties'].items():
        props[k] = v
        if k == 'step':
            props['water'] = WATER
    d['properties'] = props
    d['required'] = [x for k in d['required'] for x in ([k, 'water'] if k == 'step' else [k])]
    write(p, json.dumps(d, indent=2, ensure_ascii=False) + '\n', crlf)

# 2. the cross-reference rule: the water sounds exist, and count as used
p = 'tools/lib/xref-world-cues.js'
t, crlf = read(p)
a = "  for (const s of sounds) if (surfaces.size && !usedSounds.has(s))"
b = "//   world-cues-surface  each surface's hit and slide are sounds, and every sound belongs to some surface\n"
if 'world-cues-water' in t or t.count(a) != 1 or t.count(b) != 1:
    problems.append(p + ': the anchors are not as expected, or the rule is already there')
else:
    loop = r"""  for (const [k, e] of Object.entries(isObj(d.water) ? d.water : {})) {
    if (k.startsWith('_') || !isObj(e)) continue;
    for (const part of ['sound', 'seep']) {
      if (typeof e[part] !== 'string') continue;
      usedSounds.add(e[part]);
      if (sounds.size && !sounds.has(e[part])) err(F, `/water/${esc(k)}/${part}`, 'world-cues-water', `water ${k}'s ${part} sound "${e[part]}" is not in \`sounds\``);
    }
  }
"""
    t = t.replace(a, loop + a).replace(b, "//   world-cues-water    each water sound (fill, seep, wave, douse) is a sound of `sounds`, and counts as used\n" + b.replace("every sound belongs to some surface", "every sound belongs to some surface or to `water`"))
    write(p, t, crlf)

# 3. the fixtures: four cases before "fight-ricochet-angle-zero"
CASES = [
    ('audio-world-cues-key-required-water', {'del': ['/water']}, {'rule': 'required', 'pointer': ''}),
    ('audio-world-cues-water-sound-unknown', {'set': {'/water/wave/sound': 'surf.water.nowhere'}}, {'rule': 'xref:world-cues-water', 'pointer': '/water/wave/sound'}),
    ('audio-world-cues-water-groups-zero', {'set': {'/water/fill/groups': 0}}, {'rule': 'minimum', 'pointer': '/water/fill/groups'}),
    ('audio-world-cues-water-douse-gain-over-12', {'set': {'/water/douse/gain_db': 20}}, {'rule': 'maximum', 'pointer': '/water/douse/gain_db'}),
]
p = 'tools/fixtures/cases.json'
t, crlf = read(p)
anchor = '    {\n      "id": "fight-ricochet-angle-zero",'
if 'audio-world-cues-key-required-water' in t or t.count(anchor) != 1:
    problems.append(p + ': the anchor is not as expected, or the cases are already there')
else:
    text = ''
    for cid, mut, expect in CASES:
        obj = {'id': cid, 'schema': 'audio-world-cues.schema.json', 'mutate': [dict({'file': 'audio/data/world_cues.json'}, **mut)], 'expect': expect}
        body = json.dumps(obj, indent=2)
        text += '\n'.join('    ' + line for line in body.split('\n')) + ',\n'
    t2 = t.replace(anchor, text + anchor)
    json.loads(t2)
    write(p, t2, crlf)

if problems:
    print('NOT APPLIED. %d problem(s):' % len(problems))
    for x in problems:
        print('  ' + x)
    sys.exit(1)
print(('CHECKED' if check else 'APPLIED') + ': the schema (water), the rule world-cues-water, and four fixture cases')
