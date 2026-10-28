class_name DirSigAfter
## Biomes W2 (docs/combat/biomes.md sections 2 and 6, rule 3 step 2): what a signature leaves behind and the rules its
## outcome lines play by, read from data/combat/sigvariants.json.
## - The aftermath: when a beam's front has carved its whole path, the variant row's `aftermath` is laid with
##   WorldAfter.lay on the groove, and an `aftermath` cue marks the onset (VFX's glints, dust and leaves).
## - The twists (the row's `twist`, the outcome lines marked rule:): under (a HIT drives him down into the water the
##   aftermath left; World's surfacing rule brings him up set, the water rule), skate (a GUARD push-back on the glaze
##   slides slideMul times as far), wall (a GUARD push-back runs flat to the heaved plates, where World's wall rule
##   stops it). A twist's impact waits for the groove to be carved, so the aftermath is under him when it lands.
## - The personality term (byPersonality): near people the carer narrows the bite and the villain widens it.
## - crater_shape: a cue on each shaped crater World digs (its event's `surface` is set), for craterShape().
## Gates: aftermathOn (the aftermath and the twists) with World's after.json `enabled`, and only on a gen 2 planet (the
## fine biome map); byPersonality.enabled; crater_shape with World's craters.json. All off: nothing here runs or draws.
## No random draw; no state of its own (the carve's end is the tick the front reaches the path's end).

## Tools and tests only: force aftermathOn, byPersonality.enabled and the twists (1 on, 0 off; -1 keeps the file's; the
## twists follow aftermathOn).
static var forceAfter: int = -1
static var forcePers: int = -1
static var forceTwist: int = -1

const WAIT_MAX: int = 30   # ticks a twist's impact waits for the carve at most (a beam carves its path in 0.22 s)


static func afterOn() -> bool:
	var sig: Dictionary = DirData.sigData()
	return bool(sig.get("aftermathOn", false)) if forceAfter < 0 else forceAfter == 1


static func persOn() -> bool:
	var sig: Dictionary = DirData.sigData()
	return bool(sig.get("byPersonality", {}).get("enabled", false)) if forcePers < 0 else forcePers == 1


## The aftermaths are live: the file's switch, World's, and a gen 2 planet (the fine biome map; gen 1 and the hand-made
## world never lay one).
static func laying() -> bool:
	return afterOn() and WorldAfter.on() and WorldBiomes.fineCols.size() == SimConst.NC


## A's main beam (his first in S.beams; a split's forks follow it), or null.
static func _main(S: SimState, A):
	for b in S.beams:
		if b.A == A:
			return b
	return null


# ---------------------------------------------------------------- the aftermath

## Beam b's front has carved its whole path (DirBeam.beamStep, once): lay its row's aftermath on the groove.
static func carved(S: SimState, b) -> void:
	if not laying() or _main(S, b.A) != b:
		return
	var vr: Dictionary = DirData.sigByName(b.variant)
	var a = vr.get("aftermath", null)
	if not (a is Dictionary) or not vr.has("fineId"):
		return
	var x0: float = SimWrap.wrap(b.ox)
	var x1: float = SimWrap.wrap(b.ox + b.ux * b.len)
	var D = SimRoster.opp(S, b.A)
	var n: int = WorldAfter.lay(S, a, x0, x1, int(vr.fineId), b.oz, D.x)
	if n <= 0:
		return
	# The onset (VFX's ask, docs/vfx/after-fx.md "Not done"): kind the aftermath's, x and x1 the path's ends, n columns.
	SimFx.cue(S, b.A, "aftermath", String(a.kind), b.variant)
	var e = S.out.fx[S.out.fx.size() - 1]
	e.x = x0
	e.x1 = x1
	e.n = n
	SimEvents.feed(S, b.variant + " leaves " + String(a.kind), "%d columns" % n)


# ---------------------------------------------------------------- the twists

## The row's twist for this outcome of A's beam, or {}.
static func twistFor(S: SimState, A, out: String) -> Dictionary:
	if not laying() or forceTwist == 0:
		return {}
	var b = _main(S, A)
	if b == null:
		return {}
	var tw = DirData.sigByName(b.variant).get("twist", null)
	if not (tw is Dictionary) or String(tw.outcome) != out:
		return {}
	return tw


## True while A's beam has not carved its whole path yet: a twist's impact waits a tick.
static func waiting(S: SimState, A) -> bool:
	var b = _main(S, A)
	return b != null and b.p < 1.0


## The HIT twist "under": true when there is water to drive him into at his column (a split's lead, a flooded groove,
## the sea), and he is sent straight down into it. World's surfacing rule (water.json surface) brings him up set. Water
## shallower than a wade (a floe's lead is cut 40 below the sea: after.json splitDepth) takes him in waist-deep, landed.
static func under(S: SimState, A, D) -> bool:
	var w: float = WorldWater.surfaceAt(S, D.x)
	if w <= DirWater.DRY * 0.5 or w <= WorldTerrain.groundY(S, D.x) + 1.0:
		return false
	DirLaunch.doLaunch(S, A, D, {"ux": 0.0, "uy": -1.0}, 2600.0, true)
	_told(S, A, D, "under")
	return true


## The GUARD twist "skate", after the push-back's launch: on a glazed column the push goes slideMul times as far
## (distance only; he guards throughout): the push's horizontal speed times slideMul. Measured on a gen 2 ice sheet
## (sigafter_probe) that carries him about 1.7 times as far, not 2.5: the braking is World's, so the factor is QA's to tune.
static func skate(S: SimState, A, D, tw: Dictionary) -> bool:
	if WorldAfter.kindAt(S, D.x) != WorldAfter.GLAZE:
		return false
	D.vx *= float(tw.get("slideMul", 1.0))
	_told(S, A, D, "skate")
	return true


## The GUARD twist "wall": the heaved plates ahead of the push (along ux, within the groove's pad) stop it. The push runs
## flat along the ground, at the force that reaches them, up to reachMul times the push's own; plates beyond that, or
## none, leave the push as it was (false).
static func wall(S: SimState, A, D, tw: Dictionary, ux: float, force: float) -> bool:
	var s: float = 1.0 if ux >= 0.0 else -1.0
	var c0: int = WorldAfter._col(D.x)
	var NC: int = SimConst.NC
	var reach: int = -1
	for k in range(1, WorldAfter.PAD * 4):
		if S.aftermath[posmod(c0 + int(s) * k, NC)] == WorldAfter.PLATES:
			reach = k
			break
	if reach < 0:
		return false
	var travel: float = WorldSlide.launchTravel(s, 0.0)
	var d: float = (float(reach) + 1.0) * SimConst.COL
	var v0: float = force
	var vMax: float = force * float(tw.get("reachMul", 1.0))
	if WorldSlide.slideDistance(vMax, 0.0, travel) < d:
		return false
	var v: float = maxf(v0, _speedFor(v0, d, 1.0, vMax / maxf(v0, 1e-9), travel))
	DirLaunch.doLaunch(S, A, D, {"ux": s, "uy": 0.0}, v, true)
	_told(S, A, D, "wall")
	return true


## The normalised speed in [v x lo, v x hi] whose slide on flat ground is dist (bisection; deterministic).
static func _speedFor(v: float, dist: float, lo: float, hi: float, travel: float = 1.0) -> float:
	var a: float = v * lo
	var b: float = v * hi
	for _i in range(40):
		var m: float = (a + b) * 0.5
		if WorldSlide.slideDistance(m, 0.0, travel) < dist:
			a = m
		else:
			b = m
	return b


static func _told(S: SimState, A, D, kind: String) -> void:
	var b = _main(S, A)
	var nm: String = b.variant if b != null else ""
	SimFx.cue(S, D, "sig_twist", kind, nm)
	SimEvents.feed(S, nm + " twist: " + kind, "the rule line of the variant's row")


# ---------------------------------------------------------------- the personality term

## The beam sample's [width factor, bite factor] for the firer's personality at x: near people (popNear over the launch
## planner's care radius above whenPopAbove) the carer (care > 0) takes hero's and the villain (care < 0) villain's.
## [1, 1] when off, for a fighter of no side, or where nobody is near.
static func persMul(S: SimState, A, x: float) -> Array:
	if not persOn() or A.care == 0.0:
		return [1.0, 1.0]
	var row: Dictionary = DirData.sigData().byPersonality.get("hero" if A.care > 0.0 else "villain", {})
	if row.is_empty() or WorldStructures.popNear(S, x, DirLaunch.CARE_R) <= float(row.get("whenPopAbove", 0.0)):
		return [1.0, 1.0]
	return [float(row.get("widthMul", 1.0)), float(row.get("structMul", 1.0))]


# ---------------------------------------------------------------- crater_shape

## Each live tick, after the fighters, the director and the beams have dug (DirBeam.beamStep's end): a shaped crater dug
## this tick (World's crater event with its `surface` set: craters.json on) gets a crater_shape cue (source the material;
## x, y, r, depth, rim and owner the bowl as dug). craterShape(e) gives the rest (WorldCraters.eventFor).
static func craterShapes(S: SimState) -> void:
	if not WorldCraters.on():
		return
	var found: Array = []
	var i: int = S.out.fx.size() - 1
	while i >= 0 and int(S.out.fx[i].tick) == S.tick:
		var e = S.out.fx[i]
		if String(e.type) == "crater" and String(e.surface) != "":
			found.push_front(e)
		i -= 1
	for c in found:
		SimFx.cue(S, null, "crater_shape", "", String(c.surface))
		var e = S.out.fx[S.out.fx.size() - 1]
		e.x = c.x; e.y = c.y; e.r = c.r; e.depth = c.depth; e.rim = c.rim; e.owner = c.owner


## The crater_shape cue's full record: {x, y, r, depth, rim, owner, surface, shape} (World's eventFor, its row's factors
## and looks).
static func craterShape(e) -> Dictionary:
	return WorldCraters.eventFor(e, String(e.source))
