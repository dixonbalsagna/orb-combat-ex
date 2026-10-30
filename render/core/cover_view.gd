class_name CoverView
extends RefCounted
## Biome rendering window 2 (docs/rendering/biomes.md; Art's docs/art/biomes.md and biomes-cover.md): the cover that
## grows on the band's ground, behind the fighter plane. Each strip of Art's 1,200-unit window carries, in each of
## RenderLook.COVER_LAYERS (a span of depth), the cover Art's data gives the biome under it ("cover": a kind, how many a
## strip, a height range): trees, tufts, boulders, cacti, reeds, firs and the rest, as Art's flat silhouettes
## (RenderCoverMeshes) standing in the strip's plane. Across a border's zone each shape takes the neighbour's cover by
## the zone's band share (Art: the cover mixes by probability), and the zone has its own ecotone covers (Art's pairs).
## A water column carries only what floats or stands in the sea, and where a river or a lake is drawn (a gen 2 ring's,
## S.planetRing's lakes; GroundField.flooded) there is no land cover. No cover where the band's buildings stand, in the
## city or the village (their streets and houses are theirs), or in front of the fighter plane.
##
## Made once for a world (the band's biomes, the buildings), the same in every pane and every copy: one MultiMesh for
## each kind in each of COVER_CHUNKS spans of the planet's length, so the frustum leaves out the spans off the screen.
## Where each shape stands is the ground's (render/shaders/cover.gdshader reads the ground under its foot, craters and
## all, and leaves a shape out inside a crater). Seeded by the world and the strip, so the same world grows the same
## cover. Render only.

const STRIP: float = 1200.0   # Art's window: the cover counts are per this much of the strip
const WATER_KINDS: Array = ["whitecap", "floeblock", "berg", "stack", "foam"]   # what stands or floats in the sea
const FLOAT_KINDS: Array = ["whitecap", "floeblock", "berg", "foam"]            # what floats at the water's level
const NO_FLIP: Array = ["krummholz"]   # never mirrored: its lean is its shape (Art), and its lit face stays on the left
const SAME: Dictionary = {"foam": "whitecap"}   # a kind Art's data names that is drawn as another (draw.mjs: foam is a small whitecap)

static var record: bool = false         # tools only: laid collects what a build places (a headless run keeps no MultiMesh data)
static var ctl_in_water: bool = false   # tools only (cover_water_check's failing control): land cover stands in rivers and lakes again
var meshes: Array = []   # [kind, chunk, MultiMesh] for the planet copies (planet_view.gd)
var count: int = 0       # the shapes placed
var laid: Array = []     # tools only: [x, z, kind, flip], in the order placed
var in_water: int = 0    # the land shapes a river or a lake kept out of this build


## Grow the cover for the world in S (its band's biomes, its buildings) on ground field g (the zone rows). seed: the
## world's (the same world grows the same cover).
func build(S: SimState, g: GroundField, seed: int) -> void:
	meshes.clear()
	count = 0
	laid.clear()
	in_water = 0
	var nc: int = SimConst.NC
	var w: float = SimConst.W
	var bio: PackedFloat32Array = g.row_bytes(GroundField.ROW_BIOME).to_float32_array()
	var za: PackedFloat32Array = g.row_bytes(GroundField.ROW_ZONE_A).to_float32_array()
	var zb: PackedFloat32Array = g.row_bytes(GroundField.ROW_ZONE_B).to_float32_array()
	var zx: PackedFloat32Array = g.row_bytes(GroundField.ROW_ZONE_X).to_float32_array()
	var known: PackedStringArray = RenderCoverMeshes.kinds()
	var per: Dictionary = {}   # kind -> [[Transform3D, palette id, floats], ...] by chunk
	var strips: int = int(ceil(w / STRIP))
	var near: Array = _buildings_by_strip(S, strips)
	var lakes: Array = S.planetRing.get("lakes", []) if S.planetRing is Dictionary else []
	var rng := RandomNumberGenerator.new()
	for si in range(strips):
		for li in range(RenderLook.COVER_LAYERS.size()):
			var layer: Vector2 = RenderLook.COVER_LAYERS[li]
			rng.seed = hash([seed, si, li])
			var x0: float = float(si) * STRIP
			var mid: int = posmod(int((x0 + STRIP * 0.5) / SimConst.COL), nc)
			var n_here: int = _count_of(RenderBiomeLook.name_of(int(za[mid])))   # how many candidates this strip draws
			for k in range(n_here):
				var x: float = x0 + rng.randf() * STRIP
				if x >= w:
					continue
				var z: float = lerpf(layer.x, layer.y, rng.randf())
				var col: int = posmod(int(x / SimConst.COL), nc)
				# the biome this shape grows in: the zone's other side by its band share (Art's five bands)
				var id: int = int(za[col])
				var other: int = int(zb[col])
				var share: float = 0.0
				if other != id and zx[col] > -1.0e8:
					var t: float = clampf(0.5 + (x / SimConst.COL - zx[col]) * SimConst.COL / RenderLook.BIOME_ZONE, 0.0, 1.0)
					share = 0.0 if t <= 0.0 else (1.0 if t >= 1.0 else (floor(t * 5.0) + 0.5) / 5.0)
				var pick: int = other if rng.randf() < share else id
				var name: String = RenderBiomeLook.name_of(pick)
				var kind: String = ""
				if other != id and share > 0.0 and share < 1.0 and rng.randf() < RenderLook.COVER_ECO:
					kind = _eco(RenderBiomeLook.name_of(id), RenderBiomeLook.name_of(other), rng)
				var e: Dictionary = {}
				if kind == "":
					e = _cover_pick(name, rng)
					kind = String(e.get("k", ""))
				kind = String(SAME.get(kind, kind))
				if kind == "" or not known.has(kind):
					continue
				var wet: bool = S.base[col] < WorldWater.RESERVOIR_BASE
				if wet != WATER_KINDS.has(kind):
					continue
				if _in_building(near[si], x, z):
					continue
				var hr: Array = e.get("h", [RenderCoverMeshes.DRAW_H.get(kind, 50.0), RenderCoverMeshes.DRAW_H.get(kind, 50.0)])
				var h: float = lerpf(float(hr[0]), float(hr[1]), rng.randf())
				var s: float = h * RenderCoverMeshes.height_scale(kind)
				var flip: float = -1.0 if rng.randf() < 0.5 and not NO_FLIP.has(kind) else 1.0
				# After the shape's own draws, so the rest of its strip grows as it would: only this shape is gone.
				if not wet and not lakes.is_empty() and not ctl_in_water and g.flooded(S, col) and _lake_level(lakes, g.shore[col]):
					in_water += 1
					continue
				if record:
					laid.append([x, z, kind, flip])
				var xf := Transform3D(Basis.from_scale(Vector3(s * flip, s, s)), Vector3(x, -RenderCoverMeshes.ground_line(kind) * s, z))
				var ch: int = mini(int(x / w * float(RenderLook.COVER_CHUNKS)), RenderLook.COVER_CHUNKS - 1)
				if not per.has(kind):
					per[kind] = []
					for c in range(RenderLook.COVER_CHUNKS):
						per[kind].append([])
				per[kind][ch].append([xf, pick, 1.0 if FLOAT_KINDS.has(kind) else 0.0])
				count += 1
	# Each span's box for the frustum: the instances stand at height 0 in their transforms and the shader lifts them to the
	# ground, so the box spans the span's ground (less the deepest crater, plus the tallest shape), not the transforms.
	var boxes: Array = []
	var cw: float = w / float(RenderLook.COVER_CHUNKS)
	var zr: Vector2 = Vector2(INF, -INF)
	for layer in RenderLook.COVER_LAYERS:
		zr = Vector2(minf(zr.x, minf(layer.x, layer.y)), maxf(zr.y, maxf(layer.x, layer.y)))
	for c in range(RenderLook.COVER_CHUNKS):
		var lo: float = INF
		var hi: float = -INF
		for col in range(int(float(c) * cw / SimConst.COL), mini(nc, int(float(c + 1) * cw / SimConst.COL) + 1)):
			lo = minf(lo, S.base[col])
			hi = maxf(hi, S.base[col])
		lo -= RenderLook.COVER_BOX_PAD.x
		hi += RenderLook.COVER_BOX_PAD.y
		boxes.append(AABB(Vector3(float(c) * cw - 600.0, lo, zr.x - 600.0), Vector3(cw + 1200.0, hi - lo, zr.y - zr.x + 1200.0)))
	for kind in per:
		for c in range(RenderLook.COVER_CHUNKS):
			var list: Array = per[kind][c]
			if list.is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true        # white: the renderer multiplies the vertex colour (the slot and tone) by the instance's
			mm.use_custom_data = true
			mm.mesh = RenderCoverMeshes.mesh(kind, false)
			mm.instance_count = list.size()
			for i in range(list.size()):
				mm.set_instance_transform(i, list[i][0])
				mm.set_instance_color(i, Color.WHITE)
				mm.set_instance_custom_data(i, Color((float(list[i][1]) + 0.5) / 32.0, float(list[i][2]), 0.0, 0.0))
			mm.custom_aabb = boxes[c]
			meshes.append([kind, c, mm])


## How many shapes a strip of this biome carries (Art's counts, summed); 0 for the city, the village or no data.
static func _count_of(name: String) -> int:
	if name == "city" or name == "village":
		return 0
	var n: int = 0
	for c in RenderBiomeLook.entry(name).get("cover", []):
		n += int(c.n)
	return n


## One of the biome's covers, by Art's counts as weights; {} for none.
static func _cover_pick(name: String, rng: RandomNumberGenerator) -> Dictionary:
	if name == "city" or name == "village":
		return {}
	var list: Array = RenderBiomeLook.entry(name).get("cover", [])
	var total: int = 0
	for c in list:
		total += int(c.n)
	if total <= 0:
		return {}
	var r: int = rng.randi_range(0, total - 1)
	for c in list:
		r -= int(c.n)
		if r < 0:
			return c
	return {}


## An ecotone cover of the pair (Art's "neighbours": the covers that appear only where the two meet), or "".
## Is lv the level of one of this ring's rivers or lakes? (The sea's is another level, so its shallows keep their cover.)
static func _lake_level(lakes: Array, lv: float) -> bool:
	for lk in lakes:
		if absf(float(lk[2]) - lv) < 1.0:
			return true
	return false


static func _eco(a: String, b: String, rng: RandomNumberGenerator) -> String:
	for pair in [[a, b], [b, a]]:
		for nb in RenderBiomeLook.entry(pair[0]).get("neighbours", []):
			if String(nb.get("id", "")) == pair[1] and (nb.get("eco", []) as Array).size() > 0:
				var eco: Array = nb.eco
				return String(eco[rng.randi_range(0, eco.size() - 1)])
	return ""


## The buildings that reach into each strip (with the margin), so a shape is checked only against its own strip's.
static func _buildings_by_strip(S: SimState, strips: int) -> Array:
	var out: Array = []
	out.resize(strips)
	for i in range(strips):
		out[i] = []
	var m: float = RenderLook.COVER_BUILDING_PAD
	for b in S.buildings:
		var half: float = float(b.w) * 0.5 + m
		var s0: int = int(floor((float(b.x) - half) / STRIP))
		var s1: int = int(floor((float(b.x) + half) / STRIP))
		for si in range(s0, s1 + 1):
			out[posmod(si, strips)].append(b)
	return out


## Whether (x, z) lies on one of these buildings' footprints (its width across, its depth either way of its z: the
## render reads B1's footprint the same way), with a margin.
static func _in_building(list: Array, x: float, z: float) -> bool:
	var m: float = RenderLook.COVER_BUILDING_PAD
	for b in list:
		if absf(SimWrap.sdx(float(b.x), x)) > float(b.w) * 0.5 + m:
			continue
		var bz: float = float(b.z) if "z" in b else 0.0
		var bd: float = absf(float(b.d)) if "d" in b else 0.0
		if absf(z - bz) <= bd + m:
			return true
	return false
