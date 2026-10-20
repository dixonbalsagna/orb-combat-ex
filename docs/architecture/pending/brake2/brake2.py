# PARKED BUILD (Simulation): the air brake, the second window, on Game Design's rulings of 2026-10-18 (rulings-2026-10-
# 18b.md 1b) and launch anywhere on main (f4e8269c). Behind the brake's switch (data/fight/brake.json, off).
#   Air sense is 10% sooner a mark (it was 25%); the marks are the sender's to set (Encounter's line, grant_encounter.py)
#   and are spent at the send. The start window reads the send's power: the launcher's (Fighter.launchPower) when the
#   launch carries one, else its own speed over a full launch's. A flight's end clears launchPower (here and, for the
#   journey's two ends, World's lines: grant_world.py), so a later send never reads an old launch's power.
#   edits sim/core/brake.gd, fighter.gd (the water recovery's reset), tools/parity.gd (the brake check),
#         data/fight/brake.json (airSense)
# Usage: python brake2.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert 'static func power(f, v0: float)' not in open('sim/core/brake.gd', encoding='utf-8').read(), 'already in'
edit('sim/core/brake.gd', [
("static func window(v: float, marks: int) -> int:\n\tvar p: float = SimMathx.jmin(1.0, v / fullSpeed)\n\tvar k: float",
 "static func window(p: float, marks: int) -> int:\n\tvar k: float"),
("\t\tb.at = window(b.v0, b.marks)\n",
 "\t\tb.at = window(power(f, b.v0), b.marks)\n"
 "\t\tb.marks = 0   # air sense: the sender sets the send kind's marks before each send, and they are spent here\n"),
("static func _control(S: SimState, f) -> void:\n\tf.vx = f.vx / f.launchT\n\tf.launchT = 1.0\n",
 "static func _control(S: SimState, f) -> void:\n\tf.vx = f.vx / f.launchT\n\tf.launchT = 1.0\n\tf.launchPower = 1.0   # the flight is over: no launcher's power carried\n"),
])
p = 'sim/core/brake.gd'
s = open(p, encoding='utf-8').read()
# replace the old doc comment above window() with the new one, and add power() before it
old_doc_start = s.index("## The start window for a send of speed v")
old_doc_end = s.index("static func window(p: float, marks: int) -> int:")
s = s[:old_doc_start] + '''## The send's power (launch-anywhere.md section 4): the launcher's, Fighter.launchPower, when the launch carries one;
## else (a knock-back, a throw, a blast's push, or any launch with no launcher's power) its own speed over a full launch's,
## at most 1.
static func power(f, v0: float) -> float:
	if float(f.launchPower) != 1.0:
		return float(f.launchPower)
	return SimMathx.jmin(1.0, v0 / fullSpeed)


## The start window for a send of power p (ticks after the send): straight-line from minTicks at lowPower or less to
## maxTicks at fullPower or more; air sense takes airSense off it for each mark of the send's kind on him (the sender's
## to set before the send).
''' + s[old_doc_end:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('sim/core/fighter.gd', [
("\t\t\tspin(S, f, dt, SPIN_STOP)\n\t\t\tf.launchT = 1.0\n\t\t\tWorldBrunt.endFlight(S, f)\n\t\t\treturn\n",
 "\t\t\tspin(S, f, dt, SPIN_STOP)\n\t\t\tf.launchT = 1.0\n\t\t\tf.launchPower = 1.0   # the flight is over: no launcher's power carried\n\t\t\tWorldBrunt.endFlight(S, f)\n\t\t\treturn\n"),
])

edit('data/fight/brake.json', [
("  \"airSense\": 0.25,\n", "  \"airSense\": 0.1,\n"),
])
s = open('data/fight/brake.json', encoding='utf-8').read()
a = s[s.index('  "_airSense": '):]
a = a[:a.index('\n')]
s = s.replace(a, '  "_airSense": "a send of a kind already marked on him (launch-anywhere.md section 5) can be braked this share sooner for each mark (Game Design, 2026-10-18: 10%, it was 25%). The marks are the sender\'s to set before the send"', 1)
open('data/fight/brake.json', 'w', encoding='utf-8', newline='\n').write(s)
import json
json.loads(s)

p = 'sim/core/tools/parity.gd'
edit(p, [
("\tvar w: Array = [SimBrake.window(0.3 * fs, 0), SimBrake.window(0.55 * fs, 0), SimBrake.window(0.775 * fs, 0), SimBrake.window(fs, 0), SimBrake.window(2.0 * fs, 0), SimBrake.window(fs, 1)]\n"
 "\tif w != [8, 8, 14, 20, 20, 15]:\n"
 "\t\treturn \"the start window by power: %s (want [8, 8, 14, 20, 20, 15])\" % str(w)\n",
 "\tvar w: Array = [SimBrake.window(0.3, 0), SimBrake.window(0.55, 0), SimBrake.window(0.775, 0), SimBrake.window(1.0, 0), SimBrake.window(2.0, 0), SimBrake.window(1.0, 1)]\n"
 "\tif w != [8, 8, 14, 20, 20, 18]:\n"
 "\t\treturn \"the start window by power: %s (want [8, 8, 14, 20, 20, 18])\" % str(w)\n"
 "\tvar pf := SimState.Fighter.new()\n"
 "\tif SimBrake.power(pf, 0.5 * fs) != 0.5 or SimBrake.power(pf, 3.0 * fs) != 1.0:\n"
 "\t\treturn \"a send with no launcher's power: its speed over a full launch's, at most 1\"\n"
 "\tpf.launchPower = 0.62\n"
 "\tif SimBrake.power(pf, 3.0 * fs) != 0.62:\n"
 "\t\treturn \"a launch's own power is not the window's\"\n"),
("\tif f.start != f.at or f.at != SimBrake.window(f.v0, 0) or f.at < 8 or f.at > 20:\n",
 "\tif f.start != f.at or f.at != SimBrake.window(SimMathx.jmin(1.0, f.v0 / SimBrake.fullSpeed), 0) or f.at < 8 or f.at > 20:\n"),
])
# the marks: set before a send, spent at it
s = open(p, encoding='utf-8').read()
a = "\tif runs.special.start >= 0:\n\t\treturn \"a set piece's send was braked\"\n"
assert s.count(a) == 1
s = s.replace(a, a + '''	var K := SimCore.createSim()
	SimCore.newMatch(K, 5, {"p1": false, "p2": false}, {"brake": true})
	var KD = K.fighters[1]
	KD.y = WorldTerrain.groundY(K, KD.x) + 400.0
	KD.brk.marks = 2
	KD.launchPower = 0.9
	DirLaunch.doLaunch(K, K.fighters[0], KD, {"ux": 0.6, "uy": 0.8}, 2400.0, false)
	SimCore.step(K, [null, null])
	if KD.brk.at != SimBrake.window(0.9, 2) or KD.brk.marks != 0:
		return "a send with power 0.9 and two marks: window %d (want %d), marks %d left" % [KD.brk.at, SimBrake.window(0.9, 2), KD.brk.marks]
	SimCore.dispose(K)
''')
open(p, 'w', encoding='utf-8', newline='\n').write(s)

# Controls' brake_ready (docs/controls/haptics.md item 5): an air_brake "ready" at the rising edge of the brake being
# settable, once a send: the first tick he could start it (in the air, past the window, not a set piece's send).
edit('sim/core/state.gd', [
("\tvar marks: int = 0         # the send kind's marks on him (air sense): the sender's to set; 0 until launch-anywhere\n",
 "\tvar marks: int = 0         # the send kind's marks on him (air sense): the sender's to set; 0 until launch-anywhere\n"
 "\tvar told: bool = false     # this send's \"ready\" was told (the first tick he could brake: Controls' brake_ready)\n"),
])
edit('sim/core/brake.gd', [
("const HASHED: Array = [\"n\", \"t\", \"v0\", \"at\", \"no\", \"on\", \"marks\"]",
 "const HASHED: Array = [\"n\", \"t\", \"v0\", \"at\", \"no\", \"on\", \"marks\", \"told\"]"),
("\t\tb.no = f.launchSpecial",
 "\t\tb.told = false\n\t\tb.no = f.launchSpecial"),
("\tvar air: bool = f.slide == 0.0 and f.chainEvt == 0.0\n",
 "\tvar air: bool = f.slide == 0.0 and f.chainEvt == 0.0\n"
 "\tvar can: bool = air and not b.no and b.t >= b.at and b.v0 > 0.0   # he could start it now\n"
 "\tif can and not b.told:   # the rising edge, once a send: Controls' brake_ready (one sharp tick), Audio, the HUD\n"
 "\t\tb.told = true\n"
 "\t\t_event(S, f, \"ready\", \"window\")\n"),
("\telif held and air and not b.no and b.t >= b.at and b.v0 > 0.0:\n", "\telif held and can:\n"),
])
edit(p, [
("\"slowing\": true, \"at\": -1}", "\"slowing\": true, \"at\": -1, \"ready\": -1, \"readies\": 0}"),
("\t\t\t\tif e.type == \"air_brake\" and e.text == \"start\":\n\t\t\t\t\tr.start = t\n",
 "\t\t\t\tif e.type == \"air_brake\" and e.text == \"ready\":\n\t\t\t\t\tr.ready = t\n\t\t\t\t\tr.readies += 1\n"
 "\t\t\t\telif e.type == \"air_brake\" and e.text == \"start\":\n\t\t\t\t\tr.start = t\n"),
("\tif runs.special.start >= 0:\n\t\treturn \"a set piece's send was braked\"\n",
 "\tif runs.special.start >= 0:\n\t\treturn \"a set piece's send was braked\"\n"
 "\tif f.ready != f.at or f.readies != 1 or runs.special.readies != 0:\n"
 "\t\treturn \"the brake's ready: told at tick %d (want %d), %d times; %d for a set piece's send (want 0)\" % [f.ready, f.at, f.readies, runs.special.readies]\n"),
])
edit('docs/architecture/fx-events.md', [
("the air brake only (`S.brakeOn`; `sim/core/brake.gd`): `text` start or end; `kind` the reason (held at the start;",
 "the air brake only (`S.brakeOn`; `sim/core/brake.gd`): `text` ready, start or end; `kind` the reason (window at the ready, the first tick of a send he could brake, once a send: Controls' `brake_ready`; held at the start;"),
])
print("the brake: air sense 10%, the launcher's power, a flight's end clears it, the brake's ready")
