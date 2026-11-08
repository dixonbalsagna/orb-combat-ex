extends SceneTree
## CD-05 (Orb, 2026-11-07, "no civilian deaths going forward"): no fighter gains anything from a civilian death. WorldCollateral.kill never raises any fighter's menace or power, whoever
## caused it, however many it grants; the villain's menace still rises from people his blows forced to flee (the evacuation source). Three halves, each with its negative control:
##   1. behaviour: kills by each fighter and by nobody, over several worlds, with the budget open: casualties are granted, no fighter's menace or power rose;
##   2. the evacuation source is kept: with no room left the same kill is all evacuees, and the villain's menace rises by them and his power does not;
##   3. the code and the data: `_feed` names neither menace nor power, the only write to menace in collateral.gd is the evacuation one, and a menace casualty source in a meters file is
##      rejected as not wired (the 0.9 row and the 0.09 power line are gone).
## The controls: the detector is run on the old feed's gains put back by hand (it must flag them), the lint on the old `_feed` text (it must find them), the loader on the old data row
## (it must reject it). A check that cannot fail proves nothing.
##   godot --headless --path . --script res://sim/world/tools/casualty_feed_check.gd

var _fails: int = 0


func ok(c: bool, msg: String) -> void:
	if not c:
		_fails += 1
		print("  FAIL: ", msg)


func fresh(seed_: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {}, {"intro": false})
	S.out.fx.clear()
	return S


## Every fighter's [menace, power] now.
func snap(S: SimState) -> Array:
	var a: Array = []
	for f in S.fighters:
		a.append([float(f.menace), float(f.power)])
	return a


## The fighters whose menace or power is above what the snapshot held: their slot and what rose.
func raised(S: SimState, before: Array) -> Array:
	var out: Array = []
	for i in range(S.fighters.size()):
		if float(S.fighters[i].menace) > float(before[i][0]):
			out.append("fighter %d menace %.4f -> %.4f" % [i, before[i][0], S.fighters[i].menace])
		if float(S.fighters[i].power) > float(before[i][1]):
			out.append("fighter %d power %.4f -> %.4f" % [i, before[i][1], S.fighters[i].power])
	return out


## Meters low enough that no rise can hide at the cap.
func lower(S: SimState) -> void:
	for f in S.fighters:
		f.menace = 10.0
		f.power = 10.0


func populated(S: SimState, atLeast: float):
	for b in S.buildings:
		if b.popAlive >= atLeast:
			return b
	return null


## True when the text of a function body names a menace or power write.
func feeds_meter(body: String) -> bool:
	return body.contains("menace") or body.contains(".power")


func body_of(src: String, head: String) -> String:
	var i0: int = src.find(head)
	if i0 < 0:
		return ""
	var i1: int = src.find("\nstatic func ", i0 + head.length())
	return src.substr(i0, (i1 if i1 > 0 else src.length()) - i0)


func _init() -> void:
	SimInputData.load_and_apply()
	# ---- 1. behaviour
	var granted_total: float = 0.0
	var kills: int = 0
	for seed_ in [1, 2, 3]:
		for who in [0, 1, -1]:
			var S := fresh(seed_)
			lower(S)
			var cause = S.fighters[who] if who >= 0 else null
			var b = populated(S, 8.0)
			ok(b != null, "seed %d: a building with people to kill" % seed_)
			if b == null:
				continue
			var before: Array = snap(S)
			var cas0: float = S.world.casualties
			var got: float = WorldCollateral.kill(S, b.idx, minf(b.popAlive, 30.0), cause, 0.0, b.x)
			granted_total += got
			kills += 1
			ok(got > 0.0 and S.world.casualties > cas0, "seed %d cause %d: the kill granted casualties (%.2f), so the check is not vacuous" % [seed_, who, got])
			var up: Array = raised(S, before)
			ok(up.is_empty(), "seed %d cause %d: no fighter's menace or power rose from a kill %s" % [seed_, who, str(up)])
	# every building, by each fighter, as a collapse's people would be killed
	var Sw := fresh(4)
	lower(Sw)
	var bw: Array = snap(Sw)
	var ev0: float = Sw.world.evacuated
	var tot: float = 0.0
	for bb in Sw.buildings:
		tot += WorldCollateral.kill(Sw, bb.idx, bb.popAlive, Sw.fighters[1], 0.0, bb.x)
	var allow: float = (Sw.world.evacuated - ev0) * Sw.fighters[1].md.menaceEvac * WorldCollateral.POP_REF / Sw.world.pop0
	var upw: Array = raised(Sw, bw)
	ok(tot > 0.0 and Sw.fighters[1].menace - bw[1][0] <= allow + 0.0001 and Sw.fighters[1].power <= bw[1][1] and Sw.fighters[0].menace <= bw[0][0] and Sw.fighters[0].power <= bw[0][1], "a whole world's buildings killed by the villain (%.1f died, %.1f evacuated): menace rose by no more than the evacuees' share (%.3f of %.3f allowed) and power did not rise %s" % [tot, Sw.world.evacuated - ev0, Sw.fighters[1].menace - bw[1][0], allow, str(upw)])
	# the real route: a building that falls with people in it (damageBuilding), the villain's blow
	var Sd := fresh(5)
	lower(Sd)
	var bd = populated(Sd, 8.0)
	if bd != null:
		var bdb: Array = snap(Sd)
		var c0: float = Sd.world.casualties
		WorldStructures.damageBuilding(Sd, bd, float(bd.maxhp) * 3.0, Sd.fighters[1], "implode", bd.x)
		ok(Sd.world.casualties > c0 or Sd.world.evacuated > 0.0, "a building the villain levels with people in it harms or moves them (casualties %.2f)" % (Sd.world.casualties - c0))
		var allowd: float = Sd.world.evacuated * Sd.fighters[1].md.menaceEvac * WorldCollateral.POP_REF / Sd.world.pop0
		ok(Sd.fighters[1].menace - bdb[1][0] <= allowd + 0.0001 and Sd.fighters[1].power <= bdb[1][1] and Sd.fighters[0].power <= bdb[0][1] and Sd.fighters[0].menace <= bdb[0][0], "the levelled building raised power not at all and menace by no more than the evacuees' share")
	# the control: the old feed's gains put back by hand are flagged
	var Sn := fresh(1)
	lower(Sn)
	var nb: Array = snap(Sn)
	var norm: float = WorldCollateral.POP_REF / Sn.world.pop0
	Sn.fighters[1].menace = minf(100.0, Sn.fighters[1].menace + 5.0 * 0.9 * norm)
	Sn.fighters[1].power = minf(100.0, Sn.fighters[1].power + 5.0 * 0.09 * norm)
	var flagged: Array = raised(Sn, nb)
	ok(flagged.size() == 2, "control: the old feed's menace and power gains are both flagged by the detector (%s)" % str(flagged))
	# ---- 2. the evacuation source is kept
	var Se := fresh(1)
	lower(Se)
	Se.world.cbSum = WorldCollateral.budget(Se) + 1000.0   # no room: everything asked is evacuated
	var be = populated(Se, 3.0)
	if be != null:
		var eb: Array = snap(Se)
		var cas1: float = Se.world.casualties
		var got2: float = WorldCollateral.kill(Se, be.idx, 3.0, Se.fighters[1], 0.0, be.x)
		var rise: float = Se.fighters[1].menace - eb[1][0]
		var want: float = 3.0 * Se.fighters[1].md.menaceEvac * WorldCollateral.POP_REF / Se.world.pop0
		ok(got2 == 0.0 and Se.world.casualties == cas1, "no room: no one died (%.2f)" % got2)
		ok(Se.fighters[1].hasMenace and Se.fighters[1].md.menaceEvac > 0.0, "the villain's evacuation source is in his data")
		ok(absf(rise - want) < 0.001 and rise > 0.0, "three evacuees feed the villain's menace at his data rate (+%.3f, wanted %.3f)" % [rise, want])
		ok(Se.fighters[1].power == eb[1][1] and Se.fighters[0].power == eb[0][1], "evacuees feed no one's power")
	# ---- 3. the code and the data
	var src: String = FileAccess.get_file_as_string("res://sim/world/collateral.gd")
	var feed: String = body_of(src, "static func _feed(")
	ok(feed != "" and not feeds_meter(feed), "_feed names neither menace nor power")
	var writes: int = 0
	var evac_write: bool = false
	var lines: PackedStringArray = src.split("\n")
	for i in range(lines.size()):
		if lines[i].contains(".menace =") or lines[i].contains(".power ="):
			writes += 1
			evac_write = lines[i].contains("evac * cause.md.menaceEvac")
	ok(writes == 1 and evac_write, "collateral.gd's only write to menace or power is the evacuation one (%d writes)" % writes)
	var old_feed: String = "static func _feed(S, n, cause):\n\tif cause != null and cause.hasMenace:\n\t\tcause.menace = jmin(100.0, cause.menace + n * cause.md.menaceCas * norm)\n\t\tcause.power = jmin(100.0, cause.power + n * 0.09 * norm)\n"
	ok(feeds_meter(old_feed), "control: the lint finds the old _feed's menace and power lines")
	var rv = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters/RIVAL/meters.json"))
	var srcs: Array = rv.meters.menace.sources
	var cas_rows: int = 0
	for s in srcs:
		cas_rows += 1 if String(s.event) == "casualty" else 0
	ok(cas_rows == 0 and srcs.size() == 1 and String(srcs[0].event) == "evacuee", "the villain's meters.json has the evacuation source and no casualty source")
	var errs0: int = FighterData.errors().size()
	var old_row := {"menace": {"range": [0.0, 100.0], "start": 0.0, "decay": {"rate": 0.4, "delayTicks": 240}, "sources": [{"event": "casualty", "amount": 0.9, "whose": "self"}]}}
	FighterData.quiet = true   # the control is meant to be rejected: no push_error for it
	FighterData._meters("CONTROL", old_row)
	FighterData.quiet = false
	ok(FighterData.errors().size() > errs0, "control: a menace casualty source (the old row) is rejected as not wired")
	var errs1: int = FighterData.errors().size()
	var new_row := {"menace": {"range": [0.0, 100.0], "start": 0.0, "decay": {"rate": 0.4, "delayTicks": 240}, "sources": [{"event": "evacuee", "amount": 0.45, "whose": "self"}]}}
	FighterData._meters("CONTROL2", new_row)
	ok(FighterData.errors().size() == errs1, "the evacuation row loads without a complaint")
	print("CASUALTYFEED: %d kills over 3 worlds, %.1f people died in them" % [kills, granted_total])
	print("CASUALTYFEED: %d check(s) failed" % _fails)
	quit(1 if _fails > 0 else 0)
