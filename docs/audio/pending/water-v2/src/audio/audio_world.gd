class_name AudioWorld
extends RefCounted
## What the ground and the weather sound like (docs/audio/biomes.md). Three parts, all read-only on the sim:
##   * the bed: one looped ambience for the biome the pair is over (wind, surf, a city's hum), crossfaded when they cross a border and
##     ducked while the fight is intense;
##   * the surface: a hit and a slide per ground (grass, sand, snow, mud, water, rock, rubble, paving), played under a blow near the
##     ground, a landing, a bounce, a slide, a skim, a splash, a crater and a step.
## The surface is the sim's own read at the contact: WorldContact.surfaceAt (paving, rock, soil, sand, rubble, which also counts a
## rubble heap) and WorldWater (standing water); soil is made of the biome's own ground (data `soil`). Nothing here draws from the sim's
## RNG. Parked behind data/world_cues.json `enabled`.
##   * the water (World's water v2, sim/world/fill.gd): a hole filling (water_fill), a slam's ring wave (water_wave), water putting out a scorched
##     column (water_douse): data `water`.

const WORLD_PATH := "res://audio/data/world_cues.json"

var cues: AudioCues
var cfg: Dictionary = {}

var _group: String = ""         # the bed voice group sounding now ("amb.a" or "amb.b"), "" when none
var _biome: String = ""         # the biome id it is for
var _cand: String = ""          # a different biome seen for a while
var _cand_t: int = 0
var _flip: int = 0
var _intensity: float = 0.0     # the fight's intensity, 0..1+, decaying
var _int_tick: int = 0
var _next_upd: int = 0
var _sent_db: float = 0.0         # the level of the last update sent: a new one goes only when it has moved
var _next_step: Dictionary = {}
var _slide_i: Dictionary = {}
var _due: Array = []             # {tick, cue}: a later stop (the end of a fill's swell)
var _fill_n: int = 0             # the fills sounding take their groups in turn


func _init(p_cues) -> void:
	cues = p_cues
	cfg = AudioBank.load_json(WORLD_PATH)


func reset() -> void:
	_group = ""
	_biome = ""
	_cand = ""
	_cand_t = 0
	_flip = 0
	_intensity = 0.0
	_int_tick = 0
	_next_upd = 0
	_sent_db = 0.0
	_next_step.clear()
	_slide_i.clear()
	_due.clear()
	_fill_n = 0


func enabled() -> bool:
	return bool(cfg.get("enabled", false))


## The bed ids a match will want, for the host to warm at the start (the biomes of the ring, fine ones where the world has them, or all
## of them without a slice).
func warm_beds(S: SimState) -> Array:
	var seen: Dictionary = {}
	var cols: PackedByteArray = WorldBiomes.planetCols
	var fine: PackedByteArray = WorldBiomes.fineCols
	if cols.size() > 0:
		var use_fine: bool = fine.size() == cols.size()
		for i in range(0, cols.size(), 8):
			var st: int = cols[i]
			if st >= 7:
				seen["city" if st == 8 else "village"] = true      # a settlement's own ground: the stored codes 7 and 8 are not the fine ids
			elif use_fine:
				seen[WorldClimate.fineName(fine[i])] = true
			else:
				seen[WorldPlanetWorld.BIOME_NAME[st]] = true
	else:
		for s in WorldBiomes.SEG:
			seen[s[2]] = true
	var out: Array = []
	for b in seen:
		var id: String = "amb." + _bed_of(String(b))
		if not out.has(id):
			out.append(id)
	return out


## The biome at x as the sound keys on it: World's own reading (WorldBiomes.fineNameAt): a village or a city first (the settlement's own
## ground), then the fine biome on a generation 2 planet, else the stored biome's name: so a hand-made world or a generation 1 planet is
## the seven it always was.
func biome_at(x: float) -> String:
	return WorldBiomes.fineNameAt(x)


func _bed_of(biome: String) -> String:
	var B: Dictionary = cfg.biomes.get(biome, cfg.biomes[cfg.default_biome])
	return String(B.bed)


## One tick: the events of the tick (S.out.fx) and the cues they make appended to out.
func consume(S: SimState, events: Array, out: Array) -> void:
	if not enabled():
		return
	_decay(S)
	_flush(S, out)
	for e in events:
		match String(e.type):
			"damage":
				_on_damage(S, e, out)
			"crater":
				_on_crater(S, e, out)
			"land":
				_on_land(S, e, out, cfg.land)
			"bounce":
				_on_land(S, e, out, cfg.bounce)
			"slide_dust":
				_on_slide(S, e, out)
			"skim":
				_on_skim(S, e, out)
			"splash":
				_on_splash(S, e, out)
			"water_fill":
				_on_water_fill(S, e, out)
			"water_wave":
				_on_water_wave(S, e, out)
			"water_douse":
				_on_water_douse(S, e, out)
	_steps(S, out)
	_bed(S, out)


func _decay(S: SimState) -> void:
	var dt: int = maxi(S.tick - _int_tick, 0)
	_int_tick = S.tick
	if dt > 0 and _intensity > 0.0:
		_intensity *= exp(-float(dt) / (float(cfg.intensity.decay_s) * 60.0))
		if _intensity < 0.001:
			_intensity = 0.0


# ---- the surface of the ground at a place

## The surface class at (x, y): standing water if the contact is at or under its surface, else the sim's class at the column, with
## soil made of the biome's own ground.
func surface_at(S: SimState, x: float, y: float) -> String:
	var ws: float = WorldWater.surfaceAt(S, x)
	if ws > WorldWater.DRY and y <= ws + float(cfg.hit.water_margin):
		return "water"
	return _ground_of(WorldContact.surfaceAt(S, x), x)


## The ground a sim class means at x: soil, rock and sand take the fine biome's own ground where it has one (ice, a wetland, a beach),
## and soil the biome's soil; paving and rubble (and water) stand as the sim says.
func _ground_of(s: String, x: float) -> String:
	if s == "soil" or s == "rock" or s == "sand":
		var b: String = biome_at(x)
		if cfg.ground.has(b):
			return String(cfg.ground[b])
		if s == "soil":
			return String(cfg.soil.get(b, "grass"))
	return s


## The surface a sim event names (land and bounce carry one: paving, rock, soil, sand, rubble, water), or, with none, the one at the place.
## Soil is made of the biome's own ground.
func _surf(S: SimState, x: float, y: float, given: String = "") -> Dictionary:
	var s: String = surface_at(S, x, y) if given == "" else _ground_of(given, x)
	return cfg.surfaces.get(s, cfg.surfaces.grass)


func _emit(out: Array, sound: String, x: float, y: float, gain_db: float, pitch: float, priority: int, cls: String, cap: int, S: SimState) -> void:
	out.append(cues.make_cue(sound, x, y, gain_db, pitch, priority, "Sfx", cls, cap, "", S))


# ---- blows near the ground: a scuff of the ground under the hit

func _on_damage(S: SimState, e, out: Array) -> void:
	var H: Dictionary = cfg.hit
	_intensity += float(e.amount) * float(cfg.intensity.per_damage)
	if float(e.amount) < float(H.min_amount):
		return
	var g: float = WorldTerrain.groundY(S, float(e.x))
	var ws: float = WorldWater.surfaceAt(S, float(e.x))
	var floor_y: float = maxf(g, ws) if ws > WorldWater.DRY else g
	if float(e.y) - floor_y > float(H.near_ground):
		return
	var sf: Dictionary = _surf(S, float(e.x), float(e.y))
	var s: float = maxf(float(e.amount), 1.0) / float(H.ref)
	var pitch: float = clampf(pow(s, float(H.pitch_exp)), float(H.pitch_min), float(H.pitch_max)) * float(sf.pitch)
	var gain: float = float(H.gain_db) + float(sf.gain_db) + clampf(20.0 * float(H.gain_exp) * log(s) / log(10.0), float(H.gain_db_min), float(H.gain_db_max))
	_emit(out, String(sf.hit), float(e.x), float(e.y), gain, pitch, int(H.priority), String(H.cls), int(H.cap), S)


func _on_crater(S: SimState, e, out: Array) -> void:
	var C: Dictionary = cfg.crater
	_intensity += float(cfg.intensity.per_crater)
	if float(e.energy) < float(C.min_energy):
		return
	var sf: Dictionary = _surf(S, float(e.x), float(e.y))
	var s: float = maxf(float(e.energy), 0.001) / float(C.ref)
	var gain: float = float(C.gain_db) + float(sf.gain_db) + clampf(20.0 * float(C.gain_exp) * log(s) / log(10.0), float(C.gain_db_min), float(C.gain_db_max))
	var pitch: float = clampf(pow(s, float(C.pitch_exp)), float(C.pitch_min), float(C.pitch_max)) * float(sf.pitch)
	_emit(out, String(sf.hit), float(e.x), float(e.y), gain, pitch, int(C.priority), String(C.cls), int(C.cap), S)


# ---- a body meeting the ground

func _on_land(S: SimState, e, out: Array, L: Dictionary) -> void:
	var spd: float = float(e.spd)
	if spd < float(L.min_speed):
		return
	var sf: Dictionary = _surf(S, float(e.x), float(e.y), String(e.surface))
	var u: float = clampf(spd / float(L.ref_speed), 0.0, 1.5)
	var gain: float = float(L.gain_db) + float(sf.gain_db) + clampf(20.0 * log(maxf(u, 0.05)) / log(10.0), float(L.gain_db_min), float(L.gain_db_max))
	var pitch: float = lerpf(float(L.pitch_slow), float(L.pitch_fast), clampf(u, 0.0, 1.0)) * float(sf.pitch)
	_emit(out, String(sf.hit), float(e.x), float(e.y), gain, pitch, int(L.priority), String(L.cls), int(L.cap), S)


## A sample along a slide (every few): the drag of the ground, louder for a faster one.
func _on_slide(S: SimState, e, out: Array) -> void:
	var D: Dictionary = cfg.slide
	if int(e.n) % maxi(int(D.every), 1) != 0:
		return
	var sf: Dictionary = _surf(S, float(e.x), float(e.y), "water" if String(e.variant) == "water" else "")
	var gain: float = float(D.gain_db) + float(sf.gain_db) + float(D.gain_db_per_spd) * clampf(float(e.spd), 0.0, 1.5) - 3.0
	_emit(out, String(sf.slide), float(e.x), float(e.y), gain, float(D.pitch) * float(sf.pitch), int(D.priority), String(D.cls), int(D.cap), S)


func _on_skim(S: SimState, e, out: Array) -> void:
	var K: Dictionary = cfg.skim
	var sf: Dictionary = cfg.surfaces.water
	var u: float = clampf(float(e.spd) / float(K.ref_speed), 0.0, 1.0)
	_emit(out, String(sf.hit), float(e.x), float(e.y), float(K.gain_db) + float(sf.gain_db) - 3.0 * (1.0 - u), lerpf(float(K.pitch_slow), float(K.pitch_fast), u), int(K.priority), String(K.cls), int(K.cap), S)


func _on_splash(S: SimState, e, out: Array) -> void:
	var P: Dictionary = cfg.splash
	var sf: Dictionary = cfg.surfaces.water
	var gain: float = clampf(float(P.gain_db) + float(P.gain_db_per_ln) * log(maxf(float(e.n), 1.0) / float(P.ref_n)), float(P.gain_db_min), float(P.gain_db_max))
	_emit(out, String(sf.hit), float(e.x), float(e.y), gain + float(sf.gain_db), float(P.pitch), int(P.priority), String(P.cls), int(P.cap), S)


# ---- water v2: a hole filling, a ring wave, a fire put out

## A hole the fight dug fills (cause sea, water or table; amount the deepest dig, dur the seconds it takes to settle, spd the front's units a second,
## 0 for a seep): a low rushing swell at where the front starts, bigger and lower for a deeper dig, cut when the fill settles; a table's seep is
## a quiet trickle instead.
func _on_water_fill(S: SimState, e, out: Array) -> void:
	var F: Dictionary = cfg.water.fill
	var table: bool = String(e.cause) == "table"
	var amt: float = maxf(float(e.amount), 1.0)
	var gain: float = clampf(float(F.gain_db) + float(F.gain_db_per_ln) * log(amt / float(F.ref_amount)), float(F.gain_db_min), float(F.gain_db_max))
	if table:
		gain += float(F.seep_db)
	var pitch: float = clampf(pow(amt / float(F.ref_amount), float(F.pitch_exp)), float(F.pitch_min), float(F.pitch_max))
	var c = cues.make_cue(String(F.seep if table else F.sound), float(e.x), float(e.y), gain, pitch, int(F.priority), "Sfx", String(F.cls), int(F.cap), "", S)
	c.group = "water.fill.%d" % (_fill_n % int(F.groups))
	_fill_n += 1
	out.append(c)
	var hold: float = clampf(float(e.dur), float(F.min_s), float(F.max_s))
	var stop = cues.Cue.new()
	stop.stop_group = c.group
	stop.fade_ms = int(F.stop_ms)
	_due.append({"tick": S.tick + int(ceil(hold * 60.0)), "cue": stop})


## A slam into deep water sends a ring wave (x, the surface at y, a ring of r units, the push in amount): one heavy slosh at the slam.
func _on_water_wave(S: SimState, e, out: Array) -> void:
	var W: Dictionary = cfg.water.wave
	out.append(cues.make_cue(String(W.sound), float(e.x), float(e.y), float(W.gain_db), 1.0, int(W.priority), "Sfx", String(W.cls), int(W.cap), "", S))
	_intensity += float(cfg.intensity.per_crater)


## Water reaching a scorched column (x the fill's source, w the extent, n the columns newly wet): a short low hiss, bigger for more columns.
func _on_water_douse(S: SimState, e, out: Array) -> void:
	var D: Dictionary = cfg.water.douse
	var gain: float = clampf(float(D.gain_db) + float(D.gain_db_per_ln) * log(maxf(float(e.n), 1.0) / float(D.ref_n)), float(D.gain_db_min), float(D.gain_db_max))
	out.append(cues.make_cue(String(D.sound), float(e.x), float(e.y), gain, 1.0, int(D.priority), "Sfx", String(D.cls), int(D.cap), "", S))


## The stops that have come due.
func _flush(S: SimState, out: Array) -> void:
	if _due.is_empty():
		return
	var keep: Array = []
	for d in _due:
		if S.tick >= int(d.tick):
			out.append(d.cue)
		else:
			keep.append(d)
	_due = keep


# ---- footfall: a fighter on the ground and moving

func _steps(S: SimState, out: Array) -> void:
	var T: Dictionary = cfg.step
	for a in range(S.fighters.size()):
		var f = S.fighters[a]
		if String(f.state) != "free":
			continue
		var g: float = WorldTerrain.groundY(S, f.x)
		if f.y - g > float(T.near_ground) or absf(f.vy) > float(T.max_vy):
			_next_step.erase(a)
			continue
		var speed: float = absf(f.vx)
		if speed < float(T.min_speed):
			_next_step.erase(a)
			continue
		if S.tick < int(_next_step.get(a, -1)):
			continue
		var u: float = clampf((speed - float(T.min_speed)) / (float(T.speed_fast) - float(T.min_speed)), 0.0, 1.0)
		_next_step[a] = S.tick + int(lerpf(float(T.interval_slow), float(T.interval_fast), u))
		var sf: Dictionary = _surf(S, f.x, f.y)
		var foot: int = int(_slide_i.get(a, 0))
		_slide_i[a] = foot + 1
		var pitch: float = float(T.pitch) * (1.0 + (float(T.pitch_alt) if foot % 2 == 0 else -float(T.pitch_alt))) * float(sf.pitch)
		_emit(out, String(sf.hit), f.x, f.y, float(T.gain_db) + float(sf.gain_db) + 3.0 * u, pitch, int(T.priority), String(T.cls), int(T.cap), S)


# ---- the bed

func _pair(S: SimState) -> Vector2:
	if S.fighters.size() < 2:
		return Vector2(S.fighters[0].x, S.fighters[0].y)
	var a = S.fighters[0]
	var b = S.fighters[1]
	return Vector2(SimWrap.wrap(a.x + SimWrap.sdx(a.x, b.x) * 0.5), (a.y + b.y) * 0.5)


func _bed(S: SimState, out: Array) -> void:
	var B: Dictionary = cfg.bed
	var p: Vector2 = _pair(S)
	var here: String = biome_at(p.x)
	if _group == "":
		_start(S, here, p, out)
		_next_upd = S.tick + int(B.update_every)
		return
	if here != _biome and _bed_of(here) != _bed_of(_biome):
		if here == _cand:
			_cand_t += 1
		else:
			_cand = here
			_cand_t = 1
		if _cand_t >= int(B.hold_ticks):
			var old: String = _group
			_start(S, here, p, out)
			var stop = cues.Cue.new()
			stop.stop_group = old
			stop.fade_ms = int(B.fade_ms)
			out.append(stop)
			_next_upd = S.tick + int(B.update_every)
			return
	else:
		_cand = ""
		_cand_t = 0
		if here != _biome:
			_biome = here
	if S.tick >= _next_upd:
		_next_upd = S.tick + int(B.update_every)
		var u = _level(S, _biome, p, int(B.ramp_ms))
		if absf(u.gain_db - _sent_db) >= float(B.min_step_db):
			_sent_db = u.gain_db
			u.group = _group
			u.update = true
			out.append(u)


## The bed's level now: its biome's level, up or down with height, and ducked by the fight.
func _level(S: SimState, biome: String, p: Vector2, ramp_ms: int):
	var B: Dictionary = cfg.bed
	var R: Dictionary = cfg.biomes.get(biome, cfg.biomes[cfg.default_biome])
	var alt: float = clampf((p.y - WorldTerrain.groundY(S, p.x)) / float(B.alt_ref), 0.0, 1.0)
	var duck: float = float(cfg.intensity.duck_db) * clampf(_intensity, 0.0, 1.0)
	var c = cues.Cue.new()
	c.sound = "amb." + String(R.bed)
	c.gain_db = float(R.gain_db) + float(R.alt_db) * alt + duck
	c.pitch = 1.0
	c.x = p.x
	c.y = p.y
	c.bus = String(B.bus)
	c.priority = int(B.priority)
	c.cls = String(B.cls)
	c.cap = int(B.cap)
	c.ambient = true
	c.loop = true
	c.ramp_ms = ramp_ms
	return c


func _start(S: SimState, biome: String, p: Vector2, out: Array) -> void:
	var B: Dictionary = cfg.bed
	_flip += 1
	_group = "amb." + ("a" if _flip % 2 == 1 else "b")
	_biome = biome
	_cand = ""
	_cand_t = 0
	var c = _level(S, biome, p, 0)
	var target: float = c.gain_db
	c.gain_db = float(B.start_db)
	c.group = _group
	out.append(c)
	var u = _level(S, biome, p, int(B.fade_ms))
	u.gain_db = target
	_sent_db = target
	u.group = _group
	u.update = true
	out.append(u)
