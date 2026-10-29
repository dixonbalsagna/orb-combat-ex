extends SceneTree
## Where SimCore.step's time goes (natively, headless): the tick's own parts, timed one by one over a seeded match, with
## a twin sim stepped by SimCore.step itself and compared by SimHash at the end, so the timed copy of the step is proven
## to be the step. Prints each part's mean per tick in microseconds and its share, the tick's mean, p50 and p99, the
## arena's columns the match ran on, the first live tick's time (the process's first, where a lazy load lands), and the
## match's start (SimCore.beginMatch, a piece a loading frame) timed by MatchJob phase.
##   godot --headless --path . --script res://sim/core/tools/tick_prof.gd -- [--ticks=3600] [--seed=1] [--planet] [--gen2] [--bots]
## Default: AI against AI on the hand-made world. --planet: planet 7, touch-down 3; --gen2: a gen 2 planet (planet 7,
## touch-down 3, arena 2400); --bots: net/'s scripted players (the rollback bench's inputs) instead of the AI.
## Run it on a quiet machine.

const PARTS: Array = ["head", "control", "stepFighter", "dirUpdate", "beamStep", "shots", "water", "mood", "cata+forms", "collateral", "tickMark", "clash", "frozen"]

var acc: Dictionary = {}
var live: bool = false   # the last _step was a live tick (not the intro's, a pause's or hit-stop's)


func _now() -> int:
	return Time.get_ticks_usec()


func _add(k: String, t0: int) -> int:
	var t1: int = _now()
	acc[k] = int(acc.get(k, 0)) + (t1 - t0)
	return t1


## SimCore._step, part by part (keep it in step with sim/core/sim.gd: the twin's hash proves it is).
func _step(S: SimState, inputs) -> void:
	var t: int = _now()
	live = false
	if SimConst.NC != S.arenaCols or WorldBiomes.worldId != S.worldId:
		SimConst.setArena(S.arenaCols)
		WorldBiomes.planetCols = S.planetCols
		WorldBiomes.fineCols = S.fineCols
		WorldClimate.curGen = S.planetGen
		WorldBiomes.worldId = S.worldId
	var dtReal: float = SimConst.DT
	var dt: float = dtReal * S.game.ts
	S.dt = dt
	S.tick += 1
	if SimIntro.tick(S, inputs):
		SimFx.tickMark(S, dt, false)
		_add("frozen", t)
		return
	if SimPause.frozenTick(S):
		if S.epoch != null:
			WorldEpoch.tick(S, false)
		SimFx.tickMark(S, dt, true)
		_add("frozen", t)
		return
	if S.dirS.stop > 0.0:
		S.dirS.stop -= dtReal
		if S.hitstopOn:
			SimHitstop.frozen(S)
		if S.epoch != null:
			WorldEpoch.tick(S, false)
		SimFx.tickMark(S, dt, true)
		_add("frozen", t)
		return
	S.T += dt
	live = true
	if S.epoch != null:
		WorldEpoch.tick(S, DirCalm.hold(S))
	if S.hitstopOn:
		SimHitstop.live(S)
	SimPause.liveTick(S)
	if S.game.ko != null:
		S.game.koT += dt
		if S.game.koT > 2.2:
			S.game.ts = 1.0
	var ord: Array = [0, 1] if S.rng.next() < 0.5 else [1, 0]
	for k in range(2, S.fighters.size()):
		ord.append(k)
	t = _add("head", t)
	for k in ord:
		SimControl.control(S, S.fighters[k], inputs[k] if inputs != null and k < inputs.size() else null)
	t = _add("control", t)
	for f in S.fighters:
		SimFighter.stepFighter(S, f, dt)
	t = _add("stepFighter", t)
	DirExchange.dirUpdate(S, dt)
	t = _add("dirUpdate", t)
	DirBeam.beamStep(S, dt)
	t = _add("beamStep", t)
	SimShots.step(S, dt)
	t = _add("shots", t)
	WorldWater.step(S)
	t = _add("water", t)
	SimMood.tick(S)
	t = _add("mood", t)
	if S.cata != null and S.cata.ashLeft > 0:
		SimCata.tick(S)
	if S.formsOn:
		SimForms.events(S)
	t = _add("cata+forms", t)
	WorldCollateral.tick(S)
	t = _add("collateral", t)
	SimFx.tickMark(S, dt, false)
	t = _add("tickMark", t)
	if S.game.clash != null:
		var c = S.game.clash
		var p: float = SimMathx.jclamp((S.T - c.t0) / c.dur, 0.0, 1.0)
		var mid: float = c.mid if c.mid >= 0.0 else 0.5 + (1.0 if c.aw else -1.0) * 0.35 * p
		var ax: float = c.A.x
		var dx: float = SimWrap.sdx(ax, c.D.x)
		var sx: float = SimWrap.wrap(ax + dx * mid)
		var sz: float = c.A.z + (c.D.z - c.A.z) * mid
		SimFx.spark(S, sx, (c.A.y + (c.D.y - c.A.y) * mid) + 38.0, 3, "#ffffff", 700.0, sz)
		SimFx.shake(S, 7.0, sx, sz)
	_add("clash", t)


func _init() -> void:
	var ticks: int = 3600
	var seed: int = 1
	var setup: Dictionary = {}
	var bots: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--seed="):
			seed = int(a.substr(7))
		elif a == "--planet":
			setup = {"planet": 7, "touch": 3}
		elif a == "--gen2":
			setup = {"planet": 7, "touch": 3, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}
		elif a == "--bots":
			bots = true
	var ai: Dictionary = {"p1": not bots, "p2": not bots}
	var S := SimCore.createSim()
	var job := SimCore.beginMatch(S, seed, ai, setup)   # newMatch's own job, a piece at a time (the loading screen's frames), each timed
	var byPhase: Dictionary = {}   # MatchJob phase -> [pieces, us, the longest piece's us]
	var startUs: int = 0
	while true:
		var ph: int = job.phase
		var p0: int = _now()
		var fin: bool = job.step()
		var us: int = _now() - p0
		startUs += us
		var e: Array = byPhase.get(ph, [0, 0, 0])
		byPhase[ph] = [e[0] + 1, e[1] + us, maxi(e[2], us)]
		if fin:
			break
	var nb: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var log: Array = []
	var times := PackedInt32Array()
	var firstLive: int = -1
	for tk in range(ticks):
		var ins = null
		if bots:
			ins = []
			for k in range(2):
				ins.append(SimIntent.unpack(NetSession.NEUTRAL if tk < 2 else nb[k].next()))
		log.append(ins)
		var t0: int = _now()
		_step(S, ins)
		S.bindCheck()   # as SimCore.step: a tick that replaced the buildings or the trees binds them again
		SimState.sealFresh()
		times.append(_now() - t0)
		if firstLive < 0 and live:
			firstLive = tk
		S.out.feed.clear()
		S.out.fx.clear()
	var R := SimCore.createSim()   # the twin, after the timed run (two sims stepped in turn rebuild World's per-world caches)
	SimCore.newMatch(R, seed, ai, setup)
	for tk in range(ticks):
		SimCore.step(R, log[tk])
		R.out.feed.clear()
		R.out.fx.clear()
	var same: bool = str(SimHash.stateHash(S).gameplay) == str(SimHash.stateHash(R).gameplay)
	var sorted: PackedInt32Array = times.duplicate()
	sorted.sort()
	var tot: float = 0.0
	for v in times:
		tot += float(v)
	print("tick_prof   %s   seed %d   %d ticks   setup %s   inputs %s   twin hash %s" % [OS.get_processor_name(), seed, ticks, str(setup), "bots" if bots else "AI", "same" if same else "DIFFERENT"])
	print("tick mean %.1f us  p50 %d  p99 %d  max %d" % [tot / ticks, sorted[ticks / 2], sorted[mini(ticks - 1, int(ticks * 0.99))], sorted[ticks - 1]])
	print("arena %d columns (SimConst.NC %d)   first live tick: tick %d, %d us" % [S.arenaCols, SimConst.NC, firstLive + 1, times[firstLive] if firstLive >= 0 else -1])
	var phases: Array = byPhase.keys()
	phases.sort()
	var pp := PackedStringArray()
	for ph in phases:
		pp.append("%d: %d x, %.1f ms, longest %.1f" % [ph, byPhase[ph][0], byPhase[ph][1] / 1000.0, byPhase[ph][2] / 1000.0])
	print("start in pieces: %d pieces, %.1f ms; by phase  %s" % [job.pieces, startUs / 1000.0, "   ".join(pp)])
	for k in PARTS:
		var v: float = float(acc.get(k, 0))
		print("  %-12s %7.1f us/tick  %5.1f%%" % [k, v / ticks, 100.0 * v / maxf(1.0, tot)])
	SimCore.dispose(S)
	SimCore.dispose(R)
	quit(0 if same else 1)
