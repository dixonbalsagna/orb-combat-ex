extends RefCounted
## A planet for QA's matches (docs/qa/cloud-reports/2026-10-28-gen2-baseline.md): with QA_PLANET set in the environment
## (the child Godot processes inherit it), records.gd, masher.gd and players.gd play each match on a planet ring
## instead of the hand-made world. Unset, nothing changes and the records are as they were.
##   QA_PLANET="gen=2;planets=3,7,11,13,17,19,23,25,29,31;touches=0,1,2,3;cols=2400"
## Seed s plays planet planets[(s-1) % P] at touch touches[((s-1) / P) % T]: every planet and touch is met in turn.
## gen is the setup's planetGen (1 or 2); cols the ring's columns (2400, the campaign's ringCols).


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
