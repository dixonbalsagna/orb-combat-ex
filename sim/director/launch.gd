class_name DirLaunch
## Launch planner (Encounter Systems): scores launch candidates for a launch beat and picks the best (chooseLaunch),
## then applies it (doLaunch). Born as the twin of launch.js; since ADR 0006 it scores where the fight goes as well as
## how the hit looks (balance-targets.md section 10):
##  - a flight predictor estimates where each candidate lands and how far it carries the target;
##  - a distance term favours long hauls across the map and a new-biome term favours landing somewhere new, both only
##    when the landing is open ground (empty land, not a town); a water term steers away from launches that end in the
##    sea (a fighter who hits water stops dead and the fight sinks);
##  - DRIVE DOWN (SLAM DOWN until the landing mix) gets no bonus over the ocean or the city;
##  - SMASH ACROSS is the long haul or nothing: a rising arc whose force is raised (up to HAUL_FM_MAX) so the predicted
##    flight reaches HAUL_TARGET, and it drops out when it still cannot carry the target HAUL_MIN;
##  - the predictor stops a flight or a slide at the first standing building, so a throw into a town is scored as the
##    short crash it will be; MOUNTAINSIDE aims at the nearest slope ahead out to MOUNTAIN_REACH;
##  - BUILDING SMASH scores building height in fighter-scale terms (h / (32 x WS)) since the world scale;
##  - "NONE" competes too: when no launch beats it, the strike knocks the target back instead of launching it, which
##    keeps launches to a few a minute and makes each one count. Holding back is scored with the personality term at
##    the target's position, so the hero throws the villain out of a town rather than leaving the fight there.
##  - the landing mix (balance-targets.md section 19): DRIVE DOWN (the old SLAM DOWN) sends the target down and forward
##    at 25 to 50 degrees by its height, which ploughs in and slides; the straight-down slam is its own candidate, CRATER SLAM, offered
##    only for a rival directly below the launcher and as the tier-3 crater set piece (data/director/launch.json).
## Candidate order fixes the order of the noise draws.

const NOISE: float = 8.0            # uniform noise added to every candidate
const CARE_W: float = 34.0          # personality: -care x this x population near the landing point
const CARE_R: float = 700.0 * SimConst.WS
const REPEAT_1: float = 20.0        # variety: the previous launch
const REPEAT_2: float = 10.0        # variety: the one before
const DIST_W: float = 12.0          # per 1000 units of predicted horizontal travel
const DIST_UNIT: float = 1000.0 * SimConst.TRAV_LAUNCH   # a launch's horizontal reach is TRAV_LAUNCH times longer (world/slide.gd)
const DIST_CAP: float = 3.0 * DIST_UNIT
const HAUL_TARGET: float = 2.2 * DIST_UNIT   # SMASH ACROSS aims to carry the target this far (13,200 units, 176 bh)
const HAUL_FM_MAX: float = 3.0             # ... with at most this force multiplier
const HAUL_MIN: float = 1.6 * DIST_UNIT     # below this predicted travel SMASH ACROSS drops out (9,600 units, 128 bh)
const HAUL_SHORT: float = 100.0            # the score it loses then
const MOUNTAIN_STEP: float = 520.0 * SimConst.WS   # the mountainside probe: first step (the old single probe) ...
const MOUNTAIN_REACH: float = 1560.0 * SimConst.WS # ... and the farthest slope it looks for (12,480 units)
const OPEN_POP: float = 0.2         # popNear(landing, CARE_R) at or below this is open ground
const NEW_BIOME_W: float = 10.0     # predicted landing in a different biome that is not ocean
const WATER_W: float = 45.0         # predicted landing in the sea
const NONE_BASE: float = 25.0       # "no launch" in the old profiles; the knock-back's score is data (launch.json knockBack.score)
const ACROSS_UY: float = 0.32       # SMASH ACROSS arc
const ACROSS_FORCE: float = 2.0     # SMASH ACROSS force multiplier
const KNOCKBACK: float = 700.0      # push when no launch is chosen
## BUILDING SMASH scoring (B2). The occupancy term saturates at BRUNT_POP_REF living people: at today's scale a building holds
## one to five, not the thirteen the first draft assumed.
const BRUNT_BASE: float = 14.0
const BRUNT_POP_REF: float = 8.0   # the old absolute cap: WorldStructures.buildingPopRef(S) (2% of the starting population) is what is read
const BRUNT_TALL_W: float = 12.0     # the fighter who feeds on collateral seeks tall buildings
const BRUNT_FRESH: float = 4.0       # an undamaged building
const BRUNT_ROW_W: float = 2.0       # ... and deeper rows (more dramatic)
const BRUNT_CHAIN_DRAMA: float = 5.0
const BRUNT_DRAMA_CAP: float = 14.0
const BRUNT_REPEAT: float = 12.0     # the same building twice running
const BRUNT_RAMP: float = 5.0        # per planner launch that had a building in reach and chose something else
const BRUNT_OVER_BUDGET: float = 40.0
const PREDICT_REACH: float = 40000.0  # buildings farther than this from the launch point are not checked
const PREDICT_STEPS: int = 240      # flight predictor horizon: 4 s at the fixed step
const BH: float = 75.0              # a body height, in units
const DATA_PATH: String = "res://data/director/launch.json"
static var _data = null
static var _dataText: String = ""
## Combat's data/combat/launch_biome.json (docs/combat/biomes.md section 3; biomes W3): the eight candidates that use the
## ground, the terms on the landing's surface and the two biome tables, all behind biome.enabled (off by default).
const BIOME_PATH: String = "res://data/combat/launch_biome.json"
static var _bio = null
static var _bioText: String = ""
static var forceBiome: int = -1   # tools only: 1 on, 0 off, -1 the file's biome.enabled


## data/director/launch.json: the drive's angle rule and the CRATER SLAM's gates and score.
static func data() -> Dictionary:
	if _data == null:
		_dataText = FileAccess.get_file_as_string(DATA_PATH)
		_data = JSON.parse_string(_dataText)
		if _data == null:
			push_error("DirLaunch: could not parse " + DATA_PATH)
			_data = {}
	return _data


## The data file's text, for DirData.dataHash() (the replay header).
static func dataText() -> String:
	data()
	return _dataText


## The biome block of data/combat/launch_biome.json ({} when the file is missing).
static func biome() -> Dictionary:
	if _bio == null:
		_bioText = FileAccess.get_file_as_string(BIOME_PATH) if FileAccess.file_exists(BIOME_PATH) else ""
		var j = JSON.parse_string(_bioText) if _bioText != "" else null
		if _bioText != "" and not (j is Dictionary):
			push_error("DirLaunch: could not parse " + BIOME_PATH)
		_bio = j.get("biome", {}) if j is Dictionary else {}
	return _bio


## The biome file's text, for DirData.dataHash() (the replay header).
static func biomeText() -> String:
	biome()
	return _bioText


## Whether the biome block plays: its enabled, or a tool's forceBiome.
static func biomeOn() -> bool:
	return forceBiome == 1 if forceBiome >= 0 else bool(biome().get("enabled", false))


## DRIVE DOWN's direction for a target alt units above the ground: [along the facing, up]. No draw.
static func driveDir(alt: float) -> Array:
	var d: Dictionary = data().drive
	var t: float = SimMathx.jclamp((alt / BH - float(d.lowBh)) / (float(d.highBh) - float(d.lowBh)), 0.0, 1.0)
	var a: float = (float(d.lowDeg) + (float(d.highDeg) - float(d.lowDeg)) * t) * SimMathx.PI / 180.0
	return [SimDetMath.cos(a), -SimDetMath.sin(a)]


## S.dirS.craterT holds the match time of each slot's last CRATER SLAM; it is sized here on first use. With the town
## rules one more number follows them: the match time the planner last paid its new-biome bonus (0 never).
static func _sizeCraterT(S: SimState) -> void:
	if S.dirS.craterT.size() < S.fighters.size():
		S.dirS.craterT.resize(S.fighters.size())


## Whether the new-biome bonus may be paid now: once in town.newBiomeEveryS seconds of the match (always, with no
## such number). A read: it sizes nothing.
static func _newBiomeDue(S: SimState, town: Dictionary) -> bool:
	var every: float = float(town.get("newBiomeEveryS", 0.0))
	if every <= 0.0 or S.dirS.craterT.size() <= S.fighters.size():
		return true
	var paid: float = S.dirS.craterT[S.fighters.size()]
	return paid <= 0.0 or S.T - paid >= every


## Whether CRATER SLAM is offered: the rival is directly below the launcher, or the launcher is at the set piece's tier
## and has not thrown one in the last everySec seconds. (Break and finisher launches keep their authored vectors.)
static func craterOffered(S: SimState, A, D) -> bool:
	var cs: Dictionary = data().craterSlam
	if absf(SimWrap.sdx(A.x, D.x)) <= float(cs.below.sideBh) * BH and A.y - D.y >= float(cs.below.dropBh) * BH:
		return true
	_sizeCraterT(S)
	return A.tier >= float(cs.setPiece.minTier) and S.T - S.dirS.craterT[S.fighters.find(A)] >= float(cs.setPiece.everySec)


## force is the template's launch force; the prediction uses it with the tier scaling doLaunch applies.
## longOnly (break and finisher launches, spec-wounds.md §1): only the long-haul candidates (SMASH ACROSS, BUILDING SMASH,
## MOUNTAINSIDE), SMASH ACROSS always offered, and no "no launch".
static func chooseLaunch(S: SimState, A, D, force: float, longOnly: bool = false, sends: String = "", tilt: int = 0, noKnock: bool = false, fresh: bool = false) -> Dictionary:
	var g: float = WorldTerrain.groundY(S, D.x)
	var alt: float = D.y - g
	var bio: String = WorldBiomes.biomeAt(D.x)
	var f: float = A.face
	var town: Dictionary = data().get("town", {})   # buildings.md section 3: staying in town, and aiming for a building
	var inTown: bool = (town.get("biomes", []) as Array).has(bio)
	var bon: bool = biomeOn()   # biomes W3: the eight candidates that use the ground, and the surface terms
	var c: Array = []
	if not longOnly:
		var up: Dictionary = data().uppercut   # the slam lever: more forward carry, so the fall lands under 70 degrees
		c.append({"name": "UPPERCUT", "ux": float(up.ux) * f, "uy": float(up.uy), "s": 10.0 + (12.0 if alt < 120.0 else 0.0)})
	if not longOnly:
		var dv: Array = driveDir(alt)
		var dB: float = float(biome().get("downBonus", {}).get(WorldBiomes.fineNameAt(D.x), 0.0)) if bon else (8.0 if bio == "forest" else 0.0)   # biome on: the downBonus table (forest keeps its 8)
		c.append({"name": "DRIVE DOWN", "ux": dv[0] * f, "uy": dv[1], "s": (18.0 if alt > 140.0 else 0.0) + A.tier * 4.0 + dB})
		if craterOffered(S, A, D):
			var cs: Dictionary = data().craterSlam
			c.append({"name": "CRATER SLAM", "ux": float(cs.ux) * f, "uy": float(cs.uy), "s": float(cs.score.base) + float(cs.score.perTier) * A.tier + (float(cs.score.high) if alt > float(cs.score.highAlt) else 0.0)})
	c.append({"name": "SMASH ACROSS", "ux": f, "uy": ACROSS_UY, "fm": ACROSS_FORCE, "s": 8.0})
	var tierF: float = SimForms.launchMul(S, A)   # D1b: ladder.json (forms: his own steps)
	# BUILDING SMASH (B2, docs/world/b2-plan.md section 4): one candidate per building the launch can be aimed at, in any row,
	# scored by personality first and drama on top; a chain through several buildings is part of the candidate.
	var hadBrunt: bool = false
	# Contact (contact-spacing.md section 5.1): no launch goes back through the launcher. With a contact block only the
	# targets on the far side of the rival are offered.
	var fwdOnly: bool = not DirData.contact().is_empty()
	for bi in WorldBrunt.candidates(S, D):
		var plan = WorldBrunt.aim(S, A, D, S.buildings[bi], force * (DirBrawl.freshMul(S, D, 4) if fresh else 1.0), tierF, longOnly)   # fresh: the launcher's send into a building, x its freshness
		if plan != null and fwdOnly and float(plan.ux) * f < 0.0:
			plan = null
		if plan != null:
			hadBrunt = true
			plan.s = bruntScore(S, A, plan)
			if tilt == 0 and not town.is_empty() and A.tier >= float(town.get("bruntFromTier", 99.0)):
				plan.s += float(town.get("bruntPrefer", 0.0))   # a building on the line, no stick held: preferred from this tier
			c.append(plan)
		var ip = _insideAim(S, A, D, S.buildings[bi], force * (DirBrawl.freshMul(S, D, 4) if fresh else 1.0), tierF, longOnly, plan)
		if ip != null and not (fwdOnly and float(ip.ux) * f < 0.0):
			hadBrunt = true
			ip.s = bruntScore(S, A, ip) + _insideScore(A)
			if tilt == 0 and not town.is_empty() and A.tier >= float(town.get("bruntFromTier", 99.0)):
				ip.s += float(town.get("bruntPrefer", 0.0))
			c.append(ip)
	for sign in [-1.0, 1.0]:
		if fwdOnly and sign * f < 0.0:
			continue
		# The nearest mountainside ahead, out to MOUNTAIN_REACH: near slopes give a short throw, far ones a long haul.
		var md: float = MOUNTAIN_STEP
		while md <= MOUNTAIN_REACH:
			if WorldBiomes.biomeAt(D.x + sign * md) == "mountains":
				c.append({"name": "MOUNTAINSIDE", "ux": sign, "uy": 0.05, "s": 24.0, "land": D.x + sign * md})
				break
			md += MOUNTAIN_STEP
	if bon:
		_biomeCands(S, A, D, c, longOnly, fwdOnly, force * (DirBrawl.freshMul(S, D, 1) if fresh else 1.0) * tierF, fresh)
	if not longOnly and not noKnock:
		c.append({"name": "KNOCK BACK", "ux": 0.0, "uy": 0.0, "s": float(data().knockBack.score)})   # "no launch": a scored outcome (it was NONE)
	if sends != "":
		# Combat's hook (alchemist-content.md): a piece that names where it sends the rival keeps only those candidates.
		var keep: Array = SENDS.get(sends, []) + ((biome().get("sends", {}).get(sends, []) as Array) if bon else [])   # biome on: its candidates join their kind
		c = c.filter(func(k): return k.name == "KNOCK BACK" or keep.has(k.name))
	if tilt > 0:
		# The stick's tilt (1 up, then clockwise by eighths): only candidates within TILT_CONE of it compete. A tilt back
		# through the launcher is not a direction a launch can take (the turning throw is M0): it keeps its up or down part.
		var tx: float = [0.0, 0.7071, 1.0, 0.7071, 0.0, -0.7071, -1.0, -0.7071][tilt - 1]
		var ty: float = [1.0, 0.7071, 0.0, -0.7071, -1.0, -0.7071, 0.0, 0.7071][tilt - 1]
		if tx * f < 0.0:
			tx = 0.0
		if tx != 0.0 or ty != 0.0:
			var tl: float = SimDetMath.hypot(tx, ty)
			var cone: float = float(DirBrawl.la().get("aim", {}).get("bendCos", TILT_CONE)) if DirBrawl.anywhere() else TILT_CONE   # launch anywhere: the choreographer bends at most this inside the stick's kind
			var near: Array = c.filter(func(k): return k.name == "KNOCK BACK" or (k.ux * tx + k.uy * ty) / (tl * SimMathx.jmax(SimDetMath.hypot(k.ux, k.uy), 0.000001)) >= cone)
			if near.any(func(k): return k.name != "KNOCK BACK"):
				c = near
				for k in c:
					if k.has("brunt"):
						k.s += float(town.get("stickWins", 0.0))   # the player's stick is a vote that wins: a building on the side he leans to is taken when a plan to it exists
	var preferW: float = float(DirBrawl.la().get("fresh", {}).get("preferW", 0.0)) if DirBrawl.anywhere() else 0.0   # launch anywhere: a fresh kind is preferred
	for k in c:
		k.s += S.rng.range_(0.0, NOISE)
		if preferW > 0.0 and k.name != "KNOCK BACK":
			k.s -= preferW * float(DirBrawl.freshMarks(S, D, DirBrawl.kindOfSend(k)))
		if k.name == "KNOCK BACK":
			# Holding back leaves the fight where it is: the same personality term, at the target's position.
			k.s += (-A.care) * CARE_W * WorldStructures.popNear(S, D.x, CARE_R)
			continue
		if k.has("brunt"):
			# A brunt is scored by bruntScore; its flight is WorldBrunt's, so there is nothing to predict here.
			var br: Dictionary = k.brunt
			var lastb = S.buildings[br.chain[br.chain.size() - 1].b]
			k.land = lastb.x
			k.travel = absf(SimWrap.sdx(D.x, lastb.x))
			k.p = {"x": br.hit.x, "travel": k.travel, "water": false, "building": true, "t": br.hit.t}
			if k.name == S.dirS.lastLaunch:
				k.s -= REPEAT_1
			if k.name == S.dirS.lastLaunch2:
				k.s -= REPEAT_2
			continue
		var fm: float = (k.fm if k.has("fm") else 1.0) * (DirBrawl.freshMul(S, D, DirBrawl.kindOfSend(k)) if fresh else 1.0)   # fresh: each candidate x its own kind's freshness
		var p: Dictionary = predictFlight(S, D.x, D.y, WorldSlide.launchVX(k.ux, k.uy, force * fm * tierF), k.uy * force * fm * tierF, WorldSlide.launchTravel(k.ux, k.uy))
		var street: bool = false
		if k.name == "SMASH ACROSS" and inTown and not longOnly and float(town.get("haulTarget", 0.0)) > 0.0:
			# A launch along a street stays in the street: the force is set (once, square-root rule) so the flight carries
			# him town.haulTarget and no further. It is kept while he still lands inside the settlement, town.haulMin on at
			# least; where the street does not run that far it is the long haul, below.
			var fmT: float = clampf(fm * sqrt(float(town.haulTarget) / SimMathx.jmax(p.travel, 1.0)), 0.05, HAUL_FM_MAX)
			var pT: Dictionary = predictFlight(S, D.x, D.y, WorldSlide.launchVX(k.ux, k.uy, force * fmT * tierF), k.uy * force * fmT * tierF, WorldSlide.launchTravel(k.ux, k.uy))
			if pT.travel >= float(town.get("haulMin", 0.0)) and not pT.water and (town.biomes as Array).has(WorldBiomes.biomeAt(pT.x)):
				street = true
				fm = fmT
				k.fm = fm
				k.street = true
				p = pT
		if k.name == "SMASH ACROSS" and not street and p.travel < HAUL_TARGET and not fresh:   # a launcher's length is its power's: no long-haul boost
			# The long haul: raise the force (once, square-root rule, capped) so the predicted flight reaches HAUL_TARGET.
			fm = SimMathx.jmin(HAUL_FM_MAX, fm * sqrt(HAUL_TARGET / SimMathx.jmax(p.travel, 1.0)))
			k.fm = fm
			p = predictFlight(S, D.x, D.y, WorldSlide.launchVX(k.ux, k.uy, force * fm * tierF), k.uy * force * fm * tierF, WorldSlide.launchTravel(k.ux, k.uy))
		if k.name == "SMASH ACROSS" and not street and p.travel < HAUL_MIN and not longOnly:
			# SMASH ACROSS is the long haul or nothing: when it cannot carry the target HAUL_MIN, it is not offered.
			k.s -= HAUL_SHORT
		k.p = p
		var lx: float = k.land if k.has("land") else p.x
		k.travel = absf(SimWrap.sdx(D.x, lx)) if k.has("land") else p.travel
		var popL: float = WorldStructures.popNear(S, lx, CARE_R)
		k.s += (-A.care) * CARE_W * popL
		# Distance and new ground only count when the landing is open ground: long hauls carry the fight to empty land.
		if popL <= OPEN_POP:
			k.s += DIST_W * SimMathx.jmin(k.travel, DIST_CAP) / DIST_UNIT * (float(town.get("distMul", 1.0)) if inTown else 1.0) * (float(biome().get("distMul", {}).get(WorldBiomes.fineNameAt(lx), 1.0)) if bon else 1.0)   # from a settlement the haul out is worth less; biome on: open country more, closed less
		var lb: String = WorldBiomes.biomeAt(lx)
		if lb != bio and lb != "ocean" and popL <= OPEN_POP and _newBiomeDue(S, town):
			k.s += NEW_BIOME_W
			k.newBiome = true
		if bon:
			k.s += _landTerms(S, k, lx, p)
		if p.water and not k.has("land") and not k.get("wetOk", false):
			k.s -= WATER_W
		if k.name == S.dirS.lastLaunch:
			k.s -= REPEAT_1
		if k.name == S.dirS.lastLaunch2:
			k.s -= REPEAT_2
		k.s += DirRally.variety(S, A, k)   # 23d 13: a rally's variety (0 outside one)
	# Stable sort by score, highest first: an insertion sort keeps equal scores in candidate order.
	for i in range(1, c.size()):
		var key = c[i]
		var j: int = i - 1
		while j >= 0 and key.s - c[j].s > 0.0:
			c[j + 1] = c[j]
			j -= 1
		c[j + 1] = key
	if c[0].get("newBiome", false) and float(town.get("newBiomeEveryS", 0.0)) > 0.0:
		_sizeCraterT(S)
		if S.dirS.craterT.size() < S.fighters.size() + 1:
			S.dirS.craterT.resize(S.fighters.size() + 1)   # one more number after the slots' own: the match time the bonus was last paid
		S.dirS.craterT[S.fighters.size()] = S.T + 0.001   # the new-biome bonus was paid: not again for town.newBiomeEveryS
	# The pity counter: launches that had a building in reach and chose something else make the next brunt likelier.
	if hadBrunt:
		if c[0].name == "BUILDING SMASH":
			S.dirS.sinceBrunt = 0.0
			S.dirS.lastBrunt = float(c[0].brunt.b)
		else:
			S.dirS.sinceBrunt += 1.0
	return {"best": c[0], "top": c.slice(0, 3), "all": c}


## Biomes W3 (docs/combat/biomes.md section 3; data/combat/launch_biome.json): the eight candidates that use the ground,
## each offered only where its feature is, appended to c in a fixed order (the noise draws keep it). CLIFFSIDE is a long
## haul like MOUNTAINSIDE and is offered to a break or finisher launch too; the other seven are not. pf is the force the
## flight would get (the template's, the tier's and an across send's freshness), for SKIM ASHORE's skim prediction and
## PROP SMASH's aim; fresh marks a launch anywhere's send, which PROP SMASH does not aim.
static func _biomeCands(S: SimState, A, D, c: Array, longOnly: bool, fwdOnly: bool, pf: float, fresh: bool = false) -> void:
	var cd: Dictionary = biome().get("candidates", {})
	var pers: String = _persOf(A)
	var f: float = A.face
	var g: float = WorldTerrain.groundY(S, D.x)
	var alt: float = D.y - g
	var q: Dictionary = cd.get("CLIFFSIDE", {})
	if not q.is_empty():
		for sign in [-1.0, 1.0]:
			if fwdOnly and sign * f < 0.0:
				continue
			var face = _cliff(S, D.x, sign, q.probe)
			if face != null and WorldBiomes.biomeAt(face.x) != "mountains":   # a face inside the mountains is MOUNTAINSIDE's
				c.append(_bc(q, "CLIFFSIDE", sign, float(q.uy), pers, minf(face.rise / BH * float(q.perRiseBh), float(q.riseCap)), {"land": face.x, "rise": face.rise}))
	if longOnly:
		return
	var sea: bool = WorldTerrain.seaAt(S, D.x)
	var look: String = WorldContact.lookAt(S, D.x)
	q = cd.get("ICE SKID", {})
	if not q.is_empty() and not sea and look == "ice" and alt <= float(q.onIceBh) * BH:
		c.append(_bc(q, "ICE SKID", f, float(q.uy), pers, 0.0, {"fm": float(q.force)}))
	q = cd.get("MARSH SWALLOW", {})
	if not q.is_empty() and not sea and look == "mud" and alt <= float(q.maxAltBh) * BH:
		c.append(_bc(q, "MARSH SWALLOW", float(q.ux) * f, float(q.uy), pers, 0.0, {"embed": float(q.embedMul)}))
	q = cd.get("TREE LINE", {})
	if not q.is_empty():
		var n: int = 0
		var reach: float = float(q.reachBh) * BH
		for t in S.trees:
			var d: float = SimWrap.sdx(D.x, t.x) * f
			if t.alive and d >= 0.0 and d <= reach and D.y - WorldTerrain.groundY(S, t.x) < t.h:   # a standing trunk the low line passes through
				n += 1
		if n >= int(q.minTrees):
			n = mini(n, int(q.maxTrees))
			c.append(_bc(q, "TREE LINE", f, float(q.uy), pers, float(q.perTree) * float(n), {"trees": n, "treeBrake": float(q.brakePerTree)}))
	q = cd.get("SKIM ASHORE", {})
	if not q.is_empty() and sea:
		var sk = _skimAshore(S, D.x, D.y, WorldSlide.launchVX(f, float(q.uy), pf), float(q.uy) * pf, int(q.maxSkims), float(q.landBh) * BH)
		if sk != null:
			c.append(_bc(q, "SKIM ASHORE", f, float(q.uy), pers, 0.0, {"land": sk.x, "skims": sk.n}))
	q = cd.get("DOWNHILL", {})
	if not q.is_empty() and not sea:
		var lowX: float = D.x
		var low: float = g
		var run: float = float(q.dropRunBh) * BH
		var d: float = SimConst.COL
		while d <= run:
			var gy: float = WorldTerrain.groundY(S, D.x + f * d)
			if gy < low:
				low = gy
				lowX = D.x + f * d
			d += SimConst.COL
		var drop: float = g - low
		if drop >= float(q.minDropBh) * BH and not WorldTerrain.seaAt(S, lowX) and (q.surfaces as Array).has(WorldContact.lookAt(S, D.x + f * 0.5 * absf(SimWrap.sdx(D.x, lowX)))):
			c.append(_bc(q, "DOWNHILL", f, float(q.uy), pers, minf(drop / BH * float(q.perDropBh), float(q.dropCap)), {"drop": drop}))
	var vq: Dictionary = cd.get("VENT LIFT", {})
	var pq: Dictionary = cd.get("PROP SMASH", {})
	if (vq.is_empty() and pq.is_empty()) or not WorldGround.live():
		return
	var preach: float = float(pq.get("reachBh", 0.0)) * BH
	var near: Array = _propsNear(S, D.x - maxf(float(vq.get("withinBh", 0.0)) * BH, preach), D.x + maxf(float(vq.get("withinBh", 0.0)) * BH, preach))
	if not vq.is_empty():
		for p in near:
			if String(p.kind) == "vent" and absf(SimWrap.sdx(D.x, p.x)) <= float(vq.withinBh) * BH:
				var up: Dictionary = data().uppercut
				var onUp: float = (10.0 + (12.0 if alt < 120.0 else 0.0)) if bool(vq.get("onUppercut", false)) else 0.0   # UPPERCUT's own score there, the vent's on top
				c.append(_bc(vq, "VENT LIFT", float(up.ux) * f, float(up.uy) * float(vq.liftMul), pers, onUp, {"vent": p.x}))

				break
	if not pq.is_empty():
		# PROP SMASH is aimed as BUILDING SMASH is (World's W6 finding: a plan whose flight stopped short of its prop, or
		# passed over a low one): the first force of the row's aimFm, the row's own first, whose flight breaks a prop on
		# the line ahead. A launch anywhere's send keeps its own force (its length is its power's, as with the long haul).
		var props: Array = _propTargets(S, D, near, pq.props, f, preach)
		if not props.is_empty():
			for fm in ([1.0] if fresh else pq.get("aimFm", [1.0])):
				var hit: int = _propFlight(S, A, D, f, float(pq.uy), pf * float(fm), props)
				if hit >= 0:
					c.append(_bc(pq, "PROP SMASH", f, float(pq.uy), pers, 0.0, {"land": props[hit].x, "prop": props[hit].kind, "fm": float(fm)}))
					break


## PROP SMASH's targets on the line ahead of D (direction f) within reach: [{"d", "x", "col", "kind", "top"}], nearest
## first, one a column. A column's target is the prop WorldContact._smashProp breaks there (WorldGround.smashIn of the
## column's props), and top is its height above the ground; a column whose props World does not smash has none.
static func _propTargets(S: SimState, D, near: Array, kinds: Array, f: float, reach: float) -> Array:
	var out: Array = []
	var broken: PackedInt32Array = brokenProps(S)
	for p in near:
		var d: float = SimWrap.sdx(D.x, p.x) * f
		if not kinds.has(String(p.kind)) or d < 0.0 or d > reach or out.any(func(q): return int(q.col) == int(p.col)):
			continue
		var here: Array = []
		for q in WorldGround.matchProps(S, float(p.x) - SimConst.COL, float(p.x) + SimConst.COL, broken):
			if int(q.col) == int(p.col):
				here.append(q)
		var pick: int = WorldGround.smashIn(here)
		if pick < 0:
			continue
		var t: Dictionary = {"d": d, "x": float(p.x), "col": int(p.col), "kind": String(p.kind), "top": float(here[pick].size) * WorldGround.BH}
		var i: int = out.size()
		while i > 0 and float(out[i - 1].d) > d:
			i -= 1
		out.insert(i, t)
	return out


## The prop a send of (ux, uy) at force F breaks, as World's flight would play it: an index into props
## (_propTargets), or -1 when the journey ends first. The body is the one doLaunch and WorldContact.toBody make, and
## each tick is the runtime's (WorldContact.stepFighter): moveAir, the path's prop test, groundPhase in the air;
## stepContact, then the test, in a skid or tumble. The test is _smashProp's: the prop within PROP_STOP of the tick's
## path ahead, and he lower than its top (over it, it stands, and a later tick may still meet it). Reads only. Like
## WorldContact.journey it reads the ground as it is now, not as the flight changes it (a landing's crater, a skid's
## trench, the rubble of what it breaks). rec (tools only): when an Array, it gets his [x, y] at the end of each tick.
static func _propFlight(S: SimState, A, D, ux: float, uy: float, F: float, props: Array, rec = null) -> int:
	var tv: float = WorldSlide.launchTravel(ux, uy)
	var b: WorldContact.Body = WorldContact.launchBody(D.x, D.y, ux * F * tv, uy * F, tv, A.tier, D.y < WorldWater.seaTop(S, D.x), D.z)
	b.dir = 1.0 if ux >= 0.0 else -1.0
	b.wetT = int(D.wetT)
	b.slideD = float(D.slideD)
	b.embedOK = S.T - D.embedCool >= WorldContact.K_EMB_COOL
	var ev: Array = []
	for t in range(WorldContact.TICK_CAP):
		var x0: float = b.x
		var hit: int = -1
		if b.mode == WorldContact.AIR:
			WorldContact.moveAir(S, b, SimConst.DT, ev)
			if not b.done:
				hit = _propOnPath(S, b, x0, 1.0 if b.vx >= 0.0 else -1.0, props)
				if hit < 0:
					WorldContact.groundPhase(S, b, ev)
		else:
			WorldContact.stepContact(S, b, SimConst.DT, ev)
			if b.dxStep != 0.0:
				hit = _propOnPath(S, b, x0, b.dir, props)
		if rec != null:
			rec.append([b.x, b.y])
		if hit >= 0 or b.done:
			return hit
		ev.clear()
	return -1


## The first of props on a tick's path from x0 to b.x (direction dir) that _smashProp would break: within PROP_STOP
## ahead of where the tick leaves him, and he lower than its top. -1 when none.
static func _propOnPath(S: SimState, b: WorldContact.Body, x0: float, dir: float, props: Array) -> int:
	var run: float = SimWrap.sdx(x0, b.x) * dir
	if run <= 0.0:
		return -1
	for i in range(props.size()):
		var d: float = SimWrap.sdx(x0, float(props[i].x)) * dir
		if d >= 0.0 and d <= run + WorldContact.PROP_STOP and b.y - WorldTerrain.groundY(S, float(props[i].x)) < float(props[i].top):
			return i
	return -1


## A biome candidate: its name, direction and score (the row's score, its personality's flavour and extra), plus fields.
static func _bc(q: Dictionary, nm: String, ux: float, uy: float, pers: String, extra: float, more: Dictionary) -> Dictionary:
	var k: Dictionary = {"name": nm, "ux": ux, "uy": uy, "s": float(q.score) + extra + (float(q.get(pers, 0.0)) if pers != "" else 0.0), "bio": true}
	k.merge(more, true)
	return k


## CLIFFSIDE's probe: walking from x0 along sign in strides of stepBh out to reachBh, the first stride whose ground rises
## minRiseBh is searched column by column for a face: a run of columns steeper than minTan rising minRiseBh or more in all.
## Returns {"x": the face's foot, "rise": its height} or null. Found from the heights, never from a biome name.
static func _cliff(S: SimState, x0: float, sign: float, pr: Dictionary):
	var step: float = float(pr.stepBh) * BH
	var reach: float = float(pr.reachBh) * BH
	var minRise: float = float(pr.minRiseBh) * BH
	var tn: float = float(pr.minTan) * SimConst.COL
	var d: float = 0.0
	var g0: float = WorldTerrain.groundY(S, x0)
	while d < reach:
		var d1: float = minf(d + step, reach)
		var g1: float = WorldTerrain.groundY(S, x0 + sign * d1)
		if g1 - g0 >= minRise:
			var e: float = d
			var gp: float = WorldTerrain.groundY(S, x0 + sign * e)
			var foot: float = -1.0
			var rise: float = 0.0
			while e < d1 + step:
				var gn: float = WorldTerrain.groundY(S, x0 + sign * (e + SimConst.COL))
				if gn - gp >= tn:
					if foot < 0.0:
						foot = e
					rise += gn - gp
				else:
					if foot >= 0.0 and rise >= minRise:
						break
					foot = -1.0
					rise = 0.0
				gp = gn
				e += SimConst.COL
			if foot >= 0.0 and rise >= minRise and not WorldTerrain.seaAt(S, x0 + sign * foot):
				return {"x": SimWrap.wrap(x0 + sign * foot), "rise": rise}
		g0 = g1
		d = d1
	return null


## SKIM ASHORE's prediction: the free flight of predictFlight with contact.json's water skim (WorldContact.moveAir's rule:
## a fast, flat entry bounces off the sea's top, lifted and slowed). Returns {"x": where he first touches dry ground,
## "n": the skims} when that is within reach of x0 after at most maxSk skims, else null (he goes in, or never lands).
static func _skimAshore(S: SimState, x0: float, y0: float, vx0: float, vy0: float, maxSk: int, reach: float):
	var w: Dictionary = WorldContact.data().get("water", {})
	var dt: float = SimConst.DT
	var kAir: float = SimDetMath.pow(0.55, dt)
	var x: float = x0
	var y: float = y0
	var vx: float = vx0
	var vy: float = vy0
	var travel: float = 0.0
	var n: int = 0
	var wet: bool = y < WorldWater.seaTop(S, x)
	for i in range(PREDICT_STEPS):
		vy -= 1000.0 * dt
		vx *= kAir
		x = SimWrap.wrap(x + vx * dt)
		travel += absf(vx * dt)
		y += vy * dt
		if travel > reach:
			return null
		var top: float = WorldWater.seaTop(S, x)
		if y < top and not wet:
			var sp: float = SimDetMath.hypot(vx, vy)
			if vy < 0.0 and sp > float(w.get("skimMinSpeed", 500.0)) and -vy < absf(vx) * float(w.get("skimMaxTan", 0.6)) and n < maxSk:
				n += 1
				y = top
				vy = -vy * float(w.get("skimLift", 0.65))
				vx *= float(w.get("skimKeep", 0.85))
			else:
				return null   # he goes in
		wet = y < top
		if y <= WorldTerrain.groundY(S, x) and not WorldTerrain.seaAt(S, x):
			return {"x": x, "n": n}
	return null


## World's set dressing between x0 and x1 on a gen 2 planet: the match's props as the sim owns them (WorldGround.matchProps,
## keyed by the planet's seed, the same draw the renderer lays), less the props a launch has broken (brokenProps):
## [{"x", "kind", "size", "col"}]. Empty on any other world.
static func _propsNear(S: SimState, x0: float, x1: float) -> Array:
	return WorldGround.matchProps(S, x0, x1, brokenProps(S))


## The landing's biome terms on a candidate k landing at lx (p its predicted flight): the surface's row by the kind of
## send (sand and rubble only with touchBuilt), its soft factor on the plan, and ICE SKID's end bonus (a lead of water,
## where the water penalty is waived, or a berg).
static func _landTerms(S: SimState, k: Dictionary, lx: float, p: Dictionary) -> float:
	var b: Dictionary = biome()
	var s: float = 0.0
	var look: String = WorldContact.lookAt(S, lx)
	var row = b.get("surfaceLand", {}).get(look, null)
	if row is Dictionary and (bool(b.get("touchBuilt", false)) or (look != "sand" and look != "rubble")):
		s += float(row.get(sendKind(String(k.name)), 0.0))
		if row.has("soft"):
			k.soft = float(row.soft)
	if String(k.name) == "ICE SKID":
		var eb: Dictionary = b.candidates["ICE SKID"].get("endBonus", {})
		if bool(p.get("water", false)):
			s += float(eb.get("water", 0.0))
			k.wetOk = true
		elif WorldGround.live():
			for pr in _propsNear(S, float(p.x) - BH, float(p.x) + BH):
				if String(pr.kind) == "berg":
					s += float(eb.get("berg", 0.0))
					break
	return s


## The score of a BUILDING SMASH candidate (docs/world/b2-plan.md section 4): a base, the launcher's tier, personality (who
## is in the building and, for a fighter who feeds on collateral, how tall it is), drama on top (capped: personality decides
## which building, drama decides among near equals), the pity counter, a repeat penalty, and a penalty for a chain that would
## exceed the casualty budget the runtime will enforce.
## The interior aim (launch.json interiorAim; World's finding, camera-intent.md section 5): with it on and World's interior
## chain on, a send into b aimed inside the chain's gate (WorldBrunt.aimInside over interiorAim.uy), when the low aim
## (low, aim's plan or null) would not start the chain itself. Null otherwise, and always with it off.
static func _insideAim(S: SimState, A, D, b, force: float, tierF: float, special: bool, low):
	var ia: Dictionary = data().get("interiorAim", {})
	if not bool(ia.get("enabled", false)) or not WorldInterior.on(S):
		return null
	if low != null and bool(low.brunt.hit.get("ok", false)) and WorldInterior.fits(S, b, float(low.brunt.hit.vx) / WorldSlide.launchTravel(float(low.ux), float(low.uy)), float(low.brunt.hit.vy)):
		return null   # the low aim already starts it
	var ai := Callable(WorldBrunt, "aimInside")
	if not ai.is_valid():
		return null   # World's grant is not in
	return ai.call(S, A, D, b, force, tierF, special, ia.uy)


## What a send inside a tower is worth to him (interiorAim.score): by his care's sign, or his role at care 0 (hero;
## villain or rival), as the AI's launcher aim reads it. The Anti-hero seeks the chain; the hero avoids it.
static func _insideScore(A) -> float:
	var sc: Dictionary = data().get("interiorAim", {}).get("score", {})
	return float(sc.get(_persOf(A), 0.0))


## His personality for a flavour score: by his care's sign, or his role at care 0 (hero; villain or rival); "" for none.
static func _persOf(A) -> String:
	var pers: String = "hero" if A.care > 0.0 else ("villain" if A.care < 0.0 else "")
	if pers == "":
		var dd = FighterData.def(A.id)
		var role: String = String(dd.get("role", "")) if dd is Dictionary else ""
		pers = "hero" if role == "hero" else ("villain" if (role == "villain" or role == "rival") else "")
	return pers


static func bruntScore(S: SimState, A, plan: Dictionary) -> float:
	var chain: Array = plan.brunt.chain
	var pers: float = 0.0
	var drama: float = 0.0
	var first = S.buildings[chain[0].b]
	for i in range(chain.size()):
		var cb = S.buildings[chain[i].b]
		pers += (-A.care) * CARE_W * clampf(cb.popAlive / WorldStructures.buildingPopRef(S), 0.0, 1.0)
		if A.care < 0.0:
			pers += (-A.care) * BRUNT_TALL_W * clampf(cb.h / SimConst.WS / 400.0, 0.0, 1.0)
	drama += first.h / SimConst.WS / 32.0 + (BRUNT_FRESH if first.hp >= first.maxhp else 0.0)
	if A.care < 0.0:
		drama += BRUNT_ROW_W * first.row
	drama += BRUNT_CHAIN_DRAMA * float(chain.size() - 1)
	var s: float = BRUNT_BASE + 3.0 * A.tier + pers + minf(drama, BRUNT_DRAMA_CAP) + BRUNT_RAMP * S.dirS.sinceBrunt
	if S.dirS.lastBrunt == float(chain[0].b):
		s -= BRUNT_REPEAT
	if chain.size() > 1:
		var allow: float = 0.0
		if A.tier >= 3.0:
			allow = WorldCollateral.eventAllow("chain", int(A.tier)) * S.world.present
		if plan.brunt.deaths > WorldCollateral.room(S) + allow:
			s -= BRUNT_OVER_BUDGET
	return s


## Where a launched fighter would come to rest: the free-flight part of SimFighter.stepLaunched (gravity, air drag,
## water drag and the stop in water, ground impacts by the slam-or-slide rule of world/slide.gd), without buildings (a launch
## collides only with the building it is aimed at: WorldBrunt.aim and chainPlan predict that). It reads the terrain
## and never writes state. Returns {"x": landing x, "travel": horizontal distance, "water": ends in the sea}, with "t"
## the time to the first touchdown, "land" its x and "slide" what a knock-back slide adds after it (the camera-intent feed).
static func predictFlight(S: SimState, x0: float, y0: float, vx0: float, vy0: float, trav: float = 1.0) -> Dictionary:
	var dt: float = SimConst.DT
	var kAir: float = SimDetMath.pow(0.55, dt)
	var kWx: float = SimDetMath.pow(0.05, dt)
	var kWy: float = SimDetMath.pow(0.1, dt)
	var x: float = x0
	var y: float = y0
	var vx: float = vx0
	var vy: float = vy0
	var travel: float = 0.0
	var t: float = 0.0
	var dir0: float = -1.0 if vx0 < 0.0 else 1.0
	for n in range(PREDICT_STEPS):
		t += dt
		vy -= 1000.0 * dt
		vx *= kAir
		x = SimWrap.wrap(x + vx * dt)
		travel += vx * dt
		y += vy * dt
		if y < WorldWater.seaTop(S, x):
			vx *= kWx
			vy *= kWy
			if SimDetMath.hypot(vx, vy) < 200.0 and t > 0.3:
				return {"x": x, "travel": absf(travel), "water": true, "t": t, "land": x}
		var g: float = WorldTerrain.groundY(S, x)
		if y <= g:
			# The same rule as SimFighter.impact: a slam (or the sea, or too slow) lands here; anything shallower is a
			# knockback slide that ends slideDistance() further on. The optional hop is ignored.
			y = g
			var spN: float = SimDetMath.hypot(vx / trav, vy)
			var sea: bool = WorldTerrain.seaAt(S, x)
			if sea or spN <= WorldSlide.MIN_IMPACT or WorldSlide.isSlam(vx, vy):
				return {"x": x, "travel": absf(travel), "water": sea, "t": t, "land": x}
			var dir: float = 1.0 if vx >= 0.0 else -1.0
			var d: float = minf(WorldSlide.slideDistance(spN, WorldSlide.slope(S, x, dir), trav), SimConst.W * 0.25)
			return {"x": SimWrap.wrap(x + dir * d), "travel": absf(travel) + d, "water": false, "t": t, "land": x, "slide": d}
	return {"x": x, "travel": absf(travel), "water": y < WorldWater.seaTop(S, x), "t": t, "land": x}


## special marks a signature, a finisher or a break launch: its ground impact may leave a big crater (world/crater.gd).
static func doLaunch(S: SimState, att, tgt, plan: Dictionary, force: float, special: bool = false) -> void:
	var fm: float = plan.fm if plan.has("fm") else 1.0
	var f: float = force * fm * SimForms.launchMul(S, att)   # D1b: ladder.json (forms: his own steps)
	if S.dirS.ex != null and String(plan.get("name", "")) != "KNOCK BACK":
		DirInterrupt.si(S.dirS.ex.A, DirInterrupt.LAST_END, DirInterrupt.END_LAUNCH)
	tgt.state = "launched"
	if String(plan.get("name", "")) != "KNOCK BACK":
		DirBrawl.launched(S, tgt)   # the brawl's launcher rests on him after any launch
	tgt.launchBy = att
	tgt.bounces = 0.0
	tgt.launchSpecial = special
	tgt.hopped = false
	tgt.stateT = 0.0
	tgt.rush = null
	if tgt.hidden:
		SimHiding.regainLock(S, tgt)   # a launch gives him away: the lock comes back announced (found, and no new break for a while)
	tgt.wet = tgt.y < WorldWater.seaTop(S, tgt.x)
	if "slideFeet" in tgt:
		tgt.slideFeet = String(plan.get("slide", "")) == "feet"   # World's flag for a slide on the feet (ground-contact.md section 24), once the field exists
	tgt.launchT = WorldSlide.launchTravel(plan.ux, plan.uy)
	tgt.slide = 0.0
	tgt.vx = plan.ux * f * tgt.launchT
	tgt.vy = plan.uy * f
	tgt.spin = (1.0 if plan.ux >= 0.0 else -1.0) * S.rng.range_(8.0, 16.0)
	if plan.get("name", "") == "CRATER SLAM":
		_sizeCraterT(S)
		S.dirS.craterT[S.fighters.find(att)] = S.T
	SimFx.launch(S, tgt, att, SimDetMath.hypot(tgt.vx, tgt.vy), 1.0 if tgt.vx >= 0.0 else -1.0)
	WorldBrunt.arm(S, tgt, att, plan)   # B2: the aimed building, the depth waypoints and the chain's token
	_hookArm(S, tgt, plan)   # biomes W6: the plan's biome fields for World's flight (biome.enabled only)
	SimFx.ring(S, tgt.x, tgt.y + 34.0, 600.0, "#ffffff", 0.3, 20.0)
	SimFx.shake(S, 10.0, tgt.x)


## Biomes W6 (docs/world/flight-hooks-w6.md): the launched fighter's record of his plan's biome fields, which World's
## flight reads (WorldContact, through flightHook) so that each candidate plays as biomes.md section 3 says. It sits in
## his director integers after the rally's block and is sized only with biome.enabled on, so the hashed count never
## moves with it off. A record belongs to one launch (HK_LN, the launch number arm gave it); a launch whose plan carries
## no field writes none. Each broken prop's column is kept in its breaker's ring, so the prop query leaves it out.
const HK_LN: int = 0       # the launch number the record belongs to (Fighter.launchN); 0 none
const HK_KIND: int = 1     # HOOKS index plus 1; 0 a plan with only a soft landing
const HK_A: int = 2        # MARSH SWALLOW: embed x 1e6; TREE LINE: the brake a trunk x 1e6; PROP SMASH: the prop's x x 1000
const HK_B: int = 3        # PROP SMASH: the prop's column plus 1; TREE LINE: the trunks the planner counted
const HK_SOFT: int = 4     # the landing's soft factor x 1e6; 0 none
const HK_BRKI: int = 5     # the next slot of the broken props' ring
const HK_BRK: int = 6      # the ring: HK_BRK_N columns plus 1 (0 empty)
const HK_BRK_N: int = 4
const HK_N: int = 10
const HOOKS: Array = ["MARSH SWALLOW", "TREE LINE", "PROP SMASH", "ICE SKID"]


static func _hkBase() -> int:
	return DirRally._base() + DirRally.RL_N


static func _hkSize(f) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < _hkBase() + HK_N:
		f.act.dirI.resize(_hkBase() + HK_N)


## doLaunch's: write tgt's record from the plan's fields (embed, treeBrake, land and prop, ICE SKID's name, soft).
static func _hookArm(S: SimState, tgt, plan: Dictionary) -> void:
	if not biomeOn():
		return
	var nm: String = String(plan.get("name", ""))
	var kind: int = HOOKS.find(nm) + 1
	if (kind == 1 and not plan.has("embed")) or (kind == 2 and not plan.has("treeBrake")) or (kind == 3 and not (plan.has("prop") and plan.has("land"))):
		kind = 0
	var soft: float = float(plan.get("soft", 0.0))
	if kind == 0 and soft <= 0.0:
		return
	_hkSize(tgt)
	var i: int = _hkBase()
	var a: int = 0
	var b: int = 0
	if kind == 1:
		a = int(round(float(plan.embed) * 1.0e6))
	elif kind == 2:
		a = int(round(float(plan.treeBrake) * 1.0e6))
		b = int(plan.get("trees", 0))
	elif kind == 3:
		a = int(round(float(plan.land) * 1000.0))
		b = int(floor(float(plan.land) / SimConst.COL)) % SimConst.NC + 1
	tgt.act.dirI[i + HK_LN] = int(tgt.launchN)
	tgt.act.dirI[i + HK_KIND] = kind
	tgt.act.dirI[i + HK_A] = a
	tgt.act.dirI[i + HK_B] = b
	tgt.act.dirI[i + HK_SOFT] = int(round(soft * 1.0e6))


## World's read of f's flight: {} when his launch carries no biome field, else {"kind": the candidate's name or "", and
## by kind "embed", "treeBrake" and "trees", or "propX" and "propCol"; "soft" (0 none)}.
static func flightHook(S: SimState, f) -> Dictionary:
	var i: int = _hkBase()
	if f.act.dirI.size() < i + HK_N or int(f.launchN) == 0 or f.act.dirI[i + HK_LN] != int(f.launchN):
		return {}
	var kind: int = f.act.dirI[i + HK_KIND]
	var h: Dictionary = {"kind": String(HOOKS[kind - 1]) if kind > 0 else "", "soft": float(f.act.dirI[i + HK_SOFT]) / 1.0e6}
	if kind == 1:
		h.embed = float(f.act.dirI[i + HK_A]) / 1.0e6
	elif kind == 2:
		h.treeBrake = float(f.act.dirI[i + HK_A]) / 1.0e6
		h.trees = f.act.dirI[i + HK_B]
	elif kind == 3:
		h.propX = float(f.act.dirI[i + HK_A]) / 1000.0
		h.propCol = f.act.dirI[i + HK_B] - 1
	return h


## World's flight broke f's PROP SMASH prop: it goes into his ring (the prop query leaves it out from now on) and the
## record's kind is spent, so it breaks once.
static func propBroke(S: SimState, f) -> void:
	var i: int = _hkBase()
	if f.act.dirI.size() < i + HK_N or f.act.dirI[i + HK_KIND] != 3:
		return
	var k: int = f.act.dirI[i + HK_BRKI]
	f.act.dirI[i + HK_BRK + k] = f.act.dirI[i + HK_B]
	f.act.dirI[i + HK_BRKI] = (k + 1) % HK_BRK_N
	f.act.dirI[i + HK_KIND] = 0


## The columns of the props broken in this match (the last HK_BRK_N each fighter broke), for the prop query.
static func brokenProps(S: SimState) -> PackedInt32Array:
	var out := PackedInt32Array()
	var i: int = _hkBase() + HK_BRK
	for f in S.fighters:
		if f.act.dirI.size() >= _hkBase() + HK_N:
			for k in range(HK_BRK_N):
				if f.act.dirI[i + k] > 0:
					out.append(f.act.dirI[i + k] - 1)
	return out


const TILT_CONE: float = 0.7071     # the cosine of 45 degrees: how near the stick's tilt a launch candidate must point


## Which launch candidates a piece's "sends" tag keeps (Combat: across, up, down; turned waits for the turning throw).
const SENDS: Dictionary = {
	"across": ["SMASH ACROSS", "MOUNTAINSIDE", "BUILDING SMASH"],
	"up": ["UPPERCUT"],
	"down": ["DRIVE DOWN", "CRATER SLAM"],
}   # with the biome block on, its sends lists join these (launch_biome.json biome.sends)


## A candidate's kind of send for the surface terms: up, down or across (the biome's sends lists, then SENDS; across else).
static func sendKind(nm: String) -> String:
	for kd in ["up", "down"]:
		if (SENDS[kd] as Array).has(nm) or (biome().get("sends", {}).get(kd, []) as Array).has(nm):
			return kd
	return "across"


## Whether att has earned a launch on tgt at this launch beat (agency-pass.md section 3; launch.json earned): Orb's four.
## Returns the reason, or "" when it has not.
static func earned(S: SimState, ex, att, tgt) -> String:
	var e: Dictionary = data().earned
	if ex.tag.begins_with("HEAVY CLASH"):
		return "a clash won"
	if ex.tag == "GUARD BREAK" or ex.tag == "RIPOSTE":
		return ""   # both end in a knock-back (Orb)
	var p: int = phrase(S, ex, att)
	if p < 0 or (p & 1) != SimAct.HEAVY:
		return ""
	if ((p >> 8) & 3) == DirAlchemy.HELD:
		return "a held heavy"
	var landed: int = DirInterrupt.gi(att, DirInterrupt.LANDED)
	var fl: Dictionary = DirRecipe.cfg().get("flow", {})   # data/director/alchemy.json
	if fl.get("enabled", false):
		# Section 18: flow governs the string's ender. A heavy that ends a string of stringAfter or more landed strikes
		# launches only at flow launchAt or more; below that it is a knock-back, and the stick only aims. The stick
		# earner below is for a heavy that is its own exchange.
		if landed - 1 >= int(fl.enderAfter):
			return ("the ender of a string at flow " + str(att.act.flow) + " (" + str(landed - 1) + " strikes landed before it)") if att.act.flow >= int(fl.launchAt) else ""
	elif landed - 1 >= int(e.enderAfter):
		return "the ender of a full string (" + str(landed - 1) + " strikes landed before it)"
	if (p & DirAlchemy.INTENT) != 0 and DirInterrupt.gi(att, DirInterrupt.TAKEN) <= int(e.cleanTaken):
		return "a heavy with the stick, landing clean"
	return ""


## Whether the AI's next link press is its ender, a heavy: the string is full, or (with the flow gate) it has landed
## enderAfter strikes and its flow would launch.
static func aiEnder(who) -> bool:
	var e: Dictionary = data().earned
	var landed: int = DirInterrupt.gi(who, DirInterrupt.LANDED)
	var fl: Dictionary = DirRecipe.cfg().get("flow", {})
	if fl.get("enabled", false):
		return landed >= int(fl.enderAfter) and who.act.flow >= int(fl.launchAt)
	return landed >= int(e.enderAfter)


## The press behind att's blow at this launch beat: the attacker's is the one that started his exchange or link; the
## defender's (a counter) is his newest press. Packed as the press log packs it; -1 when he pressed nothing.
static func phrase(S: SimState, ex, att) -> int:
	return DirInterrupt.gi(att, DirInterrupt.PHRASE_P) if (att == ex.A or DirBrawl.isBrawl(ex)) else DirAlchemy.last(S, att)   # in a brawl each blow notes its own press


## Whether the blow at this launch beat came from a heavy press (the knock-back) or a light one (the brawl goes on). A
## guard break and a launching riposte are heavy blows whatever was pressed.
static func heavyBlow(S: SimState, ex, att) -> bool:
	if ex.tag == "GUARD BREAK" or ex.tag == "RIPOSTE":
		return true
	var p: int = phrase(S, ex, att)
	return p >= 0 and (p & 1) == SimAct.HEAVY


## The knock-back (launch.json knockBack): a short send, not a launch across the map, distBh body heights by the
## striker's tier.
##  - On the ground, slideUnderBh and over: a low send with no travel boost that the ground-contact model skids (dust,
##    a scuff, a trench). Its plan carries slide "feet" and the distance, for World's slide on the feet.
##  - On the ground, under slideUnderBh: he slides back upright. The director carries him that far along the ground
##    over slideTicks. It is not a launch: no journey, no trench.
##  - In the air, over the sea, or with groundMode "shove": he is carried back that far, upright, over driftTicks.
## mul scales the distance (the plain blur's ender goes blur.enderDist of it). A knock-back the director carries pays
## its wear here (knockBack.wear of a launch's impact at the speed he is carried); a skid's wear is the journey's.
static func knock(S: SimState, att, tgt, mul: float = 1.0, ox: float = NAN) -> void:
	var kb: Dictionary = data().knockBack
	var ti: int = clampi(int(att.tier) - 1, 0, 3)
	var s: float = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(att.x if is_nan(ox) else ox, tgt.x)), att.face)   # ox: away from that point (a mine's blast), not from the attacker
	var g: float = WorldTerrain.groundY(S, tgt.x)
	var dist: float = float(kb.distBh[ti]) * BH * mul
	var ground: bool = String(kb.groundMode) == "skid" and tgt.y - g <= float(kb.groundWithinBh) * BH and not WorldTerrain.seaAt(S, tgt.x)
	if ground:
		SimFx.cue(S, tgt, "slide_brace", "", "")   # Combat's cue for the slide on the feet
	if ground and dist >= float(kb.get("slideUnderBh", 0.0)) * BH:
		var sp: float = float(kb.skidSpeed[ti]) * sqrt(mul)   # a skid's length goes with the square of its speed
		doLaunch(S, att, tgt, {"name": "KNOCK BACK", "ux": s, "uy": float(kb.skidUy), "slide": "feet", "dist": dist}, sp, false)
		tgt.launchT = 1.0          # no travel boost: a knock-back is a short slide, not a flight across the map
		tgt.vx = s * sp            # ... and its speed is the data's, whatever the tier scaling of a launch
		tgt.vy = float(kb.skidUy) * sp
		SimFx.knockback(S, tgt, att, "slideLong", dist, S.tick + int(ceil(2.0 * dist / sp * DirData.TICKS_PER_SEC)))   # the end is an estimate (a steady brake); World's journey decides
		DirRecoil.knocked(S, att, tgt, dist, 1, S.tick + int(ceil(2.0 * dist / sp * DirData.TICKS_PER_SEC)))   # recoil flips: his window out of the skid
		return
	var r := SimState.Rush.new()
	r.px = SimWrap.wrap(tgt.x + s * dist)
	var g2: float = WorldTerrain.groundY(S, r.px)
	var slide: bool = ground and not WorldTerrain.seaAt(S, r.px)   # the upright slide ends on the ground; a drift keeps its height
	r.py = g2 if slide else SimMathx.jmax(tgt.y, g2)
	var ticks: float = float(kb.slideTicks if slide else kb.driftTicks)
	# The bump (World, ground-contact.md section 24): an obstacle inside an upright slide's length ends it early, a body
	# short of it. World's slideObstacle finds it and its bump pays the light brunt when the slide ends; until World has
	# both, the hook does nothing.
	var bumpKind: int = 0
	var so := Callable(WorldContact, "slideObstacle")
	if slide and so.is_valid() and Callable(WorldContact, "bump").is_valid():
		var ob = so.call(S, tgt.x, tgt.z, s, dist)
		if ob is Dictionary and ob.get("hit", false):
			var d2: float = maxf(0.0, float(ob.d) - BUMP_SHORT)
			ticks = maxf(1.0, round(ticks * d2 / maxf(dist, 1.0)))   # the same speed, a shorter way
			dist = d2
			r.px = SimWrap.wrap(tgt.x + s * dist)
			r.py = WorldTerrain.groundY(S, r.px)
			bumpKind = maxi(1, BUMP_KINDS.find(String(ob.get("kind", "wall"))))
			DirInterrupt.si(tgt, DirInterrupt.BUMP_AT, S.tick + int(ticks))
			DirInterrupt.si(tgt, DirInterrupt.BUMP_REQ, bumpKind | (int(dist / (ticks * SimConst.DT)) << 4))
	r.end = S.T + ticks * SimConst.DT
	tgt.rush = r
	SimFx.knockback(S, tgt, att, "bump" if bumpKind > 0 else ("slideShort" if slide else "drift"), dist, S.tick + int(ticks))
	DirRecoil.knocked(S, att, tgt, dist, 2 if slide else 3, S.tick + int(ticks))   # recoil flips: his window out of the slide or the drift
	tgt.vx = 0.0
	tgt.vy = 0.0
	SimFx.ring(S, tgt.x, tgt.y + 34.0, 300.0, "#ffffff", 0.25, 12.0)
	# A knock-back hurts (agency-pass.md section 13, rule 4): half of what a launch's impact costs at that speed.
	var wear: float = float(kb.get("wear", 0.0)) * float(kb.get("impactPerSpeed", 0.0)) * dist / (ticks * SimConst.DT)
	if wear > 0.0:
		SimDamage.hurt(S, tgt, wear, att)


const BUMP_SHORT: float = 30.0   # the slide stops this far short of the obstacle (a body's radius; World's figure)
const BUMP_KINDS: Array = ["", "wall", "heap", "rim"]   # World's obstacle kinds, as BUMP_REQ packs them


## Once a live tick: an upright slide that was cut short by an obstacle ends now, and World's bump pays its light brunt.
static func tick(S: SimState) -> void:
	for f in S.fighters:
		var at: int = DirInterrupt.gi(f, DirInterrupt.BUMP_AT)
		if at <= 0 or S.tick < at:
			continue
		DirInterrupt.si(f, DirInterrupt.BUMP_AT, 0)
		var req: int = DirInterrupt.gi(f, DirInterrupt.BUMP_REQ)
		var bump := Callable(WorldContact, "bump")
		if bump.is_valid() and S.game.ko == null and f.state != "launched":
			bump.call(S, f, SimRoster.opp(S, f), String(BUMP_KINDS[req & 15]), float(req >> 4))


## No launch in the old profiles: the strike shoves the (locked) target back along the attacker's facing.
static func knockBack(S: SimState, att, tgt) -> void:
	tgt.vx += att.face * KNOCKBACK
	SimFx.ring(S, tgt.x, tgt.y + 34.0, 300.0, "#ffffff", 0.25, 12.0)
