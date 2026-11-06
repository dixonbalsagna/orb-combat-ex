class_name AudioMoments
extends RefCounted
## The moments a player would notice that had no sound: a beam charging and firing, a KO, the biggest blows, a launch, the meteor's
## landing, a parry and two bolts meeting (docs/audio/first-play-sound.md, the EP's brief of 2026-11-01). Created and called by
## AudioCues. It reads the sim's events and returns sound cues; it never writes the sim and needs no sound device.
##
## EXISTING SOUNDS ONLY (no new recipe): the gather, the blast, the heavy hit, the crater, the whoosh of a rush, the guard and the
## absorbed hit, each at its own pitch and level in data/moment_cues.json. The silence while the meteor flies is left as it is (it
## stands in for "the silence before a huge hit"). PARKED behind that file's "enabled" (false): off, nothing here runs and audio is
## byte-for-byte what it was (no cue, and no draw from the audio stream).

const PATH := "res://audio/data/moment_cues.json"

var cfg: Dictionary = {}
var cues                                  # AudioCues
var _meteor_until: int = -1               # a crater until this tick is the meteor's landing


func _init(p_cues) -> void:
	cues = p_cues
	cfg = AudioBank.load_json(PATH)


func reset() -> void:
	_meteor_until = -1


func enabled() -> bool:
	return bool(cfg.get("enabled", false))


## Every event, in order (AudioCues.consume calls this for each).
func on_event(S: SimState, e, out: Array) -> void:
	if not enabled():
		return
	match String(e.type):
		"cue":
			match String(e.kind):
				"beam_charge":
					_charge(S, e, out)
				"beam_fire":
					_fire(S, e, out)
				"arc_send":
					if String(e.text) == "meteor":
						_meteor_until = S.tick + int(cfg.meteor.within_ticks)
		"ko":
			_layers(S, cfg.ko, _slot(S, int(e.loser)), out)
		"decisive":
			var D: Dictionary = cfg.decisive
			if D.kinds.has(String(e.kind)):
				_layers(S, D.kinds[String(e.kind)], _slot(S, int(e.loser)), out)
		"launch":
			_layers(S, cfg.launch, _slot(S, int(e.actor)), out)
		"parry":
			_layers(S, cfg.parry, _slot(S, int(e.actor)), out)
		"shot_clash":
			_layers(S, cfg.shot_clash, Vector2(float(e.x), float(e.y)), out)
		"crater":
			if _meteor_until >= S.tick and float(e.energy) >= float(cfg.meteor.min_energy):
				_meteor_until = -1
				_layers(S, cfg.meteor, Vector2(float(e.x), float(e.y)), out)


func _slot(S: SimState, slot: int) -> Vector2:
	if slot < 0 or slot >= S.fighters.size():
		return Vector2(S.fighters[0].x, S.fighters[0].y)
	return Vector2(S.fighters[slot].x, S.fighters[slot].y)


## One cue for each layer of a rule: {layers: [{sound, gain_db, pitch}], priority, cls, cap, caption}.
func _layers(S: SimState, R: Dictionary, p: Vector2, out: Array) -> void:
	for L in R.layers:
		out.append(cues.make_cue(String(L.sound), p.x, p.y, float(L.gain_db), float(L.pitch), int(R.priority), String(R.get("bus", "Sfx")), String(R.cls), int(R.cap), String(R.get("caption", "")), S))


## A beam's charge (the tell before it fires): a gather at the shooter that is cut when the charge ends. The shooter is the actor.
func _charge(S: SimState, e, out: Array) -> void:
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var C: Dictionary = cfg.charge
	if String(e.text) == "start":
		var f = S.fighters[a]
		var c = cues.make_cue(String(C.sound), f.x, f.y, float(C.gain_db), float(C.pitch), int(C.priority), "Sfx", String(C.cls), int(C.cap), String(C.get("caption", "")), S)
		c.group = "beamcharge.%d" % a
		out.append(c)
	else:
		var stop = cues.Cue.new()
		stop.stop_group = "beamcharge.%d" % a
		stop.fade_ms = int(C.stop_ms)
		out.append(stop)


## The beam leaves the shooter.
func _fire(S: SimState, e, out: Array) -> void:
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	_layers(S, cfg.fire, _slot(S, a), out)
