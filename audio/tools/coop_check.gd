extends SceneTree
## Do the co-op and controller sounds behave (audio/audio_coop.gd, data/coop_cues.json; docs/audio/coop-sound.md)?
## Stages the sim's cues by hand and, over seeded matches (1v1 and 2v2), checks the cues. The set is parked behind `enabled`; the
## test switches it on in memory only. From the repo root:
##   godot --headless --path . --script res://audio/tools/coop_check.gd
## Exit code 1 on any failure. No sound device is used.

var bank: AudioBank
var cues: AudioCues
var S: SimState
var fails: int = 0


func _initialize() -> void:
	bank = AudioBank.new()
	cues = AudioCues.new(bank)
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func cue(kind: String, text: String, actor: int, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "cue"
	e.kind = kind
	e.text = text
	e.actor = float(actor)
	e.target = float(1 - actor)
	for k in extra:
		e.set(k, extra[k])
	return e


func tick(t: int, events: Array) -> Array:
	S.tick = t
	S.T = float(t) / 60.0
	return cues.consume(S, events)


func others(t: int, lists: Array) -> Array:
	S.tick = t
	S.T = float(t) / 60.0
	return cues.consume_others(S, lists)


func sounds(list: Array) -> Array:
	return list.map(func(c): return c.sound if c.sound != "" else "(stop " + c.stop_group + ")")


func with_sound(list: Array, id: String) -> Array:
	return list.filter(func(c): return c.sound == id)


func _valid(list: Array) -> String:
	for c in list:
		if c.sound == "":
			continue
		if not bank.has_sound(c.sound):
			return "no such sound " + c.sound
		if c.variant < 0 or c.variant >= bank.variants(c.sound):
			return "variant out of range for " + c.sound
		if not (is_finite(c.gain_db) and is_finite(c.pitch) and is_finite(c.x) and is_finite(c.y)) or c.pitch < 0.4 or c.pitch > 2.0 or c.gain_db < -20.0 or c.gain_db > 8.0:
			return "number out of range for %s: gain %.1f pitch %.2f" % [c.sound, c.gain_db, c.pitch]
	return ""


func _run() -> void:
	S = SimCore.createSim()
	SimCore.newMatch(S, 4)
	S.fighters[0].x = 4000.0
	S.fighters[1].x = 4100.0

	print("1. switched off (as shipped): nothing")
	ok(not cues.coop.enabled(), "the switch is off in the data")
	cues.reset(12)
	var staged: Array = [cue("brink_call", "p1", 0), cue("stick_refused", "right", 0, {"source": "ki"}), cue("press_refused", "", 0, {"source": "stun_limit"}), cue("stick_stage", "1", 0, {"k": 1.0, "n": 6.0}), cue("beam_surge", "", 0)]
	var n_off: int = 0
	for e in staged:
		n_off += tick(1000, [e]).size()
	ok(n_off == 0, "none of the five cues makes a sound (%d)" % n_off)
	ok(others(1000, [[staged[0]]]).is_empty(), "the other fights' list is read for nothing")

	cues.coop.cfg["enabled"] = true

	print("2. the brink's call, in the fight in S")
	cues.reset(12)
	var b1: Array = tick(2000, [cue("brink_call", "p1", 0)])
	var st: Array = with_sound(b1, "form.ready")
	ok(st.size() == 1 and st[0].ambient and st[0].bus == "Alert" and st[0].pitch < 1.0 and st[0].caption == "[P1 on the brink]", "a sting at the listener on the Alert bus, lower than the ready form's, named for the caller (%s)" % [sounds(b1)])
	var vo: Array = b1.filter(func(c): return c.kind == "voice")
	ok(vo.size() == 1 and vo[0].sound == "voice.protagonist.pain.head" and not vo[0].ambient and absf(vo[0].x - 4000.0) < 0.01, "the fighter's own cry, at him (%s)" % [str([vo.size(), vo[0].sound if vo.size() > 0 else "", vo[0].ambient if vo.size() > 0 else "", vo[0].muffled if vo.size() > 0 else "", vo[0].x if vo.size() > 0 else 0.0])])
	ok(tick(2100, [cue("brink_call", "p1", 0)]).is_empty(), "a second call of the same fighter within 4 s is not heard again")
	ok(tick(2000 + 241, [cue("brink_call", "p1", 0)]).size() == 2, "and 241 ticks later it is")
	ok(tick(2300, [cue("brink_call", "p2", 1)]).size() == 2, "another fighter's call has its own clock")
	var b3: Array = tick(2400, [cue("brink_call", "p3", 5)])
	ok(b3.is_empty(), "a call from a body that does not exist makes nothing")

	print("3. the brink's call, from another fight")
	var T2 := SimCore.createSim()
	SimCore.newMatch(T2, 7, {}, {"fights": 2})
	var cm := AudioCues.new(bank)
	cm.coop.cfg["enabled"] = true
	cm.reset(7)
	ok(T2.stage != null and T2.stage.fights.size() == 2 and T2.stage.cur == 0, "a two-fight match, fight 0 in S")
	T2.tick = 3000
	var far = T2.stage.fights[1].fighters[1]
	var o1: Array = cm.consume_others(T2, [[cue("brink_call", "p4", 1)]])
	var s1: Array = with_sound(o1, "form.ready")
	var v1: Array = o1.filter(func(c): return c.kind == "voice")
	ok(s1.size() == 1 and s1[0].ambient and s1[0].caption == "[P4 on the brink]", "the sting sounds at the listener, named for the partner (%s)" % [sounds(o1)])
	ok(v1.size() == 1 and v1[0].ambient and v1[0].muffled and v1[0].gain_db < -8.0 and absf(v1[0].x - far.x) < 0.01, "his cry comes far away: muffled, quiet, from his own body in the other fight (gain %.1f)" % [v1[0].gain_db if v1.size() > 0 else 0.0])
	ok(cm.consume_others(T2, [[cue("beam_fire", "", 1), cue("stick_refused", "right", 1, {"source": "ki"}), cue("stick_stage", "2", 1, {"k": 2.0, "n": 6.0})]]).is_empty(), "nothing else in another fight is heard (its distant mix is a proposal)")
	ok(cm.consume_others(T2, []).is_empty(), "an empty list is nothing")
	var one := AudioCues.new(bank)
	one.coop.cfg["enabled"] = true
	ok(one.consume_others(S, [[cue("brink_call", "p1", 0)]]).is_empty(), "a match of one fight reads no other list")
	SimCore.dispose(T2)

	print("4. the pad's refusal knock")
	cues.reset(12)
	var r1: Array = tick(4000, [cue("stick_refused", "right", 0, {"source": "ki"})])
	ok(sounds(r1) == ["grip.refuse"] and r1[0].gain_db > -6.0 and r1[0].gain_db < -2.0 and absf(r1[0].x - 4000.0) < 0.01, "a refused press: the dull knock, at the presser (%s, %.1f dB)" % [sounds(r1), r1[0].gain_db if r1.size() > 0 else 0.0])
	var knocks: int = 0
	for i in range(1, 10):
		knocks += tick(4000 + i, [cue("stick_refused", "right", 0, {"source": "ki"})]).size()
	ok(knocks == 0, "nine more in nine ticks: one knock only, a mash is never a buzz (%d)" % knocks)
	ok(tick(4013, [cue("stick_refused", "right", 0, {"source": "late"})]).size() == 1, "13 ticks on it sounds again")
	ok(tick(4013, [cue("stick_refused", "left", 1, {"source": "ki"})]).size() == 1, "each fighter has his own")
	var rq: Array = tick(4100, [cue("stick_refused", "left", 0, {"source": "replaced"})])
	ok(rq.size() == 1 and rq[0].gain_db < r1[0].gain_db - 4.0, "a press replaced by a newer one is told more quietly (%.1f against %.1f)" % [rq[0].gain_db if rq.size() > 0 else 0.0, r1[0].gain_db])
	var rp: Array = tick(4200, [cue("press_refused", "", 0, {"source": "block_lockout"})])
	ok(sounds(rp) == ["grip.refuse"], "a director-side drop (press_refused) is the same knock")

	print("5. the charge stages rising")
	cues.reset(12)
	var ps: Array = []
	var top: Array = []
	for k in range(1, 7):
		var o: Array = tick(5000 + 16 * k, [cue("stick_stage", str(k), 0, {"k": float(k), "n": 6.0})])
		var tk: Array = with_sound(o, "charge.tick.light")
		ps.append(tk[0].pitch if tk.size() == 1 else -1.0)
		top.append(with_sound(o, "tug.tock").size())
	var rising: bool = true
	for i in range(1, ps.size()):
		if not (ps[i] > ps[i - 1]):
			rising = false
	ok(rising and absf(ps[0] - 1.0) < 0.05 and absf(ps[5] - 2.0) < 0.1, "each stage's tick is higher than the last, from the root to the octave (%s)" % [str(ps)])
	ok(top == [0, 0, 0, 0, 0, 1], "only the top stage adds the low thud (%s)" % [str(top)])
	var d1: Array = tick(5300, [cue("stick_stage", "5", 0, {"k": 5.0, "n": 6.0})])
	var dt: Array = with_sound(d1, "charge.tick.light")
	ok(dt.size() == 1 and dt[0].pitch < ps[4] and dt[0].gain_db < -8.0 and with_sound(d1, "tug.tock").is_empty(), "a step down (stage 6 to 5) is a lower, duller tick and no thud")
	var cp: Array = tick(5400, [cue("stick_stage", "2", 0, {"k": 2.0, "n": 6.0, "source": "capped"})])
	ok(with_sound(cp, "grip.refuse").size() == 1 and with_sound(cp, "charge.tick.light").size() == 1, "a stage the energy will not pay for: its tick and the knock")
	var cq: Array = tick(5410, [cue("stick_stage", "2", 0, {"k": 2.0, "n": 6.0, "source": "capped"})])
	ok(sounds(cq) == ["grip.refuse"], "the same stage told capped again: only the knock")
	var nw: Array = tick(5400 + 400, [cue("stick_stage", "1", 0, {"k": 1.0, "n": 6.0})])
	ok(with_sound(nw, "charge.tick.light").size() == 1 and absf(with_sound(nw, "charge.tick.light")[0].pitch - 1.0) < 0.05, "a new charge long after starts again at the root")
	ok(tick(6000, [cue("stick_stage", "0", 0, {"k": 0.0, "n": 6.0})]).is_empty(), "stage 0 is silent")

	print("6. a good push in a beam clash")
	cues.reset(12)
	var g1: Array = tick(7000, [cue("beam_surge", "", 0)])
	ok(sounds(g1) == ["perfect.tok"] and absf(g1[0].x - 4000.0) < 0.01, "a plain surge: a sharp tok at the pusher (the struggle's whump is AudioTug's)")
	ok(tick(7001, [cue("beam_surge", "sharp", 0)]).is_empty(), "a sharp surge: nothing added here (AudioTug already adds the tok, a step higher)")
	cues.tug.cfg["enabled"] = true
	var tg: Array = []
	for e in [cue("beam_struggle", "start", 0, {"n": 7400.0}), cue("beam_surge", "", 1)]:
		tg.append_array(tick(7100, [e]))
	ok(with_sound(tg, "tug.surge").size() == 1 and with_sound(tg, "perfect.tok").size() == 1, "with the struggle's sound on: the whump and the tok together on a plain push")
	cues.tug.cfg["enabled"] = false

	print("7. seeded matches, the set on: every cue valid; 1v1 and 2v2")
	var bad: String = ""
	var calls_seen: int = 0
	var calls_heard: int = 0
	var refusals: int = 0
	var digests: Array = []
	for pass_i in range(2):
		for sd in [301, 302]:
			var M := SimCore.createSim()
			SimCore.newMatch(M, sd)
			var cx := AudioCues.new(bank)
			cx.coop.cfg["enabled"] = true
			cx.reset(sd)
			var t: int = 0
			var dg: int = 7
			while t < 2400 and not (M.game.ko != null and M.game.koT > 3.0):
				SimCore.step(M)
				var out: Array = cx.consume(M, M.out.fx)
				for e in M.out.fx:
					if e.type == "cue" and e.kind == "brink_call":
						calls_seen += 1
				for c in out:
					if c.cls.begins_with("coop") or c.cls == "grip.refuse":
						dg = (dg * 31 + hash(c.sound) + int(c.gain_db * 10.0)) & 0xFFFFFF
						if c.cls == "grip.refuse":
							refusals += 1
						if c.cls == "coop.brink":
							calls_heard += 1
				bad = bad if bad != "" else _valid(out)
				M.out.fx.clear()
				M.out.feed.clear()
				t += 1
			digests.append(dg)
			SimCore.dispose(M)
	ok(bad == "", "1v1: every cue names a bank sound with finite, in-range numbers %s" % bad)
	ok(digests.size() == 4 and digests[0] == digests[2] and digests[1] == digests[3], "and a second run makes the same coop cues (%s)" % [str(digests)])
	var seen2: int = 0
	var heard2: int = 0
	var bad2: String = ""
	DirOutside.setForce(1)      # the director's 2v2 (it makes the call); restored below
	var from_own: int = 0
	var from_other: int = 0
	for sd in [311, 312]:
		var M2 := SimCore.createSim()
		SimCore.newMatch(M2, sd, {"p1": true, "p2": true, "p3": true, "p4": true}, {"intro": false, "fights": 2, "cross": true})
		var c2 := AudioCues.new(bank)
		c2.coop.cfg["enabled"] = true
		c2.reset(sd)
		var t2: int = 0
		var last_call: Dictionary = {}
		while t2 < 2400:
			SimCore.step(M2)
			if t2 == 600:
				# one fighter in each fight is broken to his brink (the core worn through), so the real call comes from both
				for body in [M2.fighters[1], M2.stage.fights[1].fighters[0]]:
					for r in range(body.stage.size()):
						if body.wd.brinkRegion[r]:
							body.wear[r] = 1000000000
			var lists: Array = []
			for k in range(M2.stage.fights.size()):
				if k != M2.stage.cur:
					lists.append(M2.stage.fights[k].out.fx)
			var out2: Array = c2.consume(M2, M2.out.fx)
			out2.append_array(c2.consume_others(M2, lists))
			for k in range(M2.stage.fights.size()):
				var evs: Array = M2.out.fx if k == M2.stage.cur else M2.stage.fights[k].out.fx
				for e in evs:
					if e.type == "cue" and e.kind == "brink_call":
						var key: String = String(e.text)
						if M2.tick - int(last_call.get(key, -99999)) >= 240:
							seen2 += 1
						last_call[key] = M2.tick
			for c in out2:
				if c.cls == "coop.brink":
					heard2 += 1
			for c in c2.consume_others(M2, []):
				bad2 = "an empty list made a cue"
			for e in M2.out.fx:
				if e.type == "cue" and e.kind == "brink_call":
					from_own += 1
			for l in lists:
				for e in l:
					if e.type == "cue" and e.kind == "brink_call":
						from_other += 1
			bad2 = bad2 if bad2 != "" else _valid(out2)
			M2.out.fx.clear()
			M2.out.feed.clear()
			t2 += 1
		SimCore.dispose(M2)
	DirOutside.setForce(-1)
	ok(from_own >= 2 and from_other >= 2, "2v2: the sim made brink calls in both the fight in S and the other (%d, %d)" % [from_own, from_other])
	ok(bad2 == "", "2v2: every cue valid %s" % bad2)
	ok(heard2 == seen2, "2v2: one sting for each call of each fighter (spaced 4 s), from either fight (%d, %d)" % [heard2, seen2])
	print("     (1v1: %d brink calls seen, %d heard, %d refusal knocks; 2v2: %d calls)" % [calls_seen, calls_heard, refusals, seen2])

	print("\ncoop check %s" % ["passed" if fails == 0 else "FAILED (%d)" % fails])
	quit(0 if fails == 0 else 1)
