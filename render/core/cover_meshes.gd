class_name RenderCoverMeshes
extends RefCounted
## Art's 33 biome cover silhouettes (docs/art/biomes-cover.md) and the beach shell (docs/art/shell-cover.md), as flat
## meshes the renderer can instance. Each shape is ported from its cover function in art/concepts/biomes/draw.mjs (the
## shell's from shell.mjs): a few flat polygons, faceted fans and thin lines in the XY plane, x across and y up, with no
## RGB in it. A vertex's COLOR holds a palette slot (r) and a tone step (g), and
## the renderer looks the slot up in the palette of the biome the shape stands in (data/art/biomes.json), so one mesh
## serves every biome a kind grows in; a vertex with COLOR.b 1 takes a fixed tone instead (the shell's). Render only.
##
## A kind is drawn as Art's sheet draws it (art/concepts/biomes/covers.mjs): at the middle of its height range
## (DRAW_H), with draw.mjs's own generator seeded SEED, so the shapes and their triangle counts are the sheet's. Then
## the clean and charred shapes are fitted to one frame: together they span y from 0 to 1 with the foot at 0, and x is
## scaled by the same factor about the shape's root (x = 0), so the drawing's proportions hold. An instance of data
## height h is scaled by h * height_scale(kind) and lowered by ground_line(kind) of that, so it stands where Art drew
## it: a vent's steam rises above its cone, a pool and a crevasse lie under the ground line, a sea stack's foot is in
## the swell.
##
## Triangles are flat and without indices (each keeps its facet's colour), wound clockwise seen from +z (Godot's front
## face), with the normal (0, 0, 1). They keep the drawing's order: each polygon lies LAYER_Z in front of the one drawn
## before it, so a canopy covers its trunk without fighting it in depth. The keyline is not geometry (Rendering's
## outline, as Art says). The numbers inside the shape functions are draw.mjs's own, in units. Each kind is built once,
## both states together, and kept.

## The palette slots. COLOR.r is (slot + 0.5) / SLOTS, so a shader reads the slot as int(COLOR.r * 16.0), even from
## 8-bit vertex colours (read raw, with no sRGB conversion). slot_colours() gives each slot's colour for a biome.
const VEG_LIT: int = 0       # vegetation, lit face: palette.vegetation[0] (canopies, palm fronds, cacti, fir tiers)
const VEG_MID: int = 1       # vegetation, mid face
const VEG_SHADE: int = 2     # vegetation, shade face (and a flower's stem)
const SEC_LIT: int = 3       # secondary cover, lit face: palette.secondary[0] (grasses, reeds, ferns, scrub; a vent's steam)
const SEC_MID: int = 4       # secondary cover, mid face (and a jungle tree's lianas)
const SEC_SHADE: int = 5     # secondary cover, shade face (and a reed's seed head, darkened)
const ROCK_LIT: int = 6      # rock, lit face: palette.rock[0]
const ROCK_MID: int = 7      # rock, mid face (and a mesa's talus)
const ROCK_SHADE: int = 8    # rock, shade face
const TRUNK: int = 9         # trunks, branches, roots and driftwood: palette.trunk
# The accent (slot 10) is palette.accent: spruce snow, snow patches, flowers, whitecaps, the lava's glow and crust, a
# pool's rim, and the termite tower's red earth.
const ACCENT: int = 10       # the biome's accent: palette.accent
const CHAR: int = 11         # burned black, CHAR_COLOUR in every biome (burned trunks and stubs)
const ASH: int = 12          # ash grey, ASH_COLOUR in every biome (the bank under burned stubs)
const WATER: int = 13        # shallow water: palette.water.shallow (a pool; a crevasse's depth and a berg's foot, toned)
const SNOW: int = 14         # the ground's lit face: palette.ground[0], the warm white of the ices (spires, floes, bergs)
const ICE: int = 15          # the ground's shade face: palette.ground[2], the slate of the ices
const SLOTS: int = 16
# Fixed tones, the same in every biome (paints from SLOTS up): a vertex's COLOR.b is 1 and COLOR.r its tone's place,
# read from RenderBiomeLook.FIXED_ROW; the slots' own encoding is unchanged. Art's shell (shell.mjs: lit, mid, shade).
const SHELL_LIT: int = SLOTS
const SHELL_MID: int = SLOTS + 1
const SHELL_SHADE: int = SLOTS + 2
const FIXED_TONES: Array = ["#e4bcc4", "#cc90a0", "#94626e"]
# The shell in Art's three leans (degrees to the right), each its own kind: one lean along a beach row reads as a
# pattern, so a prop picks one by its seed (RenderProps.VARIANTS). Props never mirror a shell (RenderProps.NO_FLIP).
const SHELL_LEANS: Dictionary = {"shell_l8": -8.0, "shell_r2": 2.0, "shell_r12": 12.0}

const CHAR_COLOUR := Color("#2c2622")   # draw.mjs's CHAR[1]
const ASH_COLOUR := Color("#5a554f")    # draw.mjs's stubs' ash

## The tone step. COLOR.g is 0.5 + tone / 2: a tone above 0 lifts the slot's colour toward TONE_LIGHT by that share, one
## below 0 darkens it toward TONE_DARK (draw.mjs's lite() and dark(), mixed in sRGB as toned() does), and at 0.5 the
## slot's own colour shows. It carries the colours draw.mjs derives from one palette entry (a palm's lit trunk side, a
## reed's seed head, burned rock). The few it mixes with a second entry, or fixes outright, take the nearest slot and tone.
const TONE_LIGHT := Color("#fff6e0")
const TONE_DARK := Color("#0c0a14")
const TONE_CHAR_LIT: float = 0.13        # a burned trunk's lit side (draw.mjs's CHAR[0], #4a4038)
const TONE_SCORCH: float = -0.42         # burned rock: draw.mjs takes a boulder's, scree's or mesa's rock half way to #241c16
const TONE_TRUNK_LIT: float = 0.12       # a palm trunk's lit side
const TONE_BUTTRESS: float = -0.12       # a jungle tree's buttress (the trunk 12 percent toward black)
const TONE_SEED_HEAD: float = -0.3       # a reed's seed head
const TONE_PETAL: float = 0.25           # a flower's lit petals above the accent, its shade petals below
const TONE_STEAM: float = 0.2            # a vent's steam, lit face
const TONE_DRIFTWOOD: float = 0.26       # bleached driftwood (draw.mjs: the trunk 35 percent toward #d8d0c0)
const TONE_SNOW_SHADE: float = -0.2      # a snow patch's shade (draw.mjs: the accent 35 percent toward the slate #485765)
const TONE_LAVA_CRUST: float = -0.5      # cooled lava's crust (draw.mjs's #7a3220)
const TONE_CREVASSE: float = -0.53       # a crevasse's depth (draw.mjs's #1b3350)
const TONE_BERG_SEA: float = 0.08        # a berg's foot under the sea (draw.mjs's #3a7893)
const TONE_TERMITE: float = 0.06         # a termite tower (draw.mjs lightens the subsoil, which has no slot: the accent's red earth)
const TONE_TERMITE_SHADE: float = -0.36  # its shade face
# A mesa's tones on ROCK_MID, clean and charred: its talus (draw.mjs: rock mid 35 percent toward ground mid), and the
# shaded half of a lit and of a mid band (draw.mjs lays rock shade over the bands at 45 percent).
const MESA_SKIRT := Vector2(0.12, -0.17)
const MESA_SHADE_LIT := Vector2(0.0, -0.44)
const MESA_SHADE_MID := Vector2(-0.13, -0.49)

const SEED: int = 1234                   # draw.mjs's generator seed for every shape, as on Art's sheet
const PX_PER_UNIT: float = 86.0 / 75.0   # the sheet's scale (a fighter is 75 units, 86 px): line widths are in its pixels
# Each polygon's lift toward the camera over the one drawn before it, as a share of the height. 0 lays the shape
# strictly flat, and then only the triangle order keeps the drawing's.
const LAYER_Z: float = 0.002
# draw.mjs's fan(): the angle (degrees, y up) its outer edge faces picks a fan triangle's face: lit from the upper left
# round to the left, shade from below to the right, mid between.
const FAN_LIT_FROM: float = 95.0
const FAN_LIT_TO: float = 200.0
const FAN_SHADE_FROM: float = 255.0
const FAN_SHADE_TO: float = 40.0

## The height each kind is drawn at, in units: the middle of its height range over every biome it grows in (the cover
## h in data/art/biomes.json), where Art's sheet draws it. draw.mjs mixes widths fixed in units (a reed blade, a basalt
## column, a pool's span) with ones that grow with the height, so the proportions are the ones at this height. The
## order is Art's table's.
const DRAW_H := {
	"stack": 190.0, "whitecap": 16.0, "palm": 195.0, "dunegrass": 30.0, "boulder": 66.0, "driftwood": 17.0,
	"tree": 235.0, "tuft": 30.0, "shrub": 43.0, "acacia": 160.0, "termite": 70.0, "fir": 270.0,
	"jungletree": 315.0, "fern": 80.0, "flower": 40.0, "reed": 90.0, "mangrove": 160.0, "pool": 7.0,
	"cactus": 130.0, "scrub": 37.0, "mesa": 200.0, "scree": 35.0, "snowpatch": 12.0, "basaltcol": 125.0,
	"vent": 55.0, "lavaflow": 12.0, "spruce": 250.0, "krummholz": 45.0, "icespire": 110.0, "crevasse": 12.0,
	"nunatak": 160.0, "berg": 155.0, "floeblock": 22.0, "shell_l8": 48.0, "shell_r2": 48.0, "shell_r12": 48.0,
}

static var _meshes: Dictionary = {}   # kind -> [clean, charred] ArrayMesh (the same mesh twice when burning changes nothing)
static var _tris: Dictionary = {}     # kind -> Vector2i(clean, charred) triangles
static var _fit: Dictionary = {}      # kind -> Vector2(height_scale, ground_line)


## The 36 kinds, in the order of Art's table (the shell's three leans last).
static func kinds() -> PackedStringArray:
	return PackedStringArray(DRAW_H.keys())


## The kind's mesh, clean or charred (Art's burned state: a black trunk with bare branches for a tree, black stubs on an
## ash bank for grass and ferns, the rock darkened for a boulder, scree or mesa, the very same mesh for the kinds fire
## does not touch). A mesh with no surface when the state draws nothing: a burned pool is gone. Null, with an error, for
## a kind Art has not drawn.
static func mesh(kind: String, charred: bool) -> ArrayMesh:
	if not _built(kind):
		return null
	return _meshes[kind][1 if charred else 0]


## The kind's triangles, clean or charred.
static func triangles(kind: String, charred: bool) -> int:
	if not _built(kind):
		return 0
	var t: Vector2i = _tris[kind]
	return t.y if charred else t.x


## The mesh's height (its 1.0) in units of the kind's data height: scale an instance of height h by h * height_scale.
static func height_scale(kind: String) -> float:
	if not _built(kind):
		return 1.0
	return (_fit[kind] as Vector2).x


## Where draw.mjs's ground line lies in the mesh, as a share of its height (0 for most kinds; a pool's or a crevasse's is
## near 1): lower an instance by this times its scaled height, so its ground line sits on the ground.
static func ground_line(kind: String) -> float:
	if not _built(kind):
		return 0.0
	return (_fit[kind] as Vector2).y


## Each slot's colour for one biome, from its palette in data/art/biomes.json ("palette": vegetation, secondary, rock
## and ground as [lit, mid, shade], trunk, accent, water.shallow), indexed by slot. A reference for the renderer's own
## lookup; toned() applies a vertex's tone to it.
static func slot_colours(palette: Dictionary) -> PackedColorArray:
	var c := PackedColorArray()
	c.resize(SLOTS)
	for i in range(3):
		c[VEG_LIT + i] = Color(String(palette.vegetation[i]))
		c[SEC_LIT + i] = Color(String(palette.secondary[i]))
		c[ROCK_LIT + i] = Color(String(palette.rock[i]))
	c[TRUNK] = Color(String(palette.trunk))
	c[ACCENT] = Color(String(palette.accent))
	c[CHAR] = CHAR_COLOUR
	c[ASH] = ASH_COLOUR
	c[WATER] = Color(String(palette.water.shallow))
	c[SNOW] = Color(String(palette.ground[0]))
	c[ICE] = Color(String(palette.ground[2]))
	return c


## A slot's colour with a vertex's tone step (its COLOR.g) applied, as draw.mjs's lite() and dark() mix it.
static func toned(c: Color, g: float) -> Color:
	var t: float = (g - 0.5) * 2.0
	if t >= 0.0:
		return c.lerp(TONE_LIGHT, t)
	return c.lerp(TONE_DARK, -t)


## One shape being drawn: its triangles in Art's units, and draw.mjs's generator.
class _Build:
	var pos := PackedVector3Array()      # x and y in units; z is the polygon's place in the drawing order
	var paints := PackedVector2Array()   # per vertex: its slot and tone
	var layer: int = 0
	var tris: int = 0
	var _s: int = 0

	func _init(start: int) -> void:
		_s = start & 0xffffffff

	## draw.mjs's rng() to the bit: the next number in [0, 1). The state is kept as an unsigned 32-bit value.
	func rnd() -> float:
		_s = (_s + 0x6d2b79f5) & 0xffffffff
		var t: int = _s
		t = _imul(t ^ (t >> 15), t | 1)
		t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & 0xffffffff)) & 0xffffffff
		return float((t ^ (t >> 14)) & 0xffffffff) / 4294967296.0

	## Math.imul on unsigned 32-bit values, split so that no product passes 48 bits.
	static func _imul(a: int, b: int) -> int:
		return (a * (b & 0xffff) + (((a * (b >> 16)) & 0xffff) << 16)) & 0xffffffff


## Builds both states of a kind once, fits them to one frame (so the swap on burning keeps the shape's place and
## scale) and keeps them. False, with an error, for a kind Art has not drawn.
static func _built(kind: String) -> bool:
	if _meshes.has(kind):
		return true
	if not DRAW_H.has(kind):
		push_error("RenderCoverMeshes: no cover kind '%s'" % kind)
		return false
	var h: float = DRAW_H[kind]
	var clean := _Build.new(SEED)
	_shape(clean, kind, h, false)
	var burned := _Build.new(SEED)
	_shape(burned, kind, h, true)
	var lo: float = 0.0
	var hi: float = 0.0
	for b: _Build in [clean, burned]:
		for p in b.pos:
			lo = minf(lo, p.y)
			hi = maxf(hi, p.y)
	var e: float = maxf(hi - lo, 0.001)
	var m: ArrayMesh = _finish(clean, lo, e)
	var same: bool = clean.pos == burned.pos and clean.paints == burned.paints
	_meshes[kind] = [m, m if same else _finish(burned, lo, e)]
	_tris[kind] = Vector2i(clean.tris, burned.tris)
	_fit[kind] = Vector2(e / h, -lo / e)
	return true


## The drawn shape as a mesh in the kind's frame: y from lo becomes 0, and a height of e becomes 1.
static func _finish(b: _Build, lo: float, e: float) -> ArrayMesh:
	var m := ArrayMesh.new()
	var n: int = b.pos.size()
	if n == 0:
		return m
	var verts := PackedVector3Array()
	var nrms := PackedVector3Array()
	var cols := PackedColorArray()
	verts.resize(n)
	nrms.resize(n)
	cols.resize(n)
	for i in range(n):
		var p: Vector3 = b.pos[i]
		var k: Vector2 = b.paints[i]
		verts[i] = Vector3(p.x / e, (p.y - lo) / e, p.z * LAYER_Z)
		nrms[i] = Vector3(0.0, 0.0, 1.0)
		var fixed: bool = k.x >= float(SLOTS)
		cols[i] = Color((k.x - (float(SLOTS) if fixed else 0.0) + 0.5) / float(SLOTS), 0.5 + 0.5 * clampf(k.y, -1.0, 1.0), 1.0 if fixed else 0.0, 1.0)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = nrms
	arrays[Mesh.ARRAY_COLOR] = cols
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


# ---------------------------------------------------------------------------------------------------- drawing

## A paint: a slot and a tone step.
static func _k(slot: int, tone: float = 0.0) -> Vector2:
	return Vector2(slot, tone)


## A lit, mid and shade ramp from a lit slot (the two after it are its mid and shade), all at one tone.
static func _ramp(lit: int, tone: float = 0.0) -> PackedVector2Array:
	return PackedVector2Array([Vector2(lit, tone), Vector2(lit + 1, tone), Vector2(lit + 2, tone)])


## Points from a flat list of x, y pairs, in units.
static func _pts(xy: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, xy.size(), 2):
		out.append(Vector2(float(xy[i]), float(xy[i + 1])))
	return out


## A filled polygon (draw.mjs's poly): cut into simple loops where its edges cross, each loop triangulated (a fan from
## its first point if that fails). A polygon of n points makes n - 2 triangles, as Art counts them.
static func _poly(b: _Build, pts: PackedVector2Array, paint: Vector2) -> void:
	for loop: PackedVector2Array in _loops(pts):
		var idx: PackedInt32Array = Geometry2D.triangulate_polygon(loop)
		if idx.size() != 3 * (loop.size() - 2):
			idx = PackedInt32Array()
			for i in range(1, loop.size() - 1):
				idx.append(0)
				idx.append(i)
				idx.append(i + 1)
		for k in range(0, idx.size(), 3):
			_tri(b, loop[idx[k]], loop[idx[k + 1]], loop[idx[k + 2]], paint)
	b.layer += 1


## A polygon as simple loops. Where two of its edges cross it is cut in two at the crossing, and an SVG fills both
## parts (a cactus arm's pinched elbow, a frond folded over itself), so both are kept. The loops of a polygon of n
## points hold n + 2 points per cut, so they still make n - 2 triangles in all.
static func _loops(pts: PackedVector2Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var n: int = pts.size()
	for i in range(n):
		for j in range(i + 2, n):
			if i == 0 and j == n - 1:
				continue   # neighbours across the wrap
			var hit: Variant = Geometry2D.segment_intersects_segment(pts[i], pts[(i + 1) % n], pts[j], pts[(j + 1) % n])
			if hit == null:
				continue
			var x: Vector2 = hit
			var a := PackedVector2Array([x])
			for k in range(i + 1, j + 1):
				a.append(pts[k])
			var c := PackedVector2Array([x])
			for k in range(j + 1, n + i + 1):
				c.append(pts[k % n])
			out.append_array(_loops(a))
			out.append_array(_loops(c))
			return out
	out.append(pts)
	return out


## A thin line (draw.mjs's line), its width in the sheet's pixels: a quad for each segment.
static func _line(b: _Build, pts: PackedVector2Array, width_px: float, paint: Vector2) -> void:
	var half: float = 0.5 * width_px / PX_PER_UNIT
	for i in range(pts.size() - 1):
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[i + 1]
		var side: Vector2 = (q - p).orthogonal().normalized() * half
		_tri(b, p - side, p + side, q + side, paint)
		_tri(b, p - side, q + side, q - side, paint)
	b.layer += 1


## A faceted fan about a centre (draw.mjs's fan): each triangle takes the ramp's lit, mid or shade by the way its outer
## edge faces.
static func _fan(b: _Build, c: Vector2, ring: PackedVector2Array, ramp: PackedVector2Array) -> void:
	var n: int = ring.size()
	for i in range(n):
		var p: Vector2 = ring[i]
		var q: Vector2 = ring[(i + 1) % n]
		var m: Vector2 = (p + q) * 0.5 - c
		var ang: float = fposmod(rad_to_deg(atan2(m.y, m.x)), 360.0)
		var paint: Vector2 = ramp[1]
		if ang > FAN_LIT_FROM and ang < FAN_LIT_TO:
			paint = ramp[0]
		elif ang >= FAN_SHADE_FROM or ang < FAN_SHADE_TO:
			paint = ramp[2]
		_tri(b, c, p, q, paint)
	b.layer += 1


## draw.mjs's blob: n points round an ellipse about c, each pushed out or in by up to jit of its radius.
static func _blob(b: _Build, c: Vector2, rx: float, ry: float, n: int, jit: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(n):
		var a: float = float(i) / float(n) * TAU
		var k: float = 1.0 + (b.rnd() - 0.5) * 2.0 * jit
		out.append(Vector2(c.x + cos(a) * rx * k, c.y + sin(a) * ry * k))
	return out


## One triangle, wound clockwise seen from +z (Godot's front face), on the current layer.
static func _tri(b: _Build, p0: Vector2, p1: Vector2, p2: Vector2, paint: Vector2) -> void:
	var z: float = float(b.layer)
	b.pos.append(Vector3(p0.x, p0.y, z))
	if (p1 - p0).cross(p2 - p0) > 0.0:
		b.pos.append(Vector3(p2.x, p2.y, z))
		b.pos.append(Vector3(p1.x, p1.y, z))
	else:
		b.pos.append(Vector3(p1.x, p1.y, z))
		b.pos.append(Vector3(p2.x, p2.y, z))
	b.paints.append(paint)
	b.paints.append(paint)
	b.paints.append(paint)
	b.tris += 1


# ---------------------------------------------------------------------------------------------------- the shapes
# Each draws at the origin (draw.mjs's x and y) with height h, in the order draw.mjs draws, so the generator's numbers
# fall where they fall on Art's sheet.

static func _shape(b: _Build, kind: String, h: float, charred: bool) -> void:
	match kind:
		"stack": _stack(b, h)
		"whitecap": _whitecap(b, h)
		"palm": _palm(b, h, charred)
		"dunegrass": _dunegrass(b, h, charred)
		"boulder": _boulder(b, h, charred)
		"driftwood": _driftwood(b, h)
		"tree": _tree(b, h, charred)
		"tuft": _tuft(b, h, charred)
		"shrub": _shrub(b, h, charred)
		"acacia": _acacia(b, h, charred)
		"termite": _termite(b, h)
		"fir": _fir(b, h, charred, false)
		"jungletree": _jungletree(b, h, charred)
		"fern": _fern(b, h, charred)
		"flower": _flower(b, h, charred)
		"reed": _reed(b, h, charred)
		"mangrove": _mangrove(b, h, charred)
		"pool": _pool(b, h, charred)
		"cactus": _cactus(b, h, charred)
		"scrub": _scrub(b, h, charred)
		"mesa": _mesa(b, h, charred)
		"scree": _scree(b, h, charred)
		"snowpatch": _snowpatch(b, h)
		"basaltcol": _basaltcol(b, h)
		"vent": _vent(b, h)
		"lavaflow": _lavaflow(b, h)
		"spruce": _fir(b, h * 1.05, charred, true)
		"krummholz": _krummholz(b, h, charred)
		"icespire": _icespire(b, h)
		"crevasse": _crevasse(b, h)
		"nunatak": _nunatak(b, h)
		"berg": _berg(b, h)
		"floeblock": _floeblock(b, h)
		"shell_l8", "shell_r2", "shell_r12": _shell(b, h, SHELL_LEANS[kind])


## A burned tree (draw.mjs's charredTree): a black trunk with a lit side, and bare branches.
static func _charred_tree(b: _Build, foot: Vector2, h: float, branches: int) -> void:
	var w: float = maxf(3.0, h * 0.035)
	var x: float = foot.x
	var y: float = foot.y
	_poly(b, _pts([x - w, y, x + w, y, x + w * 0.55, y + h * 0.7, x - w * 0.55, y + h * 0.7]), _k(CHAR))
	_poly(b, _pts([x - w, y, x - w * 0.2, y, x - w * 0.1, y + h * 0.68, x - w * 0.55, y + h * 0.7]), _k(CHAR, TONE_CHAR_LIT))
	for _i in range(branches):
		var t: float = 0.35 + b.rnd() * 0.4
		var s: float = -1.0 if b.rnd() < 0.5 else 1.0
		var bx: float = x + s * w * 0.4
		var by: float = y + h * t
		var l: float = h * (0.14 + b.rnd() * 0.14)
		var tip := Vector2(bx + s * l, by + l * (0.7 + b.rnd() * 0.4))
		_line(b, PackedVector2Array([Vector2(bx, by), tip]), maxf(1.4, w * 0.7), _k(CHAR))


## Burned grass (draw.mjs's stubs): n black stubs spread across the base, and a low ash bank.
static func _stubs(b: _Build, h: float, n: int, spread: float) -> void:
	for _i in range(n):
		var bx: float = (b.rnd() - 0.5) * spread
		var s: float = (b.rnd() - 0.5) * 6.0
		var top := Vector2(bx + s, maxf(5.0, h * (0.1 + b.rnd() * 0.14)))
		_poly(b, PackedVector2Array([Vector2(bx - 2.0, 0.0), Vector2(bx + 2.0, 0.0), top]), _k(CHAR))
	_poly(b, _pts([-spread * 0.5, 0.0, spread * 0.5, 0.0, spread * 0.3, 4.0, -spread * 0.3, 5.0]), _k(ASH))


static func _tree(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_charred_tree(b, Vector2.ZERO, h * 0.9, 5)
		return
	var tw: float = h * 0.035
	_poly(b, _pts([-tw * 1.3, 0.0, tw * 1.3, 0.0, tw * 0.8, h * 0.5, -tw * 0.8, h * 0.5]), _k(TRUNK))
	var c := Vector2(0.0, h * 0.7)
	_fan(b, c, _blob(b, c, h * 0.3, h * 0.3, 8, 0.16), _ramp(VEG_LIT))
	if b.rnd() < 0.5:
		var c2 := Vector2(h * 0.14, h * 0.88)
		_fan(b, c2, _blob(b, c2, h * 0.18, h * 0.16, 7, 0.16), _ramp(VEG_LIT))


## A fir; with snow, the spruce (drawn 1.05 times its height, snow on each tier).
static func _fir(b: _Build, h: float, charred: bool, snow: bool) -> void:
	if charred:
		_charred_tree(b, Vector2.ZERO, h * 0.95, 6)
		return
	var bw: float = h * 0.2
	_poly(b, _pts([-3.0, 0.0, 3.0, 0.0, 2.4, h * 0.2, -2.4, h * 0.2]), _k(TRUNK))
	for i in range(5):
		var t0: float = 0.12 + i * 0.17
		var w: float = bw * (1.0 - i * 0.17)
		var by: float = h * t0
		var ty: float = h * minf(1.0, t0 + 0.34)
		_poly(b, _pts([-w, by, 0.0, ty, 0.0, by]), _k(VEG_LIT))
		_poly(b, _pts([0.0, by, 0.0, ty, w, by]), _k(VEG_SHADE))
	if snow:
		for i in range(5):
			var t0: float = 0.12 + i * 0.17
			var w: float = bw * (1.0 - i * 0.17) * 0.5
			var by: float = h * (t0 + 0.17)
			_poly(b, _pts([-w, by, 0.0, h * minf(1.0, t0 + 0.34), w, by]), _k(ACCENT))


static func _acacia(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_charred_tree(b, Vector2.ZERO, h * 0.8, 4)
		return
	var tw: float = h * 0.03
	_poly(b, _pts([-tw * 1.4, 0.0, tw * 1.4, 0.0, tw * 0.7, h * 0.55, -tw * 0.7, h * 0.55]), _k(TRUNK))
	_poly(b, _pts([-tw * 0.7, h * 0.5, -h * 0.28, h * 0.78, -h * 0.24, h * 0.8, 0.0, h * 0.58]), _k(TRUNK))
	_poly(b, _pts([tw * 0.7, h * 0.5, h * 0.3, h * 0.76, h * 0.26, h * 0.78, 0.0, h * 0.58]), _k(TRUNK))
	var crown := _pts([-h * 0.55, h * 0.8, -h * 0.36, h * 0.93, 0.0, h * 0.99, h * 0.38, h * 0.93, h * 0.58, h * 0.8,
			h * 0.3, h * 0.74, -h * 0.28, h * 0.74])
	_fan(b, Vector2(0.0, h * 0.84), crown, _ramp(VEG_LIT))


static func _jungletree(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_charred_tree(b, Vector2.ZERO, h * 0.85, 6)
		return
	var tw: float = h * 0.04
	_poly(b, _pts([-tw * 3.0, 0.0, -tw, h * 0.18, tw, h * 0.18, tw * 3.0, 0.0]), _k(TRUNK, TONE_BUTTRESS))
	_poly(b, _pts([-tw, h * 0.1, tw, h * 0.1, tw * 0.8, h * 0.78, -tw * 0.8, h * 0.78]), _k(TRUNK))
	for crown: Vector3 in [Vector3(-h * 0.2, 0.74, 0.26), Vector3(h * 0.22, 0.78, 0.24), Vector3(0.0, 0.88, 0.3)]:
		var c := Vector2(crown.x, h * crown.y)
		_fan(b, c, _blob(b, c, h * crown.z, h * crown.z * 0.7, 8, 0.14), _ramp(VEG_LIT))
	for i in range(3):
		var lx: float = (i - 1) * h * 0.18
		_line(b, _pts([lx, h * 0.7, lx + 3.0 * (i - 1), h * 0.3]), 1.6, _k(SEC_MID))


static func _fern(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_stubs(b, h, 5, 40.0)
		return
	for i in range(6):
		var a: float = (i / 5.0 - 0.5) * 2.2 + (b.rnd() - 0.5) * 0.2
		var l: float = h * (0.7 + b.rnd() * 0.3)
		var ex: float = sin(a) * l * 0.9
		var ey: float = cos(a) * l * 0.8
		var mx: float = sin(a) * l * 0.4
		var my: float = cos(a) * l * 0.7 + l * 0.2
		_poly(b, _pts([0.0, 0.0, mx - 3.0, my, ex, ey, mx + 3.0, my - 2.0]), _k(SEC_LIT if i % 2 == 1 else SEC_MID))


static func _flower(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_stubs(b, h * 0.5, 2, 14.0)
		return
	_line(b, _pts([0.0, 0.0, 0.0, h]), 2.0, _k(VEG_SHADE))
	var c := Vector2(0.0, h)
	var ring := PackedVector2Array()
	for i in range(10):
		var a: float = i / 10.0 * TAU
		ring.append(c + Vector2(cos(a), sin(a)) * h * (0.24 if i % 2 == 1 else 0.4))
	_fan(b, c, ring, PackedVector2Array([_k(ACCENT, TONE_PETAL), _k(ACCENT), _k(ACCENT, -TONE_PETAL)]))


static func _palm(b: _Build, h: float, charred: bool) -> void:
	var lean: float = (b.rnd() - 0.5) * h * 0.3
	if charred:
		_poly(b, _pts([-4.0, 0.0, 4.0, 0.0, lean + 2.0, h * 0.85, lean - 2.0, h * 0.85]), _k(CHAR))
		return
	_poly(b, _pts([-5.0, 0.0, 5.0, 0.0, lean + 3.0, h * 0.85, lean - 3.0, h * 0.85]), _k(TRUNK))
	_poly(b, _pts([-5.0, 0.0, -1.0, 0.0, lean, h * 0.85, lean - 3.0, h * 0.85]), _k(TRUNK, TONE_TRUNK_LIT))
	var tx: float = lean
	var ty: float = h * 0.85
	var l: float = h * 0.42
	for i in range(7):
		var a: float = (i / 6.0 - 0.5) * 3.0
		var ex: float = tx + sin(a) * l
		var ey: float = ty + cos(a) * l * 0.2 - absf(sin(a)) * l * 0.45
		var mx: float = tx + sin(a) * l * 0.55
		var my: float = ty + cos(a) * l * 0.35 + l * 0.1
		_poly(b, _pts([tx, ty, mx, my + 5.0, ex, ey, mx, my - 3.0]), _k(VEG_LIT + i % 3))


static func _mangrove(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_charred_tree(b, Vector2(0.0, h * 0.15), h * 0.6, 3)
		return
	for i in range(5):
		var s: float = (i - 2) * h * 0.14
		_line(b, _pts([s * 0.2, h * 0.35, s * 0.9, h * 0.18, s, 0.0]), 2.4, _k(TRUNK))
	_poly(b, _pts([-5.0, h * 0.3, 5.0, h * 0.3, 3.5, h * 0.6, -3.5, h * 0.6]), _k(TRUNK))
	var c := Vector2(0.0, h * 0.75)
	_fan(b, c, _blob(b, c, h * 0.32, h * 0.22, 8, 0.16), _ramp(VEG_LIT))


static func _reed(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_stubs(b, h, 9, 44.0)
		return
	for i in range(8):
		var bx: float = (i - 4) * 5.0 + (b.rnd() - 0.5) * 4.0
		var hh: float = h * (0.7 + b.rnd() * 0.5)
		var lean: float = (b.rnd() - 0.5) * h * 0.2
		_poly(b, _pts([bx - 2.2, 0.0, bx + 2.2, 0.0, bx + lean, hh]), _k(SEC_LIT + i % 3))
		if i % 3 == 0:
			var hx: float = bx + lean
			_poly(b, _pts([hx - 2.0, hh - 9.0, hx + 2.0, hh - 9.0, hx + 1.4, hh + 6.0, hx - 1.4, hh + 6.0]), _k(SEC_SHADE, TONE_SEED_HEAD))


## A pool of standing water, sunk below the ground line, with a pale rim line. Burned, it is gone.
static func _pool(b: _Build, h: float, charred: bool) -> void:
	if charred:
		return
	var w: float = 90.0 + b.rnd() * 60.0
	_poly(b, _pts([-w, 0.5, -w * 0.5, -h, w * 0.5, -h * 1.1, w, 0.5]), _k(WATER))
	_line(b, _pts([-w * 0.6, 0.8, w * 0.6, 0.8]), 1.4, _k(ACCENT))


static func _cactus(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_poly(b, _pts([-6.0, 0.0, 6.0, 0.0, 5.0, h * 0.9, -5.0, h * 0.9]), _k(CHAR))
		return
	var w: float = maxf(6.0, h * 0.075)
	_poly(b, _pts([-w, 0.0, 0.0, 0.0, 0.0, h * 0.95, -w * 0.5, h]), _k(VEG_LIT))
	_poly(b, _pts([0.0, 0.0, w, 0.0, w * 0.5, h, 0.0, h * 0.95]), _k(VEG_SHADE))
	for s: float in [-1.0, 1.0]:
		var ay: float = h * (0.45 if s < 0.0 else 0.6)
		var ax: float = s * h * 0.28
		var arm := _pts([0.0, ay - 5.0, ax - s * w * 0.2, ay - 5.0, ax - s * w * 0.2, ay + h * 0.3, ax + s * w * 1.1, ay + h * 0.3,
				ax + s * w * 1.1, ay - 5.0, ax + s * w * 0.9, ay - 11.0, ax - s * w * 0.5, ay - 11.0, s * w * 0.4, ay + 8.0])
		_poly(b, arm, _k(VEG_LIT if s < 0.0 else VEG_SHADE))


static func _scrub(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_stubs(b, h, 5, 44.0)
		return
	for i in range(7):
		var bx: float = (i - 3) * h * 0.2
		var lean: float = (i - 3) * h * 0.16 + (b.rnd() - 0.5) * 6.0
		var top: float = h * (0.7 + b.rnd() * 0.5)
		_poly(b, _pts([bx - 4.0, 0.0, bx + 4.0, 0.0, bx + lean, top]), _k(SEC_LIT + i % 3))


static func _shrub(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_stubs(b, h, 5, 40.0)
		return
	var c := Vector2(0.0, h * 0.4)
	_fan(b, c, _blob(b, c, h * 0.7, h * 0.4, 7, 0.15), _ramp(VEG_LIT))


static func _tuft(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_stubs(b, h, 5, 26.0)
		return
	for i in range(7):
		var bx: float = (i - 3) * 3.2
		var lean: float = (i - 3) * h * 0.1 + (b.rnd() - 0.5) * 6.0
		var top: float = h * (0.7 + b.rnd() * 0.5)
		_poly(b, _pts([bx - 1.8, 0.0, bx + 1.8, 0.0, bx + lean, top]), _k(SEC_LIT + i % 3))


static func _dunegrass(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_stubs(b, h, 5, 26.0)
		return
	for i in range(6):
		var bx: float = (i - 3) * 3.0
		var lean: float = (i - 3) * h * 0.22
		_poly(b, _pts([bx - 1.4, 0.0, bx + 1.4, 0.0, bx + lean, h * (0.8 + b.rnd() * 0.4)]), _k(SEC_LIT + i % 2))


## A wind-bent scrub (draw.mjs's krummholz): a short root stock and eight thick branches from one root point, all
## leaning downwind, tallest at the windward side. The branches are the leaves, so nothing stands on a stalk.
static func _krummholz(b: _Build, h: float, charred: bool) -> void:
	if charred:
		_charred_tree(b, Vector2.ZERO, h, 3)
		return
	_poly(b, _pts([-7.0, 0.0, 7.0, 0.0, 4.0, h * 0.16, -3.0, h * 0.18]), _k(TRUNK))
	var branches: Array = [[-0.08, -0.16, 0.55, 8.0], [-0.04, -0.02, 0.8, 10.0], [0.0, 0.14, 0.9, 10.0], [0.04, 0.3, 0.78, 10.0],
			[0.08, 0.46, 0.66, 10.0], [0.12, 0.54, 0.5, 9.0], [0.14, 0.64, 0.36, 8.0], [0.16, 0.7, 0.24, 7.0]]
	for i in range(branches.size()):
		var br: Array = branches[i]
		var bx: float = float(br[0]) * h
		var w: float = float(br[3])
		_poly(b, _pts([bx - w, h * 0.08, bx + w, h * 0.08, float(br[1]) * h, float(br[2]) * h]), _k(VEG_LIT + (0 if i < 3 else 1 if i < 6 else 2)))


static func _boulder(b: _Build, h: float, charred: bool) -> void:
	var rock := _pts([-h * 0.95, 0.0, -h * 0.7, h * 0.7, -h * 0.1, h * 0.95, h * 0.6, h * 0.75, h * 0.95, 0.0])
	_fan(b, Vector2(0.0, h * 0.4), rock, _ramp(ROCK_LIT, TONE_SCORCH if charred else 0.0))


static func _scree(b: _Build, h: float, charred: bool) -> void:
	var tone: float = TONE_SCORCH if charred else 0.0
	for i in range(9):
		var bx: float = (i - 4) * 14.0 + (b.rnd() - 0.5) * 6.0
		var s: float = 5.0 + b.rnd() * h * 0.5
		_poly(b, _pts([bx - s, 0.0, bx - s * 0.2, s * 0.9, bx + s * 0.8, 0.0]), _k(ROCK_LIT + i % 3, tone))


## A mesa: a talus skirt and five strata bands. draw.mjs lays a translucent shade over the right of the bands; here each
## band is cut where that shade begins, and its right part takes the shaded tone (22 triangles where Art counts 14).
static func _mesa(b: _Build, h: float, charred: bool) -> void:
	var ci: int = 1 if charred else 0
	var scorch: float = TONE_SCORCH if charred else 0.0
	var w: float = h * 0.34
	_poly(b, _pts([-w * 2.3, 0.0, -w * 0.95, h * 0.3, w * 0.95, h * 0.3, w * 2.3, 0.0]), _k(ROCK_MID, MESA_SKIRT[ci]))
	var cut: float = w * 0.1
	for i in range(5):
		var t0: float = 0.3 + i * 0.14
		var t1: float = t0 + 0.14
		var w0: float = w * (1.0 - (t0 - 0.3) * 0.2)
		var w1: float = w * (1.0 - (t1 - 0.3) * 0.2)
		var y0: float = h * t0
		var y1: float = h * minf(1.0, t1)
		var lit: bool = i % 2 == 0
		_poly(b, _pts([-w0, y0, -w1, y1, cut, y1, cut, y0]), _k(ROCK_LIT if lit else ROCK_MID, scorch))
		_poly(b, _pts([cut, y0, cut, y1, w1, y1, w0, y0]), _k(ROCK_MID, (MESA_SHADE_LIT if lit else MESA_SHADE_MID)[ci]))


## A sea stack, its foot 10 units under the swell, with two shade lines of strata.
static func _stack(b: _Build, h: float) -> void:
	var w: float = h * 0.2
	var v := _pts([-w * 1.5, -10.0, -w * 1.2, h * 0.4, -w * 0.8, h * 0.82, -w * 0.1, h, w * 0.7, h * 0.9, w * 1.0, h * 0.5,
			w * 1.5, -10.0])
	_poly(b, v, _k(ROCK_MID))
	_poly(b, PackedVector2Array([v[3], v[4], v[5], v[6], Vector2(w * 0.1, -10.0)]), _k(ROCK_SHADE))
	_poly(b, PackedVector2Array([v[0], v[1], v[2], v[3], Vector2(-w * 0.1, h * 0.4)]), _k(ROCK_LIT))
	_line(b, _pts([-w * 1.3, h * 0.35, w * 1.1, h * 0.4]), 1.1, _k(ROCK_SHADE))
	_line(b, _pts([-w * 0.9, h * 0.68, w * 0.8, h * 0.72]), 1.1, _k(ROCK_SHADE))


static func _basaltcol(b: _Build, h: float) -> void:
	for i in range(5):
		var cx: float = (i - 2) * 16.0
		var hh: float = h * (0.55 + 0.45 * (1.0 - absi(i - 2) / 2.4)) * (0.85 + b.rnd() * 0.2)
		_poly(b, _pts([cx - 7.0, 0.0, cx - 7.0, hh, cx, hh + 4.0, cx + 7.0, hh, cx + 7.0, 0.0]), _k(ROCK_MID if i % 2 == 1 else ROCK_LIT))
		_poly(b, _pts([cx, 0.0, cx, hh + 4.0, cx + 7.0, hh, cx + 7.0, 0.0]), _k(ROCK_SHADE))


## A vent: a low cone and three puffs of steam rising from it.
static func _vent(b: _Build, h: float) -> void:
	_poly(b, _pts([-h * 0.8, 0.0, -h * 0.15, h * 0.7, h * 0.15, h * 0.7, h * 0.8, 0.0]), _k(ROCK_MID))
	_poly(b, _pts([0.0, 0.0, 0.0, h * 0.7, h * 0.15, h * 0.7, h * 0.8, 0.0]), _k(ROCK_SHADE))
	var steam := PackedVector2Array([_k(SEC_LIT, TONE_STEAM), _k(SEC_LIT), _k(SEC_MID)])
	for i in range(3):
		var c := Vector2(i * 6.0, h * (0.9 + i * 0.5))
		_fan(b, c, _blob(b, c, h * (0.3 + i * 0.12), h * (0.22 + i * 0.08), 7, 0.14), steam)


static func _lavaflow(b: _Build, h: float) -> void:
	var w: float = 180.0 + b.rnd() * 80.0
	_poly(b, _pts([-w, 0.0, -w * 0.5, h, w * 0.5, h * 1.1, w, 0.0]), _k(ACCENT, TONE_LAVA_CRUST))
	_poly(b, _pts([-w * 0.6, h * 0.5, -w * 0.2, h * 0.9, w * 0.35, h * 0.95, w * 0.7, h * 0.4]), _k(ACCENT))


static func _icespire(b: _Build, h: float) -> void:
	for spire: Vector2 in [Vector2(-h * 0.22, 0.7), Vector2(0.0, 1.0), Vector2(h * 0.2, 0.55)]:
		var dx: float = spire.x
		var hh: float = h * spire.y
		var w: float = h * 0.14 * (0.8 + spire.y * 0.4)
		_poly(b, _pts([dx - w, 0.0, dx - w * 0.5, hh * 0.8, dx, hh, dx, 0.0]), _k(SNOW))
		_poly(b, _pts([dx, 0.0, dx, hh, dx + w * 0.6, hh * 0.75, dx + w, 0.0]), _k(ICE))


## A crevasse: a dark crack running down into the ice, almost all of it below the ground line.
static func _crevasse(b: _Build, h: float) -> void:
	var w: float = 14.0 + b.rnd() * 10.0
	_poly(b, _pts([-w, 0.6, -w * 0.3, -h * 3.0, w * 0.2, -h * 5.0, w * 0.5, -h * 2.8, w, 0.6]), _k(WATER, TONE_CREVASSE))


static func _nunatak(b: _Build, h: float) -> void:
	_poly(b, _pts([-h * 0.7, 0.0, -h * 0.25, h * 0.7, 0.0, h, h * 0.3, h * 0.65, h * 0.8, 0.0]), _k(ROCK_MID))
	_poly(b, _pts([0.0, 0.0, 0.0, h, h * 0.3, h * 0.65, h * 0.8, 0.0]), _k(ROCK_SHADE))
	_poly(b, _pts([-h * 0.2, h * 0.75, 0.0, h, h * 0.2, h * 0.78, 0.0, h * 0.7]), _k(SNOW))


static func _snowpatch(b: _Build, h: float) -> void:
	var w: float = 50.0 + b.rnd() * 70.0
	_poly(b, _pts([-w, 0.0, -w * 0.5, h, w * 0.4, h * 1.1, w, 0.0]), _k(ACCENT))
	_poly(b, _pts([w * 0.1, 1.0, w * 0.4, h * 1.1, w, 0.0]), _k(ACCENT, TONE_SNOW_SHADE))


## A berg: the white above the sea with its slate face, and its foot under the water.
static func _berg(b: _Build, h: float) -> void:
	var w: float = h * 0.9
	_poly(b, _pts([-w, 0.0, -w * 0.7, h * 0.45, -w * 0.2, h, w * 0.15, h * 0.7, w * 0.6, h * 0.85, w, 0.0]), _k(SNOW))
	_poly(b, _pts([w * 0.1, 0.0, w * 0.15, h * 0.7, w * 0.6, h * 0.85, w, 0.0]), _k(ICE))
	_poly(b, _pts([-w, 0.0, w, 0.0, w * 0.7, -h * 0.4, -w * 0.5, -h * 0.45]), _k(WATER, TONE_BERG_SEA))


static func _floeblock(b: _Build, h: float) -> void:
	var w: float = h * 1.1
	_poly(b, _pts([-w, 0.0, -w, h, w * 0.6, h, w * 0.6, 0.0]), _k(SNOW))
	_poly(b, _pts([w * 0.6, 0.0, w * 0.6, h, w, h * 0.7, w, 0.0]), _k(ICE))


## Art's beach shell (art/concepts/biomes/shell.mjs): a scallop standing on its hinge, h its fan's radius, leaning
## lean_deg to the right. A fan over 126 degrees from the hinge: eight lobe tips at h and seven notches at 0.93 h between, one
## wedge to each pair of neighbours (14), lit, mid and shade by thirds from the left; the ear below the hinge in shade.
## Art's three fixed tones, not the biome's slots. The ribs and the growth line are keyline strokes, not geometry.
static func _shell(b: _Build, h: float, lean_deg: float) -> void:
	var lean: float = deg_to_rad(lean_deg)
	var hy: float = h * 0.1
	var span: float = deg_to_rad(126.0)
	var ribs: int = 7
	var edge := PackedVector2Array()
	for i in range(ribs + 1):
		var a0: float = -span / 2.0 + span * float(i) / float(ribs)
		if i > 0:
			var an: float = a0 - span / float(ribs) / 2.0 + lean
			edge.append(Vector2(sin(an) * h * 0.93, hy + cos(an) * h * 0.93))
		edge.append(Vector2(sin(a0 + lean) * h, hy + cos(a0 + lean) * h))
	_poly(b, _pts([-h * 0.2, 0.0, h * 0.2, 0.0, h * 0.12, hy + h * 0.06, -h * 0.12, hy + h * 0.06]), _k(SHELL_SHADE))
	for i in range(edge.size() - 1):
		var t: float = float(i) / float(edge.size() - 2)
		_poly(b, PackedVector2Array([Vector2(0.0, hy), edge[i], edge[i + 1]]), _k(SHELL_LIT if t < 0.34 else (SHELL_MID if t < 0.7 else SHELL_SHADE)))


static func _termite(b: _Build, h: float) -> void:
	_poly(b, _pts([-h * 0.5, 0.0, -h * 0.3, h * 0.6, -h * 0.08, h, h * 0.1, h * 0.95, h * 0.32, h * 0.55, h * 0.5, 0.0]), _k(ACCENT, TONE_TERMITE))
	_poly(b, _pts([h * 0.04, 0.0, h * 0.1, h * 0.95, h * 0.32, h * 0.55, h * 0.5, 0.0]), _k(ACCENT, TONE_TERMITE_SHADE))


static func _driftwood(b: _Build, h: float) -> void:
	var l: float = 70.0 + b.rnd() * 40.0
	_poly(b, _pts([-l, 1.0, -l * 0.9, h, l * 0.8, h * 1.1, l, 3.0]), _k(TRUNK, TONE_DRIFTWOOD))
	_line(b, _pts([-l * 0.3, h, -l * 0.2, h * 2.4]), 2.2, _k(TRUNK, TONE_DRIFTWOOD))


static func _whitecap(b: _Build, h: float) -> void:
	var l: float = 26.0 + b.rnd() * 50.0
	_poly(b, _pts([-l, 0.0, -l * 0.3, h * 0.9, l * 0.1, h * 0.3, l * 0.5, h, l, 0.0]), _k(ACCENT))
