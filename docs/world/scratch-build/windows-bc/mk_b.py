"""Stage B: breaches (Building.fhole, floor_hit x0 x1).  python mk_b.py <root>   (on stage W)
Lines in other directors' files: state.gd (Building.fhole, FxEvent.x0), hash.gd (the fhole array, floor_hit fields x0 x1), fx.gd (floorHit, floorHitShot x0 x1)."""
from mk_wbc_lib import *
R = root()


def state(s):
    s = rep(s, '''	var fdmg := PackedFloat32Array()   # damage per floor, allocated on the first local hit (empty before)
''', '''	var fdmg := PackedFloat32Array()   # damage per floor, allocated on the first local hit (empty before)
	var fhole := PackedFloat32Array()  # B: the broken run of each floor, two numbers a floor (its centre as a fraction of the half width, its share of the width), allocated with fdmg
''')
    s = rep(s, '''	var eta: float = 0.0         # hazard_telegraph, danger: seconds until it lands, 0 when unknown
''', '''	var eta: float = 0.0         # hazard_telegraph, danger: seconds until it lands, 0 when unknown
	var x0: float = 0.0          # floor_hit: where the breach starts (x1 is where it ends)
''')
    return s


def hashf(s):
    s = rep(s, '''		out.append(float(b.fdmg.size()))   # floor damage: empty for a building never hit locally
		for v in b.fdmg:
			out.append(v)
''', '''		out.append(float(b.fdmg.size()))   # floor damage: empty for a building never hit locally
		for v in b.fdmg:
			out.append(v)
		out.append(float(b.fhole.size()))   # B: the broken run of each floor
		for v in b.fhole:
			out.append(v)
''')
    return fx_fields_add(s, floor_hit_extra=["x0", "x1"])


def fx(s):
    s = rep(s, '''static func floorHit(S: SimState, f, b, floor_: int, n: int, outcome: String, ratio: float, y: float, by) -> void:
	var e := _ev(S, "floor_hit")
	e.b = float(b.idx); e.floor = floor_; e.n = n; e.outcome = outcome; e.ratio = ratio
	e.x = b.x; e.y = y; e.z = WorldBrunt.faceZ(b)
''', '''static func floorHit(S: SimState, f, b, floor_: int, n: int, outcome: String, ratio: float, y: float, by, x0: float = 0.0, x1: float = 0.0) -> void:
	var e := _ev(S, "floor_hit")
	e.b = float(b.idx); e.floor = floor_; e.n = n; e.outcome = outcome; e.ratio = ratio
	e.x = b.x; e.y = y; e.z = WorldBrunt.faceZ(b); e.x0 = x0; e.x1 = x1
''')
    s = rep(s, '''static func floorHitShot(S: SimState, b, floor_: int, n: int, outcome: String, ratio: float, y: float, slot: int, ux: float, uy: float) -> void:
	var e := _ev(S, "floor_hit")
	e.b = float(b.idx); e.floor = floor_; e.n = n; e.outcome = outcome; e.ratio = ratio
	e.x = b.x; e.y = y; e.z = WorldBrunt.faceZ(b)
''', '''static func floorHitShot(S: SimState, b, floor_: int, n: int, outcome: String, ratio: float, y: float, slot: int, ux: float, uy: float, x0: float = 0.0, x1: float = 0.0) -> void:
	var e := _ev(S, "floor_hit")
	e.b = float(b.idx); e.floor = floor_; e.n = n; e.outcome = outcome; e.ratio = ratio
	e.x = b.x; e.y = y; e.z = WorldBrunt.faceZ(b); e.x0 = x0; e.x1 = x1
''')
    return s


def brunt(s):
    s = rep(s, '''	"wallSlamMul": 2.0, "wallStaggerTicks": 24,
}''', '''	"wallSlamMul": 2.0, "wallStaggerTicks": 24,
	# B: breaches. A punch breaks a run of the story: breachBase + breachPerRatio * ratio fighter heights of the width, kept in fhole; the story is gone
	# (its fmask bit clears) at clearAt of the width. breachDeath: the share of a holed story's people a punch kills before the width counts.
	"breaches": 1, "breachBase": 0.8, "breachPerRatio": 0.6, "clearAt": 0.7, "breachDeath": 0.25, "breachWeakens": 0.5, "breachGrow": 0.5,
}''')
    s = rep(s, '''			var st: float = floorStr(b, j)
			if haveD and b.fdmg[j] > 0.0:''', '''			var st: float = floorStr(b, j)
			if b.fhole.size() == 2 * b.floors and b.fhole[2 * j + 1] > 0.0:   # B: a floor with a breach carries less
				st = maxf(st * float(cm.wallMin), st * (1.0 - float(cm.breachWeakens) * b.fhole[2 * j + 1]))
			if haveD and b.fdmg[j] > 0.0:''')
    s = rep(s, '''	var lowest: int = oc.k
	if oc.outcome == "punch":
		var cleared: int = 0
		for j in oc.hit:
			b.fmask = b.fmask & ~(1 << j)
			b.fdmg[j] = 0.0
			cleared += 1
			lowest = mini(lowest, j)
		if cleared > 0:
			WorldCollateral.kill(S, b.idx, popF * float(cleared), by, evt, cx, lowest)
		SimFx.floorHit(S, f, b, lowest, cleared, "punch", oc.ratio, y, by)''', '''	var lowest: int = oc.k
	if oc.outcome == "punch":
		var pr: Dictionary = punchFloors(b, oc, 0.0)   # a body crosses the building: the breach is centred on it
		lowest = mini(lowest, pr.lowest)
		var dead: float = popF * pr.deaths
		if dead > 0.0:
			WorldCollateral.kill(S, b.idx, dead, by, evt, cx, lowest)
		SimFx.floorHit(S, f, b, lowest, pr.cleared, "punch", oc.ratio, y, by, pr.x0, pr.x1)''')
    s = rep(s, '''## A cleared span longer than TUNNEL_MAX drops the floors above it''', '''## B: a punch on the floors a body covers (oc.hit). Each floor takes a breach of breachBase + breachPerRatio * ratio fighter heights of the width, centred
## at centre (a fraction of the half width: 0 for a body that crosses the building, a shot's x for a shot), merged with what is there; the floor is gone
## (its fmask bit clears, as a punch always cleared it) when the breach is clearAt of the width. With breaches off every punch clears, as before.
## Returns {"cleared", "lowest", "deaths" (the floors' share of their people to kill: a gone floor all of it, a holed one breachDeath + the share),
## "x0", "x1" (the breach on the lowest floor hit, in world x)}.
static func punchFloors(b, oc: Dictionary, centre: float) -> Dictionary:
	var c: Dictionary = cfg()
	var res := {"cleared": 0, "lowest": oc.k, "deaths": 0.0, "x0": b.x, "x1": b.x}
	var wbh: float = maxf(b.w / BH, 0.5)
	var F: int = b.floors
	var on: bool = int(c.breaches) != 0
	var first: bool = true
	for j in oc.hit:
		var gone: bool = true
		var share: float = 1.0
		if on:
			var bw: float = float(c.breachBase) + float(c.breachPerRatio) * minf(float(oc.ratio), 40.0)
			share = minf(bw / wbh, 1.0)
			if b.fhole.size() != 2 * F:
				b.fhole = PackedFloat32Array()
				b.fhole.resize(2 * F)
				b.fhole.fill(0.0)
			var lo: float = centre - share
			var hi: float = centre + share
			var grow: float = 0.0
			if b.fhole[2 * j + 1] > 0.0:
				lo = minf(lo, b.fhole[2 * j] - b.fhole[2 * j + 1])
				hi = maxf(hi, b.fhole[2 * j] + b.fhole[2 * j + 1])
				grow = float(c.breachGrow) * share   # a floor that was already broken: the breach widens by half of this one's width on top of the union
			lo = maxf(lo, -1.0)
			hi = minf(hi, 1.0)
			share = minf((hi - lo) * 0.5 + grow, 1.0)
			b.fhole[2 * j] = (lo + hi) * 0.5
			b.fhole[2 * j + 1] = share
			gone = share >= float(c.clearAt)
			if first:
				res.x0 = b.x + lo * b.w * 0.5
				res.x1 = b.x + hi * b.w * 0.5
				first = false
		if gone:
			b.fmask = b.fmask & ~(1 << j)
			if b.fdmg.size() == F:
				b.fdmg[j] = 0.0
			res.cleared += 1
			res.deaths += 1.0
		else:
			if b.fdmg.size() == F:
				b.fdmg[j] += oc.dmg * 0.25   # a holed story is damaged: it counts for the stage and for the memory of its walls
			res.deaths += minf(1.0, float(c.breachDeath) + share)
		res.lowest = mini(res.lowest, j)
	return res


## A cleared span longer than TUNNEL_MAX drops the floors above it''')
    return s


def blast(s):
    return rep(s, '''	if oc.outcome == "punch":
		var cleared: int = 0
		for j in oc.hit:
			b.fmask = b.fmask & ~(1 << j)
			b.fdmg[j] = 0.0
			cleared += 1
			lowest = mini(lowest, j)
		if cleared > 0:
			WorldCollateral.kill(S, b.idx, popF * float(cleared), by, 0.0, cx, lowest)
		SimFx.floorHitShot(S, b, lowest, cleared, "punch", oc.ratio, y, slot, ux, uy)''', '''	if oc.outcome == "punch":
		var pr: Dictionary = WorldBrunt.punchFloors(b, oc, clampf(SimWrap.sdx(b.x, cx) / (b.w * 0.5), -1.0, 1.0))   # a shot breaks the story where it lands
		lowest = mini(lowest, pr.lowest)
		var dead: float = popF * pr.deaths
		if dead > 0.0:
			WorldCollateral.kill(S, b.idx, dead, by, 0.0, cx, lowest)
		SimFx.floorHitShot(S, b, lowest, pr.cleared, "punch", oc.ratio, y, slot, ux, uy, pr.x0, pr.x1)''')


def struct(s):
    s = rep(s, '''	if b.floors >= WorldBrunt.FLOORS_MIN and b.fmask != (1 << b.floors) - 1:
		s = maxi(s, _cutStage)
	elif b.floors >= WorldBrunt.FLOORS_MIN and b.fdmg.size() > 0:''', '''	if b.floors >= WorldBrunt.FLOORS_MIN and b.fmask != (1 << b.floors) - 1:
		s = maxi(s, _cutStage)
	elif b.floors >= WorldBrunt.FLOORS_MIN and b.fhole.size() > 0 and _holed(b):
		s = maxi(s, _cutStage)   # B: a floor with a breach counts like a cut one
	elif b.floors >= WorldBrunt.FLOORS_MIN and b.fdmg.size() > 0:''')
    s = rep(s, '''## The most of a building's hit points one floors hit may take from its core''', '''static func _holed(b) -> bool:
	for k in range(b.floors):
		if 2 * k + 1 < b.fhole.size() and b.fhole[2 * k + 1] > 0.0:
			return true
	return false


## The most of a building's hit points one floors hit may take from its core''')
    return s


rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/core/hash.gd', hashf)
rw(R, 'sim/core/fx.gd', fx)
rw(R, 'sim/world/brunt.gd', brunt)
rw(R, 'sim/world/blast.gd', blast)
rw(R, 'sim/world/structures.gd', struct)
data_keys(R, {"breaches": 1, "breachBase": 0.8, "breachPerRatio": 0.6, "clearAt": 0.7, "breachDeath": 0.25, "breachWeakens": 0.5, "breachGrow": 0.5},
          "breaches: a punch breaks a run of the story, breachBase + breachPerRatio x ratio fighter heights of its width, and the story is gone at clearAt of the width (0: every punch clears the story, as before); breachDeath: the share of a holed story's people a punch kills before the width counts; breachWeakens: how much a breach weakens the floor; breachGrow: a floor already broken widens by this share of the new breach on top of the union.",
          {
              "breaches": {"type": "integer", "minimum": 0, "maximum": 1, "description": "1: a punch breaks a run of the story and it is gone at clearAt of the width; 0: every punch clears the story, as before."},
              "breachBase": {"type": "number", "exclusiveMinimum": 0, "description": "The breach a punch makes, in fighter heights of the width, before the ratio."},
              "breachPerRatio": {"type": "number", "minimum": 0, "description": "... and for each unit of the hit's ratio over the floors' strength."},
              "clearAt": {"type": "number", "exclusiveMinimum": 0, "maximum": 1, "description": "The share of a story's width broken at which the story is gone."},
              "breachDeath": {"type": "number", "minimum": 0, "maximum": 1, "description": "The share of a holed story's people a punch kills before its breach's width counts."},
              "breachWeakens": {"type": "number", "minimum": 0, "maximum": 1, "description": "How much of its strength a floor loses at a breach of its whole width."},
              "breachGrow": {"type": "number", "minimum": 0, "maximum": 1, "description": "A floor already broken: a further breach widens it by this share of its own width on top of the union."},
          })
print('stage B applied')
