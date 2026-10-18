class_name VfxBlastCloud
extends RefCounted
## The blast cloud (docs/vfx/catastrophe-plan.md section 2; run-mode section 3.2; Legal c01 to c07): a tier-5 detonation's stem-and-cap cloud, our own, with a fireball inside it that is the one
## catastrophe light event (flash_registry.gd's `cat` class). The cue is `blast_cloud` (Audio's list: `x`, `y`, `amount` the blast's size (3,000), `n` the tick it lands). Nothing here runs without it.
## The cloud itself is STATELESS on the GPU (cloud_view.gd, shaders/cloud.gdshader): positions are closed-form curves of its age, so a pause, a seek and a replay are right by construction and the CPU
## writes only a handful of uniforms a frame. The functions below are the CPU mirrors of those curves (the checks and the sprite budget use them); the shader's are the same formulas.
## Our own blast cloud (c07): no word, sign, siren or countdown, no ring leaving the blast (the ground wave is a dark dust wall), no dome of light (the glow is a lumpy core inside the stem and cap), and
## it never rests on a boss charging a sphere (its wind-up is the fighter's own detonation cue). Presentation only: no sim write, no `S.rng`, hashes only.

const DEFAULTS: Dictionary = {
	"sprites": [140, 260, 400], "far_sprites": 24, "far_distance": 9000.0, "far_size_k": 2.4,
	"height_max": 14000.0, "height_tau_s": 6.5,
	"cap_major": 2600.0, "cap_major_tau_s": 8.0, "cap_minor": 1500.0, "cap_minor_rise_s": 5.0, "cap_omega": -0.35,
	"stem_width": [260.0, 760.0],
	"skirt_reach": 4500.0, "skirt_tau_s": 3.2, "skirt_height": [300.0, 600.0],
	"heat_tau_core_s": 4.0, "heat_tau_stem_s": 2.2,
	"alpha_max": 0.85, "fade_in_s": 1.0, "life_s": 40.0, "fade_out_s": 8.0,
	"fire_rise_s": 0.6, "fire_fall_s": 2.4, "calm_fire_rise_s": 1.0, "calm_fire_fall_s": 3.6,
	"core_radius_k": 0.35, "core_sprites": 12, "core_alpha": 0.55,
	"max_alive": 2,
	"colour_hot": "#fff0c8", "colour_amber": "#f0a850", "colour_ember": "#9a6a3c", "colour_smoke": "#5f5953",
}

static var _data: Dictionary = {}
static var _loaded: bool = false

## The clouds in flight (at most `max_alive`): {id, land (the hub's clock tick it lands), x, gy (the ground there at landing), amount, seed, asked, ok, peak, rise, fall}.
var runs: Array = []
var now: int = 0
var asks_made: int = 0              # for the tests


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/catastrophe.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary and v.get("blast_cloud") is Dictionary:
			_data = v["blast_cloud"]


static func p(key: String):
	warm()
	var v = _data.get(key)
	return v if v != null else DEFAULTS[key]


func reset() -> void:
	runs.clear()
	now = 0
	asks_made = 0


# ------------------------------------------------------------------------------------------------ the curves (the shader's, mirrored)

## The cloud's scale from the blast's size: 3,000 units is 1.
static func scale_of(amount: float) -> float:
	return clampf(amount / 3000.0, 0.25, 2.0)


## The height of the stem's top, `t` seconds after landing, in units.
static func height(t: float, scale: float = 1.0) -> float:
	return float(p("height_max")) * scale * (1.0 - exp(-maxf(t, 0.0) / float(p("height_tau_s"))))


## The cap's major radius (its ring) and its minor radius (its thickness), `t` seconds after landing.
static func cap_major(t: float, scale: float = 1.0) -> float:
	return float(p("cap_major")) * scale * (1.0 - exp(-maxf(t, 0.0) / float(p("cap_major_tau_s"))))


static func cap_minor(t: float, scale: float = 1.0) -> float:
	return float(p("cap_minor")) * scale * minf(1.0, maxf(t, 0.0) / float(p("cap_minor_rise_s")))


## How far the ground's dust wall has reached each way from the blast.
static func skirt(t: float, scale: float = 1.0) -> float:
	return float(p("skirt_reach")) * scale * (1.0 - exp(-maxf(t, 0.0) / float(p("skirt_tau_s"))))


## The cloud body's opacity at age `t`: a smootherstep in over fade_in_s, held, a smootherstep out over the last fade_out_s of its life.
static func body_alpha(t: float) -> float:
	var fin: float = clampf(t / float(p("fade_in_s")), 0.0, 1.0)
	fin = fin * fin * (3.0 - 2.0 * fin)
	var life: float = float(p("life_s"))
	var fo: float = float(p("fade_out_s"))
	var out: float = clampf((t - (life - fo)) / fo, 0.0, 1.0)
	out = out * out * (3.0 - 2.0 * out)
	return float(p("alpha_max")) * fin * (1.0 - out)


## The heat of a place in the cloud, 0 to 1: the fire's colour fades to smoke as it falls. `tau` is the cap's core (heat_tau_core_s) or the stem's (heat_tau_stem_s).
static func heat(t: float, tau: float) -> float:
	return exp(-maxf(t, 0.0) / tau)


## Fire into smoke: white-amber, amber, ember brown, warm grey-brown. Red is never reached; the amber end keeps R/(R+G+B) well under 0.8 on the stored values and on the linear ones
## (the analyser's saturated-red test takes whichever is redder). Mirrored in the shader; `lit` false (a refused light, or a calm cloud) holds it below the white-amber end.
static func ramp(h: float, lit: bool = true) -> Color:
	var hot := Color(String(p("colour_hot")))
	var amber := Color(String(p("colour_amber")))
	var ember := Color(String(p("colour_ember")))
	var smoke := Color(String(p("colour_smoke")))
	var hh: float = clampf(h, 0.0, 1.0)
	if not lit:
		hh = minf(hh, 0.7)
	if hh >= 0.7:
		return amber.lerp(hot, (hh - 0.7) / 0.3)
	if hh >= 0.4:
		return ember.lerp(amber, (hh - 0.4) / 0.3)
	return smoke.lerp(ember, hh / 0.4)


# ------------------------------------------------------------------------------------------------ state

## Once a tick, from the hub (after the registry's begin_tick): the clock, the landing of each cloud (its ground read and its one ask of the register), and the finished clouds dropped.
func step(S: SimState, flashes: VfxFlashRegistry, ash: float) -> void:
	now += 1
	var i: int = 0
	while i < runs.size():
		var r: Dictionary = runs[i]
		if not bool(r["asked"]) and now >= int(r["land"]):
			r["asked"] = true
			r["gy"] = WorldTerrain.groundY(S, float(r["x"]))
			_ask(S, flashes, ash, r)
		if float(now - int(r["land"])) / 60.0 > float(p("life_s")) + 1.0:
			runs.remove_at(i)
		else:
			i += 1


## The fireball's light is one catastrophe light event: asked once, at landing, with its whole weight (the glow's area at its peak, against the standard's threshold). Refused (the 2 s gap, the
## budget, red): the cloud still rises and darkens, without its light.
func _ask(S: SimState, flashes: VfxFlashRegistry, ash: float, r: Dictionary) -> void:
	var sc: float = scale_of(float(r["amount"]))
	var core_r: float = float(p("core_radius_k")) * cap_major(1.0e9, sc)
	var area: float = VfxFlashRegistry.disc_px(core_r, flashes.ppu_at(-12.0))
	var amber := Color(String(p("colour_amber")))
	var rise: int = int(round(float(p("fire_rise_s")) * 60.0))
	var fall: int = int(round(float(p("fire_fall_s")) * 60.0))
	var ans: Dictionary = flashes.ask_cat("cat_blast", int(r["id"]), amber, area, rise, fall, 1.0, ash, S.tick)
	asks_made += 1
	r["ok"] = bool(ans["ok"])
	r["peak"] = float(ans["peak"])
	r["rise"] = int(ans["rise"])
	r["fall"] = int(ans["fall"])


## The `blast_cloud` cue: `x` (the blast's x), `amount` (its size), `n` the tick it lands (the sim's tick; a cue at or after it lands at once).
func on_events(S: SimState, events: Array) -> void:
	for e in events:
		if e.type != "cue" or String(e.kind) != "blast_cloud":
			continue
		var amount: float = float(e.get("amount") if e.get("amount") != null else 3000.0)
		var land: int = now + maxi(int(float(e.n)) - S.tick, 0)
		runs.append({"id": S.tick * 31 + int(float(e.x)) % 997, "land": land, "x": float(e.x), "gy": 0.0, "amount": amount, "seed": S.tick, "asked": false, "ok": false, "peak": 0.0, "rise": 18, "fall": 60})
		while runs.size() > int(p("max_alive")):
			runs.pop_front()


func active() -> bool:
	for r in runs:
		if now >= int(r["land"]):
			return true
	return false


## A cloud's age in seconds at the clock's tick plus `frac` of a tick (negative before it lands).
func age_s(r: Dictionary, frac: float = 0.0) -> float:
	return (float(now - int(r["land"])) + frac) / 60.0


## The fireball's light, 0 to 1, at the clock's tick: the granted envelope (rise, fall and peak as the register shaped them) or 0 when the register refused it.
func light(r: Dictionary, frac: float = 0.0) -> float:
	if not bool(r["asked"]) or not bool(r["ok"]):
		return 0.0
	return VfxFlashRegistry.cat_level(float(now - int(r["land"])) + frac, int(r["rise"]), int(r["fall"])) * float(r["peak"])
