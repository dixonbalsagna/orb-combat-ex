extends SceneTree
## Biomes W3 (docs/combat/biomes.md section 3; data/combat/launch_biome.json): the eight launch candidates that use the
## ground, each shown chosen by real launches on gen 2 planets. Each part a PASS or FAIL line:
##   off     with the file's switch (biome.enabled false), a spot where every candidate's feature is offers none of them
##           and the feed has no biome part
##   spots   with the switch on, gen 2 planets are searched for spots where each candidate is offered
##   picks   at each candidate's spots the director's own launch beat (DirMelee.launchBeat, forced as the brawl's
##           launcher is) runs real launches: each candidate is chosen at least once and he is launched. The share taken
##           where offered is printed against QA's band (takenWhereOffered), and one feed line a candidate shows its
##           score printed with the top three
##   repeat  the switch on, gen 2 AI matches plain and with an intro, each run twice: the state hash every 60 ticks is
##           the same, and the biome candidates they launched with are counted
##   godot --headless --path . --script res://sim/director/tools/launchbiome_probe.gd
## Exit code 1 on any FAIL.

const SEEDS: Array = [7, 3, 11, 25, 1, 2, 5, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79]
const NAMES: Array = ["CLIFFSIDE", "ICE SKID", "MARSH SWALLOW", "TREE LINE", "SKIM ASHORE", "DOWNHILL", "VENT LIFT", "PROP SMASH"]
const SPOTS: int = 12      # spots kept a candidate, at least SPACE columns apart
const SPACE: int = 40
const TRIES: int = 4       # launches a spot, each way (two facings)

var fails: int = 0


func ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		fails += 1


func _init() -> void:
	DirLaunch.forceBiome = 1
	var spots: Dictionary = _spots()
	DirLaunch.forceBiome = -1
	_off(spots)
	DirLaunch.forceBiome = 1
	_picks(spots)
	_repeat()
	DirLaunch.forceBiome = -1
	print("launchbiome probe " + ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


func _setup(sd: int, touch: int) -> Dictionary:
	return {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}


## Puts the defender at x (over the sea's top for over-water, on the ground else) and the attacker a little behind him
## on side -sg, facing him. Both are free and without AI.
func _pose(S: SimState, x: float, sg: float) -> void:
	var A = S.fighters[0]
	var D = S.fighters[1]
	for f in S.fighters:
		f.ai = null
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	var g: float = WorldTerrain.groundY(S, x)
	D.x = SimWrap.wrap(x)
	D.y = (WorldWater.seaTop(S, x) + 40.0) if WorldTerrain.seaAt(S, x) else g + 2.0
	A.x = SimWrap.wrap(x - sg * 200.0)
	A.y = D.y
	A.face = sg
	D.face = -sg


func _offered(S: SimState, sg: float) -> Array:
	var A = S.fighters[0]
	var D = S.fighters[1]
	var c: Array = []
	DirLaunch._biomeCands(S, A, D, c, false, not DirData.contact().is_empty(), _force() * SimForms.launchMul(S, A))
	return c.map(func(k): return String(k.name))


func _force() -> float:
	return float(DirBrawl.cfg().get("heavy", {}).get("force", 1.0))


# ---------------------------------------------------------------- spots

## name: [[seed, touch, x, facing]], up to SPOTS each.
func _spots() -> Dictionary:
	var out: Dictionary = {}
	var last: Dictionary = {}
	for nm in NAMES:
		out[nm] = []
	for sd in SEEDS:
		for touch in [0, 1]:
			if NAMES.all(func(n): return (out[n] as Array).size() >= SPOTS):
				break
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, _setup(sd, touch))
			for nm in NAMES:
				last[nm] = -999
			for col in range(0, SimConst.NC, 4):
				var x: float = (float(col) + 0.5) * SimConst.COL
				for sg in [1.0, -1.0]:
					_pose(S, x, sg)
					for nm in _offered(S, sg):
						if (out[nm] as Array).size() < SPOTS and col - int(last[nm]) >= SPACE:
							out[nm].append([sd, touch, x, sg])
							last[nm] = col
			SimCore.dispose(S)
	var parts: PackedStringArray = []
	for nm in NAMES:
		parts.append("%s %d" % [nm, (out[nm] as Array).size()])
	ok(NAMES.all(func(n): return (out[n] as Array).size() > 0), "spots: each candidate offered somewhere on gen 2 planets (%s)" % ", ".join(parts))
	return out


# ---------------------------------------------------------------- off

func _off(spots: Dictionary) -> void:
	var offered: int = 0
	var feedBio: int = 0
	var n: int = 0
	for nm in NAMES:
		for sp in spots[nm]:
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, _setup(int(sp[0]), int(sp[1])))
			_pose(S, float(sp[2]), float(sp[3]))
			var r: Dictionary = _launch(S, float(sp[3]))
			n += 1
			for k in r.all:
				if k.get("bio", false):
					offered += 1
			if r.feed.contains("biome:"):
				feedBio += 1
			SimCore.dispose(S)
	ok(offered == 0 and feedBio == 0 and not DirLaunch.biomeOn(), "off: with the file's switch (enabled %s), %d real launches at the candidates' spots offer no biome candidate (%d) and print no biome part (%d)" % [
		str(DirLaunch.biome().get("enabled", null)), n, offered, feedBio])


## One real launch beat by fighter 0 on fighter 1 as posed: {"chosen", "all" (the planner's candidates), "feed" (the
## LAUNCH line), "launched"}.
func _launch(S: SimState, sg: float) -> Dictionary:
	var A = S.fighters[0]
	var D = S.fighters[1]
	S.out.fx.clear()
	S.out.feed.clear()
	var ex = DirExchange.newEx(A, D, "probe")
	S.dirS.ex = ex
	D.state = "locked"
	DirMelee.launchBeat(S, ex, A, D, _force(), false, {"forced": true, "why": "probe"})
	var chosen: String = ""
	var all: Array = []
	for e in S.out.fx:
		if String(e.type) == "launch_plan":
			chosen = String(e.chosen)
			for part in String(e.text).split("|"):
				var nm: String = part.substr(0, part.rfind(" "))
				all.append({"name": nm, "bio": NAMES.has(nm)})
	var line: String = ""
	for l in S.out.feed:
		if String(l.tag).begins_with("LAUNCH:"):
			line = String(l.tag) + "  " + String(l.sub)
	return {"chosen": chosen, "all": all, "feed": line, "launched": D.state == "launched"}


# ---------------------------------------------------------------- picks

func _picks(spots: Dictionary) -> void:
	var band: Array = DirLaunch.biome().get("qa", {}).get("takenWhereOffered", [0.05, 0.3])
	for nm in NAMES:
		var offered: int = 0
		var taken: int = 0
		var launched: int = 0
		var shown: String = ""
		var mix: Dictionary = {}
		for sp in spots[nm]:
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, _setup(int(sp[0]), int(sp[1])))
			for t in range(TRIES * 2):
				var sg: float = float(sp[3]) * (1.0 if t % 2 == 0 else -1.0)
				_pose(S, float(sp[2]), sg)
				var r: Dictionary = _launch(S, sg)
				if not r.all.any(func(k): return k.name == nm):
					continue
				offered += 1
				mix[r.chosen] = int(mix.get(r.chosen, 0)) + 1
				if r.chosen == nm:
					taken += 1
					if r.launched:
						launched += 1
					if shown == "":
						shown = r.feed
				for i in range(30):
					SimCore.step(S)   # the flight goes on a little: the next launch is from a later point in the draws
			SimCore.dispose(S)
		var share: float = float(taken) / maxf(1.0, float(offered))
		ok(taken > 0 and launched == taken, "picks %s: chosen in %d of %d real launches where offered (%.0f%%; QA's band %.0f to %.0f%%%s), launched every time; the mix there: %s" % [
			nm, taken, offered, 100.0 * share, 100.0 * float(band[0]), 100.0 * float(band[1]), "" if (share >= float(band[0]) and share <= float(band[1])) else ", OUTSIDE (a probe of feature spots, not the batch)", _mixOf(mix)])
		if shown != "":
			print("      feed: " + shown)


func _mixOf(d: Dictionary) -> String:
	var ks: Array = d.keys()
	ks.sort_custom(func(a, b): return int(d[a]) > int(d[b]) or (int(d[a]) == int(d[b]) and String(a) < String(b)))
	var p: PackedStringArray = []
	for k in ks:
		p.append("%s %d" % [k, int(d[k])])
	return ", ".join(p)


# ---------------------------------------------------------------- repeat

func _repeat() -> void:
	for intro in [false, true]:
		var same: bool = true
		var n: int = 0
		var bio: Dictionary = {}
		for m in range(8):
			var setup: Dictionary = _setup(int(SEEDS[m]), m % 2)
			if intro:
				setup["intro"] = {"play": true}
			var runs: Array = []
			for rep in range(2):
				var S := SimCore.createSim()
				SimCore.newMatch(S, 500 + m, {}, setup)
				var hs: Array = []
				for t in range(7200):
					SimCore.step(S)
					if rep == 0:
						for e in S.out.fx:
							if String(e.type) == "launch_plan" and NAMES.has(String(e.chosen)):
								bio[String(e.chosen)] = int(bio.get(String(e.chosen), 0)) + 1
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
		ok(same and not bio.is_empty(), "repeat%s: the switch on, 8 gen 2 AI matches run twice: %d state hashes, all the same; biome launches in them: %s" % [
			(" with the intro" if intro else ""), n, _mixOf(bio) if not bio.is_empty() else "none"])
