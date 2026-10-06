class_name SkyDrive
extends RefCounted
## The dynamic sky's driver (Art's direction: docs/art/dynamic-sky.md; data/art/sky.json; a port of the reference code
## art/concepts/sky/keys.mjs). The sky keeps its four bands (top, upper, lower, horizon: skycol.gdshaderinc) and only
## their colours change:
## - by place: a lap round the planet is one day. Five keys stand round the lap (noon, golden, sunset, night, dawn);
##   each holds a little, then blends to the next in OKLab, band by band, along the path Art chose for it. The sunset
##   key is the look the game had before, and a match starts on it.
## - by time: a slow drift is added to the place.
## - by the fight's mood and the world's damage: frenzy deepens the bands, ruin takes them toward smoke, and a
##   wrecked town in view gives the horizon a low ember glow (the glow's shape is the sky shader's).
## Nothing is fast, whatever drives it. The shown place follows the wanted one through slew() (Art's slewStep), which
## moves it as far as the place budget allows; the mood drivers ease at Art's least durations; and a last limiter on
## the colours themselves holds every band to the total budget and their weighted mean to its own (limit()), so a
## driver this file did not foresee still cannot make the sky change quickly.
## One SkyDrive is shared (SimHost.sky: the drift, the mood, the towns); each pane keeps its own place (a Dictionary
## it passes to pane()), so two panes far apart show two skies.
## Presentation only: it reads the sim (the mood band, the casualties, the buildings) and writes nothing to it.

const DATA_PATH: String = "res://data/art/sky.json"
const N: int = 720                   # samples of the lap in the table
const BANDS: Array = ["horizon", "lower", "upper", "top"]             # Art's order
const UNIFORMS: Array = ["sky_horizon", "sky_lower", "sky_upper", "sky_top"]   # the shader's names, in that order
const SUNSET_STARS: float = 0.15     # the stars' level at the sunset key, where the shader's ground-level strength is 0.25 as it always was
const STAR_LOW: float = 0.25

static var _ready: bool = false
static var ok: bool = false          # the data file was read (without it the sky is the sunset, still)
static var keys: Array = []          # {id, phase, hold, stars, cols: [Color x 4 in BANDS order]}
static var start_phase: float = 0.32
static var drift_per_s: float = 0.0  # cycles a second
static var weights := PackedFloat64Array([0.18, 0.30, 0.30, 0.22])
static var place_band: float = 0.035
static var place_mean: float = 0.015
static var total_band: float = 0.05
static var total_mean: float = 0.02
static var ease_s: Dictionary = {"frenzy": 30.0, "ruin": 120.0, "glow": 50.0}
static var mood_lab: Dictionary = {}   # ember, smoke, ash, deep: OKLab
static var ember := Color.html("#d9603c")
static var _lab := PackedFloat64Array()    # N x 4 x 3: each band's OKLab along the lap
static var _lum := PackedFloat64Array()    # N x 4: each band's relative luminance
static var _stars := PackedFloat64Array()  # N
static var _key := PackedInt32Array()      # N: the key a sample stands on exactly (inside a hold), or -1

var frenzy: float = 0.0              # the eased drivers, 0 to 1
var ruin: float = 0.0
var towns: Array = []                # {x, ids: building indices, glow}: the towns and each one's eased glow
var drift: float = 0.0               # cycles drifted so far
var spawn_x: float = 0.0
var calm: bool = false               # reduced motion: the drift and the mood hold, the place blend stays
var still: bool = false              # --staticsky: the sunset, as before (for comparisons)
var snap_still: bool = false         # a tool's posed frames: with no time passing, the sky is its place's at once
var hold_phase: float = NAN          # --sky: every pane shows this place of the lap
var hold_mood: Array = []            # --skymood: [frenzy, ruin, glow], held
var _t: float = NAN
var _scan_t: float = -INF


# ------------------------------------------------------------------ colour (Art's colour.mjs)

static func _to_lin(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


static func _from_lin(v: float) -> float:
	v = clampf(v, 0.0, 1.0)
	return v * 12.92 if v <= 0.0031308 else 1.055 * pow(v, 1.0 / 2.4) - 0.055


static func _cbrt(v: float) -> float:
	return signf(v) * pow(absf(v), 1.0 / 3.0)


## A colour (sRGB) as OKLab.
static func to_lab(c: Color) -> Vector3:
	var r: float = _to_lin(c.r)
	var g: float = _to_lin(c.g)
	var b: float = _to_lin(c.b)
	var l: float = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
	var m: float = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
	var s: float = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
	return Vector3(0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s, 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s, 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


## OKLab as linear RGB, each channel held to 0 to 1.
static func lab_to_lin(v: Vector3) -> Vector3:
	var l: float = pow(v.x + 0.3963377774 * v.y + 0.2158037573 * v.z, 3.0)
	var m: float = pow(v.x - 0.1055613458 * v.y - 0.0638541728 * v.z, 3.0)
	var s: float = pow(v.x - 0.0894841775 * v.y - 1.2914855480 * v.z, 3.0)
	return Vector3(clampf(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, 0.0, 1.0), clampf(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, 0.0, 1.0), clampf(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s, 0.0, 1.0))


## Relative luminance (WCAG) of a linear RGB triple, and of a colour.
static func lum_lin(v: Vector3) -> float:
	return 0.2126 * v.x + 0.7152 * v.y + 0.0722 * v.z


static func lum_of(c: Color) -> float:
	return 0.2126 * _to_lin(c.r) + 0.7152 * _to_lin(c.g) + 0.0722 * _to_lin(c.b)


static func lin_to_color(v: Vector3) -> Color:
	return Color(_from_lin(v.x), _from_lin(v.y), _from_lin(v.z))


## One band's way from key colour A to B (OKLab): straight, or round the hue wheel one way or the other.
static func _path(A: Vector3, B: Vector3, t: float, mode: String) -> Vector3:
	if mode == "lab":
		return A.lerp(B, t)
	var c1: float = Vector2(A.y, A.z).length()
	var c2: float = Vector2(B.y, B.z).length()
	var h1: float = fposmod(rad_to_deg(atan2(A.z, A.y)), 360.0)
	var h2: float = fposmod(rad_to_deg(atan2(B.z, B.y)), 360.0)
	var d: float = h2 - h1
	if mode == "lch+":
		if d < 0.0:
			d += 360.0
	elif d > 0.0:
		d -= 360.0
	var c: float = lerpf(c1, c2, t)
	var h: float = deg_to_rad(h1 + d * t)
	return Vector3(lerpf(A.x, B.x, t), c * cos(h), c * sin(h))


# ------------------------------------------------------------------ the data and the table

static func ensure() -> void:
	if _ready:
		return
	_ready = true
	var sunset: Array = [RenderLook.col(RenderLook.SKY[3]), RenderLook.col(RenderLook.SKY[2]), RenderLook.col(RenderLook.SKY[1]), RenderLook.col(RenderLook.SKY[0])]
	keys = [{"id": "sunset", "phase": 0.32, "hold": 0.5, "stars": SUNSET_STARS, "cols": sunset}]
	var trans: Array = [{}]
	var d = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
	if d is Dictionary and d.get("keys") is Array and (d.keys as Array).size() >= 2:
		ok = true
		keys = []
		for k in d.keys:
			var cols: Array = []
			for band in BANDS:
				cols.append(Color.html(str(k.bands[band])))
			keys.append({"id": str(k.id), "phase": float(k.phase), "hold": float(k.hold), "stars": float(k.stars), "cols": cols})
		trans = d.blend.transitions
		start_phase = float(d.start.phase)
		drift_per_s = float(d.time.cycles_per_minute) / 60.0
		var rl: Dictionary = d.rate_limit
		weights = PackedFloat64Array(BANDS.map(func(b): return float(rl.weights[b])))
		place_band = float(rl.place_and_time.band)
		place_mean = float(rl.place_and_time.mean)
		total_band = float(rl.total.band)
		total_mean = float(rl.total.mean)
		for k in ease_s.keys():
			ease_s[k] = float(d.mood.min_seconds_0_to_1[k])
		ember = Color.html(str(d.mood.colours.ember))
		for k in ["ember", "smoke", "ash", "deep"]:
			mood_lab[k] = to_lab(Color.html(str(d.mood.colours[k])))
	if mood_lab.is_empty():
		for k in [["ember", "#d9603c"], ["smoke", "#2e221c"], ["ash", "#2b2724"], ["deep", "#05060f"]]:
			mood_lab[k[0]] = to_lab(Color.html(k[1]))
	_lab.resize(N * 12)
	_lum.resize(N * 4)
	_stars.resize(N)
	_key.resize(N)
	var n: int = keys.size()
	for i in range(N):
		var phase: float = float(i) / float(N)
		var labs: Array = []
		var st: float = float(keys[0].stars)
		var on: int = 0 if n == 1 else -1
		if n == 1:
			for c in keys[0].cols:
				labs.append(to_lab(c))
		for ki in range(n if n > 1 else 0):
			var a: Dictionary = keys[ki]
			var b: Dictionary = keys[(ki + 1) % n]
			var pa: float = a.phase
			var pb: float = 1.0 + float(b.phase) if ki == n - 1 else float(b.phase)
			var p: float = phase + 1.0 if (ki == n - 1 and phase < pa) else phase
			if p >= pa and p <= pb:
				var lo: float = pa + float(a.hold)
				var hi: float = pb - float(b.hold)
				var t: float = 0.0 if p <= lo else (1.0 if p >= hi else smoothstep(0.0, 1.0, (p - lo) / (hi - lo)))
				on = ki if t == 0.0 else ((ki + 1) % n if t == 1.0 else -1)
				for bi in range(4):
					labs.append(_path(to_lab(a.cols[bi]), to_lab(b.cols[bi]), t, str(trans[ki].get(BANDS[bi], "lab"))))
				st = lerpf(float(a.stars), float(b.stars), t)
				break
		for bi in range(4):
			var v: Vector3 = labs[bi]
			_lab[i * 12 + bi * 3] = v.x
			_lab[i * 12 + bi * 3 + 1] = v.y
			_lab[i * 12 + bi * 3 + 2] = v.z
			_lum[i * 4 + bi] = lum_lin(lab_to_lin(v))
		_stars[i] = st
		_key[i] = on


## The four bands' OKLab at a place of the lap (BANDS order), from the table.
static func labs_at(phase: float) -> Array:
	var f: float = fposmod(phase, 1.0) * float(N)
	var i: int = int(f) % N
	var j: int = (i + 1) % N
	var t: float = f - floor(f)
	var out: Array = []
	for bi in range(4):
		var a: int = i * 12 + bi * 3
		var b: int = j * 12 + bi * 3
		out.append(Vector3(lerpf(_lab[a], _lab[b], t), lerpf(_lab[a + 1], _lab[b + 1], t), lerpf(_lab[a + 2], _lab[b + 2], t)))
	return out


## The key a place stands on exactly (inside its hold), or -1.
static func key_at(phase: float) -> int:
	var f: float = fposmod(phase, 1.0) * float(N)
	var i: int = int(f) % N
	return _key[i] if _key[i] >= 0 and _key[i] == _key[(i + 1) % N] else -1


static func stars_at(phase: float) -> float:
	var f: float = fposmod(phase, 1.0) * float(N)
	var i: int = int(f) % N
	return lerpf(_stars[i], _stars[(i + 1) % N], f - floor(f))


## One band's luminance at a place, and the four bands' weighted mean.
static func _lum_at(phase: float, bi: int) -> float:
	var f: float = fposmod(phase, 1.0) * float(N)
	var i: int = int(f) % N
	return lerpf(_lum[i * 4 + bi], _lum[((i + 1) % N) * 4 + bi], f - floor(f))


static func mean_of(l: Array) -> float:
	return weights[0] * float(l[0]) + weights[1] * float(l[1]) + weights[2] * float(l[2]) + weights[3] * float(l[3])


static func lums_at(phase: float) -> Array:
	return [_lum_at(phase, 0), _lum_at(phase, 1), _lum_at(phase, 2), _lum_at(phase, 3)]


## How far the shown place may move toward the wanted one in dt seconds: as far as it can with no band's luminance
## changing faster than the place budget and their weighted mean no faster than its own (Art's slewStep).
static func slew(p: float, target: float, dt: float) -> float:
	var d: float = fposmod(target - p + 0.5, 1.0) - 0.5   # the short way round
	if absf(d) < 1e-9 or dt <= 0.0:
		return p
	var sgn: float = signf(d)
	var base: Array = lums_at(p)
	var base_m: float = mean_of(base)
	var lo: float = 0.0
	var hi: float = absf(d)
	if _within(base, base_m, p + sgn * hi, dt):
		return fposmod(p + sgn * hi, 1.0)
	for i in range(20):
		var mid: float = 0.5 * (lo + hi)
		if _within(base, base_m, p + sgn * mid, dt):
			lo = mid
		else:
			hi = mid
	return fposmod(p + sgn * lo, 1.0)


static func _within(base: Array, base_m: float, q: float, dt: float) -> bool:
	var l: Array = lums_at(q)
	if absf(mean_of(l) - base_m) > place_mean * dt:
		return false
	for bi in range(4):
		if absf(float(l[bi]) - float(base[bi])) > place_band * dt:
			return false
	return true


## The last limiter, on the colours themselves (linear RGB, BANDS order): how much of the step from `from` to `to`
## may be taken in dt seconds with no band's luminance moving faster than the total budget and their mean no faster
## than its own. Luminance is linear in linear RGB, so a share of the step is that share of each change.
static func limit(from: Array, to: Array, dt: float) -> float:
	var k: float = 1.0
	var dm: float = 0.0
	for bi in range(4):
		var dl: float = lum_lin(to[bi]) - lum_lin(from[bi])
		dm += weights[bi] * dl
		if absf(dl) > total_band * dt:
			k = minf(k, total_band * dt / absf(dl))
	if absf(dm) > total_mean * dt:
		k = minf(k, total_mean * dt / absf(dm))
	return k


# ------------------------------------------------------------------ the mood (Art's moodSky), in OKLab

## The bands at a place with the fight's mood and the world's damage on them (BANDS order, OKLab). f: frenzy, r: ruin.
static func mood(labs: Array, f: float, r: float) -> Array:
	var horizon: Vector3 = labs[0]
	var lower: Vector3 = labs[1]
	var upper: Vector3 = labs[2]
	var top: Vector3 = labs[3]
	var L := RenderLook
	top = top.lerp(mood_lab.deep, L.SKY_FRENZY[3] * f)
	upper = upper.lerp(top, L.SKY_FRENZY[2] * f)
	lower = lower.lerp(mood_lab.deep, L.SKY_FRENZY[1] * f)
	horizon = horizon.lerp(mood_lab.ember, L.SKY_FRENZY[0] * f)
	horizon = horizon.lerp(mood_lab.smoke, L.SKY_RUIN[0] * r)
	lower = lower.lerp(mood_lab.smoke, L.SKY_RUIN[1] * r)
	upper = upper.lerp(mood_lab.smoke, L.SKY_RUIN[2] * r)
	top = top.lerp(mood_lab.ash, L.SKY_RUIN[3] * r)
	return [horizon, lower, upper, top]


# ------------------------------------------------------------------ the shared drivers

## A new match: the sky is the start's again.
func reset(S: SimState) -> void:
	ensure()
	frenzy = 0.0
	ruin = 0.0
	drift = 0.0
	_t = NAN
	_scan_t = -INF
	var n: int = S.fighters.size()
	spawn_x = SimWrap.wrap(S.fighters[0].x + 0.5 * SimWrap.sdx(S.fighters[0].x, S.fighters[n - 1].x)) if n > 0 else 0.0
	# The towns: the buildings in runs along the ground, a new one wherever the gap is wider than SKY_TOWN_GAP.
	towns = []
	var order: Array = range(S.buildings.size())
	order.sort_custom(func(a, b): return S.buildings[a].x < S.buildings[b].x)
	var cur: Dictionary = {}
	var last_x: float = -INF
	for bi in order:
		var x: float = S.buildings[bi].x
		if cur.is_empty() or x - last_x > RenderLook.SKY_TOWN_GAP:
			cur = {"x": x, "x0": x, "ids": [], "glow": 0.0, "want": 0.0}
			towns.append(cur)
		cur.ids.append(bi)
		cur.x = 0.5 * (float(cur.x0) + x)
		last_x = x


## Once a frame, before the panes: the drift and the eased drivers at time t (seconds on the host's clock).
func advance(S: SimState, t: float) -> void:
	ensure()
	var dt: float = 0.0 if is_nan(_t) or t < _t else minf(t - _t, 0.5)
	_t = t
	if not hold_mood.is_empty():
		frenzy = float(hold_mood[0])
		ruin = float(hold_mood[1])
		for tw in towns:
			tw.glow = float(hold_mood[2])
		return
	if not ok or still or calm or dt <= 0.0:
		return
	drift += drift_per_s * dt
	var want_f: float = float(RenderLook.SKY_FRENZY_BY_BAND[clampi(int(S.mood.band), 0, 2)])
	var pop: float = maxf(float(S.world.pop0), 1.0)
	var want_r: float = clampf(0.5 * float(S.world.casualties) / pop + 0.5 * float(S.world.structuresLost) / maxf(float(S.buildings.size()), 1.0), 0.0, 1.0)
	frenzy = move_toward(frenzy, want_f, dt / float(ease_s.frenzy))
	ruin = move_toward(ruin, want_r, dt / float(ease_s.ruin))
	if t - _scan_t >= RenderLook.SKY_TOWN_SCAN_S:   # the towns' damage is read a few times a second, not every frame
		_scan_t = t
		for tw in towns:
			var hurt: int = 0
			for bi in tw.ids:
				if WorldStructures.stage(S.buildings[bi]) >= 2:
					hurt += 1
			tw.want = clampf(float(hurt) / maxf(float(tw.ids.size()), 1.0) / RenderLook.SKY_GLOW_FULL, 0.0, 1.0)
	for tw in towns:
		tw.glow = move_toward(float(tw.glow), float(tw.want), dt / float(ease_s.glow))


## The place of the lap a camera at world x wants: the start's at the spawn, a lap round the planet a day on, plus
## the drift.
func target(cam_x: float) -> float:
	if not is_nan(hold_phase):
		return fposmod(hold_phase, 1.0)
	if not ok or still:
		return start_phase
	return fposmod(start_phase + SimWrap.sdx(spawn_x, SimWrap.wrap(cam_x)) / SimConst.W + drift, 1.0)


## One pane's sky at time t for a camera at world x. st is the pane's own state (it starts empty). Returns
## {changed, cols: [Color x 4 in UNIFORMS order], star_low}; `changed` is false while nothing moved, and the pane
## then leaves its materials alone.
func pane(st: Dictionary, cam_x: float, t: float) -> Dictionary:
	ensure()
	var want: float = target(cam_x)
	var dt: float = t - float(st.get("t", NAN))
	var fresh: bool = st.is_empty() or is_nan(dt) or dt < 0.0 or dt > 0.5 or not is_nan(hold_phase) or not hold_mood.is_empty() or (dt == 0.0 and snap_still)
	if not fresh and dt == 0.0:
		return {"changed": false, "cols": st.cols, "star_low": st.star_low}
	# The sky is not worked out while its place has moved less than SKY_STEP_PHASE and nothing else has (a camera that
	# stands: only the drift moves it). The time is spent, not saved up, so a later step is still one frame's.
	if not fresh and absf(fposmod(want - float(st.p) + 0.5, 1.0) - 0.5) < RenderLook.SKY_STEP_PHASE and frenzy == float(st.f) and ruin == float(st.r) and float(st.k) >= 1.0:
		st.t = t
		return {"changed": false, "cols": st.cols, "star_low": st.star_low}
	var p: float = want if fresh else slew(float(st.p), want, dt)
	var plain: bool = frenzy == 0.0 and ruin == 0.0
	var labs: Array = labs_at(p) if plain else mood(labs_at(p), frenzy, ruin)
	var lin: Array = [lab_to_lin(labs[0]), lab_to_lin(labs[1]), lab_to_lin(labs[2]), lab_to_lin(labs[3])]
	var k: float = 1.0 if fresh else limit(st.lin, lin, dt)
	if k < 1.0:
		for bi in range(4):
			lin[bi] = (st.lin[bi] as Vector3).lerp(lin[bi], k)
	var ki: int = key_at(p) if plain and k >= 1.0 else -1
	var cols: Array = []
	for bi in range(4):
		# On a key, with nothing on it, the colours are the key's own to the bit: the sunset is the sky it always was.
		cols.append(keys[ki].cols[bi] if ki >= 0 else lin_to_color(lin[bi]))
	st.t = t
	st.p = p
	st.f = frenzy
	st.r = ruin
	st.k = k
	st.lin = lin
	st.cols = cols
	st.star_low = minf(1.0, STAR_LOW * stars_at(p) * (1.0 - RenderLook.SKY_RUIN_STARS * ruin) / SUNSET_STARS)
	return {"changed": true, "cols": cols, "star_low": st.star_low}
