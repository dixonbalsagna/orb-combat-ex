extends SceneTree
## Render a short listening demo of the brawl's sounds, made by the real mapper from STAGED events (the sim's side is not
## built yet): an X flurry that closes on a stagger, the launcher's "B now" ping over a loop of the 180 BPM metal
## reference clip, the B wind-up and the launch, a mashed point-blank bolt, a blast, and a double hit. It shows the
## ducking too: the music drops 4 dB and the impacts 3 dB for a moment under the ping. From the repo root:
##   godot --headless --path . --script res://audio/tools/render_brawl_demo.gd [-- --out=FILE]
## Mono 16-bit at 22.05 kHz. Not a game recording: a way to hear the mapping and the mix before the events exist.

const RATE := 22050


func _init() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://audio/preview/brawl-demo.wav")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
	var bank := AudioBank.new()
	var cues := AudioCues.new(bank)
	cues.reset(4)
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 4)
	S.fighters[0].x = 4000.0
	S.fighters[1].x = 4060.0
	var script: Dictionary = _script()
	var voices: Array = []                       # {group, start, buf, rate, pitch, gain, bus, end_at}
	var ducks: Array = []                        # {bus, from, to, db}
	var last_tick: int = 0
	for t in script.keys():
		last_tick = maxi(last_tick, int(t))
	for t in range(0, last_tick + 1):
		if not script.has(t):
			continue
		S.tick = t
		S.T = float(t) / 60.0
		for e in script[t]:
			if e.type == "cue" and e.kind == "blow" and int(e.n) == -1:
				e.n = t
		for c in cues.consume(S, script[t]):
			var at: float = float(t) / 60.0
			if c.sound == "" and c.stop_group != "":
				for v in voices:
					if v.group == c.stop_group and v.end_at < 0.0:
						v.end_at = at + float(c.fade_ms) * 0.001
				continue
			if c.kind == "voice":
				continue
			var buf: PackedFloat32Array = bank.buffer(c.sound, c.variant)
			voices.append({"group": c.group, "start": at, "buf": buf, "rate": bank.rate_of(c.sound), "pitch": c.pitch, "gain": c.gain_db, "bus": c.bus, "end_at": -1.0})
			for d in c.duck:
				ducks.append({"bus": String(d.bus), "from": at, "to": at + float(d.ms) * 0.001 + 0.08, "db": float(d.db)})
	var total: float = float(last_tick) / 60.0 + 1.6
	var n: int = int(total * RATE)
	var sfx := PackedFloat32Array()
	sfx.resize(n)
	var alert := PackedFloat32Array()
	alert.resize(n)
	for v in voices:
		_mix_voice(sfx if v.bus != "Alert" else alert, v)
	# the music: the metal reference, looped, on the Music bus at -8 dB, with the duck
	var music := PackedFloat32Array()
	music.resize(n)
	var ref: AudioStreamWAV = load("res://audio/preview/suno-reference/suno-ref-riff-180bpm-E.wav")
	var mus: PackedFloat32Array = _wav_samples("res://audio/preview/suno-reference/suno-ref-riff-180bpm-E.wav")
	var mg: float = AudioDsp.db_to_lin(-8.0 - 1.3)
	for i in range(n):
		music[i] = mus[i % mus.size()] * mg if mus.size() > 0 else 0.0
	for d in ducks:
		var target: PackedFloat32Array = music if d.bus == "Music" else (sfx if d.bus == "Sfx" else PackedFloat32Array())
		if target.is_empty():
			continue
		for i in range(maxi(int(d.from * RATE), 0), mini(int(d.to * RATE), n)):
			var left: float = d.to - float(i) / RATE
			var k: float = clampf(left / 0.08, 0.0, 1.0)
			target[i] *= AudioDsp.db_to_lin(d.db * k)
	var mix := PackedFloat32Array()
	mix.resize(n)
	for i in range(n):
		mix[i] = sfx[i] + alert[i] + music[i]
	AudioDsp.normalize(mix, AudioDsp.db_to_lin(-3.0))
	AudioDsp.fade(mix, 0.003, 0.3, RATE)
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var err: int = AudioDsp.to_wav(mix, RATE).save_to_wav(out_path)
	print("%s: %.1f s, %d cues, %d ducks, error %d" % [out_path, total, voices.size(), ducks.size(), err])
	SimCore.dispose(S)
	quit(0 if err == OK else 1)


func _mix_voice(dst: PackedFloat32Array, v: Dictionary) -> void:
	var src: PackedFloat32Array = v.buf
	var step: float = float(v.pitch) * float(v.rate) / float(RATE)
	var g: float = AudioDsp.db_to_lin(float(v.gain))
	var at: int = int(float(v.start) * RATE)
	var len: int = int(float(src.size()) / step)
	var cut: int = int((float(v.end_at) - float(v.start)) * RATE) if float(v.end_at) >= 0.0 else -1
	for j in range(len):
		if at + j >= dst.size():
			break
		var env: float = 1.0
		if cut >= 0:
			if j >= cut:
				break
			var fade: int = int(0.04 * RATE)
			if j > cut - fade:
				env = float(cut - j) / float(fade)
		var p: float = float(j) * step
		var i0: int = int(p)
		var f: float = p - float(i0)
		var a: float = src[i0]
		var b: float = src[i0 + 1] if i0 + 1 < src.size() else 0.0
		dst[at + j] += (a + (b - a) * f) * g * env


func _wav_samples(path: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var bytes: PackedByteArray = f.get_buffer(f.get_length())
	var pos: int = 12
	while pos + 8 <= bytes.size():
		var id: String = bytes.slice(pos, pos + 4).get_string_from_ascii()
		var size: int = bytes.decode_u32(pos + 4)
		if id == "data":
			out.resize(size / 2)
			for i in range(size / 2):
				out[i] = float(bytes.decode_s16(pos + 8 + i * 2)) / 32768.0
			return out
		pos += 8 + size + (size & 1)
	return out


func _blow(t: int, who: int, text: String) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "cue"
	e.kind = "blow"
	e.text = text
	e.actor = float(who)
	e.target = float(1 - who)
	e.n = -1
	return e


func _cue(kind: String, text: String, who: int, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "cue"
	e.kind = kind
	e.text = text
	e.actor = float(who)
	e.target = float(1 - who)
	for k in extra:
		e.set(k, extra[k])
	return e


func _tick() -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "tick"
	e.dt = 1.0 / 60.0
	e.frozen = false
	return e


func _dmg(who: int, kind: String, amount: float) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "damage"
	e.attacker = float(who)
	e.victim = float(1 - who)
	e.kind = kind
	e.amount = amount
	e.region = "core"
	e.x = 4030.0
	e.y = 90.0
	return e


## The staged sequence, by tick (60 a second).
func _script() -> Dictionary:
	var s: Dictionary = {}
	var add := func(t: int, e) -> void:
		if not s.has(t):
			s[t] = []
		s[t].append(e)
	# 1. an X flurry of eight lights, six ticks apart, closing on a flurry stagger; the launcher opens for 14 ticks
	for i in range(8):
		var t: int = 30 + 6 * i
		add.call(t, _blow(t, 0, "light"))
		add.call(t, _dmg(0, "light", 12.0))
		if i == 7:
			add.call(t, _cue("stagger", "flurry", 1, {"target": 0.0, "n": 14.0}))
			add.call(t, _cue("launcher_open", "flurry", 0, {"n": t + 14}))
	# 2. B pressed: the wind-up (14 ticks), the launcher is thrown, the launch lands heavy
	add.call(80, _cue("windup", "start", 0, {"n": 94}))
	add.call(80, _cue("launcher_close", "thrown", 0))
	add.call(94, _blow(94, 0, "heavy"))
	add.call(94, _dmg(0, "heavy", 90.0))
	add.call(94, _cue("windup", "end", 0, {"k": 1.0}))
	# 3. a mix: a medium (Y), a guarded light, a whiff
	add.call(150, _cue("windup", "start", 1, {"n": 162}))
	add.call(162, _blow(162, 1, "medium"))
	add.call(162, _dmg(1, "light", 35.0))
	add.call(190, _blow(190, 0, "light"))
	add.call(190, _dmg(0, "guard", 10.0))
	add.call(210, _cue("miss", "reach", 1))
	# 4. a mashed point-blank bolt, ten in two thirds of a second
	for i in range(10):
		add.call(250 + 4 * i, _cue("energy_land", "bolt", 0, {"source": "hit"}))
	# 5. a blast: 12 ticks of gather, then the whump
	add.call(310, _cue("energy_reach", "blast", 0, {"amount": 12.0, "n": 322}))
	add.call(322, _cue("energy_land", "blast", 0, {"source": "hit"}))
	# 6. a double hit
	add.call(400, _cue("double_hit", "both", 0, {"n": 408, "amount": 8.0, "k": 3.0}))
	add.call(408, _dmg(0, "heavy", 60.0))
	add.call(408, _dmg(1, "heavy", 60.0))
	# 7. B held: the charge hum from the 32nd tick, a light that the armour absorbs, the full tick at 44, thrown at 50
	var c0: int = 470
	add.call(c0, _cue("windup", "start", 1, {"n": c0 + 28}))
	for i in range(1, 51):
		add.call(c0 + i, _tick())
	add.call(c0 + 36, _blow(c0 + 36, 0, "light"))
	add.call(c0 + 36, _dmg(0, "light", 12.0))
	add.call(c0 + 44, _cue("charge_full", "b", 1))
	add.call(c0 + 50, _cue("windup", "end", 1, {"k": 1.0}))
	return s
