"""Stage W: the wall slam, the lodge event, building_hit.outcome "wall", the lodgeHold switch.  python mk_w.py <root>
Lines in other directors' files: state.gd (FxEvent.hold), hash.gd (FX_FIELDS lodge), fx.gd (SimFx.lodge)."""
from mk_wbc_lib import *
R = root()


def state(s):
    return rep(s, '''	var eta: float = 0.0         # hazard_telegraph, danger: seconds until it lands, 0 when unknown
''', '''	var eta: float = 0.0         # hazard_telegraph, danger: seconds until it lands, 0 when unknown
	var hold: float = 0.0        # lodge: the seconds the body is held in the building
''')


def fx(s):
    return rep(s, '''## B2: after a burst through building b the fighter heads for nb''', '''## The lodge: a body ends inside the last building of a chain, held hold seconds (World, docs/world/destruction-hook.md). b the building, actor the
## fighter's slot, n the chain's link, x y z where he is.
static func lodge(S: SimState, f, b, x: float, y: float, hold: float, link: int, by) -> void:
	var e := _ev(S, "lodge")
	e.actor = float(S.fighters.find(f)); e.b = float(b.idx); e.x = x; e.y = y; e.z = WorldBrunt.faceZ(b); e.hold = hold; e.n = link
	e.owner = float(S.fighters.find(by)); e.victim = e.actor


## B2: after a burst through building b the fighter heads for nb''')


def hashf(s):
    return fx_fields_add(s, newtypes='"lodge": ["actor", "b", "x", "y", "z", "hold", "n", "owner", "victim"],')


def brunt(s):
    s = rep(s, '''	"keepHi": 0.8, "keepK": 0.45, "keepRef": 3000.0, "keepMin": 0.35, "keepFree": 0.95, "heavyKeep": 0.7,
}''', '''	"keepHi": 0.8, "keepK": 0.45, "keepRef": 3000.0, "keepMin": 0.35, "keepFree": 0.95, "heavyKeep": 0.7,
	# the wall slam (buildings.md section 2): twice the building's hit, a stagger at the wall
	"wallSlamMul": 2.0, "wallStaggerTicks": 24,
}
const BRUNT_STRINGS: Dictionary = {   # the switches that are words: their values and the default (today's behaviour)
	"lodgeHold": [["world", "body"], "world"],   # does a lodge hold the whole fight (a hit-stop) or only the body (he is stunned, the fight goes on)
}''')
    s = rep(s, '''	_c = BRUNT_KEYS.duplicate(true)
''', '''	_c = BRUNT_KEYS.duplicate(true)
	for k in BRUNT_STRINGS:
		_c[k] = BRUNT_STRINGS[k][1]
''')
    s = rep(s, '''		_c[k] = v
	var h := SimHash.Hasher.new()
	h.text("biomes.brunt")''', '''		_c[k] = v
	for k in BRUNT_STRINGS:
		if j.has(k):
			if BRUNT_STRINGS[k][0].has(str(j[k])):
				_c[k] = str(j[k])
			else:
				_cErrors.append("brunt.json: %s is one of %s" % [k, str(BRUNT_STRINGS[k][0])])
	var h := SimHash.Hasher.new()
	h.text("biomes.brunt")''')
    s = rep(s, '''	var lodge: bool = passes and nx.b < 0
	var oce: Dictionary = oc
	if lodge:
		oce = oc.duplicate()
		oce.keep = 0.0   # (a building_hit that passes with keep 0 is a lodge: the body ends inside the building)
	SimFx.buildingHitB2(S, f, b, y, link, by, oce, hitText, spN)''', '''	var lodge: bool = passes and nx.b < 0
	var oce: Dictionary = oc
	if lodge:
		oce = oc.duplicate()
		oce.keep = 0.0   # (a building_hit that passes with keep 0 is a lodge: the body ends inside the building)
	if not passes:
		hitText = "wall"   # a building that holds him: a wall (the floor_hit says crack or dent)
	SimFx.buildingHitB2(S, f, b, y, link, by, oce, hitText, spN)''')
    s = rep(s, '''		SimDamage.hurt(S, f, spLeft * FIGHTER_DMG, by)
		S.dirS.stop = SimMathx.jmax(S.dirS.stop, lodgeSeconds(by.tier, f.launchSpecial))
		var bodyW: float = WorldLanes.body()[0]
		f.x = SimWrap.wrap(far - dir * (bodyW * 2.0))
		f.y = y
		f.vx = 0.0
		f.vy = 0.0
		endFlight(S, f)
		return
	if not passes:
		S.dirS.stop = SimMathx.jmax(S.dirS.stop, lodgeSeconds(by.tier, f.launchSpecial))   # held at the wall for the lodge's seconds, then he comes off it
''', '''		SimDamage.hurt(S, f, spLeft * FIGHTER_DMG, by)
		var holdS: float = lodgeSeconds(by.tier, f.launchSpecial)
		_hold(S, f, holdS)
		var bodyW: float = WorldLanes.body()[0]
		f.x = SimWrap.wrap(far - dir * (bodyW * 2.0))
		f.y = y
		f.vx = 0.0
		f.vy = 0.0
		SimFx.lodge(S, f, b, f.x, f.y, holdS, link, by)
		endFlight(S, f)
		return
	if not passes:
		_hold(S, f, lodgeSeconds(by.tier, f.launchSpecial))   # held at the wall for the lodge's seconds, then he comes off it
		# the wall slam (buildings.md section 2): he takes the building's hit again over (wallSlamMul, Game Design's twice), and is staggered at the wall
		var slam: float = float(cm.wallSlamMul) - 1.0
		if slam > 0.0:
			SimDamage.hurt(S, f, spN * FIGHTER_DMG * slam, by)
		f.stunTicks = maxi(f.stunTicks, int(cm.wallStaggerTicks))
''')
    s = rep(s, '''## Splash: buildings beside b (within SPLASH_W of its width in x and SPLASH_Z in depth)''', '''## The hold in a wall or a lodge: the whole sim stops for it (a hit-stop, today's behaviour) or only the body is held (lodgeHold "body": he is stunned for
## the seconds, the fight goes on around him). Orb's homework: which of the two.
static func _hold(S: SimState, f, seconds: float) -> void:
	if str(cfg().lodgeHold) == "body":
		f.stunTicks = maxi(f.stunTicks, int(ceil(seconds * 60.0)))
	else:
		S.dirS.stop = SimMathx.jmax(S.dirS.stop, seconds)


## Splash: buildings beside b (within SPLASH_W of its width in x and SPLASH_Z in depth)''')
    return s


rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/core/fx.gd', fx)
rw(R, 'sim/core/hash.gd', hashf)
rw(R, 'sim/world/brunt.gd', brunt)
data_keys(R, {"wallSlamMul": 2.0, "wallStaggerTicks": 24, "lodgeHold": "world"},
          "The wall slam: a body held at a wall takes wallSlamMul times the hit (Game Design: twice) and is staggered wallStaggerTicks. lodgeHold: does a lodge or a wall hold the whole sim (world, a hit-stop) or only the body (body: he is stunned and the fight goes on): Orb's homework.",
          {
              "wallSlamMul": {"type": "number", "minimum": 1, "maximum": 6, "description": "A body held at a wall takes this many times the building's hit (Game Design: twice)."},
              "wallStaggerTicks": {"type": "integer", "minimum": 0, "maximum": 240, "description": "The ticks a body held at a wall is staggered (input gated)."},
              "lodgeHold": {"enum": ["world", "body"], "description": "Does a lodge or a wall hold the whole sim (world: a hit-stop) or only the body (body: he is stunned for the seconds and the fight goes on)."},
          })
print('stage W applied')
