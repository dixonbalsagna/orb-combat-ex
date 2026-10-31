class_name VfxWater
extends RefCounted
## Dramatic water (docs/vfx/water-plan.md): the spray of a skip, the crown and column of a plunge, a beam raking the sea,
## and the wake behind a fast low flight. It turns the sim's `splash`, `skim` and `beamSplash` events and the fighters'
## own state into debris bits (render/vfx/debris.gd: cel spray streaks and foam puffs in Art's ocean colours) and scales
## them with speed and the power tier. The numbers are data (data/vfx/water.json; missing keys fall back to the defaults
## below). Presentation only: it reads the sim and never writes it, and draws from the debris pool's own streams.

const DEFAULTS: Dictionary = {
	"scale": {"ref_speed": 4000.0, "min": 0.45, "max": 3.0, "tier_gain": 0.25},
	"skim": {"streaks_base": 14, "streaks_per_scale": 10, "elev_min_deg": 15.0, "elev_max_deg": 55.0, "len_min": 40.0, "len_max": 110.0, "speed_frac_min": 0.12, "speed_frac_max": 0.38, "speed_cap": 2600.0, "life_min": 0.6, "life_max": 1.2, "tail_puffs_base": 4, "tail_puffs_per_scale": 3, "skip_decay": 0.85},
	"plunge": {"height_per_speed": 0.25, "height_min": 300.0, "height_max": 3500.0, "streaks_base": 22, "streaks_per_scale": 18, "cone_deg": 26.0, "column_puffs_base": 6, "column_puffs_per_scale": 5, "rebound_delay": 0.28, "rebound_share": 0.45},
	"beam": {"throw_chance": 0.3, "throws_per_tick": 4, "streaks_per_throw": 4, "power_gain": 0.35, "puff_every": 2, "forward_deg_min": 20.0, "forward_deg_max": 60.0},
	"wake": {"min_speed": 2200.0, "max_height": 160.0, "streaks_per_tick": 2, "puff_every": 4},
	"caps": {"spray_alive": 260, "per_tick": 60},
	"fill": {"lip_every": 2, "lip_streaks": 2, "lip_foam_min": 50.0, "lip_foam_max": 110.0, "start_streaks": 4, "rim_streaks": 8, "rim_foams": 3, "rim_reach": 70.0, "bore_streaks": 12, "bore_foams": 4, "seep_foams": 4, "max_fronts": 4},
	"wave": {"streaks_per_pulse": 3, "foam_per_pulse": 1, "rim_streaks": 10, "rim_foams": 3, "max_waves": 3},
	"slap": {"speed_min": 900.0, "throw_speed": 2800.0, "height_per_speed": 0.12, "height_min": 140.0, "height_max": 900.0, "streaks_base": 14, "streaks_per_scale": 12, "fan_min_deg": 8.0, "fan_max_deg": 50.0, "centre_streaks": 5, "centre_share": 0.3, "foam_base": 8, "foam_per_scale": 6, "run_min": 140.0, "run_max": 560.0, "ring_r": 50.0, "ring_rate": 800.0, "ring_life": 0.5, "throw_gain": 1.3, "entrance_gain": 0.7, "entrance_life": 0.75},
	"douse": {"puffs_max": 5, "per_columns": 4, "size_min": 36.0, "size_max": 64.0, "grow": 1.8, "life_min": 1.3, "life_max": 2.0, "rise_min": 40.0, "rise_max": 90.0},
}

static var _data: Dictionary = {}
static var _loaded: bool = false

class Front:
	var id: int = 0
	var x0: float = 0.0
	var y: float = 0.0
	var r: float = 0.0
	var spd: float = 0.0
	var age: float = 0.0           # seconds since the cue
	var dur: float = 1.0
	var z: float = 0.0
	var rims: Dictionary = {}      # crater rims the front has crossed (rounded x)
	var ends: Array = [0.0, 0.0]   # the front's two ends now (wrapped x)
	var bored: Dictionary = {}     # fronts it has met


class Wave:
	var x: float = 0.0
	var y: float = 0.0
	var r: float = 600.0
	var n: int = 6
	var dur: float = 1.0
	var age: float = 0.0
	var z: float = 0.0
	var done: int = 0              # pulses sent
	var rims: Dictionary = {}


var fronts: Array = []           # the fills that are running (water_fill with a front speed)
var waves: Array = []            # the ring waves that are running (water_wave)
var fills: int = 0               # counters for the tests
var seeps: int = 0
var lips: int = 0
var rim_bursts: int = 0
var bores: int = 0
var wave_events: int = 0
var pulses: int = 0
var douses: int = 0
var steam_puffs: int = 0
var _front_id: int = 0
var debris: VfxDebris
var skims: int = 0               # counters for the tests
var plunges: int = 0
var slaps: int = 0               # a body met the sheet with the floor on (slap)
var _spd: Array = []             # each fighter's speed at the end of the last tick: a splash arrives after the sim has already slowed the body
var beam_hits: int = 0
var wakes: int = 0
var _tick_n: int = 0             # spray spawned this tick (budget caps.per_tick)
var _wake_t: int = 0
var _beam_tick: int = -1
var _beam_n: int = 0
var _beam_throws: int = 0


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/water.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


## One number: group.key from the data file, else the default.
static func p(group: String, key: String) -> float:
	warm()
	var g = _data.get(group)
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS[group][key])


func reset() -> void:
	skims = 0
	plunges = 0
	slaps = 0
	_spd.clear()
	beam_hits = 0
	wakes = 0
	_tick_n = 0
	_wake_t = 0
	_beam_tick = -1
	_beam_n = 0
	_beam_throws = 0
	fronts.clear()
	waves.clear()
	fills = 0
	seeps = 0
	lips = 0
	rim_bursts = 0
	bores = 0
	wave_events = 0
	pulses = 0
	douses = 0
	steam_puffs = 0
	_front_id = 0


## Called once per tick before the events: the spawn budget starts again.
func begin_tick() -> void:
	_tick_n = 0


## Size of an effect from speed and the power tier: 1 at the reference speed and tier 1.
static func scale_of(speed: float, tier: float) -> float:
	var s: float = speed / p("scale", "ref_speed")
	s *= 1.0 + p("scale", "tier_gain") * maxf(tier - 1.0, 0.0)
	return clampf(s, p("scale", "min"), p("scale", "max"))


func _q() -> float:
	return VfxLook.QUALITY_SHARDS[clampi(debris.quality, 0, 2)] * (0.5 if debris.reduced else 1.0)


func _room() -> bool:
	return _tick_n < int(p("caps", "per_tick"))


## The fighter closest to x (by the shortest arc), the one a splash at x belongs to.
static func nearest_fighter(S: SimState, x: float):
	var best = null
	var bd: float = 1e30
	for f in S.fighters:
		var d: float = absf(SimWrap.sdx(f.x, x))
		if d < bd:
			bd = d
			best = f
	return best


# ------------------------------------------------------------------------------------------------------------ skip

## The sim's skim event: a fighter skipped off the water at (x, y = the surface) at raw speed spd, the n-th skip. A fan of
## spray streaks thrown up and forward along the travel, and a tail of foam thrown up and back; later skips are smaller.
func skim(S: SimState, x: float, y: float, spd: float, n: int) -> void:
	skims += 1
	var f = nearest_fighter(S, x)
	var dir: float = 1.0 if f == null or f.vx >= 0.0 else -1.0
	var tier: float = f.tier if f != null else 1.0
	var s: float = scale_of(spd, tier) * pow(p("skim", "skip_decay"), maxf(float(n) - 1.0, 0.0))
	var q: float = _q()
	var cnt: int = int(round((p("skim", "streaks_base") + p("skim", "streaks_per_scale") * s) * q))
	var cap: float = p("skim", "speed_cap")
	for k in range(cnt):
		var elev: float = deg_to_rad(lerpf(p("skim", "elev_min_deg"), p("skim", "elev_max_deg"), debris._rd.next()))
		var sp: float = minf(spd * lerpf(p("skim", "speed_frac_min"), p("skim", "speed_frac_max"), debris._rd.next()), cap) * (0.6 + 0.4 * s)
		var life: float = lerpf(p("skim", "life_min"), p("skim", "life_max"), debris._rd.next())
		var len: float = lerpf(p("skim", "len_min"), p("skim", "len_max"), debris._rd.next()) * (0.6 + 0.5 * s)
		_streak(x + dir * debris._rd.range_(0.0, 160.0) * s, y, dir * cos(elev) * sp, sin(elev) * sp * 1.3, len, life, y)
	# The tail: foam thrown up and back where the fighter left the water.
	var np: int = int(round((p("skim", "tail_puffs_base") + p("skim", "tail_puffs_per_scale") * s) * q))
	for k in range(np):
		var sz: float = debris._rd.range_(80.0, 240.0) * (0.5 + 0.5 * s)
		_foam(x - dir * debris._rd.range_(0.0, 220.0) * s, y + 10.0, -dir * debris._rd.range_(100.0, 500.0) * s, debris._rd.range_(300.0, 900.0) * s, sz, debris._rd.range_(0.9, 1.6))
	debris._ring(x, y + 20.0, RenderLook.Z_BEAMS + 6.0, 40.0 * s, 700.0 * s, 0.3)


# ---------------------------------------------------------------------------------------------------------- plunge

## A fighter went into the water or a body struck the sea (a `splash` event of 10 or more droplets: 12 a plunge, 14 a
## ground impact at sea). A crown of spray in a narrow cone and a column of foam rising from the impact, then a smaller jet
## when the cavity closes. Smaller splashes (a skip's 8, a beam's 3) are not drawn here.
func plunge(S: SimState, x: float, y: float, n: int) -> void:
	plunges += 1
	var f = nearest_fighter(S, x)
	var speed: float = 2000.0
	var tier: float = 1.0
	if f != null:
		speed = maxf(Vector2(f.vx, f.vy).length(), 600.0)
		tier = f.tier
	var s: float = scale_of(speed, tier)
	var q: float = _q()
	var H: float = clampf(speed * p("plunge", "height_per_speed") * (0.7 + 0.3 * s), p("plunge", "height_min"), p("plunge", "height_max"))
	_column(x, y, s, H, q, 1.0)
	var j := VfxDebris.Job.new()
	j.at = debris.now + p("plunge", "rebound_delay")
	j.kind = "plunge2"
	j.a = {"x": x, "y": y, "s": s, "H": H * p("plunge", "rebound_share")}
	j.zs = debris.z_shift
	debris.jobs.append(j)
	debris._ring(x, y + 30.0, RenderLook.Z_BEAMS + 6.0, 60.0 * s, 950.0 * s, 0.4)
	debris._ring(x, y + 30.0, RenderLook.Z_BEAMS + 7.0, 30.0 * s, 650.0 * s, 0.55)


func rebound(a: Dictionary) -> void:
	_column(a.x, a.y, a.s * 0.7, a.H, _q(), 0.7)


# ------------------------------------------------------------------------------------------------------------ the sheet

## With World's floor on (Game Design rulings 2026-10-30) a body that meets the sea's or a lake's surface does not go under: he lands on the sheet, or is slammed flat on it. A low wide splash, not a plunge's tall column: spray
## thrown out both ways in a flat fan, a short jet where he hit, foam running out along the surface and two flat rings spreading on it. Cut from the speed he had at the end of the last tick (the sim has already slowed him
## when the splash event arrives) or, for the grapple's down throw (thrown: the thrower's index), from `slap.throw_speed` and bigger by `throw_gain`. The same streak and foam pools and caps as the plunge.
## An entrance landing on the sheet (drop: the height he fell from, no crater dug; rulings 2026-10-30 row 13) is cut from the speed that fall gives him and is smaller by `entrance_gain` and shorter by `entrance_life`, so
## the spray and foam have cleared by the staredown as the landing's dust does.
func slap(S: SimState, x: float, y: float, thrown: int = -1, drop: float = 0.0) -> void:
	slaps += 1
	var f = nearest_fighter(S, x)
	var tier: float = f.tier if f != null else 1.0
	var speed: float = p("slap", "speed_min")
	var gain: float = 1.0
	var lk: float = 1.0
	if thrown >= 0:
		speed = p("slap", "throw_speed")
		gain = p("slap", "throw_gain")
		if thrown < S.fighters.size():
			tier = S.fighters[thrown].tier
	elif drop > 0.0:
		speed = clampf(sqrt(2.0 * 1200.0 * drop), speed, p("slap", "throw_speed"))
		gain = p("slap", "entrance_gain")
		lk = p("slap", "entrance_life")
	elif f != null:
		var i: int = S.fighters.find(f)
		if i >= 0 and i < _spd.size():
			speed = maxf(float(_spd[i]), speed)
	var s: float = scale_of(speed, tier)
	var q: float = _q()
	var H: float = clampf(speed * p("slap", "height_per_speed") * (0.7 + 0.3 * s), p("slap", "height_min"), p("slap", "height_max"))
	var vmax: float = sqrt(2.0 * 1200.0 * H)
	# The flat fan, one side then the other.
	var cnt: int = int(round((p("slap", "streaks_base") + p("slap", "streaks_per_scale") * s) * q * gain))
	var lo: float = deg_to_rad(p("slap", "fan_min_deg"))
	var hi: float = deg_to_rad(p("slap", "fan_max_deg"))
	for k in range(cnt):
		var side: float = 1.0 if k % 2 == 0 else -1.0
		var a: float = debris._rd.range_(lo, hi)
		var sp: float = vmax * debris._rd.range_(0.55, 1.0)
		var off: float = debris._rd.range_(0.0, 90.0) * s
		var len: float = debris._rd.range_(50.0, 120.0) * (0.6 + 0.5 * s)
		var life: float = debris._rd.range_(0.8, 1.5) * lk
		_streak(x + side * off, y, side * cos(a) * sp * 1.4, sin(a) * sp, len, life, y)
	# The short jet where he hit.
	var jn: int = int(round(float(p("slap", "centre_streaks")) * q * gain))
	for k in range(jn):
		var a2: float = deg_to_rad(90.0) + debris._rd.range_(-0.2, 0.2)
		var sp2: float = vmax * p("slap", "centre_share") * debris._rd.range_(0.6, 1.0) * 1.6
		var off2: float = debris._rd.range_(-40.0, 40.0) * s
		var len2: float = debris._rd.range_(60.0, 130.0) * (0.6 + 0.5 * s)
		var life2: float = debris._rd.range_(0.9, 1.5) * lk
		_streak(x + off2, y, cos(a2) * sp2, sin(a2) * sp2, len2, life2, y)
	# Foam running out along the surface, both ways.
	var np: int = int(round((p("slap", "foam_base") + p("slap", "foam_per_scale") * s) * q * gain))
	for k in range(np):
		var side2: float = 1.0 if k % 2 == 0 else -1.0
		var run: float = debris._rd.range_(p("slap", "run_min"), p("slap", "run_max")) * s
		var rise: float = debris._rd.range_(30.0, 160.0)
		var sz: float = debris._rd.range_(120.0, 300.0) * (0.5 + 0.5 * s)
		var fl: float = debris._rd.range_(1.0, 1.9) * lk
		var ox: float = debris._rd.range_(0.0, 70.0) * s
		_foam(x + side2 * ox, y + 12.0, side2 * run, rise, sz, fl)
	# Two flat rings spreading on the sheet (one under reduced motion).
	var r0: float = p("slap", "ring_r") * s
	var rate: float = p("slap", "ring_rate") * s
	var rl: float = p("slap", "ring_life") * lk
	debris._ring(x, y + 6.0, RenderLook.Z_BEAMS + 6.0, r0, rate, rl, true)
	if not debris.reduced:
		debris._ring(x, y + 6.0, RenderLook.Z_BEAMS + 7.0, r0 * 0.5, rate * 0.65, rl * 1.3, true)


## The grapple's down throw: a `cue` grapple_end "thrown_down" in this tick's events whose target (the body thrown) stands at x. The thrower's index, else -1.
static func thrown_at(S: SimState, events: Array, x: float) -> int:
	for e in events:
		if e.type == "cue" and String(e.kind) == "grapple_end" and String(e.text) == "thrown_down":
			var ti: int = int(float(e.target)) if e.get("target") != null else -1
			if ti >= 0 and ti < S.fighters.size() and absf(SimWrap.sdx(S.fighters[ti].x, x)) < 300.0:
				return int(float(e.actor))
	return -1


## A column of spray streaks in a cone and foam puffs rising to height H.
func _column(x: float, y: float, s: float, H: float, q: float, share: float) -> void:
	var cnt: int = int(round((p("plunge", "streaks_base") + p("plunge", "streaks_per_scale") * s) * q * share))
	var cone: float = deg_to_rad(p("plunge", "cone_deg"))
	var vmax: float = sqrt(2.0 * 1200.0 * H)
	for k in range(cnt):
		var a: float = deg_to_rad(90.0) + debris._rd.range_(-cone, cone)
		var sp: float = vmax * debris._rd.range_(0.45, 1.0)
		_streak(x + debris._rd.range_(-60.0, 60.0) * s, y, cos(a) * sp, sin(a) * sp, debris._rd.range_(50.0, 130.0) * (0.6 + 0.5 * s), debris._rd.range_(0.9, 1.7), y)
	var np: int = int(round((p("plunge", "column_puffs_base") + p("plunge", "column_puffs_per_scale") * s) * q * share))
	for k in range(np):
		var fr: float = (float(k) + debris._rd.next()) / float(maxi(np, 1))
		_foam(x + debris._rd.range_(-80.0, 80.0) * s, y + 20.0, debris._rd.range_(-160.0, 160.0), (0.35 + 0.65 * fr) * vmax * 0.5, debris._rd.range_(120.0, 320.0) * (0.5 + 0.5 * s), debris._rd.range_(1.0, 2.0))


# ------------------------------------------------------------------------------------------------------------ beam

## A beam sample low over the sea (beamSplash: x). One burst per beam per tick however many samples it has (a beam has up to
## a dozen), thrown forward along its direction and scaled by its power. dir: +1 or -1 along x; power: the beam's pw.
func beam(S: SimState, x: float, power: float, dir: float, tick: int) -> void:
	if tick != _beam_tick:
		_beam_tick = tick
		_beam_n = 0
	# A beam samples tens of times a tick; only a share of the samples throws, and a tick throws at most a few times, so a
	# long beam fills the spray with fresh streaks along its length instead of exhausting the pool in the first tenth of a second.
	beam_hits += 1
	if debris._rd.next() >= p("beam", "throw_chance") or _beam_n >= int(p("beam", "throws_per_tick")):
		return
	_beam_n += 1
	var every: int = maxi(int(p("beam", "puff_every")), 1)
	var q: float = _q()
	var s: float = clampf(0.6 + p("beam", "power_gain") * power, 0.6, 2.6)
	var sea: float = WorldWater.surfaceAt(S, x)
	if sea == WorldWater.DRY:
		sea = 0.0
	for k in range(int(round(p("beam", "streaks_per_throw") * q + 0.5))):
		var elev: float = deg_to_rad(lerpf(p("beam", "forward_deg_min"), p("beam", "forward_deg_max"), debris._rd.next()))
		var sp: float = debris._rd.range_(700.0, 2000.0) * s
		_streak(x + debris._rd.range_(-80.0, 80.0), sea, dir * cos(elev) * sp * 0.6, sin(elev) * sp, debris._rd.range_(70.0, 170.0) * (0.6 + 0.4 * s), debris._rd.range_(0.7, 1.4), sea)
	_beam_throws += 1
	if _beam_throws % every == 0:
		_foam(x, sea + 15.0, dir * debris._rd.range_(80.0, 400.0), debris._rd.range_(300.0, 800.0) * s, debris._rd.range_(60.0, 150.0) * s, debris._rd.range_(0.9, 1.5))


# ------------------------------------------------------------------------------------------------------------ wake

## Once a tick: a fast fighter low over water leaves a wake, two spray streaks thrown back and up, and a foam puff now and
## then. Scaled by speed. Free flight and launches alike.
func wake(S: SimState) -> void:
	_wake_t += 1
	_spd.resize(S.fighters.size())
	for i in range(S.fighters.size()):
		var fi = S.fighters[i]
		_spd[i] = Vector2(fi.vx, fi.vy).length()
	for f in S.fighters:
		if f.hidden:
			continue
		var speed: float = Vector2(f.vx, f.vy).length()
		if speed < p("wake", "min_speed") or absf(f.vx) < 0.5 * speed:
			continue
		var surf: float = WorldWater.surfaceAt(S, f.x)
		if surf == WorldWater.DRY or f.y - surf > p("wake", "max_height") or f.y < surf - 40.0:
			continue
		wakes += 1
		var back: float = -1.0 if f.vx > 0.0 else 1.0
		var s: float = scale_of(speed, f.tier)
		var q: float = _q()
		for k in range(int(p("wake", "streaks_per_tick"))):
			var kp: float = debris._rd.next()
			var sp: float = debris._rd.range_(300.0, 900.0) * (0.6 + 0.4 * s)
			var el: float = deg_to_rad(debris._rd.range_(25.0, 70.0))
			if kp < q:
				_streak(f.x, surf, back * cos(el) * sp, sin(el) * sp, debris._rd.range_(50.0, 110.0) * (0.6 + 0.4 * s), debris._rd.range_(0.5, 0.9), surf)
		if _wake_t % maxi(int(p("wake", "puff_every")), 1) == 0:
			var kp2: float = debris._rd.next()
			if kp2 < q:
				_foam(f.x, surf + 10.0, back * debris._rd.range_(100.0, 400.0), debris._rd.range_(200.0, 600.0), debris._rd.range_(90.0, 200.0) * (0.5 + 0.5 * s), debris._rd.range_(0.8, 1.3))


# ------------------------------------------------------------------------------------------------------------ water v2: fills, waves, douse

## The sim's `water_fill` (World's water v2: a hole the fight dug fills with water from the sea, a lake or the water table): x the front's start, y the target surface, r the half extent, spd the front's
## speed in units a second (0: a table seep, all at once), dur the seconds it runs. The fronts are drawn as they run (`step_fills`): a foam lip and spray at each end of the filling water, a burst where it
## pours over a crater's rim, a bore splash where two fronts meet. A seep is a few bubbles of foam along the window. Faceted spray and foam in Art's water colours: no haze, no blur.
func on_fill(S: SimState, x: float, y: float, r: float, spd: float, dur: float, z: float = 0.0) -> void:
	fills += 1
	var q: float = _q()
	var rd: SimRng = debris._rd
	if spd <= 0.0:
		seeps += 1
		var n: int = int(round(p("fill", "seep_foams") * q))
		for i in range(maxi(n, 1)):
			var px: float = SimWrap.wrap(x + rd.range_(-r, r))
			_foam(px, WorldTerrain.groundY(S, px) + 8.0, rd.range_(-20.0, 20.0), rd.range_(40.0, 120.0), rd.range_(40.0, 80.0), rd.range_(0.9, 1.4))
		return
	while fronts.size() >= int(p("fill", "max_fronts")):
		fronts.pop_front()
	var f := Front.new()
	_front_id += 1
	f.id = _front_id
	f.x0 = x
	f.y = y
	f.r = maxf(r, 1.0)
	f.spd = spd
	f.dur = maxf(dur, 0.1)
	f.z = z
	f.ends = [x, x]
	fronts.append(f)
	var gy: float = WorldTerrain.groundY(S, x) + 6.0
	for i in range(int(round(p("fill", "start_streaks") * q))):
		_streak(x, gy, rd.range_(-120.0, 120.0), rd.range_(260.0, 560.0), rd.range_(30.0, 70.0), rd.range_(0.5, 1.0), gy)


## Once per unfrozen tick: move the running fronts, throw their lips, find the rims they cross and the fronts that meet.
func step_fills(S: SimState) -> void:
	var dt: float = SimConst.DT
	var every: int = maxi(int(p("fill", "lip_every")), 1)
	var i: int = 0
	while i < fronts.size():
		var f: Front = fronts[i]
		f.age += dt
		var ext: float = minf(f.spd * f.age, f.r)
		var tick_i: int = int(round(f.age / dt))
		for side in [-1.0, 1.0]:
			var xf: float = SimWrap.wrap(f.x0 + side * ext)
			f.ends[0 if side < 0.0 else 1] = xf
			if ext < f.r and tick_i % every == 0:
				_lip(S, xf, side)
			_rims(S, f, xf, side)
		_bores(S, f)
		if f.age >= f.dur or ext >= f.r:
			fronts.remove_at(i)
		else:
			i += 1
	_step_waves(S, dt)


func _lip(S: SimState, xf: float, side: float) -> void:
	lips += 1
	var q: float = _q()
	var rd: SimRng = debris._rd
	var y: float = WorldTerrain.groundY(S, xf) + 6.0
	for k in range(int(p("fill", "lip_streaks"))):
		var kp: float = rd.next()
		var vx: float = side * rd.range_(60.0, 200.0)
		var vy: float = rd.range_(220.0, 520.0)
		var ln: float = rd.range_(30.0, 70.0)
		var lf: float = rd.range_(0.5, 1.0)
		if kp < q:
			_streak(xf, y, vx, vy, ln, lf, y)
	var kp2: float = rd.next()
	var fx: float = side * rd.range_(30.0, 120.0)
	var fy: float = rd.range_(40.0, 120.0)
	var fs: float = rd.range_(p("fill", "lip_foam_min"), p("fill", "lip_foam_max"))
	var fl: float = rd.range_(0.8, 1.4)
	if kp2 < q:
		_foam(xf, y + 6.0, fx, fy, fs, fl)


## Where a front crosses the rim of a crater: the water pours over it, a burst of spray and foam, once a rim.
func _rims(S: SimState, f: Front, xf: float, side: float) -> void:
	var reach: float = p("fill", "rim_reach")
	for c in S.craters:
		if absf(SimWrap.sdx(f.x0, c.x)) > f.r + float(c.r) + 200.0:
			continue
		for rs in [-1.0, 1.0]:
			var rx: float = SimWrap.wrap(c.x + rs * float(c.r))
			var key: int = int(round(rx))
			if f.rims.has(key) or absf(SimWrap.sdx(xf, rx)) > reach:
				continue
			f.rims[key] = true
			rim_bursts += 1
			_burst(S, rx, side, int(p("fill", "rim_streaks")), int(p("fill", "rim_foams")))


## Where two fronts meet (one from each side of a basin): a bore splash, once for the pair.
func _bores(S: SimState, f: Front) -> void:
	if f.age < 0.2:
		return
	for o in fronts:
		if o.id <= f.id or f.bored.has(o.id):
			continue
		for a in range(2):
			for b in range(2):
				if absf(SimWrap.sdx(f.ends[a], o.ends[b])) < 60.0:
					f.bored[o.id] = true
					bores += 1
					_burst(S, SimWrap.wrap(f.ends[a] + SimWrap.sdx(f.ends[a], o.ends[b]) * 0.5), 0.0, int(p("fill", "bore_streaks")), int(p("fill", "bore_foams")))
					return


## A burst of spray thrown up (and a little the way the water was going) and foam rising from the ground at x.
func _burst(S: SimState, x: float, way: float, streaks: int, foams: int) -> void:
	var q: float = _q()
	var rd: SimRng = debris._rd
	var y: float = WorldTerrain.groundY(S, x) + 8.0
	for k in range(streaks):
		var kp: float = rd.next()
		var a: float = deg_to_rad(rd.range_(55.0, 125.0))
		var sp: float = rd.range_(500.0, 1100.0)
		var ln: float = rd.range_(50.0, 120.0)
		var lf: float = rd.range_(0.7, 1.3)
		if kp < q:
			_streak(x + rd.range_(-30.0, 30.0), y, cos(a) * sp + way * 120.0, sin(a) * sp, ln, lf, y)
	for k in range(foams):
		var kp2: float = rd.next()
		var fx: float = rd.range_(-120.0, 120.0) + way * 80.0
		var fy: float = rd.range_(200.0, 520.0)
		var fs: float = rd.range_(100.0, 220.0)
		var fl: float = rd.range_(0.9, 1.5)
		if kp2 < q:
			_foam(x + rd.range_(-40.0, 40.0), y + 10.0, fx, fy, fs, fl)


## The sim's `water_wave` (a slam into standing water at least 40 deep): a ring wave of radius r over dur seconds in n steps. A pulse of spray and foam at each step at both ends of the wave, a bigger
## burst where it passes a crater's rim.
func on_wave(S: SimState, x: float, y: float, r: float, n: int, dur: float, z: float = 0.0) -> void:
	wave_events += 1
	while waves.size() >= int(p("wave", "max_waves")):
		waves.pop_front()
	var w := Wave.new()
	w.x = x
	w.y = y
	w.r = maxf(r, 1.0)
	w.n = maxi(n, 1)
	w.dur = maxf(dur, 0.1)
	w.z = z
	waves.append(w)
	debris._ring(x, y + 20.0, RenderLook.Z_BEAMS + 6.0, 40.0, 600.0, 0.4)


func _step_waves(S: SimState, dt: float) -> void:
	var i: int = 0
	while i < waves.size():
		var w: Wave = waves[i]
		w.age += dt
		var want: int = mini(int(floor(w.age / w.dur * float(w.n))) + 1, w.n)
		while w.done < want:
			w.done += 1
			pulses += 1
			var rad: float = w.r * float(w.done) / float(w.n)
			for side in [-1.0, 1.0]:
				var xp: float = SimWrap.wrap(w.x + side * rad)
				_burst(S, xp, side, int(p("wave", "streaks_per_pulse")), int(p("wave", "foam_per_pulse")))
				for c in S.craters:
					if absf(SimWrap.sdx(w.x, c.x)) > w.r + float(c.r):
						continue
					for rs in [-1.0, 1.0]:
						var rx: float = SimWrap.wrap(c.x + rs * float(c.r))
						var key: int = int(round(rx))
						if w.rims.has(key) or absf(SimWrap.sdx(xp, rx)) > w.r / float(w.n):
							continue
						w.rims[key] = true
						rim_bursts += 1
						_burst(S, rx, side, int(p("wave", "rim_streaks")), int(p("wave", "rim_foams")))
		if w.age >= w.dur:
			waves.remove_at(i)
		else:
			i += 1


## The sim's `water_douse` (a fill reached a scorched line): thin steam along the doused ground, a few small pale faceted puffs rising and spreading, never a bank: it must not hide a tell.
func on_douse(S: SimState, x: float, w: float, n: int, z: float = 0.0) -> void:
	douses += 1
	var q: float = _q()
	var cnt: int = clampi(int(ceil(float(n) / maxf(p("douse", "per_columns"), 1.0))), 1, int(p("douse", "puffs_max")))
	var rd: SimRng = debris._rd
	for k in range(cnt):
		var px: float = SimWrap.wrap(x + rd.range_(-w, w))
		var s0: float = rd.range_(p("douse", "size_min"), p("douse", "size_max"))
		var lf: float = rd.range_(p("douse", "life_min"), p("douse", "life_max"))
		var vy: float = rd.range_(p("douse", "rise_min"), p("douse", "rise_max"))
		var keep: float = rd.next()
		if keep >= q:
			continue
		steam_puffs += 1
		debris.dust_puff("ocean", px, WorldTerrain.groundY(S, px) + 8.0, 0.0, rd.range_(-14.0, 14.0), vy, s0, s0 * p("douse", "grow"), lf, 0, Color("#cdd6d8"))


# ------------------------------------------------------------------------------------------------------------ pieces

func _streak(x: float, y: float, vx: float, vy: float, len: float, life: float, kill_y: float) -> void:
	if not _room() or debris._spray_alive >= int(p("caps", "spray_alive") * (0.5 + 0.5 * _q())):   # the cap thins with quality too
		return
	_tick_n += 1
	debris.spray(x, y, vx, vy, len, life, kill_y)


func _foam(x: float, y: float, vx: float, vy: float, size: float, life: float) -> void:
	if not _room():
		return
	_tick_n += 1
	debris.foam(x, y, vx, vy, size, life)
