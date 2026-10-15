"""Stage C: the failing state, building_failing, the falling stack.  python mk_c.py <root>   (on stages W and B)
Lines in other directors' files: state.gd (Building.fail*, FxEvent.t_warn t_fall), hash.gd (the fail names and failHurt array, building_failing fields),
fx.gd (SimFx.buildingFailing), sim.gd (WorldStructures.stepFailing each tick)."""
from mk_wbc_lib import *
R = root()


def state(s):
    s = rep(s, '''	var fhole := PackedFloat32Array()  # B: the slot broken on each floor, three numbers a floor (its two ends as fractions of the half width, -1 to 1, and how much of the story is gone, 0 to 1), allocated with fdmg
''', '''	var fhole := PackedFloat32Array()  # B: the slot broken on each floor, three numbers a floor (its two ends as fractions of the half width, -1 to 1, and how much of the story is gone, 0 to 1), allocated with fdmg
	var failT: float = 0.0     # C: seconds into a collapse; negative is the warning before it
	var failK: int = -1        # C: the lowest floor not yet landed while it fails (-1: standing)
	var failDir: int = 0       # C: -1 or 1, the way it tips; 0 a pancake
	var failBy: int = -1       # C: the slot of the fighter who brought it down (-1: none)
	var failN: int = 0         # C: floors landed so far
	var failHurt := PackedFloat32Array()   # C: the damage the falling stack has done each fighter (one number a body in the match, allocated when it starts)
''')
    s = rep(s, '''	var hold: float = 0.0        # lodge: the seconds the body is held in the building
''', '''	var hold: float = 0.0        # lodge: the seconds the body is held in the building
	var t_warn: float = 0.0      # building_failing: seconds of warning before the first floor lands
	var t_fall: float = 0.0      # building_failing: seconds the stack takes to come down once it starts
''')
    return s


def hashf(s):
    s = rep(s, '"floors", "fmask", "wear",', '"floors", "fmask", "wear", "failT", "failK", "failDir", "failBy", "failN",')
    s = rep(s, '''		out.append(float(b.fhole.size()))   # B: the broken run of each floor
		for v in b.fhole:
			out.append(v)
''', '''		out.append(float(b.fhole.size()))   # B: the broken run of each floor
		for v in b.fhole:
			out.append(v)
		out.append(float(b.failHurt.size()))   # C: what a falling stack has done each fighter
		for v in b.failHurt:
			out.append(v)
''')
    return fx_fields_add(s, newtypes='"building_failing": ["b", "x", "y", "w", "h", "t_warn", "t_fall", "n", "owner", "kind"],')


def fx(s):
    return rep(s, '''## B2: after a burst through building b the fighter heads for nb''', '''## A tower begins to fail (World, the failing state): b, where it stands (x, y its ground, w its width, h its standing height), the seconds of warning
## and the seconds the stack takes to come down once it starts, dir the way it tips (0 a pancake), owner the slot that brought it down.
static func buildingFailing(S: SimState, b, y: float, h: float, t_warn: float, t_fall: float, dir: int, owner: float) -> void:
	var e := _ev(S, "building_failing")
	e.b = float(b.idx); e.x = b.x; e.y = y; e.w = b.w; e.h = h; e.t_warn = t_warn; e.t_fall = t_fall; e.n = dir; e.owner = owner; e.kind = b.kind


## B2: after a burst through building b the fighter heads for nb''')


def simf(s):
    return rep(s, '''	SimShots.step(S, dt)   # energy blasts in flight: they move, trade, and meet fighters and the ground
''', '''	SimShots.step(S, dt)   # energy blasts in flight: they move, trade, and meet fighters and the ground
	WorldStructures.stepFailing(S, dt)   # World: the towers that are coming down (a floor lands each step)
''')


def brunt(s):
    s = rep(s, '''	"breaches": 1, "breachBase": 0.8, "breachPerRatio": 0.6, "clearAt": 0.7, "breachDeath": 0.25, "breachWeakens": 0.5, "breachGrow": 0.5,
}''', '''	"breaches": 1, "breachBase": 0.8, "breachPerRatio": 0.6, "clearAt": 0.7, "breachDeath": 0.25, "breachWeakens": 0.5, "breachGrow": 0.5,
	# C: the failing state. failing 1 brings a tower down over seconds (0: in the tick, as before); failWarn seconds of warning (over any hold a
	# fighter in its reach is in by failWarnOver); failMin the least time the stack takes; failStep the most time a floor takes to land.
	"failing": 1, "failWarn": 1.5, "failWarnOver": 0.6, "failMin": 2.0, "failStep": 0.25,
	"failDamageFloor": 6.0, "failDamageCap": 100.0, "failBuryTicks": 45, "failReachZ": 4.0, "failBesideBh": 0.5, "failTipAt": 0.5, "failTipFar": 3.0, "failTipReach": 0.4, "failTipMaxBh": 6.0,
}''')
    s = rep(s, '''	"lodgeHold": [["world", "body", "auto"], "auto"],   # does a lodge hold the whole fight (world: a hit-stop), or only the body (body: pinned in the building while the fight goes on), or auto: the first with two bodies, the second with more
}''', '''	"lodgeHold": [["world", "body", "auto"], "auto"],   # does a lodge hold the whole fight (world: a hit-stop), or only the body (body: pinned in the building while the fight goes on), or auto: the first with two bodies, the second with more
	"failHurts": [["none", "both", "rival"], "none"],   # whom a falling stack hurts: nobody (today), both fighters, or the one who did not bring it down
}''')
    s = rep(s, '''	if isHouse(b):
		var r: float = dmg / b.maxhp
		return {"floors": false, "dmg": maxf(dmg, b.hp), "ratio": r, "outcome": "collapse", "pass": true, "keep": float(c.houseKeep), "deaths": b.popAlive}''', '''	if b.failK >= 0:   # a tower already coming down: he goes through it, and it takes nothing more
		return {"floors": false, "dmg": 0.0, "ratio": 99.0, "outcome": "collapse", "pass": true, "keep": float(c.houseKeep), "deaths": 0.0}
	if isHouse(b):
		var r: float = dmg / b.maxhp
		return {"floors": false, "dmg": maxf(dmg, b.hp), "ratio": r, "outcome": "collapse", "pass": true, "keep": float(c.houseKeep), "deaths": b.popAlive}''')
    s = rep(s, '''	var res := {"pancake": false, "collapse": false}
	var F: int = b.floors
	# the longest cleared run that contains a just-cleared floor and has standing floors above it''', '''	var res := {"pancake": false, "collapse": false}
	var F: int = b.floors
	if b.failK >= 0:
		return res   # already coming down
	# the longest cleared run that contains a just-cleared floor and has standing floors above it''')
    s = rep(s, '''	var popF: float = floorPop(b)
	var from_floor: int = run_lo
	var lost: int = m
	# clear the stack
	for j in range(run_hi + 1, F):
		b.fmask = b.fmask & ~(1 << j)
	var j2: int = run_lo - 1
	var stack: float = float(m)
	while j2 >= 0:
		if isStanding(b, j2):
			if PANCAKE_K * stack >= floorStr(b, j2):
				b.fmask = b.fmask & ~(1 << j2)
				stack += 1.0
				lost += 1
				from_floor = j2
			else:
				break
		j2 -= 1
	res.pancake = true''', '''	var popF: float = floorPop(b)
	var from_floor: int = run_lo
	var lost: int = m
	var failing: bool = int(cfg().failing) != 0
	# clear the stack (in the tick, or: it comes down over seconds from from_floor, below)
	if not failing:
		for j in range(run_hi + 1, F):
			b.fmask = b.fmask & ~(1 << j)
	var j2: int = run_lo - 1
	var stack: float = float(m)
	while j2 >= 0:
		if isStanding(b, j2):
			if PANCAKE_K * stack >= floorStr(b, j2):
				if not failing:
					b.fmask = b.fmask & ~(1 << j2)
				stack += 1.0
				lost += 1
				from_floor = j2
			else:
				break
		j2 -= 1
	res.pancake = true
	if failing:
		WorldStructures.startFail(S, b, from_floor, by, cx)
		return res''')
    return s


STRUCT_FAIL = open(__file__.replace('mk_c.py', 'struct_fail.gd.txt'), encoding='utf-8').read()


def struct(s):
    s = rep(s, '''	if b.floors >= WorldBrunt.FLOORS_MIN and b.fmask != (1 << b.floors) - 1:
		s = maxi(s, _cutStage)
	elif b.floors >= WorldBrunt.FLOORS_MIN and b.fhole.size() > 0 and _holed(b):''', '''	if b.floors >= WorldBrunt.FLOORS_MIN and (b.fmask != (1 << b.floors) - 1 or b.failK >= 0):
		s = maxi(s, _cutStage)
	elif b.floors >= WorldBrunt.FLOORS_MIN and b.fhole.size() > 0 and _holed(b):''')
    s = rep(s, '''	if b.floors >= WorldBrunt.FLOORS_MIN and b.fmask != (1 << b.floors) - 1:
		# a skyscraper with floors gone stands as tall as its top standing floor
		return float(WorldBrunt.topFloor(b) + 1) * WorldBrunt.floorH(b)''', '''	if b.floors >= WorldBrunt.FLOORS_MIN and (b.fmask != (1 << b.floors) - 1 or b.failK >= 0):
		# a skyscraper with floors gone stands as tall as its top standing floor
		return float(WorldBrunt.topFloor(b) + 1) * WorldBrunt.floorH(b)''')
    s = rep(s, '''	var gy: float = baseY(S, b)
	if b.hp <= 0.0:
		b.alive = false''', '''	var gy: float = baseY(S, b)
	if b.hp <= 0.0 and b.floors >= WorldBrunt.FLOORS_MIN and int(WorldBrunt.cfg().failing) != 0 and WorldBrunt.standingCount(b) > 0:
		# a tower that is spent comes down over seconds (a warning, then a floor a step): the failing state; the last floor to land takes it
		if b.failK < 0:
			startFail(S, b, 0, cause, cx)
		if not local:
			stageEmit(S, b, s0, cause, cx)
		return
	if b.hp <= 0.0:
		b.alive = false''')
    s = rep(s, '''	if not b.alive or d <= 0.0:
		return
	var before: float = b.hp''', '''	if not b.alive or d <= 0.0 or b.failK >= 0:
		return   # (a tower already coming down takes nothing more)
	var before: float = b.hp''')
    s = rep(s, '''## The index of the lowest building whose box the body overlaps right now, or -1.''', STRUCT_FAIL + '''## The index of the lowest building whose box the body overlaps right now, or -1.''')
    return s


def probe(s):
    s = rep(s, '''func fresh(seed: int = 1) -> SimState:''', '''## A tower that is spent comes down over seconds (the failing state): run it to the end.
func settleFail(S: SimState) -> void:
	for i in range(2400):
		var any: bool = false
		for b in S.buildings:
			if b.failK >= 0:
				any = true
				break
		if not any:
			return
		WorldStructures.stepFailing(S, SimConst.DT)


func fresh(seed: int = 1) -> SimState:''')
    s = rep(s, '''	WorldStructures.damageArea(Sr, tw.x + 4000.0, 0.0, 6000.0, 1.0e7, Sr.fighters[1])   # (the stage cap: the first blast leaves them standing, the second finishes them)
''', '''	WorldStructures.damageArea(Sr, tw.x + 4000.0, 0.0, 6000.0, 1.0e7, Sr.fighters[1])   # (the stage cap: the first blast leaves them standing, the second finishes them)
	settleFail(Sr)
''')
    s = rep(s, '''		WorldStructures.damageArea(Sh, tall3.x, 0.0, 600.0, 1.0e8, Sh.fighters[1])   # (the second blast of the stage cap)
''', '''		WorldStructures.damageArea(Sh, tall3.x, 0.0, 600.0, 1.0e8, Sh.fighters[1])   # (the second blast of the stage cap)
		settleFail(Sh)
''')
    s = rep(s, '''	WorldStructures.damageBuilding(Sr_t, f1_t, 1.0e9, Sr_t.fighters[1], "implode", f1_t.x, 0.0)
''', '''	WorldStructures.damageBuilding(Sr_t, f1_t, 1.0e9, Sr_t.fighters[1], "implode", f1_t.x, 0.0)
	settleFail(Sr_t)
''')
    return s


rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/core/hash.gd', hashf)
rw(R, 'sim/core/fx.gd', fx)
rw(R, 'sim/core/sim.gd', simf)
rw(R, 'sim/world/brunt.gd', brunt)
rw(R, 'sim/world/structures.gd', struct)
rw(R, 'sim/world/tools/probe.gd', probe)
data_keys(R, {"failing": 1, "failWarn": 1.5, "failWarnOver": 0.6, "failMin": 2.0, "failStep": 0.25, "failHurts": "none", "failDamageFloor": 6.0, "failDamageCap": 100.0,
              "failBuryTicks": 45, "failReachZ": 4.0, "failBesideBh": 0.5, "failTipAt": 0.5, "failTipFar": 3.0, "failTipReach": 0.4, "failTipMaxBh": 6.0},
          "failing: a tower that is spent or pancaked comes down over seconds (failWarn of warning, failWarnOver more over any hold a fighter under it is in; the stack takes at least failMin and a floor lands at most each failStep); failHurts: whom the falling stack hurts (none, both, or rival: the one who did not bring it down; Orb's homework); failDamageFloor a floor on a fighter under it, failDamageCap the most from one building, failBuryTicks the stagger; failReachZ the depth and failBesideBh the width beside the footprint it reaches; failTipAt the share of the half width a hit must be off the middle to tip it toward the breach, failTipFar how far (in half widths) a blow from outside still pushes it over, failTipReach the share of the height thrown to the side, failTipMaxBh at most.",
          {
              "failing": {"type": "integer", "minimum": 0, "maximum": 1, "description": "1: a tower that is spent or pancaked comes down over seconds; 0: in the tick, as before."},
              "failWarn": {"type": "number", "minimum": 0, "maximum": 10, "description": "Seconds of warning before the first floor lands (Game Design: at least 1.5)."},
              "failWarnOver": {"type": "number", "minimum": 0, "maximum": 5, "description": "The warning is at least this long over any hold a fighter under the tower is in."},
              "failMin": {"type": "number", "minimum": 0, "maximum": 20, "description": "The least seconds the stack takes to come down (Game Design: at least 2)."},
              "failStep": {"type": "number", "exclusiveMinimum": 0, "maximum": 5, "description": "The most seconds a floor takes to land."},
              "failHurts": {"enum": ["none", "both", "rival"], "description": "Whom the falling stack hurts: nobody (today), both fighters, or the one who did not bring it down."},
              "failDamageFloor": {"type": "number", "minimum": 0, "description": "The damage a landing floor does a fighter under it."},
              "failDamageCap": {"type": "number", "minimum": 0, "description": "The most one building's stack does one fighter."},
              "failBuryTicks": {"type": "integer", "minimum": 0, "maximum": 300, "description": "The ticks a fighter is buried under a landing floor."},
              "failReachZ": {"type": "number", "minimum": 0, "maximum": 20, "description": "How far beside the footprint in depth, in fighter heights, the stack reaches."},
              "failBesideBh": {"type": "number", "minimum": 0, "maximum": 10, "description": "How far beside the footprint, in fighter heights, a falling stack reaches."},
              "failTipAt": {"type": "number", "minimum": 0, "maximum": 1, "description": "A blow this share of the half width off the middle tips the building that way."},
              "failTipFar": {"type": "number", "minimum": 1, "maximum": 20, "description": "A blow from beside the footprint within this many half widths of the middle pushes it over, away from the blow; a farther one leaves it to fall in place."},
              "failTipReach": {"type": "number", "minimum": 0, "maximum": 2, "description": "The share of its height a tipping stack is thrown to its side."},
              "failTipMaxBh": {"type": "number", "minimum": 0, "maximum": 40, "description": "... at most this many fighter heights."},
          })
print('stage C applied')
