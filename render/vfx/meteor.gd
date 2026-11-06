class_name VfxMeteor
extends RefCounted
## The meteor trail's model (docs/vfx/meteor-trail.md; Orb 2026-10-31: "the knocked back character leaves a burning trail through the atmosphere ... the entire burnup should be determined by the altitude, the speed,
## and the rule-of-cool"). A fighter's own burn: while `burn = air(altitude) x smoothstep(burn_from, burn_full, speed) x cool` is above a floor, his path is laid down as a run of points in the ring's
## own coordinates (x on the wrap, y, z), and the view (meteor_view.gd) draws it as a ribbon that cools in the world. Steps once per unfrozen tick from the fighter's own displacement, so it works for
## flight, launches and slides alike. Presentation only: it reads the fighter, draws no random number, writes nothing of the sim, and its clock is the sum of the ticks' dt, so a replay lays the same points.
## Behind the hub's `meteor_enabled` switch (off by default: nothing here runs, nothing draws). Every number is in data/vfx/meteor.json.

const DEFAULT_FRAME: Dictionary = {
	"burn_from": 3500.0, "burn_full": 10000.0, "air_depth": 20000.0, "air_h": 0.28, "air_floor": 0.6, "sheath_floor": 0.4, "ground_h": 40.0, "rise_s": 0.3, "fall_s": 1.0, "min_burn": 0.03,
	"base_w": 60.0, "peak_w": 0.6, "w_min": 0.45, "px_ref": 1280.0, "glow_cap": 0.92, "calm_strength": 0.82, "hz": 0.9, "hz_calm": 0.55, "pattern_flow": 1.0,
	"wide_k": 0.3, "wide_from": 1.5, "wide_to": 5.0, "blade_on": 0.3, "blade_off": 0.18, "head_cap_bh": 0.6, "head_len_bh": 4.0, "bright_k": 1.6, "ramp_s": 0.0, "pan_from": 0.6, "pan_to": 3.0, "pan_k": 1.0, "life_calm_k": 0.5, "life_min_s": 2.0, "burn_s": 1.2, "cool_s": 4.0, "w_cool": 0.4, "w_smoulder": 0.25, "taper": 0.15, "end_taper_pts": 3.0, "deep_dark": 0.35, "max_pts": 1024.0, "chest_y": 36.0, "z_off": -12.0,
	"layer_k": [4.0, 2.2, 0.9], "layer_alpha": [0.30, 0.80, 0.95], "floor_px": [10.0, 5.0, 3.0], "ceil_px": [107.0, 53.0, 27.0], "wfloor_from": 12000.0, "wfloor_to": 50000.0, "wfloor_mul": [1.6, 2.4, 3.2], "wfloor_hot": 0.25, "send_only": 1.0, "min_tier": 4.0,
	"life_s": [4.0, 8.0, 12.0], "spacing": [800.0, 500.0, 300.0], "draw_pts": [32.0, 64.0, 96.0],
}
## The line's radius in units: the planet is PLANET_NC columns round (Simulation's `SimField.R`).
const R_PLANET: float = float(SimConst.PLANET_NC) * SimConst.COL / TAU
const DEFAULT_COOL: Dictionary = {"tier": [0.0, 0.0, 0.3, 0.7], "form_step": 0.1, "form_max": 0.3}
const DEFAULT_ROW: Dictionary = {"front": "wall", "width_k": 1.0, "linger_k": 1.0, "scale": 100.0, "braid": 0.0}
## The flight lines (docs/vfx/flight-lines.md; Game Design docs/design/rule-of-cool-map.md section 1): the same ribbon laid by a fighter flying near flat out, with a strength of its own.
const DEFAULT_FLIGHT: Dictionary = {"flat_out": 6100.0, "from_k": 0.8, "tier": [0.0, 0.0, 0.5, 0.8], "form_step": 0.1, "form_max": 0.2, "hold_min": 0.6, "hold_s": 0.3, "len_ground": 0.7, "len_high": 1.5, "alt_high": 8000.0, "thin_w": 0.8, "dev_bh": 1.0, "settle_s": 1.5, "pan_k": 0.6}

static var _data: Dictionary = {}
static var _loaded: bool = false
static var _prof: Dictionary = {}       # the profile in force: frame keys that win over the file's `frame` (data/vfx/meteor.json `profiles`)
static var _word: String = "?"          # the page's word, read once
static var _fword: String = "?"         # the flight lines' page word, read once


## A named set of frame values over the base (`quiet` is the base as shipped, `loud` the full-strength set): Orb judges both in the private preview. An unknown name is the base.
static func set_profile(name: String) -> void:
	warm()
	_prof = {}
	var ps = _data.get("profiles")
	if ps is Dictionary and ps.has(name) and ps[name] is Dictionary:
		_prof = ps[name].duplicate()


## The preview's page word: `?meteor=1` or `=quiet` turns the trail on with the base values, `=loud` with the loud profile. Only where UI honours its own bypass words (a local page); a public page's link is not read.
## Returns "" (and does nothing) off the web, on a page without the word, and anywhere the bypass is not allowed.
static func page_word() -> String:
	if _word != "?":
		return _word
	_word = ""
	if OS.has_feature("web") and UiHud.bypass_allowed():
		var q: String = str(JavaScriptBridge.eval("location.search", true))
		for pair in q.trim_prefix("?").split("&", false):
			var kv: PackedStringArray = pair.split("=", true, 1)
			if kv[0] == "meteor" and kv.size() > 1 and kv[1] != "" and kv[1] != "0" and kv[1] != "false":
				_word = "quiet" if kv[1] == "1" else kv[1]
	if _word != "":
		set_profile(_word)
	return _word


## The preview's page word for the flight lines: `?flight=1` (or `=quiet`, `=loud`: the meteor trail's two sets) turns them on. The same gate as the meteor word: only where UI honours its own bypass words (a local page).
static func flight_word() -> String:
	if _fword != "?":
		return _fword
	_fword = ""
	if OS.has_feature("web") and UiHud.bypass_allowed():
		var q: String = str(JavaScriptBridge.eval("location.search", true))
		for pair in q.trim_prefix("?").split("&", false):
			var kv: PackedStringArray = pair.split("=", true, 1)
			if kv[0] == "flight" and kv.size() > 1 and kv[1] != "" and kv[1] != "0" and kv[1] != "false":
				_fword = "quiet" if kv[1] == "1" else kv[1]
	if _fword != "" and page_word() == "":
		set_profile(_fword)
	return _fword


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/meteor.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func on() -> bool:
	warm()
	return bool(_data.get("enabled", true))


## A frame number: the file's, else the compiled default.
static func fp(key: String) -> float:
	warm()
	if _prof.has(key):
		return float(_prof[key])
	var fr = _data.get("frame")
	if fr is Dictionary and fr.has(key):
		return float(fr[key])
	return float(DEFAULT_FRAME[key])


## A frame list (per layer or per quality).
static func fa(key: String) -> Array:
	warm()
	if _prof.has(key) and _prof[key] is Array:
		return _prof[key]
	var fr = _data.get("frame")
	if fr is Dictionary and fr.has(key) and fr[key] is Array:
		return fr[key]
	return DEFAULT_FRAME[key]


## A flight-line number: the file's `flight` group, else the compiled default.
static func flp(key: String) -> float:
	warm()
	var g = _data.get("flight")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULT_FLIGHT[key])


static func _cool_group() -> Dictionary:
	warm()
	var c = _data.get("cool")
	return c if c is Dictionary else DEFAULT_COOL


## The shader's id for a front or texture name (the file's `fronts` and `textures`); 0 where the name is not there.
static func name_id(group: String, key: String) -> int:
	warm()
	var g = _data.get(group)
	if g is Dictionary and g.has(key):
		return int(g[key])
	return 0


## Planet coordinates (docs/world/ring-any-angle/simulation.md section 11): on a field world Simulation's `S.frame` (px, py, pz the point at x0, tx, ty, tz the heading, x0) says which great circle the strip is. A trail point is
## kept as the planet direction it was laid at, so a turn of the frame (the turntable swing) carries it with the world. These are the frame's own definitions (`SimField.placeIn` and `strip`), restated here as pure reads of the
## frame's numbers; a check holds them to the round trip, and when the field frame lands the cross-check against `SimField` is the first thing to run.
## The direction of strip x at depth z (toward the camera above 0): the line's point turned about the line by z / R.
static func place(fr, x: float, z: float) -> PackedFloat64Array:
	var a: float = SimWrap.sdx(float(fr.x0), x) / R_PLANET
	var c: float = cos(a)
	var s: float = sin(a)
	var qx: float = float(fr.px) * c + float(fr.tx) * s
	var qy: float = float(fr.py) * c + float(fr.ty) * s
	var qz: float = float(fr.pz) * c + float(fr.tz) * s
	if z != 0.0:
		var b: float = z / R_PLANET
		var cb: float = cos(b)
		var sb: float = sin(b)
		var nx: float = float(fr.ty) * float(fr.pz) - float(fr.tz) * float(fr.py)
		var ny: float = float(fr.tz) * float(fr.px) - float(fr.tx) * float(fr.pz)
		var nz: float = float(fr.tx) * float(fr.py) - float(fr.ty) * float(fr.px)
		qx = qx * cb + nx * sb
		qy = qy * cb + ny * sb
		qz = qz * cb + nz * sb
	return PackedFloat64Array([qx, qy, qz])


## The inverse: a planet direction's strip x and depth in the frame, as (x, z).
static func unplace(fr, qx: float, qy: float, qz: float) -> Vector2:
	var nx: float = float(fr.ty) * float(fr.pz) - float(fr.tz) * float(fr.py)
	var ny: float = float(fr.tz) * float(fr.px) - float(fr.tx) * float(fr.pz)
	var nz: float = float(fr.tx) * float(fr.py) - float(fr.ty) * float(fr.px)
	var sz: float = R_PLANET * asin(clampf(qx * nx + qy * ny + qz * nz, -1.0, 1.0))
	var sx: float = SimWrap.wrap(float(fr.x0) + R_PLANET * atan2(qx * float(fr.tx) + qy * float(fr.ty) + qz * float(fr.tz), qx * float(fr.px) + qy * float(fr.py) + qz * float(fr.pz)))
	return Vector2(sx, sz)


## A dotted path off a fighter (`tier`, `form.step`): null where it does not exist.
static func read_path(f, path: String):
	var cur = f
	for part in path.split("."):
		if cur == null:
			return null
		if cur is Dictionary:
			cur = cur.get(part)
		elif cur is Object:
			cur = cur.get(part)
		else:
			return null
	return cur


## A fighter's composed row: the default, then his roster id's, then the entry for the form step he has taken, then every situation that holds. Keys it does not name keep the compiled default.
static func row_of(f, flight: bool = false) -> Dictionary:
	warm()
	var rows = _data.get("fighters")
	var out: Dictionary = DEFAULT_ROW.duplicate()
	if not (rows is Dictionary):
		return out
	if rows.has("default"):
		out.merge(rows["default"], true)
	var raw = f.get("id") if f != null else null
	var id: String = String(raw).to_lower().replace("-", "_").replace(" ", "_") if raw != null else ""
	var mine = rows.get(id) if id != "" else null
	if mine is Dictionary:
		out.merge(mine, true)
		var step = read_path(f, "form.step")
		var forms = mine.get("forms")
		if step != null and forms is Dictionary and forms.has(str(int(step))):
			out.merge(forms[str(int(step))], true)
		var sits = mine.get("situations")
		if sits is Array:
			for s in sits:
				if s is Dictionary and _holds(f, s):
					out.merge(s.get("set", {}), true)
	out.erase("forms")
	out.erase("situations")
	# Keys that begin `fl_` belong to the flight line: they win over the plain key while the lines are on, and are not read otherwise (so the meteor trail alone is as it was).
	for k in out.keys():
		if String(k).begins_with("fl_"):
			if flight:
				out[String(k).substr(3)] = out[k]
			out.erase(k)
	return out


static func _holds(f, s: Dictionary) -> bool:
	var v = read_path(f, String(s.get("read", "")))
	if v == null:
		return false
	if s.has("is") and v != s["is"]:
		return false
	if s.has("min") and float(v) < float(s["min"]):
		return false
	if s.has("max") and float(v) > float(s["max"]):
		return false
	return true


## The rule of cool, 0 to 1: the tier's term plus the form steps taken (data), or the row's own `cool` where a situation sets it.
static func cool_of(f, row: Dictionary) -> float:
	var g: Dictionary = _cool_group()
	var tbl: Array = g.get("tier", DEFAULT_COOL["tier"])
	var tier: float = float(f.get("tier")) if f != null and f.get("tier") != null else 1.0
	var t: float = clampf(tier - 1.0, 0.0, float(tbl.size() - 1))
	var lo: int = int(floor(t))
	var hi: int = mini(lo + 1, tbl.size() - 1)
	var c: float = lerpf(float(tbl[lo]), float(tbl[hi]), t - float(lo))
	var step = read_path(f, "form.step")
	if step != null:
		c += minf(float(g.get("form_max", 0.3)), float(step) * float(g.get("form_step", 0.1)))
	if row.has("cool"):
		c = maxf(c, float(row["cool"]))
	return clampf(c, 0.0, 1.0)


## The air a point at this height above the ground burns in: 1 at the ground, falling with `air_h` of the atmosphere's depth; at least `air_floor` of the core's burn stays above it (Orb: "enough to look cool when the camera zooms").
static func air_at(alt: float) -> float:
	return clampf(exp(-maxf(alt, 0.0) / maxf(fp("air_h") * fp("air_depth"), 1.0)), 0.0, 1.0)


static func air_eff(alt: float) -> float:
	return maxf(air_at(alt), fp("air_floor"))


static func ramp_of(speed: float) -> float:
	return smoothstep(fp("burn_from"), fp("burn_full"), speed)


## Who may burn (Orb, 2026-11-01: "a base-form fighter should never burn up"): a body that is SENT (launched or dropped; one flying under its own power is the flight line's, never a burn) and only for a real
## high-energy send: tier `min_tier` or more, or a real meteor on the director's curve (DirArc), at any tier. `send_only` 0 in a profile turns the first half off (the tests, the old look).
static func may_burn(f) -> bool:
	if f == null:
		return true
	if fp("send_only") > 0.5 and f.state != "launched" and f.state != "dropped":
		return false
	var tv = f.get("tier")
	if (float(tv) if tv != null else 1.0) >= fp("min_tier"):
		return true
	return DirArc._g(f, DirArc.A_ROW) != 0


## burn = air x speed ramp x cool.
static func burn_of(speed: float, alt: float, cool: float) -> float:
	return air_eff(alt) * ramp_of(speed) * cool


## The flight line's strength, 0 to 1, a term of its own and not `cool`'s product (Game Design: a tier-4 flier at about 0.25 would be too faint for the zoomed shot): the tier's value, plus each form step taken, up to 1.
## Tier 1 has none; tier 2 keeps today's speed streak only (also none here); the form steps add only where there is a line.
static func flight_strength(f, row: Dictionary) -> float:
	var tbl: Array = flp_a("tier")
	var tier: float = float(f.get("tier")) if f != null and f.get("tier") != null else 1.0
	var t: float = clampf(tier - 1.0, 0.0, float(tbl.size() - 1))
	var lo: int = int(floor(t))
	var hi: int = mini(lo + 1, tbl.size() - 1)
	var c: float = lerpf(float(tbl[lo]), float(tbl[hi]), t - float(lo))
	var step = read_path(f, "form.step")
	if step != null and c > 0.0:
		c += minf(flp("form_max"), float(step) * flp("form_step"))
	return clampf(c, 0.0, 1.0)


static func flp_a(key: String) -> Array:
	warm()
	var g = _data.get("flight")
	if g is Dictionary and g.has(key) and g[key] is Array:
		return g[key]
	return DEFAULT_FLIGHT[key]


## Flat out for this fighter, in units a second: the sim's own free-flight dash (SimFighter.flightSpeed: his speed, tier, forms and stance, times the dash) at the full traversal boost, which the sim gives only far from the rival
## (it is 10 times the melee dash at 12,000 apart). A pure read of the state. The data's `flat_out` is the fallback where there is no state to read.
static func flat_out_of(S, f) -> float:
	if S == null or f == null or not (f is Object) or f.get("spd") == null:
		return flp("flat_out")
	var sp: float = SimFighter.flightSpeed(S, f, true)
	var sep: float = 0.0      # the distance to the other body of his fight, read from the fighters' list (the two-fighter ratchet), 0 when there is none
	for g in S.fighters:
		if g != f:
			sep = absf(SimWrap.sdx(f.x, g.x))
			break
	var boost: float = 1.0 + (SimConst.TRAV_FREE - 1.0) * clampf((sep - SimConst.BOOST_NEAR) / (SimConst.BOOST_FAR - SimConst.BOOST_NEAR), 0.0, 1.0)
	return sp / boost * SimConst.TRAV_FREE


## The speed's share: nothing under `from_k` of flat out, full at flat out.
static func flight_ramp(speed: float, flat_out: float = -1.0) -> float:
	var fo: float = flp("flat_out") if flat_out < 0.0 else flat_out
	return smoothstep(flp("from_k") * fo, fo, speed)


## The altitude's length factor: `len_ground` on the ground, `len_high` at `alt_high` and up (thick air, a short hot line; thin air, a long thin one).
static func len_k(alt: float) -> float:
	return lerpf(flp("len_ground"), flp("len_high"), clampf(alt / maxf(flp("alt_high"), 1.0), 0.0, 1.0))


## The phase times of a point of life `life`: the end of the burn and the end of the cooling.
static func phases(life: float) -> Vector2:
	return Vector2(minf(fp("burn_s"), 0.3 * life), minf(fp("cool_s"), 0.7 * life))


## The head's width cap (Legal RL-222 (1): "at close zoom the head's width is capped so it does not read as a body-wide flame"): a layer's width, in pixels, near the fighter's body. The sheath is at most `head_cap_bh` body heights wide
## there (the body and the core in the layers' own ratio), widening to the layer's ceiling over `head_len_bh` body heights back along the path. `dh` is the distance back from the head in world units, `bh_px` a body height in pixels
## on this view, `ratio` the layer's ceiling as a share of the sheath's, `ceil_px` the layer's ceiling.
static func head_cap_px(dh: float, bh_px: float, ratio: float, ceil_px: float) -> float:
	var near: float = fp("head_cap_bh") * bh_px * ratio
	var t: float = smoothstep(0.0, 1.0, dh / maxf(fp("head_len_bh") * VfxLook.BH, 1.0))
	return lerpf(minf(near, ceil_px), ceil_px, t)


## A line that draws tight (the Empress's) once she has stopped: each point between the two ends moves `t` of the way to the straight line joining them, at the same share along it. The ends stay.
static func settle(pos: PackedVector2Array, t: float) -> PackedVector2Array:
	var out := pos.duplicate()
	var n: int = pos.size()
	if n < 3 or t <= 0.0:
		return out
	for k in range(1, n - 1):
		out[k] = pos[k].lerp(pos[0].lerp(pos[n - 1], float(k) / float(n - 1)), clampf(t, 0.0, 1.0))
	return out


## A point's width as a share of its laid width by age, before the tail's taper: full while it burns, narrowing as it cools.
static func phase_w(age: float, life: float, wc: float = -1.0, ws: float = -1.0) -> float:
	var ph: Vector2 = phases(life)
	var w_c: float = fp("w_cool") if wc < 0.0 else wc          # a flight line's row sets its own: Grist's widens as it cools, the Anti-hero's narrows
	var w_s: float = fp("w_smoulder") if ws < 0.0 else ws
	if age < ph.x:
		return 1.0
	if age < ph.y:
		return lerpf(1.0, w_c, (age - ph.x) / maxf(ph.y - ph.x, 1e-6))
	return lerpf(w_c, w_s, clampf((age - ph.y) / maxf(life - ph.y, 1e-6), 0.0, 1.0))


## The tail's taper: to a point over the last share of a point's life (a tail burns out, it does not fade).
static func taper_at(age: float, life: float) -> float:
	return 1.0 - smoothstep(1.0 - fp("taper"), 1.0, age / maxf(life, 1e-6))


static func width_at(age: float, life: float) -> float:
	return phase_w(age, life) * taper_at(age, life)


## The heat colour by age: the tint while it burns, cooling toward its deeper tint, then dimmer. Brightness only falls, once, over seconds.
static func heat(tint: Color, age: float, life: float, dark: float = -1.0) -> Color:
	var ph: Vector2 = phases(life)
	var deep: Color = tint.darkened(fp("deep_dark") if dark < 0.0 else dark)
	if age < ph.x:
		return tint
	if age < ph.y:
		return tint.lerp(deep, (age - ph.x) / maxf(ph.y - ph.x, 1e-6))
	return deep.lerp(deep.darkened(0.3), clampf((age - ph.y) / maxf(life - ph.y, 1e-6), 0.0, 1.0))


## A point's alpha share by age: 1 while it burns, 0.85 cooled, 0.6 smouldering; and, when `ramp_s` is set, heating up over that long from its laying (a point the head has just passed is not yet at full strength, so no frame sees the whole ribbon's edge change at once).
static func alpha_at(age: float, life: float) -> float:
	var ph: Vector2 = phases(life)
	var r: float = fp("ramp_s")
	var up: float = smoothstep(0.0, r, age) if r > 0.0 else 1.0
	if age < ph.x:
		return up
	if age < ph.y:
		return lerpf(1.0, 0.85, (age - ph.x) / maxf(ph.y - ph.x, 1e-6)) * up
	return lerpf(0.85, 0.6, clampf((age - ph.y) / maxf(life - ph.y, 1e-6), 0.0, 1.0)) * up


## A run: one stretch of one fighter's path while he burned, oldest point first. Points are in the ring's coordinates (x wrapped), so the view maps them to any camera.
class Run:
	var slot: int = 0
	var id: int = 0
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()
	var z := PackedFloat64Array()
	var qx := PackedFloat64Array()         # the planet direction each point was laid at (a field world; zeros and has_q false off one)
	var qy := PackedFloat64Array()
	var qz := PackedFloat64Array()
	var has_q: bool = false
	var s := PackedFloat64Array()          # arc length from the run's start: the pattern is fixed to the path, not to the screen
	var born := PackedFloat64Array()       # the model's clock when the point was laid
	var b := PackedFloat32Array()          # the burn when it was laid
	var w := PackedFloat32Array()          # its width share when it was laid
	var life: float = 8.0
	var base: int = 0                      # points dropped from the front so far: a point's number is stable while the oldest go
	var live: bool = true
	var look: Dictionary = {}              # the composed row, plus `cols` (the three layers' tints), `hue` (the second tint's turn) and `lane`
	var cool: float = 0.0
	var acc: float = 0.0
	var since: float = 0.0
	var lk := PackedFloat32Array()         # each point's life as a multiple of the run's (the flight line's altitude length; 1 for a burn)
	var ended: float = -1.0                # the model's clock when the run stopped being laid (-1: still live)

	func add(px: float, py: float, pz: float, ps: float, pt: float, pb: float, pw: float, q = null, pk: float = 1.0) -> void:
		if q != null:
			qx.append(q[0])
			qy.append(q[1])
			qz.append(q[2])
			has_q = true
		else:
			qx.append(0.0)
			qy.append(0.0)
			qz.append(0.0)
		x.append(px)
		y.append(py)
		z.append(pz)
		s.append(ps)
		born.append(pt)
		b.append(pb)
		w.append(pw)
		lk.append(pk)

	func drop_front(n: int) -> void:
		if n <= 0:
			return
		base += n
		qx = qx.slice(n)
		qy = qy.slice(n)
		qz = qz.slice(n)
		x = x.slice(n)
		y = y.slice(n)
		z = z.slice(n)
		s = s.slice(n)
		born = born.slice(n)
		b = b.slice(n)
		w = w.slice(n)
		lk = lk.slice(n)

	func copy_point(r: Run, j: int) -> void:
		add(r.x[j], r.y[j], r.z[j], r.s[j], r.born[j], r.b[j], r.w[j], [r.qx[j], r.qy[j], r.qz[j]] if r.has_q else null, r.lk[j])

	func blank() -> Run:
		var n := Run.new()
		n.slot = slot
		n.id = id
		n.life = life
		n.live = false
		n.look = look
		n.cool = cool
		n.acc = acc
		n.ended = ended
		return n


var runs: Array = []                      # Run, oldest first
var clock: float = 0.0                    # seconds of unfrozen ticks since the match began
var kb: Array = [0.0, 0.0]                # each fighter's eased burn
var cur: Array = [null, null]             # each fighter's run being laid, or null
var last: Array = [{}, {}]                # the last tick's numbers, for the tests and the debug feed
var laid: int = 0                         # points laid in all (the tests)
var swap: Array = [false, false]          # a fighter whose burn has taken over from the old white trail blade (the trail view skips his blade): on at `blade_on`, off below `blade_off`
var frame_override = null                 # a frame for a test or a tool; the state's own `frame` (a field world) when null
var remaps: int = 0                       # times the points were carried to a turned frame (the tests)
var burn_on: bool = true                  # the meteor burn is laid (the hub turns it off when only the flight lines are on)
var flight_on: bool = false               # the flight lines are laid (the hub's `flight_enabled`)
var fshare: Array = [0.0, 0.0]            # each fighter's share of the line that is the flight line's (0 a burn, 1 a flight line)
var _held: Array = [0.0, 0.0]             # seconds each fighter has held the stick
var _fkey := PackedFloat64Array()
var _px: Array = [0.0, 0.0]
var _py: Array = [0.0, 0.0]
var _has: Array = [false, false]
var _look: Array = [{}, {}]
var _next_id: int = 1


func reset() -> void:
	runs.clear()
	clock = 0.0
	kb = [0.0, 0.0]
	cur = [null, null]
	last = [{}, {}]
	laid = 0
	swap = [false, false]
	remaps = 0
	_fkey = PackedFloat64Array()
	_px = [0.0, 0.0]
	_py = [0.0, 0.0]
	_has = [false, false]
	_look = [{}, {}]
	_next_id = 1
	fshare = [0.0, 0.0]
	_held = [0.0, 0.0]


## One unfrozen tick. quality: a VfxLook.Q_* level; calm: reduced flashing or reduced motion (a shorter linger).
func step(S: SimState, dt: float, quality: int, calm: bool) -> void:
	if not on():
		return
	clock += dt
	var q: int = clampi(quality, 0, 2)
	_remap(S)
	for i in range(mini(2, S.fighters.size())):
		_step_fighter(S, S.fighters[i], i, dt, q, calm)
	var any_dead: bool = false
	for r in runs:
		var n: int = 0
		while n < r.born.size() and clock - r.born[n] > r.life * r.lk[n]:
			n += 1
		r.drop_front(n)
		if r.born.size() == 0 and not r.live:
			any_dead = true
	if any_dead:
		runs = runs.filter(func(r): return r.born.size() > 0 or r.live)


func _step_fighter(S: SimState, f, i: int, dt: float, q: int, calm: bool) -> void:
	var dx: float = 0.0
	var dy: float = 0.0
	var had: bool = _has[i]
	var bx: float = _px[i]        # where he was a tick ago: a corner is laid there, at the bend, and not a tick past it
	var by: float = _py[i]
	if _has[i]:
		dx = SimWrap.sdx(_px[i], f.x)
		dy = f.y - _py[i]
	var d: float = sqrt(dx * dx + dy * dy)
	if d > 3000.0:
		_end_run(S, i, f)       # a teleport (a new match, the ring laid again), not a flight
		d = 0.0
	_px[i] = f.x
	_py[i] = f.y
	_has[i] = true
	var speed: float = d / maxf(dt, 1e-6)
	if _look[i].is_empty() or S.tick % 15 == 0:
		_look[i] = row_of(f, flight_on)
	var row: Dictionary = _look[i]
	var alt: float = f.y - WorldTerrain.groundY(S, f.x)
	var cool: float = cool_of(f, row)
	var tb: float = burn_of(speed, alt, cool) if burn_on and may_burn(f) else 0.0
	var tf: float = 0.0
	if flight_on:
		tf = flight_strength(f, row) * flight_ramp(speed, flat_out_of(S, f)) * _held_of(f, i, dt)
	var target: float = maxf(tb, tf)
	fshare[i] = tf / maxf(tb + tf, 1e-6)
	if f.state == "down" or f.state == "intro" or f.hidden or alt < fp("ground_h"):
		target = 0.0
	var tau: float = fp("rise_s") if target > kb[i] else fp("fall_s")
	kb[i] += (target - kb[i]) * (1.0 - exp(-dt / maxf(tau, 1e-4)))
	swap[i] = kb[i] >= fp("blade_on") or (swap[i] and kb[i] >= fp("blade_off"))
	last[i] = {"speed": speed, "alt": alt, "air": air_eff(alt), "ramp": ramp_of(speed), "cool": cool, "target": target, "burn": kb[i]}
	var r = cur[i]
	if kb[i] < fp("min_burn"):
		_end_run(S, i, f)
		return
	if r == null:
		r = _start_run(S, f, i, q, calm, row, cool)
		_lay(S, r, f, i)
	r.acc += d
	r.since += d
	r.cool = cool
	if r.since >= fa("spacing")[q] * (float(row.get("knot_k", 1.0)) if r.x.size() >= 2 else 1.0):
		_lay(S, r, f, i)
	elif had and _corner(r, f, row):
		_lay(S, r, f, i, bx, by, d)


## The stick held steady (Game Design: a flight line "needs the stick held steady"): the seconds it has been held at `hold_min` or more, eased in over `hold_s`. A launched body has no stick and follows the burn, so it is 1.
func _held_of(f, i: int, dt: float) -> float:
	if f.state == "launched" or f.state == "dropped":
		return 1.0
	var hx = f.get("heldMx")
	var hy = f.get("heldMy")
	if hx == null or hy == null:
		return 1.0
	if sqrt(float(hx) * float(hx) + float(hy) * float(hy)) >= flp("hold_min"):
		_held[i] += dt
	else:
		_held[i] = 0.0
	return smoothstep(0.0, flp("hold_s"), _held[i])


## A corner for a row with fewer knots (the Anti-hero's needle is drawn from knots `knot_k` times as far apart): lay one when he has strayed from the line through the last two by `dev_bh` body heights,
## so the drawn line stays within a body height of his true path.
func _corner(r: Run, f, row: Dictionary) -> bool:
	if float(row.get("knot_k", 1.0)) <= 1.0 or r.x.size() < 2:
		return false
	var n: int = r.x.size()
	var ux: float = SimWrap.sdx(r.x[n - 2], r.x[n - 1])
	var uy: float = r.y[n - 1] - r.y[n - 2]
	var ul: float = sqrt(ux * ux + uy * uy)
	if ul < 1.0:
		return false
	var px: float = SimWrap.sdx(r.x[n - 1], f.x)
	var py: float = f.y + fp("chest_y") - r.y[n - 1]
	return absf(px * uy - py * ux) / ul > flp("dev_bh") * VfxLook.BH


func _start_run(S: SimState, f, i: int, q: int, calm: bool, row: Dictionary, cool: float) -> Run:
	var r := Run.new()
	r.slot = i
	r.id = _next_id
	_next_id += 1
	r.cool = cool
	var life: float = float(fa("life_s")[q]) * float(row.get("linger_k", 1.0))
	if calm:
		life = maxf(life * fp("life_calm_k"), fp("life_min_s"))
	r.life = life
	var look: Dictionary = row.duplicate()
	var lane: Color = VfxAura.lane_color(String(f.aura))
	var cols: Array = []
	var hue: float = 0.0
	for li in range(3):
		var tt: Array = VfxBeamLook.tints(f, lane, li)
		cols.append(tt[0])
		if li == 2:
			var dh: float = fposmod(tt[1].h - tt[0].h + 0.5, 1.0) - 0.5
			hue = dh
	look["cols"] = cols
	look["hue"] = hue
	if look.has("rim"):
		look["rim_c"] = Color.html(String(look["rim"]))
	if not look.has("texture"):
		look["texture"] = ["none", "boil", "facets"][clampi(int(VfxBeamLook.flavour(f).get("pat", 0.0)), 0, 2)]
	r.look = look
	runs.append(r)
	cur[i] = r
	return r


func _lay(S: SimState, r: Run, f, i: int, bx: float = INF, by: float = 0.0, back: float = 0.0) -> void:
	if bx != INF and r.x.size() > 0 and absf(SimWrap.sdx(r.x[r.x.size() - 1], bx)) < 1.0 and absf(r.y[r.y.size() - 1] - (by + fp("chest_y"))) < 1.0:
		bx = INF       # a corner a tick after a knot would lay the same point twice and blind the next corner's line: lay it here instead
		back = 0.0
	var wf: float = lerpf(fp("w_min"), 1.0, clampf(kb[i], 0.0, 1.0)) * (1.0 + fp("peak_w") * r.cool)
	var lk: float = 1.0
	if fshare[i] > 0.0:
		var alt_l: float = f.y - WorldTerrain.groundY(S, f.x)
		var ak: float = clampf(alt_l / maxf(flp("alt_high"), 1.0), 0.0, 1.0)
		lk = lerpf(1.0, len_k(alt_l), fshare[i])
		wf *= lerpf(1.0, flp("thin_w"), ak * fshare[i])        # thin air: a long thin line
	var fr = _frame(S)
	var lx: float = f.x if bx == INF else bx
	var ly: float = f.y if bx == INF else by
	r.add(lx, ly + fp("chest_y"), f.z, r.acc - back, clock, kb[i], wf, place(fr, lx, f.z) if fr != null else null, lk)
	r.since = back
	laid += 1
	if r.x.size() > int(fp("max_pts")):
		r.drop_front(r.x.size() - int(fp("max_pts")))


## The burn has ended (he slowed, landed or was teleported): the run keeps the last point at his body and stops being laid; it cools out where it is.
func _end_run(S: SimState, i: int, f) -> void:
	var r = cur[i]
	if r == null:
		return
	if r.since > 1.0:
		var fr = _frame(S)
		r.add(f.x, f.y + fp("chest_y"), f.z, r.acc, clock, kb[i], r.w[r.w.size() - 1] if r.w.size() > 0 else 1.0, place(fr, f.x, f.z) if fr != null else null, r.lk[r.lk.size() - 1] if r.lk.size() > 0 else 1.0)
	r.live = false
	r.ended = clock
	cur[i] = null


## The field frame in force: a test's, else the state's own (null off a field world, and on a state with no such field).
func _frame(S: SimState):
	return frame_override if frame_override != null else S.get("frame")


## A turned frame carries the points with the planet: each point is mapped again from its planet direction, once when the frame's numbers change (a swing tick), never at rest.
func _remap(S: SimState) -> void:
	var fr = _frame(S)
	if fr == null:
		return
	var key := PackedFloat64Array([float(fr.px), float(fr.py), float(fr.pz), float(fr.tx), float(fr.ty), float(fr.tz), float(fr.x0)])
	if key == _fkey:
		return
	_fkey = key
	remaps += 1
	for r in runs:
		if not r.has_q:
			continue
		for j in range(r.x.size()):
			var v: Vector2 = unplace(fr, r.qx[j], r.qy[j], r.qz[j])
			r.x[j] = v.x
			r.z[j] = v.y


## The ring turns (World's window 3, `arena_turn {x, carry}`): points beyond the zone are gone, inside it a point stays while the turn weight is 0.1 or more, and a run cut in the middle is two.
func on_turn(px: float, carry: float) -> void:
	var out: Array = []
	for r in runs:
		if r.has_q:
			out.append(r)       # a field world's points are planet directions: the turn moves the frame, not the points
			continue
		var n: int = r.x.size()
		var piece: Run = null
		var live_piece: Run = null
		for j in range(n):
			if VfxHub.turn_weight(absf(SimWrap.sdx(px, r.x[j])), carry) >= 0.1:
				if piece == null:
					piece = r.blank()
					out.append(piece)
				piece.copy_point(r, j)
				if j == n - 1:
					live_piece = piece
			else:
				piece = null
		if r.live:
			if live_piece != null:
				live_piece.live = true
				cur[r.slot] = live_piece
			elif cur[r.slot] == r:
				cur[r.slot] = null
	runs = out
