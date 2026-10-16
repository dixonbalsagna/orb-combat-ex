"""N bodies, World's side (scratch; main's HEAD).  python mk_nbody.py <root>
1. the set-piece token per flight: more than one set piece open at once keep their own collateral allowance (World.evtMore beside the scalar slot)
2. the launcher of a flight: launchBy, else the nearest foe (by team when a body has one): WorldCollateral.launcherOf and foes, in place of SimRoster.opp
3. the lodge hold per body when more than two bodies are in the match (lodgeHold "auto": a hit-stop with two, a per-body pin with more): Fighter.holdT
Lines in Simulation's files: state.gd (World.evtMore, Fighter.holdT), hash.gd (both, written only when set, so a 1v1 hash is byte-identical)."""
import sys, json
R = sys.argv[1].rstrip('/') + '/'


def rw(p, fn):
    s = open(R + p, encoding='utf-8', newline='').read()
    cr = '\r\n' in s
    s = fn(s.replace('\r\n', '\n'))
    open(R + p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if cr else s)


def rep(s, a, b):
    assert s.count(a) == 1, (a[:100], s.count(a))
    return s.replace(a, b)


def state(s):
    s = rep(s, '''	var evtEvac: float = 0.0          # civilians it has made flee
''', '''	var evtEvac: float = 0.0          # civilians it has made flee
	var evtMore := PackedFloat32Array()   # more set pieces open at once, five numbers each (token, kind, left, dead, evac): two flights, two allowances; empty with one
''')
    s = rep(s, '''	var launchSpecial: bool = false  # the current launch is a signature, finisher or break launch (its ground mark may be big)
''', '''	var launchSpecial: bool = false  # the current launch is a signature, finisher or break launch (its ground mark may be big)
	var holdT: int = 0               # World's per-body lodge hold: ticks he is pinned in a building (the rest of the fight goes on); 0 when free
''')
    return s


def hashf(s):
    s = rep(s, '''"evtDead", "evtEvac", "tokenSeq", "heavyX", "heavyT", "stateT"])
''', '''"evtDead", "evtEvac", "tokenSeq", "heavyX", "heavyT", "stateT"])
	if S.world.evtMore.size() > 0:   # more than one set piece open: written only then, so a match with one hashes as before
		out.append(float(S.world.evtMore.size()))
		for v in S.world.evtMore:
			out.append(v)
''')
    s = rep(s, '''		out.append(float(f.flightHits))
''', '''		out.append(float(f.flightHits))
		if f.holdT != 0:   # World's per-body lodge hold: written only while held, so a match without one hashes as before
			out.append(float(f.holdT))
''')
    return s


COLL_KILL_OLD = '''	var rm: float = maxf(0.0, budget(S) - w.cbSum)
	var borrow: float = w.evtLeft if (evt != 0.0 and evt == w.evtToken) else 0.0
	var cl: float = ceilingLeft(S)
	var granted: float = minf(want, minf(rm + borrow, cl))
	if granted > rm:
		w.evtLeft -= granted - rm
'''
COLL_KILL_NEW = '''	var rm: float = maxf(0.0, budget(S) - w.cbSum)
	var slot: int = _slotOf(w, evt)   # the set piece this blow belongs to: its own allowance (-1 the first open, an index into evtMore, -2 none)
	var borrow: float = 0.0
	if slot == -1:
		borrow = w.evtLeft
	elif slot >= 0:
		borrow = w.evtMore[slot + 2]
	var cl: float = ceilingLeft(S)
	var granted: float = minf(want, minf(rm + borrow, cl))
	if granted > rm:
		if slot == -1:
			w.evtLeft -= granted - rm
		elif slot >= 0:
			w.evtMore[slot + 2] -= granted - rm
'''


def coll(s):
    s = rep(s, '''	w.evtDead = 0.0
	w.evtEvac = 0.0
	w.tokenSeq = 0.0
''', '''	w.evtDead = 0.0
	w.evtEvac = 0.0
	w.evtMore = PackedFloat32Array()
	w.tokenSeq = 0.0
''')
    s = rep(s, '''## Open a set piece: returns its token, which the source passes to kill() (through damageArea and damageBuilding) so the
## allowance belongs to this event's own source. At tier 1 and 2 there is no allowance.
static func beginEvent(S: SimState, kind: String, cause) -> float:
	var w: SimState.World = S.world
	w.tokenSeq += 1.0
	w.evtToken = w.tokenSeq
	w.evtKind = kind
	var t: int = tier(S)
	w.evtLeft = EVENT_ALLOW[kind][t - 1] * w.pop0 if EVENT_ALLOW.has(kind) else 0.0
	w.evtDead = 0.0
	w.evtEvac = 0.0
	return w.evtToken
''', '''const EVENT_KINDS: Array = ["slide", "chain", "landslide", "quake"]


## Where a token's set piece is kept: -1 the first open one (World.evtToken and its scalars), an offset into World.evtMore (five numbers: token, kind,
## left, dead, evac) for each further one open at the same time, -2 for a token that is not open.
static func _slotOf(w: SimState.World, token: float) -> int:
	if token == 0.0:
		return -2
	if token == w.evtToken:
		return -1
	for i in range(0, w.evtMore.size(), 5):
		if w.evtMore[i] == token:
			return i
	return -2


## A token no body holds any more (a chain or a slide whose flight ended without closing it: the old single slot was simply overwritten by the next
## one) is closed, so only set pieces that are really running stay open.
static func _held(S: SimState, token: float) -> bool:
	for f in S.fighters:
		if f.chainEvt == token or f.slideEvt == token:
			return true
	return false


static func _dropStale(S: SimState) -> void:
	var w: SimState.World = S.world
	if w.evtToken != 0.0 and not _held(S, w.evtToken):
		w.evtKind = ""
		w.evtLeft = 0.0
		w.evtToken = 0.0
		w.evtDead = 0.0
		w.evtEvac = 0.0
	if w.evtMore.size() > 0:
		var keep := PackedFloat32Array()
		for i in range(0, w.evtMore.size(), 5):
			if _held(S, w.evtMore[i]):
				keep.append_array(w.evtMore.slice(i, i + 5))
		w.evtMore = keep
	if w.evtToken == 0.0 and w.evtMore.size() >= 5:   # the first slot is free: the oldest of the rest moves into it
		w.evtToken = w.evtMore[0]
		w.evtKind = EVENT_KINDS[int(w.evtMore[1])] if int(w.evtMore[1]) >= 0 else ""
		w.evtLeft = w.evtMore[2]
		w.evtDead = w.evtMore[3]
		w.evtEvac = w.evtMore[4]
		w.evtMore = w.evtMore.slice(5)


## Open a set piece: returns its token, which the source passes to kill() (through damageArea and damageBuilding) so the
## allowance belongs to this event's own source. At tier 1 and 2 there is no allowance. Two set pieces open at once (two bodies launched into
## buildings in the same second, a slide and a chain) each keep their own: the first in the scalar slot, the rest in World.evtMore.
static func beginEvent(S: SimState, kind: String, cause) -> float:
	var w: SimState.World = S.world
	_dropStale(S)
	w.tokenSeq += 1.0
	var t: int = tier(S)
	var left: float = EVENT_ALLOW[kind][t - 1] * w.pop0 if EVENT_ALLOW.has(kind) else 0.0
	if w.evtToken == 0.0:
		w.evtToken = w.tokenSeq
		w.evtKind = kind
		w.evtLeft = left
		w.evtDead = 0.0
		w.evtEvac = 0.0
	else:
		w.evtMore.append_array(PackedFloat32Array([w.tokenSeq, float(EVENT_KINDS.find(kind)), left, 0.0, 0.0]))
	return w.tokenSeq


## Whether b is an enemy of a: by team when both bodies have one, else by Simulation's stage 1 shape (SimRoster.opp: slot 0 is the opponent of every
## other body, and the others are his), so a guard is no foe of the principal he stands for. With two bodies: the other one.
static func foes(S: SimState, a, b) -> bool:
	if a == b:
		return false
	var ta = a.get("team")
	var tb = b.get("team")
	if ta == null or tb == null:
		var ia: int = S.fighters.find(a)
		var ib: int = S.fighters.find(b)
		if ia < 0 or ib < 0:
			return true
		return (ia == 0) != (ib == 0)
	return ta != tb


## Who launched f: launchBy, else the nearest body of an enemy team (the other one, with two bodies), else null. In place of SimRoster.opp's "the other of two".
static func launcherOf(S: SimState, f):
	if f.launchBy != null:
		return f.launchBy
	var best = null
	var bd: float = 1.0e30
	for o in S.fighters:
		if o == f or not foes(S, f, o):
			continue
		var d: float = absf(SimWrap.sdx(f.x, o.x))
		if d < bd:
			bd = d
			best = o
	return best
''')
    s = rep(s, '''	if token != 0.0 and token == w.evtToken:
		r.dead = w.evtDead
		r.evac = w.evtEvac
		w.evtKind = ""
		w.evtLeft = 0.0
		w.evtToken = 0.0
		w.evtDead = 0.0
		w.evtEvac = 0.0
	return r
''', '''	var slot: int = _slotOf(w, token)
	if slot == -1:
		r.dead = w.evtDead
		r.evac = w.evtEvac
		w.evtKind = ""
		w.evtLeft = 0.0
		w.evtToken = 0.0
		w.evtDead = 0.0
		w.evtEvac = 0.0
	elif slot >= 0:
		r.dead = w.evtMore[slot + 3]
		r.evac = w.evtMore[slot + 4]
		var rest := PackedFloat32Array()
		for i in range(0, w.evtMore.size(), 5):
			if i != slot:
				rest.append_array(w.evtMore.slice(i, i + 5))
		w.evtMore = rest
	return r
''')
    s = rep(s, COLL_KILL_OLD, COLL_KILL_NEW)
    s = rep(s, '''	if evt != 0.0 and evt == w.evtToken:
		w.evtDead += granted
		w.evtEvac += evac
''', '''	if slot == -1:
		w.evtDead += granted
		w.evtEvac += evac
	elif slot >= 0:
		w.evtMore[slot + 3] += granted
		w.evtMore[slot + 4] += evac
''')
    return s


def brunt(s):
    s = rep(s, '	var by = f.launchBy if f.launchBy != null else SimRoster.opp(S, f)\n', '	var by = WorldCollateral.launcherOf(S, f)\n')
    s = rep(s, '''	"lodgeHold": [["world", "body"], "world"],   # does a lodge hold the whole fight (a hit-stop) or only the body (he is stunned, the fight goes on)''',
            '''	"lodgeHold": [["world", "body", "auto"], "auto"],   # does a lodge hold the whole fight (world: a hit-stop), or only the body (body: pinned in the building while the fight goes on), or auto: the first with two bodies, the second with more''')
    # the hold: a wall (a hit that does not go through) is still stunned for the seconds in body mode; a lodge pins the body
    s = rep(s, '''static func _hold(S: SimState, f, seconds: float) -> void:
	if str(cfg().lodgeHold) == "body":
		f.stunTicks = maxi(f.stunTicks, int(ceil(seconds * 60.0)))
	else:
		S.dirS.stop = SimMathx.jmax(S.dirS.stop, seconds)
''', '''static func _hold(S: SimState, f, seconds: float, lodged: bool = false) -> void:
	var mode: String = str(cfg().lodgeHold)
	if mode == "auto":
		mode = "body" if S.fighters.size() > 2 else "world"
	if mode == "body":
		var ticks: int = int(ceil(seconds * 60.0))
		if lodged:
			f.holdT = maxi(f.holdT, ticks)   # pinned in the building (WorldContact.stepFighter), the rest of the fight goes on
		else:
			f.stunTicks = maxi(f.stunTicks, ticks)   # a wall: staggered for the seconds, he comes off the face as ever
	else:
		S.dirS.stop = SimMathx.jmax(S.dirS.stop, seconds)
''')
    s = rep(s, '''		_hold(S, f, holdS)
''', '''		_hold(S, f, holdS, true)
''')
    return s


def contact(s):
    s = s.replace('	var by = f.launchBy if f.launchBy != null else SimRoster.opp(S, f)\n', '	var by = WorldCollateral.launcherOf(S, f)\n')
    assert 'SimRoster.opp' not in s
    s = rep(s, '''static func stepFighter(S: SimState, f, dt: float) -> void:
	var by = WorldCollateral.launcherOf(S, f)
''', '''static func stepFighter(S: SimState, f, dt: float) -> void:
	if f.holdT > 0:   # a body lodged in a building (World's per-body lodge hold): pinned, and the fight goes on around him
		f.holdT -= 1
		f.vx = 0.0
		f.vy = 0.0
		return
	var by = WorldCollateral.launcherOf(S, f)
''')
    return s


def slide(s):
    s = rep(s, '	var by = f.launchBy if f.launchBy != null else SimRoster.opp(S, f)\n', '	var by = WorldCollateral.launcherOf(S, f)\n')
    return s


rw('sim/core/state.gd', state)
rw('sim/core/hash.gd', hashf)
rw('sim/world/collateral.gd', coll)
rw('sim/world/brunt.gd', brunt)
rw('sim/world/contact.gd', contact)
rw('sim/world/slide.gd', slide)

# the data default and the schema's enum
p = R + 'data/biomes/brunt.json'
d = json.load(open(p, encoding='utf-8'))
d['lodgeHold'] = 'auto'
d['_about'] = d['_about'].replace('lodgeHold: does a lodge or a wall hold the whole sim (world, a hit-stop) or only the body (body: he is stunned and the fight goes on): Orb\'s homework.',
                                  'lodgeHold: does a lodge hold the whole sim (world, a hit-stop) or only the body (body: he is pinned in the building and the fight goes on); auto: world with two bodies, body with more (Orb\'s homework: which, with two).')
open(p, 'w', encoding='utf-8', newline='').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
p = R + 'tools/schemas/biomes-brunt.schema.json'
j = json.load(open(p, encoding='utf-8'))
j['properties']['lodgeHold'] = {"enum": ["world", "body", "auto"], "description": "Does a lodge hold the whole sim (world: a hit-stop) or only the body (body: pinned in the building while the fight goes on; a wall only staggers him); auto: world with two bodies, body with more."}
open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2, ensure_ascii=False) + '\n')
print('n-body stage applied')
