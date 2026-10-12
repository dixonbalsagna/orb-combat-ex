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
## Every part stays inside the sim's box (b.w wide, b.h tall above its footing), so what is drawn never stands where
## the sim has nothing. Shapes that narrow toward the top (stepped, crown, spire, chimney, lighthouse, a gable) are
## narrower than the sim's box up there; that is listed for World in docs/rendering/lanes-look.md.
##
## Reads the sim and the settlements data only; writes neither.

const SETTLEMENTS: String = "res://data/biomes/settlements.json"
## A part's flags.
const ROOF: int = 1     # a roof facet: its own colour, no windows, gone from a shell
const PLAIN: int = 2    # no windows
const CAP: int = 4      # a top piece (a roof, a spire, a plant box): gone from a shell, and from a tower whose top floors are gone
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
## pane, 8 wide door panels along the ground row.
const LOOK: Dictionary = {
	"downtown": {"wall": ["#b8c0cc", "#7f8896", "#4a5261"], "roof": "#4a5261", "win": [46.0, 0.16, 0.84, 1.0], "pane": [0.07, 1.0, 1.0], "glass": ["#2c4a63", "#6aa0c0", 0.1], "trim": "#4a5261", "flags": 0, "lot": ["#7b7e86", 1.0]},
	"mid_rise": {"wall": ["#c6cdd7", "#929aa7", "#5a6270"], "roof": "#5a6270", "win": [120.0, 0.05, 0.95, 1.0], "pane": [0.16, 0.84, 2.0], "glass": ["#2c4a63", "#6aa0c0", 0.2], "trim": "#5a6270", "flags": 0, "lot": ["#7b7e86", 1.0]},
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


## The looks' names in the data's order (a district's look is an index into this).
static func look_names() -> Array:
	if _names.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(SETTLEMENTS))
		_names = (j as Dictionary).get("looks", []) if j is Dictionary else []
		if _names.is_empty():
			_names = [FALLBACK]
	return _names


## Look k's table (the fallback for a name with no entry here, so a look World adds is drawn, plainly, until Art has it).
static func look(k: int) -> Dictionary:
	var names: Array = look_names()
	var n: String = str(names[k]) if k >= 0 and k < names.size() else FALLBACK
	return LOOK.get(n, LOOK[FALLBACK])


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
	var roof: Color = _c(lk["roof"])
	var trim: Color = _c(lk["trim"])
	var out: Array = []
	var shape: String = str(b.shape)
	var plant: float = clampf(0.4 * fh, 24.0, 70.0)
	match shape:
		"stepped":
			# A core the full height at about 60 percent of the base, with two skirts: the setbacks.
			out.append(_p(0.0, 0.0, w * 0.62, d * 0.7, 0.0, h - plant, wall))
			out.append(_p(0.0, 0.0, w, d, 0.0, _snap(h * 0.45, fh), wall))
			out.append(_p(0.0, 0.0, w * 0.8, d * 0.85, 0.0, _snap(h * 0.74, fh), wall))
			out.append(_p(side * w * 0.08, 0.0, w * 0.3, d * 0.3, h - plant, h, dark, PLAIN | CAP))
		"crown":
			var c: float = clampf(0.9 * w, fh, 0.12 * h)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - c, wall))
			out.append(_p(0.0, 0.0, w, d, h - c, h, _c(tones[1]), PLAIN | CAP, 0.5, 0.5))
		"spire":
			var c: float = clampf(1.6 * w, 1.5 * fh, 0.2 * h)
			if int(b.landmark) > 0:
				# The Gatebell (Art, Legal RL-040): a stone shaft, an open belfry, a spire, one stair bump; no clock face.
				var bel: float = clampf(1.1 * w, fh, 0.08 * h)
				out.append(_p(0.0, 0.0, w, d, 0.0, h - c - bel, _c(tones[0]), 0, 1.0, 1.0, 0.0, STONE))
				out.append(_p(0.0, 0.0, w * 0.84, d * 0.84, h - c - bel, h - c, _c(BELFRY), PLAIN | CAP))
				out.append(_p(0.0, 0.0, w, d, h - c - bel - 0.12 * bel, h - c - bel, _c(tones[0]), PLAIN | CAP))
				out.append(_p(0.0, 0.0, w, d, h - c - 0.12 * bel, h - c, _c(tones[0]), PLAIN | CAP))
				out.append(_p(0.0, 0.0, w * 0.96, d * 0.96, h - c, h, roof, ROOF | CAP, 0.02, 0.02))
				out.append(_p(side * w * 0.3, d * 0.5 + 12.0, w * 0.2, 24.0, 0.0, _snap(h * 0.045, fh), _c(tones[1]), 0, 1.0, 1.0, 0.0, STONE))
			else:
				out.append(_p(0.0, 0.0, w, d, 0.0, h - c, wall))
				out.append(_p(0.0, 0.0, w * 0.94, d * 0.94, h - c, h, roof, ROOF | CAP, 0.02, 0.02))
		"slab", "block", "shaft":
			out.append(_p(0.0, 0.0, w, d, 0.0, h - plant, wall))
			out.append(_p(side * w * (0.22 if shape == "block" else 0.12), 0.0, w * (0.34 if shape == "block" else 0.42), d * 0.36, h - plant, h, dark, PLAIN | CAP))
		"warehouse":
			var rh: float = minf(0.13 * d, 0.3 * h)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - rh, wall))
			out.append(_p(0.0, 0.0, w * 1.02, d * 1.04, h - rh, h, roof, ROOF | CAP, 1.0, 0.03))
		"sawtooth":
			var th: float = clampf(0.2 * h, 30.0, 120.0)
			var n: int = clampi(int(round(w / 190.0)), 2, 5)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - th, wall))
			for i in range(n):
				out.append(_p((float(i) + 0.5) / float(n) * w - 0.5 * w, 0.0, w / float(n), d, h - th, h, roof, ROOF | CAP, 1.0, 1.0, 1.0))
		"chimney":
			var ch: float = clampf(0.03 * h, 24.0, 110.0)
			var tp: float = 0.72
			out.append(_p(0.0, 0.0, w, d, 0.0, h - ch, _c(BRICK_STACK), PLAIN, tp, tp))
			out.append(_p(0.0, 0.0, w * tp * 1.12, d * tp * 1.12, h - ch, h, _c(SOOT), PLAIN | CAP, 1.14, 1.14))
			if int(b.landmark) > 0:
				# The stack (Art, Legal): pale stone and soot bands, a flared cap, a short side flue. No red and white.
				(out[0] as Array)[COL] = _c("#b9b2a4")
				for band in [[0.3, 0.37], [0.58, 0.65]]:
					var w0: float = 1.0 - (1.0 - tp) * float(band[0]) * h / (h - ch)
					var w1: float = 1.0 - (1.0 - tp) * float(band[1]) * h / (h - ch)
					out.append(_p(0.0, 0.0, w * w0 * 1.03, d * w0 * 1.03, h * float(band[0]), h * float(band[1]), _c(SOOT), PLAIN, w1 / w0, w1 / w0))
				out.append(_p(side * w * 0.2, d * 0.5 + 10.0, w * 0.16, 20.0, 0.0, h * 0.28, _c(SOOT), PLAIN))
		"lighthouse":
			# A tapering tower in two wide bands, a lantern room of pale glass under a low cone. No stripe, no beam.
			var tp: float = 0.68
			var hb: float = 0.84 * h
			out.append(_p(0.0, 0.0, w, d, 0.0, hb, _c(tones[0]), 0, tp, tp, 0.0, STONE))
			var w0: float = 1.0 - (1.0 - tp) * 0.36 / 0.84
			var w1: float = 1.0 - (1.0 - tp) * 0.6 / 0.84
			out.append(_p(0.0, 0.0, w * w0 * 1.02, d * w0 * 1.02, 0.36 * h, 0.6 * h, _c(SLATE), PLAIN, w1 / w0, w1 / w0))
			out.append(_p(0.0, 0.0, w * tp * 1.22, d * tp * 1.22, hb, 0.86 * h, dark, PLAIN | CAP))
			out.append(_p(0.0, 0.0, w * tp * 0.8, d * tp * 0.8, 0.86 * h, 0.94 * h, _c(LANTERN), PLAIN | CAP))
			out.append(_p(0.0, 0.0, w * tp * 0.96, d * tp * 0.96, 0.94 * h, h, _c(SLATE), ROOF | CAP, 0.02, 0.02))
		"house", "shop", "thatch":
			# A gable whose end faces the street: 35 to 40 degrees, a thatch about 55 with deep eaves.
			var steep: bool = shape == "thatch"
			var rh: float = minf((0.71 if steep else 0.377) * w, (0.6 if steep else 0.45) * h)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - rh, wall))
			out.append(_p(0.0, 0.0, w * (1.22 if steep else 1.08), d * 1.04, h - rh, h, roof, ROOF | CAP, 0.02, 1.0))
			if shape == "shop" and fh * 0.92 < h - rh:
				out.append(_p(0.0, d * 0.5 + 20.0, w * 0.96, 40.0, fh * 0.86, fh * 0.92, trim, PLAIN))
		"terrace":
			# Two stone steps up a slope, the upper one under a steep roof.
			var rh: float = minf(0.36 * w, 0.4 * h)
			out.append(_p(side * w * 0.24, 0.0, w * 0.52, d, 0.0, h - rh, wall))
			out.append(_p(side * w * 0.24, 0.0, w * 0.58, d * 1.04, h - rh, h, roof, ROOF | CAP, 0.02, 1.0))
			out.append(_p(-side * w * 0.26, 0.0, w * 0.48, d, 0.0, 0.58 * h, _c(tones[1])))
		"hall":
			# A long gable, its slope to the street, with a porch.
			var lan: float = 0.07 * h if int(b.landmark) > 0 else 0.0
			var rh: float = minf(0.42 * d, 0.42 * h)
			out.append(_p(0.0, 0.0, w, d, 0.0, h - rh - lan, wall))
			out.append(_p(0.0, 0.0, w * 1.04, d * 1.06, h - rh - lan, h - lan, roof, ROOF | CAP, 1.0, 0.02))
			var ph: float = minf(0.42 * h, h - rh - lan)
			out.append(_p(0.0, d * 0.5 + 30.0, w * 0.3, 60.0, 0.0, ph * 0.78, _c(tones[1]), PLAIN))
			out.append(_p(0.0, d * 0.5 + 30.0, w * 0.34, 66.0, ph * 0.78, ph, roof, ROOF, 0.02, 1.0))
			if lan > 0.0:
				out.append(_p(0.0, 0.0, w * 0.09, w * 0.09, h - lan - 0.25 * rh, h, _c(tones[0]), PLAIN | CAP))   # the hall's ridge lantern
		"chapel":
			# A gable with a small belfry at one end.
			var nave: float = 0.6 * h
			var rh: float = minf(0.55 * w * 0.74, 0.45 * nave)
			out.append(_p(-side * w * 0.13, 0.0, w * 0.74, d, 0.0, nave - rh, wall))
			out.append(_p(-side * w * 0.13, 0.0, w * 0.8, d * 1.04, nave - rh, nave, roof, ROOF | CAP, 0.02, 1.0))
			out.append(_p(side * w * 0.37, 0.0, w * 0.26, minf(d, w * 0.26), 0.0, 0.86 * h, _c(tones[1]), 0, 1.0, 1.0, 0.0, STONE))
			out.append(_p(side * w * 0.37, 0.0, w * 0.2, minf(d, w * 0.2), 0.74 * h, 0.82 * h, _c(BELFRY), PLAIN))
			out.append(_p(side * w * 0.37, 0.0, w * 0.3, minf(d, w * 0.3), 0.86 * h, h, roof, ROOF | CAP, 0.02, 0.02))
		"shed":
			var rh: float = 0.28 * h
			out.append(_p(0.0, 0.0, w, d, 0.0, h - rh, wall))
			out.append(_p(0.0, 0.0, w * 1.04, d * 1.04, h - rh, h, roof, ROOF | CAP, 1.0, 1.0, side))
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
