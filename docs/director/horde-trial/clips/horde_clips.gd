extends SceneTree
## The Horde trial's clip (T8; the design's section 9, clip 1): one real match from its start, the pads scripted, a mark on each beat, written
## as a match file Tools' clip kit cuts (node tools/clips/make.mjs --from-match <file> --build <a web build of this tree>).
##   godot --headless --path . --script res://sim/director/tools/horde_clips.gd -- --seeds=1-6 --out=<file> [--commit=<id>] [--to-blast]
##   godot --headless --path . --script res://sim/director/tools/horde_clips.gd -- --check=<file>     (the file replays exactly on this tree)
## Beats: 1 wave 1 (the streak-ins, an X string); 2 B through a building (waves 2 and 3, the pad presses B when a building stands ahead);
## 3 wave 4 with one pad (a wind-up beaten by hitting first, one guarded, one dropped by a late guard, one landing); 4 the second pad joins;
## 5 a blast past the partner into a weak fighter (RB with X); 6 seat 0's pad lets go and goes down, seat 1 finishes the wave, seat 0 gets up.

const PLAYS: Dictionary = {"horde": true, "intro": false, "planet": 7, "touch": 2, "planetGen": 3, "power": true, "dash": true, "slip": true, "kick": true, "flatOut": 3500.0, "v2": [true, true]}
const CAP: int = 60 * 60 * 14   # a recording stops here whatever happens

var args: Dictionary = {}


## The pad's memory between ticks, a seat each (horde_probe.gd's medium pad).
class Pad:
	var kind: String = "medium"
	var seat: int = 0
	var seed: int = 1
	var plans: Dictionary = {}
	var seen: Dictionary = {}
	var lastPress: int = -1000
	var hush: int = -1   # no attack press before this tick (after a blast: the shot alone reaches the body)


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


## horde_probe.gd's playing pad, as it is (medium: 4 presses a second, defends half).
func _intent(S: SimState, p: Pad, t: int) -> SimIntent:
	var i := SimIntent.new()
	var a = S.fighters[p.seat]
	if a.out or a.hd.phase == 7 or p.kind == "idle":
		return i
	var gap: int = 15
	var defend: float = 0.5
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
			if _r(p.seed, "pad.defend", key) < defend:
				var u: float = _r(p.seed, "pad.how", key)
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
	if i.guard or i.dodge or t < p.hush:
		return i
	if t - p.lastPress >= gap and M != null and (DirBands.dist(a, M) <= reach or target != null):
		p.lastPress = t
		if _r(p.seed, "pad.wide", t) < 0.1:
			return i
		if target != null:
			i.mx = 1.0 if SimWrap.sdx(a.x, target.x) > 0.0 else -1.0
		i.light = true
	return i


## A building standing ahead of A on his facing, near his line, within a heavy launch's flight: its index, or -1.
func _buildingAhead(S: SimState, A) -> int:
	for bi in range(S.buildings.size()):
		var b = S.buildings[bi]
		if not b.alive:
			continue
		var along: float = SimWrap.sdx(A.x, b.x) * A.face - float(b.w) * 0.5
		var off: float = absf(float(b.z) - A.z) - float(b.d) * 0.5
		if along > 80.0 and along < 1800.0 and off <= 120.0:
			return bi
	return -1


## The stick toward the nearest building in the lane (near A's line), within 20,000: -1, 1, or 0 for none.
func _toBuilding(S: SimState, A) -> float:
	var best: float = INF
	var go: float = 0.0
	for bi in range(S.buildings.size()):
		var b = S.buildings[bi]
		if not b.alive or absf(float(b.z) - A.z) - float(b.d) * 0.5 > 120.0:
			continue
		var dx: float = SimWrap.sdx(A.x, b.x)
		if absf(dx) < best and absf(dx) < 20000.0:
			best = absf(dx)
			go = 1.0 if dx > 0.0 else -1.0
	return go


func _record(seed: int) -> Dictionary:
	var S := SimCore.createSim()
	var rec: SimReplay = SimReplay.recorder(S, seed, {"p1": false, "p2": true}, PLAYS)
	var pads: Array = []
	for s in range(2):
		var p := Pad.new()
		p.seat = s
		p.seed = seed * 31 + s
		pads.append(p)
	var beat: Dictionary = {}       # name -> tick
	var marks: Array = []
	var notes: Array = []
	var joined: bool = false
	var w4Start: int = -1
	var heavyAt: int = -1
	var blast: Dictionary = {}      # a blast in flight: at, shooter, partner, target, hp0, partnerHp0
	var lastBlastTry: int = -100000
	var idleFrom: int = -1
	var tEnd: int = CAP
	var bTries: int = 0
	var bw: Dictionary = {}         # name -> the wave it came in
	for t in range(CAP):
		if t >= tEnd:
			break
		var R = S.horde
		var wave: int = R.wave
		var resting: bool = R.rest > 0
		if not beat.has("w1") and wave == 1 and not resting:
			beat.w1 = t
		if w4Start < 0 and wave == 4 and not resting:
			w4Start = t
		var ins: Array = [null, null, null, null, null]
		for p in pads:
			if p.seat == 1 and not joined:
				continue
			ins[p.seat] = _intent(S, p, t)
		var A = S.fighters[0]
		# beat 2: from wave 2 until the join, the pad drifts toward the nearest building in the lane, and presses B when one stands ahead
		# and the near body is in front, until one is hit
		if args.has("b") and not beat.has("b") and wave >= 2 and not joined and not resting and t - heavyAt > 240:
			var i0: SimIntent = ins[0]
			var M = _near(S, 0)
			if i0 != null and i0.light and M != null and SimWrap.sdx(A.x, M.x) * A.face > 0.0 and _buildingAhead(S, A) >= 0:
				i0.light = false
				i0.sig = true
				i0.sigHeld = true
				heavyAt = t
				bTries += 1
			elif i0 != null and not i0.light and not i0.guard and not i0.dodge and _buildingAhead(S, A) < 0:
				var go: float = _toBuilding(S, A)
				if go != 0.0:
					i0.mx = go
		# beat 4: the second pad joins once wave 4 (or later) has shown its four answers, or 90 s into wave 4; seat 0's pad lets go then,
		# so it goes down while seat 1 plays on (beat 6)
		if not joined and w4Start >= 0 and (t - w4Start >= 5400 or (beat.has("beaten") and beat.has("guarded") and beat.has("blocked") and beat.has("hit"))):
			rec.toggle(1)
			joined = true
			beat.join = t
			ins[1] = _intent(S, pads[1], t)
			idleFrom = t
			notes.append("join at %d: seat 0 hp %.0f, wave %d" % [t, A.hp, wave])
			pads[0].kind = "idle"
			ins[0] = SimIntent.new()
		# beat 5: a blast from seat 1 past seat 0 (standing still) into a weak fighter beyond
		if joined and not beat.has("blast") and blast.is_empty() and t - int(beat.join) > 300 and t - lastBlastTry >= 30:
			for s in [1]:
				var Sh = S.fighters[s]
				var Q = S.fighters[1 - s]
				if Sh.out or Q.out or Sh.hd.phase == 7 or Q.hd.phase == 7 or Sh.state != "free":
					continue
				var dq: float = SimWrap.sdx(Sh.x, Q.x) * Sh.face
				if dq < 60.0 or dq > 900.0 or absf(Q.y - Sh.y) > 250.0:
					continue
				var tgt: int = -1
				for k in range(SimHorde.seats, S.fighters.size()):
					var M = S.fighters[k]
					if M.out or M.hd.phase < 2 or M.hd.phase > 5:
						continue
					var dm: float = SimWrap.sdx(Sh.x, M.x) * Sh.face
					if dm > dq + 60.0 and dm < 1600.0 and absf(M.y - Sh.y) < 300.0:
						tgt = k
						break
				if tgt < 0:
					continue
				var ib := SimIntent.new()
				ib.mode = 1
				ib.light = true
				ib.mx = Sh.face
				ins[s] = ib
				lastBlastTry = t
				blast = {"at": t, "shooter": s, "partner": 1 - s, "target": tgt, "hp0": S.fighters[tgt].hp, "qhp0": Q.hp, "qhit": false, "wound": false}
				pads[0].hush = t + 60
				pads[1].hush = t + 60
				break
		# the late guard (the design's "dropped by a guard raised at the last moment"): until one lands, 2 ticks before a wind-up at seat 0 lands
		if wave >= 4 and not joined and not resting and not beat.has("blocked") and ins[0] != null:
			for k in range(SimHorde.seats, S.fighters.size()):
				var f = S.fighters[k]
				if not f.out and f.hd.phase == 3 and R.mark[k] == 0 and f.hd.at - S.tick >= 0 and f.hd.at - S.tick <= 2:
					ins[0] = SimIntent.new()
					ins[0].guard = true   # raised 2 ticks before it lands and held through it
					ins[0].guardPress = f.hd.at - S.tick == 2
		if not blast.is_empty() and t > int(blast.at) and t - int(blast.at) <= 45:
			var hold := SimIntent.new()
			hold.mode = 1   # the energy family held through the wind-up
			ins[int(blast.shooter)] = hold
		# pre-step: wind-ups at seat 0 (beaten by hitting first), in wave 4 or later before the join
		var winding: Dictionary = {}
		if wave >= 4 and not joined and not resting:
			for k in range(SimHorde.seats, S.fighters.size()):
				var f = S.fighters[k]
				if not f.out and f.hd.phase == 3 and R.mark[k] == 0:
					winding[k] = f.hp
		rec.step(ins)
		for e in S.out.fx:
			if e.type == "building_hit" and heavyAt >= 0 and not beat.has("b") and S.tick - heavyAt <= 240:
				beat.b = t
				notes.append("b: building %d hit %d ticks after B" % [int(e.b), t - heavyAt])
			if e.type != "cue":
				continue
			var kind: String = String(e.kind)
			var actor: int = int(e.actor)
			if kind == "horde_pack" and wave >= 4 and not joined and actor == 0:
				var txt: String = String(e.text)
				if (txt == "hit" or txt == "guarded" or txt == "blocked") and not beat.has(txt):
					beat[txt] = t
			if kind == "blast_windup" and not blast.is_empty() and actor == int(blast.shooter):
				blast.wound = true
			if kind == "horde_pack" and not blast.is_empty() and actor == int(blast.partner) and String(e.text) == "hit":
				blast.qhit = true
			if kind == "horde_down" or kind == "horde_up":
				notes.append("%s: seat %d at %d (wave %d)" % [kind, actor, t, S.horde.wave])
			if kind == "horde_down" and idleFrom >= 0 and not beat.has("down"):
				beat.down = t   # the first seat down after the join (either: seat 1 alone carries the wave seat 0 lets go of)
				beat.downSeat = actor
				tEnd = t + 600
			if kind == "horde_up" and actor == 0 and beat.has("down") and not beat.has("up"):
				beat.up = t
				tEnd = t + 240
		for k in winding.keys():
			var f = S.fighters[k]
			if not beat.has("beaten") and (f.hp < float(winding[k]) or f.out or f.hd.phase == 6) and f.hd.phase != 3:
				beat.beaten = t
		if beat.has("down") and not beat.has("cleared") and S.horde.rest > 0 and not resting:
			beat.cleared = t
		if not blast.is_empty() and t - int(blast.at) >= 90:
			var M = S.fighters[int(blast.target)]
			var Q = S.fighters[int(blast.partner)]
			var shot: bool = M.hp < float(blast.hp0) or M.out or M.hd.phase == 6
			var spared: bool = Q.hp >= float(blast.qhp0) or bool(blast.qhit)
			var fired: bool = bool(blast.wound)   # the blast wound up (the shooter's blows are held off, the partner stands still: only the shot reaches the body)
			notes.append("blast try at %d from seat %d: fired %s, the body hit %s, the partner spared %s" % [int(blast.at), int(blast.shooter), str(fired), str(shot), str(spared)])
			if shot and spared and fired:
				beat.blast = int(blast.at)
				if args.has("to-blast"):
					tEnd = t + 400   # the short file: it ends after the blast
			blast = {}
		for k in beat.keys():
			if not bw.has(k):
				bw[k] = S.horde.wave
		S.out.fx.clear()
		S.out.feed.clear()
		if SimCore.ended(S):
			notes.append("the match ended at %d" % t)
			break
	notes.append("B presses %d" % bTries)
	var rp: Dictionary = rec.finish().duplicate(true)
	var hp: Array = [S.fighters[0].hp, S.fighters[1].hp]
	SimCore.dispose(S)
	# the marks, 8 to 15 seconds each (a mark's window is [tick - before, tick])
	var want: Array = [["w1", 840, 780], ["beaten", 60, 300], ["guarded", 60, 300], ["blocked", 60, 300], ["hit", 90, 330],
		["join", 300, 420], ["blast", 90, 300], ["down", 300, 540]]
	if args.has("to-blast"):
		want.pop_back()
	var missing: Array = []
	for w in want:
		if beat.has(w[0]):
			marks.append({"before": int(w[2]), "kind": "clip", "tick": int(beat[w[0]]) + int(w[1]), "beat": String(w[0])})
		else:
			missing.append(String(w[0]))
	marks.sort_custom(func(x, y): return int(x.tick) < int(y.tick))
	# windows that overlap (or sit within a second of each other) are one continuous window: no footage is cut twice
	var merged: Array = []
	for m in marks:
		var lo: int = int(m.tick) - int(m.before)
		if not merged.is_empty() and lo <= int(merged[-1].tick) + 60:
			var prev: Dictionary = merged[-1]
			var plo: int = int(prev.tick) - int(prev.before)
			prev.tick = maxi(int(prev.tick), int(m.tick))
			prev.before = int(prev.tick) - plo
			prev.beat = String(prev.beat) + "+" + String(m.beat)
		else:
			merged.append(m.duplicate())
	marks = merged
	return {"seed": seed, "beat": beat, "bw": bw, "marks": marks, "missing": missing, "log": notes, "replay": rp, "ticks": int(rp.ticks), "hp": hp}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("check"):
		var doc = JSON.parse_string(FileAccess.get_file_as_string(String(args.check)))
		var res: Dictionary = SimReplay.play(doc.replay)
		print(("ok    " if bool(res.ok) else "FAIL  ") + "the match file replays exactly on this tree (%s, first bad tick %d, %d ticks, %d toggles, %d marks)" % [String(res.reason), int(res.firstBadTick), int(doc.replay.ticks), doc.replay.toggles.size(), doc.marks.size()])
		print("HORDE CLIPS: %d check(s) failed" % (0 if bool(res.ok) else 1))
		quit(0 if bool(res.ok) else 1)
		return
	var lohi: PackedStringArray = String(args.get("seeds", "1-4")).split("-")
	var best: Dictionary = {}
	for seed in range(int(lohi[0]), int(lohi[lohi.size() - 1]) + 1):
		var r: Dictionary = _record(seed)
		var bt: Array = []
		for k in r.beat.keys():
			bt.append("%s %d (w%d)" % [k, int(r.beat[k]), int(r.bw.get(k, -1))])
		print("seed %d: %d ticks (%.1f min), missing %s; beats %s; hp left %.0f %.0f" % [seed, r.ticks, float(r.ticks) / 3600.0, str(r.missing), ", ".join(bt), r.hp[0], r.hp[1]])
		for l in r.log:
			print("      " + String(l))
		if best.is_empty() or r.missing.size() < best.missing.size() or (r.missing.size() == best.missing.size() and r.ticks < best.ticks):
			best = r
		if r.missing.is_empty() and not args.has("all"):
			break
	var secs: float = 0.0
	for m in best.marks:
		secs += float(m.before) / 60.0
	var note: String = "Horde trial T8, clip 1 (the design's section 9): seed %d, %d ticks; beats %s; %.0f s of marks; missing %s" % [best.seed, best.ticks, str(best.beat), secs, str(best.missing)]
	var doc := {"build": {"commit": String(args.get("commit", ""))}, "marks": best.marks, "note": note, "pageSearch": "", "replay": best.replay}
	if args.has("out"):
		var fa := FileAccess.open(String(args.out), FileAccess.WRITE)
		fa.store_string(JSON.stringify(doc))
		fa.close()
	print("      chosen: seed %d, %d marks, %.0f s, missing %s" % [best.seed, best.marks.size(), secs, str(best.missing)])
	print("HORDE CLIPS: %d check(s) failed" % (0 if best.missing.is_empty() else 1))
	quit(0 if best.missing.is_empty() else 1)
