extends SceneTree
## Where the director's part of the tick goes (natively, headless): Simulation's tick_prof split finer, with each of
## dirUpdate's sub-ticks and the AI's input (in a brawl and out of one) timed on its own. A twin sim stepped by
## SimCore.step is compared by SimHash at the end, so the timed copy of the step is proven to be the step.
##   godot --headless --path . --script res://sim/director/tools/dir_prof.gd -- [--ticks=3600] [--seed=1] [--gen2] [--bots] [--intro]
## Default: AI against AI on the hand-made world. --gen2: a gen 2 planet (planet 7, touch-down 3, arena 2400);
## --bots: net/'s scripted players; --intro: the entrance plays. Prints the tick's mean, p50 and p99 and each part's
## mean in microseconds, largest first. Exits 1 when the twin's hash differs.

var acc: Dictionary = {}
var calls: Dictionary = {}
var nBrawl: int = 0
var nEx: int = 0


func _now() -> int:
	return Time.get_ticks_usec()


func _add(k: String, t0: int) -> int:
	var t1: int = _now()
	acc[k] = int(acc.get(k, 0)) + (t1 - t0)
	calls[k] = int(calls.get(k, 0)) + 1
	return t1


## SimControl.control, with the AI's input timed (keep in step with sim/input/control.gd).
func _control(S: SimState, f, intent) -> void:
	var t: int = _now()
	var i: SimIntent = f.input
	SimIntent.clearIntent(i)
	if S.game.ko != null:
		_add("control.rest", t)
		return
	if f.ai != null:
		var key: String = "ai.brawl" if DirBrawl.inBrawl(S, f) else "ai.free"
		t = _add("control.rest", t)
		DirAI.aiInput(S, f)
		t = _add(key, t)
	elif intent != null:
		SimIntent.applyIntent(i, intent)
	SimWounds.gateIntent(f, i)
	if f.act.v2:
		SimAct.update(S, f, i)
		f.stance = SimAct.stance(S, f, i)
	elif i.stance >= 0.0:
		f.stance = i.stance
	if i.light or i.heavy:
		f.lastAtkT = S.T
	t = _add("control.rest", t)
	if not (i.light or i.heavy or i.sig):
		return
	if i.light:
		DirExchange.requestAttack(S, f, "light")
	elif i.heavy:
		DirExchange.requestAttack(S, f, "heavy")
	elif i.sig:
		DirExchange.requestAttack(S, f, "sig")
	_add("control.request", t)


## DirExchange.dirUpdate and _update, sub-tick by sub-tick (keep in step with sim/director/exchange.gd).
func _dirUpdate(S: SimState, dt: float) -> void:
	var t: int = _now()
	DirLocation.record(S, dt)
	var cap: float = DirData.timeCapAt()
	if cap > 0.0 and not S.game.timeCap and S.T >= cap:
		S.game.timeCap = true
		SimPause.request(S, SimPause.TIMECAP, -1)
		SimEvents.feed(S, "TIME CAP", "every decisive win on the brink is a finisher")
	t = _add("d.location+cap", t)
	DirExchange._transforms(S)
	t = _add("d.transforms", t)
	if S.dirS.cool > 0.0:
		S.dirS.cool -= dt
	DirBands.tick(S)
	t = _add("d.Bands", t)
	DirBrawl.sentTick(S)
	t = _add("d.Brawl.sentTick", t)
	DirBrawl.holdTick(S)
	t = _add("d.Brawl.holdTick", t)
	DirZip.tick(S)
	t = _add("d.Zip", t)
	DirAlchemy.tick(S)
	t = _add("d.Alchemy", t)
	DirBlast.tick(S)
	t = _add("d.Blast", t)
	DirBury.tick(S)
	t = _add("d.Bury", t)
	DirLaunch.tick(S)
	t = _add("d.Launch", t)
	DirRecoil.tick(S)
	t = _add("d.Recoil", t)
	DirWallKick.tick(S)
	t = _add("d.WallKick", t)
	DirChase.tick(S)
	t = _add("d.Chase", t)
	DirExchange._setupLapse(S)
	t = _add("d.setupLapse", t)
	DirExchange._queues(S)
	t = _add("d.queues", t)
	_ex(S, dt)
	t = _now()
	DirWindows.afterTick(S)
	t = _add("d.Windows.afterTick", t)
	DirCalm.tick(S)
	t = _add("d.Calm", t)
	DirBrawl.laTick(S)
	t = _add("d.Brawl.laTick", t)
	DirWater.tick(S)
	t = _add("d.Water", t)
	DirRally.tick(S)
	_add("d.Rally", t)


func _ex(S: SimState, dt: float) -> void:
	var t: int = _now()
	var ex = S.dirS.ex
	if ex == null:
		DirInterrupt.tick(S)
		_add("d.Interrupt", t)
		return
	ex.t += dt
	nEx += 1
	DirInterrupt.tick(S)
	t = _add("d.Interrupt", t)
	DirBrawl.lineEnter(S, ex)
	t = _add("d.Brawl.line", t)
	if DirBrawl.isBrawl(ex):
		nBrawl += 1
	DirBrawl.tick(S, ex)
	t = _add("d.Brawl.tick", t)
	DirBrawl.tellTick(S, ex)
	t = _add("d.Brawl.tellTick", t)
	if S.dirS.ex != ex:
		DirBrawl.lineLeave(S)
		_add("d.Brawl.line", t)
		return
	DirBeamPlay.lateTick(S, ex)
	t = _add("d.BeamPlay.late", t)
	DirMelee.contactTick(S, ex)
	t = _add("d.Melee.contact", t)
	var i: int = 0
	while i < ex.beats.size():
		var b = ex.beats[i]
		if not b.done and b.t <= ex.t:
			b.done = true
			DirExchange.runBeat(S, ex, b)
			if S.dirS.ex != ex:
				t = _add("d.beats", t)
				DirBrawl.lineLeave(S)
				_add("d.Brawl.line", t)
				return
		i += 1
	t = _add("d.beats", t)
	DirBrawl.lineLeave(S)
	t = _add("d.Brawl.line", t)
	DirExchange._struggleTick(S, ex)
	t = _add("d.struggle", t)
	if ex.ext != null and S.T < ex.ext.until:
		var A = ex.A
		var inReach: bool = not (ex.D.state == "launched" and absf(SimWrap.sdx(A.x, ex.D.x)) > DirExchange.CHAIN_REACH)
		var head: Array = SimAct.peek(A)
		var pressed: bool = (not head.is_empty() and int(head[0]) != SimAct.SIG) if A.act.v2 else A.lastAtkT >= ex.ext.start
		if pressed and ex.combo < 5.0 and A.ki >= 6.0 and inReach:
			if A.act.v2:
				var rq: Array = SimAct.pop(A)
				var lp: int = DirAlchemy.at(A, int(rq[3]))
				DirInterrupt.si(A, DirInterrupt.PHRASE_P, lp if lp >= 0 and (lp & 1) == mini(int(rq[0]), 1) else mini(int(rq[0]), 1))
			DirExchange.chain(S, ex)
	elif ex.ext != null and DirExchange._blurDue(S, ex):
		DirExchange._blurEnder(S, ex)
	var pending: bool = false
	for b in ex.beats:
		if not b.done:
			pending = true
			break
	if not pending and not (ex.ext != null and S.T < ex.ext.until) and not DirBrawl.holds(S, ex):
		DirExchange.endEx(S, ex)
	_add("d.chain+end", t)


## SimCore._step (keep in step with sim/core/sim.gd; the twin's hash proves it is). The parts outside the director are
## timed as one.
func _step(S: SimState, inputs) -> void:
	var t: int = _now()
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
	_add("core", t)
	for k in ord:
		_control(S, S.fighters[k], inputs[k] if inputs != null and k < inputs.size() else null)
	t = _now()
	for f in S.fighters:
		SimFighter.stepFighter(S, f, dt)
	t = _add("core", t)
	_dirUpdate(S, dt)
	t = _now()
	DirBeam.beamStep(S, dt)
	SimShots.step(S, dt)
	WorldWater.step(S)
	SimMood.tick(S)
	if S.cata != null and S.cata.ashLeft > 0:
		SimCata.tick(S)
	if S.formsOn:
		SimForms.events(S)
	WorldCollateral.tick(S)
	SimFx.tickMark(S, dt, false)
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
	_add("core", t)


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
		elif a == "--gen2":
			setup.merge({"planet": 7, "touch": 3, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}, true)
		elif a == "--intro":
			setup["intro"] = true
		elif a == "--bots":
			bots = true
	var ai: Dictionary = {"p1": not bots, "p2": not bots}
	# The director reads its data files on first use (the first DirInterrupt.on() parses them, some 200 ms here): a
	# throwaway match warms them, so the means are the tick's own and not the load's.
	var W := SimCore.createSim()
	SimCore.newMatch(W, seed + 1, ai, setup)
	for tk in range(120):
		SimCore.step(W, null)
	SimCore.dispose(W)
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, ai, setup)
	var nb: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var log: Array = []
	var times := PackedInt32Array()
	for tk in range(ticks):
		var ins = null
		if bots:
			ins = []
			for k in range(2):
				ins.append(SimIntent.unpack(NetSession.NEUTRAL if tk < 2 else nb[k].next()))
		log.append(ins)
		var t0: int = _now()
		_step(S, ins)
		SimState.sealFresh()
		times.append(_now() - t0)
		S.out.feed.clear()
		S.out.fx.clear()
	var R := SimCore.createSim()
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
	print("dir_prof   seed %d   %d ticks   setup %s   inputs %s   twin hash %s" % [seed, ticks, str(setup), "bots" if bots else "AI", "same" if same else "DIFFERENT"])
	print("tick mean %.1f us  p50 %d  p99 %d   ticks in an exchange %d, in a brawl %d" % [tot / ticks, sorted[ticks / 2], sorted[mini(ticks - 1, int(ticks * 0.99))], nEx, nBrawl])
	var keys: Array = acc.keys()
	keys.sort_custom(func(a, b): return int(acc[a]) > int(acc[b]))
	for k in keys:
		print("  %-20s %7.1f us/tick  %5.1f%%   %6d calls, %6.1f us a call" % [k, float(acc[k]) / ticks, 100.0 * float(acc[k]) / maxf(1.0, tot), int(calls[k]), float(acc[k]) / maxf(1.0, float(calls[k]))])
	SimCore.dispose(S)
	SimCore.dispose(R)
	quit(0 if same else 1)
