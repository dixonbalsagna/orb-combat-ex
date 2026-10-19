class_name RenderShapes
extends RefCounted
## The re-laid city's buildings for the renderer (World's brief docs/world/rendering-brief-lanes.md; Art's
## docs/art/district-looks.md): each building's shape as a few boxes, and each district look's colours and windows.
##
## A building is drawn as PARTS: boxes of one mesh in one MultiMesh, each deformed in building.gdshader by three numbers
## (its top's width and depth as a share of its base, and a lean that slopes its top down to one side). A shaft is one
## box; a stepped tower is a core with wider skirts; a spire is a box under a pyramid; a gable is a box whose top is
## pinched to a ridge; a saw-tooth roof is a row of leaning boxes. Art's rule holds by construction: prisms and stacks of
## prisms, no curves (an octagonal stack is drawn four-sided until Art draws it).
##
## The sim's box is a rectangle (b.w wide, b.h tall above its footing) and every blast, shot and flight reads it, so
## the shapes FILL it (World's rule, 2026-10-12): at the sim's height a building's walls are at least 85% of its width
## (a stepped tower's top tier, a crown's chamfer, a stack's taper), so a fighter does not hit air beside a narrow
## top. What makes the silhouette stands ABOVE the sim's height as an ornament that does not collide: a spire, a
## finial, a ridge, a plant box, a lantern room, at most ORN_MAX of the height (flag ORN). No wall is wider than the
## box. A gable starts a little under the sim's height (at most a tenth of it) so its pitch is not flat.
##
## Reads the sim and the settlements data only; writes neither.

const SETTLEMENTS: String = "res://data/biomes/settlements.json"
## Art's city palettes and facade types (docs/art/city-facades.md): with it the downtown and mid-rise towers take a tint
## and a facade each (city_look); without it they are drawn in their look as before.
const CITY_LOOKS: String = "res://data/art/city-looks.json"
const FACADES: Array = ["ribbon", "punched", "fins", "balconied"]   # building.gdshader's facade index
const NO_FACADE: int = 4                                # ... the look's own windows (RenderLook.CITY_FACADES off)
const CITY_SLOTS: int = 20                              # building.gdshader's city arrays: Art's tints, at most (city_code holds 31)
## A part's flags.
const ROOF: int = 1     # a roof facet: its own colour, no windows, gone from a shell
const PLAIN: int = 2    # no windows
const CAP: int = 4      # a top piece (a roof, a spire, a plant box): gone from a shell, and from a tower whose top floors are gone
const ORN: int = 8      # an ornament: it stands above the sim's height (wholly or with its upper part) and does not collide
const ORN_MAX: float = 0.15   # ... by at most this share of the height
const FILL: float = 0.85      # the least share of the sim's width the walls have at its height
## The crown tower's four corner stubs (Art, docs/art/city-facades.md; Legal RL-127): their side as a share of the
## tower's width, their height in floors (never more than their side), and how much lighter than the tower's mid tone
## they are, in relative luminance (the cornice's step).
const CROWN_STUB_W: float = 0.12
const CROWN_STUB_H: float = 0.9
const CROWN_STUB_LIFT: float = 0.05
## A part as an array: [x offset, z offset, width, depth, bottom, top (above the footing, of the whole building),
## top's width share, top's depth share, lean, colour, flags].
const X := 0
const Z := 1
const W := 2
const D := 3
const Y0 := 4
const Y1 := 5
const TX := 6
const TZ := 7
const LEAN := 8
const COL := 9
const FLAGS := 10
const LOOKX := 11       # the look its windows take: -1 the district's, or one of the extra looks below
const LOOKS: int = 10   # building.gdshader's look arrays: the data's looks (at most 8), then the extra ones
const STONE: int = 8    # a stone tower's few slit windows (the Gatebell's shaft, a lighthouse, a chapel's belfry)
const ROW_H: float = 150.0   # a row of windows is about this tall: a floor taller than that carries more than one row

## Each look, by its name in the data (Art's palettes, style-guide 8.1). wall: the facade's tones, light, mid, shadow;
## win: a column of windows every so many units, the pane's span across its cell, the share of cells that have one;
## pane: its span up the row, and the strips a row; glass: dark glass, bright glass, the share lit warm; trim: doors,
## shutters, frames, awnings; lot: the paved ground of its blocks and how strongly it covers the biome's (0: yards).
## flags: 1 only the top row has windows (a clerestory), 2 a door in the ground row's middle cell, 4 shutters beside a
## pane, 8 wide door panels along the ground row, 16 the contrast budget (its windows cover most of the wall, so pane
## and wall are kept within RenderLook.PATTERN_BUDGET of each other: building.gdshader 7b).
const LOOK: Dictionary = {
	"downtown": {"wall": ["#b8c0cc", "#7f8896", "#4a5261"], "roof": "#4a5261", "win": [46.0, 0.16, 0.84, 1.0], "pane": [0.07, 1.0, 1.0], "glass": ["#2c4a63", "#6aa0c0", 0.1], "trim": "#4a5261", "flags": 16, "lot": ["#7b7e86", 1.0]},
	"mid_rise": {"wall": ["#c6cdd7", "#929aa7", "#5a6270"], "roof": "#5a6270", "win": [120.0, 0.05, 0.95, 1.0], "pane": [0.16, 0.84, 2.0], "glass": ["#2c4a63", "#6aa0c0", 0.12], "trim": "#5a6270", "flags": 16, "lot": ["#7b7e86", 1.0]},
	"suburb": {"wall": ["#d9cfc0", "#b9ac8f", "#8f8468"], "roof": "#5b6474", "win": [95.0, 0.3, 0.7, 1.0], "pane": [0.34, 0.74, 1.0], "glass": ["#34425a", "#6aa0c0", 0.3], "trim": "#7a5a3c", "flags": 2, "lot": ["#8a8d86", 0.0]},
	"industrial": {"wall": ["#9ea3ab", "#8a8f98", "#5c6068"], "roof": "#6b7280", "win": [150.0, 0.04, 0.96, 1.0], "pane": [0.5, 0.86, 1.0], "glass": ["#2f2a2a", "#8a9aa6", 0.1], "trim": "#2f2a2a", "flags": 9, "lot": ["#6e7076", 1.0]},
	"harbour": {"wall": ["#eee6d6", "#d8cfbb", "#a89f8a"], "roof": "#4c6f8e", "win": [110.0, 0.3, 0.7, 0.4], "pane": [0.3, 0.8, 1.0], "glass": ["#7a5a3c", "#7a5a3c", 0.08], "trim": "#7a5a3c", "flags": 2, "lot": ["#b9ac8f", 1.0]},
	"village_harbour": {"wall": ["#eee6d6", "#ddd4c0", "#a89f8a"], "roof": "#4c6f8e", "win": [90.0, 0.34, 0.66, 1.0], "pane": [0.4, 0.72, 1.0], "glass": ["#34425a", "#6aa0c0", 0.3], "trim": "#4c6f8e", "flags": 6, "lot": ["#b9ac8f", 0.0]},
	"village_workshop": {"wall": ["#b86a55", "#a5533f", "#7a3d2f"], "roof": "#4a4a4f", "win": [90.0, 0.34, 0.66, 1.0], "pane": [0.4, 0.72, 1.0], "glass": ["#2f2a2a", "#8a7a66", 0.25], "trim": "#2f2a2a", "flags": 2, "lot": ["#a07d55", 0.0]},
	"village_hill": {"wall": ["#a3a892", "#8a8f7a", "#666b59"], "roof": "#c9a55a", "win": [110.0, 0.4, 0.6, 1.0], "pane": [0.45, 0.7, 1.0], "glass": ["#33372e", "#8a8f7a", 0.2], "trim": "#6f5a3c", "flags": 2, "lot": ["#6f8a4a", 0.0]},
}
const FALLBACK: String = "mid_rise"
## The extra looks, by index from STONE on.
const EXTRA: Array = [
	{"win": [130.0, 0.4, 0.6, 0.55], "pane": [0.3, 0.78, 1.0], "glass": ["#2b2f38", "#2b2f38", 0.1], "trim": "#4a5261", "flags": 0},
	{"win": [130.0, 0.4, 0.6, 0.0], "pane": [0.3, 0.78, 1.0], "glass": ["#2b2f38", "#2b2f38", 0.0], "trim": "#4a5261", "flags": 0},
]
const BELFRY: String = "#2b2f38"       # the Gatebell's open belfry, read as its dark inside
const SOOT: String = "#2f2a2a"
const BRICK_STACK: String = "#8a5a48"  # a chimney's brick (Art, industrial)
const SLATE: String = "#5b6474"
const LANTERN: String = "#cfe9ee"      # a lighthouse's lantern room: pale glass
const STEEL: String = "#6b7280"
const TIMBER: String = "#7a5a3c"

static var _names: Array = []
static var _marks: Array = []
static var _city: Dictionary = {}
static var _city_read: bool = false
static var _tints: Array = []
static var _dnames: Array = []


## The looks' names in the data's order (a district's look is an index into this).
static func look_names() -> Array:
	if _names.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(SETTLEMENTS))
		_names = (j as Dictionary).get("looks", []) if j is Dictionary else []
		if _names.is_empty():
			_names = [FALLBACK]
	return _names


## Building b's landmark key in the data ("bell_tower", "ledger_hall", ...), or "" for none.
static func landmark_key(b) -> String:
	var k: int = int(b.landmark)
	if k <= 0:
		return ""
	if _marks.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(SETTLEMENTS))
		for m in ((j as Dictionary).get("landmarks", []) if j is Dictionary else []):
			_marks.append(str((m as Dictionary).get("key", "")))
	return str(_marks[k - 1]) if k <= _marks.size() else "landmark"


## Look k's table (the fallback for a name with no entry here, so a look World adds is drawn, plainly, until Art has it).
static func look(k: int) -> Dictionary:
	var names: Array = look_names()
	var n: String = str(names[k]) if k >= 0 and k < names.size() else FALLBACK
	return LOOK.get(n, LOOK[FALLBACK])


## Art's city data (data/art/city-looks.json) whatever the switches say, or {} without the file: the checks and the
## shader's arrays read it.
static func city_data() -> Dictionary:
	if not _city_read:
		_city_read = true
		if FileAccess.file_exists(CITY_LOOKS):
			var j = JSON.parse_string(FileAccess.get_file_as_string(CITY_LOOKS))
			_city = j if j is Dictionary else {}
	return _city


## Art's city data as the towers wear it: {} with RenderLook.CITY_TINTS off (the facades build on the tints).
static func city() -> Dictionary:
	return city_data() if RenderLook.CITY_TINTS else {}


## Every tint in Art's data, the looks' in the data's order: [look name, tint]. A tint's index here is building.gdshader's.
static func city_tints() -> Array:
	if _tints.is_empty():
		var looks: Dictionary = city_data().get("looks", {})
		for ln in looks:
			for t in looks[ln]:
				_tints.append([str(ln), t])
	return _tints


## Every district's name in the sim's order: b.district counts the settlements' districts in the data's order.
static func district_names() -> Array:
	if _dnames.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(SETTLEMENTS))
		for s in ((j as Dictionary).get("settlements", []) if j is Dictionary else []):
			for dd in (s as Dictionary).get("districts", []):
				_dnames.append(str((dd as Dictionary).get("name", "")))
	return _dnames


## A number from 0 to 1 from a building's seed (itself one draw from 0 to 1) and a salt, well mixed, so two picks from one
## seed are independent and each covers the whole range.
static func _mix(seed: float, salt: int) -> float:
	var x: int = (int(seed * 4294967296.0) ^ (salt * 0x9E3779B1)) & 0xFFFFFFFF
	x = ((x ^ (x >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	x = ((x ^ (x >> 16)) * 0x45D9F3B) & 0xFFFFFFFF
	x = x ^ (x >> 16)
	return float(x) / 4294967296.0


## The key of `weights` that u (0 to 1) falls in, the weights taken as shares in their order; "" for none.
static func _pick(weights: Dictionary, u: float) -> String:
	var total: float = 0.0
	for k in weights:
		total += maxf(float(weights[k]), 0.0)
	var acc: float = 0.0
	for k in weights:
		acc += maxf(float(weights[k]), 0.0) / maxf(total, 0.0001)
		if u < acc:
			return str(k)
	return str(weights.keys().back()) if not weights.is_empty() else ""


## Look k as building b wears it: a downtown or mid-rise tower (not a landmark) in a district of Art's data takes a tint
## and a facade type by the district's weights, from its own seed (render only; nothing in the sim reads it): the tint's
## wall tones for the look's, the facade's windows for its "win" and "pane" (VFX's pane grid reads them; the lobby
## storey's two rows are not in them), and "tint" and "facade" (indexes into city_tints and FACADES), "base" (Art's
## lobby storey) and "crown" ([floors, setback each side], Art's set-back crown) for parts() and building.gdshader. Any other building,
## or any building without the data, wears the look as it is.
static func city_look(b, k: int) -> Dictionary:
	var lk: Dictionary = look(k)
	var c: Dictionary = city()
	var names: Array = district_names()
	var di: int = int(b.district)
	if c.is_empty() or int(b.landmark) > 0 or di < 0 or di >= names.size():
		return lk
	var dd: Dictionary = (c.get("districts", {}) as Dictionary).get(str(names[di]), {})
	var lnames: Array = look_names()
	if dd.is_empty() or k < 0 or k >= lnames.size() or str(dd.get("look", "")) != str(lnames[k]):
		return lk
	var tid: String = _pick(dd.get("tint_weights", {}), _mix(float(b.seed), 1))
	var fi: int = FACADES.find(_pick(dd.get("facade_weights", {}), _mix(float(b.seed), 2)))
	var tints: Array = city_tints()
	var ti: int = -1
	for i in range(mini(tints.size(), CITY_SLOTS)):
		if str(tints[i][0]) == str(lnames[k]) and str((tints[i][1] as Dictionary).get("id", "")) == tid:
			ti = i
	if ti < 0 or fi < 0:
		return lk
	var wl: Dictionary = (tints[ti][1] as Dictionary)["wall"]
	var out: Dictionary = lk.duplicate()
	out["wall"] = [str(wl["light"]), str(wl["mid"]), str(wl["shadow"])]
	out["roof"] = str(wl["shadow"])
	out["trim"] = str(wl["shadow"])
	out["tint"] = ti
	out["facade"] = fi if RenderLook.CITY_FACADES else NO_FACADE
	if not RenderLook.CITY_FACADES:
		return out
	# The facade's windows as a look's (what building.gdshader draws from fac_a and fac_b), for VFX's pane grid.
	var fu: Dictionary = city_uniforms()
	var fa: Vector4 = fu["fac_a"][fi]
	var fb: Vector4 = fu["fac_b"][fi]
	out["win"] = [float(lk["win"][0]) * fa.x, fa.y, fa.z, fa.w]
	if FACADES[fi] == "balconied":
		out["win"] = [float(lk["win"][0]) * fa.x * 0.5, 0.5 - 0.5 * fa.z, 0.5 + 0.5 * fa.z, fa.w]   # the pair as two even panes: near enough for the pane grid
	out["pane"] = [fb.x, fb.y, 1.0]
	var bc: Dictionary = c.get("base_and_crown", {})
	out["base"] = bc.has("base") and int(b.floors) >= RenderLook.CITY_BASE_FLOORS
	if bc.has("crown") and int(b.floors) >= RenderLook.CITY_CROWN_FLOORS and ["shaft", "slab", "block"].has(str(b.shape)):
		out["crown"] = [float((bc["crown"] as Dictionary).get("floors", 2)), float((bc["crown"] as Dictionary).get("setback", 0.06))]
	return out


## What building.gdshader reads of a building's city look (win_tex's fifth texel, a, a 32-bit float): 0 for none; else 1
## plus its tint (up to 30), plus 32 times its facade (NO_FACADE: the look's own windows), plus 256 with a lobby storey,
## plus 512 times the floor its crown starts at.
static func city_code(lk: Dictionary, floors: int) -> float:
	if not lk.has("tint"):
		return 0.0
	var code: int = 1 + int(lk["tint"]) + 32 * int(lk["facade"]) + (256 if bool(lk.get("base", false)) else 0)
	if lk.has("crown"):
		code += 512 * maxi(floors - int(lk["crown"][0]), 0)
	return float(code)


## c's relative luminance (c in sRGB; worked out in linear light).
static func _lum(c: Color) -> float:
	var l: Color = c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


## c scaled by k in linear light, at its own hue (sRGB in and out).
static func _scaled(c: Color, k: float) -> Color:
	var l: Color = c.srgb_to_linear()
	return Color(minf(l.r * k, 1.0), minf(l.g * k, 1.0), minf(l.b * k, 1.0), c.a).linear_to_srgb()


## Art's tints and facade types for building.gdshader (7c). A tower is massed in its look's shadow tone (7b), and Art drew
## its facade on the mid tone, so each tint's glass and trim are scaled by the shadow's luminance over the mid's, and its
## spandrels, fins and lobby storey are given as multiples of the wall (the luminance Art set them at over the mid's):
## Art's hues and ratios, at the values the towers have today. city_glass, city_hi: dark and bright glass (a: the lobby
## storey's wall); city_trim: the cornice and lintel; city_k: a ribbon's spandrel, a punched one's, a fin, a fin's sun
## side; city_k2: the balconied facade's spandrel and its slab line. fac_a, fac_b, fac_c: each facade type's column (a
## multiple of the look's), its pane across the cell and up the floor, its spandrel's band up the floor and a fin's half
## width (balconied: fac_a's y and z are the pair's gap and a pane's width as shares of half the cell, and fac_c.w is
## the slab line's height up the floor, under every second floor). city_base: the lobby storey in floors, its lintel.
static func city_uniforms() -> Dictionary:
	var glass: Array = []
	var hi: Array = []
	var trim: Array = []
	var kk: Array = []
	var kk2: Array = []
	var c: Dictionary = city_data()
	var tints: Array = city_tints()
	var fac: Dictionary = c.get("facades", {})
	var bc: Dictionary = c.get("base_and_crown", {})
	var rib: Dictionary = fac.get("ribbon", {})
	var pun: Dictionary = fac.get("punched", {})
	var fin: Dictionary = fac.get("fins", {})
	var bal: Dictionary = fac.get("balconied", {})
	var off_bal: float = float((bal.get("spandrel", {}) as Dictionary).get("lum_offset", 0.0))
	var off_slab: float = float((bal.get("_slab", {}) as Dictionary).get("lum_offset", 0.0))
	var off_rib: float = float((rib.get("spandrel", {}) as Dictionary).get("lum_offset", 0.0))
	var off_pun: float = float((pun.get("spandrel", {}) as Dictionary).get("lum_offset", 0.0))
	var off_fin: float = float((fin.get("fin", {}) as Dictionary).get("lum_offset", 0.0))
	var off_sun: float = float((fin.get("fin", {}) as Dictionary).get("sun_side_offset", 0.0))
	var off_base: float = float((bc.get("base", {}) as Dictionary).get("wall_lum_offset", 0.0))
	for i in range(CITY_SLOTS):
		if i >= tints.size():
			glass.append(Color(0, 0, 0, 1))
			hi.append(Color(0, 0, 0, 1))
			trim.append(Color(0, 0, 0, 1))
			kk.append(Vector4(1, 1, 1, 1))
			kk2.append(Vector4(1, 1, 1, 1))
			continue
		var t: Dictionary = tints[i][1]
		var lm: float = maxf(_lum(_c(t["wall"]["mid"])), 0.0001)
		var s: float = _lum(_c(t["wall"]["shadow"])) / lm
		var gd: Color = _scaled(_c(t["glass"]["dark"]), s)
		glass.append(Color(gd.r, gd.g, gd.b, (lm + off_base) / lm))
		hi.append(_scaled(_c(t["glass"]["bright"]), s))
		trim.append(_scaled(_c(t["trim"]), s))
		kk.append(Vector4((lm + off_rib) / lm, (lm + off_pun) / lm, (lm + off_fin) / lm, (lm + off_sun) / lm))
		kk2.append(Vector4((lm + off_bal) / lm, (lm + off_slab) / lm, 1.0, 1.0))
	var pw: Vector4 = RenderLook.FACADE_PITCH
	var rib_w: float = 1.0 - float(rib.get("pier_w", 0.05))
	var rib_s: float = float((rib.get("spandrel", {}) as Dictionary).get("h", 0.45))
	var pun_w: float = float(pun.get("pane_w", 0.38))
	var pun_s: float = float((pun.get("spandrel", {}) as Dictionary).get("h", 0.3))
	var fin_w: float = float(fin.get("pane_w", 0.78))
	var bal_w: float = float(bal.get("pane_w", 0.34))
	var bal_s: float = float((bal.get("spandrel", {}) as Dictionary).get("h", 0.25))
	var bal_slab: float = float((bal.get("_slab", {}) as Dictionary).get("h", 0.12))
	var fa: Array = [
		Vector4(pw.x, 0.5 - 0.5 * rib_w, 0.5 + 0.5 * rib_w, 1.0),
		Vector4(pw.y, 0.5 - 0.5 * pun_w, 0.5 + 0.5 * pun_w, 1.0),
		Vector4(pw.z, 0.5 - 0.5 * fin_w, 0.5 + 0.5 * fin_w, 1.0),
		Vector4(pw.w, RenderLook.BALCONY_PAIR_GAP, 2.0 * bal_w, 1.0),
	]
	var fb: Array = [
		Vector4(rib_s, minf(rib_s + float(rib.get("pane_h", 0.55)), 1.0), 1.0, 16.0),
		Vector4(pun_s, minf(pun_s + float(pun.get("pane_h", 0.5)), 1.0), 1.0, 16.0),
		Vector4(0.0, 1.0, 1.0, 16.0),
		Vector4(bal_s, minf(bal_s + float(bal.get("pane_h", 0.5)), 1.0), 1.0, 16.0),
	]
	var fc: Array = [
		Vector4(0.0, rib_s, 0.0, 0.0),
		Vector4(0.0, pun_s, 0.0, 0.0),
		Vector4(0.0, 0.0, 0.5 * float((fin.get("fin", {}) as Dictionary).get("w", 0.14)), 0.0),
		Vector4(0.0, bal_s, 0.0, bal_slab),
	]
	return {"city_glass": glass, "city_hi": hi, "city_trim": trim, "city_k": kk, "city_k2": kk2, "fac_a": fa, "fac_b": fb, "fac_c": fc,
		"city_base": Vector4(float((bc.get("base", {}) as Dictionary).get("floors", 1.6)), RenderLook.CITY_LINTEL, RenderLook.CITY_CORNICE, float(RenderLook.CITY_BASE_ROWS)),
		"city_base_pane": RenderLook.CITY_BASE_PANE}


## The look index of the district building b stands in (the lane table's), 0 with no table.
static func look_of(t: PackedFloat32Array, b) -> int:
	if t.size() < RenderLanes.HEADER:
		return 0
	var k: int = int(b.district)
	if k < 0 or k >= int(t[3]):
		return 0
	return int(t[int(t[12]) + 6 * k + 2])


static func _c(hex: String) -> Color:
	return RenderLook.col(hex)


static func _p(x: float, z: float, w: float, d: float, y0: float, y1: float, col: Color, flags: int = 0, tx: float = 1.0, tz: float = 1.0, lean: float = 0.0, lookx: int = -1) -> Array:
	return [x, z, w, d, y0, y1, tx, tz, lean, col, flags, lookx]


## col with its relative luminance raised by dl, at the same hue (Art's steps are in luminance).
static func _lift(col: Color, dl: float) -> Color:
	var lin: Color = col.srgb_to_linear()
	var l: float = 0.2126 * lin.r + 0.7152 * lin.g + 0.0722 * lin.b
	var k: float = (l + dl) / maxf(l, 0.0001)
	return Color(minf(lin.r * k, 1.0), minf(lin.g * k, 1.0), minf(lin.b * k, 1.0), col.a).linear_to_srgb()


## How many rows of windows a floor of height fh carries.
static func rows(fh: float) -> int:
	return maxi(1, int(round(fh / ROW_H)))


## Building b's parts as it stands whole, the body first (it carries the building's index and is never hidden while the
## building stands). lk: its district's look (look()); depth: its footprint's depth as drawn. Deterministic from the building's own numbers: its tone and the
## side an off-centre piece sits on come from b.seed.
static func parts(b, lk: Dictionary, depth: float = -1.0) -> Array:
	var w: float = b.w
	var d: float = depth if depth > 0.0 else maxf(b.d, 1.0)
	var h: float = maxf(b.h, 1.0)
	var fh: float = h / float(maxi(int(b.floors), 1))
	var tones: Array = lk["wall"]
	var u: float = fposmod(float(b.seed) * 0.6180339887, 1.0)
	var side: float = -1.0 if fposmod(float(b.seed) * 0.3819660113, 1.0) < 0.5 else 1.0
	var wall: Color = _c(tones[0] if u < 0.45 else tones[1])
	var dark: Color = _c(tones[2])
	if (int(lk["flags"]) & 16) != 0:
		# A look with the contrast budget (the tall glass towers): the mass is the shadow tone, as dark as a burnt-out
		# tower is, so a street of whole and damaged towers is one value under a fast camera; the lighter tones are trim.
		wall = _c(tones[2])
		dark = _c(tones[1])
	var roof: Color = _c(lk["roof"])
	var trim: Color = _c(lk["trim"])
	var out: Array = []
	var shape: String = str(b.shape)
	var mark: String = landmark_key(b)
	var orn: float = ORN_MAX * h
	var plant: float = minf(clampf(0.4 * fh, 24.0, 70.0), orn)
	match shape:
		"stepped":
			# Two setbacks, the top tier still 86 percent of the base: the steps show and the box is full.
			var a_top: float = _snap(h * 0.45, fh)
			var b_top: float = _snap(h * 0.74, fh)
			if mark == "ledger_hall":
				# The ledger hall: a broad stepped hall of pale stone, a dark arcade at the street, a pale ledge at
				# each setback, and a low stepped cap above. Generic: no real building.
				var stone: Color = _c(tones[0])
				var ledge: Color = _c("#d5d9df")
				out.append(_p(0.0, 0.0, w * 0.86, d * 0.9, 0.0, h, stone, 0, 1.0, 1.0, 0.0, STONE))
				out.append(_p(0.0, 0.0, w, d, 0.0, a_top, stone, 0, 1.0, 1.0, 0.0, STONE))
				out.append(_p(0.0, 0.0, w * 0.93, d * 0.95, 0.0, b_top, stone, 0, 1.0, 1.0, 0.0, STONE))
				out.append(_p(0.0, d * 0.5 + 4.0, w * 0.98, 8.0, 0.0, minf(fh, a_top), _c(BELFRY), PLAIN))
				out.append(_p(0.0, 3.0, w * 0.999, d + 6.0, a_top - 0.18 * fh, a_top, ledge, PLAIN))
				out.append(_p(0.0, 3.0, w * 0.929, d * 0.95 + 6.0, b_top - 0.18 * fh, b_top, ledge, PLAIN))
				out.append(_p(0.0, 3.0, w * 0.859, d * 0.9 + 6.0, h - 0.18 * fh, h, ledge, PLAIN | CAP))
				out.append(_p(0.0, 0.0, w * 0.6, d * 0.62, h, h + orn * 0.5, stone, PLAIN | CAP | ORN))
				out.append(_p(0.0, 0.0, w * 0.34, d * 0.36, h + orn * 0.5, h + orn, ledge, PLAIN | CAP | ORN))
			else:
				out.append(_p(0.0, 0.0, w * 0.86, d * 0.9, 0.0, h, wall))
				out.append(_p(0.0, 0.0, w, d, 0.0, a_top, wall))
				out.append(_p(0.0, 0.0, w * 0.93, d * 0.95, 0.0, b_top, wall))
				out.append(_p(side * w * 0.08, 0.0, w * 0.3, d * 0.3, h, h + plant, dark, PLAIN | CAP | ORN))
		"crown":
			# A chamfer the box still fills (86 percent at the top), and the cut gem above it.
			var c: float = clampf(0.5 * w, fh, 0.1 * h)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - c, wall))
			out.append(_p(0.0, 0.0, w, d, h - c, h, _c(tones[1]), PLAIN | CAP, 0.86, 0.86))
			if mark == "crown_tower":
				# The crown tower: a pale band under the chamfer and a crown above it, a low gem between four short
				# square stubs on the corners of the chamfer's top (Legal RL-127: four thin pale points read from the
				# front as two horns; Art's shape, docs/art/city-facades.md): no taper, no taller than wide, in the
				# tower's mid tone lifted by CROWN_STUB_LIFT of luminance, so from the front they read as a battlement.
				out.append(_p(0.0, 3.0, w * 0.999, d + 6.0, h - c - 0.2 * fh, h - c, _c("#d5d9df"), PLAIN | CAP))
				out.append(_p(0.0, 0.0, w * 0.6, d * 0.6, h, h + orn * 0.55, _c(tones[1]), PLAIN | CAP | ORN, 0.5, 0.5))
				var st: float = CROWN_STUB_W * minf(w, d)
				var stub: Color = _lift(_c(tones[1]), CROWN_STUB_LIFT)
				for sx in [-1.0, 1.0]:
					for sz in [-1.0, 1.0]:
						out.append(_p(sx * (0.43 * w - 0.5 * st), sz * (0.43 * d - 0.5 * st), st, st, h, h + minf(CROWN_STUB_H * fh, st), stub, PLAIN | CAP | ORN))
			else:
				out.append(_p(0.0, 0.0, w * 0.86, d * 0.86, h, h + orn * 0.6, _c(tones[1]), PLAIN | CAP | ORN, 0.55, 0.55))
		"spire":
			# A shaft the whole height of the box, and the spire above it: never a needle (no taller than 15 percent).
			if mark == "bell_tower":
				# The Gatebell (Art, Legal RL-040): a stone shaft, an open belfry, a spire, one stair bump; no clock face.
				var bel: float = clampf(0.5 * w, fh, 0.08 * h)
				out.append(_p(0.0, 0.0, w, d, 0.0, h - bel, _c(tones[0]), 0, 1.0, 1.0, 0.0, STONE))
				out.append(_p(0.0, 0.0, w * 0.9, d * 0.9, h - bel, h, _c(BELFRY), PLAIN | CAP))
				out.append(_p(0.0, 3.0, w * 0.999, d + 6.0, h - bel - 0.12 * bel, h - bel, _c("#d5d9df"), PLAIN | CAP))
				out.append(_p(0.0, 3.0, w * 0.999, d + 6.0, h - 0.12 * bel, h, _c("#d5d9df"), PLAIN | CAP))
				out.append(_p(0.0, 0.0, w * 0.96, d * 0.96, h, h + orn, roof, ROOF | CAP | ORN, 0.02, 0.02))
				out.append(_p(side * w * 0.3, d * 0.5 + 12.0, w * 0.2, 24.0, 0.0, _snap(h * 0.06, fh), _c(tones[1]), 0, 1.0, 1.0, 0.0, STONE))
			else:
				out.append(_p(0.0, 0.0, w, d, 0.0, h, wall))
				out.append(_p(0.0, 0.0, w * 0.94, d * 0.94, h, h + minf(orn, 0.75 * w), roof, ROOF | CAP | ORN, 0.02, 0.02))
		"slab", "block", "shaft":
			var cr: Array = lk.get("crown", [])
			if cr.is_empty():
				out.append(_p(0.0, 0.0, w, d, 0.0, h, wall))
			else:
				# Art's crown (docs/art/city-facades.md): the top floors set back each side. The core is the body and
				# stands the whole height; the shaft round it stops under the crown, as a stepped tower's skirts do.
				var sb: float = 1.0 - 2.0 * float(cr[1])
				out.append(_p(0.0, 0.0, w * sb, d * sb, 0.0, h, wall))
				out.append(_p(0.0, 0.0, w, d, 0.0, h - float(cr[0]) * fh, wall))
			out.append(_p(side * w * (0.22 if shape == "block" else 0.12), 0.0, w * (0.34 if shape == "block" else 0.42), d * 0.36, h, h + plant, dark, PLAIN | CAP | ORN))
		"warehouse":
			var rise: float = 0.13 * d
			var up: float = minf(orn, rise)
			var dn: float = minf(rise - up, 0.1 * h)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - dn, wall))
			out.append(_p(0.0, 0.0, w * 1.02, d * 1.04, h - dn, h + up, roof, ROOF | CAP | ORN, 1.0, 0.03))
		"sawtooth":
			var rise: float = clampf(0.2 * h, 30.0, 120.0)
			var up: float = minf(orn, rise)
			var dn: float = minf(rise - up, 0.1 * h)
			var n: int = clampi(int(round(w / 190.0)), 2, 5)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - dn, wall))
			for i in range(n):
				out.append(_p((float(i) + 0.5) / float(n) * w - 0.5 * w, 0.0, w / float(n), d, h - dn, h + up, roof, ROOF | CAP | ORN, 1.0, 1.0, 1.0))
		"chimney":
			# A stack whose taper the box still fills, and its flared cap above.
			var tp: float = 0.86
			out.append(_p(0.0, 0.0, w, d, 0.0, h, _c(BRICK_STACK), PLAIN, tp, tp))
			out.append(_p(0.0, 0.0, w * tp * 1.02, d * tp * 1.02, h, h + minf(orn, clampf(0.03 * h, 24.0, 110.0)), _c(SOOT), PLAIN | CAP | ORN, 1.12, 1.12))
			if mark != "":
				# The stack (Art, Legal): pale stone and soot bands, a flared cap, a short side flue. No red and white.
				(out[0] as Array)[COL] = _c("#b9b2a4")
				for band in [[0.3, 0.37], [0.58, 0.65]]:
					var w0: float = 1.0 - (1.0 - tp) * float(band[0])
					var w1: float = 1.0 - (1.0 - tp) * float(band[1])
					out.append(_p(0.0, 0.0, w * w0 * 0.999, d * w0 * 1.03, h * float(band[0]), h * float(band[1]), _c(SOOT), PLAIN, w1 / w0, w1 / w0))
				out.append(_p(side * w * 0.2, d * 0.5 + 10.0, w * 0.16, 20.0, 0.0, h * 0.28, _c(SOOT), PLAIN))
		"lighthouse":
			# A tapering tower in two wide bands the box still fills, and above it a gallery, a lantern room of pale
			# glass and a low cone. No stripe, no beam.
			var tp: float = 0.86
			out.append(_p(0.0, 0.0, w, d, 0.0, h, _c(tones[0]), 0, tp, tp, 0.0, STONE))
			var w0: float = 1.0 - (1.0 - tp) * 0.4
			var w1: float = 1.0 - (1.0 - tp) * 0.66
			out.append(_p(0.0, 0.0, w * w0 * 0.999, d * w0 * 1.03, 0.4 * h, 0.66 * h, _c(SLATE), PLAIN, w1 / w0, w1 / w0))
			out.append(_p(0.0, 0.0, w * tp * 1.12, d * tp * 1.12, h, h + 0.12 * orn, dark, PLAIN | CAP | ORN))
			out.append(_p(0.0, 0.0, w * tp * 0.74, d * tp * 0.74, h + 0.12 * orn, h + 0.62 * orn, _c(LANTERN), PLAIN | CAP | ORN))
			out.append(_p(0.0, 0.0, w * tp * 0.9, d * tp * 0.9, h + 0.62 * orn, h + orn, _c(SLATE), ROOF | CAP | ORN, 0.02, 0.02))
		"house", "shop", "thatch":
			# A gable whose end faces the street. Its ridge stands above the sim's height and its eaves a little under
			# it: 35 to 40 degrees where the house's height allows, a thatch steeper with deep eaves.
			var steep: bool = shape == "thatch"
			var rise: float = (0.71 if steep else 0.377) * w
			var up: float = minf(orn, rise)
			var dn: float = minf(rise - up, (0.12 if steep else 0.1) * h)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - dn, wall))
			out.append(_p(0.0, 0.0, w * (1.22 if steep else 1.08), d * 1.04, h - dn, h + up, roof, ROOF | CAP | ORN, 0.02, 1.0))
			if shape == "shop" and fh * 0.92 < h - dn:
				out.append(_p(0.0, d * 0.5 + 20.0, w * 0.96, 40.0, fh * 0.86, fh * 0.92, trim, PLAIN))
		"terrace":
			# Two stone steps up a slope, the upper one under a steep roof.
			var up: float = minf(orn, 0.36 * w)
			var dn: float = minf(0.36 * w - up, 0.1 * h)
			out.append(_p(side * w * 0.24, 0.0, w * 0.52, d, 0.0, h - dn, wall))
			out.append(_p(side * w * 0.24, 0.0, w * 0.58, d * 1.04, h - dn, h + up, roof, ROOF | CAP | ORN, 0.02, 1.0))
			out.append(_p(-side * w * 0.26, 0.0, w * 0.48, d, 0.0, 0.58 * h, _c(tones[1])))
		"hall":
			# A long gable, its slope to the street, with a porch.
			var rise: float = 0.42 * d
			var up: float = minf((0.6 if mark != "" else 1.0) * orn, rise)
			var dn: float = minf(rise - up, 0.1 * h)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - dn, wall))
			out.append(_p(0.0, 0.0, w * 1.04, d * 1.06, h - dn, h + up, roof, ROOF | CAP | ORN, 1.0, 0.02))
			var ph: float = minf(0.42 * h, h - dn)
			out.append(_p(0.0, d * 0.5 + 30.0, w * 0.3, 60.0, 0.0, ph * 0.78, _c(tones[1]), PLAIN))
			out.append(_p(0.0, d * 0.5 + 30.0, w * 0.34, 66.0, ph * 0.78, ph, roof, ROOF, 0.02, 1.0))
			if mark != "":
				out.append(_p(0.0, 0.0, w * 0.09, w * 0.09, h + 0.3 * orn, h + orn, _c(tones[0]), PLAIN | CAP | ORN))   # the hall's ridge lantern
		"chapel":
			# A gable with a small belfry at one end (the belfry's own cap above the sim's height).
			var nave: float = 0.72 * h
			var rh: float = minf(0.55 * w * 0.74, 0.4 * nave)
			out.append(_p(-side * w * 0.13, 0.0, w * 0.74, d, 0.0, nave - rh, wall))
			out.append(_p(-side * w * 0.13, 0.0, w * 0.8, d * 1.04, nave - rh, nave, roof, ROOF | CAP, 0.02, 1.0))
			out.append(_p(side * w * 0.37, 0.0, w * 0.26, minf(d, w * 0.26), 0.0, h, _c(tones[1]), 0, 1.0, 1.0, 0.0, STONE))
			out.append(_p(side * w * 0.37, 0.0, w * 0.2, minf(d, w * 0.2), 0.84 * h, 0.94 * h, _c(BELFRY), PLAIN))
			out.append(_p(side * w * 0.37, 0.0, w * 0.26, minf(d, w * 0.26), h, h + orn, roof, ROOF | CAP | ORN, 0.02, 0.02))
		"shed":
			var rise: float = 0.28 * h
			var up: float = minf(orn, 0.6 * rise)
			var dn: float = minf(rise - up, 0.1 * h)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - dn, wall))
			out.append(_p(0.0, 0.0, w * 1.04, d * 1.04, h - dn, h + up, roof, ROOF | CAP | ORN, 1.0, 1.0, side))
		"quay":
			out.append(_p(0.0, 0.0, w, d, 0.0, 0.55 * h, _c(tones[2]), PLAIN))
			for i in range(4):
				out.append(_p((float(i) + 0.5) / 4.0 * w - 0.5 * w, d * 0.4, 16.0, 16.0, 0.55 * h, h, _c(TIMBER), PLAIN | CAP))
		"crane":
			# A mast a little off centre, a long jib, a cab.
			var t: float = clampf(0.14 * w, 12.0, 60.0)
			out.append(_p(-side * w * 0.18, 0.0, t, minf(d, t), 0.0, 0.93 * h, _c(STEEL), PLAIN))
			out.append(_p(side * w * 0.02, 0.0, w * 0.96, minf(d, t * 0.6), 0.93 * h, h, _c(STEEL), PLAIN | CAP))
			out.append(_p(-side * w * 0.18, 0.0, t * 1.7, minf(d, t * 1.5), 0.84 * h, 0.93 * h, trim, PLAIN | CAP))
		"mast":
			var t: float = clampf(0.1 * w, 8.0, 30.0)
			out.append(_p(0.0, 0.0, t, minf(d, t), 0.0, h, _c(TIMBER), PLAIN))
			out.append(_p(side * w * 0.04, 0.0, w * 0.9, minf(d, t * 0.6), 0.78 * h, 0.78 * h + minf(0.03 * h, 30.0), _c(TIMBER), PLAIN))
		_:
			out.append(_p(0.0, 0.0, w, d, 0.0, h, wall))   # a shape with no builder yet: the sim's box, plainly
	return out


static func _snap(y: float, fh: float) -> float:
	return maxf(fh, round(y / fh) * fh)


## Which of a building's parts is its shell at the street: the widest walled box that stands on the ground, centred on
## the footprint. A lobby's colonnade is this part's (RenderLook.OPEN_*); every other part that reaches the lobby is
## inside it or stuck onto it. 0 (the body) when none qualifies.
static func shell(ps: Array) -> int:
	var best: int = 0
	var area: float = -1.0
	for j in range(ps.size()):
		var p: Array = ps[j]
		if float(p[Y0]) > 0.0 or (int(p[FLAGS]) & ROOF) != 0 or absf(float(p[X])) > 1.0 or absf(float(p[Z])) > 1.0:
			continue
		var a: float = float(p[W]) * float(p[D])
		if a > area:
			area = a
			best = j
	return best


## From what height over the building's footing part j is its outermost wall: the top of the tallest part that is
## wider than it (a stepped tower's skirts stand outside its core up to their tops), 0 for the shell at the street.
## There the part carries the frame's columns in a cleared floor (building.gdshader). A part that is not a centred,
## walled box (a roof, a porch, a stair bump, a ledge) never does: a huge number.
static func outer_from(ps: Array, j: int) -> float:
	var p: Array = ps[j]
	if (int(p[FLAGS]) & ROOF) != 0 or absf(float(p[X])) > 1.0 or absf(float(p[Z])) > 1.0:
		return 1.0e9
	var a: float = float(p[W]) * float(p[D])
	var y: float = 0.0
	for i in range(ps.size()):
		var q: Array = ps[i]
		if i == j or (int(q[FLAGS]) & ROOF) != 0 or absf(float(q[X])) > 1.0 or absf(float(q[Z])) > 1.0:
			continue
		if float(q[W]) * float(q[D]) > a + 0.5 and float(q[Y0]) <= float(p[Y0]) + 0.5:
			y = maxf(y, float(q[Y1]))
	return y


## Whether a building of this shape has a lobby to open (RenderLook.OPEN_SHAPES): the towers with straight walls. A
## tapered stack, a lighthouse, a hall and a chapel do not, whatever their floors.
static func has_lobby(shape: String) -> bool:
	return RenderLook.OPEN_SHAPES.has(shape)


## A part as it stands now. H: the building's standing height (WorldStructures.curH); h: its full height; stage: the
## damage stage it is drawn at; cut: a tower whose top floors are gone (it loses its caps and is cut off at H; any other
## building is scaled down with its hit points, as the sim's height is). Returns [bottom, top] above the footing, or an
## empty array when the part does not show.
static func span(p: Array, body: bool, H: float, h: float, stage: int, cut: bool) -> Array:
	var f: int = int(p[FLAGS])
	if (f & CAP) != 0 and (stage >= 3 or cut):
		return []
	if (f & ROOF) != 0 and stage >= 3:
		return []
	var y0: float = float(p[Y0])
	var y1: float = float(p[Y1])
	if cut:
		if y0 >= H - 1.0:
			return []
		y1 = minf(y1, H)
	else:
		var s: float = H / maxf(h, 1.0)
		y0 *= s
		y1 *= s
	if body and (stage >= 3 or cut):
		y1 = H   # a shell, and a cut tower, stand as tall as the sim says with nothing on top
	return [y0, y1] if y1 > y0 + 0.5 else []


## The looks' window numbers for building.gdshader, a vec4 a look: [pitch, pane from, pane to (across the cell), the
## share of cells with a window], [pane from, to (up the row), strips a row, flags], glass (rgb) and the share lit,
## bright glass (rgb), trim (rgb).
static func look_uniforms() -> Dictionary:
	var a: Array = []
	var bb: Array = []
	var glass: Array = []
	var hi: Array = []
	var trim: Array = []
	var names: Array = look_names()
	for k in range(LOOKS):
		var lk: Dictionary = (look(k) if k < names.size() else LOOK[FALLBACK]) if k < STONE else EXTRA[mini(k - STONE, EXTRA.size() - 1)]
		a.append(Vector4(float(lk["win"][0]), float(lk["win"][1]), float(lk["win"][2]), float(lk["win"][3])))
		bb.append(Vector4(float(lk["pane"][0]), float(lk["pane"][1]), float(lk["pane"][2]), float(lk["flags"])))
		var g: Color = _c(lk["glass"][0])
		glass.append(Color(g.r, g.g, g.b, float(lk["glass"][2])))
		hi.append(_c(lk["glass"][1]))
		trim.append(_c(lk["trim"]))
	return {"look_a": a, "look_b": bb, "look_glass": glass, "look_hi": hi, "look_trim": trim}


## The looks' paved ground for the ground shader: rgb, and how strongly it covers the biome's ground in a block (0: yards).
static func lot_colours() -> Array:
	var out: Array = []
	var names: Array = look_names()
	for k in range(8):
		var lk: Dictionary = look(k) if k < names.size() else LOOK[FALLBACK]
		var c: Color = _c(lk["lot"][0])
		out.append(Color(c.r, c.g, c.b, float(lk["lot"][1])))
	return out
