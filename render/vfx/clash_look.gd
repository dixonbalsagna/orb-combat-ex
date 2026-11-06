class_name VfxClashLook
extends RefCounted
## The composition of a beam clash (docs/vfx/clash-look.md; Orb, 2026-10-30: the clash's solid white flare is to be replaced by "visually distinctive procedural shaders ... the air should look like it's rippling and
## glowing with pressure and energy, dynamic distortions and color changes and patterns should erupt out based on the composition and power behind each of the beams of each fighter"). This file turns a fighter, his
## form and the state he is in into one side's look, from DATA (data/vfx/clash.json); clash_view.gd draws it with the shaders (shaders/clash_core.gdshaderinc).
##
## One side is composed, in this order, each step overriding the last:
##   1. his lane colour (Art's: VfxAura.lane_color of his aura, so a colour-vision preset follows) and his beam flavour (energy.json: the second tint's hue shift, the beam's pattern, which is the clash's texture
##      unless the row names one);
##   2. the `default` row, then the row for his roster id (lower case; the Anti-hero IS the roster's RIVAL);
##   3. the row's `forms` entry for the form step he is in (Fighter.form.step, while forms are on);
##   4. each of the row's `situations` whose condition holds: {read: a dotted path off the fighter (tier, form.step, form.branch ...), is / min / max, set: any of the row's keys}.
## So a new fighter is a data row, and a special case of his (a form, a branch, a tier) is a `situations` entry: no code. Everything here reads sim state and writes none; it draws no random number.

const DEFAULTS: Dictionary = {
	"enabled": true,
	"frame": {
		"radius": 165.0, "radius_per_power": 130.0, "radius_max": 360.0, "ring_n": 3.6, "ring_n_per_power": 1.6, "ring_hz": 0.9, "ring_hz_calm": 0.55, "front_hz": 0.7, "distort": 0.07, "distort_calm": 0.035,
		"lens": 0.3, "keep_r": 105.0, "keep_y": 55.0, "glow": 1.0, "glow_cap": 0.92, "lighten": 0.1, "z_off": -3.0, "strip_k": 0.7, "core_r": 0.14, "core_per_knot": 0.7, "lean": 0.55, "ease_s": 0.3, "burst_ticks": 14.0, "burst_s": 0.9, "rise_s": 0.4, "fall_s": 0.5,
		"burst_gap": 45.0, "burst_gap_calm": 60.0, "burst_amp": 0.7, "calm_strength": 0.82, "calm_rise_s": 0.3, "spikes": 6.0, "spikes_per_power": 4.0,
	},
	"power": {"tier": 0.22, "step": 0.1, "max": 1.4},
	"fronts": {"wall": 0, "lances": 1, "wire": 2, "sputter": 3, "plain": 4},
	"textures": {"none": 0, "boil": 1, "facets": 2},
	"fighters": {"default": {"front": "wall", "ring_k": 1.0, "spike_k": 1.0, "scale": 1.0}},
}

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/clash.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func _group(name: String):
	warm()
	var g = _data.get(name)
	return g if g != null else DEFAULTS[name]


## The one switch: off, BeamView draws the old flare. On by default.
static func on() -> bool:
	warm()
	return bool(_data.get("enabled", DEFAULTS["enabled"]))


static func fp(key: String) -> float:
	var g = _group("frame")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS["frame"][key])


## The press's numbers (data/vfx/clash.json `press`).
static func pp(key: String) -> float:
	var g = _data.get("press")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(PRESS_DEFAULTS[key])


const PRESS_DEFAULTS: Dictionary = {"flare_k": 1.1, "sheet_k": 0.8, "eddy_k": 0.5, "eddy_v": 100.0, "eddy_wl": 140.0, "reach": 320.0, "hue": 0.8, "surge_k": 0.35, "calm_k": 0.5}


static func power_p(key: String) -> float:
	var g = _group("power")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS["power"][key])


## A fighter's roster key: his id, lower case (`protagonist`, `rival`, `reference`); `default` has its own row.
static func key_of(f) -> String:
	if f == null:
		return "default"
	var raw = f.get("id")
	var id: String = String(raw).to_lower().replace("-", "_").replace(" ", "_") if raw != null else ""
	var rows = _group("fighters")
	return id if (id != "" and rows is Dictionary and rows.has(id)) else "default"


## A dotted path read off a fighter (or a dictionary): `tier`, `form.step`, `form.branch`. Null when any step is missing, so a condition on something a fighter does not have is simply false.
static func read_path(f, path: String):
	var cur = f
	for seg in path.split("."):
		if cur == null:
			return null
		if cur is Dictionary:
			cur = cur.get(seg)
		elif cur is Object:
			cur = cur.get(seg)
		else:
			return null
	return cur


static func _holds(f, cond: Dictionary) -> bool:
	var v = read_path(f, String(cond.get("read", "")))
	if v == null:
		return false
	if cond.has("is"):
		var want = cond["is"]
		if (v is float or v is int) and (want is float or want is int):
			if not is_equal_approx(float(v), float(want)):
				return false
		elif String(v) != String(want):
			return false
	if cond.has("min") and not (float(v) >= float(cond["min"])):
		return false
	if cond.has("max") and not (float(v) <= float(cond["max"])):
		return false
	return true


## The row that composes for fighter f now: default, his own, the form's, then each situation that holds. A plain Dictionary of the row's keys (front, texture, lane, accent, hue_shift, ring_k, spike_k, scale).
static func row(f) -> Dictionary:
	var rows = _group("fighters")
	var out: Dictionary = {}
	if rows is Dictionary and rows.has("default"):
		out.merge(rows["default"], true)
	else:
		out.merge(DEFAULTS["fighters"]["default"], true)
	var key: String = key_of(f)
	var mine: Dictionary = {}
	if key != "default" and rows is Dictionary and rows.get(key) is Dictionary:
		mine = rows[key]
		for k in mine:
			if k != "forms" and k != "situations":
				out[k] = mine[k]
	var form = f.get("form") if f != null else null
	if form != null and mine.get("forms") is Dictionary:
		var step_row = mine["forms"].get(str(int(form.step)))
		if step_row is Dictionary:
			out.merge(step_row, true)
	if mine.get("situations") is Array:
		for sit in mine["situations"]:
			if sit is Dictionary and sit.get("set") is Dictionary and _holds(f, sit):
				out.merge(sit["set"], true)
	return out


static func _id_of(map_name: String, label: String, fallback: int) -> int:
	var m = _group(map_name)
	if m is Dictionary and m.has(label):
		return int(m[label])
	return fallback


## A fighter's power for the clash: his tier and, with forms on, the step he has taken. 0 to `power.max`.
static func power_of(f) -> float:
	if f == null:
		return 0.0
	var form = f.get("form")
	var steps: float = float(form.step) if form != null else 0.0
	return clampf(float(f.tier) * power_p("tier") + steps * power_p("step"), 0.0, power_p("max"))


## The pair's mix colour, where the two sides meet: the two lane colours averaged in hue by the short way round (a pair of opposite hues would otherwise average to grey), saturation and value averaged.
static func mix_tint(a: Color, b: Color) -> Color:
	var dh: float = b.h - a.h
	if dh > 0.5:
		dh -= 1.0
	elif dh < -0.5:
		dh += 1.0
	var h: float = fposmod(a.h + dh * 0.5, 1.0)
	var c: Color = Color.from_hsv(h, clampf((a.s + b.s) * 0.5, 0.0, 1.0), clampf((a.v + b.v) * 0.5, 0.0, 1.0))
	c.a = 1.0
	return c


## One side's composed look. `hex` is the fighter's aura key (his lane colour); the colour-blind preset follows through VfxAura.lane_color. Keys: lane, tint_a, tint_b, accent (Colors), front, texture (the shader's ids),
## scale, ring_k, spike_k, power, key (the roster row used), names (front and texture as the row says them, for the debug feed).
static func side(f, hex: String) -> Dictionary:
	var rw: Dictionary = row(f)
	var lane: Color = Color(String(rw["lane"])) if rw.has("lane") else VfxAura.lane_color(hex)
	var tt: Array = VfxBeamLook.tints(f, lane, 1)
	var a: Color = tt[0]
	var b: Color = tt[1]
	if rw.has("hue_shift"):
		b = VfxBeamLook.shifted(a, float(rw["hue_shift"]))
	var acc: Color = Color(String(rw["accent"])) if rw.has("accent") else b.lightened(0.28)
	acc.a = 1.0
	var fl: Dictionary = VfxBeamLook.flavour(f)
	var tex_name: String = String(rw["texture"]) if rw.has("texture") else ("boil" if float(fl["pat"]) > 0.5 and float(fl["pat"]) < 1.5 else ("facets" if float(fl["pat"]) > 1.5 else "none"))
	var front_name: String = String(rw.get("front", "wall"))
	return {
		"lane": lane, "tint_a": a, "tint_b": b, "accent": acc,
		"front": _id_of("fronts", front_name, 0), "texture": _id_of("textures", tex_name, 0),
		"scale": float(rw.get("scale", 1.0)), "ring_k": float(rw.get("ring_k", 1.0)), "spike_k": float(rw.get("spike_k", 1.0)),
		"power": power_of(f), "key": key_of(f), "names": [front_name, tex_name],
	}


## The disc's radius in world units from the pair's power: the more power behind the beams, the bigger the air that moves.
static func radius_of(pa: float, pd: float) -> float:
	return minf(fp("radius") + fp("radius_per_power") * 0.5 * (pa + pd), fp("radius_max"))


## A surge's eruptions, planned from the struggle model's waves. A wave that is a surge (amp at least `amp_min`: beats are small and stray pinches negative) arrives at the point `wave_ticks` after it is born; an eruption is
## kept for `burst_s`, and one starts no sooner than `gap` ticks after the last. `seen` maps a wave's born tick to its arrival time so a wave is planned once: {born: arrival_T}. Returns the new list of {t0 (sim seconds),
## amp, side}, the ones still running at `now` (sim seconds). Pure: the same waves and times give the same list.
static func plan_bursts(waves: Array, clock: float, now: float, wave_ticks: float, dt: float, bursts: Array, seen: Dictionary, gap: float, life: float, amp_min: float) -> Array:
	var out: Array = []
	for bu in bursts:
		if now - float(bu["t0"]) <= life:
			out.append(bu)
	for w in waves:
		if float(w.amp) < amp_min:
			continue
		var key: float = float(w.born) * 2.0 + float(w.side)
		if seen.has(key):
			continue
		var arrive: float = now + maxf(wave_ticks - (clock - float(w.born)), 0.0) * dt
		seen[key] = arrive
		var last: float = -1.0e9
		for bu in out:
			last = maxf(last, float(bu["t0"]))
		if arrive - last < gap * dt:
			continue
		out.append({"t0": arrive, "amp": clampf(float(w.amp), 0.0, 1.6), "side": int(w.side)})
	return out
