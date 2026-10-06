extends SceneTree
## Scripted players for the agency-pass balance tests (docs/qa/timing-edge-plan.md): a masher, a holder, a tapper with an
## adjustable timing accuracy, a mix, and the AI, played against each other on the live sim through the real input path (a v2
## human slot). Each scripted player keeps the press log the sim will keep (SimPressRead, Controls' classifier and thresholds
## from data/input/timing.json `read`) and reports what the classifier reads, how many of its presses were on the beat, and
## how its exchanges ended, so the same script measures today's sim (no timing rules: expect no edge) and the agency-pass sim.
##   godot --headless --path . --script res://qa/godot/players.gd -- <matches> <baseSeed> --a=<spec> --b=<spec> [--capsec=900] [--wall=300] [--budget=3600]
## Hard caps, so a run cannot hang: --capsec ends a match at that sim time, --wall ends a match after that many real seconds (recorded as a timeout, and counted in wallCapped),
## --budget stops starting matches after that many real seconds (budgetStopped; n is then the matches run and requested the matches asked for).
## A spec is kind[:key=value...]:
##   ai[:level=easy|medium|hard]                     the AI (the director drives the slot)
##   masher[:gap=8][:kind=L|H][:forms=1]             a press every gap live ticks
##   holder[:kind=H|L][:hold=16][:rest=24][:forms=1] press and hold the button hold ticks, then rest
##   holder:timed=1[:acc=100][:win=6]               a hold released on a blow's flash: acc percent of releases land within win ticks of a blow's contact
##                                                   (Game Design: a hold released within 6 ticks of the flash)
##   tapper[:acc=100][:jit=1][:win=4][:mix=L][:idle=24][:forms=1]
##                                                   taps its own blows: acc percent of presses land within the beat window
##                                                   (win ticks, default beatHalf 4, of a blow's contact), the rest miss it by 3 to 10 ticks more;
##                                                   win=3 is the steady mash that lands on the beat (Game Design: within 3 ticks);
##                                                   jit adds a uniform jitter of +-jit ticks to every press; mix is a string of
##                                                   L and H pressed in turn; between exchanges it requests one every idle ticks
##   mix[:mix=LLH][:gap=12][:forms=1]                presses in a fixed pattern, off the beat (a rhythm of its own)
## Add :energy=1 to any scripted player: the energy family is held (RB), so every press is a blast (bolts for a light, a charged shot for a held heavy).
## Add :stick=1 to any scripted player: a heavy press (and a hold) is made with the stick up and toward the rival, the way Orb's earned
## launch is thrown (agency slice 1: a heavy pressed with a stick direction that lands clean launches); without it a heavy is a plain heavy.
## Player A takes slot 0 on odd seeds and slot 1 on even ones, so spawn side and slot cancel. Prints one JSON line.
## Read-only with respect to sim/: it only calls the sim's public functions.

class Pl:
	static var brawl = null     # the DirBrawl script when the build has one (loaded dynamically: an older export has none), for its reads beatAt, busy and inBrawl
	var kind: String = "ai"
	var P: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	var log: Array = []
	var carry: int = -1            # a press the sim did not consume (hit-stop): sent again on the next call
	var carry_hold: bool = false
	var carry_ticks: int = 0       # the frozen steps a carried press has waited (the intent's `waited`: a press is graded at its own tick)
	var plan: Array = []           # [{tick, k}] presses planned against the running exchange's blows
	var last_press: int = -1000
	var last_press_tick: int = -1000   # the S.tick of the last press (the clock a tapping player's real rate counts)
	var brawl_prev_c: int = -1         # the last beatAt read, to see a new blow go on its way
	var brawl_off: int = 0
	var brawl_done: bool = true
	var hold_until: int = -1
	var hold_kind: int = 0
	var pending_rel: int = -1      # a timed hold's release tick
	var rest_until: int = 0
	var pat_i: int = 0
	var contacts: Array = []       # contact ticks (live ticks) of the running exchange's blows, both sides
	var seen_ex = null
	var blows: Array = []          # a tapper's own pending blows: {b: the beat, off: ticks from the contact to press at, done}
	var struggle_cb = null         # the contest beat of the struggle this player is pressing through
	var struggle_off: Array = []
	var struggle_done: Array = []
	var d_in: int = 0              # presses made inside an exchange, as the director graded them (its own beat, not ours)
	var d_on4: int = 0             # ... within beatHalf (4) ticks of a blow's contact (the combo's timed press)
	var d_on2: int = 0             # ... within blurBeatHalf (2) ticks (the perfect blur's beat)
	var beat_seen: int = 0         # beats of the running exchange already read for contacts (links add beats as they are taken)
	var next_idle: int = 0
	var presses: int = 0
	var on_beat: int = 0
	var in_beat_window: int = 0    # presses made during an exchange (the denominator of the on-beat share)
	var styles: Dictionary = {}
	var half: int = 4
	var forms: bool = false
	var level: String = ""

	func setup(spec: String, seed_: int, slot: int) -> void:
		var parts: PackedStringArray = spec.split(":")
		kind = parts[0]
		P = {}
		for i in range(1, parts.size()):
			var kv: PackedStringArray = parts[i].split("=")
			if kv.size() == 2:
				P[kv[0]] = kv[1]
		rng.seed = seed_ * 7919 + slot * 104729 + 13
		forms = int(P.get("forms", "0")) != 0
		level = String(P.get("level", ""))
		half = int(SimPressRead.params()["beatHalf"])

	func scripted() -> bool:
		return kind != "ai"

	func _kind_at(pattern: String) -> int:
		var c: String = pattern.substr(pat_i % maxi(1, pattern.length()), 1)
		pat_i += 1
		return 1 if c == "H" else 0

	## The offset of one planned press from its blow's contact: on the beat with chance acc (within win ticks), else off it.
	func _offset() -> int:
		var acc: float = float(P.get("acc", "100")) / 100.0
		var jit: int = int(P.get("jit", "1"))
		var win: int = int(P.get("win", str(half)))
		var off: int
		if rng.randf() < acc:
			off = rng.randi_range(-win, win)
		else:
			off = (1 if rng.randf() < 0.5 else -1) * rng.randi_range(win + 3, win + 10)
		if jit > 0:
			off += rng.randi_range(-jit, jit)
		return off

	## Plan the presses for a new exchange: one per blow of this player's own side, on or off the beat.
	func _plan_exchange(S, slot: int, lt: int) -> void:
		plan.clear()
		contacts.clear()
		blows.clear()
		beat_seen = 0
		var ex = S.dirS.ex
		if ex == null:
			return
		_read_beats(S, slot, lt)

	## Read the beats not yet seen: each blow is a contact, and each of this player's own blows gets a press planned against it.
	## A chain link's blow is a `chainStrike` beat (or, in a blur string, a strike beat) added when the link is taken, so this
	## runs every call: a timed script follows the links and presses on every blow of its string, as a player watching would.
	func _read_beats(S, slot: int, lt: int) -> void:
		var ex = S.dirS.ex
		if ex == null:
			return
		var mine: String = "A" if ex.A == S.fighters[slot] else "D"
		var pattern: String = String(P.get("mix", "L"))
		while beat_seen < ex.beats.size():
			var b = ex.beats[beat_seen]
			beat_seen += 1
			var linked: bool = b.op == "chainStrike"
			if not linked and (b.op != "strike" or b.args == null):
				continue
			var contact: int = lt + int(roundf((b.t - ex.t) * 60.0))
			contacts.append(contact)
			if linked:
				if mine != "A" or kind == "holder":
					continue
			elif String(b.args.a) != mine:
				continue
			var off: int = _offset()
			if kind == "holder":   # a timed hold: down hold ticks before the release, released at the flash
				var hold_t: int = int(P.get("hold", "16"))
				if contact + off - hold_t > lt:
					plan.append({"tick": contact + off - hold_t, "k": 1 if String(P.get("kind", "H")) == "H" else 0, "rel": contact + off})
			elif kind == "tapper":
				blows.append({"b": b, "off": off, "done": false})   # pressed against the director's own contact tick, recomputed every call
			else:
				plan.append({"tick": maxi(lt + 1, contact + off), "k": _kind_at(pattern)})

	## The steps until beat b runs, counted as the director counts them (DirAlchemy._blows): the exchange's clock gains a tick,
	## then every beat at or before it runs. A press sent now is read in the first of those steps.
	func _steps_to(ex, b) -> int:
		var n: int = 0
		var tt: float = ex.t
		while n <= 40 and (n == 0 or tt < b.t):
			tt += SimConst.DT
			n += 1
		return n

	## The finisher's struggle (Combat's struggle scoring, the contest beat's args): the fighter on the brink presses on the
	## struggle's beats, each within the half-width on the beat with the script's accuracy. Returns true when to press now.
	func _struggle_press(S, slot: int) -> bool:
		var ex = S.dirS.ex
		if ex == null or int(P.get("struggle", "1")) == 0:
			return false
		var cb = null
		for b in ex.beats:
			if not b.done and b.op == "contest":
				cb = b
				break
		if cb == null or not cb.args.has("sOpen"):
			return false
		if (ex.D if cb.args.w == "A" else ex.A) != S.fighters[slot]:
			return false
		var st: Dictionary = DirData.struggle()
		if st.is_empty():
			return false
		if struggle_cb != cb:
			struggle_cb = cb
			struggle_off.clear()
			struggle_done.clear()
			var win: int = mini(int(P.get("win", str(half))), int(st.halfWidthTicks))
			var acc: float = float(P.get("acc", "100")) / 100.0
			for i in range(st.beatTicks.size()):
				struggle_done.append(false)
				if rng.randf() < acc:
					struggle_off.append(rng.randi_range(-win, win))
				else:
					struggle_off.append((1 if rng.randf() < 0.5 else -1) * rng.randi_range(int(st.halfWidthTicks) + 2, int(st.halfWidthTicks) + 8))
		var rel: float = (S.T + SimConst.DT - float(cb.args.sOpen)) * 60.0   # the press is read in the next step
		for i in range(st.beatTicks.size()):
			if not struggle_done[i] and rel >= float(st.beatTicks[i]) + float(struggle_off[i]):
				struggle_done[i] = true
				return true
		return false

	## The tapper inside a brawl. The beat list holds a light's blow for 2 ticks only, so the old oracle never sees it (the script went blind). The
	## director's own read is DirBrawl.beatAt(S, f): the S.tick of his blow on its way (B2: its beat point), or -1. A rhythm player throws one blow
	## at a time, never a flurry (taps slower than 12 ticks are not one): a new blow goes on its way, the next press is planned at its read tick plus
	## the script's offset (accuracy and window as before), and not sooner than `minGap` ticks (default 14) after his last press.
	## With the line free and nothing on its way he starts the next blow after `idle` ticks, as he starts an exchange outside a brawl.
	func _brawl_press(S, slot: int) -> int:
		var f = S.fighters[slot]
		var c: int = int(brawl.call("beatAt", S, f))
		var min_gap: int = int(P.get("mingap", "14"))
		if c >= 0:
			if brawl_prev_c < 0:
				brawl_off = _offset()
				brawl_done = false
			brawl_prev_c = c
			if not brawl_done and S.tick + 1 >= c + brawl_off and S.tick - last_press_tick >= min_gap:
				brawl_done = true
				return _kind_at(String(P.get("mix", "L")))
			return -1
		brawl_prev_c = -1
		if not bool(brawl.call("busy", S, f)) and S.tick - last_press_tick >= maxi(min_gap, int(P.get("idle", "24"))):
			return _kind_at(String(P.get("mix", "L")))
		return -1

	## The press to send this call: -1 none, 0 light, 1 heavy. `hold` is set when the button stays down.
	func decide(S, slot: int, lt: int) -> int:
		if carry >= 0:
			return carry
		match kind:
			"masher":
				var gap: int = int(P.get("gap", "8"))
				# clock=tick: the taps count S.tick, which runs through hit-stop (a player's real tap rate; the brawl's flurry counts it); the default counts live ticks
				var due: bool = (S.tick - last_press_tick >= gap) if String(P.get("clock", "live")) == "tick" else (lt - last_press >= gap)
				if due:
					return 1 if String(P.get("kind", "L")) == "H" else 0
			"mix":
				var gap2: int = int(P.get("gap", "12"))
				if lt - last_press >= gap2:
					return _kind_at(String(P.get("mix", "LLH")))
			"holder":
				if int(P.get("timed", "0")) != 0:
					if S.dirS.ex != seen_ex:
						seen_ex = S.dirS.ex
						_plan_exchange(S, slot, lt)
					while not plan.is_empty() and int(plan[0]["tick"]) < lt - 1:
						plan.pop_front()
					if lt >= hold_until and not plan.is_empty() and int(plan[0]["tick"]) <= lt:
						var pk: Dictionary = plan.pop_front()
						hold_kind = int(pk["k"])
						pending_rel = int(pk["rel"])
						return hold_kind
					if S.dirS.ex == null and lt >= hold_until and lt >= next_idle:   # nothing to time against: request an exchange with an ordinary hold
						hold_kind = 1 if String(P.get("kind", "H")) == "H" else 0
						pending_rel = -1
						return hold_kind
					# inside a brawl there is no flash to release on (the heavy's flash is B2/B3's), so the timed hold plays as a plain one rather than going blind
					if brawl != null and bool(brawl.call("inBrawl", S, S.fighters[slot])) and plan.is_empty() and lt >= hold_until and lt >= rest_until:
						hold_kind = 1 if String(P.get("kind", "H")) == "H" else 0
						pending_rel = -1
						return hold_kind
				elif lt >= hold_until and lt >= rest_until:
					hold_kind = 1 if String(P.get("kind", "H")) == "H" else 0
					return hold_kind
			"tapper":
				if S.dirS.ex != seen_ex:
					seen_ex = S.dirS.ex
					_plan_exchange(S, slot, lt)
				elif S.dirS.ex != null and int(P.get("follow", "1")) != 0:
					_read_beats(S, slot, lt)
				var ex = S.dirS.ex
				if ex != null:
					if _struggle_press(S, slot):
						return 0
					if brawl != null and bool(brawl.call("inBrawl", S, S.fighters[slot])):
						return _brawl_press(S, slot)
					for e in blows:
						if e.done:
							continue
						if e.b.done:
							e.done = true
							continue
						if _steps_to(ex, e.b) <= 1 - int(e.off):
							e.done = true
							return _kind_at(String(P.get("mix", "L")))
				elif lt >= next_idle:
					return _kind_at(String(P.get("mix", "L")))
		return -1

	## The press went through at live tick lt (kind k): log it, read the beat, classify.
	func pressed(k: int, lt: int, held: bool, S = null, slot: int = -1) -> void:
		var beat: int = SimPressRead.beat_offset(lt, contacts)
		SimPressRead.push(log, k, 0, lt, beat)
		last_press = lt
		last_press_tick = S.tick if S != null else lt
		presses += 1
		if S != null and slot >= 0 and S.dirS.ex != null:
			var f = S.fighters[slot]
			var cnt: int = int(f.act.dirI[DirAlchemy.COUNT])
			if cnt > 0:
				var db: int = int(f.act.dirI[DirAlchemy.BEAT0 + (cnt - 1) % DirAlchemy.RING])
				if db != SimPressRead.NO_BEAT:
					d_in += 1
					if absi(db) <= half:
						d_on4 += 1
					if absi(db) <= int(SimPressRead.params().get("blurBeatHalf", 2)):
						d_on2 += 1
		if beat != SimPressRead.NO_BEAT:
			in_beat_window += 1
			if absi(beat) <= half:
				on_beat += 1
		var now_c: int = lt
		if kind == "holder":   # a hold reads as a hold once it has been down holdTicks: classify at the release
			now_c = lt + int(P.get("hold", "16"))
		var st: String = String(SimPressRead.classify(log, now_c, {"offset": 0})["style"])
		styles[st] = int(styles.get(st, 0)) + 1
		if kind == "tapper" or kind == "holder":
			next_idle = lt + int(P.get("idle", "24"))
		if kind == "holder":
			hold_until = pending_rel if (int(P.get("timed", "0")) != 0 and pending_rel > lt) else lt + int(P.get("hold", "16"))
			rest_until = hold_until + int(P.get("rest", "24"))
			SimPressRead.release(log, k, hold_until)

	func is_holding(lt: int) -> bool:
		return kind == "holder" and lt < hold_until


func _init() -> void:
	var pos: Array = []
	var spec_a: String = "masher"
	var spec_b: String = "ai:level=medium"
	var capsec: float = 900.0
	var wall: float = 300.0       # real seconds one match may take before it is ended as a timeout
	var budget: float = 3600.0    # real seconds the whole run may take before it stops starting matches
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wall="):
			wall = float(a.substr(7))
		elif a.begins_with("--budget="):
			budget = float(a.substr(9))
		elif a.begins_with("--a="):
			spec_a = a.substr(4)
		elif a.begins_with("--b="):
			spec_b = a.substr(4)
		elif a.begins_with("--capsec="):
			capsec = float(a.substr(9))
		else:
			pos.append(a)
	var n: int = int(pos[0]) if pos.size() > 0 else 20
	var base: int = int(pos[1]) if pos.size() > 1 else 1
	SimInputData.load_and_apply()
	if ResourceLoader.exists("res://sim/director/brawl.gd"):
		Pl.brawl = load("res://sim/director/brawl.gd")
	var g: Dictionary = _gblank()
	var sums: Array = [_blank(), _blank()]
	var wins: Array = [0, 0]
	var timeouts: int = 0
	var lens: Array = []
	var brinks: Array = []   # brink to KO of each match that ended in a KO: seconds from the loser's first brink_enter
	var t_proc: int = Time.get_ticks_msec()
	var n_done: int = 0
	var wall_capped: int = 0
	var budget_stopped: bool = false
	for i in range(n):
		if float(Time.get_ticks_msec() - t_proc) > budget * 1000.0:
			budget_stopped = true
			break
		var seed: int = base + i
		var slot_a: int = 0 if seed % 2 == 1 else 1
		var res: Dictionary = _match(seed, [spec_a, spec_b], [slot_a, 1 - slot_a], capsec, sums, int(wall * 1000.0), g)
		n_done += 1
		if res.get("wall", false):
			wall_capped += 1
		lens.append(res.t)
		if res.brink >= 0.0:
			brinks.append(res.brink)
		if res.winner < 0:
			timeouts += 1
		else:
			wins[res.winner] += 1
	lens.sort()
	var out: Dictionary = {"players": true, "a": spec_a, "b": spec_b, "n": n_done, "requested": n, "wallCapped": wall_capped, "budgetStopped": budget_stopped, "aWins": wins[0], "bWins": wins[1], "timeouts": timeouts, "medianSec": snappedf(lens[lens.size() >> 1], 0.1) if lens.size() > 0 else -1.0, "brinkToKoMedian": (snappedf(_med(brinks), 0.1) if brinks.size() > 0 else -1.0), "alternationShare": snappedf(float(sums[0].alternations) / maxf(1.0, float(sums[0].pairs)), 0.001), "stats": [_report(sums[0], maxi(1, n_done), g.sec), _report(sums[1], maxi(1, n_done), g.sec)], "brawl": _greport(g)}
	print(JSON.stringify(out))
	quit(0)


func _med(a: Array) -> float:
	var b: Array = a.duplicate()
	b.sort()
	return float(b[b.size() >> 1])


func _blank() -> Dictionary:
	return {"presses": 0, "onBeat": 0, "inExchange": 0, "styles": {}, "exchanges": 0, "launchEnds": 0, "otherEnds": 0, "damage": 0.0, "hits": 0, "heavyHits": 0, "launchesEarned": 0, "launchesTaken": 0, "airCatches": 0, "alternations": 0, "pairs": 0, "flowMax": 0, "flowTo3": 0, "end_launch": 0, "end_knockback": 0, "end_continue": 0, "strings5": 0, "locks5": 0, "dIn": 0, "dOn4": 0, "dOn2": 0, "closes": 0, "strOpens": 0, "strHits": 0, "strStrays": 0}


func _report(s: Dictionary, n: int, secs: float = 0.0) -> Dictionary:
	var ex: float = maxf(1.0, float(s.exchanges))
	return {"pressesPerMatch": snappedf(float(s.presses) / n, 0.1), "onBeatShare": snappedf(float(s.onBeat) / maxf(1.0, float(s.inExchange)), 0.001), "styles": s.styles, "exchangesPerMatch": snappedf(float(s.exchanges) / n, 0.1), "launchShareOfExchanges": snappedf(float(s.launchEnds) / ex, 0.001), "damagePerMatch": snappedf(float(s.damage) / n, 1.0), "damagePerExchange": snappedf(float(s.damage) / ex, 0.1), "hitsPerMatch": snappedf(float(s.hits) / n, 0.1), "heavyHitsPerMatch": snappedf(float(s.heavyHits) / n, 0.1), "launchesEarnedPerMatch": snappedf(float(s.launchesEarned) / n, 0.1), "launchesTakenPerMatch": snappedf(float(s.launchesTaken) / n, 0.1), "endsLaunch": s.end_launch, "endsKnockback": s.end_knockback, "endsContinue": s.end_continue, "flowMax": s.flowMax, "flowTo3PerMatch": snappedf(float(s.flowTo3) / n, 0.1), "blurStrings": s.strings5, "blurLocked": s.locks5, "blurLockShare": snappedf(float(s.locks5) / maxf(1.0, float(s.strings5)), 0.001), "directorOnBeat4": snappedf(float(s.dOn4) / maxf(1.0, float(s.dIn)), 0.001), "directorOnBeat2": snappedf(float(s.dOn2) / maxf(1.0, float(s.dIn)), 0.001), "directorPresses": s.dIn, "struggles": s.strOpens, "struggleHits": s.strHits, "struggleStrays": s.strStrays, "closes": s.closes, "closesPerMin": snappedf(float(s.closes) / maxf(0.001, secs / 60.0), 0.1)}


## The brawl's per-run counts (Game Design's rows, melee-press-feel.md sections 9 and 9d): closes, who made them, the trade's break, momentum.
func _gblank() -> Dictionary:
	return {"sec": 0.0, "brawls": 0, "ends": {}, "blows": {}, "closes": 0, "closesBrink": 0, "closesOneBrink": 0, "heavyStaggers": 0, "tradeBreaks": 0, "onLimit": 0, "late": 0, "momBreaks": 0, "momChanges": 0, "decided": 0, "slot0Wins": 0, "limit": -1, "perfectBlocks": 0, "guardBreaks": 0, "trades": 0, "firstSlotSeq": [], "exact": 0, "draws": 0, "drawsAfterClose": 0, "drawChanges": 0, "leads": 0, "early": 0, "lateTicks": []}


## An event field as an int, 0 when the build's event has no such field.
func _ei(e, k: String) -> int:
	var v = e.get(k)
	return int(v) if v != null else 0


func _p95(a: Array) -> int:
	if a.size() == 0:
		return 0
	var b: Array = a.duplicate()
	b.sort()
	return int(b[mini(b.size() - 1, int(float(b.size()) * 0.95))])


func _greport(g: Dictionary) -> Dictionary:
	var mins: float = maxf(0.001, g.sec / 60.0)
	return {"brawls": g.brawls, "brawlsPerMin": snappedf(float(g.brawls) / mins, 0.1), "ends": g.ends, "blows": g.blows,
		"closes": g.closes, "closesPerMin": snappedf(float(g.closes) / mins, 0.1), "heavyStaggers": g.heavyStaggers,
		"closesByBrinkFighter": g.closesBrink, "closesWhileOneOnBrink": g.closesOneBrink, "brinkCloseShare": snappedf(float(g.closesBrink) / maxf(1.0, float(g.closesOneBrink)), 0.001),
		"tradeBreaks": g.tradeBreaks, "tradeBreaksOnLimit": g.onLimit, "tradeLimit": g.limit, "breakToCloseLate": g.late,
		"momentumBreaks": g.momBreaks, "momentumChanges": g.momChanges, "momentumChangeShare": snappedf(float(g.momChanges) / maxf(1.0, float(g.momBreaks)), 0.001),
		"decided": g.decided, "firstSlotWins": g.slot0Wins, "firstSlotShare": snappedf(float(g.slot0Wins) / maxf(1.0, float(g.decided)), 0.001),
		"perfectBlocks": g.perfectBlocks, "guardBreaks": g.guardBreaks, "trades": g.trades,
		"exactTradeFields": g.exact > 0 and g.exact == g.tradeBreaks, "levelTrades": g.drawsAfterClose, "levelChanges": g.drawChanges, "levelChangeShare": snappedf(float(g.drawChanges) / maxf(1.0, float(g.drawsAfterClose)), 0.001),
		"firstSlotSeq": g.firstSlotSeq, "breaksByLead": g.leads, "breaksByDraw": g.draws, "breaksEarly": g.early, "breakLateMax": (g.lateTicks.max() if g.lateTicks.size() > 0 else 0), "breakLateP95": _p95(g.lateTicks)}


## One match: specs[i] plays slot slots[i]. Returns {winner: 0 or 1 (the spec's index), -1 for a timeout, t}.
func _match(seed: int, specs: Array, slots: Array, capsec: float, sums: Array, wall_ms: int = 300000, g: Dictionary = {}) -> Dictionary:
	var pl: Array = []
	for i in range(2):
		var p := Pl.new()
		p.setup(specs[i], seed, slots[i])
		pl.append(p)
	var lvl: String = ""
	for p in pl:
		if p.kind == "ai" and p.level != "":
			lvl = p.level
	var dai = load("res://sim/director/ai.gd")   # loaded as a resource: a typed class reference would not parse on a sim before step 3
	dai.set("level", lvl)
	var by_slot: Array = [null, null]
	by_slot[slots[0]] = pl[0]
	by_slot[slots[1]] = pl[1]
	var S: SimState = SimCore.createSim()
	var ai: Dictionary = {"p1": not by_slot[0].scripted(), "p2": not by_slot[1].scripted()}
	SimCore.newMatch(S, seed, ai, {"v2": [by_slot[0].scripted(), by_slot[1].scripted()]})
	var lt: int = 0
	var ticks: int = 0
	var cur_ex = null
	var ex_launch: bool = false
	var ex_attacker: int = -1
	var last_att: int = -1
	var ex_hits: int = 0           # damaging strikes the running exchange's attacker has landed (a string of five or more is the blur's whole length)
	var ex_heavies: int = 0
	var ex_locked: bool = false    # the perfect blur locked in this exchange (cue blur_locked)
	var brink_t: Dictionary = {}   # slot -> first brink_enter time
	var ko_t: float = -1.0
	var brink_now := {}            # fighter index -> on the brink now (brink_enter and brink_exit)
	var last_closer: int = -1      # the fighter who made the last close in this brawl
	var tb_tick: int = -1          # the S.tick of a trade's break still waiting for its close
	if not g.is_empty() and g.limit < 0 and Pl.brawl != null:
		g.limit = int(Pl.brawl.call("cfg").flurry.tradeMaxTicks)
	var wall0: int = Time.get_ticks_msec()
	var walled: bool = false
	while S.T < capsec and not (S.game.ko != null and S.game.koT > 3.0) and ticks < 400000:
		ticks += 1
		if (ticks & 255) == 0 and Time.get_ticks_msec() - wall0 > wall_ms:
			walled = true
			break
		var ins: Array = [null, null]
		var sent: Array = [-1, -1]
		var carried: Array = [false, false]
		for slot in range(2):
			var p = by_slot[slot]
			if not p.scripted():
				continue
			carried[slot] = p.carry >= 0
			var it := SimIntent.new()
			if p.carry >= 0:
				it.waited = mini(15, p.carry_ticks)   # a press the freeze held waited this many steps; the sim grades it at its own tick
			if p.forms and S.fighters[slot].act.formReady:
				it.transform = true
			var k: int = p.decide(S, slot, lt)
			if k >= 0:
				if k == 1:
					it.heavy = true
				else:
					it.light = true
			if int(p.P.get("stick", "0")) != 0 and (k == 1 or (p.is_holding(lt) and p.hold_kind == 1)):
				var rival = S.fighters[1 - slot]
				it.mx = 0.8 * SimMathx.jsign(SimWrap.sdx(S.fighters[slot].x, rival.x))
				it.my = 0.7
			if int(p.P.get("energy", "0")) != 0:
				it.mode = 1   # the energy family held: presses are bolts and charged shots, not melee
			if p.is_holding(lt):
				if p.hold_kind == 1 and "heavyHeld" in it:
					it.set("heavyHeld", true)
				elif "lightHeld" in it:
					it.set("lightHeld", true)
			ins[slot] = it
			sent[slot] = k
		var stepped: bool = SimCore.step(S, ins)
		if stepped:
			lt += 1
		for slot in range(2):
			var p = by_slot[slot]
			if not p.scripted():
				continue
			if sent[slot] >= 0:
				if stepped:
					p.carry = -1
					p.pressed(sent[slot], lt, p.kind == "holder", S, slot)
				else:
					p.carry = sent[slot]
					p.carry_ticks = (p.carry_ticks + 1) if carried[slot] else 1
		# the brawl's events (docs/director/brawl-b1.md section 4), counted for Game Design's rows
		if not g.is_empty():
			if tb_tick >= 0 and S.tick - tb_tick > 28:   # 24 ticks, and 4 for a hit-stop (a pressing probe read 25 once)
				g.late += 1
				tb_tick = -2
			for e in S.out.fx:
				if e.type == "brink_enter":
					brink_now[int(e.actor)] = true
				elif e.type == "brink_exit":
					brink_now.erase(int(e.actor))
				elif e.type == "cue":
					var ck: String = str(e.get("kind"))
					if ck == "brawl_start":
						g.brawls += 1
						last_closer = -1
					elif ck == "brawl_end":
						var why: String = str(e.get("text"))
						g.ends[why] = int(g.ends.get(why, 0)) + 1
						tb_tick = -1
						last_closer = -1
					elif ck == "blow":
						var bt: String = str(e.get("text"))
						g.blows[bt] = int(g.blows.get(bt, 0)) + 1
					elif ck == "trade":
						g.trades += 1
					elif ck == "perfect_block":
						g.perfectBlocks += 1
					elif ck == "guard_break":
						g.guardBreaks += 1
					elif ck == "trade_break":
						g.tradeBreaks += 1
						# the break comes on the first live tick at or after the limit (a hit-stop holds the sim), so lateness is counted and a break before the limit is the fault
						var lim: int = _ei(e, "amount") if _ei(e, "amount") > 0 else g.limit
						var late_by: int = _ei(e, "n") - lim
						if late_by < 0:
							g.early += 1
						else:
							g.lateTicks.append(late_by)
						if late_by == 0:
							g.onLimit += 1
						tb_tick = S.tick
						var how: String = str(e.get("text"))
						if how == "lead" or how == "draw":   # the exact fields (Encounter's next slice): who it breaks for, the runs, how it was settled, who closed last
							g.exact += 1
							var kk: int = _ei(e, "k")     # 0 nobody has closed in this brawl, 1 the actor, 2 the target
							if how == "lead":
								g.leads += 1
							else:
								g.draws += 1
								if kk > 0:
									g.drawsAfterClose += 1
									if kk == 2:
										g.drawChanges += 1    # a draw that went against the last closer: the momentum changed hands
						if last_closer >= 0:
							g.momBreaks += 1
							if int(e.actor) != last_closer:
								g.momChanges += 1
					elif ck == "stagger" and str(e.get("text")) == "flurry":
						var closer: int = int(e.target)
						g.closes += 1
						if closer >= 0 and closer < 2 and by_slot[closer].scripted():
							sums[_idx(pl, by_slot[closer])].closes += 1
						if brink_now.has(closer) != brink_now.has(1 - closer):
							g.closesOneBrink += 1
							if brink_now.has(closer):
								g.closesBrink += 1
						last_closer = closer
						if tb_tick >= 0:
							tb_tick = -1
					elif ck == "stagger" and str(e.get("text")) == "heavy":
						g.heavyStaggers += 1
		# exchange endings and per-player counts, from this tick's events
		for e in S.out.fx:
			if e.type == "damage" and e.number and int(e.attacker) >= 0 and int(e.attacker) < 2 and e.amount > 0.0:
				var who = sums[_idx(pl, by_slot[int(e.attacker)])]
				who.damage += e.amount
				who.hits += 1
				if int(e.attacker) == ex_attacker and cur_ex != null:
					ex_hits += 1
					if str(e.get("kind")) == "heavy":
						ex_heavies += 1
				if str(e.get("kind")) == "heavy":
					who.heavyHits += 1
			elif e.type == "brink_enter":
				if not brink_t.has(int(e.actor)):
					brink_t[int(e.actor)] = S.T
			elif e.type == "ko":
				ko_t = S.T
			elif e.type == "struggle_press":
				var sw = sums[_idx(pl, by_slot[int(e.actor)])]
				if str(e.get("kind")) == "hit":
					sw.strHits += 1
				else:
					sw.strStrays += 1
			elif e.type == "cue" and str(e.get("kind")) == "struggle":
				sums[_idx(pl, by_slot[int(e.actor)])].strOpens += 1
			elif e.type == "cue" and str(e.get("kind")) == "blur_locked" and int(e.actor) == ex_attacker and cur_ex != null:
				ex_locked = true
			elif e.type == "exchange_end":   # slice 3: the director's ending of this player's exchange (the actor is the attacker)
				var xw = sums[_idx(pl, by_slot[int(e.actor)])]
				var xk: String = "end_" + str(e.get("kind"))
				xw[xk] = int(xw.get(xk, 0)) + 1
			elif e.type == "flow":   # slice 3: the flow count; nothing but the HUD and QA reads it
				var fwho = sums[_idx(pl, by_slot[int(e.actor)])]
				fwho.flowMax = maxi(int(fwho.flowMax), int(e.n))
				if int(e.n) == 3:
					fwho.flowTo3 += 1
			elif e.type == "launch":
				var victim: int = int(e.actor)
				var lau: int = int(e.target)
				ex_launch = true
				if lau >= 0 and lau < 2:
					sums[_idx(pl, by_slot[lau])].launchesEarned += 1
				sums[_idx(pl, by_slot[victim])].launchesTaken += 1
		S.out.fx.clear()
		S.out.feed.clear()
		if S.dirS.ex != cur_ex:
			if cur_ex != null and ex_attacker >= 0 and (str(cur_ex.kind) == "light" or str(cur_ex.kind) == "heavy"):
				var sm = sums[_idx(pl, by_slot[ex_attacker])]
				if ex_hits >= 5 and ex_heavies == 0:   # a five-blow string with no heavy: the blur's whole length
					sm.strings5 += 1
					if ex_locked:
						sm.locks5 += 1
				if ex_launch:
					sm.launchEnds += 1
				else:
					sm.otherEnds += 1
			cur_ex = S.dirS.ex
			ex_launch = false
			ex_hits = 0
			ex_heavies = 0
			ex_locked = false
			ex_attacker = S.fighters.find(cur_ex.A) if cur_ex != null else -1
			if cur_ex != null and (str(cur_ex.kind) == "light" or str(cur_ex.kind) == "heavy"):
				sums[_idx(pl, by_slot[ex_attacker])].exchanges += 1
				# turn-taking: does the attacker change from one melee exchange to the next (the trade of stomach punches)
				if last_att >= 0:
					sums[0].pairs += 1
					if last_att != ex_attacker:
						sums[0].alternations += 1
				last_att = ex_attacker
	var winner: int = -1
	if S.game.ko != null:
		var loser_slot: int = S.fighters.find(S.game.ko)
		winner = 1 - _idx(pl, by_slot[loser_slot])
	var t: float = S.T
	var brink: float = -1.0
	if S.game.ko != null:
		var ls: int = S.fighters.find(S.game.ko)
		if brink_t.has(ls):
			brink = (ko_t if ko_t >= 0.0 else S.T) - float(brink_t[ls])
	for i in range(2):
		sums[i].presses += pl[i].presses
		sums[i].onBeat += pl[i].on_beat
		sums[i].inExchange += pl[i].in_beat_window
		sums[i].dIn += pl[i].d_in
		sums[i].dOn4 += pl[i].d_on4
		sums[i].dOn2 += pl[i].d_on2
		for st in pl[i].styles:
			sums[i].styles[st] = int(sums[i].styles.get(st, 0)) + int(pl[i].styles[st])
	if not g.is_empty():
		g.sec += t
		if winner >= 0 and S.game.ko != null:
			g.decided += 1
			if 1 - S.fighters.find(S.game.ko) == 0:   # the winner took the first slot (slot 0)
				g.slot0Wins += 1
				g.firstSlotSeq.append(1)
			else:
				g.firstSlotSeq.append(0)
		else:
			g.firstSlotSeq.append(-1)   # no winner (a timeout)
	SimCore.dispose(S)
	return {"winner": winner, "t": t, "brink": brink, "wall": walled}


## The index (0 or 1) of player object p in the pl array of the match, found through the sums' order: players are kept in spec order.
var _pl_ref: Array = []

func _idx(pl: Array, p) -> int:
	return 0 if pl[0] == p else 1
