extends SceneTree
## Do the moments make the sounds they should (audio/audio_moments.gd, data/moment_cues.json; docs/audio/first-play-sound.md)?
## Stages the sim's events by hand and, over seeded matches, checks the cues. The set is parked behind `enabled`; the test
## switches it on in memory only. From the repo root:
##   godot --headless --path . --script res://audio/tools/moments_check.gd
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


func ev(type: String, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = type
	for k in extra:
		e.set(k, extra[k])
	return e


func cue(kind: String, text: String, actor: int, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := ev("cue", extra)
	e.kind = kind
	e.text = text
	e.actor = float(actor)
	e.target = float(1 - actor)
	return e


func tick(t: int, events: Array) -> Array:
	S.tick = t
	S.T = float(t) / 60.0
	return cues.consume(S, events)


func sounds(list: Array) -> Array:
	return list.map(func(c): return c.sound if c.sound != "" else "(stop " + c.stop_group + ")")


func _run() -> void:
	S = SimCore.createSim()
	SimCore.newMatch(S, 4)
	S.fighters[0].x = 4000.0
	S.fighters[1].x = 4100.0
	var fx0: float = S.fighters[0].x
	var fx1: float = S.fighters[1].x
	var staged: Array = [
		cue("beam_charge", "start", 0), cue("beam_charge", "end", 0), cue("beam_fire", "", 0),
		ev("ko", {"winner": 0.0, "loser": 1.0}), ev("decisive", {"winner": 0.0, "loser": 1.0, "kind": "knockback"}),
		ev("launch", {"actor": 1.0, "target": 0.0}), ev("parry", {"actor": 0.0, "target": 1.0}),
		ev("shot_clash", {"x": 4050.0, "y": 100.0}), cue("arc_send", "meteor", 0), ev("crater", {"x": 4300.0, "y": 50.0, "energy": 20.0}),
	]

	print("1. switched off (as shipped): nothing")
	ok(not cues.moments.enabled(), "the switch is off in the data")
	cues.reset(12)
	var n_off: int = 0
	for e in staged:
		var o: Array = tick(1000, [e])
		if e.type == "crater":
			n_off = o.size()          # the ordinary crater sound only
	ok(sounds(tick(1000, [staged[0], staged[1], staged[2], staged[3], staged[4], staged[5], staged[6], staged[7]])).is_empty(), "none of the eight events makes a cue")
	ok(n_off <= 1, "the crater alone makes the ordinary crater sound (%d)" % n_off)

	print("2. switched on: each moment")
	cues.moments.cfg["enabled"] = true
	cues.reset(12)
	var o1: Array = tick(1000, [staged[0]])
	ok(sounds(o1) == ["energy.gather"] and o1[0].group == "beamcharge.0" and absf(o1[0].x - fx0) < 0.01, "a beam's charge: a gather at the shooter, in its own group (%s)" % [sounds(o1)])
	var o2: Array = tick(1030, [staged[1]])
	ok(o2.size() == 1 and o2[0].stop_group == "beamcharge.0" and o2[0].sound == "", "the charge's end cuts it")
	var o3: Array = tick(1040, [staged[2]])
	ok(sounds(o3) == ["energy.blast", "impact.heavy"] and absf(o3[0].x - fx0) < 0.01 and o3[0].pitch < 1.0, "the beam leaving: the blast and a heavy under it, low, at the shooter (%s)" % [sounds(o3)])
	var o4: Array = tick(1100, [staged[3]])
	ok(sounds(o4) == ["impact.heavy", "impact.crater"] and absf(o4[0].x - fx1) < 0.01 and o4[0].pitch <= 0.6, "a KO: a heavy hit at about half speed and a crater under it, at the loser (%s)" % [sounds(o4)])
	var o5: Array = tick(1100, [staged[4]])
	ok(sounds(o5) == ["impact.heavy"] and o5[0].gain_db < 0.0, "a decisive knockback: a heavy thump under the blow")
	ok(tick(1100, [ev("decisive", {"winner": 0.0, "loser": 1.0, "kind": "launch"})]).is_empty() and tick(1100, [ev("decisive", {"winner": 0.0, "loser": 1.0, "kind": "beam_clash"})]).is_empty(), "a decisive launch and beam clash add nothing (the launch's whoosh and the struggle's lock are theirs)")
	var o6: Array = tick(1110, [staged[5]])
	ok(sounds(o6) == ["rush.whoosh"] and absf(o6[0].x - fx1) < 0.01, "a launch: the whoosh at the sent body, not the launcher")
	ok(sounds(tick(1120, [staged[6]])) == ["impact.absorbed"], "a parry: the absorbed hit")
	var o7: Array = tick(1120, [staged[7]])
	ok(sounds(o7) == ["impact.guard"] and absf(o7[0].x - 4050.0) < 40.0, "two bolts meeting: a guard thud at the meeting point")

	print("3. the meteor's landing")
	cues.reset(12)
	var m0: Array = tick(2000, [staged[8]])
	ok(m0.is_empty(), "the send is silent and so is the flight (the silence before the landing is kept)")
	var small: Array = tick(2100, [ev("crater", {"x": 4300.0, "y": 50.0, "energy": 1.0})])
	ok(sounds(small).filter(func(s): return s == "impact.heavy").is_empty(), "a small crater in flight is not the landing")
	var m1: Array = tick(2300, [ev("crater", {"x": 4300.0, "y": 50.0, "energy": 20.0})])
	var s1: Array = sounds(m1)
	ok(s1.count("impact.crater") == 2 and s1.count("impact.heavy") == 1, "the landing: the ordinary crater, and the meteor's crater and heavy layered on it (%s)" % [s1])
	var deep: bool = false
	var loud: bool = false
	for c in m1:
		if c.cls == "moment.meteor" and c.sound == "impact.crater":
			deep = c.pitch <= 0.55
			loud = c.gain_db >= 2.0
	ok(deep and loud, "the meteor's crater is as low and as loud as the cue limits allow (pitch 0.5, +3 dB)")
	var m2: Array = tick(2310, [ev("crater", {"x": 4300.0, "y": 50.0, "energy": 20.0})])
	ok(sounds(m2).count("impact.heavy") == 0, "once: the next big crater is an ordinary one")
	cues.reset(12)
	tick(3000, [staged[8]])
	var late: Array = tick(3000 + 1600, [ev("crater", {"x": 4300.0, "y": 50.0, "energy": 20.0})])
	ok(sounds(late).count("impact.heavy") == 0, "past the window it is not the meteor's")

	print("4. seeded matches, the set on: every cue is valid and each moment sounds as often as it happens")
	var all_ok: bool = true
	var why: String = ""
	var fires: int = 0
	var fire_cues: int = 0
	var kos: int = 0
	var ko_cues: int = 0
	var launches: int = 0
	var launch_cues: int = 0
	var meteors: int = 0
	for sd in [301, 302, 303, 304]:
		var M := SimCore.createSim()
		SimCore.newMatch(M, sd)
		var cm := AudioCues.new(bank)
		cm.moments.cfg["enabled"] = true
		cm.reset(sd)
		var t: int = 0
		while t < 3600 and not (M.game.ko != null and M.game.koT > 3.0):
			SimCore.step(M)
			var out: Array = cm.consume(M, M.out.fx)
			for e in M.out.fx:
				if e.type == "cue" and e.kind == "beam_fire":
					fires += 1
				elif e.type == "ko":
					kos += 1
				elif e.type == "launch":
					launches += 1
				elif e.type == "cue" and e.kind == "arc_send" and e.text == "meteor":
					meteors += 1
			for c in out:
				if c.cls == "moment.fire" and c.sound == "energy.blast":
					fire_cues += 1
				elif c.cls == "moment.ko" and c.sound == "impact.heavy":
					ko_cues += 1
				elif c.cls == "moment.launch":
					launch_cues += 1
				if c.sound == "":
					continue
				if not bank.has_sound(c.sound):
					all_ok = false
					why = "no such sound " + c.sound
				elif c.variant < 0 or c.variant >= bank.variants(c.sound):
					all_ok = false
					why = "variant out of range for " + c.sound
				elif not (is_finite(c.gain_db) and is_finite(c.pitch) and is_finite(c.x) and is_finite(c.y)) or c.pitch < 0.4 or c.pitch > 2.0 or c.gain_db < -20.0 or c.gain_db > 8.0:
					all_ok = false
					why = "number out of range for %s: gain %.1f pitch %.2f" % [c.sound, c.gain_db, c.pitch]
			M.out.fx.clear()
			M.out.feed.clear()
			t += 1
		SimCore.dispose(M)
	ok(all_ok, "every cue names a bank sound with finite, in-range numbers %s" % why)
	ok(fire_cues == fires, "one blast for each beam fired (%d, %d)" % [fire_cues, fires])
	ok(ko_cues == kos, "one KO hit for each KO (%d, %d)" % [ko_cues, kos])
	ok(launch_cues == launches, "one whoosh for each launch (%d, %d)" % [launch_cues, launches])
	print("     (%d meteor sends in these matches)" % meteors)

	print("\nmoments check %s" % ["passed" if fails == 0 else "FAILED (%d)" % fails])
	quit(0 if fails == 0 else 1)
