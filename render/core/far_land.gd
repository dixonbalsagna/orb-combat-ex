class_name FarLand
extends RefCounted
## The planet's own far land (World's window 2; docs/rendering/slow-drift.md). On a planet match (World's S.planetRing,
## the turn on or off), the ground's far rows read World's WorldFarMap, a cached height-and-biome map of the planet,
## beside the ring the match plays on (ground.gdshaderinc far_dir, far4), with each biome's far relief on it as before
## and the settlements' ground (the map's sites) in the city's and the village's colours. The map has mip levels: each
## far row reads the level as coarse as its spacing in depth, so the planet's small features never alias between the
## far rows (streaks of sea across a distant plain). The distant towns and cities (WorldPlanet.farPlaces) stand on it
## as blocks (far_town.gdshader). Render only. The map is built RenderLook.FAR_MAP_STEP texels a frame and kept for the
## planet, so the same planet again has it from the first frame. It shows only from a hard cut, never in view: a
## match's start if the map is whole by then, else World's next turn. Until then the far land is the band's own.

const KEEP: int = 2   # the planets whose whole maps are kept
const CITY: int = 2      # GroundField.BIOME_ORDER's city and village
const VILLAGE: int = 3

static var _texs: Dictionary = {}   # planet seed -> its whole map as the shaders read it: {h, b0, b1} (ImageTextures with mip levels)

var active: bool = false    # this match is on a planet (S.planetRing)
var planet: int = 0         # its seed
var on: bool = false        # the ground reads the map, from the last cut
var ring: Dictionary = {}   # the ring the match plays on now (WorldRingPick.ringFrom)
var version: int = 0        # moves whenever what the ground's materials read changes
var towns: MultiMesh = null # the distant towns and cities beside the ring, made at each cut; drawn while `on`
var _map: WorldFarMap = null           # the map being built (null once whole)
var _px := PackedFloat32Array()        # its texels so far as the shaders read them: the height x its biome's far
                                       # multiplier, its biome's relief amplitude, the height, 0
var _b0 := PackedByteArray()           # and its biome as shares (255 for its own): BIOME_ORDER 0 to 3,
var _b1 := PackedByteArray()           # 4 to 6 (so a coarser level holds each biome's share of its texels)
var _mul := PackedFloat32Array()       # by the planet's biome (WorldPlanetWorld.BIOME_NAME): RenderLook.FAR_RELIEF
var _amp := PackedFloat32Array()
var _idx := PackedInt32Array()


## A new match (after SimCore.newMatch). now: build the map whole at once (stills and probes).
func begin(S: SimState, now: bool = false) -> void:
	var R = S.planetRing
	active = R is Dictionary and not R.is_empty()
	ring = {}
	if active:
		var p: int = int(R.seed)
		if p != planet or (_map == null and not _texs.has(p)):   # another planet, or this one's map was let go
			planet = p
			_map = null
			_clear()
			if not _texs.has(p):
				_map = WorldFarMap.new(WorldPlanet.make(p), RenderLook.FAR_MAP_N)
				_tables()
		if now:
			step(RenderLook.FAR_MAP_N * RenderLook.FAR_MAP_N)
		ring = _ring_of(R)
	cut()


## A hard cut: the ground reads the map from here if it is whole.
func cut() -> void:
	on = active and _texs.has(planet)
	towns = _make_towns() if on else null
	version += 1


## World's turn: the new ring, under the turn's cut.
func turn(S: SimState) -> void:
	if active and not S.planetRing.is_empty():
		ring = _ring_of(S.planetRing)
	cut()


## Once a frame: `count` more texels of the map while it is not whole. A whole map shows from the next cut.
func step(count: int) -> void:
	if _map == null:
		return
	var k0: int = _map.next
	_map.step(count)
	var k1: int = _map.next
	var hs: PackedFloat32Array = _map.hs
	var bs: PackedByteArray = _map.bs
	var ss: PackedByteArray = _map.sites
	var chunk := PackedFloat32Array()
	chunk.resize(4 * (k1 - k0))
	var c0 := PackedByteArray()
	c0.resize(4 * (k1 - k0))
	var c1 := PackedByteArray()
	c1.resize(4 * (k1 - k0))
	for k in range(k0, k1):
		var b: int = bs[k]
		var j: int = 4 * (k - k0)
		chunk[j] = hs[k] * _mul[b]
		chunk[j + 1] = _amp[b]
		chunk[j + 2] = hs[k]
		var bi: int = _idx[b]
		if ss[k] > 0 and hs[k] >= 0.0:   # a settlement's ground (World's sites): the city's colour, or the village's
			bi = CITY if ss[k] == 2 else VILLAGE
		if bi < 4:
			c0[j + bi] = 255
		else:
			c1[j + bi - 4] = 255
	_px.append_array(chunk)
	_b0.append_array(c0)
	_b1.append_array(c1)
	if _map.done:
		if _texs.size() >= KEEP:
			_texs.clear()
		_texs[planet] = {"h": _tex(_px.to_byte_array(), Image.FORMAT_RGBAF), "b0": _tex(_b0, Image.FORMAT_RGBA8), "b1": _tex(_b1, Image.FORMAT_RGBA8)}
		_map = null
		_clear()


## The far map and the ring on a ground material (planet_view.gd set_far).
func apply(m: ShaderMaterial) -> void:
	m.set_shader_parameter("far_map_on", on)
	if not on:
		return
	var t: Dictionary = _texs[planet]
	var P: WorldPlanet.Planet = WorldPlanet.make(planet)
	var st: float = float(ring.st)
	var n: int = (t.h as ImageTexture).get_width()
	var texel: float = PI * P.R / float(n)   # a texel of the finest level, in units of the surface (about)
	m.set_shader_parameter("far_map", t.h)
	m.set_shader_parameter("far_bio0", t.b0)
	m.set_shader_parameter("far_bio1", t.b1)
	m.set_shader_parameter("far_map_n", n)
	m.set_shader_parameter("far_texel_w", texel)
	m.set_shader_parameter("far_lod_k", RenderLook.ROW_GROWTH / texel)
	m.set_shader_parameter("far_lod_max", RenderLook.FAR_MAP_LOD_MAX)
	m.set_shader_parameter("ring_c", _v3(ring.c))
	m.set_shader_parameter("ring_u", _v3(ring.u))
	m.set_shader_parameter("ring_v", _v3(ring.v))
	m.set_shader_parameter("ring_sc", Vector2(st, float(ring.ct)))
	m.set_shader_parameter("ring_step", SimConst.COL / (P.R * st))
	m.set_shader_parameter("ring_mid", float(WorldPlanet.touchCol()))
	m.set_shader_parameter("planet_r", P.R)


func _clear() -> void:
	_px = PackedFloat32Array()
	_b0 = PackedByteArray()
	_b1 = PackedByteArray()


## A map level 0 and its mip levels (box-filtered: the heights average, and the biomes' shares).
func _tex(bytes: PackedByteArray, format: int) -> ImageTexture:
	var img: Image = Image.create_from_data(_map.n, _map.n, false, format, bytes)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _tables() -> void:
	var names: Array = WorldPlanetWorld.BIOME_NAME
	_mul.resize(names.size())
	_amp.resize(names.size())
	_idx.resize(names.size())
	for b in range(names.size()):
		var name: String = names[b]
		var r: Array = RenderLook.FAR_RELIEF[name]
		_mul[b] = r[0]
		_amp[b] = r[1] * (RenderLook.MS if name == "mountains" else RenderLook.WS)
		_idx[b] = GroundField.BIOME_ORDER.find(name)


## The distant towns and cities beside the ring (World's WorldPlanet.farPlaces), as blocks on the planet's far land: one
## instance a block, scaled to its size, its palette entry and shade in its colour (far_town.gdshader reads where it
## stands from its place). The far land behind the fighter plane follows each column's way over the surface toward the
## ring's axis and on past it (ground.gdshaderinc far_dir), so a place is drawn where those ways meet it: a place inside
## the ring on its own column's way, short of the axis, and every place on the opposite column's way, past the axis.
## Only where the far land is whole (past the far blend) and within FAR_TOWN_REACH; a place the ring passes through is
## the band's own. Across the ways the far land is drawn wider than the planet near the axis (its columns crowd
## together there), so a town's blocks spread as wide as its ground's colour. Seeded by the planet and the place, so a
## town stands the same way every time. Null when there are none.
func _make_towns() -> MultiMesh:
	var P: WorldPlanet.Planet = WorldPlanet.make(planet)
	var near: float = -RenderLook.Z_TERRAIN_BACK + RenderLook.FAR_BLEND   # the far land is whole from this depth
	var axis: float = float(ring.th) * P.R   # the ring's axis lies this far behind the fighter plane
	var xf: Array = []
	var cols := PackedColorArray()
	for pl in WorldPlanet.farPlaces(P, ring):
		var lat: float = float(pl.z)   # toward the ring's axis: R x (the ring's angular radius less the place's angle from the axis)
		var rad: float = float(pl.rad)
		if absf(lat) < rad:
			continue
		var city: bool = int(pl.kind) == WorldPlanet.KIND_CITY
		var spec: Array = RenderLook.FAR_CITY if city else RenderLook.FAR_TOWN   # [blocks, width min, max, height min, max]
		var psi: float = (axis - lat) / P.R   # the place's angle from the ring's axis
		var wide: float = clampf(float(ring.st) / maxf(sin(psi), 1e-3), 1.0, RenderLook.FAR_TOWN_WIDE)
		var ways: Array = [[float(pl.col), -2.0 * axis + lat]]   # the opposite column's way, past the axis
		if lat > 0.0:
			ways.append([float(pl.col), -lat])   # its own column's way, short of the axis
		ways[0][0] += float(SimConst.NC) * 0.5
		for wy in ways:
			if -float(wy[1]) - rad > RenderLook.FAR_TOWN_REACH:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash([planet, int(pl.id)])
			for k in range(int(spec[0])):
				var a: float = rng.randf() * TAU
				var r: float = sqrt(rng.randf()) * rad * RenderLook.FAR_TOWN_SPREAD
				var w: float = rng.randf_range(spec[1], spec[2])
				var d: float = rng.randf_range(spec[1], spec[2])
				var core: float = 1.0 - r / (rad * RenderLook.FAR_TOWN_SPREAD)   # taller toward the middle
				var h: float = lerpf(float(spec[3]), float(spec[4]), core * core * rng.randf())
				var pal: int = rng.randi_range(0, 2) + (0 if city else 3)
				var shade: float = rng.randf_range(0.85, 1.1)
				var bz: float = float(wy[1]) + sin(a) * r
				if bz > -near:
					continue
				var bx: float = float(wy[0]) * SimConst.COL + cos(a) * r * wide
				xf.append(Transform3D(Basis.from_scale(Vector3(w, h, d)), Vector3(bx - SimConst.W * floorf(bx / SimConst.W), 0.0, bz)))
				cols.append(Color((float(pal) + 0.5) / 8.0, shade, 0.0, 1.0))
	if xf.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _block()
	mm.instance_count = xf.size()
	for i in range(xf.size()):
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, cols[i])
	return mm


static var _block_mesh: ArrayMesh = null


## A block of unit width, depth and height: its foot sinks FAR_TOWN_FOOT of its height below the ground it stands on, so
## a slope never shows under it. Flat faces with their own normals; no bottom.
static func _block() -> ArrayMesh:
	if _block_mesh != null:
		return _block_mesh
	var y0: float = -RenderLook.FAR_TOWN_FOOT
	var v := PackedVector3Array()
	var nrm := PackedVector3Array()
	var faces: Array = [
		[Vector3(0, 1, 0), [Vector3(-0.5, 1, -0.5), Vector3(0.5, 1, -0.5), Vector3(0.5, 1, 0.5), Vector3(-0.5, 1, 0.5)]],
		[Vector3(0, 0, 1), [Vector3(-0.5, y0, 0.5), Vector3(-0.5, 1, 0.5), Vector3(0.5, 1, 0.5), Vector3(0.5, y0, 0.5)]],
		[Vector3(0, 0, -1), [Vector3(0.5, y0, -0.5), Vector3(0.5, 1, -0.5), Vector3(-0.5, 1, -0.5), Vector3(-0.5, y0, -0.5)]],
		[Vector3(1, 0, 0), [Vector3(0.5, y0, 0.5), Vector3(0.5, 1, 0.5), Vector3(0.5, 1, -0.5), Vector3(0.5, y0, -0.5)]],
		[Vector3(-1, 0, 0), [Vector3(-0.5, y0, -0.5), Vector3(-0.5, 1, -0.5), Vector3(-0.5, 1, 0.5), Vector3(-0.5, y0, 0.5)]],
	]
	for f in faces:
		var q: Array = f[1]
		for i in [0, 1, 2, 0, 2, 3]:
			v.append(q[i])
			nrm.append(f[0])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nrm
	_block_mesh = ArrayMesh.new()
	_block_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return _block_mesh


static func _ring_of(R: Dictionary) -> Dictionary:
	return WorldRingPick.ringFrom(R.c, int(R.cols), R.t)


static func _v3(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])
