class_name RenderBiomeLook
extends RefCounted
## Art's biome look (docs/art/biomes.md, data/art/biomes.json) for the ground's shaders (biome rendering window 1;
## docs/rendering/biomes.md): one small palette texture, a column per biome and a row per tone. The columns are World's
## fine biomes by their ids (data/biomes/climate.json "fine": FINE), then the render's own city and village (Art draws
## none). Each is Art's entry under its name; until Art's data carries every fine name, Art's older name for it (OLD) or
## its stored alias (ALIAS: World's fallback for a consumer that knows only the stored seven). The rows: the ground's
## lit, mid and shade faces; the rock's; the subsoil's (a crater's inside: Art's lite 0.14, the subsoil, Art's dark 0.3);
## a beam's scar band and its edge; and in the last row, red: whether the biome's rock carries strata lines (desert,
## mountains, volcanic, highland), green: the height above which its ground is rock whatever its slope (ROCK_ABOVE, in
## tens of thousands of units; Art's mountains are green only at the foot). The render's own biome names
## (GroundField.BIOME_ORDER) map onto these by id_of. Window 2: rows COVER_ROW to COVER_ROW + 15 hold the cover's 16
## palette slots for the biome (RenderCoverMeshes: vegetation, secondary and rock, each lit, mid and shade; trunk;
## accent; char; ash; shallow water; the ground's lit and shade, the whites and slates of the ices).

const DATA_PATH := "res://data/art/biomes.json"
const FINE: Array = ["ocean", "plains", "forest", "desert", "mountains", "ice_sheet", "sea_ice", "jungle", "savanna", "tundra", "taiga", "wetland", "beach", "highland", "volcanic"]
const ALIAS: Dictionary = {"ice_sheet": "mountains", "sea_ice": "plains", "jungle": "forest", "savanna": "plains", "tundra": "plains", "taiga": "forest", "wetland": "plains", "beach": "desert", "highland": "mountains", "volcanic": "mountains"}
const OLD: Dictionary = {"ice_sheet": "ice", "sea_ice": "seaice"}
const CITY: int = 15
const VILLAGE: int = 16
const COUNT: int = 17
const WIDTH: int = 32
const ROW_GROUND: int = 0    # lit, mid, shade
const ROW_ROCK: int = 3      # lit, mid, shade
const ROW_SUB: int = 6       # lit, mid, shade
const ROW_SCAR: int = 9      # the band, then its edge
const ROW_STRATA: int = 11   # red 1: the rock carries strata lines; green: ROCK_ABOVE / 10,000
const COVER_ROW: int = 12  # the cover's slots (RenderCoverMeshes.SLOTS of them)
const ROWS: int = 28
const LITE := "#fff6e0"      # Art's lite() and dark() (art/concepts/biomes/draw.mjs)
const DARK := "#0c0a14"
const STRATA: Array = ["desert", "mountains", "volcanic", "highland"]
const SCAR_DEFAULT: Array = ["#221c18", "#4a4036"]
const ROCK_ABOVE: Dictionary = {"mountains": 900.0, "highland": 700.0}   # units: above this the ground is rock

static var _tex: ImageTexture = null
static var _data = null
static var _loaded: bool = false


## Art's data (data/art/biomes.json), read once; null when it is missing.
static func data():
	if not _loaded:
		_loaded = true
		_data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
	return _data


## Art's entry for a biome by name: its own, else Art's older name for it, else its stored alias's; {} for none (the
## city, the village, or no data).
static func entry(name: String) -> Dictionary:
	var d = data()
	if d is Dictionary and d.get("biomes") is Dictionary:
		for key in [name, OLD.get(name, ""), ALIAS.get(name, "")]:
			if key != "" and d.biomes.has(key):
				return d.biomes[key]
	return {}


## A palette column's biome name (a fine name, "city" or "village").
static func name_of(id: int) -> String:
	return FINE[id] if id >= 0 and id < FINE.size() else ("city" if id == CITY else "village")


## The palette column of a biome by name: one of World's fine names, or the render's own (GroundField.BIOME_ORDER: the
## stored five, the city, the village). A fine biome's column is its fine id.
static func id_of(name: String) -> int:
	if name == "city":
		return CITY
	if name == "village":
		return VILLAGE
	var i: int = FINE.find(name)
	return i if i >= 0 else FINE.find("plains")


## The palette texture (made once): RGBA8, sRGB colours as the data writes them (the shaders read it as a source colour).
static func texture() -> ImageTexture:
	if _tex == null:
		var d = data()
		var img := Image.create_empty(WIDTH, ROWS, false, Image.FORMAT_RGBA8)
		for k in range(COUNT):
			var t: Array = tones(d, k)
			for r in range(COVER_ROW):
				img.set_pixel(k, r, t[r])
			var e: Dictionary = entry(name_of(k))
			if e.is_empty():
				e = entry("plains")   # the city's and the village's cover, if any stands there, in the plains' colours
			if e.get("palette") is Dictionary:
				var sc: PackedColorArray = RenderCoverMeshes.slot_colours(e.palette)
				for r in range(sc.size()):
					img.set_pixel(k, COVER_ROW + r, sc[r])
		_tex = ImageTexture.create_from_image(img)
	return _tex


## Biome k's ROWS colours: Art's entry for the fine biome (its own name, else Art's older name, else its alias's); for the
## city and the village, the render's own colour as the mid face with Art's lite and dark for the others, and a
## neighbour's rock and subsoil. Without the data, the render's own biome colours.
static func tones(d, k: int) -> Array:
	var name: String = name_of(k)
	var b: Dictionary = entry(name) if d is Dictionary else {}
	var g: Array = []
	var r: Array = []
	var sub: String = ""
	var scar: Array = SCAR_DEFAULT
	if not b.is_empty():
		g = b.palette.ground
		r = b.palette.rock
		sub = b.palette.subsoil
		if b.get("scar") is Dictionary:
			scar = [b.scar.fill, b.scar.edge]
	else:
		var mid: String = RenderLook.BIOME.get(name, RenderLook.BIOME.get(ALIAS.get(name, "plains"), "#5f9140"))
		g = [_mix(mid, LITE, 0.14), mid, _mix(mid, DARK, 0.25)]
		r = ["#908a77", "#7e7a6e", "#5a574e"]
		sub = "#5c574f" if name == "city" else "#6b5338"
	var out: Array = []
	for h in g + r:
		out.append(RenderLook.col(h))
	out.append_array([RenderLook.col(_mix(sub, LITE, 0.14)), RenderLook.col(sub), RenderLook.col(_mix(sub, DARK, 0.3))])
	out.append_array([RenderLook.col(scar[0]), RenderLook.col(scar[1])])
	out.append(Color(1.0 if STRATA.has(name) else 0.0, float(ROCK_ABOVE.get(name, 0.0)) / 10000.0, 0.0, 1.0))
	return out


## Art's mix() of two hex colours, rounded to whole channels as Art rounds them.
static func _mix(a: String, b: String, t: float) -> String:
	var ca := Color(a)
	var cb := Color(b)
	return "#" + Color(roundf(lerpf(ca.r8, cb.r8, t)) / 255.0, roundf(lerpf(ca.g8, cb.g8, t)) / 255.0, roundf(lerpf(ca.b8, cb.b8, t)) / 255.0).to_html(false)
