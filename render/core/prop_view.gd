class_name RenderProps
extends RefCounted
## The match's props (World's WorldGround.matchProps; docs/world/props-w5.md, docs/world/flight-hooks-w6.md) as Art's
## cover silhouettes (RenderCoverMeshes), so what PROP SMASH breaks is what is drawn. Only with Combat's biome block on
## (DirLaunch.biomeOn: launch_biome.json's biome.enabled, off on main), so the picture is unchanged while it is off; and
## only on a world with fine ground (gen 2: matchProps is [] elsewhere).
##
## The ring's props are laid once for a world (the whole ring: about 400 on a gen 2 planet), each at its x, at its data
## height (size x WorldGround.BH), in the strip's plane at Z (just behind the fighter plane), as the kind KINDS names,
## drawn by the cover's shader: its foot on the ground as drawn, and, unlike the cover, standing in a crater too (it
## still stands in the sim). One MultiMesh for each kind in each of RenderLook.COVER_CHUNKS spans of the planet, as the
## cover's, so the frustum leaves out the spans off the screen.
##
## A prop a launch breaks (SimDir.brokenProps: the columns the director keeps broken) is gone on the frame its column
## is broken: a hard cut, the debris and dust doing the work (no fade, ADR 0010). A column's props are asked again only
## when the broken list changes, and only that column's: a fighter's ring holds four, so a fifth break lets the oldest
## stand again. Nothing else is done a frame. Render only: it reads the sim and writes nothing back.

## World's prop kinds as Art's cover kinds (provisional: Art's call, docs/rendering/props.md). A kind not named here is
## not drawn (a shell: Art has no shape for it yet). A lone tree is drawn as the tree Art's cover gives its biome.
const KINDS: Dictionary = {
	"grass": "tuft", "tall_grass": "dunegrass", "fern": "fern", "vine": "fern", "reeds": "reed", "scrub": "scrub",
	"boulder": "boulder", "lichen_rock": "boulder", "lava_rock": "boulder", "log": "driftwood", "driftwood": "driftwood",
	"cactus": "cactus", "termite_mound": "termite", "ice_spire": "icespire", "snow_drift": "snowpatch", "puddle": "pool",
	"vent": "vent", "berg": "berg",
}
const LONE_TREE: String = "lone_tree"
const Z: float = -8.0 * RenderLook.WS   # the props' depth: just behind the fighter plane, where a launch meets them (Art's call)

static var ctl_frozen: bool = false     # tools only (props_check's failing control): the update does nothing
var meshes: Array = []                  # [name, MultiMesh] for the planet copies (planet_view.gd)
var count: int = 0                      # the props laid
var shown := PackedByteArray()          # per prop: 1 drawn, 0 broken (for tools)
var placed: Array = []                  # per prop: its transform as last written (a headless run keeps no MultiMesh data; for tools)
var _x := PackedFloat64Array()          # per prop: its x
var _kind := PackedStringArray()        # per prop: World's kind
var _mm: Array = []                     # per prop: its MultiMesh
var _slot := PackedInt32Array()         # per prop: its instance in that MultiMesh
var _xf: Array = []                     # per prop: its transform standing
var _cols: Dictionary = {}              # column -> its props' indices
var _broken := PackedInt32Array()       # the broken columns as last drawn


## Lay the ring's props for the world in S on ground field g (its zone rows give each prop its biome's palette), with
## the props already broken taken out. Nothing while Combat's biome block is off. Seeded by the prop's column and kind,
## so the same world draws the same props.
func build(S: SimState, g: GroundField) -> void:
	meshes.clear()
	count = 0
	shown = PackedByteArray()
	placed.clear()
	_x = PackedFloat64Array()
	_kind = PackedStringArray()
	_mm.clear()
	_slot = PackedInt32Array()
	_xf.clear()
	_cols.clear()
	_broken = PackedInt32Array()
	if not DirLaunch.biomeOn():
		return
	var all: Array = WorldGround.matchProps(S, 0.0, SimConst.W)
	if all.is_empty():
		return
	var nc: int = SimConst.NC
	var w: float = SimConst.W
	var za: PackedFloat32Array = g.row_bytes(GroundField.ROW_ZONE_A).to_float32_array()
	var known: PackedStringArray = RenderCoverMeshes.kinds()
	var rng := RandomNumberGenerator.new()
	var per: Dictionary = {}   # cover kind -> by chunk: [[prop, Transform3D, Color], ...]
	for p in all:
		if bool(p.get("cell", false)):
			continue   # a berg cell: the terrain stands there as the berg (World's W5)
		var x: float = float(p.x)
		var col: int = posmod(int(p.col), nc)
		rng.seed = hash([col, String(p.kind), x])
		var pid: int = int(za[col]) if za.size() == nc else 0
		var ck: String = RenderTrees._pick(RenderBiomeLook.name_of(pid), rng) if String(p.kind) == LONE_TREE else String(KINDS.get(String(p.kind), ""))
		if ck == "" or not known.has(ck):
			continue
		var s: float = float(p.size) * WorldGround.BH * RenderCoverMeshes.height_scale(ck)
		var flip: float = -1.0 if rng.randf() < 0.5 else 1.0
		var xf := Transform3D(Basis.from_scale(Vector3(s * flip, s, s)), Vector3(x, -RenderCoverMeshes.ground_line(ck) * s, Z))
		var custom := Color((float(pid) + 0.5) / 32.0, 1.0 if CoverView.FLOAT_KINDS.has(ck) else 0.0, 0.0, 1.0)   # a: stands in a crater
		var ch: int = clampi(int(x / w * float(RenderLook.COVER_CHUNKS)), 0, RenderLook.COVER_CHUNKS - 1)
		if not per.has(ck):
			per[ck] = []
			for c in range(RenderLook.COVER_CHUNKS):
				per[ck].append([])
		var i: int = count
		count += 1
		_x.append(x)
		_kind.append(String(p.kind))
		_xf.append(xf)
		placed.append(xf)
		shown.append(1)
		_mm.append(null)
		_slot.append(0)
		if not _cols.has(col):
			_cols[col] = PackedInt32Array()
		_cols[col].append(i)
		per[ck][ch].append([i, xf, custom])
	# Each span's box, as the cover's: the instances stand at height 0 and the shader lifts them to the ground.
	var cw: float = w / float(RenderLook.COVER_CHUNKS)
	for ck in per:
		for c in range(RenderLook.COVER_CHUNKS):
			var list: Array = per[ck][c]
			if list.is_empty():
				continue
			var lo: float = INF
			var hi: float = -INF
			for col in range(int(float(c) * cw / SimConst.COL), mini(nc, int(float(c + 1) * cw / SimConst.COL) + 1)):
				lo = minf(lo, S.base[col])
				hi = maxf(hi, S.base[col])
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true        # white: the cover's shader multiplies the vertex colour (the slot and tone)
			mm.use_custom_data = true   # r: the biome's palette column; g: it floats; a: it stands in a crater
			mm.mesh = RenderCoverMeshes.mesh(ck, false)
			mm.instance_count = list.size()
			for k in range(list.size()):
				var i: int = int(list[k][0])
				_mm[i] = mm
				_slot[i] = k
				mm.set_instance_transform(k, list[k][1])
				mm.set_instance_color(k, Color.WHITE)
				mm.set_instance_custom_data(k, list[k][2])
			mm.custom_aabb = AABB(Vector3(float(c) * cw - 600.0, lo - RenderLook.COVER_BOX_PAD.x, Z - 600.0), Vector3(cw + 1200.0, hi - lo + RenderLook.COVER_BOX_PAD.x + RenderLook.COVER_BOX_PAD.y, 1200.0))
			meshes.append(["Props_%s_%d" % [ck, c], mm])
	update(S)


## Per frame: when the director's broken columns changed, each column that came in or went out is asked again, and a
## prop that no longer stands there is gone this frame (one that stands again is back).
func update(S: SimState) -> void:
	if count == 0 or ctl_frozen:
		return
	var br: PackedInt32Array = SimDir.brokenProps(S)
	if br == _broken:
		return
	var cols: Dictionary = {}
	for c in br:
		cols[c] = true
	for c in _broken:
		cols[c] = true
	_broken = br
	for c in cols:
		if not _cols.has(c):
			continue
		var stand: Array = WorldGround.matchProps(S, float(c) * SimConst.COL, float(c) * SimConst.COL, br)
		for i in _cols[c]:
			var up: int = 0
			for p in stand:
				if float(p.x) == _x[i] and String(p.kind) == _kind[i]:
					up = 1
					break
			if up == shown[i]:
				continue
			shown[i] = up
			var xf: Transform3D = _xf[i] if up == 1 else Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(_x[i], 0.0, Z))
			(_mm[i] as MultiMesh).set_instance_transform(_slot[i], xf)
			placed[i] = xf


## The props in column c that are drawn now, as [x, World's kind] (for tools).
func standing(c: int) -> Array:
	var out: Array = []
	for i in _cols.get(c, PackedInt32Array()):
		if shown[i] == 1:
			out.append([_x[i], _kind[i]])
	return out
