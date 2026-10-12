#!/usr/bin/env python3
"""The split, Combat's part: rename the placeholder fighters to PROTAGONIST and RIVAL in data/combat (PARKED).

For the window the EP schedules with Simulation (docs/combat/pending/apply-order.md section 9). Run from the repo root:

    python docs/combat/pending/split-rename.py            show what would change
    python docs/combat/pending/split-rename.py --apply    make the edits
    python docs/combat/pending/split-rename.py --root DIR the same on another copy of the tree (a scratch export)

Each edit is one exact piece of text that must be found once; if any is not, nothing is written. Run again after
--apply and it reports that everything is already done. No beat, number or cue changes: only names.
"""
import io, os, sys

ROOT = sys.argv[sys.argv.index("--root") + 1] if "--root" in sys.argv else "."
APPLY = "--apply" in sys.argv

# file -> [(JSON pointer, the text now, the text after)]
EDITS = {
    "data/combat/finishers.json": [
        ("/select/byFighter", '"byFighter": { "KAI": "kai", "VORR": "vorr" }', '"byFighter": { "PROTAGONIST": "protagonist", "RIVAL": "rival" }'),
        ("/select/_rule", "by fighter name (e.g. 'KAI')", "by fighter name (e.g. 'PROTAGONIST')"),
        ("/finishers/2/id", '"id": "kai"', '"id": "protagonist"'),
        ("/finishers/2/fighter", '"fighter": "KAI"', '"fighter": "PROTAGONIST"'),
        ("/finishers/3/id", '"id": "vorr"', '"id": "rival"'),
        ("/finishers/3/fighter", '"fighter": "VORR"', '"fighter": "RIVAL"'),
        ("/shapes/antihero (the key)", '    "antihero": {', '    "rival": {'),
    ],
    "data/combat/styles.json": [
        ("/selectors/traits/KAI and /VORR (removed: the roster's placeholders)", '"KAI": ["blink", "aerial"],\n      "VORR": ["volley", "brawler"],\n      ', ''),
        ("/selectors/traits/antihero (the key)", '"antihero": ["volley", "aerial"]', '"rival": ["volley", "aerial"]'),
        ("/telegraphs/finishers/futureKinds/antihero (the key)", '"antihero": "melee"', '"rival": "melee"'),
    ],
    "data/combat/recipes.json": [
        ("/_status/live (a note)", "KAI and VORR still draw on the placeholder key sets", "the two fighters still draw on the placeholder key sets"),
    ],
}

plan, bad = [], []
for rel, edits in EDITS.items():
    path = os.path.join(ROOT, rel)
    text = io.open(path, encoding="utf-8", newline="").read()
    nl = "\r\n" if "\r\n" in text else "\n"
    new = text
    for ptr, a, b in edits:
        a2, b2 = a.replace("\n", nl), b.replace("\n", nl)
        if new.count(a2) == 1:
            new = new.replace(a2, b2)
            plan.append((rel, ptr, "to do"))
        elif (b2 and new.count(b2) >= 1 and new.count(a2) == 0) or (not b2 and new.count(a2) == 0):
            plan.append((rel, ptr, "already done"))
        else:
            bad.append((rel, ptr, "found %d times, expected once" % new.count(a2)))
    EDITS[rel] = (path, text, new)

for rel, ptr, state in plan:
    print("%-13s %s %s" % (state, rel, ptr))
for rel, ptr, why in bad:
    print("STOP          %s %s: %s" % (rel, ptr, why))
if bad:
    print("nothing written")
    sys.exit(1)
if APPLY:
    for rel, (path, text, new) in EDITS.items():
        if new != text:
            io.open(path, "w", encoding="utf-8", newline="").write(new)
    print("applied")
else:
    print("dry run: add --apply to write")
