class_name AudioTug
extends RefCounted
## The beam struggle's sound (docs/audio/launch-and-tug.md): Encounter's five cues (beam_struggle, beam_pulse, beam_surge,
## beam_stray, beam_end) and the meeting point become a clash thud, a bed of two looped drones that tightens as the point
## nears either fighter, a beat on every pulse, a whump on a surge, a quiet droop on a stray, and an ending. Created and
## called by AudioCues. Pure logic: it reads the sim (the cues and Clash.mid) and never writes it; it needs no sound device.
##
## PARKED behind data/tug_cues.json "enabled" (false): until Encounter's window is on main nothing here runs, and
## audio is byte-for-byte what it was. Every number and name is in the data.
##
## The meeting point, 0 at A's hands to 1 at D's: S.game.clash.mid when it exists (Simulation's field, on main), else the
## `amount` a cue carries (> 0) once Encounter sends it, else where it was.

const TUG_PATH := "res://audio/data/tug_cues.json"

var cfg: Dictionary = {}
var cues                                  # AudioCues
var _on: bool = false
var _a: int = -1                          # the slot at whose hands the point is 0 (the firer)
var _d: int = -1
var _mid: float = 0.5
var _sent_mid: float = -1.0               # the point the bed was last told about
var _sent_tick: int = -999
var _t0: int = 0
var _stray: Dictionary = {}               # slot -> the tick of its last droop


func _init(p_cues) -> void:
	cues = p_cues
	cfg = AudioBank.load_json(TUG_PATH)


func reset() -> void:
	_on = false
	_a = -1
	_d = -1
	_mid = 0.5
	_sent_mid = -1.0
	_sent_tick = -999
	_stray.clear()


## For AudioCarry (the groove and the cracks follow the struggle):
func is_on() -> bool:
	return _on and enabled()


func dist() -> float:
	return _dist()


func point(S: SimState) -> Vector2:
	return _point(S)


func enabled() -> bool:
	return bool(cfg.get("enabled", false))


## The ids of the drones, for AudioBank (drone.<name>).
func drone_recipe(name: String) -> Dictionary:
	return cfg.get("drones", {}).get(name, {})


## One cue of the five. A struggle that has not started (its start cue was missed) makes nothing but the lone sounds.
func on_cue(S: SimState, e, out: Array) -> void:
	if not enabled():
		return
	match String(e.kind):
		"beam_struggle":
			if String(e.text) == "start":
				_start(S, e, out)
		"beam_pulse":
			_pulse(S, e, out)
		"beam_surge":
			_surge(S, e, out)
		"beam_stray":
			_stray_press(S, e, out)
		"beam_end":
			_end(S, e, out)


## Once a tick after the cues: tell the bed where the point is, if it moved.
func after(S: SimState, out: Array) -> void:
	if not _on or not enabled():
		return
	_read_mid(S, null)
	if S.tick - _t0 > int(cfg.bed.max_ticks):
		_stop_bed(out, 300)      # a missed end cue must not leave a drone running
		_on = false
		return
	if absf(_mid - _sent_mid) >= float(cfg.bed.min_mid_step) and S.tick - _sent_tick >= int(cfg.bed.min_ticks_between_updates):
		_bed(S, out, true)


func _slot_of(S: SimState, v) -> int:
	return S.fighters.find(v) if v != null else -1


func _read_mid(S: SimState, e) -> void:
	var c = S.game.clash
	var m = c.get("mid") if c != null else null      # get(): a sim that has no Clash.mid yet is not an error
	if m != null and float(m) >= 0.0:
		_mid = clampf(float(m), 0.0, 1.0)
	elif e != null and float(e.x) > 0.0 and float(e.x) <= 1.0:
		_mid = clampf(float(e.x), 0.0, 1.0)      # Encounter's agreed cue list: `x` is the point, 0 at the actor's hands to 1 at the target's
	elif e != null and float(e.amount) > 0.0:
		_mid = clampf(float(e.amount), 0.0, 1.0)


## How far the point is from the middle: 0 even, 1 at a fighter's hands.
func _dist() -> float:
	return clampf(absf(_mid - 0.5) * 2.0, 0.0, 1.0)


func _point(S: SimState) -> Vector2:
	if _a < 0 or _d < 0 or _a >= S.fighters.size() or _d >= S.fighters.size():
		return Vector2(S.fighters[0].x, S.fighters[0].y)
	var fa = S.fighters[_a]
	var fd = S.fighters[_d]
	var x: float = fa.x + SimWrap.sdx(fa.x, fd.x) * _mid
	return Vector2(fposmod(x, float(SimConst.W)), (fa.y + fd.y) * 0.5)


func _fixed(sound: String, p: Vector2, gain_db: float, pitch: float, priority: int, cls: String, cap: int, caption: String = ""):
	var c = cues.Cue.new()
	c.sound = sound
	c.variant = 0
	c.x = p.x
	c.y = p.y
	c.gain_db = gain_db
	c.pitch = pitch
	c.priority = priority
	c.bus = "Sfx"
	c.cls = cls
	c.cap = cap
	c.caption = caption
	return c


func _duck(c) -> void:
	var D: Dictionary = cfg.duck
	c.duck = [{"bus": String(D.bus), "db": float(D.db), "ms": int(D.ms)}]


## The bed's two voices: first start (loop true) or an update of where they are (loop false, update true).
func _bed(S: SimState, out: Array, update: bool) -> void:
	var B: Dictionary = cfg.bed
	var d: float = _dist()
	var p: Vector2 = _point(S)
	var pitch: float = pow(2.0, float(B.pitch_st_at_end) * d / 12.0)
	var lo_g: Array = B.lo.gain_db
	var hi_g: Array = B.hi.gain_db
	var det: Array = B.hi.detune
	var lo = _fixed("drone.bed.lo", p, lerpf(float(lo_g[0]), float(lo_g[1]), d), pitch, int(B.priority), String(B.cls), int(B.cap))
	var hi = _fixed("drone.bed.hi", p, lerpf(float(hi_g[0]), float(hi_g[1]), d), pitch * (1.0 + lerpf(float(det[0]), float(det[1]), d)), int(B.priority), String(B.cls), int(B.cap))
	lo.group = "tug.bed.lo"
	hi.group = "tug.bed.hi"
	for c in [lo, hi]:
		c.loop = true
		c.update = update
		c.ramp_ms = int(B.ramp_ms)
		out.append(c)
	_sent_mid = _mid
	_sent_tick = S.tick


func _stop_bed(out: Array, fade_ms: int) -> void:
	for g in ["tug.bed.lo", "tug.bed.hi"]:
		var s = cues.Cue.new()
		s.stop_group = g
		s.fade_ms = fade_ms
		out.append(s)


func _start(S: SimState, e, out: Array) -> void:
	var a: int = int(e.actor)
	var t: int = int(e.target)
	if a < 0 or t < 0 or a == t or a >= S.fighters.size() or t >= S.fighters.size():
		var c = S.game.clash
		if c == null:
			return
		a = _slot_of(S, c.A)
		t = _slot_of(S, c.D)
		if a < 0 or t < 0:
			return
	_a = a
	_d = t
	_on = true
	_t0 = S.tick
	_mid = 0.5
	_read_mid(S, e)
	var L: Dictionary = cfg.lock
	var p: Vector2 = _point(S)
	var lock = _fixed(String(L.sound), p, float(L.gain_db), float(L.pitch), int(L.priority), String(L.cls), int(L.cap), String(L.caption))
	_duck(lock)
	out.append(lock)
	var w: Dictionary = L["with"]
	out.append(_fixed(String(w.sound), p, float(w.gain_db), float(w.pitch), int(L.priority), String(L.cls), int(L.cap)))
	_bed(S, out, false)


## The beat: a fixed low thud on the pulse's tick, whose pitch steps up as the point nears either fighter.
func _pulse(S: SimState, e, out: Array) -> void:
	if not _on:
		return
	_read_mid(S, e)
	var P: Dictionary = cfg.pulse
	var step: float = roundf(float(P.steps_st) * _dist())
	var c = _fixed(String(P.sound), _point(S), float(P.gain_db), pow(2.0, step / 12.0), int(P.priority), String(P.cls), int(P.cap))
	_duck(c)
	out.append(c)


func _surge(S: SimState, e, out: Array) -> void:
	if not _on:
		return
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var U: Dictionary = cfg.surge
	var sharp: bool = String(e.text) == "sharp"
	var f = S.fighters[a]
	var p := Vector2(f.x, f.y)
	out.append(_fixed(String(U.sound), p, float(U.gain_db) + (float(U.sharp_db) if sharp else 0.0), 1.0, int(U.priority), String(U.cls), int(U.cap)))
	if sharp:
		var T: Dictionary = U.sharp_tok
		out.append(_fixed(String(T.sound), p, float(T.gain_db), float(T.pitch), int(U.priority), String(U.cls), int(U.cap)))


## A stray moves nothing, so its sound is one soft droop, and at most one every gap_ticks for a fighter: a mash is never a buzz.
func _stray_press(S: SimState, e, out: Array) -> void:
	if not _on:
		return
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var Y: Dictionary = cfg.stray
	if S.tick - int(_stray.get(a, -999)) < int(Y.gap_ticks):
		return
	_stray[a] = S.tick
	var f = S.fighters[a]
	out.append(_fixed(String(Y.sound), Vector2(f.x, f.y), float(Y.gain_db), 1.0, int(Y.priority), String(Y.cls), int(Y.cap)))


func _end(S: SimState, e, out: Array) -> void:
	var E: Dictionary = cfg.end
	var kind: String = String(e.text)
	if not E.has(kind):
		kind = "time"
	_read_mid(S, e)
	var R: Dictionary = E[kind]
	var p: Vector2 = _point(S) if _on else Vector2(float(e.x), float(e.y))
	# the loser stands at the end the point reached; on time, the side the point is on
	var side: int = _d if _mid >= 0.5 else _a
	if kind == "overwhelmed" and int(e.target) >= 0 and int(e.target) < S.fighters.size():
		side = int(e.target)      # the cue names the loser
	if (kind == "overwhelmed" or kind == "time") and side >= 0 and side < S.fighters.size():
		p = Vector2(S.fighters[side].x, S.fighters[side].y)
	_stop_bed(out, int(R.fade_ms))
	out.append(_fixed(String(R.sound), p, float(R.gain_db), 1.0, int(E.priority), String(E.cls), int(E.cap)))
	if R.has("with"):
		var w: Dictionary = R["with"]
		out.append(_fixed(String(w.sound), p, float(w.gain_db), float(w.pitch), int(E.priority), String(E.cls), int(E.cap)))
	_on = false
