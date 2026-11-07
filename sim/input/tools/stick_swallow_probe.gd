extends SceneTree
## Where do stick requests die? A bot that flicks the right stick toward the rival every N ticks against the AI (real fights, several seeds), and for every request (rsStart) whether
## the director started a strike (the `stick_start` cue) within 12 / 30 / 90 live ticks, by what the player's fighter was doing when he asked. Then the same with a buffer of B ticks
## replayed by this probe (a stand-in for the smallest version): a request that finds the fighter unable to act is held up to B ticks and asked again each tick until the director starts it.
##   godot --headless --path . --script res://sim/input/tools/stick_swallow_probe.gd
const TICKS: int = 3000


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["quickRead"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	print("== STICK REQUESTS in real fights: a bot flicking toward the rival every 25 ticks, the AI fighting back, 6 seeds x %d ticks ==" % TICKS)
	var all: Dictionary = {}
	for seed_ in [3, 11, 29, 47, 101, 2026]:
		var r: Dictionary = _fight(seed_, 0)
		for k in r:
			all[k] = int(all.get(k, 0)) + int(r[k])
	var buffered: Dictionary = {}
	for window in ([9, 18, 36] if hub_has_buffer() else []):
		var tot: Dictionary = {}
		for seed_ in [3, 11, 29, 47, 101, 2026]:
			var r2: Dictionary = _fight(seed_, window)
			for k in r2:
				tot[k] = int(tot.get(k, 0)) + int(r2[k])
		buffered[window] = tot
	var n: int = int(all.get("req", 0))
	print("requests %d: started within 12 ticks %d (%.0f%%), within 30 %d (%.0f%%), within 90 %d (%.0f%%), never %d (of which some blow of his own within 30 ticks: %d)" % [n, all.get("s12", 0), 100.0 * float(all.get("s12", 0)) / maxf(1.0, n), all.get("s30", 0), 100.0 * float(all.get("s30", 0)) / maxf(1.0, n), all.get("s90", 0), 100.0 * float(all.get("s90", 0)) / maxf(1.0, n), all.get("never", 0), all.get("as_blow", 0)])
	print("of the requests that never started: he was free of any exchange within 9 ticks of the request: %d, within 18: %d, within 36: %d, later: %d, never again before the match ended: %d" % [all.get("free_9", 0), all.get("free_18", 0), all.get("free_36", 0), all.get("free_after", 0), all.get("free_never", 0)])
	var kinds: Array = []
	for k in all:
		if str(k).begins_with("nv_") and (str(k).ends_with("_blow") or str(k).ends_with("_none")):
			kinds.append("%s %d" % [str(k).substr(3), all[k]])
	kinds.sort()
	print("requests that never became a stick strike, by his state (X = in an exchange) and whether he threw a blow of his own within 30 ticks: " + "; ".join(kinds))
	print("of the requests that never became a stick strike: told by a stick_refused cue %d; silent (no strike, no blow of his own within 30 ticks, no cue) %d; stick_refused cues in all %d" % [all.get("told", 0), all.get("silent", 0), all.get("refused_cues", 0)])
	var sil: Array = []
	for k in all:
		if str(k).begins_with("sil_"):
			sil.append("%s %d" % [str(k).substr(4), all[k]])
	sil.sort()
	print("the silent ones, by his state when he asked: " + "; ".join(sil))
	var states: Array = []
	for k in all:
		if str(k).begins_with("st_"):
			states.append("%s %d (never %d)" % [str(k).substr(3), all[k], int(all.get("nv_" + str(k).substr(3), 0))])
	states.sort()
	print("what the fighter was doing when he asked (requests, of which never started): " + "; ".join(states))
	for w in buffered:
		var b2: Dictionary = buffered[w]
		print("with the input buffer at %d ticks (a request waits while he is launched, down or in an intro): requests %d, strikes started %d (was %d), %.1f per 1000 ticks (was %.1f)" % [w, int(b2.get("req", 0)), int(b2.get("strikes", 0)), int(all.get("strikes", 0)), 1000.0 * float(b2.get("strikes", 0)) / (6.0 * TICKS), 1000.0 * float(all.get("strikes", 0)) / (6.0 * TICKS)])
	quit(0)


func _fight(seed_: int, window: int) -> Dictionary:
	var st: Dictionary = SimInputData.timing.get("strike", {})
	st["bufferTicks"] = window
	SimInputData.timing["strike"] = st
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {"p1": false, "p2": true}, su)
	var a = S.fighters[0]
	var res: Dictionary = {}
	var pending: Array = []   # [tick asked, state, answered]
	var held_for: int = 0
	var refire: int = 0
	var strikes: int = 0
	for t in range(TICKS):
		var phase: int = t % 25
		var push: bool = phase < 3
		hub.pad_stick_right(7, 1.0 if push else 0.0, 0.0)
		if hub.has_method("set_can_act"):
			hub.set_can_act(0, not (str(a.state) in ["launched", "down", "intro", "waiting", "dropped"]))   # the host line of the input buffer (parked; only when it is applied)
		# steer toward the rival so "toward" is toward
		var dx: float = SimWrap.sdx(a.x, S.fighters[1].x)
		hub.pad_stick(7, signf(dx) * 0.6, 0.0)
		var i: SimIntent = hub.intent(0)
		var state: String = str(a.state) + (("+exA" if S.dirS.ex.A == a else "+exD") if S.dirS.ex != null else "")   # exA: he is the attacker of the exchange, exD: he is the one attacked
		if i.rsStart:
			pending.append([t, state, -1, -1, -1, -1])
			res["req"] = int(res.get("req", 0)) + 1
			res["st_" + state] = int(res.get("st_" + state, 0)) + 1
		var live: bool = SimCore.step(S, [i, null])
		if live:
			hub.consumed()
		for e in S.out.fx:
			var nm: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
			if nm == "stick_start" and int(e.actor) == 0:
				strikes += 1
				for k in range(pending.size() - 1, -1, -1):   # the cue answers the latest request still waiting, within 90 ticks
					var p = pending[k]
					if int(p[2]) < 0 and t - int(p[0]) <= 90:
						p[2] = t - int(p[0])
						break
			if nm == "stick_refused" and int(e.actor) == 0:
				res["refused_cues"] = int(res.get("refused_cues", 0)) + 1
				for k in range(pending.size() - 1, -1, -1):   # the cue answers the latest request still waiting
					var pr = pending[k]
					if int(pr[5]) < 0 and int(pr[2]) < 0 and t - int(pr[0]) <= 90:
						pr[5] = t - int(pr[0])
						break
			if (nm == "blow" or nm == "shot_fire" or nm == "beam_fire") and int(e.actor) == 0:
				for p in pending:
					if int(p[3]) < 0 and t - int(p[0]) <= 30:
						p[3] = t - int(p[0])
						break
		if str(a.state) == "free" and S.dirS.ex == null:
			for p in pending:
				if int(p[4]) < 0 and t > int(p[0]):
					p[4] = t - int(p[0])   # the first tick after the request he is free of any exchange
		S.out.fx.clear()
		hub.take_haptics()
		if float(S.fighters[0].hp) <= 0.0 or float(S.fighters[1].hp) <= 0.0:
			break
	for p in pending:
		var d: int = int(p[2])
		if d >= 0 and d <= 12:
			res["s12"] = int(res.get("s12", 0)) + 1
		if d >= 0 and d <= 30:
			res["s30"] = int(res.get("s30", 0)) + 1
		if d >= 0 and d <= 90:
			res["s90"] = int(res.get("s90", 0)) + 1
		if (d < 0 or d > 90) and int(p[5]) >= 0:
			res["told"] = int(res.get("told", 0)) + 1   # no strike, but the player was told (stick_refused)
		if (d < 0 or d > 90) and int(p[5]) < 0 and int(p[3]) < 0:
			res["silent"] = int(res.get("silent", 0)) + 1   # no strike, no blow of his own, and nothing told
			var sk: String = "sil_" + str(p[1]).replace("+ex", "X")
			res[sk] = int(res.get(sk, 0)) + 1
		if d < 0 or d > 90:
			var bk: String = "nv_" + str(p[1]).replace("+ex", "X") + ("_blow" if int(p[3]) >= 0 else "_none")
			res[bk] = int(res.get(bk, 0)) + 1
			var fa: int = int(p[4])
			var bucket: String = "free_never" if fa < 0 else ("free_9" if fa <= 9 else ("free_18" if fa <= 18 else ("free_36" if fa <= 36 else "free_after")))
			res[bucket] = int(res.get(bucket, 0)) + 1
		if (d < 0 or d > 90) and int(p[3]) >= 0:
			res["as_blow"] = int(res.get("as_blow", 0)) + 1   # no stick strike, but he threw a blow within 30 ticks of the request
		if d < 0 or d > 90:
			res["never"] = int(res.get("never", 0)) + 1
			res["nv_" + str(p[1])] = int(res.get("nv_" + str(p[1]), 0)) + 1
	res["strikes"] = strikes
	SimCore.dispose(S)
	return res


## Whether the parked input buffer (input-buffer.patch) is in this tree: only then is the buffer experiment meaningful.
func hub_has_buffer() -> bool:
	return SimInputHub.new().has_method("set_can_act")
