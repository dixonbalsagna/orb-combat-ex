"""Slice 1 of docs/world/staged-destruction.md: the hybrid pair (reach[3] 1.8, area.slam 0.75), WorldStructures.stage(b) with data/biomes/stages.json,
the building_stage event.  python mk_stage1.py <root>"""
import sys, json, os
R = sys.argv[1].rstrip('/') + '/'


def rw(p, fn):
    s = open(R + p, encoding='utf-8', newline='').read()
    cr = '\r\n' in s
    s = fn(s.replace('\r\n', '\n'))
    open(R + p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if cr else s)


def rep(s, a, b):
    assert s.count(a) == 1, (a[:90], s.count(a))
    return s.replace(a, b)


# ---- data
open(R + 'data/biomes/stages.json', 'w', encoding='utf-8', newline='\n').write(json.dumps({
    "schema": "biomes.stages/1",
    "_about": "The stages of a building's destruction (docs/world/staged-destruction.md; WorldStructures.stage). Stage 0 is intact and 4 is rubble (not alive), fixed in code. hpAt: the share of its hit points a building must fall under to reach stage 1 (windows out), 2 (a part gone) and 3 (a shell). cutFloorsStage: the stage a skyscraper with a cut floor is at least in. leaveFrac: one blast (damageArea, not a beam or a brunt) cannot take a standing building below this share of its hit points, so a second blast finishes it (0 is off).",
    "hpAt": [0.9, 0.65, 0.35],
    "cutFloorsStage": 2,
    "leaveFrac": 0.10
}, indent=2) + '\n')
for f in ('KAI', 'VORR'):
    p = R + 'data/fighters/%s/ladder.json' % f
    t = open(p, encoding='utf-8', newline='').read()
    assert t.count('"structure": [1.0, 1.0, 1.6, 2.8]') == 1
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('"structure": [1.0, 1.0, 1.6, 2.8]', '"structure": [1.0, 1.0, 1.6, 1.8]', 1))
p = R + 'data/biomes/contact.json'
t = open(p, encoding='utf-8', newline='').read()
assert t.count('"slam": 0.9') == 1
open(p, 'w', encoding='utf-8', newline='').write(t.replace('"slam": 0.9', '"slam": 0.75', 1))

# ---- structures.gd: the stage function, the data, the emission in damageBuilding
STAGE_CODE = '''
# ---- the stages of a building's destruction (docs/world/staged-destruction.md) ----
const STAGES_PATH: String = "res://data/biomes/stages.json"
const STAGES_SCHEMA: String = "biomes.stages/1"
static var _hpAt: Array = [0.9, 0.65, 0.35]
static var _cutStage: int = 2
static var _leave: float = 0.0
static var _stLoaded: bool = false
static var _stErrors: Array = []
static var _stHash: String = ""


static func stagesErrors() -> Array:
	if not _stLoaded:
		_stLoad()
	return _stErrors


static func stagesHash() -> String:
	if not _stLoaded:
		_stLoad()
	return _stHash


static func _stLoad() -> void:
	_stLoaded = true
	_stErrors = []
	var f := FileAccess.open(STAGES_PATH, FileAccess.READ)
	if f == null:
		_stErrors.append("stages.json: cannot open " + STAGES_PATH)
		return
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != STAGES_SCHEMA:
		_stErrors.append("stages.json: not a %s object" % STAGES_SCHEMA)
		return
	var hp = j.get("hpAt")
	if not (hp is Array) or hp.size() != 3 or not (hp[0] > hp[1] and hp[1] > hp[2] and hp[2] > 0.0 and hp[0] < 1.0):
		_stErrors.append("stages.json: hpAt is three numbers, strictly decreasing, in (0, 1)")
		return
	var h := SimHash.Hasher.new()
	h.text("biomes.stages")
	FighterData._canon(h, j)
	_stHash = h.hex()
	_hpAt = [float(hp[0]), float(hp[1]), float(hp[2])]
	_cutStage = clampi(int(j.get("cutFloorsStage", 2)), 1, 3)
	_leave = clampf(float(j.get("leaveFrac", 0.0)), 0.0, 0.9)


## The stage of a building, 0 to 4: 0 intact, 1 windows out, 2 a part gone, 3 a shell, 4 rubble (not alive). A pure function of its hit points and its
## cut floors (and so of the hashed state): Rendering calls it every frame, a seek or a late join needs nothing saved.
static func stage(b) -> int:
	if not _stLoaded:
		_stLoad()
	if not b.alive:
		return 4
	var f: float = b.hp / b.maxhp
	var s: int = 0
	if f < float(_hpAt[0]):
		s = 1
		if f < float(_hpAt[1]):
			s = 2
			if f < float(_hpAt[2]):
				s = 3
	if b.floors >= WorldBrunt.FLOORS_MIN and b.fmask != (1 << b.floors) - 1:
		s = maxi(s, _cutStage)
	return s


## The share of its hit points a blast must leave a standing building (stages.json leaveFrac; 0 off).
static func leaveFrac() -> float:
	if not _stLoaded:
		_stLoad()
	return _leave


## Send building_stage when the building's stage is no longer s0 (taken before the damage). n: the floors lost in the step.
static func stageEmit(S: SimState, b, s0: int, cause, cx: float, n: int = 0) -> void:
	var s1: int = stage(b)
	if s1 != s0:
		SimFx.buildingStage(S, b, s0, s1, cx, WorldCrater._slot(S, cause), n, curH(b))

'''


def structures(s):
    s = rep(s, '\n## Standing height shrinks with damage to 30 percent of full;', STAGE_CODE + '\n## Standing height shrinks with damage to 30 percent of full;')
    s = rep(s, '	var before: float = b.hp\n	b.hp -= d\n', '	var before: float = b.hp\n	var s0: int = stage(b)\n	b.hp -= d\n')
    s = rep(s, '''	else:
		SimFx.debris(S, b.x, gy + curH(b), 4, "#77808f", 300.0)
''', '''	else:
		SimFx.debris(S, b.x, gy + curH(b), 4, "#77808f", 300.0)
	if not local:   # (a collapse called by a floors path is reported by that path)
		stageEmit(S, b, s0, cause, cx)
''')
    s = rep(s, '		damageBuilding(S, b, dmg * (1.0 - SimMathx.jclamp(d / r, 0.0, 1.0) * 0.7), cause, "implode", x, evt, false, kp)\n', '''		var dd: float = dmg * (1.0 - SimMathx.jclamp(d / r, 0.0, 1.0) * 0.7)
		var lv: float = leaveFrac()
		if not beam and lv > 0.0 and b.hp > lv * b.maxhp:   # a blast cannot finish a standing building (stages.json leaveFrac): it leaves it at that share and the next blast takes it
			dd = minf(dd, b.hp - lv * b.maxhp)
		damageBuilding(S, b, dd, cause, "implode", x, evt, false, kp)
''')
    return s


rw('sim/world/structures.gd', structures)


# ---- brunt.gd: applyFloors reports its stage change once (collapse inside it is local and silent)
def brunt(s):
    s = rep(s, 'static func applyFloors(S: SimState, b, oc: Dictionary, by, evt: float, cx: float, f, y: float) -> Dictionary:\n',
            '''static func applyFloors(S: SimState, b, oc: Dictionary, by, evt: float, cx: float, f, y: float) -> Dictionary:
	var s0: int = WorldStructures.stage(b)
	var fm0: int = b.fmask
	var r: Dictionary = _applyFloors(S, b, oc, by, evt, cx, f, y)
	WorldStructures.stageEmit(S, b, s0, by, cx, _bits(fm0 & ~b.fmask))
	return r


## The number of set bits.
static func _bits(m: int) -> int:
	var n: int = 0
	while m != 0:
		n += m & 1
		m >>= 1
	return n


static func _applyFloors(S: SimState, b, oc: Dictionary, by, evt: float, cx: float, f, y: float) -> Dictionary:
''')
    return s


rw('sim/world/brunt.gd', brunt)


# ---- blast.gd: a shot's floors hit
def blast(s):
    s = rep(s, '		var c: Dictionary = _floors(S, b, oc, by, x, y, slot, vx / sp, vy / sp)\n',
            '''		var s0: int = WorldStructures.stage(b)
		var fm0: int = b.fmask
		var c: Dictionary = _floors(S, b, oc, by, x, y, slot, vx / sp, vy / sp)
		WorldStructures.stageEmit(S, b, s0, by, x, WorldBrunt._bits(fm0 & ~b.fmask))
''')
    return s


rw('sim/world/blast.gd', blast)

# ---- fx.gd: the event; hash.gd: its fields; replay.gd: the data hash line (Simulation's lines)
rw('sim/core/fx.gd', lambda s: rep(s, '## B2: a brunt hit floors of a skyscraper', '''## A building's stage changed (WorldStructures.stage: 0 intact, 1 windows out, 2 a part gone, 3 a shell, 4 rubble): b, from, to, where it stands (x, y its
## ground, z its depth, w its width), h its standing height now, kind, cx the blast's x, owner the causing slot, n the floors lost in the step.
static func buildingStage(S: SimState, b, from_: int, to_: int, cx: float, owner: float, n: int, h: float) -> void:
	var e := _ev(S, "building_stage")
	e.b = float(b.idx); e.from = float(from_); e.to = float(to_); e.x = b.x; e.y = WorldStructures.baseY(S, b); e.z = b.z; e.w = b.w; e.h = h
	e.kind = b.kind; e.cx = cx; e.owner = owner; e.n = n


## B2: a brunt hit floors of a skyscraper'''))
rw('sim/core/hash.gd', lambda s: rep(s, '"floors_fall": [', '"building_stage": ["b", "from", "to", "x", "y", "z", "w", "h", "kind", "cx", "owner", "n"], "floors_fall": ['))
rw('sim/core/replay.gd', lambda s: rep(s, "	h.text(WorldBlast.dataHash())     # World's shot blast: data/biomes/blast.json\n", "	h.text(WorldBlast.dataHash())     # World's shot blast: data/biomes/blast.json\n	h.text(WorldStructures.stagesHash())   # World's building stages: data/biomes/stages.json\n"))
# ---- probe.gd (World's): two checks level a building with one huge blast; with the cap a second blast finishes it
def probe(s):
    a1 = "\tWorldStructures.damageArea(Sr, tw.x + 4000.0, 0.0, 6000.0, 1.0e7, Sr.fighters[1])\n"
    s = rep(s, a1, a1 + "\tWorldStructures.damageArea(Sr, tw.x + 4000.0, 0.0, 6000.0, 1.0e7, Sr.fighters[1])   # (the stage cap: the first blast leaves them standing, the second finishes them)\n")
    a2 = "\t\tWorldStructures.damageArea(Sh, tall3.x, 0.0, 600.0, 1.0e8, Sh.fighters[1])\n"
    s = rep(s, a2, a2 + "\t\tWorldStructures.damageArea(Sh, tall3.x, 0.0, 600.0, 1.0e8, Sh.fighters[1])   # (the second blast of the stage cap)\n")
    return s


rw('sim/world/tools/probe.gd', probe)

rw('sim/core/view/fx.gd', lambda s: rep(s, '"floor_hit", "floors_fall", "left_ground"', '"floor_hit", "floors_fall", "building_stage", "left_ground"'))
print('slice 1 applied')
