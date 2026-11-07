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
var web: AudioWeb = null       # the browser-direct one-shots (audio_web.gd): on the web only, null everywhere else and with ?webvoices=0
var _web_db: Dictionary = {}   # bus name -> the last level (dB) sent to the page
var _lowpass: Dictionary = {}  # bus name -> its low-pass (Hz) from mix.json, for the page's muffled voices
const WEB_TRIM_DB := -3.0      # measured: with no trim the page's one-shots sit 5.5 to 6 dB above the same cues through Godot's mixer (docs/audio/crackle.md), +3 dB were wrong; -3 puts them within 1 dB
static var _inst: AudioVoices = null
var _pool: Array = []          # AudioStreamPlayer2D
var _meta: Array = []          # per player: {priority, group, t}
var _tweens: Array = []        # per player: the tween moving a looped voice, or null
var _listener: AudioListener2D
var _clock: float = 0.0
var _duck: Dictionary = {}     # bus name -> {db, until}: a bus held down for a moment by a cue
var _base_db: Dictionary = {}  # bus name -> its level in mix.json
const DUCK_RELEASE := 0.08     # seconds to come back up
var _deferred: Array = []      # {cue, cam_x, zoom, at}: cues whose sound the warm-up has not rendered yet; they play when it has, if not too late
const DEFER_MAX := 24
const DEFER_TIMEOUT_MS := 6000


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
	for b in mix.buses:
		if b.has("lowpass_hz"):
			_lowpass[String(b.name)] = float(b.lowpass_hz)
	_inst = self
	var w := AudioWeb.new()
	if w.install():
		web = w
		_sync_web(true)
		web.set_mono(mono)


func _process(delta: float) -> void:
	_clock += delta
	if web != null:
		_sync_web(false)
	_run_deferred()
	for bus in _duck.keys():
		var d: Dictionary = _duck[bus]
		var idx: int = AudioServer.get_bus_index(bus)
		var left: float = float(d.until) - _clock
		if left <= 0.0:
			if idx != -1:
				AudioServer.set_bus_volume_db(idx, float(_base_db.get(bus, 0.0)) + user_db(bus))
			_duck.erase(bus)
		elif idx != -1:
			var k: float = clampf(left / DUCK_RELEASE, 0.0, 1.0)     # 1 while held, then a short ramp back up
			AudioServer.set_bus_volume_db(idx, float(_base_db.get(bus, 0.0)) + user_db(bus) + float(d.db) * k)


## Whether a pool slot is sounding: its Godot player is playing, or the page is playing its one-shot (until the time it was started for).
func _busy(i: int) -> bool:
	return _pool[i].playing or float(_meta[i].get("until", 0.0)) > _clock


## Send the buses' levels to the page's graph: what AudioServer holds (mix.json's level, the player's trim, any duck) in dB for each
## bus, and the Master's, when it has moved by more than 0.05 dB (or at once with force).
func _sync_web(force: bool) -> void:
	for b in mix.buses:
		var name: String = String(b.name)
		var idx: int = AudioServer.get_bus_index(name)
		if idx == -1:
			continue
		var db: float = AudioServer.get_bus_volume_db(idx)
		if force or absf(db - float(_web_db.get(name, 1000.0))) > 0.05:
			_web_db[name] = db
			web.set_bus(name, db_to_linear(db))
	var m: float = AudioServer.get_bus_volume_db(0)
	if force or absf(m - float(_web_db.get("Master", 1000.0))) > 0.05:
		_web_db["Master"] = m
		web.set_master(db_to_linear(m))


## A cue the page may play itself: a one-shot that nothing moves after it starts (not a loop, not updated) and the page's context runs.
func _web_ok(cue: AudioCues.Cue) -> bool:
	return web != null and not cue.loop and not cue.ambient and web.running()


## A cue for a sound the warm-up has not rendered: move that sound to the front of the queue, and hold the cue. It plays when the sound
## is ready if it would not be later than its own length; otherwise it is lost (and named in bank.skipped_log).
func _defer(cue: AudioCues.Cue, cam_x: float, zoom: float) -> void:
	bank.warm_want(cue.sound, cue.variant)
	if _deferred.size() >= DEFER_MAX:
		var o: Dictionary = _deferred.pop_front()
		bank.note_skip(o.cue.sound, o.cue.variant, "overflow", float(Time.get_ticks_msec() - int(o.at)))
	_deferred.append({"cue": cue, "cam_x": cam_x, "zoom": zoom, "at": Time.get_ticks_msec()})
	bank.deferred_n = _deferred.size()


func _run_deferred() -> void:
	if _deferred.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	var keep: Array = []
	for d in _deferred:
		var c: AudioCues.Cue = d.cue
		var late: float = float(now - int(d.at))
		var pv: int = bank.pick_ready(c.sound, c.variant)
		if pv >= 0:
			var own_ms: float = bank.stream(c.sound, pv).get_length() * 1000.0 / maxf(c.pitch, 0.1)
			if late > own_ms:
				bank.note_skip(c.sound, c.variant, "late", late)
			else:
				bank.deferred_played += 1
				play(c, d.cam_x, d.zoom)
		elif late > DEFER_TIMEOUT_MS:
			bank.note_skip(c.sound, c.variant, "timeout", late)
		else:
			keep.append(d)
	_deferred = keep
	bank.deferred_n = _deferred.size()


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
		_base_db[bus] = float(_mix_db.get(bus, AudioServer.get_bus_volume_db(idx) - user_db(bus)))
	var until: float = _clock + float(ms) * 0.001 + DUCK_RELEASE
	if _duck.has(bus):
		until = maxf(until, float(_duck[bus].until))
		db = minf(db, float(_duck[bus].db))
	_duck[bus] = {"db": db, "until": until}
	AudioServer.set_bus_volume_db(idx, float(_base_db[bus]) + user_db(bus) + db)


## The player's volume (UI's Settings screen): a trim in dB per group of buses, on top of mix.json's levels and any
## ducking, so a duck's release comes back to the player's level. "master" is Godot's Master bus. Set before the buses
## exist (saved settings load first), it applies when setup_buses makes them. Music has no group yet.
const USER_GROUPS := {"master": ["Master"], "effects": ["Sfx", "SfxMuffled", "Alert", "Ambience"], "voice": ["Voice", "VoiceMuffled"]}
const MUTE_DB := -80.0
static var _user_db: Dictionary = {}     # group -> dB (0 = mix.json's level)
static var _mix_db: Dictionary = {}      # bus name -> its mix.json level, so a trim never compounds
static var mono: bool = false            # every bus summed to mono on the Master bus


## The trim for one bus, in dB (0 when the player has not changed it).
static func user_db(bus: String) -> float:
	for g in USER_GROUPS:
		if (USER_GROUPS[g] as Array).has(bus):
			return float(_user_db.get(g, 0.0))
	return 0.0


## Set a group's volume from a linear level (0 silent, 1 mix.json's level) and apply it to the buses that exist now.
static func set_user_volume(group: String, linear: float) -> void:
	if not USER_GROUPS.has(group):
		return
	var v: float = clampf(linear, 0.0, 1.0)
	var was: float = float(_user_db.get(group, 0.0))
	_user_db[group] = MUTE_DB if v <= 0.0 else maxf(linear_to_db(v), MUTE_DB)
	for bus in USER_GROUPS[group]:
		var idx: int = AudioServer.get_bus_index(bus)
		if idx == -1:
			continue
		if not _mix_db.has(bus):
			_mix_db[bus] = 0.0 if bus == "Master" else AudioServer.get_bus_volume_db(idx) - was
		AudioServer.set_bus_volume_db(idx, float(_mix_db[bus]) + float(_user_db[group]))


## Mono sound: a stereo enhancer with no pull-out on the Master bus sums left and right (added on first use, then switched).
static func set_mono(on: bool) -> void:
	mono = on
	if _inst != null and _inst.web != null:
		_inst.web.set_mono(on)      # the page's one-shots too
	var e: int = _effect_index(0, "AudioEffectStereoEnhance")
	if e == -1:
		if not on:
			return
		var se := AudioEffectStereoEnhance.new()
		se.pan_pullout = 0.0
		AudioServer.add_bus_effect(0, se)
		e = AudioServer.get_bus_effect_count(0) - 1
	AudioServer.set_bus_effect_enabled(0, e, on)


static func _effect_index(bus: int, cls: String) -> int:
	for i in range(AudioServer.get_bus_effect_count(bus)):
		if AudioServer.get_bus_effect(bus, i).get_class() == cls:
			return i
	return -1


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
		_mix_db[String(b.name)] = float(b.volume_db)
		AudioServer.set_bus_volume_db(idx, float(b.volume_db) + user_db(String(b.name)))
	AudioServer.set_bus_volume_db(0, user_db("Master"))
	if _effect_index(0, "AudioEffectLimiter") == -1 and m.has("master_limiter"):
		var lim := AudioEffectLimiter.new()
		lim.threshold_db = float(m.master_limiter.threshold_db)
		lim.ceiling_db = float(m.master_limiter.ceiling_db)
		AudioServer.add_bus_effect(0, lim)


## One line of what the audio is doing, for the page's audio log (?audiolog=1). Read-only: it changes nothing and is safe to call
## every second. Godot's side: cues played and dropped, voices sounding, cues lost or waiting for the warm-up, the output's rate and
## latency, the Master bus's peak (the mixer's real output level in Stream mode; -200 means nothing is being mixed), the player's three
## trims and the bus levels. On the web also the browser's side, from the page shell's hook: the AudioContext's state, its clock (frozen means suspended), rate and
## output latency. Reading it: a Master peak well above -60 dB while nothing is heard means the page works and the browser, the OS or
## the device does not; -200 with `played` rising means a trim or a mute; -200 with `played` flat means no cues arrive.
func status_line() -> String:
	var live: int = active()
	var peak: float = AudioServer.get_bus_peak_volume_left_db(0, 0)
	var s: String = "audio: played %d dropped %d live %d | lost %d waiting %d warming %s | %d Hz %.0f ms out %s | master peak %.0f dB | trim m %.0f e %.0f v %.0f dB" % [
		played, dropped, live, bank.skipped, bank.deferred_n, str(bank.warming), int(AudioServer.get_mix_rate()), AudioServer.get_output_latency() * 1000.0,
		AudioServer.get_output_device(), peak, float(_user_db.get("master", 0.0)), float(_user_db.get("effects", 0.0)), float(_user_db.get("voice", 0.0))]
	var levels: PackedStringArray = PackedStringArray()
	for i in range(AudioServer.bus_count):
		levels.append("%s %.0f%s" % [AudioServer.get_bus_name(i), AudioServer.get_bus_volume_db(i), " MUTED" if AudioServer.is_bus_mute(i) else ""])
	s += " | buses " + ", ".join(levels)
	if OS.has_feature("web"):
		# The engine's own context is not a global of the page; the page shell keeps a reference to every AudioContext it is made
		# (docs/audio/pending/audio-resume/shell-snippet.js) and answers for them: the state, the clock, the rate and the output latency.
		if web != null:
			s += " | web: " + web.status()
		s += " | ctx " + str(JavaScriptBridge.eval("(function(){try{return window.__audioShell&&window.__audioShell.state?window.__audioShell.state():'no shell hook'}catch(e){return 'error ('+e+')'}})()"))
	return s


## Level in dB for a sound this far (world units) from the camera; below the floor means inaudible.
func distance_db(dist: float) -> float:
	var s: Dictionary = mix.space
	var f: float = clampf(dist / float(s.max_distance), 0.0, 1.0)
	return float(s.min_gain_db) * pow(f, float(s.rolloff))


## Play a cue for a camera at cam_x with zoom pixels per world unit. Returns true if a voice took it.
func play(cue: AudioCues.Cue, cam_x: float, zoom: float = 1.0) -> bool:
	bank.last_ask_ms = Time.get_ticks_msec()      # the cue traffic: the warm-up's budget reads it when the host has not said
	if cue.sound == "" and cue.stop_group != "":
		return stop_group(cue.stop_group, cue.fade_ms)
	var dx: float = 0.0 if cue.ambient else SimWrap.sdx(cam_x, cue.x)
	if cue.update:
		return update_group(cue.group, cue.gain_db + distance_db(absf(dx)), cue.pitch, cue.ramp_ms, dx * zoom)
	var dist: float = absf(dx)
	if dist >= float(mix.space.max_distance):
		dropped += 1
		return false
	var vsel: int = cue.variant
	if bank.warming and not bank.is_ready(cue.sound, vsel):
		vsel = bank.pick_ready(cue.sound, vsel)      # another variant of the same sound is rendered: play that one
		if vsel < 0:
			_defer(cue, cam_x, zoom)      # none is: its sound goes to the front of the queue, and the cue waits for it
			return false
	var slot: int = _take(cue)
	if slot < 0:
		dropped += 1
		return false
	var p: AudioStreamPlayer2D = _pool[slot]
	if web != null and bool(_meta[slot].get("js", false)):
		web.stop_slot(slot)
	if _web_ok(cue):
		var st: AudioStreamWAV = bank.stream(cue.sound, vsel)
		var key: String = "%s#%d" % [cue.sound, vsel]
		web.ensure(key, st)
		var bus_name: String = cue.bus
		var lp: float = 0.0
		if cue.muffled:
			bus_name = "SfxMuffled" if cue.bus == "Sfx" else ("VoiceMuffled" if cue.bus == "Voice" else cue.bus)
			lp = float(_lowpass.get(bus_name, 0.0))
		var half: float = maxf(get_viewport().get_visible_rect().size.x * 0.5, 1.0)
		var pan: float = clampf(dx * zoom / half, -1.0, 1.0)
		var lin: float = db_to_linear(cue.gain_db + distance_db(dist) + WEB_TRIM_DB)
		if web.play(slot, key, lin, pan, cue.pitch, bus_name, lp, cue.group):
			p.stop()
			_kill_tween(slot)
			_meta[slot] = {"priority": cue.priority, "group": cue.group, "t": _clock, "cls": cue.cls, "js": true, "until": _clock + st.get_length() / maxf(cue.pitch, 0.1)}
			for d in cue.duck:
				_hold_down(String(d.bus), float(d.db), int(d.ms))
			played += 1
			return true
	p.stop()
	_kill_tween(slot)
	p.stream = _looped(bank.stream(cue.sound, vsel)) if cue.loop else bank.stream(cue.sound, vsel)
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
			if _meta[i].group == cue.group and _busy(i):
				return i
	if cue.cap > 0 and cue.cls != "":
		var oldest: int = -1
		var count: int = 0
		for i in range(_pool.size()):
			if _busy(i) and _meta[i].cls == cue.cls:
				count += 1
				if oldest == -1 or _meta[i].t < _meta[oldest].t:
					oldest = i
		if count >= cue.cap:
			return oldest if cue.priority >= int(_meta[oldest].priority) else -1
	var weakest: int = -1
	for i in range(_pool.size()):
		if not _busy(i):
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
		if web != null and bool(_meta[i].get("js", false)) and float(_meta[i].get("until", 0.0)) > _clock and _meta[i].group == group:
			found = true
			web.stop_slot(i, fade_ms)
			_meta[i]["until"] = 0.0
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
	for i in range(_pool.size()):
		if _busy(i):
			n += 1
	return n
