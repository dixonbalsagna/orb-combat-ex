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
## A part's flags.
const ROOF: int = 1     # a roof facet: its own colour, no windows, gone from a shell
const PLAIN: int = 2    # no windows
const CAP: int = 4      # a top piece (a roof, a spire, a plant box): gone from a shell, and from a tower whose top floors are gone
const ORN: int = 8      # an ornament: it stands above the sim's height (wholly or with its upper part) and does not collide
const ORN_MAX: float = 0.15   # ... by at most this share of the height
const FILL: float = 0.85      # the least share of the sim's width the walls have at its height
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
				# The crown tower: a pale band under the chamfer and a crown above it, a low gem between four points.
				out.append(_p(0.0, 3.0, w * 0.999, d + 6.0, h - c - 0.2 * fh, h - c, _c("#d5d9df"), PLAIN | CAP))
				out.append(_p(0.0, 0.0, w * 0.6, d * 0.6, h, h + orn * 0.55, _c(tones[1]), PLAIN | CAP | ORN, 0.5, 0.5))
				for sx in [-1.0, 1.0]:
					for sz in [-1.0, 1.0]:
						out.append(_p(sx * w * 0.36, sz * d * 0.36, w * 0.13, d * 0.13, h, h + orn, _c("#d5d9df"), ROOF | CAP | ORN, 0.04, 0.04))
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
			out.append(_p(0.0, 0.0, w, d, 0.0, h, wall))
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
