class_name RenderTrees
extends RefCounted
## The fellable trees (S.trees) as Art's silhouettes (docs/art/biomes-cover.md; RenderCoverMeshes), in place of the cones
## World's gen 2 readiness list still named. Each tree takes one of the tree kinds Art's cover gives the biome it stands
## in (by Art's counts as weights; the plain broadleaf where the biome names none), at the sim's height, and stands in
## the strip's plane at its own depth, drawn by the cover's shader (it reads the ground under the foot, so a dig moves
## the tree with no CPU work). The states are the tree's own (World's window 18, docs/world/forest-fire.md):
## - burn 0 and alive: the tree;
## - 0 < burn < 1 and alive: burning, its crown charred down from the top in RenderLook.TREE_BURN_STEPS hard steps;
## - burn 1 and not alive: charred, Art's burned shape (a black trunk with bare branches), shortened to TREE_CHAR_H;
## - burn 0 and not alive: felled, gone (as before).
## One MultiMesh for each kind the world's trees use, and one for its charred shape where burning changes it; a charred
## one draws nothing until a tree of its kind burns out. Render only: it reads S.trees and writes nothing back.

const KINDS: Array = ["tree", "fir", "spruce", "palm", "acacia", "jungletree", "mangrove"]   # Art's cover kinds that are trees
const FALLBACK: String = "tree"   # a biome whose cover names no tree (a city, a village, a desert's odd grove)

var meshes: Array = []   # [name, MultiMesh] for the planet copies (planet_view.gd)
var _kinds: Array = []   # per kind used: [kind, clean MultiMesh, charred MultiMesh or null, height_scale, ground_line]
var _at := PackedInt32Array()      # per tree: its kind (an index into _kinds)
var _slot := PackedInt32Array()    # per tree: its instance in that kind's meshes
var _pid := PackedInt32Array()     # per tree: the palette column of the biome it stands in
var _flip := PackedFloat32Array()  # per tree: 1 or -1, so a stand is not all one way round
var _z := PackedFloat64Array()     # per tree: its depth (the props' own, planet_view.gd)
var _drawn := PackedFloat32Array() # per tree: the state last drawn (-1 none, -2 felled, -3 charred, else the burn step)


## Pick each tree's kind and make the meshes for a new world. tree_z: each tree's depth. Seeded by the tree's index, so
## the same world draws the same trees.
func build(S: SimState, g: GroundField, tree_z: PackedFloat64Array) -> void:
	meshes.clear()
	_kinds.clear()
	var n: int = S.trees.size()
	var nc: int = SimConst.NC
	var za: PackedFloat32Array = g.row_bytes(GroundField.ROW_ZONE_A).to_float32_array()
	_at.resize(n)
	_slot.resize(n)
	_pid.resize(n)
	_flip.resize(n)
	_drawn.resize(n)
	_drawn.fill(-1.0)
	_z = tree_z.duplicate()
	var index: Dictionary = {}   # kind -> its place in _kinds
	var counts: Array = []
	var rng := RandomNumberGenerator.new()
	for ti in range(n):
		var t = S.trees[ti]
		rng.seed = hash([4242, ti])
		var col: int = posmod(int(floor(float(t.x) / SimConst.COL)), nc)
		var pid: int = int(za[col]) if za.size() == nc else 0
		var kind: String = _pick(RenderBiomeLook.name_of(pid), rng)
		if not index.has(kind):
			index[kind] = _kinds.size()
			_kinds.append([kind, null, null, RenderCoverMeshes.height_scale(kind), RenderCoverMeshes.ground_line(kind)])
			counts.append(0)
		var k: int = index[kind]
		_at[ti] = k
		_slot[ti] = counts[k]
		counts[k] += 1
		_pid[ti] = pid
		_flip[ti] = -1.0 if rng.randf() < 0.5 else 1.0
	for k in range(_kinds.size()):
		var kind: String = _kinds[k][0]
		var clean: ArrayMesh = RenderCoverMeshes.mesh(kind, false)
		var charred: ArrayMesh = RenderCoverMeshes.mesh(kind, true)
		_kinds[k][1] = _multimesh(clean, counts[k])
		meshes.append(["Trees_%s" % kind, _kinds[k][1]])
		if charred != clean:
			_kinds[k][2] = _multimesh(charred, counts[k])
			_kinds[k][2].visible_instance_count = 0   # no draw until a tree of this kind burns out
			meshes.append(["Trees_%s_charred" % kind, _kinds[k][2]])
	for ti in range(n):
		var k: int = _at[ti]
		var custom := Color((float(_pid[ti]) + 0.5) / 32.0, 0.0, 0.0, 0.0)
		for m in [1, 2]:
			var mm: MultiMesh = _kinds[k][m]
			if mm != null:
				mm.set_instance_transform(_slot[ti], _hidden(float(S.trees[ti].x)))
				mm.set_instance_color(_slot[ti], Color.WHITE)
				mm.set_instance_custom_data(_slot[ti], custom)


## Draw each tree's state where it changed (a tree's burn moves in hard steps, so a burning stand changes a few times).
func update(S: SimState) -> void:
	var steps: float = float(RenderLook.TREE_BURN_STEPS)
	for ti in range(mini(S.trees.size(), _at.size())):
		var t: SimState.TreeState = S.trees[ti]
		var burn: float = float(t.burn)
		var st: float
		if t.alive:
			st = floor(clampf(burn, 0.0, 1.0) * steps) / steps if burn < 1.0 else 1.0
		else:
			st = -3.0 if burn >= 1.0 else -2.0
		if st == _drawn[ti]:
			continue
		_drawn[ti] = st
		var k: int = _at[ti]
		var clean: MultiMesh = _kinds[k][1]
		var charred: MultiMesh = _kinds[k][2]
		var x: float = float(t.x)
		var s: float = float(t.h) * float(_kinds[k][3])
		var line: float = float(_kinds[k][4])
		if st >= 0.0:
			clean.set_instance_transform(_slot[ti], Transform3D(Basis.from_scale(Vector3(s * _flip[ti], s, s)), Vector3(x, -line * s, _z[ti])))
			clean.set_instance_custom_data(_slot[ti], Color((float(_pid[ti]) + 0.5) / 32.0, 0.0, st, 0.0))
		else:
			clean.set_instance_transform(_slot[ti], _hidden(x))
		if charred != null:
			if st == -3.0:
				charred.visible_instance_count = -1   # (all; the others are hidden)
				var sh: float = s * RenderLook.TREE_CHAR_H
				charred.set_instance_transform(_slot[ti], Transform3D(Basis.from_scale(Vector3(s * _flip[ti], sh, s)), Vector3(x, -line * sh, _z[ti])))
			else:
				charred.set_instance_transform(_slot[ti], _hidden(x))


## The cover kind tree ti was given ("" before the world is built): VFX's forest fire reads it to set its flames in the tree's crown.
func kind_at(ti: int) -> String:
	if ti < 0 or ti >= _at.size():
		return ""
	return String(_kinds[_at[ti]][0])


## One of the tree kinds Art's cover gives the biome, by Art's counts as weights; FALLBACK where it names none.
static func _pick(name: String, rng: RandomNumberGenerator) -> String:
	var list: Array = []
	var total: int = 0
	for c in RenderBiomeLook.entry(name).get("cover", []):
		if KINDS.has(String(c.get("k", ""))):
			list.append(c)
			total += int(c.get("n", 1))
	if total <= 0:
		return FALLBACK
	var r: int = rng.randi_range(0, total - 1)
	for c in list:
		r -= int(c.get("n", 1))
		if r < 0:
			return String(c.k)
	return FALLBACK


static func _multimesh(mesh: Mesh, count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true          # white: the cover's shader multiplies the vertex colour (the slot and tone)
	mm.use_custom_data = true     # r: the biome's palette column; b: the burn step
	mm.mesh = mesh
	mm.instance_count = count
	# The planet's length, the tallest tree and the props' depths; the shader lifts each foot to the ground.
	mm.custom_aabb = AABB(Vector3(-1000.0 * RenderLook.WS, -2000.0 * RenderLook.WS, RenderLook.Z_TREE_MIN * 1.5), Vector3(SimConst.W + 2000.0 * RenderLook.WS, 4000.0 * RenderLook.WS, 100.0 - RenderLook.Z_TREE_MIN * 1.5))
	return mm


static func _hidden(x: float) -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(x, 0.0, 0.0))
