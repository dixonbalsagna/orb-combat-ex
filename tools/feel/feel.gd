extends SceneTree
## Feel replays and the refusal ledger (Tools; docs/tools/feel.md). Plays a saved match of Orb's (the black box file) through the sim on the tree the page was built from, as SimReplay.play does, and reads slot 0, the pad.
##   godot --headless --path <tree copy> --script <this file> -- <match.json> --mode=replay|ledger [--overrides=<file.json>] [--window=240] [--interest=rsStart,sig,special] [--max-forks=120] [--no-fork] [--no-whole]
## replay: the baseline timeline, then the candidate (an override of interrupts.json or timing.json, applied in memory): (a) FORKED, at every press of interest the sim state is snapshotted, the override applied, the next `window` ticks played from the
##   recorded inputs, the state restored and the override taken out; the baseline's own timeline is read over the same window; (b) WHOLE, the match replayed from tick 0 with the override on (open loop: it drifts from Orb's real match).
## ledger: the baseline only: every press of slot 0 and what the game answered, with the tick, the press and the reason.
## Read-only with respect to the project: nothing is written; one JSON line, FEEL <json>, comes back. The sim runs with its own data; only the in-memory override differs.

var SLOT: int = 0               # the pad's slot: the one with most input records (Orb may have taken slot 1), or --slot=N
## press_ack texts that mean the press was not honoured as pressed (the others, chase and held, are the press being answered or kept).
const NOT_HONOURED: Array = ["refused", "double", "zip", "lapsed", "stunned", "chase_no_ki", "chase_late"]
## Intent edges a press is read from, and the name each gets in the ledger.
const EDGES: Array = ["light", "heavy", "sig", "special", "dodge", "guardPress", "rsStart", "transform", "context", "powerPress"]

var rp: Dictionary = {}
var raw: Array = []             # the recorded input records
var mode: String = "replay"
var window: int = 240
var interest: Array = ["rsStart", "sig", "special"]
var max_forks: int = 120
var do_fork: bool = true
var do_whole: bool = true
var overrides: Array = []
var word2: bool = false
var slot_given: bool = false


func _init() -> void:
	var pos: Array = []
	var ovpath: String = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.substr(7)
		elif a.begins_with("--overrides="):
			ovpath = a.substr(12)
		elif a.begins_with("--window="):
			window = int(a.substr(9))
		elif a.begins_with("--interest="):
			interest = a.substr(11).split(",", false)
		elif a.begins_with("--max-forks="):
			max_forks = int(a.substr(12))
		elif a.begins_with("--slot="):
			SLOT = int(a.substr(7))
			slot_given = true
		elif a == "--no-fork":
			do_fork = false
		elif a == "--no-whole":
			do_whole = false
		else:
			pos.append(a)
	SimInputData.load_and_apply()
	word2 = SimInputData.right_stick_on()
	var f := FileAccess.open(pos[0], FileAccess.READ)
	rp = JSON.parse_string(f.get_as_text())
	if rp.has("replay"):
		rp = rp.replay
	raw = rp.inputs
	if not slot_given:
		var cnt: Dictionary = {}
		for r in raw:
			cnt[int(r[1])] = int(cnt.get(int(r[1]), 0)) + 1
		var best: int = -1
		for k in cnt:
			if int(cnt[k]) > best:
				best = int(cnt[k])
				SLOT = int(k)
	if ovpath != "":
		var of := FileAccess.open(ovpath, FileAccess.READ)
		overrides = JSON.parse_string(of.get_as_text())
	var out: Dictionary = {}
	if mode == "ledger":
		out = _ledger()
	else:
		out = _replay()
	out["tree"] = ProjectSettings.globalize_path("res://")
	out["ticks"] = int(rp.ticks)
	out["seed"] = int(rp.seed)
	out["slot"] = SLOT
	print("FEEL " + JSON.stringify(out))
	quit(0)


# ---------------------------------------------------------------- the replay's parts

## A fresh intent from record i (the sim may edit an intent it is given, so no two runs share one).
func _intent(i: int):
	var inp: Array = raw[i]
	var p: int = SimReplay.join(inp[2], inp[3])
	if p == -1:
		return null
	var it = SimIntent.unpack(p)
	if inp.size() == 5 and it != null:
		SimIntent.unpack2(int(inp[4]), it)
	return it


func _new_sim() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, int(rp.seed), rp.ai, rp.get("setup", {}))
	return S


## The feed of a match: where its input and toggle records are, and the intent each slot holds.
class Feed:
	var ii: int = 0
	var ti: int = 0
	var idx: Array = []         # the record each slot's current intent came from, -1 for none
	var cur: Array = []
	func copy() -> Feed:
		var c := Feed.new()
		c.ii = ii
		c.ti = ti
		c.idx = idx.duplicate()
		c.cur = []
		c.cur.resize(cur.size())
		return c


func _feed_new(S: SimState) -> Feed:
	var fd := Feed.new()
	var slots: int = SimStage.slotCount(S)
	fd.cur.resize(slots)
	fd.idx.resize(slots)
	fd.idx.fill(-1)
	return fd


## Applies tick t's records to the feed (and the AI toggles to S). Returns the edge names slot 0 pressed this tick.
func _feed_to(S: SimState, fd: Feed, t: int) -> Array:
	var edges: Array = []
	while fd.ti < rp.toggles.size() and int(rp.toggles[fd.ti][0]) == t:
		SimCore.toggleAI(S, int(rp.toggles[fd.ti][1]))
		fd.ti += 1
	while fd.ii < raw.size() and int(raw[fd.ii][0]) == t:
		var slot: int = int(raw[fd.ii][1])
		var it = _intent(fd.ii)
		fd.cur[slot] = it
		fd.idx[slot] = fd.ii
		if slot == SLOT and it != null:
			for k in EDGES:
				if it.get(k):
					edges.append(k)
		fd.ii += 1
	return edges


## A fork's feed: the same position, with fresh intents rebuilt from the records the slots hold.
func _feed_fork(fd: Feed) -> Feed:
	var c: Feed = fd.copy()
	for s in range(c.cur.size()):
		if c.idx[s] >= 0:
			c.cur[s] = _intent(c.idx[s])
	return c


# ---------------------------------------------------------------- the meter

## What a tick showed, as sparse rows [tick, key, amount]; windows sum rows by tick.
class Meter:
	var rows: Array = []
	var side: int = 0
	var lastTaken: int = -1000
	func add(t: int, key: String, amt: float = 1.0) -> void:
		rows.append([t, key, amt])


func _reason(e) -> String:
	var k: String = str(e.kind)
	if k == "press_ack":
		return "press_" + str(e.text) + "/" + str(e.source)
	if k == "stick_refused":
		return "stick/" + str(e.source)
	var s: String = str(e.source) if str(e.source) != "" else str(e.text)
	return k + ("/" + s if s != "" else "")


func _refusal(e) -> bool:
	var k: String = str(e.kind)
	if k == "press_ack":
		return NOT_HONOURED.has(str(e.text))
	return k.ends_with("_refused")


## Reads one stepped tick into the meter: beams, refusals by reason, hits, hits taken, clean hits, time without control, side swaps.
func _read(S: SimState, t: int, m: Meter) -> void:
	for e in S.out.fx:
		if e.type == "cue":
			var who: int = int(e.actor)
			var k: String = str(e.kind)
			if k == "beam_fire":
				m.add(t, "beams" if who == SLOT else "foeBeams")
			elif k == "driver_fire" and who == SLOT:
				m.add(t, "driverFires")
			elif who == SLOT and _refusal(e):
				m.add(t, "refused")
				m.add(t, "refused:" + _reason(e))
		elif e.type == "damage":
			var at: int = int(e.attacker)
			var vi: int = int(e.victim)
			if at == SLOT and vi != SLOT:
				m.add(t, "hits")
				if t - m.lastTaken > 30:
					m.add(t, "cleanHits")
			elif vi == SLOT and at != SLOT:
				m.add(t, "hitsTaken")
				m.lastTaken = t
	var f = S.fighters[SLOT]
	if f.state == "locked" or f.state == "launched" or f.state == "down" or f.stunTicks > 0 or f.embedT > 0:
		m.add(t, "noControl")
	m.add(t, "ticks")
	if S.fighters.size() > 1:
		var d: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)
		var sd: int = 0
		if d > 40.0:
			sd = 1
		elif d < -40.0:
			sd = -1
		if sd != 0:
			if m.side != 0 and sd != m.side:
				m.add(t, "swaps")
			m.side = sd


## Sums a meter's rows over ticks [a, b) into a Dictionary key -> amount.
func _sum(m: Meter, a: int, b: int) -> Dictionary:
	var d: Dictionary = {}
	for r in m.rows:
		if int(r[0]) >= a and int(r[0]) < b:
			d[r[1]] = float(d.get(r[1], 0.0)) + float(r[2])
	return d


func _add_into(dst: Dictionary, src: Dictionary) -> void:
	for k in src:
		dst[k] = float(dst.get(k, 0.0)) + float(src[k])


# ---------------------------------------------------------------- overrides

func _root(file: String):
	if file == "data/input/timing.json":
		return SimInputData.timing
	if file == "data/director/interrupts.json":
		return DirInterrupt.data()
	return null


func _supported() -> bool:
	for o in overrides:
		if _root(str(o.file)) == null:
			return false
	return true


## Puts the overrides into the live data; the undo list comes back.
func _apply() -> Array:
	var undo: Array = []
	var timing: bool = false
	for o in overrides:
		var file: String = str(o.file)
		var path: Array = o.path
		var targets: Array = [_root(file)]
		if file == "data/input/timing.json":
			timing = true
			if str(path[0]) == "perfectBlock":
				targets.append(DirInterrupt.data().get("timing", {}))
		for r in targets:
			var d: Dictionary = r
			for i in range(path.size() - 1):
				var k: String = str(path[i])
				if not (d.get(k) is Dictionary):
					undo.append([d, k, d.has(k), d.get(k)])
					d[k] = {}
				d = d[k]
			var last: String = str(path[path.size() - 1])
			undo.append([d, last, d.has(last), d.get(last)])
			d[last] = o.value
	if timing:
		SimInputData.invalidate()
	return undo


func _undo(undo: Array) -> void:
	for i in range(undo.size() - 1, -1, -1):
		var u: Array = undo[i]
		if u[2]:
			u[0][u[1]] = u[3]
		else:
			u[0].erase(u[1])
	SimInputData.invalidate()


# ---------------------------------------------------------------- replay mode

## The baseline timeline: Orb's match on the recording tree. Returns {meter, forks: [[t, edges, snapshot-less meter window...]]}; with `forkOv`, every press of interest forks the candidate.
func _run_timeline(ov_on: bool, fork: bool) -> Dictionary:
	var undo: Array = []
	if ov_on:
		undo = _apply()
	var S: SimState = _new_sim()
	var fd: Feed = _feed_new(S)
	var m := Meter.new()
	var forks: Array = []
	var n: int = int(rp.ticks)
	var stride: int = 1
	if fork:
		stride = maxi(1, int(ceil(float(_interest_count()) / float(max_forks))))   # over the cap, the presses are thinned evenly
	var seen: int = 0
	for t in range(n):
		var edges: Array = _feed_to(S, fd, t)
		if fork:
			var hit: String = ""
			for k in edges:
				if interest.has(k):
					hit = k
					break
			if hit != "" and t + 1 < n:
				seen += 1
				if (seen - 1) % stride == 0:
					var snap: NetSnapshot = NetSnapshot.take(S)
					var fk: Feed = _feed_fork(fd)
					var fmx := Meter.new()
					fmx.side = m.side
					fmx.lastTaken = m.lastTaken
					var undo2: Array = _apply()
					var end: int = mini(n, t + window)
					for u in range(t, end):
						if u > t:
							_feed_to(S, fk, u)
						SimCore.step(S, fk.cur)
						_read(S, u, fmx)
						S.out.fx.clear()
						S.out.feed.clear()
					_undo(undo2)
					NetSnapshot.restore(S, snap)
					forks.append({"t": t, "press": hit, "edges": edges, "cand": _sum(fmx, t, end), "end": end})
		SimCore.step(S, fd.cur)
		_read(S, t, m)
		S.out.fx.clear()
		S.out.feed.clear()
	var final: String = SimHash.stateHash(S).gameplay
	SimCore.dispose(S)
	if ov_on:
		_undo(undo)
	return {"meter": m, "forks": forks, "final": final}


## How many of slot 0's records carry an edge of interest.
func _interest_count() -> int:
	var c: int = 0
	for i in range(raw.size()):
		if int(raw[i][1]) != SLOT:
			continue
		var it = _intent(i)
		if it == null:
			continue
		for k in interest:
			if it.get(k):
				c += 1
				break
	return c


## Whether this tree reproduces the saved match: the saved final hash against the replay's. A match cut short saved none (checked false).
func _recorded(got: String) -> Dictionary:
	var saved: String = str(rp.get("final", ""))
	return {"final": saved, "got": got, "checked": saved != "", "exact": saved != "" and saved == got}


func _tot(m: Meter) -> Dictionary:
	return _sum(m, 0, 1 << 30)


func _replay() -> Dictionary:
	var out: Dictionary = {"mode": "replay", "overrides": overrides, "window": window, "interest": interest}
	var supported: bool = _supported()
	out["inProcess"] = supported
	# baseline: Orb's match on this tree, with the forks of the candidate
	var base: Dictionary = _run_timeline(false, do_fork and supported and not overrides.is_empty())
	var bm: Meter = base.meter
	out["recorded"] = _recorded(base.final)
	out["baselineWhole"] = _tot(bm)
	var forks: Array = base.forks
	var sum_b: Dictionary = {}
	var sum_c: Dictionary = {}
	var rows: Array = []
	for fk in forks:
		var b: Dictionary = _sum(bm, int(fk.t), int(fk.end))
		_add_into(sum_b, b)
		_add_into(sum_c, fk.cand)
		rows.append({"t": fk.t, "press": fk.press, "base": b, "cand": fk.cand})
	out["forks"] = {"count": forks.size(), "baseline": sum_b, "candidate": sum_c, "rows": rows}
	if do_whole and not overrides.is_empty() and supported:
		var cand: Dictionary = _run_timeline(true, false)
		out["candidateWhole"] = _tot(cand.meter)
		out["candidateFinal"] = cand.final
	return out


# ---------------------------------------------------------------- ledger mode

## An answer (a cue of his own, or a blow he landed) goes to the oldest open press with no answer yet, else to the latest: three presses and one blow leave two unanswered, as the rule "each press is a blow" reads it.
func _credit(open: Array, kind: String) -> void:
	if open.is_empty():
		return
	var target = open[open.size() - 1]
	for row in open:
		if row.acts == 0 and row.refused.is_empty():
			target = row
			break
	target.acts += 1
	if kind != "":
		target.cues.append(kind)


## Every press of the pad and what came of it: honoured (an answer within `look` ticks), refused (the game said no, with the reason) or silent (nothing at all).
func _ledger() -> Dictionary:
	var undo: Array = []
	if not overrides.is_empty() and _supported():
		undo = _apply()
	var S: SimState = _new_sim()
	var fd: Feed = _feed_new(S)
	var look: int = 12
	var presses: Array = []        # {t, press, ...}
	var open: Array = []
	var n: int = int(rp.ticks)
	for t in range(n):
		var edges: Array = _feed_to(S, fd, t)
		for k in edges:
			var row: Dictionary = {"t": t, "press": k, "state": S.fighters[SLOT].state, "ki": int(S.fighters[SLOT].ki), "cues": [], "refused": [], "acts": 0}
			var it = fd.cur[SLOT]
			if it != null:
				row["rs"] = [int(it.rsDir), int(it.rsLevel), int(it.rsMask)] if k == "rsStart" else []
			presses.append(row)
			open.append(row)
		SimCore.step(S, fd.cur)
		for e in S.out.fx:
			if e.type == "cue" and int(e.actor) == SLOT:
				if _refusal(e):
					if not open.is_empty():
						open[open.size() - 1].refused.append(_reason(e))   # a refusal answers the latest press
				else:
					_credit(open, str(e.kind))
			elif e.type == "damage" and int(e.attacker) == SLOT:
				_credit(open, "")
		var still: Array = []
		for row in open:
			if t - int(row.t) <= look:
				still.append(row)
		open = still
		S.out.fx.clear()
		S.out.feed.clear()
	var final: String = SimHash.stateHash(S).gameplay
	SimCore.dispose(S)
	if not undo.is_empty():
		_undo(undo)
	var rows: Array = []
	for row in presses:
		var verdict: String = "honoured"
		if row.refused.size() > 0 and row.acts == 0:
			verdict = "refused"
		elif row.refused.size() > 0:
			verdict = "partly"
		elif row.acts == 0:
			verdict = "silent"
		rows.append({"t": row.t, "press": row.press, "verdict": verdict, "reasons": row.refused, "cues": row.cues.slice(0, 4), "state": row.state, "ki": row.ki, "rs": row.get("rs", [])})
	return {"mode": "ledger", "presses": rows, "recorded": _recorded(final)}

