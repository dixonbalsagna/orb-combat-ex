#!/usr/bin/env python3
"""Flip data/director switch rows to the played build's values, changing only each value's own text (no reformatting).
python rows_flip.py <tree> <build data/director dir> <group> [--check]
  group: ai (the computer opponent, A-AI-05: 3 rows), ending (the match-ending rules, A-MODES-07: 1 row), fight (the other 33),
         all (the 37). --check only compares and lists.
Each row's value is read from the build's own packed JSON (not a switch list), and after the edit the tree's parsed value must equal
it, with every other value unchanged."""
import sys, os, json

GROUPS = {
    'ai': [('ai.json', 'levels.easy.brawl.paceMatch.enabled'), ('ai.json', 'vsHuman.enabled'),
           ('interrupts.json', 'beamPlays.front.ownMove.ai')],
    'ending': [('interrupts.json', 'ending.enabled')],
}
FIGHT = [('interrupts.json', p) for p in [
    'bands.arrive.enabled', 'bands.follow.enabled', 'beamPlays.front.aim.enabled', 'beamPlays.front.enabled',
    'beamPlays.front.ownMove.enabled', 'beamStruggle.enabled', 'beamStruggle.pushMode.enabled', 'blast.driver.enabled',
    'brawl.chargeClose.enabled', 'brawl.oneRuleB.enabled', 'brawl.pressWait.enabled', 'calmTurn.enabled', 'carryRound.enabled',
    'chase.tap.enabled', 'grapple.enabled', 'press.refusedCue', 'stances.enabled', 'water.enabled', 'zip.flightStrikes.enabled']] + \
    [('launch.json', p) for p in ['arc.enabled', 'arc.firstMeteor', 'sideFromBlowOnly']] + \
    [('stick.json', p) for p in ['armour.enabled', 'flickKeep.enabled', 'flickRun.enabled', 'fullSend.enabled', 'lightStops',
                                 'lungeLight.enabled', 'pendFollow.enabled', 'strikeStages.enabled']] + \
    [('swing.json', p) for p in ['brawl.shareCap.enabled', 'enabled', 'jolt.yieldToLaunch']]
GROUPS['fight'] = FIGHT
GROUPS['all'] = GROUPS['ai'] + GROUPS['ending'] + FIGHT


def spans(text):
    """Every scalar value's path and (start, end) offsets in a JSON text."""
    out = {}
    i, n = 0, len(text)
    stack = []  # (kind, key or index)

    def ws():
        nonlocal i
        while i < n and text[i] in ' \t\r\n':
            i += 1

    def string():
        nonlocal i
        assert text[i] == '"'
        j = i + 1
        while text[j] != '"':
            j += 2 if text[j] == '\\' else 1
        s = json.loads(text[i:j + 1])
        i = j + 1
        return s

    def value(path):
        nonlocal i
        ws()
        c = text[i]
        if c == '{':
            i += 1
            ws()
            if text[i] == '}':
                i += 1
                return
            while True:
                ws()
                k = string()
                ws()
                assert text[i] == ':'
                i += 1
                value(path + [k])
                ws()
                if text[i] == ',':
                    i += 1
                    continue
                assert text[i] == '}'
                i += 1
                return
        if c == '[':
            i += 1
            ws()
            if text[i] == ']':
                i += 1
                return
            k = 0
            while True:
                value(path + [str(k)])
                k += 1
                ws()
                if text[i] == ',':
                    i += 1
                    continue
                assert text[i] == ']'
                i += 1
                return
        start = i
        if c == '"':
            string()
        else:
            while i < n and text[i] not in ',}] \t\r\n':
                i += 1
        out['.'.join(path)] = (start, i)

    value([])
    return out


def get(o, path):
    for k in path.split('.'):
        o = o[int(k)] if isinstance(o, list) else o[k]
    return o


def main():
    tree, bdir, group = sys.argv[1], sys.argv[2], sys.argv[3]
    check = '--check' in sys.argv
    rows = GROUPS[group]
    byfile = {}
    for fn, p in rows:
        byfile.setdefault(fn, []).append(p)
    changed = 0
    for fn, paths in sorted(byfile.items()):
        tp = os.path.join(tree, 'data/director', fn)
        text = open(tp, encoding='utf8', newline='').read()
        before = json.loads(text)
        build = json.load(open(os.path.join(bdir, fn), encoding='utf8'))
        sp = spans(text)
        edits = []
        for p in paths:
            want = get(build, p)
            have = get(before, p)
            print('%-16s %-40s main %-6s build %-6s %s' % (fn, p, json.dumps(have), json.dumps(want), 'same' if have == want else ('FLIP' if not check else 'differs')))
            if have != want and not check:
                s, e = sp[p]
                edits.append((s, e, json.dumps(want)))
        for s, e, v in sorted(edits, reverse=True):
            text = text[:s] + v + text[e:]
        if edits:
            after = json.loads(text)
            for p in paths:
                assert get(after, p) == get(build, p), (fn, p)
            # nothing else moved: put the flipped values back and compare
            chk = json.loads(text)
            for p in paths:
                o = chk
                ks = p.split('.')
                for k in ks[:-1]:
                    o = o[k]
                o[ks[-1]] = get(before, p)
            assert chk == before, fn + ': something else changed'
            open(tp, 'w', encoding='utf8', newline='').write(text)
            changed += len(edits)
    print('%s: %d value(s) %s' % (group, changed, 'flipped' if not check else 'checked'))


main()
