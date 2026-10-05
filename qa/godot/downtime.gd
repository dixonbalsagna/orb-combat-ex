extends SceneTree
## "Nothing running", as Game Design defines it for QA (docs/design/melee-press-feel.md section 2b), and its close-band split.
## Counted: every sim tick from the end of the intro to the KO, except ticks the sim is paused. A tick is RUNNING when, for either fighter:
##   1. an exchange (the old kind, or later a brawl) is in progress (S.dirS.ex);
##   2. an attack is on its way: a rush (lunge, charge, pursuit, zip) or an approach pending (DirBands.pending);
##   3. a shot, a beam or a mine is live, or a fighter holds a beam charge;
##   4. a struggle, a signature or a finisher (they run inside an exchange or a beam);
##   5. a fighter is locked, launched, down, stunned (stagger, daze) or embedded (reeling, knocked back, lifted, buried).
## Otherwise NOTHING IS RUNNING: free flight with no attack, standing, a guard held with nothing coming, channelling, a taunt, the cooldown.
## A running read that the build can give exactly (DirBrawl.busy, once brawl slice B1 has it) should replace this approximation; the grabs, throws
## and carries of the list do not exist yet.
## Reported as seconds for each minute of counted ticks: overall and inside the close band (DirBands.CLOSE, counting only the minutes
## the fighters spend there), as the mean over all counted time, and the median and 90th percentile across matches, for two setups:
##   ai: the AI against the AI (default arm), and press: a pressing script (flies at the rival, a light every `gap` live ticks, takes his forms)
##   against the medium AI (the same player as sim/director/tools/brawl_probe.gd, with the `waited` field).
##   godot --headless --path . --script res://qa/godot/downtime.gd -- <matches> <baseSeed> [--setup=ai|press|both] [--level=medium] [--gap=8]
## Read-only with respect to sim/.


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var pos: Array = []
	var setup := "both"
	var level := "medium"
	var gap := 8
	for a in args:
		if a.begins_with("--setup="):
			setup = a.substr(8)
		elif a.begins_with("--level="):
			level = a.substr(8)
		elif a.begins_with("--gap="):
			gap = int(a.substr(6))
		else:
			pos.append(a)
	var n: int = int(pos[0]) if pos.size() > 0 else 10
	var base: int = int(pos[1]) if pos.size() > 1 else 1
	SimInputData.load_and_apply()
	var dai = load("res://sim/director/ai.gd")
	dai.set("level", level)
	var out := {"downtime": true, "n": n, "level": level, "gap": gap}
	for s in (["ai", "press"] if setup == "both" else [setup]):
		out[s] = _run(s, n, base, gap)
	print(JSON.stringify(out))
	quit()


## True when something is running this tick (the list above).
func _running(S: SimState) -> bool:
	if S.dirS.ex != null:
		return true
	if S.shots.size() > 0 or S.beams.size() > 0:
		return true
	for f in S.fighters:
		if f.rush != null or DirBands.pending(f):
			return true
		if f.state == "locked" or f.state == "launched" or f.state == "down":
			return true
		if f.stunTicks > 0 or f.embedT > 0 or f.beamCharge != null:
			return true
	return false


func _run(setup: String, n: int, base: int, gap: int) -> Dictionary:
	var perMatch: Array = []        # [total idle s a minute, close-band idle s a minute] for each match
	var tot_ticks := 0
	var idle_ticks := 0
	var close_ticks := 0
	var close_idle := 0
	for m in range(n):
		var S := SimCore.createSim()
		if setup == "press":
			SimCore.newMatch(S, base + m, {"p1": false, "p2": true}, {"v2": [true, false]})
		else:
			SimCore.newMatch(S, base + m)
		var me = S.fighters[0]
		var ai = S.fighters[1]
		var lt := 0
		var ticks := 0
		var pending := false
		var carry := 0
		var t := 0
		var ti := 0
		var tc := 0
		var tci := 0
		var wall0: int = Time.get_ticks_msec()
		while S.T < 900.0 and not (S.game.ko != null and S.game.koT > 3.0) and ticks < 400000:
			ticks += 1
			if (ticks & 255) == 0 and Time.get_ticks_msec() - wall0 > 300000:   # a match may take 5 real minutes at most
				break
			var ins = null
			if setup == "press":
				var it := SimIntent.new()
				var dx: float = SimWrap.sdx(me.x, ai.x)
				var dy: float = ai.y - me.y
				it.mx = signf(dx) if absf(dx) > 110.0 else 0.0
				it.my = signf(dy) if absf(dy) > 40.0 else 0.0
				it.dash = absf(dx) > 700.0
				it.light = pending
				it.lightHeld = pending
				it.waited = mini(15, carry) if pending else 0
				if me.act.formReady:
					it.transform = true
				ins = [it, null]
			var stepped: bool = SimCore.step(S, ins) if ins != null else SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
			if not stepped:
				if pending:
					carry += 1
				continue
			lt += 1
			if pending:
				pending = false
				carry = 0
			if setup == "press" and lt % gap == 0:
				pending = true
			# counted: after the intro (a fighter in "intro" or "waiting" is still in it) and before the KO
			if S.game.ko != null or me.state == "intro" or ai.state == "intro" or me.state == "waiting" or ai.state == "waiting":
				continue
			t += 1
			var close: bool = DirBands.band(me, ai) == DirBands.CLOSE
			var run: bool = _running(S)
			if close:
				tc += 1
			if not run:
				ti += 1
				if close:
					tci += 1
		SimCore.dispose(S)
		if t > 0:
			perMatch.append([60.0 * float(ti) / float(t), 60.0 * float(tci) / float(t)])
		tot_ticks += t
		idle_ticks += ti
		close_ticks += tc
		close_idle += tci
	var a_all: Array = []
	var a_close: Array = []
	for p in perMatch:
		a_all.append(p[0])
		a_close.append(p[1])
	a_all.sort()
	a_close.sort()
	return {
		"ticks": tot_ticks,
		"nothingRunningPerMin": snappedf(60.0 * float(idle_ticks) / float(maxi(1, tot_ticks)), 0.1),
		"nothingRunningMedian": snappedf(_q(a_all, 0.5), 0.1), "nothingRunningP90": snappedf(_q(a_all, 0.9), 0.1),
		"closeBandShareOfTime": snappedf(float(close_ticks) / float(maxi(1, tot_ticks)), 0.001),
		"closeBandNothingRunningPerMin": snappedf(60.0 * float(close_idle) / float(maxi(1, tot_ticks)), 0.1),
		"closeBandMedian": snappedf(_q(a_close, 0.5), 0.1), "closeBandP90": snappedf(_q(a_close, 0.9), 0.1),
		"closeBandIdleShareOfCloseTime": snappedf(float(close_idle) / float(maxi(1, close_ticks)), 0.001)}


func _q(a: Array, q: float) -> float:
	return float(a[mini(a.size() - 1, int(float(a.size()) * q))]) if a.size() > 0 else -1.0
