extends SceneTree
## World's meeting point through the real director (docs/world/struggle-meet.md, grant-encounter-beam.patch): AI-vs-AI matches played until beam struggles end, with the struggle
## on (beamStruggle.enabled and endEvent set here, as the page's "struggle" switch does) and WorldStruggleMeet off and then on.
## Off: nothing of the meeting point happens: no ring cue, no shape on the end cue, no beam stopped. On: every struggle's beams stop at their fronts when it starts, rings come at most
## every ringMinGapSec, the end cue carries r, rGlass, shape and dug once, a bowl's record is the cue's radius at the cue's tick, an overwhelm's winner has a beam that starts at the
## point, and the same seed twice gives the same state.
##   godot --headless --path . --script res://sim/world/tools/struggle_dir_check.gd [-- <seeds> <seed0> <cap>]

var _fails: int = 0


func ok(c: bool, msg: String) -> void:
	if not c:
		_fails += 1
		print("  FAIL: ", msg)


## One match to its first struggle's end (or the cap). Returns what the director did.
func _run(seed_: int, cap: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {"p1": true, "p2": true}, {"v2": [true, false]})
	var r := {"ended": false, "rings": [], "end": null, "endTick": -1, "stopOk": true, "stopSeen": false, "stopped": 0, "craters0": 0, "cratersEnd": 0, "recR": -1.0, "newCr": [], "beamAtPoint": false, "how": "", "hash": ""}
	while S.tick < cap and S.game.ko == null:
		var c0: int = S.craters.size()
		SimCore.step(S, null)
		if S.game.clash != null and not r.stopSeen:
			r.stopSeen = true
			for b in S.beams:
				if b.A == S.game.clash.A or b.A == S.game.clash.D:
					r.stopped += 1 if b.stopAt >= 0.0 else 0
					if b.stopAt < 0.0:
						r.stopOk = false
		for e in S.out.fx:
			if e.type != "cue":
				continue
			var ck: String = String(e.kind)
			if ck == "struggle_ring":
				r.rings.append({"tick": S.tick, "r": e.amount, "n": e.n, "x": e.x, "y": e.y})
			elif ck == "beam_clash_end":
				r.end = {"tick": S.tick, "x": e.x, "y": e.y, "r": e.r, "rGlass": e.rGlass, "shape": e.shape, "dug": e.dug, "how": String(e.source), "text": String(e.text)}
				r.endTick = S.tick
				r.ended = true
				r.cratersEnd = S.craters.size() - c0
				if S.craters.size() > c0:
					r.recR = float(S.craters[S.craters.size() - 1].r)
					for ci in range(c0, S.craters.size()):
						(r.newCr as Array).append([snappedf(float(S.craters[ci].r), 0.1), String(S.craters[ci].cause), float(S.craters[ci].special) == 1.0])
				for b in S.beams:
					if absf(b.ox - e.x) < 1.0e-6 and absf(b.oy - e.y) < 1.0e-6:
						r.beamAtPoint = true
		if r.ended:
			break
		S.out.fx.clear()   # the host drains the event and feed lists each tick, or a cue is read again every tick
		S.out.feed.clear()
	r.hash = SimHash.stateHash(S).gameplay
	SimCore.dispose(S)
	return r


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 8
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var cap: int = int(args[2]) if args.size() > 2 else 9000
	SimInputData.load_and_apply()
	var bsd: Dictionary = DirInterrupt.data().beamStruggle
	bsd["enabled"] = true
	bsd["endEvent"] = true
	var sm: Dictionary = WorldStruggleMeet.block()
	ok(not sm.is_empty(), "the struggleMeet block is in craters.json")
	var ended_off: int = 0
	var ended_on: int = 0
	var shapes := {}
	var hows := {}
	var overwhelm_beams: int = 0
	var overwhelms: int = 0
	var rings_total: int = 0
	var stops: int = 0
	var extra: int = 0
	var lines: Array = []
	var dug_bowls: int = 0
	for k in range(n):
		var sd: int = seed0 + k
		sm["enabled"] = false
		var off: Dictionary = _run(sd, cap)
		sm["enabled"] = true
		var on_a: Dictionary = _run(sd, cap)
		var on_b: Dictionary = _run(sd, cap)
		if off.ended:
			ended_off += 1
			ok((off.rings as Array).is_empty(), "seed %d off: no struggle_ring cue" % sd)
			ok(String(off.end.shape) == "" and float(off.end.r) == 0.0 and float(off.end.rGlass) == 0.0 and float(off.end.dug) == 0.0, "seed %d off: the end cue carries no meeting-point fields" % sd)
			ok(int(off.stopped) == 0, "seed %d off: no beam stopped at the fronts" % sd)
		ok(on_a.hash == on_b.hash and on_a.ended == on_b.ended and on_a.endTick == on_b.endTick, "seed %d on: the same seed twice gives the same state" % sd)
		if on_a.ended:
			ended_on += 1
			var e: Dictionary = on_a.end
			var sh: String = String(e.shape)
			shapes[sh] = int(shapes.get(sh, 0)) + 1
			hows[String(e.how)] = int(hows.get(String(e.how), 0)) + 1
			lines.append("seed %d %s %s r %.0f rGlass %.0f dug %.1f rings %d craters on the ending tick %s (off: %s)" % [sd, String(e.how), sh, e.r, e.rGlass, e.dug, (on_a.rings as Array).size(), JSON.stringify(on_a.newCr), JSON.stringify(off.newCr) if off.ended else "no struggle"])
			ok(sh == "bowl" or sh == "scorch" or sh == "air", "seed %d on: the end cue's shape is bowl, scorch or air (%s)" % [sd, sh])
			ok(float(e.rGlass) > 0.0 and float(e.dug) >= 0.0, "seed %d on: rGlass above 0 and dug set (%.0f, %.1f)" % [sd, e.rGlass, e.dug])
			ok(on_a.stopSeen and on_a.stopOk, "seed %d on: no live beam of the pair is left running past its front when the struggle starts (%d stopped)" % [sd, on_a.stopped])
			stops += int(on_a.stopped)
			var rg: Array = on_a.rings
			rings_total += rg.size()
			for i in range(1, rg.size()):
				ok(int(rg[i].tick) - int(rg[i - 1].tick) >= 120, "seed %d on: rings at least 2 s apart" % sd)
			for i in range(1, rg.size()):
				ok(float(rg[i].r) > float(rg[i - 1].r), "seed %d on: each ring is wider than the last" % sd)
			ok(rg.size() >= 1 and float(rg[0].r) >= 75.0 - 1.0e-6, "seed %d on: a ring came, from one body height up" % sd)
			if sh == "bowl":
				dug_bowls += 1
				var mine: int = 0
				for c in on_a.newCr:
					mine += 1 if absf(float(c[0]) - float(e.r)) < 0.06 else 0
				ok(mine >= 1, "seed %d on: a bowl is a record of the cue radius dug in the cue tick (%s vs %.1f)" % [sd, JSON.stringify(on_a.newCr), e.r])
				extra += int(on_a.cratersEnd) - 1
			else:
				ok(float(e.r) == 0.0, "seed %d on: no bowl, no radius" % sd)
			if String(e.how) == "overwhelmed":
				overwhelms += 1
				overwhelm_beams += 1 if on_a.beamAtPoint else 0
	for l in lines:
		print("  ", l)
	print("STRUGGLEDIR seeds %d: ended off %d, on %d; shapes %s; endings %s; rings %d; bowls %d; overwhelms %d, beam from the point in %d; beams stopped at a struggle start %d; extra craters on an ending tick %d" % [n, ended_off, ended_on, JSON.stringify(shapes), JSON.stringify(hows), rings_total, dug_bowls, overwhelms, overwhelm_beams, stops, extra])
	ok(ended_on >= 1, "at least one struggle ended on the seeds tried (a count of 0 proves nothing: raise the seeds)")
	ok(overwhelm_beams == overwhelms, "every overwhelm's winner has a beam that starts at the point")
	print("STRUGGLEDIR: %d check(s) failed" % _fails)
	quit(1 if _fails > 0 else 0)
