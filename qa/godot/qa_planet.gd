extends RefCounted
## A planet for QA's matches (docs/qa/cloud-reports/2026-10-28-gen2-baseline.md): with QA_PLANET set in the environment
## (the child Godot processes inherit it), records.gd, masher.gd and players.gd play each match on a planet ring
## instead of the hand-made world. Unset, nothing changes and the records are as they were.
##   QA_PLANET="gen=2;planets=3,7,11,13,17,19,23,25,37,31;touches=0,1,2,3;cols=2400"   (29 was in it until 2026-10-29: planet 29 at touch 2 has no ring, planet_scan.gd)
## Seed s plays planet planets[(s-1) % P] at touch touches[((s-1) / P) % T]: every planet and touch is met in turn.
## gen is the setup's planetGen (1 or 2); cols the ring's columns (2400, the campaign's ringCols).


## Set by fellBack() when a planet match's slice failed (the first message); the runners quit with exit code 3 on it, so a batch never goes on to play the hand-made world
## as if it were a ring (World's W7 found planet 29 at touch 2 doing it: 120 structures, the mean lifted by about 1).
static var failed: String = ""


## True when QA_PLANET is set and the match S just built has no planet world (the slice failed and newMatch fell back to the hand-made world, which leaves S.planetCols empty).
static func fellBack(S, seed: int) -> bool:
	if OS.get_environment("QA_PLANET") == "" or not S.planetCols.is_empty():
		return false
	if failed == "":
		var su: Dictionary = setup(seed)
		failed = "QA_PLANET: seed %d (planet %d, touch %d, gen %d) fell back to the hand-made world: its slice failed; the batch stops" % [seed, int(su.planet), int(su.touch), int(su.planetGen)]
		printerr(failed)
		print(failed)
	return true


## The setup keys for seed `seed`, merged over `base`; `base` unchanged when QA_PLANET is unset.
static func setup(seed: int, base: Dictionary = {}) -> Dictionary:
	var spec: String = OS.get_environment("QA_PLANET")
	if spec == "":
		return base
	var gen: int = 2
	var planets: Array = [7]
	var touches: Array = [0]
	var cols: int = 2400
	for part in spec.split(";", false):
		var kv: PackedStringArray = part.split("=")
		if kv.size() != 2:
			continue
		match kv[0].strip_edges():
			"gen":
				gen = int(kv[1])
			"cols":
				cols = int(kv[1])
			"planets":
				planets = Array(kv[1].split(",", false)).map(func(x): return int(x))
			"touches":
				touches = Array(kv[1].split(",", false)).map(func(x): return int(x))
	var i: int = max(seed - 1, 0)
	var out: Dictionary = base.duplicate(true)
	out["planet"] = int(planets[i % planets.size()])
	out["touch"] = int(touches[(i / planets.size()) % touches.size()])
	out["arena"] = {"cols": cols}
	out["planetGen"] = gen
	out["intro"] = false
	return out
