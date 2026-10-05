class_name WorldBlast
## What an energy shot does to the world where it ends (docs/world/ground-contact.md section 23; SimShots.hitWorld calls this): a
## crater in the ground, the structures around the point, a splash in water. Numbers are data (data/biomes/blast.json) by shot
## kind and by the shooter's tier. Pure function of the shot's end and the world: nothing is drawn from S.rng, so it is replay-safe.
## The blast reaches buildings through damageArea, so the tier's structure reach (reachStructure) and the casualty window apply as for
## any impact; a shot that dodged a fighter and flew on ends here exactly as one that missed.

const PATH: String = "res://data/biomes/blast.json"
const SCHEMA: String = "biomes.blast/1"
static var _d: Dictionary = {}
static var _errors: Array = []
static var _loaded: bool = false
static var _hash: String = ""


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func errors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("blast.json: cannot open " + PATH)
		return
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("blast.json: not a %s object" % SCHEMA)
		return
	for k in ["kinds", "tierEnergy", "tierDamage"]:
		if not j.has(k):
			_errors.append("blast.json: missing " + k)
	var h := SimHash.Hasher.new()
	h.text("biomes.blast")
	FighterData._canon(h, j)
	_hash = h.hex()
	if _errors.is_empty():
		_d = j


## A shot of the given kind, fired by slot, ended at (x, y, z) moving at (vx, vy) units a second, against the ground (cause "ground") or the
## water (cause "water"). Returns {"crater": the record or null, "levelled": buildings levelled}.
static func shotHit(S: SimState, slot: int, kind: String, x: float, y: float, z: float, vx: float, vy: float, cause: String, charge: float = 1.0, capLeft: int = 1) -> Dictionary:
	var res := {"crater": null, "levelled": 0}
	var D: Dictionary = data()
	if D.is_empty() or not D.kinds.has(kind) or slot < 0 or slot >= S.fighters.size():
		return res
	var k: Dictionary = D.kinds[kind]
	var f = S.fighters[slot]
	var ti: int = clampi(int(f.tier), 1, 4) - 1
	if cause == "water":
		SimFx.splash(S, x, y, int(k.splash), z)
		SimFx.ring(S, x, y, float(k.ringR), "#bfe6ff", 0.4, 8.0, z)
		return res
	var g: float = WorldTerrain.groundY(S, x, z)
	var sp: float = maxf(SimDetMath.hypot(vx, vy), 0.000001)
	var E: float = lerpf(float(k.get("craterETap", k.craterE)), float(k.craterE), charge) * float(D.tierEnergy[ti])
	var air: float = maxf(0.0, y - g)   # a burst above the ground (a mine in the air, a shot that ran out of life): the bowl fades with the height
	if air > 0.0:
		E *= maxf(0.0, 1.0 - air / (float(k.get("airReach", 6.0)) * 75.0))
	if E > 0.02:
		res.crater = WorldCrater.dig(S, x, E, f, "impact", vx / sp, absf(vy) / sp, false, z)
	SimFx.debris(S, x, g + 8.0, int(k.debris), "#6d6a66", 500.0, z)
	SimFx.dust(S, x, g, int(k.dust), "", z)
	SimFx.ring(S, x, g + 10.0, float(k.ringR), "#ffffff", 0.35, 8.0, z)
	SimFx.shake(S, float(k.shake), x, z)
	res.levelled = _area(S, f, k, D, ti, charge, x, maxf(y, g + 5.0), capLeft)   # an air burst blasts at its height
	return res


## Structure damage of a direct hit by kind and charge, before the tier factor (agency-pass 15.3): a charged shot runs from `damage` (a tap)
## to `fullDamage`.
static func structDamage(k: Dictionary, charge: float) -> float:
	return lerpf(float(k.damage), float(k.get("fullDamage", k.damage)), charge)


## The blast on the buildings around a point: half of a direct hit (areaShare) over the kind's radius (a charged shot's grows with its charge,
## every kind's with the shooter's tier), the tier factor on the damage. At most capLeft buildings fall; the rest are left at a quarter of their hp.
static func _area(S: SimState, f, k: Dictionary, D: Dictionary, ti: int, charge: float, x: float, y: float, capLeft: int) -> int:
	var rad: float = lerpf(float(k.radius), float(k.get("fullRadius", k.radius)), charge) * float(D.tierRadius[ti])
	var dmg: float = structDamage(k, charge) * float(k.get("areaShare", D.areaShare)) * float(D.tierDamage[ti])
	return WorldStructures.damageArea(S, x, y, rad, dmg, f, false, 0.0, capLeft, 0.25, 1.0)


## A shot hits building b at (x, y) (SimShots.hitStructure calls this): the damage by the shot's kind and the shooter's tier, through the building's floors (a skyscraper loses
## floors: dent, crack or punch, and a punched span pancakes what stands above it) or its hit points (a house). A light shot (chip in the data)
## first piles into the building's wear pool (nothing shows); at chip.threshold of maxhp the pool is paid in one blow. Returns {"outcome",
## "dmg", "levelled"}: outcome chip (nothing shown), or what the floors did, or hit/collapse for a plain building.
static func shotBuilding(S: SimState, slot: int, kind: String, power: float, b, x: float, y: float, z: float, vx: float, vy: float, charge: float = 1.0) -> Dictionary:
	var D: Dictionary = data()
	var k: Dictionary = D.kinds[kind]
	var f = S.fighters[slot]
	var ti: int = clampi(int(f.tier), 1, 4) - 1
	var dmg: float = structDamage(k, charge) * float(D.tierDamage[ti])
	var res := {"outcome": "hit", "dmg": dmg, "levelled": false}
	var sp: float = maxf(SimDetMath.hypot(vx, vy), 0.000001)
	SimFx.shake(S, float(k.shake) * 0.5, x, z)
	if b.wear >= 0.0:   # nothing has shown yet: the damage piles into the pool (scorch marks only) until a quarter of the hit points
		b.wear += dmg
		if b.wear < float(D.chip.threshold) * b.maxhp:
			res.outcome = "chip"
			SimFx.debris(S, x, y, 2, "#77808f", 300.0, z)
			SimFx.ring(S, x, y, float(k.ringR) * 0.5, "#ffffff", 0.3, 8.0, z)
			return res
		dmg = b.wear   # it shows: the pool is paid in one blow, and from now on every hit counts at once (wear -1)
		b.wear = -1.0
		res.dmg = dmg
		res.outcome = "wound"
	var by = f
	if b.floors >= WorldBrunt.FLOORS_MIN:
		var oc: Dictionary = WorldBrunt.outcomeDmg(S, b, y, dmg)
		var s0: int = WorldStructures.stage(b)
		var fm0: int = b.fmask
		var c: Dictionary = _floors(S, b, oc, by, x, y, slot, vx / sp, vy / sp)
		WorldStructures.stageEmit(S, b, s0, by, x, WorldBrunt._bits(fm0 & ~b.fmask))
		res.outcome = "collapse" if c.collapse else ("pancake" if c.pancake else oc.outcome)
		res.levelled = not b.alive
	else:
		WorldStructures.damageBuilding(S, b, dmg, by, "burst", x, 0.0)
		res.levelled = not b.alive
		if res.levelled:
			res.outcome = "collapse"
	SimFx.debris(S, x, y, int(k.debris), "#77808f", 500.0, z)
	SimFx.dust(S, x, y, int(k.dust), "", z)
	_area(S, f, k, D, ti, charge, x, y, 1 - (1 if res.levelled else 0))   # the blast on its neighbours: one shot levels at most one building
	return res


## The charge of a charged shot from the damage the director gave it at the fire (a tap is 0.6 of the kind's damage, a full charge all of it): 0 to 1.
static func chargeOf(sh) -> float:
	if sh.kind != "charged" or not SimShots.kinds.has("charged"):
		return 1.0
	return clampf((sh.dmg / maxf(float(SimShots.kinds["charged"].dmg), 0.000001) - 0.6) / 0.4, 0.0, 1.0)


## WorldBrunt.applyFloors for a shot: the same rules (punch clears the floors it covers, crack and dent keep damage on them, the core wears by
## CORE_SHARE, a punched span pancakes the floors above), with no fighter in the event.
static func _floors(S: SimState, b, oc: Dictionary, by, cx: float, y: float, slot: int, ux: float, uy: float) -> Dictionary:
	var res := {"pancake": false, "collapse": false}
	var F: int = b.floors
	if b.fdmg.size() != F:
		b.fdmg = PackedFloat32Array()
		b.fdmg.resize(F)
		b.fdmg.fill(0.0)
	var popF: float = WorldBrunt.floorPop(b)
	var lowest: int = oc.k
	if oc.outcome == "punch":
		var cleared: int = 0
		for j in oc.hit:
			b.fmask = b.fmask & ~(1 << j)
			b.fdmg[j] = 0.0
			cleared += 1
			lowest = mini(lowest, j)
		if cleared > 0:
			WorldCollateral.kill(S, b.idx, popF * float(cleared), by, 0.0, cx, lowest)
		SimFx.floorHitShot(S, b, lowest, cleared, "punch", oc.ratio, y, slot, ux, uy)
	elif oc.outcome == "crack":
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
		var d: float = popF * float(oc.hit.size()) * minf(1.0, oc.ratio * WorldBrunt.FLOOR_DEATH)
		if d > 0.0:
			WorldCollateral.kill(S, b.idx, d, by, 0.0, cx, oc.hit[0])
		SimFx.floorHitShot(S, b, oc.hit[0], 0, "crack", oc.ratio, y, slot, ux, uy)
	else:
		for j in oc.hit:
			b.fdmg[j] += oc.dmg
		SimFx.floorHitShot(S, b, oc.hit[0] if oc.hit.size() > 0 else oc.k, 0, "dent", oc.ratio, y, slot, ux, uy)
	b.hp -= WorldBrunt.CORE_SHARE * oc.dmg
	if b.hp <= 0.0:
		res.collapse = true
		WorldStructures.collapse(S, b, by, "burst", cx, 0.0)
		return res
	if oc.outcome == "punch":
		var pk: Dictionary = WorldBrunt.pancake(S, b, by, 0.0, cx, null)
		res.pancake = pk.pancake
		res.collapse = pk.collapse
	return res


## A mine's blast (a ground mine rests on the ground, an air mine hangs at y): the shot's own blast by the mine's kind row, a vertical one.
static func mineBlast(S: SimState, slot: int, x: float, y: float, z: float) -> Dictionary:
	return shotHit(S, slot, "mine", x, y, z, 0.0, -1.0, "ground")
