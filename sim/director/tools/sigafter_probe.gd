extends SceneTree
## Biomes W2 (docs/combat/biomes.md section 2, rule 3 step 2): the aftermaths, the twists, the trees, the onset cue and
## crater_shape, each shown by a real beam: a signature's fire beat run by the director (DirExchange's beats, beamStep,
## World's jobs) on a gen 2 planet, over the ground of each row that leaves something. Each part a PASS or FAIL line:
##   gen 1     with every switch forced on, the hand-made world and a gen 1 planet lay nothing (no fine biome map)
##   off       with the file's switches (aftermathOn off), a gen 2 beam over each row lays nothing and twists nothing
##   rows      aftermathOn and World's switches on: each row's beam lays its kind (the onset cue, the columns' codes)
##   twists    the six rule lines: under (ocean, sea ice, wetland, beach), skate (ice sheet), wall (tundra)
##   trees     the row's trees reach damageArea: none stands, burn chars, fell and snap fell
##   persona   byPersonality on: a carer's beam near people carves narrower and a villain's wider
##   shape     craters.json on: a slam's shaped crater gets its crater_shape cue, and craterShape gives its row
##   repeat    every switch on (fineOn too), gen 2 AI matches plain and with an intro, each run twice: the state hash
##             every 60 ticks is the same, and the aftermaths, twists and crater_shape cues they made are counted
##   godot --headless --path . --script res://sim/director/tools/sigafter_probe.gd
## Exit code 1 on any FAIL.

const GEN2_SEEDS: Array = [7, 3, 11, 25, 1, 2, 5, 13, 17, 19, 23, 29, 31, 37, 41, 43]
const CODES: Dictionary = {"glaze": [1], "clearing": [2], "heave": [3], "fireLine": [4, 5], "ember": [6, 7], "snowDump": [8], "flood": [9], "scree": [10], "split": [12], "part": [13]}
const TICKS: int = 300

var fails: int = 0


func ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		fails += 1


func _init() -> void:
	WorldAfter.on()
	WorldFill.surfaceOn()
	WorldCraters.on()
	var rows: Dictionary = DirData.sigData().variants
	var want: Array = []
	for k in rows:
		if rows[k].get("aftermath", null) is Dictionary:
			want.append(k)
	print("sigafter probe: %d rows leave something (%s); file aftermathOn %s, byPersonality %s" % [want.size(), ", ".join(want),
		str(DirData.sigData().aftermathOn), str(DirData.sigData().byPersonality.enabled)])
	_gen1()
	var at: Dictionary = _find(want)
	_off(want, at, rows)
	_rows(want, at, rows)
	_twists(at, rows)
	_trees(at, rows)
	_persona(at)
	_shape(at)
	_repeat()
	_reset()
	print("sigafter probe " + ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


func _on(after: bool, pers: bool = false) -> void:
	DirData.sigFine = 1
	DirSigAfter.forceAfter = 1 if after else 0
	DirSigAfter.forcePers = 1 if pers else 0
	DirSigAfter.forceTwist = -1
	WorldAfter.K_ON = after
	WorldFill.K_SURF_ON = after


func _reset() -> void:
	DirData.sigFine = -1
	DirSigAfter.forceAfter = -1
	DirSigAfter.forcePers = -1
	DirSigAfter.forceTwist = -1
	WorldAfter._loaded = false
	WorldFill._loaded = false
	WorldCraters._loaded = false


func _setup(sd: int, touch: int) -> Dictionary:
	return {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}


# ---------------------------------------------------------------- gen 1: nothing is laid

func _gen1() -> void:
	_on(true, false)
	var lay: Array = []
	for setup in [{}, {"planet": 7, "planetGen": 1, "intro": false}]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 1, {}, setup)
		lay.append(DirSigAfter.laying())
		var r: Dictionary = _fire(S, (float(SimConst.NC) * 0.5) * SimConst.COL, "HIT", "")
		lay.append(r.cue != "" or r.twist != "")
		SimCore.dispose(S)
	ok(not lay.has(true), "gen 1: with every switch on, the hand-made world and a gen 1 planet lay nothing and twist nothing (a beam fired on each)")


# ---------------------------------------------------------------- the ground of each row

## Each key: [seed, touch, x], the middle of its longest run of columns on the planets read (highland: its steepest).
func _find(want: Array) -> Dictionary:
	var at: Dictionary = {}
	var best: Dictionary = {}
	for sd in GEN2_SEEDS:
		for touch in [0, 1]:
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, _setup(sd, touch))
			var NC: int = SimConst.NC
			var c: int = 0
			while c < NC:
				var nm: String = WorldBiomes.fineNameAt((float(c) + 0.5) * SimConst.COL)
				var e: int = c
				while e + 1 < NC and WorldBiomes.fineNameAt((float(e + 1) + 0.5) * SimConst.COL) == nm:
					e += 1
				var n: int = e - c + 1
				if want.has(nm):
					var mid: int = (c + e) / 2
					var score: float = float(mini(n, 160))
					if nm == "ocean" or nm == "beach" or nm == "sea_ice":
						score = -1.0
						for k in range(c + 4, e - 4):
							var sc: float = _wetScore(S, nm, k)
							if sc > score:
								score = sc
								mid = k
					elif nm == "highland":
						score = 0.0
						for k in range(c + 8, e - 8):
							var x: float = (float(k) + 0.5) * SimConst.COL
							score = maxf(score, absf(WorldSlide.slope(S, x, 1.0)) * 1000.0 + float(mini(n, 60)))
							if score == absf(WorldSlide.slope(S, x, 1.0)) * 1000.0 + float(mini(n, 60)):
								mid = k
					if score > float(best.get(nm, -1.0)):
						best[nm] = score
						at[nm] = [sd, touch, (float(mid) + 0.5) * SimConst.COL]
				c = e + 1
			SimCore.dispose(S)
		if at.size() == want.size() and float(best.values().min()) >= 60.0:
			break
	return at


## Ocean: a column with standing sea (the defender hovers over it). Beach: low ground with the sea near. Sea ice: a
## floe (ice above the sea) with open water near.
func _wetScore(S: SimState, nm: String, k: int) -> float:
	var x: float = (float(k) + 0.5) * SimConst.COL
	var g: float = WorldTerrain.groundY(S, x)
	if nm == "ocean":
		var d: float = WorldWater.surfaceAt(S, x) - g
		return 100.0 + minf(d, 300.0) if d > 60.0 else -1.0
	if nm == "sea_ice":
		if g <= 2.0 or WorldWater.surfaceAt(S, x) > g:
			return -1.0   # a floe: ice standing above the sea, with open water near
	elif g > -5.0:
		return -1.0
	for j in range(1, 24):
		for sgn in [-1, 1]:
			var xx: float = (float(k + sgn * j) + 0.5) * SimConst.COL
			if WorldWater.surfaceAt(S, xx) > WorldTerrain.groundY(S, xx) + 20.0:
				return 100.0 - float(j) - g * 0.01
	return -1.0


func _match(p: Array) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, _setup(int(p[0]), int(p[1])))
	for f in S.fighters:
		f.ai = null
	return S


## A signature fired by the director at x: the defender stands on the ground (or the sea) at x, the attacker above and
## behind, and the exchange runs its fire beat with the outcome out. Runs TICKS ticks and returns what happened.
func _fire(S: SimState, x: float, out: String, variant: String, side: float = -1.0) -> Dictionary:
	var A = S.fighters[0]
	var D = S.fighters[1]
	for f in S.fighters:
		f.ai = null
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
	var g: float = WorldTerrain.groundY(S, x)
	D.x = x
	D.y = maxf(g, WorldWater.surfaceAt(S, x)) + 2.0
	if WorldBiomes.fineNameAt(x) == "ocean" and WorldWater.surfaceAt(S, x) > g:
		D.y += 400.0   # a defender flying over the sea: his own column is above the beam's reach of the floor
	D.state = "free"
	A.x = SimWrap.wrap(x + side * 900.0)
	A.y = D.y + 700.0
	A.state = "free"
	if variant == "":
		variant = String(DirData.sigRow(DirData.sigKeyAt(D.x)).name)
	var ex = DirExchange.newEx(A, D, "sig")
	S.dirS.ex = ex
	D.state = "locked"
	DirExchange.schedule(ex, 0.0, "beamFire", {"out": out, "variant": variant, "dist": absf(SimWrap.sdx(A.x, D.x))})
	var r := {"cue": "", "cueN": 0, "cueX": 0.0, "cueX1": 0.0, "twist": "", "codes": {}, "x0": D.x, "minUnder": 0.0, "wetTick": -1, "upTick": -1, "setTick": -1,
		"impactX": NAN, "restX": NAN, "landX": NAN, "atD": "", "lead": -1, "fell": 0, "burnt": 0, "trees0": _alive(S), "scorchW": [], "shape": [], "variant": variant}
	var restAt: int = -1
	for t in range(TICKS):
		SimCore.step(S)
		for e in S.out.fx:
			if String(e.type) == "cue" and String(e.kind) == "aftermath":
				r.cue = String(e.text); r.cueN = int(e.n); r.cueX = float(e.x); r.cueX1 = float(e.x1)
			elif String(e.type) == "cue" and String(e.kind) == "sig_twist":
				r.twist = String(e.text)
				r.impactX = D.x
				r.atD = WorldAfter.kindName(WorldAfter.kindAt(S, D.x))
				r.lead = -1
				for j in range(0, 60):
					for sg in [-1, 1]:
						if int(r.lead) < 0 and S.aftermath.size() > 0 and S.aftermath[posmod(WorldAfter._col(D.x) + sg * j, SimConst.NC)] == WorldAfter.SPLIT:
							r.lead = j
			elif String(e.type) == "cue" and String(e.kind) == "crater_shape":
				r.shape.append(DirSigAfter.craterShape(e))
			elif String(e.type) == "scorch" and String(e.variant) == variant:
				r.scorchW.append(float(e.w))
			elif String(e.type) == "damage" and int(e.victim) == 1 and is_nan(float(r.impactX)):
				r.impactX = D.x
		S.out.fx.clear()
		S.out.feed.clear()
		if S.aftermath.size() > 0:
			for i in range(S.aftermath.size()):
				var k: int = S.aftermath[i]
				if k != 0:
					r.codes[k] = maxi(int(r.codes.get(k, 0)), 1)
		var w: float = WorldWater.surfaceAt(S, D.x)
		if D.y < w - 1.0:
			if int(r.wetTick) < 0:
				r.wetTick = t
			r.minUnder = minf(float(r.minUnder), D.y - w)
		elif int(r.wetTick) >= 0 and int(r.upTick) < 0:
			r.upTick = t
		if int(r.wetTick) >= 0 and int(r.setTick) < 0 and D.state != "launched":
			r.setTick = t
		if not is_nan(float(r.impactX)) and is_nan(float(r.landX)) and D.y <= WorldTerrain.groundY(S, D.x) + 2.0 and t > 1:
			r.landX = D.x
		if not is_nan(float(r.impactX)) and D.state != "launched" and restAt < 0 and t > 20:
			restAt = t
			r.restX = D.x
		if S.game.ko != null:
			break
	if is_nan(float(r.restX)):
		r.restX = D.x
	var alive1: Array = _alive(S)
	for i in range(S.trees.size()):
		if r.trees0[i] and not alive1[i]:
			r.fell += 1
			if float(S.trees[i].burn) >= 1.0:
				r.burnt += 1
	return r


func _alive(S: SimState) -> Array:
	var a: Array = []
	for t in S.trees:
		a.append(bool(t.alive))
	return a


func _codes(r: Dictionary) -> String:
	var out: Array = []
	for k in r.codes:
		out.append(WorldAfter.kindName(int(k)))
	out.sort()
	return ", ".join(out) if not out.is_empty() else "none"


# ---------------------------------------------------------------- off: the file's switches

func _off(want: Array, at: Dictionary, rows: Dictionary) -> void:
	DirData.sigFine = 1
	DirSigAfter.forceAfter = -1
	DirSigAfter.forcePers = -1
	WorldAfter.K_ON = true   # World's own switch on: the director's aftermathOn (off in the file) is the gate shown
	WorldFill.K_SURF_ON = true
	var bad: Array = []
	for k in want:
		if not at.has(k):
			continue
		var S := _match(at[k])
		var tw = rows[k].get("twist", null)
		var r: Dictionary = _fire(S, float(at[k][2]), String(tw.outcome) if tw is Dictionary else "HIT", "")
		if r.cue != "" or r.twist != "" or not r.codes.is_empty():
			bad.append(k)
		SimCore.dispose(S)
	ok(bad.is_empty(), "off: with the file's aftermathOn (%s), a beam over each of the %d rows lays nothing, cues nothing and twists nothing%s" % [
		str(DirData.sigData().aftermathOn), want.size(), ("" if bad.is_empty() else "; laid: " + ", ".join(bad))])


# ---------------------------------------------------------------- rows: each aftermath kind

func _rows(want: Array, at: Dictionary, rows: Dictionary) -> void:
	_on(true)
	var kinds: Dictionary = {}
	for k in want:
		if not at.has(k):
			ok(false, "rows: %s has no ground on the planets read" % k)
			continue
		var a: Dictionary = rows[k].aftermath
		var kind: String = String(a.kind)
		var S := _match(at[k])
		var tw = rows[k].get("twist", null)
		var r: Dictionary = _fire(S, float(at[k][2]), String(tw.outcome) if tw is Dictionary else "HIT", "")
		var hit: bool = false
		for c in CODES[kind]:
			hit = hit or r.codes.has(c)
		ok(r.cue == kind and int(r.cueN) > 0 and hit, "rows: %s (seed %d touch %d, x %.0f) %s lays %s: onset cue %s over %d columns (x %.0f to %.0f); codes seen %s" % [
			k, int(at[k][0]), int(at[k][1]), float(at[k][2]), String(rows[k].name), kind, (r.cue if r.cue != "" else "none"), int(r.cueN), float(r.cueX), float(r.cueX1), _codes(r)])
		if r.cue == kind and hit:
			kinds[kind + ("/" + String(a.source) if a.has("source") else "")] = true
		SimCore.dispose(S)
	var ks: Array = kinds.keys()
	ks.sort()
	ok(ks.size() == want.size(), "rows: %d of %d aftermaths laid by a real beam (%s)" % [ks.size(), want.size(), ", ".join(ks)])


# ---------------------------------------------------------------- twists: the six rule lines

func _twists(at: Dictionary, rows: Dictionary) -> void:
	_on(true)
	for k in rows:
		var tw = rows[k].get("twist", null)
		if not (tw is Dictionary) or not at.has(k):
			continue
		var kind: String = String(tw.kind)
		var out: String = String(tw.outcome)
		var S := _match(at[k])
		var r: Dictionary = _fire(S, float(at[k][2]), out, "")
		SimCore.dispose(S)
		if kind == "under":
			var up: int = int(r.upTick) - int(r.wetTick)
			if int(r.upTick) < 0 and int(r.setTick) >= 0:
				up = int(r.setTick) - int(r.wetTick)   # waded water (a floe's lead): in it, landed, never under the rule
			ok(r.twist == "under" and int(r.wetTick) >= 0 and up >= 0 and up <= 32, "twists: %s %s %s: driven under (%.0f below the surface at most) and up set after %d ticks (the water rule: within 30 of going under, World's surfacing on) ; his column at the impact: %s%s" % [
				k, String(rows[k].name), out, -float(r.minUnder), up, (r.atD if r.atD != "" else "plain"), ("" if k != "sea_ice" else ", the lead %d columns away" % int(r.lead))])
		else:
			DirSigAfter.forceTwist = 0
			var S0 := _match(at[k])
			var r0: Dictionary = _fire(S0, float(at[k][2]), out, "")
			SimCore.dispose(S0)
			DirSigAfter.forceTwist = -1
			_on(false)
			var Sp := _match(at[k])
			var rp: Dictionary = _fire(Sp, float(at[k][2]), out, "")
			SimCore.dispose(Sp)
			_on(true)
			var dp: float = absf(SimWrap.sdx(float(rp.impactX), float(rp.restX)))
			var d1: float = absf(SimWrap.sdx(float(r.impactX), float(r.restX)))
			var d0: float = absf(SimWrap.sdx(float(r0.impactX), float(r0.restX)))
			if kind == "skate":
				var ratio: float = d1 / maxf(d0, 1.0)
				var s1: float = absf(SimWrap.sdx(float(r.landX), float(r.restX)))
				var s0: float = absf(SimWrap.sdx(float(r0.landX), float(r0.restX)))
				ok(r.twist == "skate" and r0.twist == "" and ratio > 1.5, "twists: %s %s GUARD: the push-back on the glaze goes %.0f against %.0f without the twist (x%.2f), its slide %.0f against %.0f (x%.2f; the row asks %.1f); on bare ground (no aftermath) %.0f, x%.2f of that" % [
					k, String(rows[k].name), d1, d0, ratio, s1, s0, s1 / maxf(s0, 1.0), float(tw.slideMul), dp, d1 / maxf(dp, 1.0)])
			else:
				var S2 := _match(at[k])
				var r2: Dictionary = _fire(S2, float(at[k][2]), out, "")
				var c: int = WorldAfter._col(float(r2.restX))
				var near: int = 99
				for j in range(-3, 4):
					if S2.aftermath[posmod(c + j, SimConst.NC)] == WorldAfter.PLATES:
						near = mini(near, absi(j))
				SimCore.dispose(S2)
				ok(r.twist == "wall" and near <= 3, "twists: %s %s GUARD: the push-back runs %.0f and stops against the heaved plates (%d columns from them; %.0f without the twist)" % [
					k, String(rows[k].name), d1, near, d0])


# ---------------------------------------------------------------- trees: the row's mode reaches damageArea

func _trees(at: Dictionary, rows: Dictionary) -> void:
	_on(false)
	for k in ["savanna", "jungle", "taiga", "ice_sheet", "plains", "forest"]:
		if not at.has(k) and k != "plains" and k != "forest":
			continue
		var p = at.get(k, null)
		if p == null:
			continue
		var S := _match(p)
		var mode: String = String(rows[k].trees)
		var r: Dictionary = _fire(S, float(p[2]), "HIT", "")
		var good: bool
		match mode:
			"none": good = r.fell == 0
			"burn": good = r.fell == 0 or r.burnt > 0
			_: good = true
		ok(good, "trees: %s %s (%s): %d trees felled on the path, %d charred" % [k, String(rows[k].name), mode, int(r.fell), int(r.burnt)])
		SimCore.dispose(S)


# ---------------------------------------------------------------- persona: the personality term

func _persona(at: Dictionary) -> void:
	# A town on a gen 2 planet: the same beam by the carer and by the villain, near people, with the term off and on.
	var p = null
	for sd in GEN2_SEEDS:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 1, {}, _setup(sd, 0))
		for b in S.buildings:
			if b.alive and WorldStructures.popNear(S, b.x, DirLaunch.CARE_R) > 0.5:
				p = [sd, 0, b.x]
				break
		SimCore.dispose(S)
		if p != null:
			break
	if p == null:
		ok(false, "persona: no populated place on the planets read")
		return
	var w: Dictionary = {}
	for pers in [false, true]:
		for who in [1.0, -1.0]:
			_on(false, pers)
			var S := _match(p)
			S.fighters[0].care = who
			var r: Dictionary = _fire(S, float(p[2]), "HIT", "")
			w["%s %s" % ["on" if pers else "off", "hero" if who > 0.0 else "villain"]] = (r.scorchW.max() if not r.scorchW.is_empty() else 0.0)
			SimCore.dispose(S)
	var good: bool = w["off hero"] == w["off villain"] and w["on hero"] < w["off hero"] and w["on villain"] > w["off villain"]
	ok(good, "persona: near people the groove's widest is %.1f (off, both); on, the carer's %.1f and the villain's %.1f" % [w["off hero"], w["on hero"], w["on villain"]])


# ---------------------------------------------------------------- shape: crater_shape

func _shape(at: Dictionary) -> void:
	_on(false)
	WorldCraters.K_ON = true
	var seen: Array = []
	for k in ["wetland", "desert", "tundra", "sea_ice", "beach", "volcanic"]:
		if not at.has(k):
			continue
		var S := _match(at[k])
		var A = S.fighters[0]
		var D = S.fighters[1]
		var x: float = float(at[k][2])
		D.x = x
		D.y = WorldTerrain.groundY(S, x) + 600.0
		A.x = SimWrap.wrap(x - 300.0)
		DirLaunch.doLaunch(S, A, D, {"ux": 0.0, "uy": -1.0}, 2600.0, true)
		for t in range(120):
			SimCore.step(S)
			for e in S.out.fx:
				if String(e.type) == "cue" and String(e.kind) == "crater_shape":
					var c: Dictionary = DirSigAfter.craterShape(e)
					if not c.is_empty() and c.has("shape"):
						seen.append("%s %s r %.0f" % [k, String(c.surface), float(c.r)])
			S.out.fx.clear()
			S.out.feed.clear()
		SimCore.dispose(S)
	WorldCraters.K_ON = false
	ok(not seen.is_empty(), "shape: craters.json on, a slam's shaped crater gets a crater_shape cue with its row (%s)" % (", ".join(seen) if not seen.is_empty() else "none"))


# ---------------------------------------------------------------- repeat: determinism with every switch on

func _repeat() -> void:
	_on(true, true)
	WorldCraters.K_ON = true
	for intro in [false, true]:
		var same: bool = true
		var counts: Dictionary = {}
		var n: int = 0
		for m in range(6):
			var setup: Dictionary = _setup(int(GEN2_SEEDS[m]), m % 2)
			if intro:
				setup["intro"] = {"play": true}
			var runs: Array = []
			for rep in range(2):
				var S := SimCore.createSim()
				SimCore.newMatch(S, 300 + m, {}, setup)
				var hs: Array = []
				for t in range(4800):
					SimCore.step(S)
					if rep == 0:
						for e in S.out.fx:
							if String(e.type) == "cue" and (String(e.kind) == "aftermath" or String(e.kind) == "sig_twist" or String(e.kind) == "crater_shape"):
								counts[String(e.kind)] = int(counts.get(String(e.kind), 0)) + 1
					S.out.fx.clear()
					S.out.feed.clear()
					if t % 60 == 59:
						hs.append(str(SimHash.stateHash(S)))
					if S.game.ko != null and S.game.koT > 3.0:
						break
				hs.append(str(SimHash.stateHash(S)))
				runs.append(hs)
				SimCore.dispose(S)
			same = same and runs[0] == runs[1]
			n += runs[0].size()
		ok(same, "repeat%s: every switch on, 6 gen 2 AI matches run twice: %d state hashes, all the same; cues made: %s" % [
			(" with the intro" if intro else ""), n, _countsOf(counts)])
	WorldCraters.K_ON = false


func _countsOf(d: Dictionary) -> String:
	var ks: Array = d.keys()
	ks.sort()
	var out: Array = []
	for k in ks:
		out.append("%s %d" % [k, int(d[k])])
	return ", ".join(out) if not out.is_empty() else "none"
