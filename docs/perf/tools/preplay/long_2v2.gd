extends SceneTree
## A long two-fights match, tick by tick (Performance and Platform, 2026-11-07, the EP's brief from Netcode's 2v2 report: "ticks get dearer late in a match").
## Plays the together setup (two fights, hits across, blows from outside, four computer fighters, planet 7 gen 3) from a seed until a team is out or --ticks, and writes per tick the sim's own time in microseconds, for the ticks over --heavy
## microseconds (default 6000) the sim's stage timers (SimCore.stg, so run it on a scratch copy of a tree that docs/perf/tools/scratch-hooks/hook-simtimers.py has timed; it does NOT compile on an untimed tree), and every --every ticks
## (default 300) what the world has grown to: craters, dead buildings, burning trees, columns with rubble, scorch, cracks, deform, water windows, the field's store serial, shots and beams in the air.
##   godot --headless --path <timed scratch tree> --script res://long_2v2.gd -- --out=<file.json> [--seed=1] [--ticks=40000] [--every=300] [--heavy=6000] [--fights=2]
## Run at below-normal priority and alone: its times are CPU times of this process. Writes nothing but --out. INVALID if the machine was above 60% load.

func _init() -> void:
	var outp := "long2v2.json"
	var seed_: int = 1
	var ticks: int = 40000
	var every: int = 300
	var heavy_us: int = 6000
	var fights: int = 2
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			outp = a.substr(6)
		elif a.begins_with("--seed="):
			seed_ = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--every="):
			every = maxi(1, int(a.substr(8)))
		elif a.begins_with("--heavy="):
			heavy_us = int(a.substr(8))
		elif a.begins_with("--fights="):
			fights = 2 if int(a.substr(9)) == 2 else 1
	WorldClimate.useGen(3)
	WorldField.bakeStep(WorldField.of(WorldPlanet.make(7)), 1 << 40)
	var S := SimCore.createSim()
	var setup := {"intro": false, "planet": 7, "touch": 3, "planetGen": 3, "v2": [true, true, true, true], "assists": [[], [], [], []]}
	var ai := {"p1": true, "p2": true}
	if fights == 2:
		setup["fights"] = 2
		setup["cross"] = true
		setup["outside"] = true
		ai = {"p1": true, "p2": true, "p3": true, "p4": true}
	var t_new: int = Time.get_ticks_usec()
	SimCore.newMatch(S, seed_, ai, setup)
	t_new = Time.get_ticks_usec() - t_new
	var us: PackedInt32Array = PackedInt32Array()
	var ser: PackedInt32Array = PackedInt32Array()   # per tick: SimField's memo serial (moves when the frame or the store changes: every column's ground is then read again) and, below, whether the line was turning
	var turning: PackedByteArray = PackedByteArray()
	var heavy := {}
	var growth: Array = []
	var ended_at: int = -1
	for t in range(ticks):
		var a: int = Time.get_ticks_usec()
		SimCore.step(S)
		var d: int = Time.get_ticks_usec() - a
		us.append(d)
		ser.append(SimField._serial)
		turning.append(1 if (S.swing != null and S.swing.active) else 0)
		if d > heavy_us:
			heavy[str(t)] = SimCore.stg.duplicate()
		if t % every == 0:
			growth.append(_grow(S, t))
		for o in _outs(S):
			o.fx.clear()
			o.feed.clear()
		if SimCore.ended(S):
			ended_at = t
			break
	var res := {"seed": seed_, "fights": fights, "ticks": us.size(), "endedAt": ended_at, "newMatchUs": t_new, "us": Array(us), "heavy": heavy, "growth": growth, "serial": Array(ser), "turning": Array(turning)}
	var f := FileAccess.open(outp, FileAccess.WRITE)
	f.store_string(JSON.stringify(res))
	f.close()
	print("long_2v2: seed %d, %d ticks%s, wrote %s" % [seed_, us.size(), (", ended at %d" % ended_at) if ended_at >= 0 else ", not ended", outp.get_file()])
	quit(0)


func _outs(S) -> Array:
	var outs: Array = [S.out]
	if S.stage != null:
		for r in S.stage.fights:
			if r.out != null and r.out != S.out:
				outs.append(r.out)
	return outs


func _nz(a: PackedFloat32Array) -> int:
	var n: int = 0
	for v in a:
		if v != 0.0:
			n += 1
	return n


func _grow(S, t: int) -> Dictionary:
	var dead: int = 0
	for v in S.bAlive:
		if v == 0:
			dead += 1
	var burn: int = 0
	for v in S.tBurn:
		if v > 0.0:
			burn += 1
	return {"t": t, "craters": S.craters.size(), "bDead": dead, "bN": S.bAlive.size(), "treesBurning": burn, "rubbleCols": _nz(S.rubble), "scorchCols": _nz(S.scorch), "crackCols": _nz(S.crack), "deformCols": _nz(S.deform),
		"waterWin": S.waterWin.size(), "serial": SimField.serialOf(S), "shots": S.shots.size(), "beams": S.beams.size()}
