extends SceneTree
## Read-only probe for the brawl slices (docs/director/brawl-plan.md section 4; melee-press-feel.md sections 2b and 9).
## A pressing player (flies at the rival, a light every `gap` ticks, takes his forms) against the AI, or against a
## dummy that never presses. It reports:
##  - seconds a minute with nothing running: no exchange, no approach, and nobody launched or down;
##  - seconds a minute with no exchange running, and of those the time a fighter is launched or down;
##  - the share of live time spent in a brawl; the brawls' length and blows (median), and how they ended; trades,
##    the flurry's closes and guard breaks by who landed them; trades that reached their limit, how late a break
##    came and how long its close took; the second slot's heavies after a close landed on it, and how many reached him;
##    the time from a brawl's knock-back to the next engagement (a brawl, a lunge or a charge, a shot, an exchange);
##  - inside a brawl: his taps a second against his blows that made contact a second, and his damage a second, by the
##    real clock (S.tick, which runs through hit-stop);
##  - press to contact inside a brawl, from the press's own tick to his blow's contact, in real and in live ticks: the
##    median, the 95th percentile, the share inside 4, the share of presses that were thrown as a blow inside 10 and
##    that made contact inside 10, and his state as each press arrived (free, busy with his own blow, reeling, staggered);
##  - over the whole match: exchanges a minute and blows an exchange, as slice B0 measured them.
## godot --headless --path . --script res://sim/director/tools/brawl_probe.gd -- <matches> <baseSeed> [--level=medium]
##   [--gap=8] [--clock=real|live] [--rival=ai|dummy] [--me=player|ai] [--max=900] [--forms=1] [--mix=1]
## --mix=1: the mixing presser (melee-press-feel.md section 9f): once two blows of his string have landed he closes
## about half his strings with an ender, a tapped heavy. The brawl's length and share bands are read on him.
## Nothing running follows section 2b's list: a tick with a shot in the air, a rush on its way or a staggered fighter
## is running. It also counts the perfect blocks, reversals and ripostes inside brawls, and a brawl's 90th percentile.
## --me=ai: an AI match; the rows about his presses then count the first slot's blows only.


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var base: int = int(args[1]) if args.size() > 1 else 1
	var level := "medium"
	var gap := 8
	var realClock := true
	var dummy := false
	var maxT := 900.0
	var forms := true
	var meAi := false
	var mix := false
	for a in args:
		if a.begins_with("--level="):
			level = a.substr(8)
		if a.begins_with("--gap="):
			gap = int(a.substr(6))
		if a.begins_with("--clock="):
			realClock = a.substr(8) != "live"
		if a.begins_with("--rival="):
			dummy = a.substr(8) == "dummy"
		if a.begins_with("--max="):
			maxT = float(a.substr(6))
		if a.begins_with("--me="):
			meAi = a.substr(5) == "ai"
		if a.begins_with("--forms="):
			forms = a.substr(8) != "0"
		if a.begins_with("--mix="):
			mix = a.substr(6) != "0"
	var dai = load("res://sim/director/ai.gd")
	dai.set("level", level)
	var brawlCls = load("res://sim/director/brawl.gd") if ResourceLoader.exists("res://sim/director/brawl.gd") else null
	var live := 0
	var exTicks := 0
	var idle := 0
	var pbN := 0    # perfect blocks inside a brawl
	var rvN := 0    # reversals inside a brawl
	var ripL := 0   # ripostes thrown: lights
	var ripH := 0   # ... heavies
	var idleShots := 0    # ... of which a shot is in the air (running, by section 2b's list)
	var idleRush := 0     # ... of which a fighter is on a rush and no shot is in the air (running)
	var idleStun := 0     # ... of which a fighter is staggered, and neither of those (running)
	var flight := 0
	var exchanges := 0
	var blows := 0
	var wins := 0
	var secs := 0.0
	var brawlLive := 0
	var brawlReal := 0
	var taps := 0          # his presses consumed while a brawl was on
	var contacts := 0      # his blows that made contact while a brawl was on
	var dmg := 0.0         # ... and their damage
	var within10 := 0      # his brawl presses whose blow made contact inside 10 real ticks
	var thrown10 := 0      # his brawl presses that became a blow (were thrown) inside 10 real ticks
	var trades := 0        # pairs of light blows that landed within the trade's ticks of each other
	var allBlows := 0      # blows thrown in brawls, by both
	var closes := [0, 0]   # the flurry's close, by who landed it
	var breaks := [0, 0]   # guards broken by a heavy, by who broke it
	var tradeBreaks := 0   # trades that reached their limit
	var breakLate := 0     # the most ticks a break came after its limit (a hit-stop holds it)
	var breakToClose := 0  # the most ticks from a break to the close it gave
	var breaksEnded := 0   # breaks after which the trade stopped with no close
	var kbGaps: Array = [] # ticks from a brawl's knock-back to the next engagement (a brawl, a lunge or a charge, a shot, an exchange)
	var answers := 0       # heavies the second slot threw within 24 ticks of a close landing on it (the AI's answer)
	var answersLanded := 0 # ... that reached the rival, clean or on his guard, before it was staggered again
	var states: Dictionary = {}   # his brawl presses by his state as the press arrived: free, busy (his own blow), reeling, staggered
	var latLive: Array = []
	var latReal: Array = []
	var lens: Array = []
	var perBrawl: Array = []
	var ends: Dictionary = {}
	var kinds: Dictionary = {}
	var acks: Dictionary = {}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, base + m, {"p1": meAi, "p2": not dummy}, {"v2": [not meAi, dummy]})
		var me = S.fighters[0]
		var ai = S.fighters[1]
		var lt := 0
		var ticks := 0
		var pending := false
		var carry := 0   # the frozen steps his press has waited: the intent's `waited`, so it is graded at its own tick
		var mine: Array = []   # his blows on their way: [the press's own tick, the live tick it was thrown on]
		var breakAt := 0
		var kbAt := 0
		var closedAt := 0
		var answering := false
		var strK := 0          # his strings that reached two landed blows, for the coin
		var decided := false   # this string's coin was tossed
		var wantEnder := false
		var mute := 0          # ticks he doesn't tap after pressing his ender, so the heavy isn't replaced by a held light
		while S.T < maxT and not (S.game.ko != null and S.game.koT > 3.0) and ticks < 400000:
			ticks += 1
			if realClock and ticks % gap == 0:
				pending = true
			var it := SimIntent.new()
			var dx: float = SimWrap.sdx(me.x, ai.x)
			var dy: float = ai.y - me.y
			it.mx = signf(dx) if absf(dx) > 110.0 else 0.0
			it.my = signf(dy) if absf(dy) > 40.0 else 0.0
			it.dash = absf(dx) > 700.0
			if mix and brawlCls != null and S.dirS.ex != null and S.dirS.ex.tpl == "brawl":
				if me.act.dirI[brawlCls.STR_ON] != 1:
					decided = false
					wantEnder = false
				elif not decided and me.act.dirI[brawlCls.STRING_N] >= 2:
					decided = true
					strK += 1
					wantEnder = SimRng.keyed(base + m, "probe.mix", strK) < 0.5
			else:
				decided = false
				wantEnder = false
			if mute > 0:
				mute -= 1
				pending = false
			it.light = pending and not wantEnder
			it.lightHeld = pending and not wantEnder
			if pending and wantEnder:
				it.heavy = true   # a tapped heavy: after two landed blows it is the ender
				wantEnder = false
				mute = 40
			it.waited = mini(15, carry) if pending else 0
			if forms and me.act.formReady:
				it.transform = true
			if breakAt > 0 and S.tick - breakAt > 30:
				breakAt = 0
				breaksEnded += 1
			var exWas = S.dirS.ex
			var inB: bool = brawlCls != null and S.dirS.ex != null and S.dirS.ex.tpl == "brawl" and S.dirS.ex.branch == ""
			var st := "free"
			if inB and pending:
				if me.stunTicks > 0:
					st = "staggered"
				elif int(round(S.T * 60.0)) + 1 < me.act.dirI[brawlCls.REEL_AT]:
					st = "reeling"
				elif me.act.dirI[brawlCls.LINE] != 0 or S.tick + 1 < me.act.dirI[brawlCls.FREE_AT]:
					st = "busy"
			var stepped: bool = SimCore.step(S, [null if meAi else it, SimIntent.new() if dummy else null])
			if inB:
				brawlReal += 1
			for e in S.out.fx:
				if e.type == "damage" and e.amount > 0.0 and S.dirS.ex != null:
					blows += 1
				if answering and e.type == "damage" and e.number and int(e.attacker) == 1 and (e.kind == "heavy" or e.kind == "guard"):
					answersLanded += 1
					answering = false
				if e.type == "damage" and e.number and int(e.attacker) == 0 and not mine.is_empty():
					var w: Array = mine.pop_front()
					contacts += 1
					dmg += e.amount
					latReal.append(S.tick - int(w[0]))
					latLive.append(lt + 1 - int(w[1]))
					if S.tick - int(w[0]) <= 10:
						within10 += 1
				if kbAt > 0 and (e.type == "attack" or (e.type == "cue" and ["brawl_start", "lunge_light", "lunge_heavy", "charge_light", "charge_heavy", "blast_windup", "blast_charge"].has(e.kind))):
					kbGaps.append(S.tick - kbAt)
					kbAt = 0
				if e.type == "cue" and e.kind == "brawl_end" and e.text == "knockback":
					kbAt = S.tick
				if e.type != "cue":
					continue
				if e.kind == "stagger" and e.text == "perfect_block":
					pbN += 1
				if e.kind == "stagger" and e.text == "reversal":
					rvN += 1
				if e.kind == "riposte":
					if e.text == "heavy":
						ripH += 1
					else:
						ripL += 1
				if e.kind == "trade":
					trades += 1
				if e.kind == "trade_break":
					tradeBreaks += 1
					breakLate = maxi(breakLate, int(e.n) - int(e.amount))
					breakAt = S.tick
				if e.kind == "stagger":
					if e.text == "flurry" and breakAt > 0:
						breakToClose = maxi(breakToClose, S.tick - breakAt)
						breakAt = 0
					if int(e.actor) == 1:
						answering = false
						closedAt = S.tick if e.text == "flurry" else 0
				if e.kind == "blow" and int(e.actor) == 1 and e.text == "heavy" and closedAt > 0 and S.tick - closedAt <= 24:
					answers += 1
					answering = true
					closedAt = 0
				if e.kind == "blow" and e.text != "release":
					allBlows += 1
				if e.kind == "stagger" and e.text == "flurry":
					closes[1 - int(e.actor)] += 1
				if e.kind == "guard_break":
					breaks[1 - int(e.actor)] += 1
				if e.kind == "blow" and int(e.actor) == 0 and e.text != "release":
					mine.append([int(e.amount), lt + 1])
					if S.tick - int(e.amount) <= 10:
						thrown10 += 1
					kinds[e.text] = int(kinds.get(e.text, 0)) + 1
				elif e.kind == "press_ack" and int(e.actor) == 0:
					acks[e.text] = int(acks.get(e.text, 0)) + 1
				elif (e.kind == "stagger" or e.kind == "guard_break") and int(e.actor) == 0:
					mine.clear()
				elif e.kind == "brawl_end":
					mine.clear()
					lens.append(int(e.amount))
					perBrawl.append(int(e.x) + int(e.y))
					ends[e.text] = int(ends.get(e.text, 0)) + 1
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
				if inB:
					taps += 1
					states[st] = int(states.get(st, 0)) + 1
			if not realClock and lt % gap == 0:
				pending = true
			if inB:
				brawlLive += 1
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
					if not S.shots.is_empty():
						idleShots += 1
					elif ai.rush != null or me.rush != null or DirZip.zipping(ai) or DirZip.zipping(me):   # a zip, from its tell, is an attack on its way
						idleRush += 1
					elif ai.stunTicks > 0 or me.stunTicks > 0:
						idleStun += 1
		live += lt
		secs += S.T
		if S.game.ko != null and S.game.ko == ai:
			wins += 1
		SimCore.dispose(S)
	latLive.sort()
	kbGaps.sort()
	latReal.sort()
	lens.sort()
	perBrawl.sort()
	var in4 := 0
	for v in latReal:
		if int(v) <= 4:
			in4 += 1
	var pm := func(x: int) -> float: return snappedf(60.0 * float(x) / float(maxi(1, live)), 0.1)
	var bs: float = float(maxi(1, brawlReal)) / 60.0
	print(JSON.stringify({
		"n": n, "level": level, "me": "ai" if meAi else "player", "rival": "dummy" if dummy else "ai", "gap": gap, "clock": "real" if realClock else "live", "wins": wins, "meanSec": snappedf(secs / float(n), 0.1),
		"nothingRunningPerMin": pm.call(idle - idleShots - idleRush - idleStun), "noExchangeUpPerMin": pm.call(idle), "ofWhich": {"shotInAir": pm.call(idleShots), "rush": pm.call(idleRush), "staggered": pm.call(idleStun)}, "noExchangePerMin": pm.call(live - exTicks), "flightPerMin": pm.call(flight),
		"exchangesPerMin": snappedf(3600.0 * float(exchanges) / float(maxi(1, live)), 0.1), "blowsPerExchange": snappedf(float(blows) / float(maxi(1, exchanges)), 0.01),
		"brawlShareOfLive": snappedf(float(brawlLive) / float(maxi(1, live)), 0.001), "brawls": lens.size(),
		"mix": mix, "brawlP90Sec": snappedf(float(_q(lens, 0.9)) / 60.0, 0.01), "brawlMedianSec": snappedf(float(_q(lens, 0.5)) / 60.0, 0.01), "brawlMedianBlows": _q(perBrawl, 0.5), "brawlEnds": ends,
		"tapsPerSec": snappedf(float(taps) / bs, 0.01), "contactsPerSec": snappedf(float(contacts) / bs, 0.01), "damagePerSec": snappedf(dmg / bs, 0.1),
		"blowKinds": kinds, "acks": acks, "tapsInBrawl": taps, "contacts": contacts,
		"pressToContactReal": {"median": _q(latReal, 0.5), "p95": _q(latReal, 0.95)},
		"pressToContactLive": {"median": _q(latLive, 0.5), "p95": _q(latLive, 0.95)},
		"contactWithin4Share": snappedf(float(in4) / float(maxi(1, latReal.size())), 0.001),
		"pressesWithContactIn10Share": snappedf(float(within10) / float(maxi(1, taps)), 0.001),
		"trades": trades, "blowsInBrawls": allBlows, "closes": closes, "guardBreaks": breaks,
		"perfectBlocksInBrawl": pbN, "reversalsInBrawl": rvN, "ripostes": {"light": ripL, "heavy": ripH}, "tradeBreaks": tradeBreaks, "breakLateMax": breakLate, "breakToCloseMax": breakToClose, "breaksWithNoClose": breaksEnded,
		"knockbackToNextSec": {"n": kbGaps.size(), "median": snappedf(float(_q(kbGaps, 0.5)) / 60.0, 0.01), "p90": snappedf(float(_q(kbGaps, 0.9)) / 60.0, 0.01)}, "answerHeavies": answers, "answerHeaviesLanded": answersLanded,
		"pressesThrownIn10Share": snappedf(float(thrown10) / float(maxi(1, taps)), 0.001), "pressStates": states}))
	quit()


func _q(a: Array, q: float) -> int:
	return int(a[mini(a.size() - 1, int(float(a.size()) * q))]) if a.size() > 0 else -1
