extends SceneTree
## Does the beam struggle's sound behave? Stages Encounter's five cues (beam_struggle, beam_pulse, beam_surge, beam_stray,
## beam_end; docs/audio/launch-and-tug.md) and the meeting point (Clash.mid), feeds them to AudioCues, and plays the cues
## through AudioVoices to check the looped voice. The struggle is parked behind data/tug_cues.json "enabled"; the test
## switches it on in memory only. From the repo root:
##   godot --headless --path . --script res://audio/tools/tug_check.gd
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


func tick(t: int, events: Array) -> Array:
	S.tick = t
	S.T = float(t) / 60.0
	return cues.consume(S, events)


func with_sound(list: Array, id: String) -> Array:
	return list.filter(func(c): return c.sound == id)


func set_mid(m: float) -> void:
	S.game.clash.mid = m


func _run() -> void:
	S = SimCore.createSim()
	SimCore.newMatch(S, 4)
	S.fighters[0].x = 4000.0
	S.fighters[1].x = 4100.0
	S.fighters[0].y = 0.0
	S.fighters[1].y = 0.0
	_dormant()
	cues.tug.cfg["enabled"] = true
	_struggle()
	_ends()
	_drone()
	await _voices()
	S.game.clash = null
	SimCore.dispose(S)
	print("\ntug check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)


func _clash(mid: float) -> void:
	var c := SimState.Clash.new()
	c.A = S.fighters[0]
	c.D = S.fighters[1]
	c.mid = mid
	S.game.clash = c


func _dormant() -> void:
	print("1. parked: with `enabled` false the five cues make nothing")
	cues.reset(5)
	_clash(0.5)
	var t: int = 100000
	var n: int = 0
	for e in [cue("beam_struggle", "start", 0, {"n": t + 300}), cue("beam_pulse", "", 0, {"k": 1.0}), cue("beam_surge", "sharp", 0), cue("beam_stray", "", 1), cue("beam_end", "overwhelmed", 0)]:
		n += tick(t, [e]).size()
		t += 20
	ok(n == 0, "no cue from any of them (%d)" % n)
	ok(not cues.tug.enabled(), "and the switch is off in the data")


func _struggle() -> void:
	print("2. a struggle: the lock, the bed, the pulse, the surge, the stray")
	cues.reset(6)
	_clash(0.5)
	var t: int = 110000
	var r: Array = tick(t, [cue("beam_struggle", "start", 0, {"n": t + 300})])
	var lock: Array = with_sound(r, "tug.lock")
	ok(lock.size() == 1 and absf(lock[0].pitch - 0.9) < 0.001 and lock[0].duck.size() == 1 and lock[0].duck[0].bus == "Music", "the start is the clash thud, and the music ducks")
	ok(with_sound(r, "impact.heavy").size() == 1, "with the heavy impact under it")
	var lo: Array = with_sound(r, "drone.bed.lo")
	var hi: Array = with_sound(r, "drone.bed.hi")
	ok(lo.size() == 1 and hi.size() == 1 and lo[0].loop and hi[0].loop and not lo[0].update, "two looped drones start")
	ok(lo[0].group == "tug.bed.lo" and hi[0].group == "tug.bed.hi" and lo[0].cls == "tug.bed" and lo[0].cap == 2, "each in its own group, one class of two")
	ok(absf(lo[0].x - 4050.0) < 0.01, "at the meeting point, between the fighters (%.1f)" % lo[0].x)
	ok(absf(lo[0].gain_db + 20.0) < 0.01 and absf(lo[0].pitch - 1.0) < 0.001 and absf(hi[0].gain_db + 28.0) < 0.01 and absf(hi[0].pitch - 1.003) < 0.0005, "even: the low drone at -20 dB, the high one at -28 dB and 0.3% sharp (the slow beat)")
	# the point moves: the bed follows
	set_mid(0.8)
	r = tick(t + 5, [])
	lo = with_sound(r, "drone.bed.lo")
	hi = with_sound(r, "drone.bed.hi")
	ok(lo.size() == 1 and hi.size() == 1 and lo[0].update and lo[0].loop and lo[0].ramp_ms == 120, "a moved point is an update of the two drones over 120 ms")
	ok(absf(lo[0].x - 4080.0) < 0.01, "to the new place (%.1f)" % lo[0].x)
	var want_pitch: float = pow(2.0, 5.0 * 0.6 / 12.0)
	ok(absf(lo[0].pitch - want_pitch) < 0.001 and absf(lo[0].gain_db + 15.2) < 0.01, "pitch up %.3f and louder (%.1f dB) at 60%% of the way to an end" % [lo[0].pitch, lo[0].gain_db])
	ok(absf(hi[0].gain_db + 17.2) < 0.01 and absf(hi[0].pitch - want_pitch * 1.015) < 0.001, "the high drone louder still and detuned further (beat %.2f%%)" % ((hi[0].pitch / lo[0].pitch - 1.0) * 100.0))
	ok(tick(t + 6, []).is_empty(), "no change, no update")
	set_mid(0.802)
	ok(tick(t + 7, []).is_empty(), "a step under half a percent of the line is not worth an update")
	set_mid(0.5)
	ok(tick(t + 7, []).is_empty(), "a big move 2 ticks after the last update waits (updates are at least 3 ticks apart)")
	r = tick(t + 8, [])
	lo = with_sound(r, "drone.bed.lo")
	ok(lo.size() == 1 and absf(lo[0].gain_db + 20.0) < 0.01 and absf(lo[0].pitch - 1.0) < 0.001, "then it is sent: back at the middle, -20 dB and the original pitch")
	# pulse
	r = tick(t + 20, [cue("beam_pulse", "", 0, {"k": 1.0, "n": t + 20})])
	var pu: Array = with_sound(r, "tug.pulse")
	ok(pu.size() == 1 and absf(pu[0].pitch - 1.0) < 0.001 and pu[0].variant == 0 and pu[0].duck.size() == 1, "the pulse at an even point: a fixed thud, the music held down")
	set_mid(1.0)
	r = tick(t + 40, [cue("beam_pulse", "", 0, {"k": 2.0, "n": t + 40})])
	pu = with_sound(r, "tug.pulse")
	ok(pu.size() == 1 and absf(pu[0].pitch - pow(2.0, 4.0 / 12.0)) < 0.001, "at an end its pitch is four semitones up (x%.3f)" % pu[0].pitch)
	set_mid(0.5)
	# surge
	r = tick(t + 60, [cue("beam_surge", "surge", 0)])
	var su: Array = with_sound(r, "tug.surge")
	ok(su.size() == 1 and absf(su[0].gain_db + 3.0) < 0.01 and with_sound(r, "perfect.tok").is_empty(), "a surge: the rising whump, nothing else")
	r = tick(t + 80, [cue("beam_surge", "sharp", 1)])
	su = with_sound(r, "tug.surge")
	var tok: Array = with_sound(r, "perfect.tok")
	ok(su.size() == 1 and absf(su[0].gain_db + 1.5) < 0.01 and tok.size() == 1 and absf(tok[0].pitch - 1.12246) < 0.001, "a sharp surge is 1.5 dB louder and adds the perfect follow-up's tok")
	ok(absf(su[0].x - S.fighters[1].x) < 0.01, "at the fighter who pressed")
	# strays: a mash is never a buzz
	var droops: int = 0
	for i in range(10):
		droops += with_sound(tick(t + 100 + i, [cue("beam_stray", "", 0)]), "perfect.break").size()
	ok(droops == 1, "ten strays in ten ticks make one droop (%d)" % droops)
	ok(with_sound(tick(t + 125, [cue("beam_stray", "", 0)]), "perfect.break").size() == 1, "and the next after 20 ticks is heard")
	ok(with_sound(tick(t + 125, [cue("beam_stray", "", 1)]), "perfect.break").size() == 1, "each fighter has his own")
	# determinism
	var d1: String = _digest()
	var d2: String = _digest()
	ok(d1 == d2 and d1 != "", "the same cues give the same sounds twice")
	# a point from the cue when the clash has none
	cues.reset(7)
	S.game.clash = null
	r = tick(t + 500, [cue("beam_struggle", "start", 0, {"n": t + 800, "amount": 0.7})])
	lo = with_sound(r, "drone.bed.lo")
	ok(lo.size() == 1 and absf(lo[0].gain_db - (-20.0 + 8.0 * 0.4)) < 0.01, "with no Clash.mid, the cue's amount is the point (0.7: -16.8 dB)")
	# a pulse with no struggle running
	cues.reset(8)
	_clash(0.5)
	ok(tick(t + 600, [cue("beam_pulse", "", 0, {"k": 1.0})]).is_empty(), "a pulse before any start makes nothing")


func _digest() -> String:
	cues.reset(9)
	_clash(0.5)
	var lines := PackedStringArray()
	var t: int = 120000
	var script: Array = [cue("beam_struggle", "start", 0, {"n": t + 300}), cue("beam_pulse", "", 0, {"k": 1.0}), cue("beam_surge", "sharp", 0), cue("beam_stray", "", 1), cue("beam_end", "overwhelmed", 0)]
	for i in range(script.size()):
		set_mid(0.5 + 0.1 * float(i))
		for c in tick(t + 20 * i, [script[i]]):
			lines.append("%d|%s|%d|%.4f|%.3f|%.2f|%s" % [i, c.sound, c.variant, c.pitch, c.gain_db, c.x, c.stop_group])
	return "\n".join(lines).sha256_text()


func _ends() -> void:
	print("3. the three ends, and the safety stop")
	for kind in ["overwhelmed", "detonate", "time"]:
		cues.reset(10)
		_clash(0.5)
		var t: int = 130000
		tick(t, [cue("beam_struggle", "start", 0, {"n": t + 300})])
		set_mid(1.0 if kind == "overwhelmed" else (0.52 if kind == "detonate" else 0.7))
		var r: Array = tick(t + 100, [cue("beam_end", kind, 0, {"x": 4050.0})])
		var stops: Array = r.filter(func(c): return c.sound == "" and c.stop_group.begins_with("tug.bed"))
		var fade: int = {"overwhelmed": 350, "detonate": 60, "time": 300}[kind]
		ok(stops.size() == 2 and stops[0].fade_ms == fade, "%s: both drones stop, fading over %d ms" % [kind, fade])
		var snd: String = {"overwhelmed": "tug.fall", "detonate": "impact.double", "time": "impact.medium"}[kind]
		ok(with_sound(r, snd).size() == 1, "%s: %s" % [kind, snd])
		if kind == "overwhelmed":
			ok(absf(with_sound(r, "tug.fall")[0].x - 4100.0) < 0.01 and with_sound(r, "energy.blast").size() == 1 and absf(with_sound(r, "energy.blast")[0].pitch - 0.9) < 0.001, "the loser stands at the end the point reached, and the beam lands on him")
		if kind == "detonate":
			ok(with_sound(r, "energy.blast").size() == 1 and absf(with_sound(r, snd)[0].x - 4052.0) < 0.01, "the boom is where the beams meet (the point, 0.52 of the way)")
		if kind == "time":
			ok(absf(with_sound(r, snd)[0].x - 4100.0) < 0.01, "on time, at the side the point is on")
		ok(tick(t + 120, [cue("beam_pulse", "", 0, {"k": 9.0})]).is_empty(), "%s: after the end nothing more sounds" % kind)
	# a missed end cue must not leave a drone running
	cues.reset(11)
	_clash(0.5)
	tick(140000, [cue("beam_struggle", "start", 0, {"n": 140300})])
	var late: Array = tick(140000 + 901, [])
	var ls: Array = late.filter(func(c): return c.sound == "" and c.stop_group.begins_with("tug.bed"))
	ok(ls.size() == 2 and ls[0].fade_ms == 300, "a struggle with no end cue is stopped after 900 ticks")
	ok(tick(140000 + 902, []).is_empty(), "and once")


func _drone() -> void:
	print("4. the drones loop without a seam")
	for id in ["drone.bed.lo", "drone.bed.hi"]:
		ok(bank.has_sound(id) and bank.rate_of(id) == 32000 and not (id in bank.ids()), "%s is in the bank, at 32 kHz, and not warmed with the one-shots" % id)
		var b: PackedFloat32Array = bank.buffer(id, 0)
		var step: float = 0.0
		for i in range(1, 400):
			step = maxf(step, absf(b[i] - b[i - 1]))
		var seam: float = absf(b[0] - b[b.size() - 1])
		print("     %s %d samples, peak %.1f dBFS, seam %.5f against a largest step of %.5f" % [id, b.size(), 20.0 * log(AudioDsp.peak(b)) / log(10.0), seam, step])
		ok(b.size() == 64000 and seam <= step * 1.01 and absf(b[0]) < 0.001, "%s: the last sample runs into the first as a normal step does" % id)
		ok(absf(20.0 * log(AudioDsp.peak(b)) / log(10.0) + 12.0) < 0.2, "%s: normalised to -12 dBFS" % id)
	var lo: PackedFloat32Array = bank.buffer("drone.bed.lo", 0)
	var hi: PackedFloat32Array = bank.buffer("drone.bed.hi", 0)
	ok(AudioDsp.rms(hi) != AudioDsp.rms(lo), "the high drone is the one with the harmonics")
	for id in ["tug.pulse", "tug.surge", "tug.lock", "tug.fall"]:
		var b2: PackedFloat32Array = bank.buffer(id, 0)
		ok(AudioDsp.peak(b2) < 0.99 and absf(b2[b2.size() - 1]) < 0.01, "%s: no clipping, clean end (%.2f s)" % [id, float(b2.size()) / bank.rate_of(id)])


func _voices() -> void:
	print("5. the looped voice in AudioVoices")
	var v := AudioVoices.new(bank)
	root.add_child(v)
	await process_frame
	cues.reset(12)
	_clash(0.5)
	var t: int = 150000
	var start: Array = tick(t, [cue("beam_struggle", "start", 0, {"n": t + 300})])
	var cam: float = 4050.0
	for c in start:
		v.play(c, cam, 1.0)
	var found: int = 0
	var looped: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and String(v._meta[i].group).begins_with("tug.bed"):
			found += 1
			if v._pool[i].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and v._pool[i].stream.loop_end == 64000:
				looped += 1
	ok(found == 2 and looped == 2, "both drones play, looped over their whole length (%d, %d)" % [found, looped])
	ok(bank.stream("drone.bed.lo", 0).loop_mode == AudioStreamWAV.LOOP_DISABLED, "and the bank's own stream is still a one-shot")
	# the point moves: the voices follow
	set_mid(0.9)
	var upd: Array = tick(t + 6, [])
	var moved: int = 0
	for c in upd:
		if v.play(c, cam, 1.0):
			moved += 1
	ok(moved == 2, "an update finds both voices")
	await create_timer(0.35).timeout
	var want: float = pow(2.0, 5.0 * 0.8 / 12.0)
	var got: float = 0.0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "tug.bed.lo":
			got = v._pool[i].pitch_scale
	ok(absf(got - want) < 0.01, "after the ramp the low drone is at its new pitch (%.3f against %.3f)" % [got, want])
	var updated_again: bool = v.update_group("tug.nothing", 0.0, 1.0, 100, 0.0)
	ok(not updated_again, "an update for a group that is not playing finds nothing")
	# a one-shot in the middle does not disturb the bed
	var pulse: Array = tick(t + 20, [cue("beam_pulse", "", 0, {"k": 1.0})])
	for c in pulse:
		v.play(c, cam, 1.0)
	var still: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and String(v._meta[i].group).begins_with("tug.bed"):
			still += 1
	ok(still == 2, "a pulse and its duck leave the bed playing")
	# the end stops them
	set_mid(1.0)
	var fin: Array = tick(t + 100, [cue("beam_end", "overwhelmed", 0)])
	for c in fin:
		v.play(c, cam, 1.0)
	await create_timer(0.5).timeout
	var left: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and String(v._meta[i].group).begins_with("tug.bed"):
			left += 1
	ok(left == 0, "the end fades both drones out and stops them")
	v.queue_free()
	await process_frame
