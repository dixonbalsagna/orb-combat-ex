class_name AudioScene
extends RefCounted
## The sound around the fight (docs/audio/friends-sound.md): one quiet wind bed and the buildings. Reads the sim's state and
## events, never writes them, and draws nothing from the sim's RNG. Created and called by AudioCues; numbers and switches in
## data/scene_cues.json (the menu sounds there are played by AudioVoices.ui, not from here).
##
## The wind is one looped voice: started low, faded to its level, then moved a few times a second: louder high above the
## ground, quieter while blows are landing. It stands down when the biome beds are on (data/world_cues.json).
##
## Buildings: building_hit and floor_hit (a blow into one), building_stage (windows out; a part gone or a shell),
## floors_fall (a stack coming down) and building_fall (a collapse; a blast's ripple carries its own delay). An area blast
## can send a score of these in one tick, so each kind makes at most one cue a tick (the one nearest the fighters), louder
## for more of them, with a short wait before the next.

const PATH := "res://audio/data/scene_cues.json"
const GROUP := "wind"
const KINDS: Array = ["hit", "glass", "crack", "floors", "fall"]

var cfg: Dictionary = {}
var cues                                    # AudioCues

var _wind_on: bool = false                  # the loop has been asked for in this match
var _duck: float = 0.0                      # 0..1+: how much the fight is holding the wind down
var _duck_tick: int = 0
var _next_upd: int = 0
var _next_ok: Dictionary = {}               # kind -> the tick it may sound again
var _due: Array = []                        # {tick, cue}: a collapse that comes after its blast's ripple


func _init(p_cues) -> void:
	cues = p_cues
	cfg = AudioBank.load_json(PATH)


func reset() -> void:
	_wind_on = false
	_duck = 0.0
	_duck_tick = 0
	_next_upd = 0
	_next_ok.clear()
	_due.clear()


func wind_enabled() -> bool:
	return bool(cfg.get("wind", {}).get("enabled", false)) and not (cues.world != null and cues.world.enabled())


func buildings_enabled() -> bool:
	return bool(cfg.get("buildings", {}).get("enabled", false))


## One tick: its events (S.out.fx), the cues appended to out.
func consume(S: SimState, events: Array, out: Array) -> void:
	if buildings_enabled():
		_buildings(S, events, out)
	if wind_enabled():
		_wind(S, events, out)


# ---- the wind

func _wind(S: SimState, events: Array, out: Array) -> void:
	var W: Dictionary = cfg.wind
	var dt: int = maxi(S.tick - _duck_tick, 0)
	_duck_tick = S.tick
	if dt > 0 and _duck > 0.0:
		_duck *= exp(-float(dt) / (float(W.duck_decay_s) * 60.0))
	for e in events:
		if String(e.type) == "damage":
			_duck += float(e.amount) * float(W.duck_per_damage)
	if not _wind_on:
		_wind_on = true
		_next_upd = S.tick + int(W.update_every)
		var start = _level(S, 0)
		var target: float = start.gain_db
		start.gain_db = float(W.start_db)
		out.append(start)
		var up = _level(S, int(W.fade_ms))
		up.gain_db = target
		up.update = true
		out.append(up)
		_next_upd = S.tick + int(ceil(float(W.fade_ms) * 0.06))     # let the fade finish before the first move
		return
	# An update goes on every beat, moved or not: if the loop had to wait for its sound to be rendered, the next one sets its level.
	if S.tick >= _next_upd:
		_next_upd = S.tick + int(W.update_every)
		var u = _level(S, int(W.ramp_ms))
		u.update = true
		out.append(u)


func _level(S: SimState, ramp_ms: int):
	var W: Dictionary = cfg.wind
	var p: Vector2 = _pair(S)
	var alt: float = clampf((p.y - WorldTerrain.groundY(S, p.x)) / float(W.alt_ref), 0.0, 1.0)
	var c = cues.Cue.new()
	c.sound = String(W.sound)
	c.gain_db = float(W.gain_db) + float(W.alt_db) * alt + float(W.duck_db) * clampf(_duck, 0.0, 1.0)
	c.x = p.x
	c.y = p.y
	c.bus = String(W.bus)
	c.priority = int(W.priority)
	c.cls = "amb.wind"
	c.cap = 1
	c.group = GROUP
	c.ambient = true
	c.loop = true
	c.ramp_ms = ramp_ms
	return c


## The middle of the fight's bodies, from the list: each one's shortest arc from the first, averaged, and their mean height.
func _pair(S: SimState) -> Vector2:
	var from_x: float = 0.0
	var dx: float = 0.0
	var y: float = 0.0
	var n: int = 0
	for f in S.fighters:
		if n == 0:
			from_x = f.x
		dx += SimWrap.sdx(from_x, f.x)
		y += f.y
		n += 1
	var k: float = float(maxi(n, 1))
	return Vector2(SimWrap.wrap(from_x + dx / k), y / k)


# ---- the buildings

func _buildings(S: SimState, events: Array, out: Array) -> void:
	if not _due.is_empty():
		var keep: Array = []
		for d in _due:
			if S.tick >= int(d.tick):
				out.append(d.cue)
			else:
				keep.append(d)
		_due = keep
	var seen: Dictionary = {}               # kind -> {n, x, y, h, db, delay, far}
	for e in events:
		match String(e.type):
			"building_hit":
				_note(S, seen, "hit", float(e.x), float(e.y), float(e.h), _outcome_db(String(e.outcome)), 0.0, 1.0)
			"floor_hit":
				_note(S, seen, "hit", float(e.x), float(e.y), 0.0, _outcome_db(String(e.outcome)), 0.0, 1.0)
			"building_stage":
				var to: int = int(e.to)
				if to == 1:
					_note(S, seen, "glass", float(e.x), float(e.y) + float(e.h) * 0.5, float(e.h), 0.0, 0.0, 1.0)
				elif to == 2 or to == 3:
					_note(S, seen, "crack", float(e.x), float(e.y) + float(e.h) * 0.5, float(e.h), 0.0, 0.0, 1.0)
			"floors_fall":
				_note(S, seen, "floors", float(e.x), WorldTerrain.groundY(S, float(e.x)), 0.0, 0.0, 0.0, 1.0)
			"building_fall":
				# depth carries the building's height (SimFx.buildingFall); n folds in the implodes past the event cap
				_note(S, seen, "fall", float(e.x), WorldTerrain.groundY(S, float(e.x)), float(e.depth), 0.0, float(e.delay), maxf(float(e.n), 1.0))
	if seen.is_empty():
		return
	var B: Dictionary = cfg.buildings
	for kind in KINDS:
		if not seen.has(kind) or S.tick < int(_next_ok.get(kind, 0)):
			continue
		var s: Dictionary = seen[kind]
		var R: Dictionary = B[kind]
		_next_ok[kind] = S.tick + int(R.cooldown_ticks)
		var gain: float = float(R.gain_db) + float(s.db) + minf(float(B.gain_db_per_ln) * log(float(s.n)), float(B.count_db_max))
		var pitch: float = 1.0
		if float(s.h) > 0.0:
			pitch = clampf(pow(float(s.h) / float(B.ref_height), float(B.pitch_exp)), float(B.pitch_min), float(B.pitch_max))
		var c = cues.make_cue(String(R.sound), float(s.x), float(s.y), gain, pitch, int(R.priority), "Sfx", String(R.cls), int(R.cap), String(R.get("caption", "")), S)
		if float(s.delay) > 0.0:
			_due.append({"tick": S.tick + int(round(float(s.delay) * 60.0)), "cue": c})
		else:
			out.append(c)


## Gather one event of a kind: count them, and keep the one nearest the fighters (the loudest outcome's trim with it).
func _note(S: SimState, seen: Dictionary, kind: String, x: float, y: float, h: float, db: float, delay: float, n: float) -> void:
	var far: float = absf(SimWrap.sdx(_pair(S).x, x))
	if not seen.has(kind):
		seen[kind] = {"n": n, "x": x, "y": y, "h": h, "db": db, "delay": delay, "far": far}
		return
	var s: Dictionary = seen[kind]
	s.n = float(s.n) + n
	s.db = maxf(float(s.db), db)
	if far < float(s.far):
		s.x = x
		s.y = y
		s.h = h
		s.delay = delay
		s.far = far


func _outcome_db(outcome: String) -> float:
	return float(cfg.buildings.hit.ratio_db.get(outcome, 0.0))
