class_name FarLand
extends RefCounted
## The planet's own far land (World's window 2; docs/rendering/slow-drift.md). On a planet match that may turn (World's
## epoch), the ground's far rows read World's WorldFarMap, a cached height-and-biome map of the planet, beside the
## ring the match plays on (ground.gdshaderinc far_dir, far4), with each biome's far relief on it as before. The map
## has mip levels: each far row reads the level as coarse as its spacing in depth, so the planet's small features never
## alias between the far rows (streaks of sea across a distant plain). Render only. The map is built RenderLook.FAR_MAP_STEP texels a frame and kept for the planet, so the same planet
## again has it from the first frame. It shows only from a hard cut, never in view: a match's start if the map is whole
## by then, else World's next turn. Until then the far land is the band's own, as ever.

const KEEP: int = 2   # the planets whose whole maps are kept

static var _texs: Dictionary = {}   # planet seed -> its whole map as the shaders read it: {h, b0, b1} (ImageTextures with mip levels)

var active: bool = false    # this match is on a planet that may turn
var planet: int = 0         # its seed
var on: bool = false        # the ground reads the map, from the last cut
var ring: Dictionary = {}   # the ring the match plays on now (WorldRingPick.ringFrom)
var version: int = 0        # moves whenever what the ground's materials read changes
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
	var E = S.epoch
	active = E is Dictionary
	ring = {}
	if active:
		var p: int = int(E.seed)
		if p != planet or (_map == null and not _texs.has(p)):   # another planet, or this one's map was let go
			planet = p
			_map = null
			_clear()
			if not _texs.has(p):
				_map = WorldFarMap.new(WorldPlanet.make(p), RenderLook.FAR_MAP_N)
				_tables()
		if now:
			step(RenderLook.FAR_MAP_N * RenderLook.FAR_MAP_N)
		ring = _ring_of(E)
	cut()


## A hard cut: the ground reads the map from here if it is whole.
func cut() -> void:
	on = active and _texs.has(planet)
	version += 1


## World's turn: the new ring, under the turn's cut.
func turn(S: SimState) -> void:
	if active and S.epoch is Dictionary:
		ring = _ring_of(S.epoch)
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
		if _idx[b] < 4:
			c0[j + _idx[b]] = 255
		else:
			c1[j + _idx[b] - 4] = 255
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


static func _ring_of(E: Dictionary) -> Dictionary:
	var sp: Dictionary = E.ring
	return WorldRingPick.ringFrom(sp.c, int(sp.cols), sp.t)


static func _v3(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])
