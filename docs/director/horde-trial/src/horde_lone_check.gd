extends SceneTree
## One player left up (Game Design, docs/design/horde-trial.md, 2026-11-15): godot --headless --path . --script res://sim/director/tools/horde_lone_check.gd -- [--seeds=1-10] [--lone=off]
## Two medium pads (horde_probe.gd's) play to the middle of wave 3; seat 0 goes down there (the down a last-legs pack blow gives, called as
## the check's staging); seat 1 plays on. QA's row: the pad left alone clears the wave in at least 8 of 10 runs. At the down: the gap back to
## the one-player value, the wave's remaining count x 1/countMul, the live bodies' toughness kept, a new spawn at one-player toughness. At the
## next wave: two-player values back. --lone=off (two.lone false in memory) is the negative control. --idle: seat 0 stops playing at
## mid-wave but stays up (the case in the clips), for information.

const PLAYS: Dictionary = {"horde": true, "intro": false, "planet": 7, "touch": 2, "planetGen": 3, "power": true, "dash": true, "slip": true, "kick": true, "flatOut": 3500.0, "v2": [true, true]}
const WAVE: int = 3
const LIMIT: int = 60 * 60 * 6   # after the down: six minutes to clear the wave

var args: Dictionary = {}
var fails: int = 0


class Pad:
	var seat: int = 0
	var seed: int = 1
	var plans: Dictionary = {}
	var seen: Dictionary = {}
	var lastPress: int = -1000


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
	print(("ok    " if c else "FAIL  ") + what)


func _near(S: SimState, s: int):
	var a = S.fighters[s]
	var best = null
	var bd: float = INF
	for k in range(SimHorde.seats, S.fighters.size()):
		var M = S.fighters[k]
		if M.out or M.hd.phase == 6:
			continue
		var d: float = DirBands.dist(a, M)
		if d < bd:
			bd = d
			best = M
	return best


## horde_probe.gd's medium pad (4 presses a second, defends half).
func _intent(S: SimState, p: Pad, t: int) -> SimIntent:
	var i := SimIntent.new()
	var a = S.fighters[p.seat]
	if a.out or a.hd.phase == 7:
		return i
	var M = _near(S, p.seat)
	var reach: float = DirHorde.lungeReach(S)
	if M != null:
		var d: float = DirBands.dist(a, M)
		var dx: float = SimWrap.sdx(a.x, M.x)
		if d > reach * 0.7:
			i.mx = 1.0 if dx > 0.0 else -1.0
			i.my = clampf((M.y - a.y) / 400.0, -1.0, 1.0)
			i.dash = absf(dx) > 1500.0
	var target = null
	for k in range(SimHorde.seats, S.fighters.size()):
		var f = S.fighters[k]
		if f.out or f.hd.phase != 3 or S.horde.mark[k] != p.seat:
			continue
		var key: int = k * 1000003 + f.hd.at
		if not p.seen.has(key):
			p.seen[key] = t
			var how: int = 0
			if SimRng.keyed(p.seed, "pad.defend", key) < 0.5:
				var u: float = SimRng.keyed(p.seed, "pad.how", key)
				how = 1 if u < 0.6 else (2 if u < 0.8 else 3)
			p.plans[key] = [how, f.hd.at]
		if t - int(p.seen[key]) >= 12 and target == null:
			target = f
	for key in p.plans.keys():
		var pl: Array = p.plans[key]
		var due: int = int(pl[1]) - S.tick
		if due < -3:
			p.plans.erase(key)
			continue
		match int(pl[0]):
			1:
				if due <= 10:
					i.guard = true
					i.guardPress = due == 10
			2:
				if due == 4:
					i.guard = true
					i.guardPress = true
			3:
				if due == 6:
					i.dodge = true
	if i.guard or i.dodge:
		return i
	if t - p.lastPress >= 15 and M != null and (DirBands.dist(a, M) <= reach or target != null):
		p.lastPress = t
		if SimRng.keyed(p.seed, "pad.wide", t) < 0.1:
			return i
		if target != null:
			i.mx = 1.0 if SimWrap.sdx(a.x, target.x) > 0.0 else -1.0
		i.light = true
	return i


## One run: both pads to the middle of wave 3, seat 0 down, seat 1 on. Returns what it read.
func _run(seed: int, idle: bool = false) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, PLAYS)
	var pads: Array = []
	for s in range(2):
		var p := Pad.new()
		p.seat = s
		p.seed = seed * 31 + s
		pads.append(p)
	var d: Dictionary = SimHorde.data()
	var g1: int = int(d.play.gapTicks[DirHorde.level()])
	var r := {"seed": seed, "downAt": -1, "cleared": false, "clearTicks": -1, "seat1Down": false, "gapBefore": -1, "gapAfter": -1, "lone": -1, "up0": -1, "up1": -1,
		"want": -1, "worthKept": true, "seat0DownAt": -1, "spawnWorth": -1.0, "spawnBase": -1.0, "next": {}, "hash": ""}
	var waveCount: int = -1
	var worths: Dictionary = {}
	var t: int = 0
	while t < 60 * 60 * 14:
		var R = S.horde
		if R.wave == WAVE and R.rest == 0 and waveCount < 0:
			waveCount = R.up
		if r.downAt < 0 and R.wave == WAVE and R.rest == 0 and waveCount > 0 and R.up * 2 <= waveCount:
			# the middle of the wave: seat 0 goes down (the down a last-legs pack blow gives)
			r.gapBefore = DirHorde.gapTicks(S)
			r.up0 = R.up
			for k in range(SimHorde.seats, S.fighters.size()):
				var f = S.fighters[k]
				if not f.out:
					worths[k] = f.hd.worth
			r.downAt = t
			if idle:
				pads[0].seat = -1   # --idle: seat 0 stops playing but stays up (the clips' case)
			else:
				DirHorde._down(S, S.fighters[0])
				DirHorde._lone(S)   # (read at once, before any blow: the step's own call is then a no-op)
			r.lone = S.horde.lone
			r.gapAfter = DirHorde.gapTicks(S)
			r.up1 = S.horde.up
			r.want = int(floor(float(r.up0) / float(d.two.countMul) + 0.5))
			for k in worths.keys():
				if not S.fighters[k].out and S.fighters[k].hd.worth != float(worths[k]):
					r.worthKept = false
		var ins: Array = [_intent(S, pads[0], t) if pads[0].seat == 0 else SimIntent.new(), _intent(S, pads[1], t), null, null, null]
		SimCore.step(S, ins)
		t += 1
		for e in S.out.fx:
			if e.type != "cue":
				continue
			if String(e.kind) == "horde_arrive" and r.downAt >= 0 and r.spawnWorth < 0.0 and not r.cleared:
				var f = S.fighters[int(e.actor)]
				r.spawnWorth = f.hd.worth
				r.spawnBase = float(SimHorde.packCfg(f.hd.kind).worth)
		S.out.fx.clear()
		S.out.feed.clear()
		if idle and r.downAt >= 0 and r.seat0DownAt < 0 and S.fighters[0].hd.phase == 7:
			r.seat0DownAt = t - int(r.downAt)   # the idle partner goes down in the end: the rule takes over from there
		if r.downAt >= 0 and not r.cleared:
			if S.horde.rest > 0 or S.horde.wave > WAVE:
				r.cleared = true
				r.clearTicks = t - int(r.downAt)
			elif S.fighters[1].hd.phase == 7 or SimCore.ended(S):
				r.seat1Down = true
				break
			elif t - int(r.downAt) > LIMIT:
				break
		if r.cleared and S.horde.wave == WAVE + 1 and S.horde.rest == 0 and r.next.is_empty():
			r.next = {"lone": S.horde.lone, "size2": S.horde.size2, "gap": DirHorde.gapTicks(S), "seat0Up": S.fighters[0].hd.phase != 7 and not S.fighters[0].out, "g1": g1}
			break
		if SimCore.ended(S):
			break
	r.hash = SimHash.stateHash(S).gameplay
	r.waveCount = waveCount
	SimCore.dispose(S)
	return r


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var on: bool = String(args.get("lone", "on")) != "off"
	if not on:
		SimHorde.data().two["lone"] = false
	var lohi: PackedStringArray = String(args.get("seeds", "1-10")).split("-")
	var cleared: int = 0
	var runs: int = 0
	var first: Dictionary = {}
	var times: Array = []
	for seed in range(int(lohi[0]), int(lohi[lohi.size() - 1]) + 1):
		var r: Dictionary = _run(seed, args.has("idle"))
		runs += 1
		if bool(r.cleared):
			cleared += 1
			times.append(float(r.clearTicks) / 60.0)
		print("      seed %d: wave %d of %d bodies, seat 0 down at %d with %d left; lone %d, gap %d -> %d, left %d -> %d (want %d), live bodies kept %s, first spawn %.1f (one-player %.1f); %s" % [
			seed, WAVE, int(r.waveCount), int(r.downAt), int(r.up0), int(r.lone), int(r.gapBefore), int(r.gapAfter), int(r.up0), int(r.up1), int(r.want), str(r.worthKept),
			float(r.spawnWorth), float(r.spawnBase), ("cleared in %.1f s" % (float(r.clearTicks) / 60.0)) if bool(r.cleared) else ("seat 1 went down" if bool(r.seat1Down) else "not cleared in 6 min")])
		if args.has("idle"):
			print("            (idle partner: seat 0 went down %s)" % (("%.1f s after it stopped" % (float(r.seat0DownAt) / 60.0)) if int(r.seat0DownAt) >= 0 else "never"))
		if first.is_empty() and int(r.downAt) >= 0:
			first = r
	print("      %s: the pad left alone cleared %d of %d; clear times %s" % ["the rule on" if on else "the rule off (negative control)", cleared, runs, str(times.map(func(x): return snappedf(x, 0.1)))])
	if args.has("idle"):
		print("INFO  an idle partner (up, not playing): the other pad cleared %d of %d" % [cleared, runs])
	elif on:
		ok(cleared * 10 >= 8 * runs, "QA's row: a medium pad left alone at mid-wave clears it in at least 8 of 10 (%d of %d)" % [cleared, runs])
		var g1: int = int(SimHorde.data().play.gapTicks[DirHorde.level()])
		ok(int(first.lone) == 1 and int(first.gapAfter) == g1 and int(first.gapBefore) != g1, "at the down: one player up, the gap back to the one-player %d (from %d)" % [g1, int(first.gapBefore)])
		ok(int(first.up1) == int(first.want), "at the down: the wave's remaining count x 1/countMul (%d -> %d)" % [int(first.up0), int(first.up1)])
		ok(bool(first.worthKept), "at the down: the live bodies keep their toughness")
		ok(float(first.spawnWorth) == float(first.spawnBase), "after the down: a new spawn comes at one-player toughness (%.1f)" % float(first.spawnWorth))
		var nx: Dictionary = first.next
		ok(not nx.is_empty() and int(nx.lone) == 0 and int(nx.size2) == 1 and bool(nx.seat0Up) and int(nx.gap) != g1, "the next wave: two-player values back, seat 0 up (gap %s)" % str(nx.get("gap", "?")))
		var again: Dictionary = _run(int(lohi[0]))
		ok(String(again.hash) == String(first.hash), "two runs of seed %d give one hash (%s)" % [int(lohi[0]), String(first.hash)])
	else:
		print("INFO  the rule off: the pad left alone cleared %d of %d" % [cleared, runs])
	print("HORDE LONE: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
