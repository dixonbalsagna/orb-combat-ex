extends SceneTree
## The three bark reads (docs/director/bark-reads.md): low_health_swing, exchange_break, after_chain. Seeded AI matches with
## the emitter on and placeholder lines for the three beats only (no draft line is read: Orb marks those):
##   - off: with no lines for the three beats, what is said is the same with the reads as without them;
##   - the sim is untouched: the gameplay hash is the same with the emitter stepping and without it;
##   - from the events alone: draining 1, 7 or 60 ticks at a time says the same lines at the same ticks;
##   - each read says what it claims, checked against the sim at the tick: a low-health speaker's core is battered or worse,
##     a break is a long pulled-back brawl and its speaker one of the two in it, an after-chain blow follows his chain_end;
##   - control: the hp read the sheet first proposed would hold for most blows of a match.
##   godot --headless --path . --script res://sim/director/tools/bark_reads_check.gd -- [--seeds=12345,777,31337] [--ticks=54000]
## Last line: "bark_reads_check: passed" or "bark_reads_check: FAILED (n)".

const READS: Array = ["low_health_swing", "exchange_break", "after_chain"]
var fails: int = 0


func _ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		print("  FAIL ", what)


## Placeholder lines for each read's beat, one a fighter; the text says what it is, and never reaches a screen.
func _over(reads: Dictionary) -> Dictionary:
	var d: Dictionary = NarrativeBarks._load().duplicate(true)
	var beats: Dictionary = {}
	for k in d.get("beats", {}):
		beats[k] = d.beats[k]
	for b in READS:
		var lines: Dictionary = {}
		for id in ["PROTAGONIST", "RIVAL"]:
			var pool: Array = []
			for n in range(6):
				pool.append({"id": b + "_" + str(n), "text": "probe " + b, "cues": [], "source": "probe"})
			lines[id] = pool
		beats[b] = {"lines": lines, "priority": 2, "chance": 1.0}
	return {"enabled": true, "beats": beats, "reads": reads}


## The data file with the three reads' beats left out, so "no lines for the three beats" still holds now that Orb's lines are there.
func _bare(reads: Dictionary) -> Dictionary:
	var d: Dictionary = NarrativeBarks._load().duplicate(true)
	var beats: Dictionary = {}
	for k in d.get("beats", {}):
		if not READS.has(k):
			beats[k] = d.beats[k]
	return {"enabled": true, "beats": beats, "reads": reads}


func _run(seed_: int, ticks: int, over, chunk: int, watch: bool = false) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {}, {})
	var nb: NarrativeBarks = NarrativeBarks.make(S, {}, over) if over != null else null
	var r: Dictionary = {"hits": 0, "hpLow": 0, "chainAt": {}, "bad": [], "ended": []}
	var rd: Dictionary = over.get("reads", {}) if over != null else {}
	var pend: Array = []
	var t: int = 0
	while t < ticks and not (S.game.ko != null and S.game.koT > 3.0):
		SimCore.step(S)
		t += 1
		if watch:
			for e in S.out.fx:
				if str(e.type) == "chain_end":
					r.chainAt[int(e.actor)] = S.tick
				elif str(e.type) == "cue" and str(e.kind) == "brawl_end":
					r.ended = [S.tick, str(e.text), int(e.amount), int(e.actor), int(e.target)]
				elif str(e.type) == "damage" and int(e.attacker) >= 0 and ["light", "medium", "heavy"].has(str(e.kind)):
					var a = S.fighters[int(e.attacker)]
					r.hits += 1
					if a.hp / a.maxhp <= 0.2:
						r.hpLow += 1
		if nb != null:
			pend.append_array(S.out.fx)
			if pend.size() > 0 and t % chunk == 0:
				var n0: int = nb.log.size()
				nb.step(S, pend)
				pend = []
				if watch:
					for l in nb.log.slice(n0):
						var b: String = str(l.beat)
						if b == "low_health_swing" and S.fighters[int(l.slot)].stage[SimWounds.CORE] < 2:
							r.bad.append(l)
						elif b == "after_chain" and int(l.tick) - int(r.chainAt.get(int(l.slot), -1000000)) > int(rd.after_chain.within_ticks):
							r.bad.append(l)
						elif b == "exchange_break":
							var en: Array = r.ended
							if en.is_empty() or int(en[0]) != int(l.tick) or not rd.exchange_break.whys.has(en[1]) or int(en[2]) < int(rd.exchange_break.min_ticks) or not [en[3], en[4]].has(int(l.slot)) or en[3] == en[4]:
								r.bad.append(l)
		S.out.fx.clear()
		S.out.feed.clear()
	if nb != null and pend.size() > 0:
		nb.step(S, pend)
	r["hash"] = str(SimHash.stateHash(S).gameplay)
	r["log"] = nb.log.duplicate(true) if nb != null else []
	r["ticks"] = t
	SimCore.dispose(S)
	return r


func _ev(type: String, f: Dictionary, tick: int) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = type
	e.tick = tick
	for k in f:
		e.set(k, f[k])
	return e


## The negative cases: each read stays silent just past its limit and speaks at it.
func _cases(reads: Dictionary) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 4242, {}, {})
	var over: Dictionary = _over(reads)
	var say = func(nb: NarrativeBarks, evs: Array) -> Array:
		return nb.step(S, evs).map(func(b): return str(b.beat))
	var nb: NarrativeBarks = NarrativeBarks.make(S, {}, over)
	var blow: Dictionary = {"kind": "light", "attacker": 0.0, "victim": 1.0}
	nb.step(S, [_ev("damage", blow, 1)])   # the match's first blow is first_blow's: each emitter here spends it
	_ok(say.call(nb, [_ev("damage", blow, 900)]).is_empty(), "a fresh fighter's blow says nothing")
	nb.step(S, [_ev("region_stage", {"actor": 0.0, "region": "core", "stage": 1}, 1000)])
	_ok(say.call(nb, [_ev("damage", blow, 2000)]).is_empty(), "a bruised core is not low health")
	nb.step(S, [_ev("region_stage", {"actor": 0.0, "region": "arms", "stage": 3}, 3000)])
	_ok(say.call(nb, [_ev("damage", blow, 4000)]).is_empty(), "broken arms are not low health")
	nb.step(S, [_ev("region_stage", {"actor": 0.0, "region": "core", "stage": 2}, 5000)])
	_ok(say.call(nb, [_ev("damage", blow, 6000)]) == ["low_health_swing"], "a battered core's blow is low health")
	_ok(say.call(nb, [_ev("damage", {"kind": "light", "attacker": 1.0, "victim": 0.0}, 12000)]).is_empty(), "the other fighter's blow is not")
	nb.step(S, [_ev("region_stage", {"actor": 0.0, "region": "core", "stage": 1}, 13000)])
	_ok(say.call(nb, [_ev("damage", blow, 20000)]).is_empty(), "a core that has faded back is not")
	nb = NarrativeBarks.make(S, {}, over)
	nb.step(S, [_ev("damage", blow, 1)])
	var within: int = int(reads.after_chain.within_ticks)
	nb.step(S, [_ev("chain_end", {"actor": 0.0, "n": 2}, 1000)])
	_ok(say.call(nb, [_ev("damage", blow, 1001 + within)]).is_empty(), "a blow past the window is not after a chain")
	_ok(say.call(nb, [_ev("damage", blow, 2000)]).is_empty(), "nor is a later one")
	nb.step(S, [_ev("chain_end", {"actor": 0.0, "n": 2}, 20000)])
	_ok(say.call(nb, [_ev("damage", blow, 20000 + within)]) == ["after_chain"], "a blow at the window's end is")
	_ok(say.call(nb, [_ev("damage", blow, 40000)]).is_empty(), "and only the first blow")
	nb = NarrativeBarks.make(S, {}, over)
	nb.step(S, [_ev("damage", blow, 1)])
	var mt: int = int(reads.exchange_break.min_ticks)
	var end := func(why: String, amount: int, tick: int) -> SimState.FxEvent:
		return _ev("cue", {"kind": "brawl_end", "text": why, "amount": float(amount), "actor": 0.0, "target": 1.0}, tick)
	_ok(say.call(nb, [end.call("idle", mt - 1, 1000)]).is_empty(), "a short brawl is no long exchange")
	_ok(say.call(nb, [end.call("signature", mt * 10, 2000)]).is_empty(), "a brawl a signature ends isn't a pull back")
	_ok(say.call(nb, [end.call("launch", mt * 10, 3000)]).is_empty(), "nor one a launch ends")
	_ok(say.call(nb, [end.call("idle", mt, 4000)]) == ["exchange_break"], "a long brawl that lapses is")
	SimCore.dispose(S)


func _line(l: Dictionary) -> String:
	return "%d %d %s %s" % [int(l.tick), int(l.slot), str(l.beat), str(l.line)]


func _initialize() -> void:
	var seeds: Array = [12345, 777, 31337]
	var ticks: int = 54000
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var reads: Dictionary = NarrativeBarks._load().get("reads", {})
	_ok(not reads.is_empty(), "the data file has the reads")
	_ok(not bool(NarrativeBarks._load().get("enabled", true)), "the switch is off in the data file")
	_cases(reads)
	var total: Dictionary = {}
	for sd in seeds:
		var plain: Dictionary = _run(sd, ticks, null, 1)
		var off: Dictionary = _run(sd, ticks, _bare(reads), 1)
		var noReads: Dictionary = _run(sd, ticks, _bare({}), 1)
		_ok(off.log.map(_line) == noReads.log.map(_line), "seed %d: with no lines for the three beats the reads change nothing said" % sd)
		var on: Dictionary = _run(sd, ticks, _over(reads), 1, true)
		_ok(on.hash == plain.hash and off.hash == plain.hash, "seed %d: the gameplay hash is the same with the emitter on" % sd)
		for ch in [7, 60]:
			var c: Dictionary = _run(sd, ticks, _over(reads), ch)
			_ok(c.log.map(_line) == on.log.map(_line), "seed %d: draining %d ticks at a time says the same lines" % [sd, ch])
		_ok(on.bad.is_empty(), "seed %d: every read's bark holds against the sim (%d not): %s" % [sd, on.bad.size(), str(on.bad)])
		var by: Dictionary = {}
		for l in on.log:
			by[str(l.beat)] = int(by.get(str(l.beat), 0)) + 1
		for b in READS:
			total[b] = int(total.get(b, 0)) + int(by.get(b, 0))
		var gapMin: int = 1000000
		var byLine: Dictionary = {}
		for i in range(on.log.size()):
			if i > 0:
				gapMin = mini(gapMin, int(on.log[i].tick) - int(on.log[i - 1].tick))
			var key: String = str(on.log[i].id) + "|" + str(on.log[i].line)
			if byLine.has(key):
				_ok(int(on.log[i].tick) - int(byLine[key]) >= 180 * 60, "seed %d: a line inside its cooldown" % sd)
			byLine[key] = int(on.log[i].tick)
		print("seed ", sd, ": ", on.ticks / 60, " s, ", on.log.size(), " barks, gap >= ", gapMin, " ticks, ", by, " | off ", off.log.size(), " | blows with hp <= 20%: ", on.hpLow, " of ", on.hits)
		_ok(float(on.hpLow) / float(maxi(1, on.hits)) > 0.5, "seed %d: the control: hp under 20%% for most blows" % sd)
	for b in READS:
		_ok(int(total.get(b, 0)) > 0, "%s fired in the seeded matches" % b)
	print("totals over the seeds: ", total)
	if fails == 0:
		print("bark_reads_check: passed")
	else:
		print("bark_reads_check: FAILED (%d)" % fails)
	quit(1 if fails > 0 else 0)
