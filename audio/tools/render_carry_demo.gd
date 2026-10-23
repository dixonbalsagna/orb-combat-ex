extends SceneTree
## Render dry listening clips (no music underneath) of the sounds that carry what the HUD no longer draws, made by the real
## mappers (AudioTug and AudioCarry) from STAGED events: the cues of the beam struggle, the grip, the forms, the brake, a rush and a
## perfect block. From the repo root:
##   godot --headless --path . --script res://audio/tools/render_carry_demo.gd [-- --out=DIR]
## Writes DIR/struggle-beat-dry.wav, DIR/grip-dry.wav, DIR/forms-brake-rush-dry.wav and DIR/arena-turn-dry.wav (default audio/preview/carry). Mono 16-bit at
## 22.05 kHz; a looped voice (the struggle's bed, the coil's hum) is rendered by following its updates. The stereo place a
## cue would have in the game is not heard in a mono file. Not a game recording.

const RATE := 22050
var bank: AudioBank
var S: SimState
var cues: AudioCues


func _init() -> void:
	var out_dir: String = ProjectSettings.globalize_path("res://audio/preview/carry")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	bank = AudioBank.new()
	_scene("struggle-beat-dry", out_dir, _struggle_script(), true)
	_scene("grip-dry", out_dir, _grip_script(), false)
	_scene("forms-brake-rush-dry", out_dir, _forms_script(), false)
	_scene("arena-turn-dry", out_dir, _arena_script(), false)
	quit(0)


func _cue(kind: String, text: String, actor: int, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "cue"
	e.kind = kind
	e.text = text
	e.actor = float(actor)
	e.target = float(1 - actor)
	for k in extra:
		e.set(k, extra[k])
	return e


func _ev(type: String, actor: int, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = type
	e.actor = float(actor)
	e.target = float(1 - actor)
	for k in extra:
		e.set(k, extra[k])
	return e


## The staged struggle: {events: {tick: [events]}, mid: [[tick, mid]...], last: tick}
func _struggle_script() -> Dictionary:
	var s: Dictionary = {}
	var mids: Array = [[0, 0.5]]
	var add := func(t: int, e) -> void:
		if not s.has(t):
			s[t] = []
		s[t].append(e)
	add.call(30, _cue("beam_struggle", "start", 0, {"n": 700, "x": 0.5}))
	# rows: A's press, D's press (surge, sharp, stray or none), and the point after
	var rows: Array = [["sharp", "surge", 0.55], ["surge", "surge", 0.55], ["", "sharp", 0.40], ["sharp", "surge", 0.45], ["stray", "surge", 0.35], ["sharp", "", 0.50],
		["sharp", "surge", 0.55], ["sharp", "", 0.70], ["sharp", "", 0.85], ["sharp", "", 0.96]]
	var t: int = 70
	var k: int = 1
	for r in rows:
		add.call(t, _cue("beam_pulse", "", 0, {"k": float(k), "n": t}))
		for side in range(2):
			var press: String = String(r[side])
			if press == "" or press == "stray":
				if press == "stray":
					add.call(t + 8, _cue("beam_stray", "", side, {"k": float(k)}))
				continue
			add.call(t + (1 if press == "sharp" else 3), _cue("beam_surge", press, side, {"k": float(k)}))
		mids.append([t + 4, float(r[2])])
		t += 20
		k += 1
	add.call(t, _cue("beam_end", "overwhelmed", 0, {"x": 1.0}))
	return {"events": s, "mid": mids, "last": t + 90}


func _grip_script() -> Dictionary:
	var s: Dictionary = {}
	var add := func(t: int, e) -> void:
		if not s.has(t):
			s[t] = []
		s[t].append(e)
	add.call(30, _cue("grapple_catch", "tell", 0, {"n": 40}))
	add.call(40, _cue("grapple_clinch", "start", 0, {"k": 1.0, "n": 40}))
	var grips: Array = [0, 1, 1, 2, 3, 3, 4, 5]
	var presses: Array = ["step", "step", "void", "sharp", "step", "step", "sharp", "step"]
	var t: int = 70
	for i in range(grips.size()):
		add.call(t, _cue("grapple_pulse", "", 0, {"k": float(i + 1), "n": t, "amount": float(grips[i])}))
		add.call(t + 3, _cue("grapple_pummel", presses[i], 0, {"k": float(grips[i])}))
		if i == 2:
			add.call(t + 10, _cue("grapple_stray", "", 1, {"k": 1.0}))
		t += 20
	add.call(t + 6, _cue("grapple_refused", "lockout", 1, {"n": t + 30}))
	add.call(t + 14, _cue("grapple_refused", "lockout", 1, {"n": t + 30}))
	add.call(t + 50, _cue("grapple_end", "thrown_down", 0))
	return {"events": s, "mid": [], "last": t + 110}


func _forms_script() -> Dictionary:
	var s: Dictionary = {}
	var add := func(t: int, e) -> void:
		if not s.has(t):
			s[t] = []
		s[t].append(e)
	add.call(30, _ev("transform_ready", 0, {"tier": 2.0, "source": "power"}))
	add.call(110, _ev("form_hold", 0, {"n": 1.0, "dur": 1.0, "amount": 12.0}))
	add.call(230, _ev("form_hold", 0, {"n": 1.0, "dur": 4.0, "amount": 45.0}))
	add.call(350, _ev("form_hold", 0, {"n": 2.0, "dur": 7.0, "amount": 85.0}))
	add.call(470, _ev("form_release", 0, {"n": 2.0, "amount": 85.0, "dur": 10.0, "k": 2.0}))
	add.call(540, _ev("air_brake", 1, {"text": "start", "kind": "held", "amount": 5200.0}))
	add.call(570, _ev("air_brake", 1, {"text": "end", "kind": "speed", "amount": 1500.0}))
	add.call(640, _ev("air_brake", 1, {"text": "start", "kind": "held", "amount": 1800.0}))
	add.call(665, _ev("air_brake", 1, {"text": "end", "kind": "released", "amount": 900.0}))
	add.call(740, _ev("rush", 0, {"n": 758}))
	add.call(810, _ev("rush", 1, {"n": 819}))
	add.call(880, _cue("perfect_block", "", 1))
	return {"events": s, "mid": [], "last": 950}


## The ring's turn at the hard cut: a full turn (10 degrees), a small one (2.5), a full one again.
func _arena_script() -> Dictionary:
	var s: Dictionary = {}
	s[40] = [_ev("arena_turn", 0, {"n": 1.0, "x": 4050.0, "amount": 10.0, "k": 10.0})]
	s[200] = [_ev("arena_turn", 0, {"n": 2.0, "x": 4050.0, "amount": 2.5, "k": 12.5})]
	s[360] = [_ev("arena_turn", 0, {"n": 3.0, "x": 4050.0, "amount": -10.0, "k": 12.5})]
	return {"events": s, "mid": [], "last": 470}


func _scene(name: String, out_dir: String, sc: Dictionary, with_clash: bool) -> void:
	S = SimCore.createSim()
	SimCore.newMatch(S, 4)
	S.fighters[0].x = 4000.0
	S.fighters[1].x = 4100.0
	S.fighters[0].y = 0.0
	S.fighters[1].y = 0.0
	cues = AudioCues.new(bank)
	cues.tug.cfg["enabled"] = true
	cues.carry.cfg["enabled"] = true
	cues.reset(4)
	if with_clash:
		var c := SimState.Clash.new()
		c.A = S.fighters[0]
		c.D = S.fighters[1]
		c.mid = 0.5
		S.game.clash = c
	var timeline: Array = []             # [tick, cue]
	var mids: Array = sc.mid
	for t in range(0, int(sc.last) + 1):
		if with_clash:
			var m: float = 0.5
			for p in mids:
				if int(p[0]) <= t:
					m = float(p[1])
			S.game.clash.mid = m
		S.tick = t
		S.T = float(t) / 60.0
		for c in cues.consume(S, sc.events.get(t, [])):
			timeline.append([t, c])
	if with_clash:
		S.game.clash = null
	var total: float = float(sc.last) / 60.0 + 1.2
	var n: int = int(total * RATE)
	var mix := PackedFloat32Array()
	mix.resize(n)
	_mix_timeline(mix, timeline, total)
	AudioDsp.normalize(mix, AudioDsp.db_to_lin(-3.0))
	AudioDsp.fade(mix, 0.003, 0.4, RATE)
	var path: String = "%s/%s.wav" % [out_dir, name]
	var err: int = AudioDsp.to_wav(mix, RATE).save_to_wav(path)
	print("%s: %.1f s, %d cues, error %d" % [path, total, timeline.size(), err])
	SimCore.dispose(S)


func _mix_timeline(mix: PackedFloat32Array, timeline: Array, total: float) -> void:
	var loops: Dictionary = {}           # group -> {start, buf, rate, keys: [[t, gain, pitch]], end}
	for entry in timeline:
		var at: float = float(int(entry[0])) / 60.0
		var c = entry[1]
		if c.sound == "" and c.stop_group != "":
			if loops.has(c.stop_group) and loops[c.stop_group].end < 0.0:
				loops[c.stop_group]["end"] = at
				loops[c.stop_group]["fade"] = float(c.fade_ms) * 0.001
			continue
		if c.loop and c.update:
			if loops.has(c.group) and loops[c.group].end < 0.0:
				var L = loops[c.group]
				var cur: Array = _at(L.keys, at)
				L.keys.append([at, cur[0], cur[1]])
				L.keys.append([at + float(c.ramp_ms) * 0.001, c.gain_db, c.pitch])
			continue
		if c.loop:
			loops[c.group] = {"start": at, "buf": bank.buffer(c.sound, c.variant), "rate": bank.rate_of(c.sound), "keys": [[at, c.gain_db, c.pitch]], "end": -1.0, "fade": 0.04}
			continue
		_mix_one(mix, bank.buffer(c.sound, c.variant), bank.rate_of(c.sound), at, c.pitch, c.gain_db, c.group, timeline)
	for g in loops:
		_mix_loop(mix, loops[g], total)


## The gain and pitch a looped voice has at a time, following its keyframes straight.
func _at(keys: Array, t: float) -> Array:
	if t <= float(keys[0][0]):
		return [keys[0][1], keys[0][2]]
	for i in range(1, keys.size()):
		if t <= float(keys[i][0]):
			var a = keys[i - 1]
			var b = keys[i]
			var u: float = (t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6)
			return [lerpf(float(a[1]), float(b[1]), u), lerpf(float(a[2]), float(b[2]), u)]
	var l = keys[keys.size() - 1]
	return [l[1], l[2]]


func _mix_loop(mix: PackedFloat32Array, L: Dictionary, total: float) -> void:
	var src: PackedFloat32Array = L.buf
	var i0: int = int(float(L.start) * RATE)
	var t_end: float = float(L.end) + float(L.fade) if float(L.end) >= 0.0 else total
	var i1: int = mini(int(t_end * RATE), mix.size())
	var pos: float = 0.0
	for i in range(i0, i1):
		var t: float = float(i) / RATE
		var gp: Array = _at(L.keys, t)
		var g: float = AudioDsp.db_to_lin(float(gp[0]))
		if float(L.end) >= 0.0 and t > float(L.end):
			g *= clampf(1.0 - (t - float(L.end)) / maxf(float(L.fade), 1e-6), 0.0, 1.0)
		pos += float(gp[1]) * float(L.rate) / RATE
		var k: int = int(pos) % src.size()
		var f: float = pos - floorf(pos)
		var a: float = src[k]
		var b: float = src[(k + 1) % src.size()]
		mix[i] += (a + (b - a) * f) * g


## One-shot at a time, pitch and gain. A cue with a group replaces its group's earlier voice, as the voice pool does, by being
## cut at the new one's start: simplified here to letting both ring, which is what a pool with room for both does.
func _mix_one(mix: PackedFloat32Array, src: PackedFloat32Array, rate: int, at: float, pitch: float, gain: float, group: String, timeline: Array) -> void:
	var step: float = pitch * float(rate) / float(RATE)
	var g: float = AudioDsp.db_to_lin(gain)
	var a0: int = int(at * RATE)
	var len: int = int(float(src.size()) / step)
	for j in range(len):
		if a0 + j >= mix.size():
			break
		var p: float = float(j) * step
		var i0: int = int(p)
		var f: float = p - float(i0)
		var a: float = src[i0]
		var b: float = src[i0 + 1] if i0 + 1 < src.size() else 0.0
		mix[a0 + j] += (a + (b - a) * f) * g
