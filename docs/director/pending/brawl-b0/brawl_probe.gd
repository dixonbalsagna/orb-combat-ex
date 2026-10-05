extends SceneTree
## Read-only probe for the brawl slices (docs/director/brawl-plan.md section 4; melee-press-feel.md sections 2b and 9).
## A pressing player (flies at the rival, a light every `gap` live ticks, takes his forms) against the AI. It reports:
##  - seconds a minute with nothing running: no exchange, no approach, and nobody launched or down;
##  - seconds a minute with no exchange running, and of those the time a fighter is launched or down;
##  - press to contact: from each of his presses to his next blow that lands, in live ticks and in real ticks (S.tick,
##    which runs through hit-stop): the median, the 95th percentile, and the share inside 10 ticks;
##  - exchanges a minute and blows an exchange.
## godot --headless --path . --script res://sim/director/tools/brawl_probe.gd -- <matches> <baseSeed> [--level=medium] [--gap=8]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var base: int = int(args[1]) if args.size() > 1 else 1
	var level := "medium"
	var gap := 8
	for a in args:
		if a.begins_with("--level="):
			level = a.substr(8)
		if a.begins_with("--gap="):
			gap = int(a.substr(6))
	var dai = load("res://sim/director/ai.gd")
	dai.set("level", level)
	var live := 0
	var exTicks := 0
	var idle := 0
	var flight := 0
	var exchanges := 0
	var blows := 0
	var wins := 0
	var secs := 0.0
	var presses := 0
	var latLive: Array = []
	var latReal: Array = []
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, base + m, {"p1": false, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var ai = S.fighters[1]
		var lt := 0
		var ticks := 0
		var pending := false
		var carry := 0   # the frozen steps his press has waited: the intent's `waited`, so it is graded at its own tick
		var waiting: Array = []   # his presses with no blow landed yet: [live tick, real tick]
		while S.T < 900.0 and not (S.game.ko != null and S.game.koT > 3.0) and ticks < 400000:
			ticks += 1
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
			var exWas = S.dirS.ex
			var stepped: bool = SimCore.step(S, [it, null])
			var hit := false
			for e in S.out.fx:
				if e.type == "damage" and e.amount > 0.0 and S.dirS.ex != null:
					blows += 1
					if int(e.attacker) == 0:
						hit = true
			S.out.fx.clear()
			S.out.feed.clear()
			if hit:
				for w in waiting:
					latLive.append(lt - int(w[0]))
					latReal.append(S.tick - int(w[1]))
				waiting.clear()
			if not stepped:
				if pending:
					carry += 1
				continue
			lt += 1
			if pending:
				pending = false
				carry = 0
				presses += 1
				if waiting.size() < 64:
					waiting.append([lt, S.tick])
			if lt % gap == 0:
				pending = true
			if S.dirS.ex != null:
				exTicks += 1
				if exWas == null:
					exchanges += 1
			else:
				var up: bool = ai.state != "launched" and ai.state != "down" and me.state != "launched" and me.state != "down"
				if not up:
					flight += 1
				elif DirBands.who(S) < 0:
					idle += 1
		live += lt
		secs += S.T
		if S.game.ko != null and S.game.ko == ai:
			wins += 1
		SimCore.dispose(S)
	latLive.sort()
	latReal.sort()
	var within := 0
	for v in latLive:
		if int(v) <= 10:
			within += 1
	var pm := func(x: int) -> float: return snappedf(60.0 * float(x) / float(maxi(1, live)), 0.1)
	print(JSON.stringify({
		"n": n, "level": level, "gap": gap, "wins": wins, "meanSec": snappedf(secs / float(n), 0.1),
		"nothingRunningPerMin": pm.call(idle), "noExchangePerMin": pm.call(live - exTicks), "flightPerMin": pm.call(flight),
		"exchangesPerMin": snappedf(3600.0 * float(exchanges) / float(maxi(1, live)), 0.1), "blowsPerExchange": snappedf(float(blows) / float(maxi(1, exchanges)), 0.01),
		"presses": presses, "pressesThatLanded": latLive.size(),
		"pressToContactLive": {"median": _q(latLive, 0.5), "p95": _q(latLive, 0.95)},
		"pressToContactReal": {"median": _q(latReal, 0.5), "p95": _q(latReal, 0.95)},
		"within10LiveShare": snappedf(float(within) / float(maxi(1, presses)), 0.001)}))
	quit()


func _q(a: Array, q: float) -> int:
	return int(a[mini(a.size() - 1, int(float(a.size()) * q))]) if a.size() > 0 else -1
