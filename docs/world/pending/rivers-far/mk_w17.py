"""Window 17 (World, 2026-10-26): rivers on the far land (the far map's river layer), behind rivers.json (off).   python mk_w17.py <root>   (root: main plus the rivers diff)
 - sim/world/farmap.gd: WorldFarMap.rivers (a layer like `sites`: 0 none, 1 to 3 the river's size at that texel), made from the planet's flow field when the rivers are on; river(qx, qy, qz) reads it
 - sim/world/tools/rivers_check.gd: the layer's checks
Render-only data for Rendering's far land (a ribbon on the texels the layer marks); nothing in the sim reads it and no Rendering file is touched."""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def farmap(s):
    s = rep(s, '''var sites := PackedByteArray()   # the settlements' layer''', '''var rivers := PackedByteArray()   # the rivers' layer (rivers.json on, gen 2): 0 none, 1 to 3 a river's size at the texel (WorldRivers flow over the river line: under 4 times it, under 16 times, more), whole from the start
var sites := PackedByteArray()   # the settlements' layer''')
    s = rep(s, '''	sites.fill(0)
	_mark_sites()
''', '''	sites.fill(0)
	_mark_sites()
	rivers.resize(n * n)
	rivers.fill(0)
	if WorldRivers.enabled() and P.gen >= 2:
		_mark_rivers()
''')
    s = rep(s, '''## The places beside a ring (WorldPlanet.farPlaces)''', '''## The rivers' layer: each river segment of the planet's flow field (from a river cell's centre to its receiver's, WorldRivers) is walked at a third of a texel and marks the texels it crosses with its size class
## (the larger of two crossing). About 1,000 segments, a few thousand marks: a few milliseconds.
func _mark_rivers() -> void:
	var F: WorldRivers.Flow = WorldRivers.flowOf(P)
	if F == null:
		return
	var G: WorldClimate.Grid = P.grid
	var ref: float = WorldRivers.K_RIVER
	var texel: float = 3.54 / float(n)   # a texel's mean angle, radians (at most about twice)
	for i in range(F.w * F.h):
		var rc: int = F.recv[i]
		if rc < 0 or G.ht[i] < 0.0 or F.flow[i] < ref:
			continue
		var cls: int = 1 if F.flow[i] < 4.0 * ref else (2 if F.flow[i] < 16.0 * ref else 3)
		var ax: float = F.px[i]
		var ay: float = F.py[i]
		var az: float = F.pz[i]
		var dx: float = F.px[rc] - ax
		var dy: float = F.py[rc] - ay
		var dz: float = F.pz[rc] - az
		var seg: float = sqrt(dx * dx + dy * dy + dz * dz)
		var steps: int = maxi(2, int(ceil(seg / texel * 3.0)))
		for s in range(steps + 1):
			var t: float = float(s) / float(steps)
			var qx: float = ax + dx * t
			var qy: float = ay + dy * t
			var qz: float = az + dz * t
			var ql: float = sqrt(qx * qx + qy * qy + qz * qz)
			var uv: Vector2 = _uv(qx / ql, qy / ql, qz / ql)
			var k: int = _tex(int(floor(uv.x + 0.5)), int(floor(uv.y + 0.5)))
			rivers[k] = maxi(int(rivers[k]), cls)


## The river under a unit vector: 0 none, 1 to 3 its size (the nearest texel's, as biome()).
func river(qx: float, qy: float, qz: float) -> int:
	var t: Vector2 = _uv(qx, qy, qz)
	return rivers[_tex(int(floor(t.x + 0.5)), int(floor(t.y + 0.5)))]


## The places beside a ring (WorldPlanet.farPlaces)''')
    return s


def check(s):
    s = rep(s, '''	WorldRivers.setOn(false)
	print("RIVERS: %d check(s) failed" % fails)''', '''	# the far land's layer (render-only): the river cells' own texels are marked, the sizes are 1 to 3, none with the switch off, the same twice
	WorldRivers.setOn(false)
	var P7 := WorldPlanet.make(7)
	var off := WorldFarMap.new(P7, 128)
	var offMarks: int = 0
	for v in off.rivers:
		offMarks += int(v)
	WorldRivers.setOn(true)
	var FM := WorldFarMap.new(P7, 128)
	var FM2 := WorldFarMap.new(P7, 128)
	var F7: WorldRivers.Flow = WorldRivers.flowOf(P7)
	var marked: int = 0
	var classOk: bool = true
	for v in FM.rivers:
		if int(v) > 0:
			marked += 1
		if int(v) > 3:
			classOk = false
	var hit: int = 0
	var cells: int = 0
	for i in range(F7.w * F7.h):
		if P7.grid.ht[i] >= 0.0 and F7.flow[i] >= WorldRivers.K_RIVER and F7.recv[i] >= 0:
			cells += 1
			if FM.river(F7.px[i], F7.py[i], F7.pz[i]) > 0:
				hit += 1
	ok(offMarks == 0 and marked > cells and hit == cells and classOk and FM.rivers == FM2.rivers, "the far map's river layer: nothing with the rivers off; on, %d texels marked for %d river cells, every river cell's own texel among them, sizes 1 to 3, the same twice" % [marked, cells])
	WorldRivers.setOn(false)
	print("RIVERS: %d check(s) failed" % fails)''')
    return s


rw(R, 'sim/world/farmap.gd', farmap)
rw(R, 'sim/world/tools/rivers_check.gd', check)
print('w17 applied')
