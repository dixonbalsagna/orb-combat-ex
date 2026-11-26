class_name WorldGlobe
extends RefCounted
## The treadmill's rules for a mark, in round form (docs/world/globe-step2.md; docs/ep/proposals/terrain-globe-plan.md 4.3): what a crater dug in the planet store reads about the ground around it. No shafts: a new
## crater's depth is held to 0.26 of its radius less the relief already there, the ring around its centre against the centre, read without the record it supersedes. Settling: where the wall of the bowl would be
## steeper than the angle of repose, it widens and shallows with its volume kept. All of it reads the store (WorldStore.heightDeltaX) at planet points and nothing else, so it is pure in the store, float64, and uses
## no trig and no random number: eight fixed bearings, a basis taken from the point.

static var _bear: Array = []   # the eight bearings as [cos, sin] pairs: 1, sqrt(1/2) (from its bits, SimMathx.f64) and 0, in order round
const WALL_STEPS: Array = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.7, 2.0]   # where along a bearing (in bowl radii) the wall is sampled


static var blind: bool = false   # tests only: the shaft cap reads no relief (the check's negative control)


## The eight fixed bearings, [cos, sin] each, a quarter turn apart and between: no trig, the same bits everywhere.
static func bearings() -> Array:
	if _bear.is_empty():
		var h: float = SimMathx.f64("3fe6a09e667f3bcd")   # sqrt(1/2)
		_bear = [[1.0, 0.0], [h, h], [0.0, 1.0], [-h, h], [-1.0, 0.0], [-h, -h], [0.0, -1.0], [h, -h]]
	return _bear


static func _R() -> float:
	return SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)


## Two unit vectors across the unit direction q, the same from the same q: [e1x, e1y, e1z, e2x, e2y, e2z].
static func basis(q: Array) -> Array:
	var hx: float = 0.0
	var hy: float = 1.0
	if absf(q[1]) >= 0.9:
		hx = 1.0
		hy = 0.0
	# e1 = q x h, normalised
	var ax: float = q[1] * 0.0 - q[2] * hy
	var ay: float = q[2] * hx - q[0] * 0.0
	var az: float = q[0] * hy - q[1] * hx
	var n: float = sqrt(ax * ax + ay * ay + az * az)
	ax /= n
	ay /= n
	az /= n
	# e2 = q x e1
	var bx: float = q[1] * az - q[2] * ay
	var by: float = q[2] * ax - q[0] * az
	var bz: float = q[0] * ay - q[1] * ax
	return [ax, ay, az, bx, by, bz]


## The unit direction `dist` units from q along bearing `bi` (0 to 7) of basis `b`.
static func pointAt(q: Array, b: Array, bi: int, dist: float) -> Array:
	var s: float = dist / _R()
	var c: float = bearings()[bi][0]
	var d: float = bearings()[bi][1]
	var px: float = q[0] + (b[0] * c + b[3] * d) * s
	var py: float = q[1] + (b[1] * c + b[4] * d) * s
	var pz: float = q[2] + (b[2] * c + b[5] * d) * s
	var n: float = sqrt(px * px + py * py + pz * pz)
	return [px / n, py / n, pz / n]


## The mean of the store's ground on a ring of `radius` units round q (eight fixed bearings), without record `skip`.
static func ringMean(S, q: Array, radius: float, skip: int = -1) -> float:
	var b: Array = basis(q)
	var sum: float = 0.0
	for bi in range(bearings().size()):
		var p: Array = pointAt(q, b, bi, radius)
		sum += WorldStore.heightDeltaX(S, p[0], p[1], p[2], skip)
	return sum / float(bearings().size())


## The relief at q: the ring at `ringR` against the centre (positive where the centre is lower), both without record `skip`.
static func relief(S, q: Array, ringR: float, skip: int = -1) -> float:
	if int(S.storeN) == 0 or blind:
		return 0.0
	return ringMean(S, q, ringR, skip) - WorldStore.heightDeltaX(S, q[0], q[1], q[2], skip)


## The steepest wall the ground would have with a bowl of radius R, depth d and rim hr added at q: the largest drop between neighbouring samples (WALL_STEPS bowl radii out along eight bearings) of the store's
## ground without record `skip` plus the new bowl, per unit of distance.
static func steepest(S, q: Array, R: float, d: float, hr: float, skip: int = -1) -> float:
	var b: Array = basis(q)
	var worst: float = 0.0
	var haveStore: bool = int(S.storeN) > 0
	for bi in range(bearings().size()):
		var prev: float = 0.0
		for si in range(WALL_STEPS.size()):
			var u: float = WALL_STEPS[si]
			var h: float = WorldCrater.profile(u, d, hr)
			if haveStore:
				var p: Array = pointAt(q, b, bi, u * R) if u > 0.0 else q
				h += WorldStore.heightDeltaX(S, p[0], p[1], p[2], skip)
			if si > 0:
				worst = maxf(worst, absf(h - prev) / ((u - WALL_STEPS[si - 1]) * R))
			prev = h
	return worst


## The steepest wall of a groove (a trench's or a scar's profile -depth x (1 - u^2)^2 across its half width): 8 / (3 root 3) of its depth over its half width.
const GROOVE_SLOPE: float = 1.5396


## A groove settled to the angle of repose: [depth, halfWidth]. One whose wall would be steeper than `repose` is widened by k and shallowed by k (the cross-section kept; k = root of s / repose) until its wall is at the angle of repose, as
## the strip's relaxation left it: a trench is never deeper than its target, and never a wall. Off with craters.json globe.settleGrooves (shipped off) or globe.settle.
static func settleGroove(depth: float, hw: float) -> Array:
	if not WorldCraters.globeSettleGrooves() or hw <= 0.0 or depth <= 0.0:
		return [depth, hw]
	var repose: float = WorldCraters.globeRepose()
	var s: float = GROOVE_SLOPE * depth / hw
	if s <= repose:
		return [depth, hw]
	var k: float = sqrt(s / repose)
	return [depth / k, hw * k]


## The settled bowl: [R, d, hr] after the wall has been eased to the angle of repose. The wall steeper than `repose` widens the bowl by k and shallows it by k^2 (the volume kept: k = (s / repose)^(1/3));
## the widened bowl is held to the cap again and its depth to the shaft cap again (`dCap`, the cap on the new R less the relief), so at the cap it only gets shallower. The rim shallows with the depth.
static func settle(S, q: Array, R: float, d: float, hr: float, rcap: float, reliefMax: float, relief_: float, skip: int = -1) -> Array:
	var repose: float = WorldCraters.globeRepose()
	var s: float = steepest(S, q, R, d, hr, skip)
	if s <= repose:
		return [R, d, hr]
	var k: float = SimDetMath.pow(s / repose, 1.0 / 3.0)
	var R2: float = minf(R * k, rcap)
	var kk: float = R2 / R
	var d2: float = minf(d / (kk * kk), maxf(0.0, reliefMax * (R2 / R) - relief_))
	var hr2: float = hr * (d2 / d) if d > 0.0 else hr
	return [R2, d2, hr2]
