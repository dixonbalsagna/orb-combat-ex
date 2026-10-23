"""The first stage's ring turns toward land when it is under Close's minimum (Game Design rulings-2026-10-23 section 6).   python mk_first.py <root>
firstRing keeps its signature and its answer when the ring round the home meets the minimum; otherwise it tries rings THROUGH the home (the home stays on the ring) at `first.bearings`
evenly spaced bearings and takes the one with the most land that meets the minimum; if none does, the story's ring stands. A stepped form (beginFirstRing, FirstJob.step) for the run host."""
import sys, json, collections
from mk_wbc_lib import rw, rep
OD = collections.OrderedDict
R = sys.argv[1].rstrip('/') + '/'


def rings_json(p):
    d = json.load(open(p, encoding='utf-8'), object_pairs_hook=OD)
    out = OD()
    for k, v in d.items():
        out[k] = v
        if k == 'coastRef':
            out['first'] = OD([("bearings", 12)])
    out['_about'] = out['_about'] + " first: the first stage's ring (a Close ring round the player's home) turns toward land when it is under Close's minimum (Game Design rulings-2026-10-23 section 6): bearings is how many evenly spaced bearings of a ring through the home are tried."
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(out, indent=2) + '\n')


def rings_schema(p):
    j = json.load(open(p, encoding='utf-8'), object_pairs_hook=OD)
    j['required'].append('first')
    props = OD()
    for k, v in j['properties'].items():
        props[k] = v
        if k == 'coastRef':
            props['first'] = OD([("type", "object"), ("required", ["bearings"]), ("additionalProperties", False), ("properties", OD([
                ("bearings", OD([("type", "integer"), ("minimum", 1), ("maximum", 72), ("description", "How many evenly spaced bearings of a ring through the home the first stage tries when its ring round the home is under Close's minimum.")]))]))])
    j['properties'] = props
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2) + '\n')


def ringpick(s):
    s = rep(s, '''	for k in ["stride", "biomeShare",''', '''	if not (j.get("first") is Dictionary and int(j.first.get("bearings", 0)) >= 1):
		_cErrors.append("rings.json: first has bearings")
	for k in ["stride", "biomeShare",''')
    a = s.index('## The first fight of a run: a Close ring round the player')
    b = s.index('## The boss\'s ring:')
    new = '''## The first fight of a run: a Close ring round the player's own home (Game Design 2c), the touch-down on a seeded bearing. **When that ring is under Close's minimum** (a coastal home gives a ring
## mostly sea: Game Design rulings-2026-10-23 section 6) **the ring turns toward land, keeping the home on it**: the rings through the home at data `first.bearings` evenly spaced bearings (from the
## same seeded one) are read and the one that meets Close's minimum with the most land (then the most biomes) is taken. If no bearing meets it the story's ring stands as it is, as the boss's does.
## opts: standing, damaged (as the picker takes them). Returns {c, t, cols, kind ("round" or "through"), turned, land}; the same answer however it is stepped (`beginFirstRing`).
static func firstRing(P: WorldPlanet.Planet, homeId: int, stream: int, opts: Dictionary = {}) -> Dictionary:
	var job: FirstJob = beginFirstRing(P, homeId, stream, opts)
	job.finishNow()
	return job.spec


static func beginFirstRing(P: WorldPlanet.Planet, homeId: int, stream: int, opts: Dictionary = {}) -> FirstJob:
	var j := FirstJob.new()
	j.P = P
	j.home = homeId
	j.standing = opts.get("standing", PackedByteArray())
	j.damaged = opts.get("damaged", [])
	var rg := SimRng.new((stream * 7919 + 15485863) & 0xFFFFFFFF)
	var phi0: float = rg.next() * 2.0 * SimMathx.PI
	var cols: int = sizeCols("close")
	j.base = roundSpec(placePoint(P, homeId), cols, phi0)
	j.base["kind"] = "round"
	j.base["place"] = homeId
	var n: int = int(cfg().first.bearings)
	var T: Array = placePoint(P, homeId)
	for k in range(n):
		var sp: Dictionary = throughSpec(T, cols, phi0 + 2.0 * SimMathx.PI * float(k) / float(n))
		sp["kind"] = "through"
		sp["place"] = homeId
		j.cands.append(sp)
	return j


## A first ring in steps (the host spends a few reads a frame): step(n) reads up to n more rings (the story's first, then the turned ones only if it is under the minimum); true when made. `spec`
## is the answer. `total` is how many reads it may take (1 + bearings).
class FirstJob extends RefCounted:
	var P: WorldPlanet.Planet
	var home: int = -1
	var standing := PackedByteArray()
	var damaged: Array = []
	var base: Dictionary = {}
	var cands: Array = []
	var evs: Array = []
	var done: bool = false
	var spec: Dictionary = {}
	var _baseEv: Dictionary = {}
	var _baseRead: bool = false

	var total: int:
		get:
			return 1 + cands.size()

	func step(n: int) -> bool:
		while n > 0 and not done:
			n -= 1
			if not _baseRead:
				_baseEv = WorldRingPick.evalRing(P, base, standing, damaged)
				_baseRead = true
				if WorldRingPick.meets(_baseEv, "close"):
					_finish(base, false, _baseEv)
				continue
			evs.append(WorldRingPick.evalRing(P, cands[evs.size()], standing, damaged))
			if evs.size() >= cands.size():
				_choose()
		return done

	func finishNow() -> void:
		step(1 << 30)

	func _choose() -> void:
		var best: int = -1
		var bestKey: Array = []
		for k in range(cands.size()):
			if not WorldRingPick.meets(evs[k], "close"):
				continue
			var key: Array = [evs[k].land, evs[k].biomes, -k]
			if best < 0 or WorldRingPick._better(key, bestKey):
				best = k
				bestKey = key
		if best < 0:
			_finish(base, false, _baseEv)   # no bearing meets the minimum: the story's ring stands
		else:
			_finish(cands[best], true, evs[best])

	func _finish(sp: Dictionary, turned: bool, ev: Dictionary) -> void:
		spec = {"c": sp.c, "t": sp.t, "cols": sp.cols, "kind": sp.kind, "turned": turned, "land": ev.land}
		done = true


'''
    return s[:a] + new + s[b:]


rings_json(R + 'data/biomes/rings.json')
rings_schema(R + 'tools/schemas/biomes-rings.schema.json')
rw(R, 'sim/world/ringpick.gd', ringpick)
print('first ring turns toward land applied')
