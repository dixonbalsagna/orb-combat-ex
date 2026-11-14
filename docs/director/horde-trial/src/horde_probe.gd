extends SceneTree
## The horde trial's probe (docs/ep/proposals/horde-trial-design.md sections 8.1 and 9; scratch only):
## godot --headless --path . --script res://sim/director/tools/horde_probe.gd -- [--pads=medium,idle,guard,dodge] [--seeds=1] [--two] [--ticks=43300]
## Scripted pads play a horde run to its end; the probe reads the run: readings 5, 6, 7, 21, 22 (T4), and 8 to 11 (T6).
## The medium pad (section 9): 4 presses a second, 1 in 10 going wide (dropped), defending half the pack blows that come due (of those 6 in 10 by a
## held guard, 2 by a strong block, 2 by a dodge), and going for a wind-up it has seen for 12 ticks. Every choice is a keyed draw.

const PLAYS: Dictionary = {"horde": true, "intro": false, "planet": 7, "touch": 2, "planetGen": 3, "power": true, "dash": true, "slip": true, "kick": true, "flatOut": 3500.0, "v2": [true, true]}

var args: Dictionary = {}


## The pad's memory between ticks, a seat each.
class Pad:
	var kind: String = "medium"
	var seat: int = 0
	var seed: int = 1
	var plans: Dictionary = {}   # a wind-up's key -> [how, at]: 0 none, 1 held guard, 2 strong block, 3 dodge
	var seen: Dictionary = {}    # a wind-up's key -> the tick it was first seen
	var lastPress: int = -1000


func _r(seed: int, key: String, n: int) -> float:
	return SimRng.keyed(seed, key, n)


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


func _intent(S: SimState, p: Pad, t: int) -> SimIntent:
	var i := SimIntent.new()
	var a = S.fighters[p.seat]
	if a.out or a.hd.phase == 7:
		return i
	match p.kind:
		"idle":
			return i
		"guard":
			if t % 12 == 0:
				i.guard = true
				i.guardPress = true
			return i
		"dodge":
			if t % 12 == 0:
				i.dodge = true
			return i
	# the playing pads (section 9): medium (4 presses a second, defends half), three (3 a second, defends half), slow (2, defends half),
	# mash (6 a second, never defends, never goes wide)
	var gap: int = {"medium": 15, "three": 20, "slow": 30, "mash": 10}.get(p.kind, 15)
	var defend: float = 0.0 if p.kind == "mash" else 0.5
	var M = _near(S, p.seat)
	var reach: float = DirHorde.lungeReach(S)
	if M != null:
		var d: float = DirBands.dist(a, M)
		var dx: float = SimWrap.sdx(a.x, M.x)
		if d > reach * 0.7:
			i.mx = 1.0 if dx > 0.0 else -1.0
			i.my = clampf((M.y - a.y) / 400.0, -1.0, 1.0)
			i.dash = absf(dx) > 1500.0
	# the wind-ups at this seat: plan each once, on first sight
	var target = null
	for k in range(SimHorde.seats, S.fighters.size()):
		var f = S.fighters[k]
		if f.out or f.hd.phase != 3 or S.horde.mark[k] != p.seat:
			continue
		var key: int = k * 1000003 + f.hd.at
		if not p.seen.has(key):
			p.seen[key] = t
			var how: int = 0
			if _r(p.seed, "pad.defend", key) < defend:
				var u: float = _r(p.seed, "pad.how", key)
				how = 1 if u < 0.6 else (2 if u < 0.8 else 3)
			p.plans[key] = [how, f.hd.at]
		if t - int(p.seen[key]) >= 12 and target == null:
			target = f   # a wind-up seen for 12 ticks: go for it
	for key in p.plans.keys():
		var pl: Array = p.plans[key]
		var due: int = int(pl[1]) - S.tick   # (the sim's tick: the pad reads the state before this tick's step)
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
	if t - p.lastPress >= gap and M != null and (DirBands.dist(a, M) <= reach or target != null):
		p.lastPress = t
		if p.kind != "mash" and _r(p.seed, "pad.wide", t) < 0.1:
			return i   # one press in ten goes wide (dropped)
		if target != null:
			i.mx = 1.0 if SimWrap.sdx(a.x, target.x) > 0.0 else -1.0   # the stick at the wind-up it saw
		i.light = true
	return i


## One run to its end. Returns its readings.
func _run(seed: int, kinds: Array, ticks: int) -> Dictionary:
	var S := SimCore.createSim()
	var two: bool = kinds.size() > 1
	SimCore.newMatch(S, seed, {"p1": false, "p2": not two}, PLAYS)
	var pads: Array = []
	for s in range(kinds.size()):
		var p := Pad.new()
		p.kind = kinds[s]
		p.seat = s
		p.seed = seed * 31 + s
		pads.append(p)
	var r := {"seed": seed, "pads": kinds, "endT": -1, "over": 0, "wave": 0, "lost": [], "downs": [], "windups": 0, "windupsWhile": 0, "blows": [], "spacingBad": 0,
		"overLanes": 0, "allCircle": 0, "threeNear": 0, "against": 0, "pressNoAnswer": 0, "stopped": 0, "lungeLong": 0, "waveTicks": [], "twoIn": [], "noneIn": [],
		"felledW1": -1, "w1Ticks": -1, "noReachMax": [0.0, 0.0], "noReachW": [], "outcomes": {}, "missD": [], "fodder12": -1, "fodderFells": [], "noPick": 0, "seatTicks": 0}
	var inFlight: Dictionary = {}   # seat -> wind-ups in flight (count)
	var lastLand: Dictionary = {}   # seat -> the tick of the last pack blow due
	var hitAt: Dictionary = {}       # seat -> the tick of the last pack blow that landed
	var lungeAt: Dictionary = {}     # seat -> the tick its lunge began
	var waveT: int = 0
	var wTwo: int = 0
	var wNone: int = 0
	var hp0: Array = []
	for s in range(kinds.size()):
		hp0.append(S.fighters[s].hp)
	var curWave: int = 0
	var nr: Array = [0, 0]
	var prevMove: Dictionary = {}
	for t in range(ticks):
		var ins: Array = [null, null, null, null, null]
		for p in pads:
			ins[p.seat] = _intent(S, p, t)
		var pre: Array = []
		for s in range(kinds.size()):
			var a = S.fighters[s]
			pre.append([a.x, a.rush != null])
		SimCore.step(S, ins)
		var pressed: Dictionary = {}
		for s in range(kinds.size()):
			var ii: SimIntent = ins[s]
			if ii != null and (ii.light or ii.heavy or ii.sig):
				pressed[s] = true
		var answered: Dictionary = {}
		for e in S.out.fx:
			if e.type != "cue":
				continue
			var actor: int = int(e.actor)
			match String(e.kind):
				"horde_wind":
					r.windups += 1
					var ps: int = 0 if String(e.text) == "p1" else 1
					if int(inFlight.get(ps, 0)) > 0:
						r.windupsWhile += 1
				"horde_pack":
					var ps: int = actor if actor < SimHorde.seats else (0 if String(e.source) == "p1" else 1)
					r.outcomes[String(e.text)] = int(r.outcomes.get(String(e.text), 0)) + 1
					if String(e.text) == "miss" and r.missD.size() < 6 and actor >= SimHorde.seats:
						var ff = S.fighters[actor]
						var pp = S.fighters[ps]
						r.missD.append("d %.0f dx %.0f dy %.0f fy %.0f py %.0f st %s/%s" % [DirBands.dist(ff, pp), SimWrap.sdx(ff.x, pp.x), pp.y - ff.y, ff.y, pp.y, ff.state, pp.state])
					if String(e.text) == "hit":
						hitAt[actor] = S.tick
				"horde_blow", "press_refused":
					answered[actor] = true
					if String(e.kind) == "horde_blow" and String(e.text) == "start":
						lungeAt[actor] = S.tick
		# readings 5 and 6 from the state: wind-ups in flight at each seat, blows due, the crowd
		for s in range(kinds.size()):
			var n: int = 0
			var near: int = 0
			var circling: int = 0
			for k in range(SimHorde.seats, S.fighters.size()):
				var f = S.fighters[k]
				if f.out or S.horde.mark[k] != s:
					continue
				if f.hd.phase == 3:
					n += 1
					if f.hd.at == S.tick + 1:
						pass
				if f.hd.phase >= 2 and f.hd.phase <= 5 and DirBands.dist(f, S.fighters[s]) <= float(SimHorde.data().play.seenBh) * DirBands.BH:
					near += 1
					if f.hd.phase == 2:
						circling += 1
			inFlight[s] = n
			if n > DirHorde.perPlayer():
				r.overLanes += 1
			if near == 3:
				r.threeNear += 1
				if circling == 3:
					r.allCircle += 1
		# blows due this tick on each seat (the strikes): spacing
		for e in S.out.fx:
			if e.type == "cue" and String(e.kind) == "horde_pack":
				var ps: int = int(e.actor) if int(e.actor) < SimHorde.seats else (0 if String(e.source) == "p1" else 1)
				if lastLand.has(ps) and S.tick - int(lastLand[ps]) < int(SimHorde.data().play.spacingTicks):
					r.spacingBad += 1
				lastLand[ps] = S.tick
		# reading 7: against a held stick (other than in its own lunge), a press after a landed blow with no answer
		for s in range(kinds.size()):
			var a = S.fighters[s]
			var ii: SimIntent = ins[s]
			if a.out or a.hd.phase == 7 or ii == null:
				continue
			r.seatTicks += 1
			var moved: float = SimWrap.sdx(float(pre[s][0]), a.x)
			var was: float = float(prevMove.get(s, 0.0))
			if absf(ii.mx) > 0.5 and moved * ii.mx < -2.0 and moved * ii.mx < was * ii.mx - 1.0 and not pre[s][1] and a.rush == null and a.state == "free":
				r.against += 1   # pushed: speeding up against the held stick (braking after a flip, the kick's coin turn, is the fighter's own momentum)
			prevMove[s] = moved
			if pressed.has(s) and hitAt.has(s) and S.tick - int(hitAt[s]) <= 6 and not answered.has(s):
				r.pressNoAnswer += 1
		S.out.fx.clear()
		S.out.feed.clear()
		# reading 21: the field, by wave
		if S.horde.wave != curWave:
			if curWave > 0 and waveT > 0:
				r.waveTicks.append(waveT)
				r.twoIn.append(float(wTwo) / float(waveT))
				r.noneIn.append(float(wNone) / float(waveT))
				for s in range(kinds.size()):
					r.noReachMax[s] = maxf(float(r.noReachMax[s]), float(nr[s]) / float(waveT))
				r.noReachW.append(str([curWave, waveT] + nr.slice(0, kinds.size()).map(func(x): return int(round(100.0 * float(x) / float(waveT))))))
			curWave = S.horde.wave
			waveT = 0
			wTwo = 0
			wNone = 0
			nr = [0, 0]
		if S.horde.rest == 0 and S.horde.wave > 0:
			waveT += 1
			var inn: int = 0
			for k in range(SimHorde.seats, S.fighters.size()):
				var f = S.fighters[k]
				if not f.out and f.hd.phase >= 2 and f.hd.phase <= 5:
					inn += 1
			if inn >= 2:
				wTwo += 1
			if inn == 0:
				wNone += 1
			for s in range(kinds.size()):   # reading 10: a seat with no pack body within the lunge's reach
				var a = S.fighters[s]
				if a.out or a.hd.phase == 7:
					continue
				var any: bool = false
				for k in range(SimHorde.seats, S.fighters.size()):
					var f = S.fighters[k]
					if not f.out and f.hd.phase >= 2 and f.hd.phase <= 5 and DirBands.dist(a, f) <= DirHorde.lungeReach(S):
						any = true
				if not any:
					nr[s] += 1
		if args.has("trace") and S.horde.wave == int(args.trace) and S.horde.rest == 0 and t % 90 == 0:
			var line: String = "  t%d" % S.horde.t
			for k in range(SimHorde.seats, S.fighters.size()):
				var f = S.fighters[k]
				line += " | p%d %s ph%d mk%d d0 %.0f d1 %.0f y %.0f st %s" % [k, SimHorde.KINDS[f.hd.kind], f.hd.phase, S.horde.mark[k], DirBands.dist(f, S.fighters[0]), DirBands.dist(f, S.fighters[1]), f.y, f.state]
			line += " | seats y %.0f %.0f gap %.0f" % [S.fighters[0].y, S.fighters[1].y, DirBands.dist(S.fighters[0], S.fighters[1])]
			print(line)
		if S.horde.wave == 1 and S.horde.felled == 12 and r.fodder12 < 0:
			r.fodder12 = S.horde.t
		if r.w1Ticks < 0 and S.horde.wave >= 1 and S.horde.rest > 0 and S.horde.wave == 1:
			r.w1Ticks = S.horde.t
			r.felledW1 = S.horde.felled
		if SimCore.ended(S):
			r.endT = S.horde.t
			break
	if waveT > 0:
		r.waveTicks.append(waveT)
		r.twoIn.append(float(wTwo) / float(waveT))
		r.noneIn.append(float(wNone) / float(waveT))
		for s in range(kinds.size()):
			r.noReachMax[s] = maxf(float(r.noReachMax[s]), float(nr[s]) / float(waveT))
	if r.felledW1 < 0:
		r.felledW1 = S.horde.felled if S.horde.wave <= 1 else -1
	r.over = S.horde.over
	r.wave = S.horde.wave
	r.felled = S.horde.felled
	r.runT = S.horde.t
	for s in range(kinds.size()):
		var a = S.fighters[s]
		r.lost.append(1.0 - a.hp / float(hp0[s]))
		r.downs.append(a.hd.downs)
	return r


func _fmt(r: Dictionary) -> String:
	var m: float = float(r.runT) / 60.0
	var tw: String = ""
	for x in r.twoIn:
		tw += "%d " % int(round(x * 100.0))
	var nn: String = ""
	for x in r.noneIn:
		nn += "%d " % int(round(x * 100.0))
	return "outcomes %s; misses %s
    seed %d %s: over %d at %d:%02d, wave %d, felled %d, body lost %s, downs %s; wind-ups %.1f/min (%.1f/min while one in flight); spacing pairs %d; over lanes %d; all three circling %d%% of %d ticks with three near; against the stick %d; press unanswered after a hit %d; two in %% by wave [%s]; none in %% [%s]; 12 fodder at %.1f s; wave 1 felled %d; no body in reach, worst wave %s" % [
		str(r.outcomes), str(r.missD), r.seed, ",".join(r.pads), r.over, int(m) / 60, int(m) % 60, r.wave, r.felled, str(r.lost.map(func(x): return "%d%%" % int(round(x * 100.0)))), str(r.downs),
		float(r.windups) / maxf(m / 60.0, 0.01), float(r.windupsWhile) / maxf(m / 60.0, 0.01), r.spacingBad, r.overLanes,
		int(round(100.0 * float(r.allCircle) / maxf(1.0, float(r.threeNear)))), r.threeNear, r.against, r.pressNoAnswer, tw.strip_edges(), nn.strip_edges(),
		float(r.fodder12) / 60.0 if r.fodder12 >= 0 else -1.0, r.felledW1, str(r.noReachMax.slice(0, r.pads.size()).map(func(x): return "%d%%" % int(round(x * 100.0))))]


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var pads: Array = String(args.get("pads", "medium")).split(",")
	var seeds: int = int(args.get("seeds", "1"))
	var ticks: int = int(args.get("ticks", str(DirHorde.capTicks() + 600)))
	var two: bool = args.has("two")
	var arm: String = String(args.get("arm", "G"))
	var d: Dictionary = SimHorde.data()   # the arm's numbers, in memory for this probe only (Game Design's rulings 1 and 2; row D)
	if arm == "240" or arm == "D":
		d.play.gapTicks = {"easy": 360, "medium": 240, "hard": 144}
		var dm: Array = [4, 8, 4] if arm == "240" else [24, 48, 24]
		var kk: Array = ["fodder", "bruiser", "speedster"]
		for j in range(3):
			d.pack[kk[j]].blow.damage = dm[j]
		if arm == "D":
			d.rest.backBody = 1600
	print("ARM %s: gap %s, blows %d/%d/%d, back in each breather %s" % [arm, str(d.play.gapTicks.medium), int(d.pack.fodder.blow.damage), int(d.pack.bruiser.blow.damage), int(d.pack.speedster.blow.damage), str(d.rest.backBody)])
	var all: Dictionary = {}
	for kind in pads:
		all[kind] = []
		for sd in range(1, seeds + 1):
			var r: Dictionary = _run(sd, [kind, kind] if two else [kind], ticks)
			all[kind].append(r)
			print("RUN " + _fmt(r))
			if args.has("perwave"):
				print("  no body in reach by wave [wave, ticks, % seat 0, % seat 1]: " + ", ".join(r.noReachW))
	_verdicts(all, two)
	_runs(all, two)
	print("PROBE done")


func _say(c: bool, what: String) -> void:
	print(("PASS  " if c else "FAIL  ") + what)


## T4's readings (section 9), from the runs: 5, 6, 7, 21 from the medium pad (and every pad for the hard rows), 22 from the tappers against the idle pad.
func _verdicts(all: Dictionary, two: bool = false) -> void:
	var hard5: bool = true
	var hard7: bool = true
	for kind in all:
		for r in all[kind]:
			hard5 = hard5 and r.spacingBad == 0 and r.overLanes == 0
			hard7 = hard7 and r.against == 0 and r.pressNoAnswer == 0
	_say(hard5, "reading 5 (hard): no two pack blows on one player within the spacing, never more wind-ups at a player than its lanes, every run")
	_say(hard7, "reading 7 (hard): never moved against a held stick outside its own lunge; every press after a landed blow answered, every run (a lunge is at most 10 + 20 ticks by construction, and a dodge or guard calls it off)")
	if all.has("medium"):
		var ok6: bool = true
		var ok21: bool = true
		for r in all.medium:
			var mins: float = maxf(float(r.runT) / 3600.0, 0.01)
			ok6 = ok6 and float(r.windups) / mins >= 30.0 and float(r.windupsWhile) / mins >= 2.0 and float(r.allCircle) <= 0.6 * maxf(1.0, float(r.threeNear))
			for x in r.twoIn:
				ok21 = ok21 and x >= 0.6
			for x in r.noneIn:
				ok21 = ok21 and x <= 0.1
		_say(ok6, "reading 6: the medium pad sees 30 wind-ups a minute or more, 2 a minute or more while another is in flight, all three only circling at most 60% of the ticks with three near")
		if two:
			var tw: Array = []
			for r in all.medium:
				tw.append(str(r.twoIn.map(func(x): return int(round(x * 100.0)))))
			print("INFO  reading 21 with two pads (for information; the model: 68%% in wave 1 rising to 88%%): two in the fight, %% by wave, a run each: %s" % ", ".join(tw))
		else:
			_say(ok21, "reading 21: two pack bodies in the fight 60% of each wave or more, none at most 10%")
	if all.has("idle") and all.has("guard") and all.has("dodge"):
		var ok22: bool = true
		for i in range(all.idle.size()):
			var idleT: float = float(all.idle[i].runT)
			for kind in ["guard", "dodge"]:
				var r: Dictionary = all[kind][i]
				ok22 = ok22 and r.felledW1 <= 0 and float(r.runT) <= idleT * 4.0 / 3.0
		_say(ok22, "reading 22: the guard-tapper and the dodge-tapper fell nothing in wave 1 and last at most a third longer than the idle pad")
	quit(0)


## T6's readings (section 9): 8 run length, 9 fair alone, 10 two players, 11 twelve fodder.
func _runs(all: Dictionary, two: bool) -> void:
	for kind in all:
		var rs: Array = all[kind]
		if rs.is_empty():
			continue
		var ts: Array = rs.map(func(r): return float(r.runT) / 3600.0)
		var lost: Array = []
		var downs: int = 0
		var nr: float = 0.0
		for r in rs:
			for x in r.lost:
				lost.append(x)
			for x in r.downs:
				downs += int(x)
			for x in r.noReachMax.slice(0, r.pads.size()):
				nr = maxf(nr, float(x))
		var mean: float = ts.reduce(func(a, b): return a + b, 0.0) / float(ts.size())
		var lmean: float = lost.reduce(func(a, b): return a + b, 0.0) / float(lost.size())
		print("SUMMARY %s%s, %d runs: run %.2f min mean (%.2f to %.2f); body lost %d%% mean (%d%% to %d%%); downs %d; cleared %d; waves reached %s; no body in reach, worst wave %d%%" % [kind, " x2" if two else "", rs.size(), mean, ts.min(), ts.max(),
			int(round(lmean * 100.0)), int(round(lost.min() * 100.0)), int(round(lost.max() * 100.0)), downs, rs.filter(func(r): return r.over == 1).size(), str(rs.map(func(r): return r.wave)), int(round(nr * 100.0))])
		match kind:
			"medium":
				if two:
					_say(ts.min() >= 6.0 and ts.max() <= 8.0, "reading 8 (two): each run 6:00 to 8:00")
					_say(lost.min() >= 0.10 and lost.max() <= 0.35, "reading 10: each medium pad of two loses 10 to 35%")
					_say(nr <= 0.35, "reading 10: a seat has no pack body within the lunge's reach for at most 35% of a wave")
					var f12two: Array = rs.map(func(r): return float(r.fodder12) / 60.0)
					_say(_band11(f12two, 3.0, 6.0), "reading 11 (two, Game Design 2026-11-15): twelve fodder in 3 to 6 s between two, on the median with 9 of 10 seeds inside (%.1f to %.1f, median %.1f)" % [f12two.min(), f12two.max(), _median(f12two)])
				else:
					_say(ts.min() >= 7.0 and ts.max() <= 9.0, "reading 8 (alone): each run 7:00 to 9:00")
					_say(lost.min() >= 0.20 and lost.max() <= 0.45 and downs == 0, "reading 9: the medium pad loses 20 to 45% and never goes down")
					var f12: Array = rs.map(func(r): return float(r.fodder12) / 60.0)
					_say(_band11(f12, 4.0, 8.0), "reading 11 (Game Design 2026-11-15): twelve fodder in 4 to 8 s alone, on the median with 9 of 10 seeds inside (%.1f to %.1f, median %.1f)" % [f12.min(), f12.max(), _median(f12)])
			"three":
				_say(lost.min() >= 0.30 and lost.max() <= 0.60, "reading 9: at 3 presses a second it loses 30 to 60%")
			"mash":
				_say(rs.all(func(r): return r.over == 1), "reading 9: a pad that mashes and never guards finishes")
			"slow":
				_say(rs.all(func(r): return r.wave >= 6), "reading 9: a slow pad at 2 presses a second reaches wave 6")
			"idle":
				print("INFO  reading 9: the idle pad lasts %.2f min mean (model 8:25)" % mean)


func _median(xs: Array) -> float:
	var a: Array = xs.duplicate()
	a.sort()
	var n: int = a.size()
	return 0.0 if n == 0 else (float(a[n / 2]) if n % 2 == 1 else 0.5 * (float(a[n / 2 - 1]) + float(a[n / 2])))


## Reading 11's rule (Game Design, 2026-11-15): the median inside the band, and at least 9 seeds in 10 inside it.
func _band11(xs: Array, lo: float, hi: float) -> bool:
	var m: float = _median(xs)
	var inside: int = xs.filter(func(x): return float(x) >= lo and float(x) <= hi).size()
	return m >= lo and m <= hi and inside * 10 >= xs.size() * 9
