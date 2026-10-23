"""The story-stage entry point of the ring picker (World, scratch): WorldRingPick.stageArena / beginStage / StageJob.   python mk_stage.py <root>
 - data/biomes/rings.json: `stage` (which of a claim's size keys a stage kind reads; the proving ground's size) and its schema
 - sim/world/ringpick.gd: grounds() (Narrative's claims by roster id), standInHome, beginStage -> StageJob (step(n), progress), stageArena (all at once)"""
import sys, json, collections
from mk_wbc_lib import rw, rep
OD = collections.OrderedDict
R = sys.argv[1].rstrip('/') + '/'


def rings_json(p):
    d = json.load(open(p, encoding='utf-8'), object_pairs_hook=OD)
    d['stage'] = OD([("claimKey", OD([("early", "early"), ("mid", "mid"), ("late", "mid"), ("boss", "boss")])), ("proving", "close")])
    d['_about'] = d['_about'] + " stage: the run's story stages (WorldRingPick.stageArena): claimKey names the key of the opponent's claim (Narrative's data/narrative/opponent_grounds.json, size.early, size.mid, size.boss) that gives a stage kind's size (the stage before the boss reads the middle size), proving the size of a Proving ground (Game Design 2c, rulings-2026-10-19b section 3). The first fight (a Close ring round the player's home) and the boss (the Whole circle through his home) are not read from a claim."
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(d, indent=2) + '\n')


def rings_schema(p):
    j = json.load(open(p, encoding='utf-8'), object_pairs_hook=OD)
    j['required'].append('stage')
    sz = OD([("enum", ["close", "half", "whole"])])
    key = OD([("enum", ["early", "mid", "boss"])])
    j['properties']['stage'] = OD([("type", "object"), ("required", ["claimKey", "proving"]), ("additionalProperties", False), ("properties", OD([
        ("claimKey", OD([("type", "object"), ("required", ["early", "mid", "late", "boss"]), ("additionalProperties", False), ("properties", OD([
            ("early", OD(list(key.items()) + [("description", "The claim size key a stage in the run's first half reads.")])),
            ("mid", OD(list(key.items()) + [("description", "The claim size key a middle stage reads.")])),
            ("late", OD(list(key.items()) + [("description", "The claim size key the stage before the boss reads.")])),
            ("boss", OD(list(key.items()) + [("description", "The claim size key the boss's pick reads when it has no ring through two places (the fallback).")]))]))])),
        ("proving", OD(list(sz.items()) + [("description", "The size of a Proving ground (Game Design 2c: Close).")]))]))])
    open(p, 'w', encoding='utf-8', newline='').write(json.dumps(j, indent=2) + '\n')


def ringpick(s):
    s = rep(s, '''	if not (j.get("turn") is Dictionary):
		_cErrors.append("rings.json: turn is an object")
''', '''	if not (j.get("turn") is Dictionary):
		_cErrors.append("rings.json: turn is an object")
	if not (j.get("stage") is Dictionary and j.stage.get("claimKey") is Dictionary and ["close", "half", "whole"].has(str(j.stage.get("proving", "")))):
		_cErrors.append("rings.json: stage has claimKey and proving")
''')
    s += '''

# ===================================================================== story stages

const GROUNDS_PATH := "res://data/narrative/opponent_grounds.json"
static var _grounds: Dictionary = {}   # Narrative's claims by roster id: a pure read of a data file, memoised outside the sim state


## Narrative's claims (data/narrative/opponent_grounds.json), by the opponent's roster id (RIVAL, EMPRESS, CYBORG, PROTAGONIST). {} if the file cannot be read.
static func grounds() -> Dictionary:
	if _grounds.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(GROUNDS_PATH))
		if j is Dictionary and j.get("claims") is Dictionary:
			_grounds = j.claims
	return _grounds


## The stand-in home until Orb names the homes (homework 39): the most populous city still standing (ties to the lower id); the most populous place if no city stands; -1 if nothing does.
static func standInHome(P: WorldPlanet.Planet, standing: PackedByteArray = PackedByteArray()) -> int:
	var best: int = -1
	for pass_ in range(2):
		for i in range(P.n):
			if standing.size() > 0 and standing[i] == 0:
				continue
			if pass_ == 0 and int(P.kind[i]) != WorldPlanet.KIND_CITY:
				continue
			if best < 0 or P.people[i] > P.people[best]:
				best = i
		if best >= 0:
			break
	return best


## The ring for a stage of a run, in steps (the host spends a few candidates a frame across the previous stage's beats: `step(n)`, true when it is made; `result` then). stage:
##   kind       "first" (a Close ring round the player's home), "early", "mid", "late" (the stage before the boss), "proving" (a Proving ground), "boss" (the Whole circle through the boss's home and
##              the most populous place still standing)
##   opponent   the opponent's roster id (the key of his claim); a first stage and a boss's ring read no claim
##   home       a place id: the player's home for "first", the boss's for "boss", the claim's for the rest (-1: none). Absent: standInHome
##   standing   the places still standing (a byte each, as WorldPlanet's); absent: all
##   damaged    the wear (the picker's `damaged`); absent: none
##   size       "close", "half" or "whole": a size forced in place of the claim's (absent: the claim's, by data/biomes/rings.json stage.claimKey; a Proving ground's by stage.proving)
## `stream`: the run's seeded stream for this stage (the picker's, as pick takes it). A pure function of the planet, the stage, the stream and the data, so a run replays.
## result: {ok, arena (setup.arena: {cols, c, t} as exact bits), spec {c, t, cols}, stage, opponent, size, home, place, kind, score, must, relaxed, tried}, or {ok: false, error, arena: {}}.
static func beginStage(P: WorldPlanet.Planet, stage: Dictionary, stream: int) -> StageJob:
	var j := StageJob.new()
	j.P = P
	j.stage = stage
	var kind: String = str(stage.get("kind", "early"))
	var opp: String = str(stage.get("opponent", ""))
	var standing: PackedByteArray = stage.get("standing", PackedByteArray())
	var home: int = int(stage.home) if stage.has("home") else standInHome(P, standing)
	j.home = home
	if kind == "first":
		if home < 0:
			return j._fail("no home to fight round")
		return j._made(firstRing(P, home, stream), "close", home, home, "round")
	if kind == "boss":
		var br = bossRing(P, home, standing) if home >= 0 else null
		if br != null:
			return j._made({"c": br.c, "t": br.t, "cols": br.cols}, "whole", home, int(br.other), "through")
		pass   # no ring through two places: the claim's own Whole pick, below
	var claims: Dictionary = grounds()
	if not claims.has(opp):
		return j._fail("no claim for '%s'" % opp)
	var claim: Dictionary = claims[opp]
	var sz: String = str(stage["size"]) if stage.has("size") else ""
	if sz == "":
		if kind == "proving":
			sz = str(cfg().stage.proving)
		else:
			var key: String = str(cfg().stage.claimKey.get(kind, "mid"))
			sz = str(claim.get("size", {}).get(key, "half"))
	j.size = sz
	j._pick = beginPick(P, claim, sz, stream, {"standing": standing, "damaged": stage.get("damaged", []), "home": home})
	j.total = j._pick.cands.size()
	return j


## The same, all at once (a tool, a test, a host that does not mind the wait: 120 to 330 ms native).
static func stageArena(P: WorldPlanet.Planet, stage: Dictionary, stream: int) -> Dictionary:
	var job: StageJob = beginStage(P, stage, stream)
	job.finishNow()
	return job.result


class StageJob extends RefCounted:
	var P: WorldPlanet.Planet
	var stage: Dictionary = {}
	var home: int = -1
	var size: String = ""
	var total: int = 0          # candidates to read (0 for a first stage or a boss's ring: made at once)
	var done: bool = false
	var result: Dictionary = {}
	var _pick: WorldRingPick.PickJob = null

	## Reads up to n more candidates; true when the stage's ring is made.
	func step(n: int) -> bool:
		if not done and _pick != null and _pick.step(n):
			var r: Dictionary = _pick.result
			result = {"ok": r.ok, "arena": WorldRingPick.arenaOf(r.spec), "spec": r.spec, "stage": str(stage.get("kind", "early")), "opponent": str(stage.get("opponent", "")), "size": size, "home": home,
				"place": r.place, "kind": r.kind, "score": r.score, "must": r.must, "relaxed": r.relaxed, "tried": r.tried}
			done = true
		return done

	func finishNow() -> void:
		step(1 << 30)

	## 0 to 1: how much of the pick is read (a ring made at once is 1).
	func progress() -> float:
		if done or _pick == null:
			return 1.0
		return float(_pick.evs.size()) / float(maxi(total, 1))

	func _made(spec: Dictionary, sz: String, homeId: int, place: int, kind: String) -> StageJob:
		size = sz
		result = {"ok": true, "arena": WorldRingPick.arenaOf(spec), "spec": spec, "stage": str(stage.get("kind", "early")), "opponent": str(stage.get("opponent", "")), "size": sz, "home": homeId,
			"place": place, "kind": kind, "score": 0.0, "must": true, "relaxed": false, "tried": 0}
		done = true
		return self

	func _fail(why: String) -> StageJob:
		result = {"ok": false, "error": why, "arena": {}, "spec": {}, "stage": str(stage.get("kind", "early")), "opponent": str(stage.get("opponent", ""))}
		done = true
		return self
'''
    return s


def cases(s):
    a = '''    {
      "id": "rings-turn-bearing-over-10",'''
    b = '''    {
      "id": "rings-stage-proving-unknown",
      "schema": "biomes-rings.schema.json",
      "mutate": [
        {
          "file": "data/biomes/rings.json",
          "set": {
            "/stage/proving": "tiny"
          }
        }
      ],
      "expect": {
        "rule": "enum",
        "pointer": "/stage/proving"
      }
    },
''' + a
    return rep(s, a, b)


rw(R, 'tools/fixtures/cases.json', cases)
rings_json(R + 'data/biomes/rings.json')
rings_schema(R + 'tools/schemas/biomes-rings.schema.json')
rw(R, 'sim/world/ringpick.gd', ringpick)
print('stage entry point applied')
