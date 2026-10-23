extends SceneTree
## Does the sound that carries what the HUD no longer draws behave? Stages the cues and events (the beam struggle's pulse,
## surge and nearing end; the grip; the ready form and the coil; the brake; a rush; a perfect block) and feeds them to
## AudioCues; plays the coil's hum through AudioVoices. The set is parked behind data/carry_cues.json "enabled"; the test
## switches it on in memory only. From the repo root:
##   godot --headless --path . --script res://audio/tools/carry_check.gd
## Exit code 1 on any failure. No sound device is used (the dummy audio driver).

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


func ev(type: String, actor: int, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = type
	e.actor = float(actor)
	e.target = float(1 - actor)
	for k in extra:
		e.set(k, extra[k])
	return e


func tick(t: int, events: Array) -> Array:
	S.tick = t
	S.T = float(t) / 60.0
	return cues.consume(S, events)


func with_sound(list: Array, id: String) -> Array:
	return list.filter(func(c): return c.sound == id)


func _clash(mid: float) -> void:
	var c := SimState.Clash.new()
	c.A = S.fighters[0]
	c.D = S.fighters[1]
	c.mid = mid
	S.game.clash = c


func set_mid(m: float) -> void:
	S.game.clash.mid = m


func _run() -> void:
	S = SimCore.createSim()
	SimCore.newMatch(S, 4)
	S.fighters[0].x = 4000.0
	S.fighters[1].x = 4100.0
	S.fighters[0].y = 0.0
	S.fighters[1].y = 0.0
	_parked()
	cues.tug.cfg["enabled"] = true
	cues.carry.cfg["enabled"] = true
	_struggle()
	_grip()
	_forms_brake_rush()
	_sounds()
	await _voices()
	S.game.clash = null
	SimCore.dispose(S)
	print("\ncarry check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)


func _parked() -> void:
	print("1. parked: with `enabled` false nothing is made")
	cues.reset(5)
	var t: int = 200000
	var n: int = 0
	var list: Array = [cue("grapple_clinch", "start", 0), cue("grapple_pulse", "", 0, {"amount": 3.0}), cue("grapple_pummel", "sharp", 0), cue("grapple_refused", "lockout", 1), cue("perfect_block", "", 1),
		ev("rush", 0, {"n": t + 12}), ev("transform_ready", 0), ev("form_hold", 0, {"amount": 50.0}), ev("form_release", 0), ev("air_brake", 0, {"text": "start", "amount": 4000.0})]
	for e in list:
		n += tick(t, [e]).size()
		t += 20
	ok(n == 0 and not cues.carry.enabled(), "none of the ten makes a cue (%d), and the switch is off in the data" % n)


func _struggle() -> void:
	print("2. the beam struggle: the groove, the cracks")
	cues.reset(6)
	_clash(0.5)
	var t: int = 210000
	tick(t, [cue("beam_struggle", "start", 0, {"n": t + 300})])
	var r: Array = tick(t + 20, [cue("beam_pulse", "", 0, {"k": 1.0, "n": t + 20})])
	ok(with_sound(r, "tug.pulse").size() == 1, "the pulse is the kick")
	ok(tick(t + 25, []).is_empty(), "nothing at 5 ticks while the point is in the middle")
	r = tick(t + 30, [])
	var tock: Array = with_sound(r, "tug.tock")
	ok(tock.size() == 1 and absf(tock[0].pitch - 1.0) < 0.001, "the off-beat knock lands 10 ticks after the kick")
	# far from the middle: the sixteenths too, a semitone-step higher
	set_mid(0.95)
	tick(t + 35, [])
	r = tick(t + 40, [cue("beam_pulse", "", 0, {"k": 2.0, "n": t + 40})])
	var got: int = 0
	var ticks_at: Array = []
	for dt in range(41, 61):
		var rr: Array = tick(t + dt + 0, [])
		for c in rr:
			if c.sound == "tug.tick":
				ticks_at.append(dt - 0)
			if c.sound == "tug.tock":
				got += 1
	ok(ticks_at == [45, 55] and got == 1, "near an end the taps come at 5 and 15 ticks and the knock at 10 (%s)" % str(ticks_at))
	# the cracks
	cues.reset(7)
	_clash(0.5)
	t = 220000
	tick(t, [cue("beam_struggle", "start", 0, {"n": t + 300})])
	var cracks: Array = []
	for m in [0.6, 0.7, 0.82, 0.86, 0.96, 0.7, 0.99]:
		set_mid(m)
		t += 10
		for c in tick(t, []):
			if c.sound == "tug.crack":
				cracks.append(snappedf(c.pitch, 0.01))
	ok(cracks.size() >= 3, "the beams crack as the point nears an end (%s)" % str(cracks))
	cues.reset(8)
	_clash(0.5)
	t = 230000
	tick(t, [cue("beam_struggle", "start", 0, {"n": t + 300})])
	var seq: Array = []
	for m in [0.5, 0.82, 0.83, 0.9, 0.96, 0.5, 0.82]:
		set_mid(m)
		t += 10
		for c in tick(t, []):
			if c.sound == "tug.crack":
				seq.append(snappedf(c.pitch, 0.01))
	ok(seq == [0.9, 1.0, 1.1, 0.9], "each threshold cracks once on the way up, and again after the point has gone back (%s)" % str(seq))
	r = tick(t + 10, [cue("beam_surge", "surge", 0)])
	var cr: Array = with_sound(r, "tug.crack")
	ok(cr.size() == 1 and absf(cr[0].gain_db + 5.0) < 0.01 and absf(cr[0].pitch - 1.0) < 0.001, "a surge cracks, at -5 dB")
	r = tick(t + 11, [cue("beam_surge", "sharp", 1)])
	cr = with_sound(r, "tug.crack")
	ok(cr.size() == 1 and absf(cr[0].gain_db + 1.0) < 0.01 and absf(cr[0].pitch - 1.2) < 0.001, "a sharp one cracks louder and higher, at the presser (x %.0f)" % cr[0].x)
	# the end clears the groove
	ok(tick(t + 20, [cue("beam_end", "overwhelmed", 0)]).size() > 0, "the end still sounds as before")
	ok(tick(t + 40, []).filter(func(c): return c.sound.begins_with("tug.t")).is_empty(), "and nothing of the groove after it")


func _grip() -> void:
	print("3. the grip")
	cues.reset(9)
	var t: int = 240000
	var r: Array = tick(t, [cue("grapple_clinch", "start", 0, {"k": 1.0, "n": t})])
	var cl: Array = with_sound(r, "grip.clasp")
	ok(cl.size() == 1 and absf(cl[0].x - 4100.0) < 0.01, "a clinch starts with a clasp, at the one caught")
	ok(tick(t + 1, [cue("grapple_clinch", "stop", 0)]).is_empty(), "only its start")
	var pitches: Array = []
	for g in [0, 2, 5, 9]:
		r = tick(t + 20 + g, [cue("grapple_pulse", "", 0, {"amount": float(g), "k": 1.0})])
		pitches.append(snappedf(with_sound(r, "grip.creak")[0].pitch, 0.001))
	ok(pitches[0] == 1.0 and pitches[1] > pitches[0] and pitches[2] > pitches[1] and pitches[3] == pitches[2], "the creak climbs a semitone a point of grip and stops at 5 (%s)" % str(pitches))
	r = tick(t + 40, [cue("grapple_pummel", "step", 0, {"k": 2.0})])
	ok(with_sound(r, "grip.thud").size() == 1 and with_sound(r, "perfect.tok").is_empty(), "a pummel thuds")
	r = tick(t + 41, [cue("grapple_pummel", "sharp", 0, {"k": 3.0})])
	ok(with_sound(r, "grip.thud").size() == 1 and with_sound(r, "perfect.tok").size() == 1, "a sharp one adds the tok")
	ok(tick(t + 42, [cue("grapple_pummel", "void", 0)]).is_empty() and tick(t + 43, [cue("grapple_stray", "", 0)]).is_empty(), "a void pummel and a stray are silent")
	r = tick(t + 50, [cue("grapple_refused", "lockout", 1, {"n": t + 70})])
	var rf: Array = with_sound(r, "grip.refuse")
	ok(rf.size() == 1 and absf(rf[0].x - 4100.0) < 0.01, "a press in the lockout gets the short dull refusal, at the presser")
	ok(tick(t + 51, [cue("grapple_refused", "busy", 1)]).is_empty() and tick(t + 52, [cue("grapple_refused", "thrown", 1)]).is_empty(), "a busy or thrown refusal is silent")


func _forms_brake_rush() -> void:
	print("4. the ready sting, the coil's hum, the skid, the rush, the perfect block")
	cues.reset(10)
	var t: int = 250000
	var r: Array = tick(t, [ev("transform_ready", 0, {"tier": 2.0})])
	var rd: Array = with_sound(r, "form.ready")
	ok(rd.size() == 1 and rd[0].bus == "Alert", "a form comes ready: the sting, unducked")
	r = tick(t + 60, [ev("form_hold", 0, {"n": 1.0, "dur": 1.0, "amount": 10.0})])
	var h: Array = with_sound(r, "drone.coil")
	ok(h.size() == 1 and h[0].loop and not h[0].update and h[0].group == "coil.0", "a held form starts the coil's hum, looped, in the fighter's own group")
	var g0: float = h[0].gain_db
	r = tick(t + 200, [ev("form_hold", 0, {"n": 1.0, "dur": 4.0, "amount": 80.0})])
	h = with_sound(r, "drone.coil")
	ok(h.size() == 1 and h[0].update and h[0].gain_db > g0 + 5.0 and h[0].pitch > 1.1, "a bigger coil lifts it: louder (+%.1f dB) and higher (x%.3f)" % [h[0].gain_db - g0, h[0].pitch])
	r = tick(t + 300, [ev("form_release", 0, {"n": 1.0, "amount": 80.0})])
	ok(r.size() == 1 and r[0].sound == "" and r[0].stop_group == "coil.0", "the release stops it")
	ok(tick(t + 310, [ev("form_release", 0, {"n": 1.0})]).is_empty(), "and only once")
	# brake
	r = tick(t + 400, [ev("air_brake", 1, {"text": "start", "kind": "held", "amount": 5000.0})])
	var sk: Array = with_sound(r, "brake.skid")
	ok(sk.size() == 1 and sk[0].group == "brake.1" and absf(sk[0].gain_db - 2.0) < 0.01 and absf(sk[0].pitch - 1.15) < 0.001, "the brake starts a skid: louder and higher for a faster send (%.1f dB, x%.2f)" % [sk[0].gain_db, sk[0].pitch])
	r = tick(t + 400, [ev("air_brake", 0, {"text": "start", "kind": "held", "amount": 1000.0})])
	ok(with_sound(r, "brake.skid")[0].gain_db < sk[0].gain_db, "a slow send skids quieter")
	r = tick(t + 430, [ev("air_brake", 1, {"text": "end", "kind": "speed", "amount": 1200.0})])
	ok(r.size() == 1 and r[0].stop_group == "brake.1" and r[0].fade_ms == 150, "the end of the brake cuts it")
	# the ring's turn
	var keep_x: Array = [S.fighters[0].x, S.fighters[1].x]
	S.fighters[0].x = 2500.0
	S.fighters[1].x = 2700.0
	r = tick(t + 450, [ev("arena_turn", 0, {"n": 1.0, "x": 9000.0, "amount": 10.0, "k": 10.0})])
	var at: Array = with_sound(r, "arena.shift")
	ok(at.size() == 1 and absf(at[0].x - 2600.0) < 0.01 and at[0].bus == "Sfx", "the ring's turn is one low shift at the pair (x %.0f), not at the far pivot" % at[0].x)
	r = tick(t + 460, [ev("arena_turn", 0, {"n": 2.0, "x": 9000.0, "amount": 2.5, "k": 12.5})])
	var at2: Array = with_sound(r, "arena.shift")
	ok(at2.size() == 1 and at2[0].pitch > at[0].pitch and at2[0].gain_db < at[0].gain_db, "a small turn is a little higher and quieter than a full one (x%.3f, %.1f dB against x%.3f, %.1f dB)" % [at2[0].pitch, at2[0].gain_db, at[0].pitch, at[0].gain_db])
	cues.carry.cfg["enabled"] = false
	ok(tick(t + 470, [ev("arena_turn", 0, {"n": 3.0, "x": 9000.0, "amount": 5.0})]).is_empty(), "parked, it makes nothing")
	cues.carry.cfg["enabled"] = true
	S.fighters[0].x = keep_x[0]
	S.fighters[1].x = keep_x[1]
	# rush
	S.fighters[0].x = 2500.0
	r = tick(t + 500, [ev("rush", 0, {"n": t + 500 + 18})])
	var rs: Array = with_sound(r, "rush.whoosh")
	ok(rs.size() == 1 and absf(rs[0].x - 2500.0) < 0.01 and absf(rs[0].pitch - 1.0) < 0.001, "a rush is a whoosh at the rusher (x %.0f), at its own length" % rs[0].x)
	r = tick(t + 600, [ev("rush", 0, {"n": t + 600 + 9})])
	ok(with_sound(r, "rush.whoosh")[0].pitch > 1.3, "a shorter, faster one is higher")
	S.fighters[0].x = 4000.0
	# perfect block
	r = tick(t + 700, [cue("perfect_block", "", 1)])
	var pb: Array = with_sound(r, "block.perfect")
	ok(pb.size() == 1 and absf(pb[0].x - 4100.0) < 0.01, "a perfect block has its own sound, at the blocker")
	# determinism
	var d1: String = _digest()
	var d2: String = _digest()
	ok(d1 == d2 and d1 != "", "the same events give the same sounds twice")


func _digest() -> String:
	cues.reset(11)
	_clash(0.5)
	var lines := PackedStringArray()
	var t: int = 260000
	var script: Array = [cue("beam_struggle", "start", 0, {"n": t + 300}), cue("beam_pulse", "", 0, {"k": 1.0}), cue("grapple_pulse", "", 0, {"amount": 3.0}), ev("form_hold", 0, {"amount": 40.0}), ev("rush", 1, {"n": t + 100}), cue("perfect_block", "", 1)]
	for i in range(script.size()):
		set_mid(0.5 + 0.08 * float(i))
		for k in range(0, 40, 5):
			var evs: Array = [script[i]] if k == 0 else []
			for c in tick(t + 40 * i + k, evs):
				lines.append("%d|%d|%s|%d|%.4f|%.3f|%.2f" % [i, k, c.sound, c.variant, c.pitch, c.gain_db, c.x])
	return "\n".join(lines).sha256_text()


func _sounds() -> void:
	print("5. the sounds")
	for id in ["tug.tock", "tug.tick", "tug.crack", "grip.clasp", "grip.creak", "grip.thud", "grip.refuse", "form.ready", "brake.skid", "rush.whoosh", "block.perfect"]:
		var b: PackedFloat32Array = bank.buffer(id, 0)
		ok(AudioDsp.peak(b) < 0.99 and absf(b[b.size() - 1]) < 0.01 and float(b.size()) / bank.rate_of(id) < 0.7, "%s: no clipping, clean end, %.2f s" % [id, float(b.size()) / bank.rate_of(id)])
	var d: PackedFloat32Array = bank.buffer("drone.coil", 0)
	var step: float = 0.0
	for i in range(1, 400):
		step = maxf(step, absf(d[i] - d[i - 1]))
	ok(bank.has_sound("drone.coil") and d.size() == 64000 and absf(d[0] - d[d.size() - 1]) <= step * 1.01, "the coil's drone loops without a seam")


func _voices() -> void:
	print("6. the coil's hum through AudioVoices")
	var v := AudioVoices.new(bank)
	root.add_child(v)
	await process_frame
	cues.reset(12)
	var t: int = 270000
	for c in tick(t, [ev("form_hold", 0, {"n": 1.0, "dur": 1.0, "amount": 20.0})]):
		v.play(c, 4050.0, 1.0)
	var found: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "coil.0" and v._pool[i].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD:
			found += 1
	ok(found == 1, "the hum plays, looped")
	for c in tick(t + 100, [ev("form_hold", 0, {"n": 1.0, "dur": 3.0, "amount": 90.0})]):
		v.play(c, 4050.0, 1.0)
	await create_timer(1.0).timeout
	var pitch: float = 0.0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "coil.0":
			pitch = v._pool[i].pitch_scale
	ok(pitch > 1.2, "it rises with the coil (x%.3f)" % pitch)
	for c in tick(t + 200, [ev("form_release", 0, {"n": 1.0})]):
		v.play(c, 4050.0, 1.0)
	await create_timer(0.45).timeout
	var left: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "coil.0":
			left += 1
	ok(left == 0, "and the release fades it out")
	v.queue_free()
	await process_frame
