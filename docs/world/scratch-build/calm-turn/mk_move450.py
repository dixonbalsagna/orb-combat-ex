"""The calm turn's ground rule to 450 units (Game Design 2026-10-23 ruling 3).   python mk_move450.py <root>
rings.json turn.moveMax 300 -> 450 (every size); epoch.gd's comments; epoch_check's pivots and thresholds follow the data."""
import sys
R = sys.argv[1].rstrip('/') + '/'


def edit(p, pairs):
    s = open(R + p, encoding='utf-8', newline='').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:70], s.count(a))
        s = s.replace(a, b)
    open(R + p, 'w', encoding='utf-8', newline='').write(s)


edit('data/biomes/rings.json', [('"moveMax": 300.0,', '"moveMax": 450.0,')])
edit('sim/world/epoch.gd', [
    ('(Game Design rulings-2026-10-22 5a: at most moveMax, 300 units)', '(Game Design rulings-2026-10-22 5a: at most moveMax, 300 units; 450 from rulings-2026-10-23 ruling 3, at every size)'),
    ('(the pair about 8,600 units or more off the pivot)', '(the pair about 12,900 units or more off the pivot at 450)'),
    ('The 300 rule wins over "never under 2 degrees".', 'The moveMax rule wins over "never under 2 degrees".'),
])
edit('sim/world/tools/epoch_check.gd', [
    ('''	# --- a landing turns less rather than not at all: the angle is scaled so the ground under the fighters moves at most 300 units, never under 2 degrees
''', '''	# --- a landing turns less rather than not at all: the angle is scaled so the ground under the fighters moves at most moveMax units (450 since Game Design 2026-10-23), never under 2 degrees
	var MM: float = float(d.moveMax)
'''),
    ('for off in [0.0, 3600.0, 7000.0, 7800.0, 9000.0, 40000.0]:', 'for off in [0.0, 3600.0, 11000.0, 12000.0, 14000.0, 40000.0]:   # 450: ten to 2,590 units, 2.5 degrees to 10,300, waits to 12,900, refused past'),
    ('''var kind: String = "refuse" if smax * sin(2.0 * PI / 180.0) > 300.0 else ("wait" if smax * sin(2.5 * PI / 180.0) > 300.0 and smax * sin(10.0 * PI / 180.0) > 300.0 else ("ten" if smax * sin(10.0 * PI / 180.0) <= 300.0 else "twofive"))''',
     '''var kind: String = "refuse" if smax * sin(2.0 * PI / 180.0) > MM else ("wait" if smax * sin(2.5 * PI / 180.0) > MM and smax * sin(10.0 * PI / 180.0) > MM else ("ten" if smax * sin(10.0 * PI / 180.0) <= MM else "twofive"))'''),
    ('absf(used - wantDeg) < 1e-9 and move <= 300.0 * 1.02', 'absf(used - wantDeg) < 1e-9 and move <= MM * 1.02'),
])
print('moveMax 450 applied')
