"""The ring picker passes over rings a run has already fought (World, scratch): opts.used.   python mk_used.py <root>
EP ruling 2026-10-23: a run never fights the same ring twice. The picker takes opts.used (rings already fought) and passes over them, scoring them down only if nothing else meets the size's minimum."""
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
            out['usedCos'] = 0.9976
            out['usedPenalty'] = 0.5
    out['_about'] = out['_about'] + " usedCos, usedPenalty: a ring a run has already fought (opts.used) is the same circle as a candidate of the same length when their axes make at least this cosine (0.9976 is about 4 degrees: the ground they cross is mostly the same; a Whole ring's axis counts either way round), and it is passed over unless nothing else meets the size's minimum, when it is scored down by usedPenalty."
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(out, indent=2) + '\n')


def rings_schema(p):
    j = json.load(open(p, encoding='utf-8'), object_pairs_hook=OD)
    j['required'] += ['usedCos', 'usedPenalty']
    props = OD()
    for k, v in j['properties'].items():
        props[k] = v
        if k == 'coastRef':
            props['usedCos'] = OD([("type", "number"), ("minimum", 0.5), ("maximum", 1), ("description", "A ring a run has fought is the same circle as a candidate of the same length when their axes' cosine is at least this (0.9976: about 4 degrees).")])
            props['usedPenalty'] = OD([("type", "number"), ("minimum", 0), ("maximum", 2), ("description", "What a repeated ring's score loses when nothing else meets the size's minimum.")])
    j['properties'] = props
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2) + '\n')


def ringpick(s):
    s = rep(s, '''for k in ["stride", "biomeShare", "ref", "mustAt", "avoidWeight", "homeBonus", "coastRef"]:''', '''for k in ["stride", "biomeShare", "ref", "mustAt", "avoidWeight", "homeBonus", "coastRef", "usedCos", "usedPenalty"]:''')
    # the doc of pick, beginPick takes opts.used
    s = rep(s, '''## The ring for an opponent's claim at a size on planet P, from the run's stream. opts: standing, damaged (wear), home (the claim's home place id, or -1), pinned (place ids to try first:
## the home).''', '''## The ring for an opponent's claim at a size on planet P, from the run's stream. opts: standing, damaged (wear), home (the claim's home place id, or -1), pinned (place ids to try first:
## the home), used (the rings the run has already fought, a run never fights one twice: see `usedMatch`; they are passed over, and scored down only when nothing else meets the size's minimum).''')
    s = rep(s, '''	j.cands = candidates(P, size, stream, pinned)
	return j
''', '''	j.cands = candidates(P, size, stream, pinned)
	j.used = usedList(opts.get("used", []))
	return j


## The rings a run has fought, as the picker compares them. Each entry is a ring's spec or setup.arena ({c, t, cols}, the numbers or the exact-bit strings arenaOf writes; only the axis c and the
## columns are read) or a candidate's identity ({place, kind, cols}: a ring "round" or "through" that place). {c: [x, y, z], cols: n, place: -1, kind: ""} each.
static func usedList(used: Array) -> Array:
	var out: Array = []
	for u in used:
		if not (u is Dictionary):
			continue
		var e := {"c": [], "cols": int(u.get("cols", 0)), "place": int(u.get("place", -1)), "kind": str(u.get("kind", ""))}
		if u.has("c") and u.c is Array and u.c.size() == 3:
			var c: Array = []
			for x in u.c:
				c.append(SimMathx.f64(x) if x is String else float(x))
			e.c = c
		if e.c.size() == 3 or e.place >= 0:
			out.append(e)
	return out


## Is candidate `cand` ({c, cols, kind, place}) the same ring as one of `used`: the same length and an axis within data usedCos of it (a Whole ring's axis either way round: it is the same
## circle), or the same place and kind (and length, when the entry gives it).
static func usedMatch(cand: Dictionary, used: Array) -> bool:
	var cosMin: float = float(cfg().usedCos)
	var whole: bool = int(cand.cols) >= SimConst.PLANET_NC
	for e in used:
		if e.c.size() == 3:
			if int(e.cols) == int(cand.cols):
				var d: float = _dot(e.c, cand.c)
				if (whole and absf(d) >= cosMin) or (not whole and d >= cosMin):
					return true
		elif e.place >= 0 and int(cand.place) == e.place and (e.kind == "" or e.kind == str(cand.kind)) and (int(e.cols) == 0 or int(e.cols) == int(cand.cols)):
			return true
	return false
''')
    s = rep(s, '''	var home: int = -1
	var cands: Array = []
	var evs: Array = []''', '''	var home: int = -1
	var used: Array = []     # the rings the run has fought (WorldRingPick.usedList)
	var cands: Array = []
	var evs: Array = []''')
    # _choose: used candidates are a last resort, scored down
    s = rep(s, '''		var best = null
		var bestKey: Array = []
		for relaxed in [false, true]:
			for i in range(cands.size()):
				if not WorldRingPick.meets(evs[i], size, relaxed):
					continue
				var sc: Dictionary = WorldRingPick.score(evs[i], claim, home)
				var key: Array = [1 if sc.must else 0, sc.score, -i]
				if best == null or WorldRingPick._better(key, bestKey):
					best = _entry(i, sc, not relaxed, relaxed)
					bestKey = key
			if best != null:
				break
''', '''		var best = null
		var bestKey: Array = []
		var repeats := PackedByteArray()   # which candidates are rings the run has fought
		repeats.resize(cands.size())
		for i in range(cands.size()):
			repeats[i] = 1 if (used.size() > 0 and WorldRingPick.usedMatch(cands[i], used)) else 0
		var penalty: float = float(WorldRingPick.cfg().usedPenalty)
		for pass_ in range(2):   # a ring the run has not fought first; a repeat only if nothing else meets even the crude minimum (scored down)
			for relaxed in [false, true]:
				for i in range(cands.size()):
					if int(repeats[i]) != pass_ or not WorldRingPick.meets(evs[i], size, relaxed):
						continue
					var sc: Dictionary = WorldRingPick.score(evs[i], claim, home)
					if pass_ == 1:
						sc = sc.duplicate()
						sc.score = float(sc.score) - penalty
					var key: Array = [1 if sc.must else 0, sc.score, -i]
					if best == null or WorldRingPick._better(key, bestKey):
						best = _entry(i, sc, not relaxed, relaxed)
						bestKey = key
				if best != null:
					break
			if best != null:
				break
''')
    s = rep(s, '''			for i in range(cands.size()):
				var sc2: Dictionary = WorldRingPick.score(evs[i], claim, home)
				var key2: Array = [1 if sc2.must else 0, sc2.score, -i]''', '''			for i in range(cands.size()):
				var sc2: Dictionary = WorldRingPick.score(evs[i], claim, home)
				if int(repeats[i]) == 1:
					sc2 = sc2.duplicate()
					sc2.score = float(sc2.score) - penalty
				var key2: Array = [1 if sc2.must else 0, sc2.score, -i]''')
    s = rep(s, '''		return {"ok": okFlag, "spec": {"c": sp.c, "t": sp.t, "cols": sp.cols}, "score": sc.score, "must": sc.must, "home": sc.home, "relaxed": relaxed, "kind": sp.kind, "place": sp.place, "ev": evs[i], "idx": i}''',
        '''		return {"ok": okFlag, "spec": {"c": sp.c, "t": sp.t, "cols": sp.cols}, "score": sc.score, "must": sc.must, "home": sc.home, "relaxed": relaxed, "kind": sp.kind, "place": sp.place, "ev": evs[i], "idx": i, "repeat": used.size() > 0 and WorldRingPick.usedMatch(sp, used)}''')
    return s


rings_json(R + 'data/biomes/rings.json')
rings_schema(R + 'tools/schemas/biomes-rings.schema.json')
rw(R, 'sim/world/ringpick.gd', ringpick)
print('opts.used applied')
