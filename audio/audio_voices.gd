class_name AudioVoices
extends Node
## Plays cues (audio_cues.gd): a pool of AudioStreamPlayer2D voices on the buses in data/mix.json. It is the only part
## of the audio code that needs the scene tree and a sound device.
##
## Space. The sim's x wraps around the planet, so a sound's distance is the shortest arc from the camera (SimWrap.sdx),
## as in rendering: a fight across the seam is as loud as it really is. The player is given the camera-relative offset
## times the zoom, with an AudioListener2D at the origin, so Godot's own 2D panning follows what is on screen. Level
## by distance comes from mix.json, not from Godot's attenuation (which would measure screen pixels).
##
## Voice cap. mix.json "voices" players; when all are busy a new cue takes the quietest, lowest-priority voice if its
## own priority is at least as high, and is dropped otherwise. A cue with a group replaces the earlier voice in that
## group (each fighter has one mouth).

var bank: AudioBank
var mix: Dictionary = {}
var played: int = 0
var dropped: int = 0
var _pool: Array = []          # AudioStreamPlayer2D
var _meta: Array = []          # per player: {priority, group, t}
var _tweens: Array = []        # per player: the tween moving a looped voice, or null
var _listener: AudioListener2D
var _clock: float = 0.0
var _duck: Dictionary = {}     # bus name -> {db, until}: a bus held down for a moment by a cue
var _base_db: Dictionary = {}  # bus name -> its level in mix.json
const DUCK_RELEASE := 0.08     # seconds to come back up


func _init(p_bank: AudioBank = null) -> void:
	bank = p_bank if p_bank != null else AudioBank.new()
	mix = AudioBank.load_json("res://audio/data/mix.json")


func _ready() -> void:
	setup_buses(mix)
	bank.async_ok = true             # the warm-up may use this node's frames (AudioBank.warm)
	_listener = AudioListener2D.new()
	add_child(_listener)
	_listener.make_current()
	for i in range(int(mix.voices)):
		var p := AudioStreamPlayer2D.new()
		p.max_distance = 1.0e7      # distance is handled in play(); never let Godot cut a voice off
		p.attenuation = 0.0
		add_child(p)
		_pool.append(p)
		_meta.append({"priority": -1, "group": "", "t": -1.0, "cls": ""})
		_tweens.append(null)


func _process(delta: float) -> void:
	_clock += delta
	for bus in _duck.keys():
		var d: Dictionary = _duck[bus]
		var idx: int = AudioServer.get_bus_index(bus)
		var left: float = float(d.until) - _clock
		if left <= 0.0:
			if idx != -1:
				AudioServer.set_bus_volume_db(idx, float(_base_db.get(bus, 0.0)))
			_duck.erase(bus)
		elif idx != -1:
			var k: float = clampf(left / DUCK_RELEASE, 0.0, 1.0)     # 1 while held, then a short ramp back up
			AudioServer.set_bus_volume_db(idx, float(_base_db.get(bus, 0.0)) + float(d.db) * k)


## How far a bus is held down right now, in dB (0 when it is not).
func duck_db(bus: String) -> float:
	if not _duck.has(bus):
		return 0.0
	var left: float = float(_duck[bus].until) - _clock
	return float(_duck[bus].db) * clampf(left / DUCK_RELEASE, 0.0, 1.0)


func _hold_down(bus: String, db: float, ms: int) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	if not _base_db.has(bus):
		_base_db[bus] = AudioServer.get_bus_volume_db(idx)
	var until: float = _clock + float(ms) * 0.001 + DUCK_RELEASE
	if _duck.has(bus):
		until = maxf(until, float(_duck[bus].until))
		db = minf(db, float(_duck[bus].db))
	_duck[bus] = {"db": db, "until": until}
	AudioServer.set_bus_volume_db(idx, float(_base_db[bus]) + db)


## Create the buses and the master limiter named in mix.json (once; safe to call again).
static func setup_buses(m: Dictionary) -> void:
	for b in m.buses:
		var idx: int = AudioServer.get_bus_index(b.name)
		if idx == -1:
			AudioServer.add_bus()
			idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, b.name)
			AudioServer.set_bus_send(idx, "Master")
			if b.has("lowpass_hz"):
				var lp := AudioEffectLowPassFilter.new()
				lp.cutoff_hz = float(b.lowpass_hz)
				AudioServer.add_bus_effect(idx, lp)
		AudioServer.set_bus_volume_db(idx, float(b.volume_db))
	if AudioServer.get_bus_effect_count(0) == 0 and m.has("master_limiter"):
		var lim := AudioEffectLimiter.new()
		lim.threshold_db = float(m.master_limiter.threshold_db)
		lim.ceiling_db = float(m.master_limiter.ceiling_db)
		AudioServer.add_bus_effect(0, lim)


## Level in dB for a sound this far (world units) from the camera; below the floor means inaudible.
func distance_db(dist: float) -> float:
	var s: Dictionary = mix.space
	var f: float = clampf(dist / float(s.max_distance), 0.0, 1.0)
	return float(s.min_gain_db) * pow(f, float(s.rolloff))


## Play a cue for a camera at cam_x with zoom pixels per world unit. Returns true if a voice took it.
func play(cue: AudioCues.Cue, cam_x: float, zoom: float = 1.0) -> bool:
	if cue.sound == "" and cue.stop_group != "":
		return stop_group(cue.stop_group, cue.fade_ms)
	var dx: float = 0.0 if cue.ambient else SimWrap.sdx(cam_x, cue.x)
	if cue.update:
		return update_group(cue.group, cue.gain_db + distance_db(absf(dx)), cue.pitch, cue.ramp_ms, dx * zoom)
	var dist: float = absf(dx)
	if dist >= float(mix.space.max_distance):
		dropped += 1
		return false
	if bank.warming and not bank.is_ready(cue.sound, cue.variant):
		bank.skipped += 1      # not rendered yet: dropped, silently, while the warm-up runs (the most wanted sounds are first)
		return false
	var slot: int = _take(cue)
	if slot < 0:
		dropped += 1
		return false
	var p: AudioStreamPlayer2D = _pool[slot]
	p.stop()
	_kill_tween(slot)
	p.stream = _looped(bank.stream(cue.sound, cue.variant)) if cue.loop else bank.stream(cue.sound, cue.variant)
	p.volume_db = cue.gain_db + distance_db(dist)
	p.pitch_scale = cue.pitch
	p.bus = cue.bus
	if cue.muffled:
		p.bus = "SfxMuffled" if cue.bus == "Sfx" else ("VoiceMuffled" if cue.bus == "Voice" else cue.bus)
	p.position = Vector2(dx * zoom, 0.0)
	p.play()
	_meta[slot] = {"priority": cue.priority, "group": cue.group, "t": _clock, "cls": cue.cls}
	for d in cue.duck:
		_hold_down(String(d.bus), float(d.db), int(d.ms))
	played += 1
	return true


## A copy of a stream that loops from its first sample to its last (the bank keeps the one-shot).
func _looped(src: AudioStreamWAV) -> AudioStreamWAV:
	var w: AudioStreamWAV = src.duplicate()
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = w.data.size() / 2          # 16-bit mono
	return w


func _kill_tween(slot: int) -> void:
	if _tweens[slot] != null:
		_tweens[slot].kill()
		_tweens[slot] = null


## Move the voices playing in a group to a new level, pitch and place over ramp_ms (the beam struggle's bed follows the
## meeting point). gain is the final level (distance included); x_offset the camera-relative place. True if one was playing.
func update_group(group: String, volume_db: float, pitch: float, ramp_ms: int, x_offset: float) -> bool:
	var found: bool = false
	for i in range(_pool.size()):
		if _pool[i].playing and _meta[i].group == group:
			found = true
			var p: AudioStreamPlayer2D = _pool[i]
			_kill_tween(i)
			if ramp_ms <= 0:
				p.volume_db = volume_db
				p.pitch_scale = pitch
				p.position = Vector2(x_offset, 0.0)
			else:
				var tw: Tween = create_tween()
				tw.set_parallel(true)
				var t: float = float(ramp_ms) * 0.001
				tw.tween_property(p, "volume_db", volume_db, t)
				tw.tween_property(p, "pitch_scale", pitch, t)
				tw.tween_property(p, "position", Vector2(x_offset, 0.0), t)
				_tweens[i] = tw
	return found


## Which pool slot a cue may use: its own group's voice, then a free one, then the weakest voice it outranks.
func _take(cue: AudioCues.Cue) -> int:
	if cue.group != "":
		for i in range(_pool.size()):
			if _meta[i].group == cue.group and _pool[i].playing:
				return i
	if cue.cap > 0 and cue.cls != "":
		var oldest: int = -1
		var count: int = 0
		for i in range(_pool.size()):
			if _pool[i].playing and _meta[i].cls == cue.cls:
				count += 1
				if oldest == -1 or _meta[i].t < _meta[oldest].t:
					oldest = i
		if count >= cue.cap:
			return oldest if cue.priority >= int(_meta[oldest].priority) else -1
	var weakest: int = -1
	for i in range(_pool.size()):
		if not _pool[i].playing:
			return i
		if weakest == -1 or _meta[i].priority < _meta[weakest].priority or (_meta[i].priority == _meta[weakest].priority and _meta[i].t < _meta[weakest].t):
			weakest = i
	if weakest != -1 and cue.priority >= int(_meta[weakest].priority):
		return weakest
	return -1


## Fade out whatever is playing in a group (the launcher's ping, once the launch is thrown). True if there was one.
func stop_group(group: String, fade_ms: int = 40) -> bool:
	var found: bool = false
	for i in range(_pool.size()):
		if _pool[i].playing and _meta[i].group == group:
			found = true
			var p: AudioStreamPlayer2D = _pool[i]
			if fade_ms <= 0:
				p.stop()
			else:
				var tw: Tween = create_tween()
				tw.tween_property(p, "volume_db", -60.0, float(fade_ms) * 0.001)
				tw.tween_callback(p.stop)
	return found


func active() -> int:
	var n: int = 0
	for p in _pool:
		if p.playing:
			n += 1
	return n
