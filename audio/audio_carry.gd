class_name AudioCarry
extends RefCounted
## Sound that carries what the HUD no longer draws (Orb, 2026-10-18: "nothing on, over or between the fighters"; Game Design's
## docs/design/minimal-hud.md, Research's docs/research/readable-speed.md, docs/audio/carry.md). Created and called by AudioCues.
## It reads the sim's cues and events and returns sound cues; it never writes the sim and needs no sound device.
##
## What it makes, all in the lower, chunkier family (Orb, 2026-10-16):
##   * the beam struggle's groove locked to its pulse (a ghost knock on the off-beat, taps on the sixteenths as the point nears
##     an end) and its cracks (a surge cracks, a sharp one cracks brighter, and the point nearing a fighter cracks the beams);
##   * the grip (grapple.md): a clasp when the clinch starts, a creak on each pulse that climbs with the grip, a thud for a
##     pummel, nothing for a stray, a short dull refusal for a press in the lockout;
##   * the ready form's sting and the coil's hum (a looped drone that rises with the coil);
##   * the air brake's skid;
##   * a rush, panned by where the rusher is;
##   * a perfect block's own sound.
##
## PARKED behind data/carry_cues.json "enabled" (false): until Orb and the EP switch it on, nothing here runs and audio is
## byte-for-byte what it was. Every number and name is in the data. The struggle's groove and cracks also need
## data/tug_cues.json "enabled" (the struggle itself).

const CARRY_PATH := "res://audio/data/carry_cues.json"

var cfg: Dictionary = {}
var cues                                  # AudioCues
var _due: Array = []                      # {tick, cue}: sounds that fall due on a later tick (the groove)
var _armed: Array = []                    # per proximity threshold: may it crack again
var _coil: Dictionary = {}                # actor slot -> true while its hum plays


func _init(p_cues) -> void:
	cues = p_cues
	cfg = AudioBank.load_json(CARRY_PATH)


func reset() -> void:
	_due.clear()
	_armed.clear()
	_coil.clear()


func enabled() -> bool:
	return bool(cfg.get("enabled", false))


func _fixed(sound: String, p: Vector2, gain_db: float, pitch: float, priority: int, cls: String, cap: int, bus: String = "Sfx"):
	var c = cues.Cue.new()
	c.sound = sound
	c.variant = 0
	c.x = p.x
	c.y = p.y
	c.gain_db = gain_db
	c.pitch = pitch
	c.priority = priority
	c.bus = bus
	c.cls = cls
	c.cap = cap
	return c


func _pos(S: SimState, slot: int) -> Vector2:
	if slot < 0 or slot >= S.fighters.size():
		return Vector2(S.fighters[0].x, S.fighters[0].y)
	return Vector2(S.fighters[slot].x, S.fighters[slot].y)


## The cue events (type "cue").
func on_cue(S: SimState, e, out: Array) -> void:
	if not enabled():
		return
	match String(e.kind):
		"beam_pulse":
			_groove(S, e, out)
		"beam_surge":
			_surge_crack(S, e, out)
		"grapple_clinch":
			_clasp(S, e, out)
		"grapple_pulse":
			_creak(S, e, out)
		"grapple_pummel":
			_pummel(S, e, out)
		"grapple_refused":
			_refuse(S, e, out)
		"perfect_block":
			_block(S, e, out)


## The sim's other events (their own types): rush, the forms and the brake.
func on_event(S: SimState, e, out: Array) -> void:
	if not enabled():
		return
	match String(e.type):
		"rush":
			_rush(S, e, out)
		"transform_ready":
			_ready(S, e, out)
		"form_hold":
			_coil_hold(S, e, out)
		"form_release":
			_coil_release(S, e, out)
		"air_brake":
			_brake(S, e, out)


## Once a tick after the events: the groove's later sounds, and the beams cracking as the point nears a fighter.
func after(S: SimState, out: Array) -> void:
	if not enabled():
		return
	var keep: Array = []
	for d in _due:
		if S.tick >= int(d.tick):
			out.append(d.cue)
		else:
			keep.append(d)
	_due = keep
	if not cues.tug.is_on():
		_armed.clear()
		return
	var K: Dictionary = cfg.struggle.crack
	var near: Dictionary = K.near
	var th: Array = near.thresholds
	while _armed.size() < th.size():
		_armed.append(true)
	var dist: float = cues.tug.dist()
	for i in range(th.size()):
		if _armed[i] and dist >= float(th[i]):
			_armed[i] = false
			out.append(_fixed(String(K.sound), cues.tug.point(S), float(near.gain_db), float(near.pitches[i]), int(K.priority), String(K.cls), int(K.cap)))
		elif not _armed[i] and dist < float(th[i]) - float(near.rearm_below):
			_armed[i] = true


# ---- the beam struggle

## On each pulse the kick is the pulse itself (AudioTug); here the off-beat knock 10 ticks on, and the sixteenths when the point
## is far from the middle: a groove at 180 beats a minute that tightens toward an end, and never depends on the music.
func _groove(S: SimState, e, out: Array) -> void:
	if not cues.tug.is_on():
		return
	var G: Dictionary = cfg.struggle.groove
	var step: float = roundf(float(G.steps_st) * cues.tug.dist())
	var pitch: float = pow(2.0, step / 12.0)
	var p: Vector2 = cues.tug.point(S)
	_due.append({"tick": S.tick + int(G.tock_ticks), "cue": _fixed(String(G.tock.sound), p, float(G.tock.gain_db), pitch, int(G.priority), String(G.cls), int(G.cap))})
	if cues.tug.dist() >= float(G.tick.dense_from):
		for t in G.tick.ticks:
			_due.append({"tick": S.tick + int(t), "cue": _fixed(String(G.tick.sound), p, float(G.tick.gain_db), pitch, int(G.priority), String(G.cls), int(G.cap))})


func _surge_crack(S: SimState, e, out: Array) -> void:
	if not cues.tug.is_on():
		return
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var K: Dictionary = cfg.struggle.crack
	var sharp: bool = String(e.text) == "sharp"
	out.append(_fixed(String(K.sound), _pos(S, a), float(K.sharp_db) if sharp else float(K.surge_db), float(K.sharp_pitch) if sharp else 1.0, int(K.priority), String(K.cls), int(K.cap)))


# ---- the grip

func _clasp(S: SimState, e, out: Array) -> void:
	if String(e.text) != "start":
		return
	var C: Dictionary = cfg.grapple.clasp
	out.append(_fixed(String(C.sound), _pos(S, int(e.target)), float(C.gain_db), 1.0, int(C.priority), String(C.cls), int(C.cap)))


## A creak on each pulse of the grip, a semitone higher for each point of the catcher's grip (to grip_max): who is ahead can be heard.
func _creak(S: SimState, e, out: Array) -> void:
	var C: Dictionary = cfg.grapple.creak
	var grip: float = clampf(absf(float(e.amount)), 0.0, float(C.grip_max))
	var p: Vector2 = (_pos(S, int(e.actor)) + _pos(S, int(e.target))) * 0.5
	out.append(_fixed(String(C.sound), p, float(C.gain_db), pow(2.0, float(C.grip_st) * grip / 12.0), int(C.priority), String(C.cls), int(C.cap)))


func _pummel(S: SimState, e, out: Array) -> void:
	var P: Dictionary = cfg.grapple.pummel
	var text: String = String(e.text)
	if text in P.silent_texts:
		return
	var sharp: bool = text == "sharp"
	var p: Vector2 = _pos(S, int(e.target))
	out.append(_fixed(String(P.sound), p, float(P.gain_db) + (float(P.sharp_db) if sharp else 0.0), 1.0, int(P.priority), String(P.cls), int(P.cap)))
	if sharp:
		var T: Dictionary = P.sharp_tok
		out.append(_fixed(String(T.sound), p, float(T.gain_db), float(T.pitch), int(P.priority), String(P.cls), int(P.cap)))


func _refuse(S: SimState, e, out: Array) -> void:
	var R: Dictionary = cfg.grapple.refuse
	if not (String(e.text) in R.texts):
		return
	out.append(_fixed(String(R.sound), _pos(S, int(e.actor)), float(R.gain_db), 1.0, int(R.priority), String(R.cls), int(R.cap)))


# ---- forms, brake, rush, the perfect block

func _ready(S: SimState, e, out: Array) -> void:
	var R: Dictionary = cfg.forms.ready
	out.append(_fixed(String(R.sound), _pos(S, int(e.actor)), float(R.gain_db), 1.0, int(R.priority), String(R.cls), int(R.cap), String(R.bus)))


## The coil's hum: a looped low drone under the music that rises with the coil (0 to 100). Started by the first form_hold, moved
## by each later one, stopped by the release.
func _coil_hold(S: SimState, e, out: Array) -> void:
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var C: Dictionary = cfg.forms.coil
	var k: float = clampf(float(e.amount) / float(C.coil_max), 0.0, 1.0)
	var c = _fixed("drone." + String(C.drone), _pos(S, a), lerpf(float(C.gain_db[0]), float(C.gain_db[1]), k), pow(2.0, float(C.pitch_st_at_max) * k / 12.0), int(C.priority), String(C.cls), int(C.cap))
	c.group = "coil.%d" % a
	c.loop = true
	c.update = _coil.has(a)
	c.ramp_ms = int(C.ramp_ms)
	_coil[a] = true
	out.append(c)


func _coil_release(S: SimState, e, out: Array) -> void:
	var a: int = int(e.actor)
	if not _coil.has(a):
		return
	_coil.erase(a)
	var s = cues.Cue.new()
	s.stop_group = "coil.%d" % a
	s.fade_ms = int(cfg.forms.coil.stop_ms)
	out.append(s)


## The skid: it starts with the brake and is cut when it ends; its level and pitch follow the send's speed.
func _brake(S: SimState, e, out: Array) -> void:
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var B: Dictionary = cfg.brake
	if String(e.text) == "end":
		var s = cues.Cue.new()
		s.stop_group = "brake.%d" % a
		s.fade_ms = int(B.stop_ms)
		out.append(s)
		return
	var f: float = clampf(float(e.amount) / float(B.full_speed), 0.0, 1.4)
	var c = _fixed(String(B.sound), _pos(S, a), float(B.gain_db) + float(B.gain_db_per_full) * f, lerpf(1.0, float(B.pitch_at_full), minf(f, 1.0)), int(B.priority), String(B.cls), int(B.cap))
	c.group = "brake.%d" % a
	out.append(c)


## A rush: the whoosh at the rusher, so the stereo place says where he is coming from, sized to the ticks to his arrival; it falls
## in pitch as it passes.
func _rush(S: SimState, e, out: Array) -> void:
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var R: Dictionary = cfg.rush
	var ticks: int = maxi(int(e.n) - S.tick, 1)
	var pitch: float = clampf(float(R.nominal_ticks) / float(ticks), float(R.pitch_min), float(R.pitch_max))
	out.append(_fixed(String(R.sound), _pos(S, a), float(R.gain_db), pitch, int(R.priority), String(R.cls), int(R.cap)))


## A perfect block: the guard's thud with a round tone over it. `actor` is the blocker.
func _block(S: SimState, e, out: Array) -> void:
	var B: Dictionary = cfg.perfect_block
	out.append(_fixed(String(B.sound), _pos(S, int(e.actor)), float(B.gain_db), 1.0, int(B.priority), String(B.cls), int(B.cap)))
