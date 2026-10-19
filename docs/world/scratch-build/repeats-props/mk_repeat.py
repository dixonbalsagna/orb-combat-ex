"""Game Design's rulings of 2026-10-18 (World, scratch, parked, on main with the interior chain applied):
 1. a held slab bounces at 900 or more between 40 and 70 degrees, any tier, else lodges (interior.gd, new version copied in)
 2. the next tower's link plays when he leaves by the far face with 900 or more (interior.gd)
 3. repeats escalate: a send into a building already marked meets it one tier higher per mark, up to two (WorldBrunt.tierAt, Building.marks); a send into ground already
    cratered deepens and widens that crater (WorldCrater._repeat); both behind brunt.json repeatMarks (0 off, else the most marks / repeats)
 4. the planner: a tower the chain inside takes ends the plan there (WorldBrunt.chainPlan), and every link's tier carries its building's marks
python mk_repeat.py <root> <interior.gd>"""
import sys, shutil
from mk_wbc_lib import rw, rep, data_keys

R = sys.argv[1].rstrip('/') + '/'
src = sys.argv[2]

KEYS = {"interiorBounceSpeed": 900.0, "interiorBounceTanMin": 0.8391, "interiorBounceTanMax": 2.7475, "interiorBounceKeep": 0.45, "interiorBounceTangent": 0.8,
        "interiorLinkSpeed": 900.0, "repeatMarks": 0, "repeatCraterGrow": 1.25}


def brunt(s):
    s = rep(s, '''	"interiorExitTier": 3, "interiorHurt": 0.5,
}''', '''	"interiorExitTier": 3, "interiorHurt": 0.5,
	# a held slab bounces at interiorBounceSpeed or more between the two tangents (40 and 70 degrees), keeping interiorBounceKeep of the normal speed and interiorBounceTangent
	# of the along-slab speed; he leaves a tower by the far face into the next link with interiorLinkSpeed or more (buildings.md section 7.3, ruled 2026-10-18)
	"interiorBounceSpeed": 900.0, "interiorBounceTanMin": 0.8391, "interiorBounceTanMax": 2.7475, "interiorBounceKeep": 0.45, "interiorBounceTangent": 0.8, "interiorLinkSpeed": 900.0,
	# repeats escalate (Orb, homework 30): repeatMarks 0 off, else the most marks a building counts and the most repeats a crater grows; repeatCraterGrow the radius factor a repeat asks
	"repeatMarks": 0, "repeatCraterGrow": 1.25,
}''')
    s = rep(s, '''## Resolve one hit on building b at height y on the near edge, and what happens to the fighter.
static func hit(''', '''## The tier a send meets building b at: tier (the launch's), one higher for each mark on b (a building an earlier send struck), at most repeatMarks (Orb's repeats escalate,
## buildings.md section 6.1). repeatMarks 0 is today's behaviour.
static func tierAt(S: SimState, b, tier: float) -> float:
	var m: int = int(cfg().repeatMarks)
	if m <= 0 or b.marks <= 0:
		return tier
	return tier + float(mini(b.marks, m))


## Resolve one hit on building b at height y on the near edge, and what happens to the fighter.
static func hit(''')
    s = rep(s, '''	var oc: Dictionary = outcomeOf(S, b, y, spN, tierOf(by, f), _count(f, MARK_TOWER), f.launchSpecial)
	f.flightHits += 1''', '''	var tierB: float = tierAt(S, b, tierOf(by, f))   # one higher for each mark on this building (repeats escalate)
	var oc: Dictionary = outcomeOf(S, b, y, spN, tierB, _count(f, MARK_TOWER), f.launchSpecial)
	if int(cfg().repeatMarks) > 0:
		b.marks += 1   # a send has struck it: the next meets it one tier higher
	f.flightHits += 1''')
    s = rep(s, '''		var tfac: float = float(cm.tierFactor[tierIx(tierOf(by, f), f.launchSpecial)])''', '''		var tfac: float = float(cm.tierFactor[tierIx(tierB, f.launchSpecial)])''')
    s = rep(s, '''		var holdS: float = lodgeSeconds(tierOf(by, f), f.launchSpecial)''', '''		var holdS: float = lodgeSeconds(tierB, f.launchSpecial)''')
    s = rep(s, '''		_hold(S, f, lodgeSeconds(tierOf(by, f), f.launchSpecial))   # held at the wall''', '''		_hold(S, f, lodgeSeconds(tierB, f.launchSpecial))   # held at the wall''')
    s = rep(s, '''WorldInterior.begin(S, f, b, y, edge, dir, by, keep, broke)''', '''WorldInterior.begin(S, f, b, y, edge, dir, by, tierB, keep, broke)''')
    s = rep(s, '''		var oc: Dictionary = outcomeOf(S, cur, r.y, r.spN, tier, punched, special)
''', '''		var oc: Dictionary = outcomeOf(S, cur, r.y, r.spN, tierAt(S, cur, tier), punched, special)
''')
    s = rep(s, '''		out.append(entry)
		if not oc.pass:
			break''', '''		out.append(entry)
		if out.size() == 1 and WorldInterior.fits(S, cur, r.vx / trav, r.vy):
			entry.lodge = true   # the chain inside a tower (interior.gd) takes him: the plan ends here (it plans its own exit)
			break
		if not oc.pass:
			break''')
    return s


def state(s):
    return rep(s, '''	var plan: int = -1        # its index in that place's plan''', '''	var marks: int = 0        # World: sends that have struck it (repeats escalate: each mark is one tier higher for the next send, at most two); counted only with brunt.json repeatMarks above 0; hashed when not 0
	var plan: int = -1        # its index in that place's plan''')


def hashf(s):
    return rep(s, '''		for v in b.fdmg:
			out.append(v)
''', '''		for v in b.fdmg:
			out.append(v)
		if b.marks != 0:
			out.append(float(b.marks))   # World: repeats escalate (only with brunt.json repeatMarks above 0)
''')


def crater(s):
    s = rep(s, '''static func dig(S: SimState, x: float, energy: float, cause, kind: String, dirx: float = 0.0, vert: float = 1.0, special: bool = false, z: float = NAN):
	if not S.depthOn:''', '''static func dig(S: SimState, x: float, energy: float, cause, kind: String, dirx: float = 0.0, vert: float = 1.0, special: bool = false, z: float = NAN):
	if kind == "impact" and int(WorldBrunt.cfg().repeatMarks) > 0:
		var rp: Array = _repeat(S, x, energy, special)
		x = rp[0]
		energy = rp[1]
	if not S.depthOn:''')
    s = rep(s, '''static func _slot(S: SimState, cause) -> float:''', '''## Repeats escalate (Orb, homework 30; buildings.md section 6.1): an impact on ground already cratered by an impact deepens and widens that crater instead of digging a
## new one beside it. The dig moves to the old crater's centre and its energy rises so the bowl is repeatCraterGrow times the last one's radius (the depth cap, a share of the
## radius less the relief already there, then lets it go deeper). After repeatMarks repeats it grows no more. Returns [x, energy]. Behind brunt.json repeatMarks.
static func _repeat(S: SimState, x: float, energy: float, special: bool) -> Array:
	var last = null
	for i in range(S.craters.size() - 1, -1, -1):
		var c = S.craters[i]
		if c.cause == "impact" and absf(SimWrap.sdx(c.x, x)) <= 0.5 * c.r:
			last = c
			break
	if last == null:
		return [x, energy]
	var m: int = 0
	for c in S.craters:
		if c.cause == "impact" and absf(SimWrap.sdx(c.x, last.x)) < 1.0:
			m += 1
	var cf: Dictionary = WorldBrunt.cfg()
	var grow: float = float(cf.repeatCraterGrow) if m <= int(cf.repeatMarks) else 1.0
	var need: float = last.r * grow / R_BASE
	need = need * need / (SPECIAL_E_MULT if special else 1.0)
	return [last.x, maxf(energy, need)]


static func _slot(S: SimState, cause) -> float:''')
    return s


shutil.copyfile(src, R + 'sim/world/interior.gd')
rw(R, 'sim/world/brunt.gd', brunt)
rw(R, 'sim/world/crater.gd', crater)
rw(R, 'sim/core/state.gd', state)
rw(R, 'sim/core/hash.gd', hashf)
data_keys(R, KEYS,
          "A held slab bounces at interiorBounceSpeed or more between interiorBounceTanMin and interiorBounceTanMax (40 and 70 degrees), keeping interiorBounceKeep of the normal speed and interiorBounceTangent of the along-slab speed; he leaves a tower by the far face into the next link with interiorLinkSpeed or more (buildings.md section 7.3). Repeats escalate (Orb, homework 30): repeatMarks 0 off, else the most marks a building counts (each one tier higher for the next send) and the most repeats a crater grows; repeatCraterGrow the radius factor a repeat asks.",
          {
              "interiorBounceSpeed": {"type": "number", "minimum": 0, "maximum": 100000, "description": "The speed at which a held slab bounces him instead of lodging (Game Design: 900)."},
              "interiorBounceTanMin": {"type": "number", "exclusiveMinimum": 0, "maximum": 10, "description": "The shallowest angle to the slab that bounces: the tangent of 40 degrees."},
              "interiorBounceTanMax": {"type": "number", "exclusiveMinimum": 0, "maximum": 10, "description": "The steepest angle to the slab that bounces: the tangent of 70 degrees."},
              "interiorBounceKeep": {"type": "number", "minimum": 0, "maximum": 1, "description": "The share of the normal speed a bounce keeps (the ground's first vertKeep)."},
              "interiorBounceTangent": {"type": "number", "minimum": 0, "maximum": 1, "description": "The share of the along-slab speed a bounce keeps (the ground's tangentKeep)."},
              "interiorLinkSpeed": {"type": "number", "minimum": 0, "maximum": 100000, "description": "The speed he must leave a tower's far face with for the next tower's link to play (Game Design: 900)."},
              "repeatMarks": {"type": "integer", "minimum": 0, "maximum": 4, "description": "Repeats escalate (Orb, homework 30): 0 off, else the most marks a building counts, each one tier higher for the next send, and the most repeats a crater grows (Game Design: 2)."},
              "repeatCraterGrow": {"type": "number", "minimum": 1, "maximum": 3, "description": "The radius factor an impact on already cratered ground asks of the old crater."},
          })
print('repeats applied')
