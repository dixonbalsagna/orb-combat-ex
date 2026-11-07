extends SceneTree
## Render dry listening clips (no music underneath) of the co-op and controller sounds, made by the real mappers (AudioCoop, and
## AudioTug for the clash) from STAGED events. From the repo root:
##   godot --headless --path . --script res://audio/tools/render_coop_demo.gd [-- --out=DIR]
## Writes DIR/brink-call-dry.wav, refusal-knock-dry.wav, charge-stages-dry.wav and clash-push-dry.wav (default audio/preview/coop). Mono
## 16-bit at 22.05 kHz. A looped voice (the struggle's bed) is left out. A muffled cue (the partner's far cry) is run through a
## 1.4 kHz low-pass, as the VoiceMuffled bus does; place and distance are not heard in a mono file. Not a game recording.

const RATE := 22050
var bank: AudioBank
var S: SimState
var cues: AudioCues


func _init() -> void:
	var out_dir: String = ProjectSettings.globalize_path("res://audio/preview/coop")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	bank = AudioBank.new()
	_scene("brink-call-dry", out_dir, _brink_script(), false)
	_scene("refusal-knock-dry", out_dir, _refuse_script(), false)
	_scene("charge-stages-dry", out_dir, _stage_script(), false)
	_scene("clash-push-dry", out_dir, _clash_script(), true)
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


func _add(s: Dictionary, t: int, e) -> void:
	if not s.has(t):
		s[t] = []
	s[t].append(e)


## {own: {tick: [events]}, other: {tick: [events of the other fight]}, last: tick}
func _brink_script() -> Dictionary:
	var own: Dictionary = {}
	var other: Dictionary = {}
	_add(own, 30, _cue("brink_call", "p1", 0))                       # a fighter on screen reaches his brink
	_add(other, 230, _cue("brink_call", "p4", 1))                    # the partner's fight, on the other side of the planet
	_add(own, 430, _cue("brink_call", "p1", 0))
	_add(other, 430, _cue("brink_call", "p4", 1))                    # both at once
	return {"own": own, "other": other, "last": 560}


func _refuse_script() -> Dictionary:
	var own: Dictionary = {}
	_add(own, 30, _cue("stick_refused", "right", 0, {"source": "ki"}))
	_add(own, 100, _cue("stick_refused", "right", 0, {"source": "late"}))
	for i in range(5):
		_add(own, 170 + i * 3, _cue("stick_refused", "left", 0, {"source": "ki"}))      # a mash: one knock
	_add(own, 250, _cue("stick_refused", "left", 0, {"source": "replaced"}))           # quieter
	_add(own, 320, _cue("press_refused", "", 0, {"source": "block_lockout"}))
	return {"own": own, "other": {}, "last": 400}


func _stage_script() -> Dictionary:
	var own: Dictionary = {}
	var t: int = 30
	for k in range(1, 7):
		t += [12, 16, 18, 20, 24, 30][k - 1]
		_add(own, t, _cue("stick_stage", str(k), 0, {"k": float(k), "n": 6.0}))
	t += 90
	_add(own, t, _cue("stick_stage", "5", 0, {"k": 5.0, "n": 6.0}))                      # steps down: it cannot pay
	t += 140
	_add(own, t, _cue("stick_stage", "1", 0, {"k": 1.0, "n": 4.0}))                      # a new, shorter charge
	t += 16
	_add(own, t, _cue("stick_stage", "2", 0, {"k": 2.0, "n": 4.0}))
	t += 18
	_add(own, t, _cue("stick_stage", "2", 0, {"k": 2.0, "n": 4.0, "source": "capped"}))  # the energy stops it
	return {"own": own, "other": {}, "last": t + 80}


func _clash_script() -> Dictionary:
	var own: Dictionary = {}
	_add(own, 20, _cue("beam_struggle", "start", 0, {"n": 700, "x": 0.5}))
	for i in range(1, 5):
		_add(own, 20 + i * 20, _cue("beam_pulse", "", 0, {"k": float(i)}))
	_add(own, 20 + 20 + 1, _cue("beam_surge", "", 0))              # a good push on the beat
	_add(own, 20 + 60 + 1, _cue("beam_surge", "sharp", 1))         # a sharp one
	_add(own, 20 + 40 + 9, _cue("beam_stray", "", 1))              # a stray, off the beat
	_add(own, 20 + 80 + 9, _cue("beam_stray", "void", 0))
	_add(own, 20 + 100, _cue("beam_end", "time", 0))
	return {"own": own, "other": {}, "last": 190}


func _scene(name: String, out_dir: String, sc: Dictionary, with_clash: bool) -> void:
	S = SimCore.createSim()
	SimCore.newMatch(S, 4, {}, {"fights": 2})
	S.fighters[0].x = 4000.0
	S.fighters[1].x = 4100.0
	S.fighters[0].y = 0.0
	S.fighters[1].y = 0.0
	cues = AudioCues.new(bank)
	cues.coop.cfg["enabled"] = true
	cues.tug.cfg["enabled"] = with_clash
	cues.reset(4)
	if with_clash:
		var c := SimState.Clash.new()
		c.A = S.fighters[0]
		c.D = S.fighters[1]
		c.mid = 0.5
		S.game.clash = c
	var timeline: Array = []
	for t in range(0, int(sc.last) + 1):
		S.tick = t
		S.T = float(t) / 60.0
		for c in cues.consume(S, sc.own.get(t, [])):
			timeline.append([t, c])
		if sc.other.has(t):
			for c in cues.consume_others(S, [sc.other[t]]):
				timeline.append([t, c])
	if with_clash:
		S.game.clash = null
	var total: float = float(sc.last) / 60.0 + 1.2
	var mix := PackedFloat32Array()
	mix.resize(int(total * RATE))
	for entry in timeline:
		var c = entry[1]
		if c.sound == "" or c.loop or c.update:
			continue
		_mix_one(mix, bank.buffer(c.sound, c.variant), bank.rate_of(c.sound), float(int(entry[0])) / 60.0, c.pitch, c.gain_db, c.muffled)
	AudioDsp.normalize(mix, AudioDsp.db_to_lin(-3.0))
	AudioDsp.fade(mix, 0.003, 0.4, RATE)
	var path: String = "%s/%s.wav" % [out_dir, name]
	var err: int = AudioDsp.to_wav(mix, RATE).save_to_wav(path)
	print("%s: %.1f s, %d cues, error %d" % [path, total, timeline.size(), err])
	SimCore.dispose(S)


func _mix_one(mix: PackedFloat32Array, src: PackedFloat32Array, rate: int, at: float, pitch: float, gain: float, muffled: bool) -> void:
	var step: float = pitch * float(rate) / float(RATE)
	var g: float = AudioDsp.db_to_lin(gain)
	var a0: int = int(at * RATE)
	var len: int = int(float(src.size()) / step)
	var lp: float = 1.0 - exp(-TAU * 1400.0 / float(RATE))
	var y: float = 0.0
	for j in range(len):
		if a0 + j >= mix.size():
			break
		var p: float = float(j) * step
		var i0: int = int(p)
		var f: float = p - float(i0)
		var a: float = src[i0]
		var b: float = src[i0 + 1] if i0 + 1 < src.size() else 0.0
		var v: float = a + (b - a) * f
		if muffled:
			y += lp * (v - y)
			v = y
		mix[a0 + j] += v * g
