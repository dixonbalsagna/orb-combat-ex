extends SceneTree
## QA's depth row (rulings-2026-10-30f.md row 9), read from seeded AI matches. For QA to fold into its table.
##   godot --headless --path . --script res://sim/director/tools/plane_read.gd -- <matches> <seed0> [--cap=18000] [--off]
## The world comes from QA_PLANET (QaPlanet.setup); unset, the hand-made world. --off sets the ease to 0 for the baseline.
## At each damaging melee strike: the depth gap between the two, and whether a standing building's box is on the line
## between their centres, or holds one of them. Each ease that passes through a standing face is counted once, a match.
## Prints one line of JSON.

const QaPlanet = preload("res://qa/godot/qa_planet.gd")
const MELEE := ["light", "medium", "heavy", "guard"]
const MID: float = 37.5


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var cap := 18000
	for s in args:
		if s.begins_with("--cap="):
			cap = int(s.substr(6))
		elif s == "--off":
			DirPlane.setRate(0.0)
	var r := {"matches": n, "rate": DirPlane.rate(), "ticks": 0, "strikes": 0, "over0": 0, "over30": 0, "over75": 0, "largest": 0.0, "face": 0, "easeThrough": 0, "offTicks": 0, "lastOver75": [], "faceAt": []}
	for m in range(n):
		var seed: int = seed0 + m
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed, {}, QaPlanet.setup(seed, {}))
		if QaPlanet.fellBack(S, seed):
			quit(3)
			return
		var was := [0.0, 0.0]
		var through := [false, false]
		while S.tick < cap and S.game.ko == null:
			SimCore.step(S)
			r.ticks += 1
			var fs = S.fighters
			var ex = S.dirS.ex
			for k in range(2):
				var f = fs[k]
				if f.state != "launched" and f.z != 0.0:
					r.offTicks += 1
				if f.z == 0.0:
					through[k] = false
				elif f.state != "launched" and f.z != was[k] and not through[k]:
					var list: Array = WorldStructures.along(S, f.x, f.x, 0.0)
					if not list.is_empty() and bool(WorldStructures.sweep(S, list, f.x, f.y + MID, was[k], f.x, f.y + MID, f.z, 0.0, 0.0, 0.0).hit):
						through[k] = true
						r.easeThrough += 1
				was[k] = f.z
			for e in S.out.fx:
				if e.type != "damage" or not e.number or e.amount <= 0.0 or ex == null or not MELEE.has(str(e.get("kind"))):
					continue
				if int(e.attacker) < 0 or int(e.attacker) > 1 or int(e.victim) < 0 or int(e.victim) > 1:
					continue
				var a = fs[int(e.attacker)]
				var b = fs[int(e.victim)]
				r.strikes += 1
				var dz: float = absf(a.z - b.z)
				r.largest = maxf(float(r.largest), dz)
				if dz > 0.5:
					r.over0 += 1
				if dz > 30.0:
					r.over30 += 1
				if dz > 75.0:
					r.over75 += 1
					if (r.lastOver75 as Array).size() < 8:
						(r.lastOver75 as Array).append({"seed": seed, "tick": S.tick, "dz": snappedf(dz, 0.1), "tag": str(ex.tag), "kind": str(e.get("kind")), "tpl": str(ex.tpl), "az": snappedf(a.z, 0.1), "vz": snappedf(b.z, 0.1)})
				if _face(S, a, b):
					r.face += 1
					if (r.faceAt as Array).size() < 8:
						(r.faceAt as Array).append(_faceInfo(S, a, b, seed, str(ex.tag)))
			S.out.fx.clear()
			S.out.feed.clear()
		SimCore.dispose(S)
	r["over30Share"] = snappedf(100.0 * float(r.over30) / maxf(1.0, float(r.strikes)), 0.001)
	r["easeThroughPerMatch"] = snappedf(float(r.easeThrough) / maxf(1.0, float(n)), 0.01)
	print("PLANE " + JSON.stringify(r))
	quit()


func _face(S, a, b) -> bool:
	if WorldStructures.blocked(S, a.x, a.y + MID, a.z, 0.0, 0.0, 0.0) >= 0 or WorldStructures.blocked(S, b.x, b.y + MID, b.z, 0.0, 0.0, 0.0) >= 0:
		return true
	var list: Array = WorldStructures.along(S, a.x, b.x, 0.0)
	return not list.is_empty() and bool(WorldStructures.sweep(S, list, a.x, a.y + MID, a.z, b.x, b.y + MID, b.z, 0.0, 0.0, 0.0).hit)


## Where a face was met, for the report: each one's depth and state, and the box holding him or crossed.
func _faceInfo(S, a, b, seed: int, tag: String) -> Dictionary:
	var ia: int = WorldStructures.blocked(S, a.x, a.y + MID, a.z, 0.0, 0.0, 0.0)
	var ib: int = WorldStructures.blocked(S, b.x, b.y + MID, b.z, 0.0, 0.0, 0.0)
	var bi: int = ia if ia >= 0 else ib
	var q: Dictionary = {"seed": seed, "tick": S.tick, "tag": tag, "az": snappedf(a.z, 0.1), "vz": snappedf(b.z, 0.1), "ast": str(a.state), "vst": str(b.state), "ay": snappedf(a.y, 0.1), "inA": ia >= 0, "inV": ib >= 0}
	if bi >= 0:
		var bd = S.buildings[bi]
		q["box"] = {"z": snappedf(bd.z, 0.1), "d": snappedf(bd.d, 0.1), "w": snappedf(bd.w, 0.1), "h": snappedf(WorldStructures.curH(bd), 0.1), "base": snappedf(WorldStructures.baseY(S, bd), 0.1), "kind": str(bd.kind)}
	return q
