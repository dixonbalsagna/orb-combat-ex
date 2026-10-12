# PARKED (Simulation, 2026-10-12): the blow's weight on the damage event, for Audio. Not applied; not run by anything.
#
# Today a landed blow's event carries its weight as `kind` (light, medium, heavy). A guarded blow's kind is `guard`, so
# its weight is lost and Audio falls back to the blow cue. This adds `weight` to the damage event: the exchange's kind
# when it is light, medium or heavy, kept on a guarded blow; "" for a hit that is not a blow of an exchange (a shot, a
# beam, a landing).
#
# It is an event field, so it MOVES EVERY GOLDEN'S LIGHT DIGEST and no state hash: tick counts and every gameplay
# checkpoint must stay identical (python sim/core/tools/golden_cmp.py <old> <new>). By the EP's ruling it rides with the
# next golden regeneration and has none of its own. Prove it alone on a clean export first, then land it in that window.
# The anchors are text: re-check them against the HEAD of the day.
# Usage: python docs/architecture/pending/weight_event.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s=open(p,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(p,a[:70],s.count(a))
        s=s.replace(a,b)
    open(p,'w',encoding='utf-8',newline='\n').write(s)

edit('sim/core/state.gd', [
('''	var mode: String = ""        # building_fall: "implode" or "burst"
''','''	var mode: String = ""        # building_fall: "implode" or "burst"
	var weight: String = ""      # damage: the blow's weight (light, medium, heavy), kept on a guarded blow; "" for a hit that is not a blow of an exchange
'''),
])
edit('sim/core/fx.gd', [
('''static func damage(S: SimState, f, attacker, amount: float, region: String, kind: String, col: String, number: bool, form: String = "") -> void:''',
 '''static func damage(S: SimState, f, attacker, amount: float, region: String, kind: String, col: String, number: bool, form: String = "", weight: String = "") -> void:'''),
('''	e.region = region; e.kind = kind; e.number = number
''','''	e.region = region; e.kind = kind; e.number = number; e.weight = weight
'''),
])
edit('sim/core/hash.gd', [
('''"damage": ["x", "y", "amount", "col", "attacker", "victim", "region", "kind", "number", "z", "mode"]''',
 '''"damage": ["x", "y", "amount", "col", "attacker", "victim", "region", "kind", "number", "z", "mode", "weight"]'''),
])
edit('sim/core/damage.gd', [
('''## (SimWounds.BLOCK_HEAVY and the rest). named: the region a landed blow names (0 to 3), or -1 to draw it by the family.
static func hurt(S: SimState, f, amt: float, by, fam: String = "spread", kind: String = "impact", col: String = "", number: bool = false, form: String = "", block: int = 0, named: int = -1) -> int:''',
 '''## (SimWounds.BLOCK_HEAVY and the rest). named: the region a landed blow names (0 to 3), or -1 to draw it by the family.
## weight: the blow's weight for the event (light, medium, heavy), or empty.
static func hurt(S: SimState, f, amt: float, by, fam: String = "spread", kind: String = "impact", col: String = "", number: bool = false, form: String = "", block: int = 0, named: int = -1, weight: String = "") -> int:'''),
('''	SimFx.damage(S, f, by, amt, SimWounds.REGIONS[region] if region >= 0 else "", kind, col, number, form)
''','''	SimFx.damage(S, f, by, amt, SimWounds.REGIONS[region] if region >= 0 else "", kind, col, number, form, weight)
'''),
('''	var region: int = hurt(S, D, dd, A, fam, kind, "#ffd45a" if o.get("ignoreStance", false) else "#ffffff", true, form, block, named)
''','''	# The blow's weight, for the event: the exchange's kind, kept when the blow is guarded (the event's kind is then guard).
	var weight: String = ex.kind if (ex != null and (ex.kind == "light" or ex.kind == "medium" or ex.kind == "heavy")) else ""
	var region: int = hurt(S, D, dd, A, fam, kind, "#ffd45a" if o.get("ignoreStance", false) else "#ffffff", true, form, block, named, weight)
'''),
])
edit('sim/core/tools/parity.gd', [
('''		if dealt <= 0.0 or e == null or e.kind != kind or e.mode != "brawl":
			return "a landed %s sent a damage event of kind %s" % [kind, "none" if e == null else e.kind]
''','''		if dealt <= 0.0 or e == null or e.kind != kind or e.mode != "brawl" or e.weight != kind:
			return "a landed %s sent a damage event of kind %s and weight %s" % [kind, "none" if e == null else e.kind, "none" if e == null else e.weight]
'''),
('''		if e == null or e.kind != "guard" or wantA <= 0 or d.wear[A] != wantA or d.wear[L] != wantL:
''','''		if e != null and e.weight != kind:
			return "a blocked %s sent a damage event of weight %s" % [kind, e.weight]
		if e == null or e.kind != "guard" or wantA <= 0 or d.wear[A] != wantA or d.wear[L] != wantL:
'''),
('''	if be == null or be.kind != "blast" or be.mode != "":
''','''	if be == null or be.kind != "blast" or be.mode != "" or be.weight != "":
'''),
])
edit('docs/architecture/fx-events.md', [
('''| `damage` | x, y, amount, col, attacker, victim, region, kind, number, mode |''','''| `damage` | x, y, amount, col, attacker, victim, region, kind, number, mode, weight |'''),
('''(`brawl-wear-and-mood.md`, sections 1 and 7) |''','''(`brawl-wear-and-mood.md`, sections 1 and 7); `weight` is the blow's weight (light, medium, heavy), kept on a guarded blow whose `kind` is guard, and empty for a hit that is not a blow of an exchange |'''),
])
print("the damage event carries the blow's weight")
