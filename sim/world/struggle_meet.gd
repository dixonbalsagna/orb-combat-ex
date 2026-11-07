class_name WorldStruggleMeet
extends RefCounted
## Where a beam struggle does its damage: the meeting point (World, docs/world/struggle-meet.md; Game Design's block "By stage, as data for World" in docs/design/power-scale.md; Legal RL-232, RL-242, RL-243, RL-246).
## data/biomes/craters.json struggleMeet, OFF by default (a match is byte for byte as it was; nothing calls this unless Encounter's struggle does, and then only with the switch on).
##
## During the struggle: struggleRing() is one ring at the point, growing from 1 to 3 body heights over the struggle, at most one every ringMinGapSec. The buildings inside it take the beam's building damage (each
##   stronger beam's, the structure factor of his tier, its ring cap and keep), as one blast does: a first ring wears a standing building and does not finish it (stages.json leaveFrac), the next may. No digging.
## At the end, once, every ending: meet() is the wave and the crater in a single step. Both beams bring their fighter's energy times their stage share (E(level) x stage / count); E_meet is the two added, times 9 if
##   either is a signature; the dug energy is E_meet x f_end x f_height; the bowl is R_BASE x sqrt(dug) (the special dig, WorldCrater.dig, depth 0.22 of it). Glass: every tower within the crater's radius before the height
##   cut loses its windows (stage 1) and no more: an air burst shatters windows and fells nothing. Fall: inside the bowl a building falls (levelIn's rule), falling off from the centre out to the lip. Structures only:
##   nothing here reads a building's people (the glass is local: no one is counted), a barred landmark (WorldSettle.noTarget) takes nothing, and nothing aims at a place.
## The beams stop carving when their fronts meet (DirBeam: each live beam's stopAt, Encounter's), an overwhelm's winner carves from the point outward (Encounter), and a detonation's old blast at the point is not
## fired when this is on (Encounter): meet() is that blast.

const KEYS_FEND: Array = ["detonate", "time", "overwhelm", "letGo"]

static var _errors: Array = []
static var _checked: bool = false


static func block() -> Dictionary:
	var b: Variant = WorldCraters.data().get("struggleMeet", {})
	return b if b is Dictionary else {}


static func on() -> bool:
	return bool(block().get("enabled", false)) and errors().is_empty()


## Problems with the block (a missing or out-of-range number): while there are any the module stays off.
static func errors() -> Array:
	if _checked:
		return _errors
	_checked = true
	_errors = []
	var b: Dictionary = block()
	if b.is_empty():
		return _errors
	var need := {"energy": ["sigMul"], "fEnd": KEYS_FEND, "fEndByRun": ["fullRunSec"], "radius": ["k", "depthShare"], "heightReach": ["ofRadius"], "during": ["ringFromBh", "ringToBh", "ringMinGapSec"],
		"wave": ["fallReach", "dent", "keep", "glassHpShare", "bodyHeight"]}
	for k in need:
		if not (b.get(k, null) is Dictionary):
			_errors.append("struggleMeet: %s is missing" % k)
			continue
		for kk in need[k]:
			if not b[k].has(kk) or not (b[k][kk] is float or b[k][kk] is int):
				_errors.append("struggleMeet: %s.%s is missing" % [k, kk])
	if not b.has("minE") or float(b.get("minE", -1.0)) < 0.0:
		_errors.append("struggleMeet: minE (0 or more) is missing")
	if _errors.is_empty():
		var w: Dictionary = b.wave
		if float(b.fEndByRun.fullRunSec) <= 0.0 or float(b.radius.k) <= 0.0 or float(b.heightReach.ofRadius) <= 0.0 or float(b.energy.sigMul) < 1.0:
			_errors.append("struggleMeet: fullRunSec, radius.k and heightReach.ofRadius above 0, energy.sigMul at least 1")
		if float(w.fallReach) <= 0.0 or float(w.fallReach) > 1.0 or float(w.dent) < 0.0 or float(w.dent) > 1.0 or float(w.keep) < 0.0 or float(w.keep) > 1.0 or float(w.glassHpShare) <= 0.0 or float(w.glassHpShare) >= 1.0:
			_errors.append("struggleMeet: wave.fallReach in (0, 1], dent and keep in [0, 1], glassHpShare in (0, 1)")
		if float(b.during.ringFromBh) <= 0.0 or float(b.during.ringToBh) < float(b.during.ringFromBh) or float(b.during.ringMinGapSec) <= 0.0:
			_errors.append("struggleMeet: during needs ringFromBh above 0, ringToBh at least ringFromBh and ringMinGapSec above 0")
	return _errors


## What a beam brings: the fighter's energy (the model's, SimPower.energy) times its stage share, `stage` of `count` (the top stage spends all of it).
static func beamEnergy(S: SimState, slot: int, stage: int, count: int) -> float:
	var f = S.fighters[slot]
	return SimPower.energy(f) * float(clampi(stage, 1, maxi(1, count))) / float(maxi(1, count))


## A beam's stage and count from the event's side ({slot, stage, count, sig}): a side that does not say has one stage of one (all of his energy: the top stage spends all of it).
static func _stageOf(side: Dictionary) -> Array:
	var count: int = maxi(1, int(side.get("count", 1)))
	return [int(side.get("stage", count)), count]


## The share dug by how the struggle ended; overwhelm and let-go count the run, `run` seconds of fullRunSec.
static func fEnd(how: String, run: float) -> float:
	var b: Dictionary = block()
	var fe: Dictionary = b.fEnd
	match how:
		"detonate":
			return float(fe.detonate)
		"overwhelmed", "overwhelm":
			return float(fe.overwhelm) * clampf(run / float(b.fEndByRun.fullRunSec), 0.0, 1.0)
		"letgo", "letGo":
			return float(fe.letGo) * clampf(run / float(b.fEndByRun.fullRunSec), 0.0, 1.0)
	return float(fe.time)


## Pure: the sizes for two beams' energies (before the 9), whether either is a signature, the ending, the run in seconds and the point's lowest height above the ground in the last second.
## Returns {meet, fEnd, e0, r0, reach, fH, dug, r, kind}: e0 and r0 are before the height cut (the glass's), dug and r after it; kind is "bowl", "scorch" (under minE) or "air" (above the reach).
static func plan(ea: float, ed: float, sig: bool, how: String, run: float, height: float) -> Dictionary:
	var b: Dictionary = block()
	var meet: float = (ea + ed) * (float(b.energy.sigMul) if sig else 1.0)
	var fe: float = fEnd(how, run)
	var e0: float = meet * fe
	var k: float = float(b.radius.k)
	var r0: float = k * sqrt(e0)
	var reach: float = float(b.heightReach.ofRadius) * r0
	var fh: float = clampf(1.0 - maxf(height, 0.0) / reach, 0.0, 1.0) if reach > 0.0 else 0.0
	var dug: float = e0 * fh
	var kind: String = "bowl"
	if fh <= 0.0:
		kind = "air"
	elif dug < float(b.minE):
		kind = "scorch"
	return {"meet": meet, "fEnd": fe, "e0": e0, "r0": r0, "reach": reach, "fH": fh, "dug": dug, "r": k * sqrt(dug), "kind": kind}


## The end of a struggle, once, in one step. ev: {x, y, z (the point), how ("time", "detonate", "overwhelmed", "letgo"), run (seconds it ran), lowY (the point's lowest y in the last second, else y),
## a: {slot, stage, count, sig}, d: {slot, stage, count, sig}}. Returns {on, kind, r, r0, glassR, dug, meet, rec, fell, glass} (on false: nothing was done). The caller adds r, glassR and kind to the end cue.
static func meet(S: SimState, ev: Dictionary) -> Dictionary:
	if not on():
		return {"on": false}
	var a: Dictionary = ev.a
	var d: Dictionary = ev.d
	var fa = S.fighters[int(a.slot)]
	var fd = S.fighters[int(d.slot)]
	var hi = fa if fa.tier >= fd.tier else fd
	var x: float = SimWrap.wrap(float(ev.x))
	var z: float = float(ev.get("z", 0.0))
	var g: float = WorldTerrain.groundY(S, x)
	var lowY: float = float(ev.get("lowY", ev.y))
	var sa: Array = _stageOf(a)
	var sd: Array = _stageOf(d)
	var p: Dictionary = plan(beamEnergy(S, int(a.slot), int(sa[0]), int(sa[1])), beamEnergy(S, int(d.slot), int(sd[0]), int(sd[1])), bool(a.get("sig", false)) or bool(d.get("sig", false)),
		String(ev.how), float(ev.get("run", 0.0)), lowY - g)
	var out: Dictionary = {"on": true, "kind": p.kind, "r": 0.0, "r0": p.r0, "glassR": p.r0, "dug": p.dug, "meet": p.meet, "rec": null, "fell": 0, "glass": 0}
	var rec = null
	if p.kind == "bowl":
		# the dug energy is already times the 9 when a signature is in it, and the special dig multiplies by 9: hand it a ninth
		rec = WorldCrater.dig(S, x, float(p.dug) / WorldCrater.SPECIAL_E_MULT, hi, "beam", 0.0, 1.0, true, z)
		out.rec = rec
		if rec != null:
			out.r = float(rec.r)
			out.fell = _fall(S, x, z, float(rec.r), hi)
	elif p.kind == "scorch":
		WorldCrater.scorch(S, x, (WorldCrater.beamPower(fa) + WorldCrater.beamPower(fd)) * 0.5, "", hi, z)
	out.glass = _glass(S, x, z, float(p.r0), hi)
	SimFx.dust(S, x, g + 8.0, clampi(int(float(p.r0) / 150.0), 3, 14), "#a89f92", z)
	return out


## Inside the bowl a building falls, falling off from the centre: every standing building within fallReach of the radius is levelled (twice its hp: "implode", a fall each, the rest folded into one event
## past the event cap), up to the cap (the stronger fighter's beamLevelCapShare of the first ring), the rest left at `keep` of their hp; from there to the lip a building takes dent x its hp falling to nothing
## at the lip. A barred landmark is left alone (RL-242, RL-243). Nothing reads a building's people or a place's size. Returns the number levelled.
static func _fall(S: SimState, x: float, z: float, r: float, cause) -> int:
	var w: Dictionary = block().wave
	var reach: float = float(w.fallReach) * r
	var dent: float = float(w.dent)
	var keep: float = float(w.keep)
	var cap: int = maxi(1, int(SimMathx.jround(float(cause.ld.beamLevelCapShare[clampi(int(cause.tier), 1, 4) - 1]) * float(WorldStructures.ringCount(S)))))
	var levelled: int = 0
	S.world.fallTick = -1.0
	SimField.far()
	for bi in WorldStructures.near(S, x, r):
		var b = S.buildings[bi]
		if not b.alive or WorldSettle.noTarget(b.landmark):
			continue
		var dd: float = SimDetMath.hypot(SimWrap.sdx(x, b.x), float(b.z) - z)
		if dd <= reach:
			var lost0: float = S.world.structuresLost
			WorldStructures.damageBuilding(S, b, float(b.maxhp) * 2.0, cause, "implode", x, 0.0, false, keep if levelled >= cap else 0.0)
			if S.world.structuresLost > lost0:
				levelled += 1
		elif dd < r and dent > 0.0 and r > reach:
			WorldStructures.damageBuilding(S, b, float(b.maxhp) * dent * (1.0 - (dd - reach) / (r - reach)), cause, "burst", x)
	SimField.near()
	if S.world.fallFold > 0.0:
		SimFx.buildingFall(S, -1, x, 0.0, 0.0, 0.0, "implode", 0.0, x, 0.0, S.world.fallFold)
		S.world.fallFold = 0.0
	return levelled


## Tower glass: every standing tower within r of the point (before the height cut) is taken to glassHpShare of its hit points if it was above: stage 1 (windows out), never lower, nothing felled. Local: no one is counted.
## Returns the number of towers it took.
static func _glass(S: SimState, x: float, z: float, r: float, cause) -> int:
	var share: float = float(block().wave.glassHpShare)
	var n: int = 0
	SimField.far()
	for bi in WorldStructures.near(S, x, r):
		var b = S.buildings[bi]
		if not b.alive or b.kind != "tower" or WorldSettle.noTarget(b.landmark):
			continue
		if SimDetMath.hypot(SimWrap.sdx(x, b.x), float(b.z) - z) > r:
			continue
		var cut: float = b.hp - share * b.maxhp
		if cut > 0.0:
			var s0: int = WorldStructures.stage(b)
			WorldStructures.damageBuilding(S, b, cut, cause, "burst", x, 0.0, true)
			WorldStructures.stageEmit(S, b, s0, cause, x)
			n += 1
	SimField.near()
	return n


## True when a ring is due: the last was `last` ticks ago (a negative last: none yet), the least gap apart.
static func ringDue(last: int, tick: int) -> bool:
	return last < 0 or float(tick - last) >= float(block().during.ringMinGapSec) * 60.0


## One ring of the struggle at the point (ev as in meet(), x, y, z, and a: {slot}, d: {slot}); frac is how far through the struggle it is, 0 to 1: the ring is 1 body height across at 0 and 3 at 1.
## The buildings inside take the beam's damage (the stronger fighter's, the structure factor of his tier), as one blast does: a standing building is left at leaveFrac of its hit points at least by the first ring, and the next ring may take it. No digging, no groove. Emits the
## cue struggle_ring (x, y, z, amount = the ring's radius in units, n = ring's body heights x 100) for VFX's ring. Returns {r, hurt}.
static func ring(S: SimState, ev: Dictionary, frac: float) -> Dictionary:
	if not on():
		return {"r": 0.0, "hurt": 0}
	var bl: Dictionary = block()
	var du: Dictionary = bl.during
	var bh: float = float(bl.wave.bodyHeight)
	var t: float = clampf(frac, 0.0, 1.0)
	var bhs: float = float(du.ringFromBh) + (float(du.ringToBh) - float(du.ringFromBh)) * t
	var r: float = bhs * bh
	var x: float = SimWrap.wrap(float(ev.x))
	var y: float = float(ev.y)
	var hurt: int = 0
	var best = null
	var bestD: float = -1.0
	var bestCap: int = 1
	var bestSf: float = 1.0
	for key in ["a", "d"]:
		var f = S.fighters[int(ev[key].slot)]
		var ix: int = clampi(int(f.tier) - 1, 0, 3)
		var sf: float = float(f.ld.beamStructure[ix])
		var dmg: float = (110.0 + WorldCrater.beamPower(f) * 75.0) * sf
		if dmg > bestD:
			bestD = dmg
			best = f
			bestCap = maxi(1, int(SimMathx.jround(float(f.ld.beamLevelCapShare[ix]) * float(WorldStructures.ringCount(S)))))
	# one ring is one hit, by the stronger of the two beams: the same call a beam's blast makes (a standing building is left at leaveFrac of its hit points, the next ring may take it)
	hurt = WorldStructures.damageArea(S, x, y, r, bestD, best, false, 0.0, bestCap, 0.25, 1.0, "none")
	SimFx.cue(S, S.fighters[int(ev.a.slot)], "struggle_ring", "", "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.x = x
	e.y = y
	e.z = float(ev.get("z", 0.0))
	e.amount = r
	e.n = int(round(bhs * 100.0))
	return {"r": r, "hurt": hurt}
