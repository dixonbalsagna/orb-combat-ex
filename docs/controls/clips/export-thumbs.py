"""Exports the synthetic thumbs of docs/controls/right-stick-model.py (right-stick.md section 4: min-jerk strokes with angle and timing noise, a 50% recentring overshoot
after flicks, drift up to 0.08 for a casual thumb and 0.04 for a practised one, 1/16 quantisation) as one JSON file Tools can feed to a pad, tick by tick.

    python docs/controls/clips/export-thumbs.py > docs/controls/clips/thumbs.json            (default 120 traces per kind and skill)
    python docs/controls/clips/export-thumbs.py 300 > thumbs-big.json

Format: { "hz": 60, "stick": "right", "y": "up", "traces": [ { "id", "kind", "skill", "intent": ["flick"|"hold"|"flick+hold"|"pump"|null, sector8|null], "dir4": 1..4|null,
"samples": [[x, y], ...] } ] }. One sample per sim tick, x right and y UP, each -1 to 1 and already quantised to 1/16. To feed a browser pad the axis value is (x, -y) because the
game reads JOY_AXIS_RIGHT_Y as down-positive and flips it (render/core/main.gd). Rest the stick for 30 ticks (all zeros) between traces. dir4 is the screen quadrant of the intended
direction (UP 1, DOWN 2, LEFT 3, RIGHT 4) when the intended direction is on an axis (the 8-way ones on a diagonal have none). Deterministic: the same seeds give the same file.
These are not people (right-stick.md); the black box's raw log of Orb's stick replaces them.
"""
import importlib.util
import json
import math
import os
import random
import sys

here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("rsm", os.path.join(here, "..", "right-stick-model.py"))
rsm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rsm)

N = int(sys.argv[1]) if len(sys.argv) > 1 else 120
KINDS = ["flick", "hold", "snap_hold", "pump", "idle", "aimwander"]
SECTOR_TO_DIR4 = {0: 4, 2: 1, 4: 3, 6: 2}   # sector8: 0 right, 2 up, 4 left, 6 down (counter-clockwise from right)
traces = []
for skill in ("skilled", "casual"):
    for kind in KINDS:
        r = random.Random(f"{skill}-{kind}")
        for i in range(N):
            samples, intent = rsm.gen(kind, r, skill)
            it = None if intent is None or intent[0] is None else [intent[0], intent[1]]
            d4 = SECTOR_TO_DIR4.get(intent[1]) if (intent is not None and intent[1] is not None) else None
            traces.append({"id": f"{skill}-{kind}-{i}", "kind": kind, "skill": skill, "intent": it, "dir4": d4, "samples": [[round(x, 4), round(y, 4)] for x, y in samples]})
json.dump({"hz": 60, "stick": "right", "y": "up", "traces": traces}, sys.stdout, separators=(",", ":"))
