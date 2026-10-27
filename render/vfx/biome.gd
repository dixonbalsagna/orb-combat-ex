class_name VfxBiome
extends RefCounted
## Biome effects (docs/vfx/biome-fx.md; Orb, 2026-10-23: "every biome answers a fight in its own material"), in Art's plume language (docs/art/biomes.md section 5). An impact on the ground is drawn the same way
## in all of the fifteen biomes: a billowing COLUMN of overlapping faceted puffs (the high ones first, so the low ones sit in front), one flat pale burst STAR on the first frame, EJECTA on arcs, a SKIRT of
## low puffs along the ground and debris that lands. What changes is the colour, the height and the ejecta. The colours, the height and the width are Art's own (data/art/biomes.json, `plume`, by the fine
## biome's name); how the composition is drawn and what each kind's ejecta are is data/vfx/biome.json. earth.gd's own chunks and dust stay under it. Scaled by the causer's power tier (pillar 4), the event's
## speed, quality and reduced motion. Presentation only: it reads the event and the biome and writes nothing of the sim; its randomness is the debris pool's cosmetic stream with a fixed number of draws a
## bit, so the stream does not depend on the quality level.

const TIER_K: Array = [0.7, 1.0, 1.45, 2.0]
const KINDS: Dictionary = {"chunk": 1, "snow": 2, "leaf": 3, "ash": 4, "splinter": 5}

static var _data: Dictionary = {}
static var _art: Dictionary = {}
static var _loaded: bool = false
## Tests and tools only: forces a biome name whatever the sim says (World's fine ids are not in every match).
static var override_biome: String = ""

var debris: VfxDebris
var flashes: VfxFlashRegistry = null     # the register: the burst star asks it (a one-frame disc is a flash by the standard's area test)
var made: Dictionary = {}                # bits asked for, by kind (for the tests)
var emitted: int = 0                     # events that had a plume spec
var stars: int = 0                       # burst stars drawn
var stars_refused: int = 0
var columns: int = 0                     # columns drawn
var _last_plume_tick: int = -1000
var _last_star_tick: int = -1000
var _last_plume_x: float = 0.0


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/biome.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v
	var ap := "res://data/art/biomes.json"
	if FileAccess.file_exists(ap):
		var a = JSON.parse_string(FileAccess.get_file_as_string(ap))
		if a is Dictionary and a.get("biomes") is Dictionary:
			for id in a["biomes"]:
				var pl = a["biomes"][id].get("plume")
				if pl is Dictionary:
					_art[String(id)] = _parse(pl, a["biomes"][id].get("palette", {}))


static func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)


## Relative luminance (the standard's, from the sRGB colour).
static func _lum(c: Color) -> float:
	return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)


## A puff's weight in the pool's drawn-area budget (Legal's fx07): a puff whose relative luminance steps 10% or more from the ground's counts at FULL weight; under 10% it may count less, down to 0.3.
static func puff_weight(c: Color, ground: Color) -> float:
	var step: float = absf(_lum(c) - _lum(ground))
	return 1.0 if step >= 0.10 else 0.3 + 0.7 * step / 0.10


static func _parse(pl: Dictionary, pal: Dictionary) -> Dictionary:
	var cols: Array = pl.get("cols", [])
	var ej: Array = pl.get("ej", [])
	if cols.size() < 3 or ej.size() < 2:
		return {}
	var mid: Color = RenderLook.col(String(cols[1]))
	var gr: Array = pal.get("ground", [])
	var gcol: Color = RenderLook.col(String(gr[1])) if gr.size() > 1 else mid
	return {
		"kind": String(pl.get("kind", "dirt")),
		"ground": gcol,
		# the puffs of a plume count in the pool's drawn-area budget by how far their luminance is from the ground's: sand on sand and ash on basalt barely step, snow on grass does
		"aw_lit": puff_weight(RenderLook.col(String(cols[0])), gcol), "aw_mid": puff_weight(mid, gcol), "aw_shade": puff_weight(RenderLook.col(String(cols[2])), gcol),
		"aw": (puff_weight(RenderLook.col(String(cols[0])), gcol) + puff_weight(mid, gcol) + puff_weight(RenderLook.col(String(cols[2])), gcol)) / 3.0,
		"lit": RenderLook.col(String(cols[0])), "mid": RenderLook.col(String(cols[1])), "shade": RenderLook.col(String(cols[2])),
		"ej0": RenderLook.col(String(ej[0])), "ej1": RenderLook.col(String(ej[1])),
		"h": float(pl.get("h", 300.0)), "w": float(pl.get("w", 200.0)),
		"ring": bool(pl.get("ring", false)), "steam": bool(pl.get("steam", false)), "wet": bool(pl.get("wet", false)), "embers": bool(pl.get("embers", false)),
	}


## Art's plume spec of a biome by its name ({} where Art has none: a village, the city), colours parsed.
static func spec(biome: String) -> Dictionary:
	warm()
	return _art.get(biome, {})


## The biome name at x: World's fine id when the match carries it (`S.fineCols`, a byte a column, gen 2, unhashed), else the stored biome's name (as VfxPalette.biome_key has it).
static func key_at(S, x: float) -> String:
	if override_biome != "":
		return override_biome
	if S != null:
		var pf = S.get("fineCols")
		if pf is PackedByteArray and pf.size() > 0:
			var col: int = clampi(int(SimWrap.wrap(x) / SimConst.COL), 0, pf.size() - 1)
			return WorldClimate.fineName(int(pf[col]))
	return VfxPalette.biome_key(x)


## The tier's share of the full effect (1 to 4).
static func tier_k(tier: int) -> float:
	warm()
	var a = _data.get("tier_k")
	if a is Array and a.size() == 4:
		return float(a[clampi(tier, 1, 4) - 1])
	return float(TIER_K[clampi(tier, 1, 4) - 1])


static func _g(group: String, key: String, d: float) -> float:
	var g = _data.get(group)
	if g is Dictionary and g.has(key):
		return float(g[key])
	return d


static func _pair(group: String, key: String, a: float, b: float) -> Vector2:
	var g = _data.get(group)
	if g is Dictionary and g.get(key) is Array and g[key].size() == 2:
		return Vector2(float(g[key][0]), float(g[key][1]))
	return Vector2(a, b)


func reset() -> void:
	made = {}
	emitted = 0
	stars = 0
	stars_refused = 0
	columns = 0
	_last_plume_tick = -1000
	_last_star_tick = -1000
	warm()


## One event at (x, y, z): event is "slam", "skid", "bounce", "leave", "crater", "slide_end" or "skid_tick"; dirx the way the body was travelling; s the event's speed share (0.25 to 2.2); tier the
## causer's (1 to 4); q the quality share (earth.gd `_q`); lk 0.55 at an intro landing (earth.gd `_lk`).
func emit(event: String, S, x: float, y: float, z: float, dirx: float, s: float, tier: int, q: float, lk: float = 1.0) -> void:
	if debris == null:
		return
	var sp: Dictionary = spec(key_at(S, x))
	if sp.is_empty() or String(sp["kind"]) == "water":
		return
	var evs = _data.get("events")
	if not (evs is Dictionary and evs.get(event) is Dictionary):
		return
	var ev: Dictionary = evs[event]
	emitted += 1
	var tk: float = tier_k(tier)
	var ss: float = clampf(s, 0.25, 2.2)
	var sc: float = clampf(_g("scale", "base", 0.3) + _g("scale", "per_k", 0.35) * tk * clampf(ss, 0.4, 1.6), _g("scale", "min", 0.3), _g("scale", "max", 1.2))
	var tick: int = int(S.tick) if S != null else 0
	var plume_w: float = float(ev.get("plume", 0.0))
	var star: bool = bool(ev.get("star", false))
	if plume_w > 0.0:
		# a slam digs a crater in the same tick: one column and one star for the pair, the first's
		if tick - _last_plume_tick < 8 and absf(SimWrap.sdx(x, _last_plume_x)) < 400.0:
			plume_w = 0.0
			star = false
		else:
			_last_plume_tick = tick
			_last_plume_x = x
	if plume_w > 0.0:
		_column(sp, x, y, z, sc * plume_w, q, lk)
		if star and lk >= 0.99:      # not at an intro landing: the staredown is still
			_star(sp, x, y, z, sc, tick)
	var ej: float = float(ev.get("ejecta", 1.0))
	if ej > 0.0:
		var list = _data.get("kinds", {}).get(String(sp["kind"]))
		if list is Array:
			for em in list:
				if String(em.get("needs", "")) == "embers" and not bool(sp["embers"]):
					continue
				_one(em, sp, x, y, z, dirx, ss, tk, ej, q, lk)
	var sk: float = float(ev.get("skirt", 0.0))
	if sk > 0.0:
		_skirt(sp, x, y, z, sc, sk, dirx, q, lk)
	if bool(ev.get("ring", false)) and (bool(sp["ring"]) or bool(sp["wet"])):
		_ring(sp, x, y, z, sc, q)
	if bool(sp["steam"]) and plume_w > 0.0:
		_steam(sp, x, y, z, q)


# --------------------------------------------------------------------------------------------------------------- the pieces

## The column: puffs from the top down (the high ones are made first, so the low ones draw in front), narrower the higher, in the plume's lit, mid and shade colours: lit at the top, shade at the foot.
func _column(sp: Dictionary, x: float, y: float, z: float, sc: float, q: float, lk: float) -> void:
	var h: float = float(sp["h"]) * sc
	var w: float = float(sp["w"]) * sc
	var n: int = clampi(int(round(h / _g("column", "puff_h", 62.0))), int(_g("column", "min", 3.0)), int(_g("column", "max", 9.0)))
	var taper: float = _g("column", "taper", 0.45)
	var size_k: float = _g("column", "size_k", 0.55)
	var grow: float = _g("column", "grow", 1.35)
	var life: Vector2 = _pair("column", "life", 1.1, 1.8)
	var rise: Vector2 = _pair("column", "rise", 30.0, 70.0)
	var drift: float = _g("column", "drift", 26.0)
	# the puffs alive at once are held to a share of the register's area threshold (the hub sets the pool's cap from the camera's scale): at a close framing the column is drawn at the size that fits,
	# so the plume is the same share of the screen however near the camera is, and never a step over a large area (Legal's flash rules)
	var need: float = 0.0
	for i in range(n):
		var ti: float = 1.0 - float(i) / float(maxi(n - 1, 1))
		var wq: float = w * (1.0 - taper * ti) * size_k * grow
		need += 0.785 * wq * wq * float(sp["aw"])
	var fit: float = 1.0
	if debris.puff_area_cap < 1e18 and need > 0.0:
		fit = clampf(sqrt(maxf(debris.puff_area_cap * 0.8 - debris._puff_area, 0.0) / need), 0.3, 1.0)
	size_k *= fit
	var rd: SimRng = debris._rd
	columns += 1
	for i in range(n):
		var t: float = 1.0 - float(i) / float(maxi(n - 1, 1))      # 1 at the top, 0 at the foot
		var jx: float = rd.range_(-0.12, 0.12) * w
		var vx: float = rd.range_(-drift, drift)
		var vy: float = rd.range_(rise.x, rise.y)
		var lf: float = rd.range_(life.x, life.y)
		var pick: float = rd.next()
		var keep: float = rd.next()
		if keep >= q:
			continue
		var wi: float = w * (1.0 - taper * t)
		var c: Color = sp["shade"]
		if t > 0.62:
			c = sp["lit"] if pick > 0.2 else sp["mid"]
		elif t > 0.28:
			c = sp["mid"] if pick > 0.2 else (sp["lit"] if pick > 0.5 else sp["shade"])
		else:
			c = sp["shade"] if pick > 0.25 else sp["mid"]
		made["puff"] = int(made.get("puff", 0)) + 1
		debris.dust_puff("plains", x + jx, y + 46.0 + t * h * 0.8, z + 6.0 + 2.0 * float(n - i), vx, vy, wi * size_k, wi * size_k * grow, lf * lk, 0, c, puff_weight(c, sp["ground"]))


## One flat pale star on the first frame (the plume's own lit tone, not white-hot), never a flicker: it lives a hundredth of a second and asks the register.
func _star(sp: Dictionary, x: float, y: float, z: float, sc: float, tick: int) -> void:
	var r: float = minf(float(sp["w"]) * sc * _g("star", "r_k", 0.5), _g("star", "r_max", 130.0))
	var col: Color = (sp["lit"] as Color).lightened(0.15)
	if tick - _last_star_tick < 60:      # never twice within a second (Legal's fx07)
		return
	if flashes != null:
		var area: float = VfxFlashRegistry.disc_px(r * 0.5, flashes.ppu_at(z))
		if not flashes.ask("biome_star", col, tick, area):
			stars_refused += 1
			return
	stars += 1
	_last_star_tick = tick
	debris.star(x, y + 30.0 + r * 0.25, z + 12.0, r, _g("star", "life", 0.025), col)


func _skirt(sp: Dictionary, x: float, y: float, z: float, sc: float, k: float, dirx: float, q: float, lk: float) -> void:
	var n: int = mini(int(ceil(_g("skirt", "n", 5.0) * k * (0.6 + 0.4 * sc) * lk)), int(_g("skirt", "max", 9.0)))
	var vxr: Vector2 = _pair("skirt", "vx", 90.0, 320.0)
	var vyr: Vector2 = _pair("skirt", "vy", 10.0, 40.0)
	var life: Vector2 = _pair("skirt", "life", 1.2, 1.9)
	var size_k: float = _g("skirt", "size_k", 0.26)
	if debris.puff_area_cap < 1e18:
		var sw: float = float(sp["w"]) * sc * size_k * 1.5
		var need: float = 0.785 * sw * sw * float(n) * float(sp["aw"])
		if need > 0.0:
			size_k *= clampf(sqrt(maxf(debris.puff_area_cap * 0.9 - debris._puff_area, 0.0) / need), 0.3, 1.0)
	var rd: SimRng = debris._rd
	for i in range(n):
		var jx: float = rd.range_(-0.2, 0.2) * float(sp["w"]) * sc
		var vx: float = rd.range_(vxr.x, vxr.y) * (1.0 if i % 2 == 0 else -1.0)
		var vy: float = rd.range_(vyr.x, vyr.y)
		var lf: float = rd.range_(life.x, life.y)
		var pick: float = rd.next()
		var keep: float = rd.next()
		if keep >= q:
			continue
		var c: Color = sp["shade"] if pick < 0.5 else sp["mid"]
		made["puff"] = int(made.get("puff", 0)) + 1
		var sz: float = float(sp["w"]) * sc * size_k * (0.8 + 0.4 * pick)
		debris.dust_puff("plains", x + jx, y + 30.0, z + 22.0, vx, vy, sz, sz * 1.5, lf * lk, 0, c, puff_weight(c, sp["ground"]))


func _ring(sp: Dictionary, x: float, y: float, z: float, sc: float, q: float) -> void:
	var rd: SimRng = debris._rd
	var keep: float = rd.next()
	if keep >= q:
		return
	var col: Color = sp["ej1"] if bool(sp["ring"]) else sp["shade"]
	var r0: float = float(sp["w"]) * sc * _g("ring", "r0", 0.2)
	made["ring"] = int(made.get("ring", 0)) + 1
	debris.ring_tint(x, y + 3.0, z + 4.0, r0, r0 * _g("ring", "grow", 2.2), _g("ring", "life", 0.9), col)


func _steam(sp: Dictionary, x: float, y: float, z: float, q: float) -> void:
	var n: int = int(_g("steam", "n", 3.0))
	var sz: Vector2 = _pair("steam", "size", 40.0, 70.0)
	var lf: Vector2 = _pair("steam", "life", 1.4, 2.0)
	var vyr: Vector2 = _pair("steam", "vy", 50.0, 90.0)
	var spread: float = _g("steam", "spread", 60.0)
	var col: Color = RenderLook.col(String(_data.get("steam", {}).get("col", "#b9c1c0")))
	var rd: SimRng = debris._rd
	for i in range(n):
		var jx: float = rd.range_(-spread, spread)
		var rs: float = rd.range_(sz.x, sz.y)
		var rl: float = rd.range_(lf.x, lf.y)
		var vy: float = rd.range_(vyr.x, vyr.y)
		var keep: float = rd.next()
		if keep >= q:
			continue
		made["steam"] = int(made.get("steam", 0)) + 1
		debris.dust_puff("plains", x + jx, y + 12.0, z + 14.0, rd.range_(-12.0, 12.0) * 0.0, vy, rs, rs * _g("steam", "grow", 1.8), rl, 0, col)


func _col(tok: String, sp: Dictionary) -> Color:
	return sp.get(tok, sp["mid"])


func _one(em: Dictionary, sp: Dictionary, x: float, y: float, z: float, dirx: float, ss: float, tk: float, ej: float, q: float, lk: float) -> void:
	var kind: String = String(em.get("kind", "chunk"))
	if not KINDS.has(kind):
		return
	var nn: float = float(em.get("n", 1.0)) * ss * tk * ej * lk
	var cap: int = int(em.get("max", 16))
	var whole: int = mini(int(floor(nn)), cap)
	var frac: float = nn - floor(nn) if int(floor(nn)) < cap else 0.0
	var count: int = whole + (1 if frac > 0.0 else 0)
	var sz: Vector2 = Vector2(float(em["size"][0]), float(em["size"][1])) if em.get("size") is Array else Vector2(10.0, 20.0)
	var lf: Vector2 = Vector2(float(em["life"][0]), float(em["life"][1])) if em.get("life") is Array else Vector2(1.0, 2.0)
	var vxr: Vector2 = Vector2(float(em["vx"][0]), float(em["vx"][1])) if em.get("vx") is Array else Vector2(60.0, 300.0)
	var vyr: Vector2 = Vector2(float(em["vy"][0]), float(em["vy"][1])) if em.get("vy") is Array else Vector2(100.0, 400.0)
	var spread: float = float(em.get("spread", 40.0))
	var grav: float = float(em.get("grav", 1.0))
	var drag: float = float(em.get("drag", 0.0))
	var dmode: String = String(em.get("dir", "both"))
	var size_k: float = (0.75 + 0.25 * tk) * (0.7 + 0.3 * ss)
	var speed_k: float = 0.6 + 0.4 * ss
	var toks: Array = em.get("cols", ["mid"])
	var rd: SimRng = debris._rd
	for i in range(count):
		# a fixed number of draws a bit (ten), kept or not by quality and by the fractional last one
		var jx: float = rd.range_(-spread, spread)
		var jy: float = rd.range_(0.0, 20.0)
		var rx: float = rd.range_(vxr.x, vxr.y)
		var ry: float = rd.range_(vyr.x, vyr.y)
		var rs: float = rd.range_(sz.x, sz.y)
		var rl: float = rd.range_(lf.x, lf.y)
		var rc: float = rd.next()
		var rsp: float = rd.range_(-1.0, 1.0)
		var rsg: float = rd.next()
		var keep: float = rd.next()
		var wgt: float = q
		if i == whole and frac > 0.0:
			wgt *= frac
		if keep >= wgt:
			continue
		var sg: float = 1.0
		match dmode:
			"back":
				sg = -dirx
			"fwd":
				sg = dirx
			"up":
				sg = -1.0 if rsg < 0.5 else 1.0
			_:
				sg = 1.0 if i % 2 == 0 else -1.0
		var vx: float = sg * rx * speed_k + rsp * 30.0
		var vy: float = ry * speed_k
		var size: float = rs * size_k
		var px: float = x + jx
		var py: float = y + jy + 4.0
		var c: Color = _col(String(toks[mini(int(rc * float(toks.size())), toks.size() - 1)]), sp)
		made[kind] = int(made.get(kind, 0)) + 1
		match kind:
			"chunk":
				# a share of the chunks lands and stays a few seconds (Art: debris that lands stays)
				var stay: bool = rsg < float(em.get("stay", 0.0)) and lk >= 0.99
				debris.fleck(VfxDebris.CHUNK, px, py, z + 6.0, vx, vy, size, (4.5 + 2.0 * rc) if stay else rl * lk, c, c.lightened(0.25), int(em.get("mode", 2)), grav, drag, 10.0, rsp, -1e9, stay)
			"snow":
				debris.fleck(VfxDebris.SNOW, px, py, z + 8.0, vx, vy, size, rl * lk, c, c, 0, grav, drag, 3.0, rsp)
			"leaf":
				debris.fleck(VfxDebris.LEAF, px, py, z + 8.0, vx, vy, size, rl * lk, c, c, 0, grav, drag, 6.0, rsp)
			"ash":
				debris.fleck(VfxDebris.ASH, px, py, z + 8.0, vx, vy, size, rl * lk, c, c, 0, grav, drag, 4.0, rsp)
			"splinter":
				debris.fleck(VfxDebris.SPLINTER, px, py, z + 8.0, vx, vy, size, rl * lk, c, c, 0, grav, drag, 9.0, rsp)
