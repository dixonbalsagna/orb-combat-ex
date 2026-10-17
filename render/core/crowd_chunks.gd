class_name RenderCrowdChunks
extends RefCounted
## The crowd in spatial chunks (Performance's audit, docs/perf/audit-2026-10-16.md: the whole crowd, 1,800 people and
## 259 k primitives, was one MultiMesh drawn whole every frame). Each chunk is its own MultiMesh holding a contiguous run
## of crowd indices whose spots lie within RenderLook.CROWD_CHUNK of each other along the planet, with a culling box
## round them, so the camera draws only the chunks it can see. The same calls as a MultiMesh's, by the crowd index (ci)
## the planet view and the flight use.
##
## Nothing drawn changes. The crowd shader's idle hop takes its phase from the figure's index: a chunk's material
## carries its first index (id_base), and INSTANCE_ID + id_base is the index the whole crowd's MultiMesh had. A figure
## the flight carries out of its chunk's box (a runner to a shelter, across the seam) widens that box, and it is not
## narrowed again in the match, so no figure is ever culled while it could be seen. Presentation only.

var chunks: Array = []                  # one MultiMesh a chunk
var firsts := PackedInt32Array()        # each chunk's first crowd index (its material's id_base)
var chunk_of := PackedInt32Array()      # per crowd index: its chunk
var _x0 := PackedFloat32Array()         # each chunk's box along x (planet x, 0 to W), its figures' spots and the pad
var _x1 := PackedFloat32Array()
var _box: AABB                          # the y and z of every chunk's box
var _pad: float = 0.0


## The crowd's chunks for spots xs (planet x per crowd index, in index order): a new chunk starts where the next spot
## would take a chunk's spread over width. mesh: the figure; box: the y and z every chunk's box spans (its x is set
## here); pad: how far a figure reaches from its spot (boosted, cowering or turned).
static func build(mesh: Mesh, xs: PackedFloat64Array, width: float, pad: float, box: AABB) -> RenderCrowdChunks:
	var c := RenderCrowdChunks.new()
	c._box = box
	c._pad = pad
	c.chunk_of.resize(xs.size())
	var first: int = 0
	var lo: float = 0.0
	var hi: float = 0.0
	for ci in range(xs.size() + 1):
		var x: float = xs[ci] if ci < xs.size() else 0.0
		if ci > first and (ci == xs.size() or maxf(hi, x) - minf(lo, x) > width):
			c._add(mesh, first, ci - first, lo, hi)
			first = ci
		if ci == first:
			lo = x
			hi = x
		else:
			lo = minf(lo, x)
			hi = maxf(hi, x)
	return c


func _add(mesh: Mesh, first: int, count: int, lo: float, hi: float) -> void:
	var k: int = chunks.size()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = count
	chunks.append(mm)
	firsts.append(first)
	_x0.append(lo - _pad)
	_x1.append(hi + _pad)
	_set_box(k)
	for ci in range(first, first + count):
		chunk_of[ci] = k


func _set_box(k: int) -> void:
	(chunks[k] as MultiMesh).custom_aabb = AABB(Vector3(_x0[k], _box.position.y, _box.position.z), Vector3(_x1[k] - _x0[k], _box.size.y, _box.size.z))


## How many figures in all.
func count() -> int:
	return chunk_of.size()


func set_instance_transform(ci: int, t: Transform3D) -> void:
	var k: int = chunk_of[ci]
	(chunks[k] as MultiMesh).set_instance_transform(ci - firsts[k], t)
	# A figure drawn outside its chunk's box widens the box (a hidden one, scaled to nothing, does not).
	var x: float = t.origin.x
	if t.basis.get_scale().x > 0.0 and (x - _pad < _x0[k] or x + _pad > _x1[k]):
		_x0[k] = minf(_x0[k], x - _pad)
		_x1[k] = maxf(_x1[k], x + _pad)
		_set_box(k)


func set_instance_color(ci: int, c: Color) -> void:
	var k: int = chunk_of[ci]
	(chunks[k] as MultiMesh).set_instance_color(ci - firsts[k], c)


func set_instance_custom_data(ci: int, d: Color) -> void:
	var k: int = chunk_of[ci]
	(chunks[k] as MultiMesh).set_instance_custom_data(ci - firsts[k], d)


func get_instance_transform(ci: int) -> Transform3D:
	var k: int = chunk_of[ci]
	return (chunks[k] as MultiMesh).get_instance_transform(ci - firsts[k])
