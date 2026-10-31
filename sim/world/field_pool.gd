class_name WorldFieldPool
extends RefCounted
## The node pool: the canonical and sub nodes (beyond the bake's) that earlier matches on a planet read, kept with the bake's cache (docs/world/gen3-field.md; Performance's load split: the ring read is the biggest
## piece left of a warm load). A node is a point of the planet, not of a ring, so a node read for one ring serves every ring: the pool grows as rings are visited and is written whole when a load ends having
## read something new. Natively the ring read is 227 ms of which 215 are 3,700 reads of the planet's function; a warm pool leaves 25.
##
## The envelope is WorldFieldCache's blob (key text with the data hash, Godot version, seed, cells, stride, sub; length; SHA-256), and four nodes of the pool are read fresh and compared bit for bit before it is
## used. The pool is capped (CAP nodes); past it nothing more is added and the file is left as it is.

const CAP: int = 60000
const WITNESSES: int = 4


static func enabled() -> bool:
	return WorldFieldCache.enabled() and bool(WorldField.data().get("cache", {}).get("pool", false))


static func keyOf(F: WorldField.Field) -> String:
	return "%s|pool|seed %d|cells %d|stride %d|sub %d" % [WorldFieldCache.baseKey(), F.seed, F.N, F.stride, F.sub]


## Reads the pool into F (nodes F does not hold yet). True when something was loaded.
static func load(F: WorldField.Field) -> bool:
	if not enabled():
		return false
	var b: PackedByteArray = WorldFieldCache.readBlob(keyOf(F))
	if b.size() < 8:
		return false
	var nc: int = b.decode_u32(0)
	var ns: int = b.decode_u32(4)
	if b.size() != 8 + nc * (4 + 4 + 1 + 1) + ns * (8 + 4 + 4):
		return false
	var o: int = 8
	var idx: PackedInt32Array = b.slice(o, o + nc * 4).to_int32_array()
	o += nc * 4
	var hh: PackedFloat32Array = b.slice(o, o + nc * 4).to_float32_array()
	o += nc * 4
	var bb: PackedByteArray = b.slice(o, o + nc)
	o += nc
	var ff: PackedByteArray = b.slice(o, o + nc)
	o += nc
	var skeys: PackedInt64Array = b.slice(o, o + ns * 8).to_int64_array()
	o += ns * 8
	var sh: PackedFloat32Array = b.slice(o, o + ns * 4).to_float32_array()
	o += ns * 4
	var sbv: PackedInt32Array = b.slice(o, o + ns * 4).to_int32_array()
	# witnesses: a few canonical nodes read fresh now must be the pool's
	var s2: int = F.side * F.side
	for w in range(mini(WITNESSES, nc)):
		var k: int = (nc * (2 * w + 1)) / (2 * mini(WITNESSES, nc))
		var face: int = idx[k] / s2
		var rem: int = idx[k] - face * s2
		var j: int = rem / F.side
		var i: int = rem - j * F.side
		WorldField._read(F, WorldField.dirOf(face, i, j, F.N))
		if PackedFloat32Array([WorldField._vh])[0] != hh[k] or WorldField._vb != bb[k] or WorldField._vf != ff[k]:
			return false
	for k in range(nc):
		if F.b[idx[k]] == WorldField.UNKNOWN:
			F.h[idx[k]] = hh[k]
			F.b[idx[k]] = bb[k]
			F.f[idx[k]] = ff[k]
			F.extra.append(idx[k])
	for k in range(ns):
		if not F.sh.has(skeys[k]):
			F.sh[skeys[k]] = sh[k]
			F.sb[skeys[k]] = sbv[k]
			F.extraSub.append(skeys[k])
	F.poolLoaded = nc + ns
	return nc + ns > 0


## Writes the pool (the loaded and the new nodes) when this load read something new and the pool is within the cap.
static func store(F: WorldField.Field) -> void:
	if not enabled():
		return
	var nc: int = F.extra.size()
	var ns: int = F.extraSub.size()
	if nc + ns == F.poolLoaded or nc + ns > CAP:
		return
	var out := PackedByteArray()
	var head := PackedByteArray()
	head.resize(8)
	head.encode_u32(0, nc)
	head.encode_u32(4, ns)
	out.append_array(head)
	var idx := PackedInt32Array()
	var hh := PackedFloat32Array()
	var bb := PackedByteArray()
	var ff := PackedByteArray()
	for ix in F.extra:
		idx.append(ix)
		hh.append(F.h[ix])
		bb.append(F.b[ix])
		ff.append(F.f[ix])
	out.append_array(idx.to_byte_array())
	out.append_array(hh.to_byte_array())
	out.append_array(bb)
	out.append_array(ff)
	var sk := PackedInt64Array()
	var sh := PackedFloat32Array()
	var sbv := PackedInt32Array()
	for key in F.extraSub:
		sk.append(key)
		sh.append(F.sh[key])
		sbv.append(F.sb[key])
	out.append_array(sk.to_byte_array())
	out.append_array(sh.to_byte_array())
	out.append_array(sbv.to_byte_array())
	WorldFieldCache.writeBlob(keyOf(F), out)
	F.poolLoaded = nc + ns
