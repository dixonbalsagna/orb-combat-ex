class_name VfxAfter
extends RefCounted
## What a beam leaves in the ground, drawn (docs/vfx/after-fx.md). World's aftermaths (sim/world/after.gd, behind data/biomes/after.json `enabled`) mark terrain columns: S.aftermath is a kind byte a column, S.aftermathT the waterTick a
## timed kind ends at, S.aftermathJobs the work still running. With the switch off the arrays are empty and this draws nothing. It reads that state and nothing else of the strip (the ground and water looks are Rendering's):
## - a fire line (BURNING): low cel flames along the strip, a thin dark smoke, a few embers, dying down in the last second;
## - a glowing strip (EMBER): steady embers rising from it until it cools;
## - a snow dump (SNOW): a powder curtain falling over the groove while it refills, a pale puff at the ground;
## - scree (SCREE): while its run is still going (a live job), tumbling chunks and dust down the slope;
## - the parted sea (OPEN): spray off the top of each water wall and foam at its foot while the trench stands;
## - the shore the wave ran up (WET): foam at the strip, strongest at the start of its wet time;
## - a split floe's lead (SPLIT): a pale sea smoke over the open water.
## The rest (glaze, cleared, plates, flooded, burnt, crust) are ground looks and have nothing for VFX to draw continuously.
## Steady and soft, never a flash: flames and embers are the pool's steady bits, the rest are flecks and puffs under the pool's own caps and area budget. Presentation only: it writes nothing of the sim, and its randomness is the
## debris pool's cosmetic stream, a fixed number of draws a bit made or not. Every look is a pure function of S.aftermath, S.aftermathT, S.aftermathJobs and the water, so a seek or a late join draws the same.

const SMOKE := Color("#4a4540")        # a warm charcoal (as the forest fire's)
const SNOW_LIT := Color("#f2f4f6")     # the ices' warm white (Art's ground lit step)
const SNOW_SHADE := Color("#c3cfda")
const MIST := Color("#dfeaf0")         # sea smoke, pale and cool
const FOAM_COLS := 6                   # the most wall columns drawn at once

static var _data: Dictionary = {}
static var _loaded: bool = false

var debris: VfxDebris
var made: Dictionary = {}              # bits asked for, by look (for the tests)
var counted: Dictionary = {}           # columns found by kind in the framing's span at the last scan (for the tests)
var _cols: Dictionary = {}             # kind -> the strip's columns nearest the pair, nearest first (at most max_cols)
var _walls: Array = []                 # the parted sea's walls: [x, foot y, top y, side]
var _scree_live: bool = false
var _acc: Dictionary = {}              # look -> bits owed
var _last_scan: int = -1000


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/biome.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary and v.get("after") is Dictionary:
			_data = v["after"]


static func _g(group: String, key: String, d: float) -> float:
	var g = _data.get(group)
	if g is Dictionary and g.has(key):
		return float(g[key])
	return d


static func _r(group: String, key: String, t: float, d0: float, d1: float) -> float:
	var g = _data.get(group)
	if g is Dictionary and g.get(key) is Array:
		return lerpf(float(g[key][0]), float(g[key][1]), t)
	return lerpf(d0, d1, t)


func reset() -> void:
	_cols = {}
	_walls = []
	_acc = {}
	_scree_live = false
	_last_scan = -1000
	made = {}
	counted = {}


## How much of a timed look is left: 1 until its last `fade` ticks, then down to 0 as it ends.
static func fade(left: float, ticks: float) -> float:
	return clampf(left / maxf(ticks, 1.0), 0.0, 1.0)


## One unfrozen tick: scan the framing's span for the strips every few ticks, make this tick's bits for each look.
func step(S: SimState, dt: float, q: float, reduced: bool) -> void:
	if debris == null or S == null or S.fighters.size() < 2 or S.aftermath.size() != SimConst.NC or S.aftermathT.size() != SimConst.NC:
		return
	warm()
	if _data.is_empty():
		return
	var every: int = maxi(1, int(_g("scan", "every", 6.0)))
	if S.tick < _last_scan or S.tick - _last_scan >= every:
		_scan(S)
		_last_scan = S.tick
	if _cols.is_empty() and _walls.is_empty():
		return
	var rn: float = q * (0.5 if reduced else 1.0)
	var now: float = S.waterTick
	var rd: SimRng = debris._rd
	var z0: float = S.fighters[0].z
	var puffs: bool = not reduced
	# a fire line: flames low along the strip, smoke, embers
	var fire: Array = _cols.get(WorldAfter.BURNING, [])
	if not fire.is_empty():
		var kf: float = 0.0
		for c in fire:
			kf += fade(float(S.aftermathT[c]) - now, _g("fire", "fade", 90.0))
		kf /= float(fire.size())
		_owe("flame", _g("fire", "rate", 0.9) * kf * float(fire.size()) * dt * rn)
		_owe("fsmoke", _g("fire", "smoke_rate", 0.22) * kf * float(fire.size()) * dt * rn)
		_owe("fember", _g("fire", "ember_rate", 0.4) * kf * float(fire.size()) * dt * rn)
		var fcap: int = int(_g("fire", "cap", 26.0))
		while _take("flame"):
			var rc: float = rd.next()
			var rj: float = rd.next()
			var rs: float = rd.next()
			var rv: float = rd.next()
			var rl: float = rd.next()
			var rz: float = rd.next()
			if debris._flame_alive >= fcap:
				continue
			var c: int = fire[mini(int(rc * float(fire.size())), fire.size() - 1)]
			var k: float = fade(float(S.aftermathT[c]) - now, _g("fire", "fade", 90.0))
			var x: float = (float(c) + 0.5 + (rj - 0.5)) * SimConst.COL
			var size: float = _r("fire", "size", rs, 30.0, 58.0) * (0.55 + 0.45 * k)
			debris.flame(x, WorldTerrain.groundY(S, x) + size * 0.25, z0 + 4.0 + rz * 10.0, 0.0, _r("fire", "rise", rv, 40.0, 110.0), size, _r("fire", "life", rl, 0.5, 0.9))
			_make("flame")
		while _take("fsmoke"):
			var sc: float = rd.next()
			var sl: float = rd.next()
			var sx: float = rd.next()
			var sy: float = rd.next()
			if not puffs:
				continue
			var c2: int = fire[mini(int(sc * float(fire.size())), fire.size() - 1)]
			var x2: float = (float(c2) + 0.5) * SimConst.COL
			var ss: float = _g("fire", "smoke_size", 38.0)
			debris.dust_puff("city", x2, WorldTerrain.groundY(S, x2) + ss * 0.8, z0 + 2.0, (sx - 0.5) * 24.0, 40.0 + 50.0 * sy, ss * 0.7, ss * 1.6, lerpf(2.2, 3.2, sl), 1, SMOKE)
			_make("fsmoke")
		while _take("fember"):
			_ember(S, fire, "fire", now, rd, z0)
	var emb: Array = _cols.get(WorldAfter.EMBER, [])
	if not emb.is_empty():
		var ke: float = 0.0
		for c in emb:
			ke += fade(float(S.aftermathT[c]) - now, _g("ember", "fade", 90.0))
		ke /= float(emb.size())
		_owe("ember", _g("ember", "rate", 0.5) * ke * float(emb.size()) * dt * rn)
		while _take("ember"):
			_ember(S, emb, "ember", now, rd, z0)
	var snow: Array = _cols.get(WorldAfter.SNOW, [])
	if not snow.is_empty():
		var kn: float = 0.0
		for c in snow:
			kn += fade(float(S.aftermathT[c]) - now, _g("snow", "fade", 24.0))
		kn /= float(snow.size())
		_owe("snow", _g("snow", "rate", 3.0) * kn * float(snow.size()) * dt * rn)
		_owe("spuff", _g("snow", "puff_rate", 0.3) * kn * float(snow.size()) * dt * rn)
		var ncap: int = int(round(_g("snow", "cap", 160.0) * q * (0.5 if reduced else 1.0)))
		while _take("snow"):
			var nc: float = rd.next()
			var nj: float = rd.next()
			var nh: float = rd.next()
			var ns: float = rd.next()
			var nf: float = rd.next()
			var nl: float = rd.next()
			var nv: float = rd.next()
			var nz: float = rd.next()
			if debris.ambient_alive >= ncap:
				continue
			var c3: int = snow[mini(int(nc * float(snow.size())), snow.size() - 1)]
			var x3: float = (float(c3) + 0.5 + (nj - 0.5)) * SimConst.COL
			debris.fleck(VfxDebris.SNOW, x3, WorldTerrain.groundY(S, x3) + _r("snow", "h", nh, 40.0, 280.0), z0 + 4.0 + nz * 12.0, (nv - 0.5) * 30.0, -_r("snow", "fall", nf, 60.0, 140.0), _r("snow", "size", ns, 7.0, 14.0), _r("snow", "life", nl, 1.0, 1.8), SNOW_LIT, SNOW_SHADE, 0, 0.0, 0.0, 3.0, nv * 2.0 - 1.0, -1e9, false, true)
			_make("snow")
		while _take("spuff"):
			var pc: float = rd.next()
			var pl: float = rd.next()
			var pv: float = rd.next()
			if not puffs:
				continue
			var c4: int = snow[mini(int(pc * float(snow.size())), snow.size() - 1)]
			var x4: float = (float(c4) + 0.5) * SimConst.COL
			var ps: float = _g("snow", "puff_size", 34.0)
			debris.dust_puff("plains", x4, WorldTerrain.groundY(S, x4) + ps * 0.4, z0 + 2.0, (pv - 0.5) * 30.0, 18.0 + 14.0 * pv, ps * 0.7, ps * 1.5, lerpf(1.2, 2.0, pl), 0, SNOW_LIT, 0.6)
			_make("spuff")
	var scree: Array = _cols.get(WorldAfter.SCREE, [])
	if _scree_live and not scree.is_empty():
		_owe("scree", _g("scree", "rate", 0.8) * float(scree.size()) * dt * rn)
		_owe("sdust", _g("scree", "puff_rate", 0.5) * float(scree.size()) * dt * rn)
		while _take("scree"):
			var cc: float = rd.next()
			var cj: float = rd.next()
			var cs: float = rd.next()
			var cl: float = rd.next()
			var cv: float = rd.next()
			var ct: float = rd.next()
			var cz: float = rd.next()
			var c5: int = scree[mini(int(cc * float(scree.size())), scree.size() - 1)]
			var x5: float = (float(c5) + 0.5 + (cj - 0.5)) * SimConst.COL
			var down: float = signf(WorldTerrain.groundY(S, x5 - SimConst.COL) - WorldTerrain.groundY(S, x5 + SimConst.COL))      # the way down the slope
			var size5: float = _r("scree", "size", cs, 8.0, 18.0)
			var key5: String = VfxPalette.biome_key(x5)
			debris.fleck(VfxDebris.CHUNK, x5, WorldTerrain.groundY(S, x5) + size5 + 10.0 * ct, z0 + 3.0 + cz * 10.0, down * (30.0 + 60.0 * cv), 20.0 + 40.0 * ct, size5, _r("scree", "life", cl, 0.8, 1.4), VfxPalette.dust(key5, "mid"), VfxPalette.dust(key5, "light"), 2, 1.0, 0.0, 4.0, cv * 2.0 - 1.0, -1e9, false, false)
			_make("scree")
		while _take("sdust"):
			var dc: float = rd.next()
			var dl: float = rd.next()
			var dv: float = rd.next()
			if not puffs:
				continue
			var c6: int = scree[mini(int(dc * float(scree.size())), scree.size() - 1)]
			var x6: float = (float(c6) + 0.5) * SimConst.COL
			var ds: float = _g("scree", "puff_size", 30.0)
			debris.dust_puff(VfxPalette.biome_key(x6), x6, WorldTerrain.groundY(S, x6) + ds * 0.3, z0 + 2.0, (dv - 0.5) * 40.0, 16.0 + 18.0 * dv, ds * 0.6, ds * 1.4, lerpf(1.0, 1.8, dl))
			_make("sdust")
	if not _walls.is_empty():
		var nw: float = float(mini(_walls.size(), FOAM_COLS))
		_owe("spray", _g("wall", "rate", 2.0) * nw * dt * rn)
		_owe("foam", _g("wall", "foam_rate", 0.5) * nw * dt * rn)
		while _take("spray"):
			var wc: float = rd.next()
			var wj: float = rd.next()
			var wl: float = rd.next()
			var wr: float = rd.next()
			var wv: float = rd.next()
			var w: Array = _walls[mini(int(wc * float(mini(_walls.size(), FOAM_COLS))), mini(_walls.size(), FOAM_COLS) - 1)]
			var side: float = float(w[3])
			debris.spray(float(w[0]) - side * wj * 5.0, float(w[2]) + 2.0 + 6.0 * wl, -side * (10.0 + 40.0 * wr), _r("wall", "rise", wv, 140.0, 300.0), _r("wall", "len", wr, 14.0, 26.0), lerpf(0.6, 1.0, wl), float(w[2]))
			_make("spray")
		while _take("foam"):
			var fc: float = rd.next()
			var fh: float = rd.next()
			var fl: float = rd.next()
			var fv: float = rd.next()
			if not puffs:
				continue
			var nf2: int = mini(_walls.size(), FOAM_COLS)
			var w2: Array = _walls[mini(int(fc * float(nf2)), nf2 - 1)]
			var side2: float = float(w2[3])
			debris.foam(float(w2[0]) - side2 * 6.0, lerpf(float(w2[1]), float(w2[2]), fh * 0.85) + 4.0, -side2 * (6.0 + 16.0 * fv), 12.0 + 18.0 * fv, _g("wall", "foam_size", 30.0), lerpf(1.0, 1.7, fl))
			_make("foam")
	var wet: Array = _cols.get(WorldAfter.WET, [])
	if not wet.is_empty():
		var kw: float = 0.0
		for c in wet:
			kw += 1.0 - fade(float(WorldAfter.K_WET_TICKS) - (float(S.aftermathT[c]) - now), _g("wet", "age", 80.0))      # strongest at the start of its wet time
		kw /= float(wet.size())
		_owe("wet", _g("wet", "rate", 0.5) * kw * float(wet.size()) * dt * rn)
		while _take("wet"):
			var ec: float = rd.next()
			var ej: float = rd.next()
			var es: float = rd.next()
			var el: float = rd.next()
			var ev: float = rd.next()
			if not puffs:
				continue
			var c7: int = wet[mini(int(ec * float(wet.size())), wet.size() - 1)]
			var x7: float = (float(c7) + 0.5 + (ej - 0.5)) * SimConst.COL
			debris.foam(x7, WorldTerrain.groundY(S, x7) + 3.0, (ev - 0.5) * 16.0, 8.0 + 10.0 * ev, _r("wet", "size", es, 14.0, 26.0), _r("wet", "life", el, 0.8, 1.3))
			_make("wet")
	var split: Array = _cols.get(WorldAfter.SPLIT, [])
	if not split.is_empty() and puffs:
		_owe("mist", _g("split", "rate", 0.12) * float(split.size()) * dt * rn)
		while _take("mist"):
			var mc: float = rd.next()
			var ml: float = rd.next()
			var ms: float = rd.next()
			var mv: float = rd.next()
			var c8: int = split[mini(int(mc * float(split.size())), split.size() - 1)]
			var x8: float = (float(c8) + 0.5) * SimConst.COL
			var sf: float = WorldWater.surfaceAt(S, x8)
			var y8: float = (sf if sf > WorldWater.DRY else WorldTerrain.groundY(S, x8))
			debris.dust_puff("ocean", x8, y8 + 6.0, z0 + 2.0, (mv - 0.5) * 14.0, _r("split", "rise", mv, 16.0, 34.0), _r("split", "size", ms, 24.0, 40.0) * 0.7, _r("split", "size", ms, 24.0, 40.0) * 1.6, _r("split", "life", ml, 2.4, 3.4), 2, MIST, 0.5)
			_make("mist")


## An ember off a strip (a fire line's or a glowing one's): the pool's steady ember bit, rising.
func _ember(S: SimState, list: Array, group: String, now: float, rd: SimRng, z0: float) -> void:
	var ec: float = rd.next()
	var ej: float = rd.next()
	var el: float = rd.next()
	var ev: float = rd.next()
	var eh: float = rd.next()
	var c: int = list[mini(int(ec * float(list.size())), list.size() - 1)]
	var x: float = (float(c) + 0.5 + (ej - 0.5)) * SimConst.COL
	debris.ember_bit(x, WorldTerrain.groundY(S, x) + 3.0 + 14.0 * eh, z0 + 4.0, (ev - 0.5) * 60.0, _r(group, "rise", ev, 40.0, 110.0), _r(group, "length", el, 10.0, 16.0), _r(group, "life", el, 1.0, 1.8), _g(group, "grav", 0.12))
	_make("ember" if group == "ember" else "fember")


func _owe(key: String, n: float) -> void:
	_acc[key] = minf(float(_acc.get(key, 0.0)) + n, 3.0)


func _take(key: String) -> bool:
	var v: float = float(_acc.get(key, 0.0))
	if v >= 1.0:
		_acc[key] = v - 1.0
		return true
	return false


func _make(key: String) -> void:
	made[key] = int(made.get(key, 0)) + 1


## The strips within the framing's span of the pair, by kind, nearest first and at most max_cols each; the parted sea's walls; whether a scree run is still going.
func _scan(S: SimState) -> void:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	var dxp: float = SimWrap.sdx(f0.x, f1.x)
	var mid: float = SimWrap.wrap(f0.x + dxp * 0.5)
	var span: float = clampf(_g("span", "base", 900.0) + _g("span", "per_sep", 0.7) * absf(dxp), _g("span", "base", 900.0), _g("span", "max", 2600.0))
	var NC: int = SimConst.NC
	var c0: int = int(floor(mid / SimConst.COL))
	var n: int = mini(int(ceil(span / SimConst.COL)), NC / 2)
	var found: Dictionary = {}
	counted = {}
	for d in range(-n, n + 1):
		var c: int = posmod(c0 + d, NC)
		var k: int = S.aftermath[c]
		if k == 0:
			continue
		if k != WorldAfter.BURNING and k != WorldAfter.EMBER and k != WorldAfter.SNOW and k != WorldAfter.SCREE and k != WorldAfter.WET and k != WorldAfter.SPLIT and k != WorldAfter.OPEN:
			continue
		counted[k] = int(counted.get(k, 0)) + 1
		if not found.has(k):
			found[k] = []
		found[k].append([absi(d), c])
	var keep: int = maxi(1, int(_g("scan", "max_cols", 40.0)))
	_cols = {}
	for k in found.keys():
		if k == WorldAfter.OPEN:
			continue
		var arr: Array = found[k]
		arr.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
		var out: Array = []
		for j in range(mini(keep, arr.size())):
			out.append(int(arr[j][1]))
		_cols[k] = out
	_walls = []
	if found.has(WorldAfter.OPEN):
		for e in found[WorldAfter.OPEN]:
			var c: int = int(e[1])
			for side in [-1, 1]:
				var cn: int = posmod(c + side, NC)
				if S.aftermath[cn] == WorldAfter.OPEN:
					continue
				var xn: float = (float(cn) + 0.5) * SimConst.COL
				var top: float = WorldWater.surfaceAt(S, xn)
				if top <= WorldWater.DRY:
					continue
				var xc: float = (float(c) + 0.5) * SimConst.COL
				_walls.append([xc + float(side) * SimConst.COL * 0.5, WorldTerrain.groundY(S, xc), top, side, int(e[0])])
		_walls.sort_custom(func(a, b): return a[4] < b[4] or (a[4] == b[4] and a[0] < b[0]))
	_scree_live = false
	for w in S.aftermathJobs:
		if w is Array and w.size() > WorldAfter.I_T0 and int(w[4]) == WorldAfter.J_SCREE:
			_scree_live = true
			break
