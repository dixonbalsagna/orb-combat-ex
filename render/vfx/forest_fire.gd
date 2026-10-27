class_name VfxForestFire
extends RefCounted
## Forest fire (docs/vfx/forest-fire.md; Orb: the landscape answers back). World's burn field (sim/world/fire.gd, behind data/biomes/fire.json `enabled`) sets a tree's own `burn`: 0 and alive is a tree, 0 < burn < 1
## and alive is burning, burn 1 and not alive is charred. The sim has no VFX of it beyond one `fire` event at the foot on ignition and on burn-out (earth.gd throws a few flames then). This draws what a burning tree
## looks like: cel flames in its crown (the pool's FLAME bit), a few steady orange embers rising, and a thin column of smoke, all from the tree's own state, so a seek, a snapshot or a late join draws the same fire.
## Everything is capped: the nearest few burning trees to the fighters get flames (the cap leaves the pool's explosions their room), the rest of a big stand only smoke, nothing is made beyond the framing's span.
## Steady, never a flash: a flame grows in over a tenth of a second and burns down (shard_view), the embers are the pool's steady ramp, the smoke is dark and thin; no luminance step on the frame. Presentation only:
## it reads S.trees and writes nothing of the sim; its randomness is the debris pool's cosmetic stream, a fixed number of draws a bit made or not.

const SMOKE := Color("#4a4540")      # a warm charcoal (the puff darkens it a quarter more)

static var _data: Dictionary = {}
static var _loaded: bool = false

var debris: VfxDebris
var made: Dictionary = {}                # bits asked for, by kind (for the tests)
var burning: int = 0                     # trees burning at the last scan, all of them
var drawn: int = 0                       # trees given flames at the last scan
var _list: Array = []                    # the indices of the burning trees nearest the pair, nearest first
var _acc: Dictionary = {}                # tree index -> Vector3(flames, embers, smoke) owed
var _last_scan: int = -1000
var _tz: PackedFloat64Array = PackedFloat64Array()   # each tree's depth, the planet view's own (render.trees stream)
var _zf: Dictionary = {}                 # a listed tree -> the depth its fire is drawn at: the tree's own, or the nearest tree in front of it that would hide it


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/biome.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary and v.get("fire") is Dictionary:
			_data = v["fire"]


static func _g(group: String, key: String, d: float) -> float:
	var g = _data.get(group)
	if g is Dictionary and g.has(key):
		return float(g[key])
	return d


static func _r(group: String, key: String, i: int, d: float) -> float:
	var g = _data.get(group)
	if g is Dictionary and g.get(key) is Array:
		return float(g[key][i])
	return d


func reset() -> void:
	_list = []
	_acc = {}
	_zf = {}
	_last_scan = -1000
	burning = 0
	drawn = 0
	made = {}


## The intensity of a tree that has burned for `b` of its life: it catches up over the first tenth, burns full, and dies down over the last third.
static func intensity(b: float) -> float:
	return smoothstep(0.0, 0.1, b) * (1.0 - 0.6 * smoothstep(0.7, 1.0, b))


## One unfrozen tick: scan for the burning trees every few ticks, make this tick's flames, embers and smoke for the nearest of them.
func step(S: SimState, dt: float, q: float, reduced: bool) -> void:
	if debris == null or S == null or S.fighters.size() < 2 or S.trees.is_empty():
		return
	warm()
	if _data.is_empty():
		return
	var every: int = maxi(1, int(_g("scan", "every", 6.0)))
	if S.tick < _last_scan or S.tick - _last_scan >= every:
		_scan(S)
		_last_scan = S.tick
	if _list.is_empty():
		return
	var rn: float = q * (0.5 if reduced else 1.0)
	var fcap: int = int(_g("flame", "cap", 36.0))
	var rd: SimRng = debris._rd
	for i in _list:
		var t = S.trees[i]
		if not (t.alive and t.burn > 0.0 and t.burn < 1.0):
			continue
		var k: float = intensity(t.burn)
		var z: float = float(_zf.get(i, _tz[i]))
		var gy: float = WorldTerrain.groundY(S, t.x, z)
		var front: float = RenderLook.TREE_W * 0.5      # in front of the cone's skin (the planet view's tree is a cone half TREE_W wide at its foot), or the depth test hides the fire inside it
		var a: Vector3 = _acc.get(i, Vector3(fposmod(float(i) * 0.618034, 1.0), fposmod(float(i) * 0.381966, 1.0), fposmod(float(i) * 0.754877, 1.0)))
		a.x += _g("flame", "rate", 2.4) * k * dt * rn
		a.y += _g("ember", "rate", 0.9) * k * dt * rn
		a.z += _g("smoke", "rate", 0.8) * dt * (0.3 + 0.7 * k) * rn
		while a.x >= 1.0:
			a.x -= 1.0
			var rx: float = rd.next()
			var rh: float = rd.next()
			var rs: float = rd.next()
			var rv: float = rd.next()
			var rl: float = rd.next()
			var rw: float = rd.next()
			if debris._flame_alive >= fcap:
				continue
			var size: float = clampf(RenderLook.TREE_W * (_r("flame", "size", 0, 0.22) + (_r("flame", "size", 1, 0.34) - _r("flame", "size", 0, 0.22)) * rs) * (0.55 + 0.45 * k), _g("flame", "min", 24.0), _g("flame", "max", 90.0))
			var hf: float = _r("flame", "h", 0, 0.12) + (_r("flame", "h", 1, 0.62) - _r("flame", "h", 0, 0.12)) * rh
			var y: float = gy + t.h * hf
			var x: float = t.x + (rx - 0.5) * RenderLook.TREE_W * 0.6 * (1.0 - hf)      # on the cone's skin: it narrows to the tip
			var vy: float = _r("flame", "rise", 0, 50.0) + (_r("flame", "rise", 1, 120.0) - _r("flame", "rise", 0, 50.0)) * rv
			var life: float = _r("flame", "life", 0, 0.6) + (_r("flame", "life", 1, 1.0) - _r("flame", "life", 0, 0.6)) * rl
			debris.flame(x, y, z + front, (rw - 0.5) * 24.0, vy, size, life)
			made["flame"] = int(made.get("flame", 0)) + 1
		while a.y >= 1.0:
			a.y -= 1.0
			var ex: float = rd.next()
			var eh: float = rd.next()
			var evx: float = rd.next()
			var evy: float = rd.next()
			var el: float = rd.next()
			var length: float = _r("ember", "length", 0, 12.0) + (_r("ember", "length", 1, 18.0) - _r("ember", "length", 0, 12.0)) * ex
			var vy: float = _r("ember", "rise", 0, 80.0) + (_r("ember", "rise", 1, 170.0) - _r("ember", "rise", 0, 80.0)) * evy
			var life: float = _r("ember", "life", 0, 1.2) + (_r("ember", "life", 1, 2.0) - _r("ember", "life", 0, 1.2)) * el
			debris.ember_bit(t.x + (ex - 0.5) * RenderLook.TREE_W * 0.5 * (1.0 - (0.45 + 0.45 * eh)), gy + t.h * (0.45 + 0.45 * eh), z + front, (evx - 0.5) * 80.0, vy, length, life, _g("ember", "grav", 0.15))
			made["ember"] = int(made.get("ember", 0)) + 1
		while a.z >= 1.0:
			a.z -= 1.0
			var sx: float = rd.next()
			var sl: float = rd.next()
			var svx: float = rd.next()
			var svy: float = rd.next()
			if reduced:
				continue
			var ss: float = t.h * _g("smoke", "size", 0.35) * (0.6 + 0.4 * k)
			debris.dust_puff("city", t.x + (sx - 0.5) * t.h * 0.3, gy + t.h * 0.9, z + front * 0.5, (svx - 0.5) * 28.0, 40.0 + 50.0 * svy, ss * 0.7, ss * 1.6, _r("smoke", "life", 0, 2.4) + (_r("smoke", "life", 1, 3.4) - _r("smoke", "life", 0, 2.4)) * sl, 1, SMOKE)
			made["smoke"] = int(made.get("smoke", 0)) + 1
		_acc[i] = a


## The burning trees within the framing's span of the pair, nearest first, at most max_trees; every other burning tree is only counted.
func _scan(S: SimState) -> void:
	if _tz.size() != S.trees.size():
		_depths(S)
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	var dxp: float = SimWrap.sdx(f0.x, f1.x)
	var mid: float = SimWrap.wrap(f0.x + dxp * 0.5)
	var span: float = clampf(_g("span", "base", 900.0) + _g("span", "per_sep", 0.7) * absf(dxp), _g("span", "base", 900.0), _g("span", "max", 2600.0))
	var cand: Array = []
	burning = 0
	for i in range(S.trees.size()):
		var t = S.trees[i]
		if t.alive and t.burn > 0.0:
			burning += 1
			var d: float = absf(SimWrap.sdx(mid, t.x))
			if d <= span:
				cand.append([d, i])
	cand.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var keep: int = maxi(1, int(_g("scan", "max_trees", 24.0)))
	_list = []
	for j in range(mini(keep, cand.size())):
		_list.append(int(cand[j][1]))
	drawn = _list.size()
	_zf = {}
	var cover: float = RenderLook.TREE_W * 0.6
	for i in _list:
		var zi: float = _tz[i]
		for j in range(S.trees.size()):
			if j != i and S.trees[j].alive and _tz[j] > zi and absf(SimWrap.sdx(S.trees[i].x, S.trees[j].x)) < cover:
				zi = _tz[j]
		_zf[i] = zi
	for key in _acc.keys():
		if not _list.has(key):
			_acc.erase(key)


## Each tree's depth in the planet view's own sequence (render/core/planet_view.gd, the `render.trees` stream: a depth, then a colour draw, per tree): the fire sits in the tree's plane.
func _depths(S: SimState) -> void:
	_tz.resize(S.trees.size())
	var tr := SimRng.new(SimRng.deriveSeed(4242, "render.trees"))
	for ti in range(S.trees.size()):
		_tz[ti] = tr.range_(RenderLook.Z_TREE_MIN, RenderLook.Z_TREE_MAX)
		tr.next()
