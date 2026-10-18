"""Stage B: breaches (Building.fhole, floor_hit x0 x1).  python mk_b.py <root>   (on stage W)
Lines in other directors' files: state.gd (Building.fhole, FxEvent.x0), hash.gd (the fhole array, floor_hit fields x0 x1), fx.gd (floorHit, floorHitShot x0 x1)."""
from mk_wbc_lib import *
R = root()


def state(s):
    s = rep(s, '''	var fdmg := PackedFloat32Array()   # damage per floor, allocated on the first local hit (empty before)
''', '''	var fdmg := PackedFloat32Array()   # damage per floor, allocated on the first local hit (empty before)
	var fhole := PackedFloat32Array()  # B: the slot broken on each floor, three numbers a floor (its two ends as fractions of the half width, -1 to 1, and how much of the story is gone, 0 to 1), allocated with fdmg
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
''', '''	"wallSlamMul": 2.0, "wallStaggerTicks": 24,
	# B: breaches. A punch breaks a run of the story: breachBase + breachPerRatio * ratio fighter heights of the width, kept in fhole; the story is gone
	# (its fmask bit clears) at clearAt of the width. breachDeath: the share of a holed story's people a punch kills before the width counts.
	"breaches": 1, "breachBase": 0.8, "breachPerRatio": 0.6, "clearAt": 0.7, "breachDeath": 0.25, "breachWeakens": 0.5, "breachGrow": 0.5,
''')
    s = rep(s, '''			var st: float = floorStr(b, j)
			if haveD and b.fdmg[j] > 0.0:''', '''			var st: float = floorStr(b, j)
			if b.fhole.size() == 3 * b.floors and b.fhole[3 * j + 2] > 0.0:   # B: a floor with a breach carries less
				st = maxf(st * float(cm.wallMin), st * (1.0 - float(cm.breachWeakens) * b.fhole[3 * j + 2]))
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
	var side: float = -1.0 if f.vx >= 0.0 else 1.0   # the edge he came in by (a held hit's mark keeps it)
	if oc.outcome == "punch":
		var pr: Dictionary = punchFloors(b, oc, 0.0, true)   # a body crosses the building: the slot runs from side to side
		lowest = mini(lowest, pr.lowest)
		var dead: float = popF * pr.deaths
		if dead > 0.0:
			WorldCollateral.kill(S, b.idx, dead, by, evt, cx, lowest)
		SimFx.floorHit(S, f, b, lowest, pr.cleared, "punch", oc.ratio, y, by, pr.x0, pr.x1)''')
    s = rep(s, '''	elif oc.outcome == "crack":
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
		var share: float = minf(1.0, oc.ratio * FLOOR_DEATH)''', '''	elif oc.outcome == "crack":
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
			markSide(b, j, side)
		var share: float = minf(1.0, oc.ratio * FLOOR_DEATH)''')
    s = rep(s, '''	else:
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
		SimFx.floorHit(S, f, b, oc.hit[0] if oc.hit.size() > 0 else oc.k, 0, "dent", oc.ratio, y, by)''', '''	else:
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
			markSide(b, j, side)
		SimFx.floorHit(S, f, b, oc.hit[0] if oc.hit.size() > 0 else oc.k, 0, "dent", oc.ratio, y, by)''')
    s = rep(s, '''## A cleared span longer than TUNNEL_MAX drops the floors above it''', '''## B: a held hit (a crack or a dent) writes its SIDE into the floor's slot: both ends at the edge the body came in by (-1 or 1), nothing gone, so a
## mark's side survives a seek and a late join (Rendering's destruction-look.md section 8). A floor already broken keeps its slot.
static func markSide(b, j: int, side: float) -> void:
	if int(cfg().breaches) == 0:
		return
	var F: int = b.floors
	if b.fhole.size() != 3 * F:
		b.fhole = PackedFloat32Array()
		b.fhole.resize(3 * F)
		b.fhole.fill(0.0)
	if b.fhole[3 * j + 2] > 0.0:
		return
	b.fhole[3 * j] = side
	b.fhole[3 * j + 1] = side


## B: a punch on the floors a body covers (oc.hit). The blow breaks a SLOT of each floor (the span of the plate it swept: from side to side for a body
## that crosses the building, full is true; a run centred at centre for a shot) and takes a share of the story with it: breachBase + breachPerRatio * ratio
## fighter heights of its width, so the slot says WHERE it is broken and g (kept in fhole) says HOW MUCH of the story is gone. A floor already broken adds
## breachGrow of the new share. The floor is gone (its fmask bit clears, as a punch always cleared it) when g is clearAt. With breaches off every punch
## clears, as before. Returns {"cleared", "lowest", "deaths" (the floors' share of their people to kill: a gone floor all of it, a holed one
## breachDeath + the share), "x0", "x1" (the slot on the lowest floor hit, in world x)}.
static func punchFloors(b, oc: Dictionary, centre: float, full: bool = false) -> Dictionary:
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
			var gnew: float = minf((float(c.breachBase) + float(c.breachPerRatio) * minf(float(oc.ratio), 40.0)) / wbh, 1.0)
			if b.fhole.size() != 3 * F:
				b.fhole = PackedFloat32Array()
				b.fhole.resize(3 * F)
				b.fhole.fill(0.0)
			var lo: float = -1.0 if full else maxf(centre - gnew, -1.0)
			var hi: float = 1.0 if full else minf(centre + gnew, 1.0)
			var g0: float = b.fhole[3 * j + 2]
			if g0 > 0.0:
				lo = minf(lo, b.fhole[3 * j])
				hi = maxf(hi, b.fhole[3 * j + 1])
				share = minf(g0 + float(c.breachGrow) * gnew, 1.0)   # a floor that was already broken: the story goes a further breachGrow of this blow's share
			else:
				share = gnew
			b.fhole[3 * j] = lo
			b.fhole[3 * j + 1] = hi
			b.fhole[3 * j + 2] = share
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
    s = rep(s, '''	if oc.outcome == "punch":
		var cleared: int = 0
		for j in oc.hit:
			b.fmask = b.fmask & ~(1 << j)
			b.fdmg[j] = 0.0
			cleared += 1
			lowest = mini(lowest, j)
		if cleared > 0:
			WorldCollateral.kill(S, b.idx, popF * float(cleared), by, 0.0, cx, lowest)
		SimFx.floorHitShot(S, b, lowest, cleared, "punch", oc.ratio, y, slot, ux, uy)''', '''	var side: float = -1.0 if ux >= 0.0 else 1.0   # the edge the shot came in by (a held hit's mark keeps it)
	if oc.outcome == "punch":
		var pr: Dictionary = WorldBrunt.punchFloors(b, oc, clampf(SimWrap.sdx(b.x, cx) / (b.w * 0.5), -1.0, 1.0), false)   # a shot breaks the story where it lands
		lowest = mini(lowest, pr.lowest)
		var dead: float = popF * pr.deaths
		if dead > 0.0:
			WorldCollateral.kill(S, b.idx, dead, by, 0.0, cx, lowest)
		SimFx.floorHitShot(S, b, lowest, pr.cleared, "punch", oc.ratio, y, slot, ux, uy, pr.x0, pr.x1)''')
    s = rep(s, '''	elif oc.outcome == "crack":
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
		var d: float = popF * float(oc.hit.size()) * minf(1.0, oc.ratio * WorldBrunt.FLOOR_DEATH)''', '''	elif oc.outcome == "crack":
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
			WorldBrunt.markSide(b, j, side)
		var d: float = popF * float(oc.hit.size()) * minf(1.0, oc.ratio * WorldBrunt.FLOOR_DEATH)''')
    s = rep(s, '''	else:
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
		SimFx.floorHitShot(S, b, oc.hit[0] if oc.hit.size() > 0 else oc.k, 0, "dent", oc.ratio, y, slot, ux, uy)''', '''	else:
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
			WorldBrunt.markSide(b, j, side)
		SimFx.floorHitShot(S, b, oc.hit[0] if oc.hit.size() > 0 else oc.k, 0, "dent", oc.ratio, y, slot, ux, uy)''')
    return s


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
		if 3 * k + 2 < b.fhole.size() and b.fhole[3 * k + 2] > 0.0:
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
          "breaches: a punch breaks a run of the story, breachBase + breachPerRatio x ratio fighter heights of its width is the share of the story a punch takes (the slot it breaks is the span it swept), and the story is gone at clearAt (0: every punch clears the story, as before); breachDeath: the share of a holed story's people a punch kills before the width counts; breachWeakens: how much a breach weakens the floor; breachGrow: a floor already broken widens by this share of the new breach on top of the union.",
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
