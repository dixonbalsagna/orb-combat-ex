class_name WorldLand
extends RefCounted
## Planet generation 2's landforms (docs/world/planet-gen2.md, window 3; data/biomes/land.json). Called by WorldPlanet.ground for a gen 2 planet, over the stored continents: ridged ranges where seeded plates
## close on each other, rifts where they part, a shoreline moved by noise (bays and capes), plateaus with steep sides on high dry ground and canyons cut into them. Generation 1 never reaches it.
##
## The plates are a handful of seeded points on the sphere, each with a drift along the ground. At a point the plates near the nearest make pairs; each pair's two drifts say whether the pair closes, and its
## dot-product difference (wobbled by a noise so the line is not straight) is the distance to the edge between them. A pair's term depends on the pair and the point alone and is gated off smoothly where a third
## plate is nearer than both, so the ground is continuous across every plate edge and every triple junction. float64, + - * / sqrt floor and the planet's own noise only; the plates are a pure function of the
## seed and the data, made once for a planet. The data's numbers are read into typed statics at load (a dictionary lookup per number per point is too slow in this hot function).

const PATH := "res://data/biomes/land.json"
const SCHEMA := "biomes.land/1"

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""

static var K_KEEP: float = 1.0
static var K_WOB_SCALE: float = 9000.0
static var K_WOB_OCT: int = 1
static var K_WOB_AMP: float = 0.05
static var K_WOB_SEED: int = 0
static var K_R_AMP: float = 0.0
static var K_R_WIDTH: float = 0.09
static var K_R_SCALE: float = 3200.0
static var K_R_OCT: int = 2
static var K_R_LO: float = 0.4
static var K_R_SEED: int = 0
static var K_R_MINCONV: float = 0.05
static var K_R_SEA: float = 0.2
static var K_F_AMP: float = 0.0
static var K_F_WIDTH: float = 0.05
static var K_F_SEA: float = 0.0
static var K_C_BAND: float = 260.0
static var K_C_SA: float = 5200.0
static var K_C_OA: int = 1
static var K_C_AA: float = 0.0
static var K_C_SB: float = 1300.0
static var K_C_OB: int = 1
static var K_C_AB: float = 0.0
static var K_C_SEED: int = 0
static var K_P_ABOVE: float = 450.0
static var K_P_MSCALE: float = 14000.0
static var K_P_MOCT: int = 1
static var K_P_MLO: float = 0.46
static var K_P_MHI: float = 0.58
static var K_P_MSEED: int = 0
static var K_P_STEP: float = 380.0
static var K_P_RISER: float = 0.3
static var K_P_MIX: float = 0.9
static var K_P_FADE: float = 220.0
static var K_K_SCALE: float = 6000.0
static var K_K_OCT: int = 1
static var K_K_SEED: int = 0
static var K_K_EDGE: float = 0.82
static var K_K_DEPTH: float = 0.0
static var K_K_ABOVE: float = 160.0
static var K_PO_SCALE: float = 14000.0
static var K_PO_OCT: int = 2
static var K_PO_AMP: float = 0.0
static var K_PO_SEED: int = 0


class Plates extends RefCounted:
	var n: int = 0
	var cx := PackedFloat64Array()
	var cy := PackedFloat64Array()
	var cz := PackedFloat64Array()
	var vx := PackedFloat64Array()   # the drift: a vector along the ground at the centre, its length the speed
	var vy := PackedFloat64Array()
	var vz := PackedFloat64Array()


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


## The share of the stored planet's own range relief a gen 2 planet keeps.
static func keep() -> float:
	if not _loaded:
		_load()
	return K_KEEP


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("land.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("land.json: not a %s object" % SCHEMA)
		return
	for k in ["plates", "ranges", "rifts", "coast", "plateaus", "canyons", "polar", "keep"]:
		if not j.has(k):
			_errors.append("land.json: %s is missing" % k)
	if _errors.is_empty():
		if int(j.plates.n) < 4:
			_errors.append("land.json: plates.n is at least 4")
		if float(j.plateaus.maskHi) <= float(j.plateaus.maskLo):
			_errors.append("land.json: plateaus.maskHi is above maskLo")
		if float(j.plateaus.step) <= 0.0 or float(j.plateaus.riser) <= 0.0 or float(j.plateaus.riser) > 1.0 or float(j.plateaus.fade) <= 0.0:
			_errors.append("land.json: plateaus.step and fade above 0, riser in (0, 1]")
		if float(j.canyons.edge) >= 1.0:
			_errors.append("land.json: canyons.edge is under 1")
		if float(j.keep) < 0.0 or float(j.keep) > 1.0:
			_errors.append("land.json: keep is in [0, 1]")
	if not _errors.is_empty():
		return
	_d = j
	_hash = str(text.hash())
	K_KEEP = float(j.keep)
	var pw: Dictionary = j.plates
	K_WOB_SCALE = float(pw.wobScale)
	K_WOB_OCT = int(pw.wobOct)
	K_WOB_AMP = float(pw.wobAmp)
	K_WOB_SEED = int(pw.wobSeed)
	var rg: Dictionary = j.ranges
	K_R_AMP = float(rg.amp)
	K_R_WIDTH = float(rg.width)
	K_R_SCALE = float(rg.ridgeScale)
	K_R_OCT = int(rg.ridgeOct)
	K_R_LO = float(rg.ridgeLo)
	K_R_SEED = int(rg.ridgeSeed)
	K_R_MINCONV = float(rg.minConv)
	K_R_SEA = float(rg.sea)
	var rt: Dictionary = j.rifts
	K_F_AMP = float(rt.amp)
	K_F_WIDTH = float(rt.width)
	K_F_SEA = float(rt.seaRidge)
	var co: Dictionary = j.coast
	K_C_BAND = float(co.band)
	K_C_SA = float(co.scaleA)
	K_C_OA = int(co.octA)
	K_C_AA = float(co.ampA)
	K_C_SB = float(co.scaleB)
	K_C_OB = int(co.octB)
	K_C_AB = float(co.ampB)
	K_C_SEED = int(co.seed)
	var pt: Dictionary = j.plateaus
	K_P_ABOVE = float(pt.above)
	K_P_MSCALE = float(pt.maskScale)
	K_P_MOCT = int(pt.maskOct)
	K_P_MLO = float(pt.maskLo)
	K_P_MHI = float(pt.maskHi)
	K_P_MSEED = int(pt.maskSeed)
	K_P_STEP = float(pt.step)
	K_P_RISER = float(pt.riser)
	K_P_MIX = float(pt.mix)
	K_P_FADE = float(pt.fade)
	var cn: Dictionary = j.canyons
	K_K_SCALE = float(cn.scale)
	K_K_OCT = int(cn.oct)
	K_K_SEED = int(cn.seed)
	K_K_EDGE = float(cn.edge)
	K_K_DEPTH = float(cn.depth)
	K_K_ABOVE = float(cn.above)
	var po: Dictionary = j.polar
	K_PO_SCALE = float(po.scale)
	K_PO_OCT = int(po.oct)
	K_PO_AMP = float(po.amp)
	K_PO_SEED = int(po.seed)


## How far the polar zone's edge moves at a point (in the sine of the latitude): WorldPlanet.surfAt adds it to the data's polarY for a gen 2 planet, so the ordinary ground ends raggedly.
static func polarWob(P: WorldPlanet.Planet, px: float, py: float, pz: float) -> float:
	if not _loaded:
		_load()
	return (WorldPlanet._fbm(P.R, px, py, pz, K_PO_SCALE, K_PO_OCT, P.seed + K_PO_SEED) - 0.5) * 2.0 * K_PO_AMP


## The plates of a planet: made once, kept on the planet. Best-candidate centres (each the farthest from the ones before out of `tries` draws), a drift of at least speedMin along the ground.
static func platesOf(P: WorldPlanet.Planet) -> Plates:
	if P.plates != null:
		return P.plates
	var D: Dictionary = data().plates
	var r := SimRng.new((P.seed + int(D.seed)) & 0xFFFFFFFF)
	var pl := Plates.new()
	var n: int = int(D.n)
	pl.n = n
	for i in range(n):
		var best: Array = WorldPlanet._randUnit(r)
		if i > 0:
			var bd: float = -1.0e9
			for k in range(int(D.tries)):
				var c: Array = best if k == 0 else WorldPlanet._randUnit(r)
				var dmin: float = 1.0e9
				for j in range(i):
					var dd: float = 1.0 - (c[0] * pl.cx[j] + c[1] * pl.cy[j] + c[2] * pl.cz[j])   # 0 on top of another, 2 opposite
					if dd < dmin:
						dmin = dd
				if dmin > bd:
					bd = dmin
					best = c
		pl.cx.append(best[0])
		pl.cy.append(best[1])
		pl.cz.append(best[2])
		# the drift: a random direction made tangent at the centre
		var u: Array = WorldPlanet._randUnit(r)
		var dot: float = u[0] * best[0] + u[1] * best[1] + u[2] * best[2]
		var tx: float = u[0] - dot * best[0]
		var ty: float = u[1] - dot * best[1]
		var tz: float = u[2] - dot * best[2]
		var tl: float = sqrt(tx * tx + ty * ty + tz * tz)
		if tl < 1.0e-6:
			tx = 1.0
			ty = 0.0
			tz = 0.0
			tl = 1.0
		var sp: float = float(D.speedMin) + (1.0 - float(D.speedMin)) * r.next()
		pl.vx.append(tx / tl * sp)
		pl.vy.append(ty / tl * sp)
		pl.vz.append(tz / tl * sp)
	P.plates = pl
	return pl


## The plate nearest a point (for tools and checks).
static func nearest(P: WorldPlanet.Planet, px: float, py: float, pz: float) -> int:
	var pl: Plates = platesOf(P)
	var b: float = -2.0
	var bi: int = 0
	for i in range(pl.n):
		var d: float = px * pl.cx[i] + py * pl.cy[i] + pz * pl.cz[i]
		if d > b:
			b = d
			bi = i
	return bi


## A smooth bump with compact support: 1 at 0, 0 at and beyond 2.5 w, (1 - (x / 2.5 w)^2)^2 between, so a term cut off at its support's edge leaves no step.
static func _bump(x: float, w: float) -> float:
	var q: float = (x / (2.5 * w)) * (x / (2.5 * w))
	if q >= 1.0:
		return 0.0
	var a: float = 1.0 - q
	return a * a


static func _ss(a: float) -> float:
	if a <= 0.0:
		return 0.0
	if a >= 1.0:
		return 1.0
	return a * a * (3.0 - 2.0 * a)


## The distance to the nearest edge at a point (the dot-product difference of the two nearest plates, wobbled; 0 on the edge) and the closing rate of that pair (-1 parting to 1 closing): for tools that draw the
## plates' edges. The ground itself uses _terms.
static var _eEdge: float = 0.0
static var _eConv: float = 0.0


static func _edge(P: WorldPlanet.Planet, px: float, py: float, pz: float) -> void:
	if not _loaded:
		_load()
	var pl: Plates = platesOf(P)
	var b1: float = -2.0
	var b2: float = -2.0
	var i1: int = 0
	var i2: int = 0
	for i in range(pl.n):
		var d: float = px * pl.cx[i] + py * pl.cy[i] + pz * pl.cz[i]
		if d > b1:
			b2 = b1
			i2 = i1
			b1 = d
			i1 = i
		elif d > b2:
			b2 = d
			i2 = i
	var wob: float = (WorldPlanet._fbm(P.R, px, py, pz, K_WOB_SCALE, K_WOB_OCT, P.seed + K_WOB_SEED) - 0.5) * 2.0 * K_WOB_AMP
	_eEdge = (b1 - b2) + wob
	var tx: float = pl.cx[i2] - pl.cx[i1]
	var ty: float = pl.cy[i2] - pl.cy[i1]
	var tz: float = pl.cz[i2] - pl.cz[i1]
	var dp: float = tx * px + ty * py + tz * pz
	tx -= dp * px
	ty -= dp * py
	tz -= dp * pz
	var tl: float = sqrt(tx * tx + ty * ty + tz * tz)
	if tl < 1.0e-9:
		_eConv = 0.0
		return
	_eConv = SimMathx.jclamp(((pl.vx[i1] - pl.vx[i2]) * tx + (pl.vy[i1] - pl.vy[i2]) * ty + (pl.vz[i1] - pl.vz[i2]) * tz) / tl * 0.5, -1.0, 1.0)


## The weights the plate edges give a point: _rA the closing edges' (Σ closing rate × edge bump × gate over the pairs of plates with one of them near the nearest), _rB the parting edges'. A pair is read from
## its nearer plate i (the larger dot product), against each plate k farther than i; the gate is 1 for the nearest plate and fades to 0 where i is farther from the nearest than the gate's reach.
static var _rA: float = 0.0
static var _rB: float = 0.0
static var _dk := PackedFloat64Array()


static func _terms(P: WorldPlanet.Planet, px: float, py: float, pz: float) -> void:
	var pl: Plates = platesOf(P)
	var n: int = pl.n
	if _dk.size() != n:
		_dk.resize(n)
	var b1: float = -2.0
	for i in range(n):
		var d: float = px * pl.cx[i] + py * pl.cy[i] + pz * pl.cz[i]
		_dk[i] = d
		if d > b1:
			b1 = d
	var wr: float = K_R_WIDTH
	var wf: float = K_F_WIDTH
	var wm: float = wr if wr > wf else wf
	var cut: float = 2.5 * wm
	var wg: float = 0.5 * wm
	var reach: float = 2.5 * wg
	_rA = 0.0
	_rB = 0.0
	var wob: float = 1.0e9
	var mc: float = K_R_MINCONV
	for i in range(n):
		var di: float = _dk[i]
		if di < b1 - reach:
			continue
		var gate: float = _bump(b1 - di, wg)   # 1 for the nearest plate itself
		for k in range(n):
			var dk: float = _dk[k]
			if k == i or dk > di or (dk == di and k < i):
				continue
			if di - dk > cut + K_WOB_AMP:
				continue
			if wob > 1.0e8:
				wob = (WorldPlanet._fbm(P.R, px, py, pz, K_WOB_SCALE, K_WOB_OCT, P.seed + K_WOB_SEED) - 0.5) * 2.0 * K_WOB_AMP
			var e: float = (di - dk) + wob
			if absf(e) > cut:
				continue
			var tx: float = pl.cx[k] - pl.cx[i]
			var ty: float = pl.cy[k] - pl.cy[i]
			var tz: float = pl.cz[k] - pl.cz[i]
			var dp: float = tx * px + ty * py + tz * pz
			tx -= dp * px
			ty -= dp * py
			tz -= dp * pz
			var tl: float = sqrt(tx * tx + ty * ty + tz * tz)
			if tl < 1.0e-9:
				continue
			var conv: float = ((pl.vx[i] - pl.vx[k]) * tx + (pl.vy[i] - pl.vy[k]) * ty + (pl.vz[i] - pl.vz[k]) * tz) / tl * 0.5
			if conv > 1.0:
				conv = 1.0
			elif conv < -1.0:
				conv = -1.0
			if conv > mc:
				_rA += (conv - mc) / (1.0 - mc) * _bump(e, wr) * gate
			elif conv < -mc:
				_rB += (-conv - mc) / (1.0 - mc) * _bump(e, wf) * gate


## The gen 2 ground at a point: `h` is the stored planet's ground there (its continents and its range blobs, the blobs scaled by keep). Returns the new height.
static func shape(P: WorldPlanet.Planet, px: float, py: float, pz: float, h: float) -> float:
	if not _loaded:
		_load()
	_terms(P, px, py, pz)
	var R: float = P.R
	var s0: int = P.seed
	if _rA > 0.0:
		var ridged: float = 1.0 - absf(2.0 * WorldPlanet._fbm(R, px, py, pz, K_R_SCALE, K_R_OCT, s0 + K_R_SEED) - 1.0)
		var wl: float = K_R_SEA + (1.0 - K_R_SEA) * _ss((h + 600.0) / 900.0)   # on land and shallows a whole range, over the deep sea only the share `sea` of it (island arcs, not new continents)
		h += K_R_AMP * _rA * (K_R_LO + (1.0 - K_R_LO) * ridged) * wl
	if _rB > 0.0:
		var lw: float = _ss((h + 100.0) / 300.0)   # land to sea, smoothly: a valley on land, a ridge on the sea floor
		h += _rB * (K_F_SEA * (1.0 - lw) - K_F_AMP * lw)
	# the shoreline
	var w: float = _bump(h, K_C_BAND)
	if w > 0.0:
		h += w * ((WorldPlanet._fbm(R, px, py, pz, K_C_SA, K_C_OA, s0 + K_C_SEED) - 0.5) * 2.0 * K_C_AA + (WorldPlanet._fbm(R, px, py, pz, K_C_SB, K_C_OB, s0 + K_C_SEED + 17) - 0.5) * 2.0 * K_C_AB)
	# plateaus and canyons on high dry ground
	var fadeIn: float = _ss((h - K_P_ABOVE) / K_P_FADE)
	if fadeIn > 0.0:
		var m: float = WorldPlanet._fbm(R, px, py, pz, K_P_MSCALE, K_P_MOCT, s0 + K_P_MSEED)
		var s: float = _ss((m - K_P_MLO) / (K_P_MHI - K_P_MLO)) * fadeIn
		if s > 0.0:
			var t: float = h / K_P_STEP
			var f: float = floor(t)
			var u: float = _ss(((t - f) - 0.5) / K_P_RISER + 0.5)
			h += ((f + u) * K_P_STEP - h) * K_P_MIX * s
			var cfade: float = _ss((h - K_K_ABOVE) / K_P_FADE)
			if cfade > 0.0:
				var c: float = 1.0 - absf(2.0 * WorldPlanet._fbm(R, px, py, pz, K_K_SCALE, K_K_OCT, s0 + K_K_SEED) - 1.0)
				h -= K_K_DEPTH * _ss((c - K_K_EDGE) / (1.0 - K_K_EDGE)) * s * cfade
	return h
