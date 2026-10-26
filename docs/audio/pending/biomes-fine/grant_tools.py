# GRANT (Tools' files, for Audio's fine-biome park): audio/data/world_cues.json gains a top-level `ground` (biome to the surface it overrides the sim's
# class with), so the closed schema needs the property, the cross-reference rule needs a loop, and the fixtures need their cases. This is Tools' own
# docs/tools/pending/audio-ground.patch (2026-10-23) REBASED on HEAD of 2026-10-26: its schema and xref hunks applied as they were, but both
# tools/fixtures/cases.json hunks were rejected (the file moved: World's lakes case and the neighbours of the insertion), so the five cases are inserted
# here by text before the "fight-ricochet-angle-zero" case (ground_cases.txt, taken from Tools' patch), and the patch's one reformatting hunk (lakes.json
# /refuse written out over lines) is left out: it is not part of this change.
# Usage: python grant_tools.py <root> [--check]      (a scratch export first; the repo root only for the EP's apply)
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
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


# 1. the schema: `ground` beside `soil` (the same shape), and required, exactly as Tools' patch has it
p = 'tools/schemas/audio-world-cues.schema.json'
t, crlf = read(p)
d = json.loads(t)
if 'ground' in d['properties']:
    problems.append(p + ': ground is already there')
else:
    g = json.loads(json.dumps(d['properties']['soil']))
    g['additionalProperties']['description'] = 'A surface of `surfaces` (rule world-cues-ground).'
    g['description'] = "Biome to the surface that takes the sim's soil, rock or sand class at a column of that fine biome (ice, a wetland, a beach): a key of biomes to a key of surfaces (rule world-cues-ground)."
    props = {}
    for k, v in d['properties'].items():
        props[k] = v
        if k == 'soil':
            props['ground'] = g
    d['properties'] = props
    d['required'] = [x for k in d['required'] for x in ([k, 'ground'] if k == 'soil' else [k])]
    write(p, json.dumps(d, indent=2, ensure_ascii=False) + '\n', crlf)

# 2. the cross-reference rule
p = 'tools/lib/xref-world-cues.js'
t, crlf = read(p)
a = "  const usedSounds = new Set();\n"
b = "//   world-cues-surface  each surface's hit and slide are sounds, and every sound belongs to some surface\n"
if 'world-cues-ground' in t or t.count(a) != 1 or t.count(b) != 1:
    problems.append(p + ': the anchors are not as expected, or the rule is already there')
else:
    loop = r"""  for (const [k, v] of Object.entries(isObj(d.ground) ? d.ground : {})) {
    if (k.startsWith('_')) continue;
    if (biomes.length && !biomes.includes(k)) err(F, `/ground/${esc(k)}`, 'world-cues-ground', `"${k}" is not a biome of \`biomes\``);
    if (typeof v === 'string' && surfaces.size && !surfaces.has(v)) err(F, `/ground/${esc(k)}`, 'world-cues-ground', `${k} is "${v}", which is not a surface of \`surfaces\``);
  }
"""
    t = t.replace(a, loop + a).replace(b, "//   world-cues-ground   each ground key is a biome and each ground value is a surface\n" + b)
    write(p, t, crlf)

# 3. the fixtures: the five cases, before "fight-ricochet-angle-zero"
p = 'tools/fixtures/cases.json'
t, crlf = read(p)
anchor = '    {\n      "id": "fight-ricochet-angle-zero",'
cases = open(os.path.join(HERE, 'ground_cases.txt'), encoding='utf-8').read()
if 'audio-world-cues-key-required-ground' in t or t.count(anchor) != 1:
    problems.append(p + ': the anchor is not as expected, or the cases are already there')
else:
    t2 = t.replace(anchor, cases + anchor)
    json.loads(t2)      # still valid JSON
    write(p, t2, crlf)

if problems:
    print('NOT APPLIED. %d problem(s):' % len(problems))
    for x in problems:
        print('  ' + x)
    sys.exit(1)
print(('CHECKED' if check else 'APPLIED') + ': the schema (ground), the rule world-cues-ground, and five fixture cases')
