extends SceneTree
## Biomes W6 (docs/world/flight-hooks-w6.md): World's flight hooks, each played by a real launch on gen 2 planets with
## Combat's biome switch on (DirLaunch.forceBiome, tools only). Each part a PASS or FAIL line:
##   spots   gen 2 planets are searched for spots where MARSH SWALLOW, TREE LINE, PROP SMASH and ICE SKID are offered
##   embed   MARSH SWALLOW: the first landing embeds every time, 1.8 times as deep as the bowl holds a plain embed; the twin
##           (the same launch with the record's kind cleared) embeds less often
##   soft    the soft landing: the journey's damage with the plan's soft is soft times the twin's without it
##   trunks  TREE LINE: the trunks on his path snap, each taking the brake off his speed; the twin snaps none
##   prop    PROP SMASH: the prop breaks, he stops a body's radius short of it, and the prop query leaves it out after
##   skid    ICE SKID: control returns at the rock stop (the reference run), the skate goes on on the ice, and the twin
##           holds him until the ice stops him, later
##   off     with the switch off, the same plans launch with no record and no hook plays
##   repeat  the switch on, gen 2 AI matches plain and with an intro, each run twice: the state hash every 60 ticks is
##           the same, and the hooks that played in them are counted
## A launch is the director's own launch beat (DirMelee.launchBeat, forced as the brawl's launcher is) when it picks the
## candidate, else DirLaunch.doLaunch with the planner's own plan for it (chooseLaunch's candidate). Both are counted.
##   godot --headless --path . --script res://sim/world/tools/flighthooks_probe.gd
## Exit code 1 on any FAIL.

const SEEDS: Array = [7, 3, 11, 25, 1, 2, 5, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79]
const NAMES: Array = ["MARSH SWALLOW", "TREE LINE", "PROP SMASH", "ICE SKID"]
const SPOTS: Dictionary = {"MARSH SWALLOW": 10, "TREE LINE": 10, "PROP SMASH": 10, "ICE SKID": 40}   # ICE SKID's spots mostly end in a lead (its end bonus), so more are searched
const SPACE: int = 40
const TRIES: int = 4
const FLY: int = 900       # ticks a launch is followed at most

var fails: int = 0


func ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		fails += 1


func _init() -> void:
	DirLaunch.forceBiome = 1
	WorldContact.hookLogOn = true
	var spots: Dictionary = _spots()
	var plays: Dictionary = {}
	for nm in NAMES:
		plays[nm] = _plays(nm, spots[nm])
	_embed(plays["MARSH SWALLOW"])
	_soft(plays)
	_trunks(plays["TREE LINE"])
	_prop(plays["PROP SMASH"])
	_skid(plays["ICE SKID"])
	_off(plays)
	_repeat()
	DirLaunch.forceBiome = -1
	WorldContact.hookLogOn = false
	print("flighthooks probe " + ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


func _setup(sd: int, touch: int) -> Dictionary:
	return {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}


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


func _force() -> float:
	return float(DirBrawl.cfg().get("heavy", {}).get("force", 1.0))


func _offered(S: SimState) -> Array:
	var c: Array = []
	DirLaunch._biomeCands(S, S.fighters[0], S.fighters[1], c, false, not DirData.contact().is_empty(), _force() * SimForms.launchMul(S, S.fighters[0]))
	return c.map(func(k): return String(k.name))


func _spots() -> Dictionary:
	var out: Dictionary = {}
	var last: Dictionary = {}
	for nm in NAMES:
		out[nm] = []
	for sd in SEEDS:
		for touch in [0, 1]:
			if NAMES.all(func(n): return (out[n] as Array).size() >= int(SPOTS[n])):
				break
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, _setup(sd, touch))
			for nm in NAMES:
				last[nm] = -999
			for col in range(0, SimConst.NC, 4):
				var x: float = (float(col) + 0.5) * SimConst.COL
				for sg in [1.0, -1.0]:
					_pose(S, x, sg)
					for nm in _offered(S):
						if out.has(nm) and (out[nm] as Array).size() < int(SPOTS[nm]) and col - int(last[nm]) >= SPACE:
							out[nm].append([sd, touch, x, sg])
							last[nm] = col
			SimCore.dispose(S)
	var parts: PackedStringArray = []
	for nm in NAMES:
		parts.append("%s %d" % [nm, (out[nm] as Array).size()])
	ok(NAMES.all(func(n): return (out[n] as Array).size() > 0), "spots: each hooked candidate offered on gen 2 planets (%s)" % ", ".join(parts))
	return out


# ---------------------------------------------------------------- one launch, followed

## A fresh match at the spot, stepped `pre` ticks (a different point in the draws), posed, and launched: by the launch
## beat when it picks nm, else (beat false) by doLaunch with the planner's own candidate for nm. mut (or null) runs on D
## right after the launch (the twin's change). Then the flight is followed to its end. Returns the play, or {} when nm was
## not offered there.
func _play(nm: String, sp: Array, sg: float, pre: int, beat: bool, mut = null, plan = null) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, _setup(int(sp[0]), int(sp[1])))
	for i in range(pre):
		SimCore.step(S)
	_pose(S, float(sp[2]), sg)
	var A = S.fighters[0]
	var D = S.fighters[1]
	S.out.fx.clear()
	S.out.feed.clear()
	WorldContact.hookLog.clear()
	var ex = DirExchange.newEx(A, D, "probe")
	S.dirS.ex = ex
	D.state = "locked"
	var used: Dictionary = {}
	if plan != null:
		used = plan
		DirLaunch.doLaunch(S, A, D, plan, _force())
	elif beat:
		DirMelee.launchBeat(S, ex, A, D, _force(), false, {"forced": true, "why": "probe"})
		var chosen: String = ""
		for e in S.out.fx:
			if String(e.type) == "launch_plan":
				chosen = String(e.chosen)
		if chosen != nm or D.state != "launched":
			SimCore.dispose(S)
			return {}
	else:
		var r: Dictionary = DirLaunch.chooseLaunch(S, A, D, _force())
		for k in r.all:
			if String(k.name) == nm:
				used = k
		if used.is_empty():
			SimCore.dispose(S)
			return {}
		DirLaunch.doLaunch(S, A, D, used, _force())
	if D.state != "launched":
		SimCore.dispose(S)
		return {}
	var n: int = D.launchN
	var hook: Dictionary = DirLaunch.flightHook(S, D)
	if mut != null:
		mut.call(S, D)
	var hp0: float = D.hp
	var x0: float = D.x
	var embeds: int = 0
	var embedDepth: float = 0.0
	var endTick: int = -1
	var skate: float = 0.0
	var skateX: float = 0.0
	var ctrlX: float = 0.0
	var ctrlT: int = -1
	var tick0: int = S.tick
	for t in range(FLY):
		if D.state == "launched":
			SimCore.step(S)
			for e in S.out.fx:
				if String(e.type) == "embed" and int(e.actor) == 1:
					embeds += 1
					embedDepth = float(e.depth)
			S.out.fx.clear()
			S.out.feed.clear()
			if D.state != "launched" and endTick < 0:
				endTick = S.tick - tick0
				ctrlX = D.x
				ctrlT = D.ctrlT
				skate = D.skateV
		elif D.skateV > 0.0:
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
		else:
			break
	skateX = D.x
	var log: Array = WorldContact.hookLog.filter(func(e): return int(e.n) == n)
	var after: Array = WorldGround.matchProps(S, 0.0, float(SimConst.NC) * SimConst.COL, DirLaunch.brokenProps(S))
	var raw: Array = WorldGround.matchProps(S, 0.0, float(SimConst.NC) * SimConst.COL)
	var out := {"plan": used, "hook": hook, "log": log, "hurt": hp0 - D.hp, "x0": x0, "end": endTick, "ctrlX": ctrlX, "skate": skate,
		"skateD": absf(SimWrap.sdx(ctrlX, skateX)), "embeds": embeds, "embedDepth": embedDepth, "after": after.size(), "raw": raw.size(),
		"travel": absf(SimWrap.sdx(x0, ctrlX)), "broken": DirLaunch.brokenProps(S)}
	SimCore.dispose(S)
	return out


## Every way nm is played at its spots: [{"sp", "sg", "pre", "beat", "r"}], the launch beat's picks first, then (when
## it picked none at a spot) the planner's plan through doLaunch.
func _plays(nm: String, spots: Array) -> Array:
	var out: Array = []
	for sp in spots:
		var got: bool = false
		for t in range(TRIES * 2):
			var sg: float = float(sp[3]) * (1.0 if t % 2 == 0 else -1.0)
			var r: Dictionary = _play(nm, sp, sg, 7 * t, true)
			if not r.is_empty():
				out.append({"sp": sp, "sg": sg, "pre": 7 * t, "beat": true, "r": r})
				got = true
				break
		if not got:
			var r: Dictionary = _play(nm, sp, float(sp[3]), 0, false)
			if not r.is_empty():
				out.append({"sp": sp, "sg": float(sp[3]), "pre": 0, "beat": false, "r": r})
	var nb: int = out.filter(func(p): return p.beat).size()
	print("      %s: %d plays (%d by the launch beat, %d by doLaunch with the planner's plan)" % [nm, out.size(), nb, out.size() - nb])
	return out


## The twin of play p: the same launch, with mut applied right after it.
func _twin(nm: String, p: Dictionary, mut: Callable) -> Dictionary:
	return _play(nm, p.sp, p.sg, p.pre, p.beat, mut)


static func _clearKind(S: SimState, f) -> void:
	f.act.dirI[DirLaunch._hkBase() + DirLaunch.HK_KIND] = 0


static func _clearSoft(S: SimState, f) -> void:
	f.act.dirI[DirLaunch._hkBase() + DirLaunch.HK_SOFT] = 0


# ---------------------------------------------------------------- the hooks

func _embed(plays: Array) -> void:
	var n: int = 0
	var emb: int = 0
	var deep: int = 0
	var twinEmb: int = 0
	var shown: String = ""
	for p in plays:
		var r: Dictionary = p.r
		n += 1
		var e: Array = r.log.filter(func(x): return x.k == "embed")
		if r.embeds > 0 and e.size() == 1:
			emb += 1
			var ratio: float = float(e[0].depth) / maxf(float(e[0].plain), 1.0e-9)
			if absf(ratio - float(r.hook.embed)) < 1.0e-6 and absf(float(r.embedDepth) - float(e[0].depth)) < 1.0e-6:
				deep += 1
			if shown == "":
				shown = "planet %d at x %.0f: bowl %.1f, a plain embed would sit %.1f, he sits %.1f (x%.2f)" % [int(p.sp[0]), float(p.sp[2]), float(e[0].bowl), float(e[0].plain), float(e[0].depth), ratio]
		var tw: Dictionary = _twin("MARSH SWALLOW", p, _clearKind)
		if not tw.is_empty() and tw.embeds > 0:
			twinEmb += 1
	ok(n > 0 and emb == n and deep == n and twinEmb < n, "embed: MARSH SWALLOW embedded in %d of %d launches, each %.1f times as deep as the plain embed (%d of %d); the twin without the hook embedded %d of %d" % [
		emb, n, 1.8, deep, n, twinEmb, n])
	if shown != "":
		print("      " + shown)


func _soft(plays: Dictionary) -> void:
	var n: int = 0
	var good: int = 0
	var shown: String = ""
	for nm in NAMES:
		for p in plays[nm]:
			var s: float = float(p.r.hook.get("soft", 0.0))
			if s <= 0.0 or p.r.hurt <= 0.0:
				continue
			var tw: Dictionary = _twin(nm, p, _clearSoft)
			if tw.is_empty() or tw.hurt <= 0.0:
				continue
			n += 1
			var ratio: float = float(p.r.hurt) / float(tw.hurt)
			if absf(ratio - s) < 0.02:
				good += 1
			if shown == "" or absf(ratio - s) >= 0.02:
				shown = "%s on planet %d: soft %.2f, the journey's damage %.2f against the twin's %.2f (x%.3f)" % [nm, int(p.sp[0]), s, float(p.r.hurt), float(tw.hurt), ratio]
	ok(n > 0 and good == n, "soft: in %d launches whose plan lands soft, the journey's damage is soft times the twin's without it (%d within 0.02)" % [n, good])
	if shown != "":
		print("      " + shown)


func _trunks(plays: Array) -> void:
	var n: int = 0
	var snapped: int = 0
	var braked: bool = true
	var twinSnap: int = 0
	var shown: String = ""
	for p in plays:
		var r: Dictionary = p.r
		n += 1
		var tr: Array = r.log.filter(func(x): return x.k == "trunk")
		snapped += tr.size()
		var lost: float = 0.0
		for e in tr:
			braked = braked and absf(float(e.after) - float(e.before) * (1.0 - float(r.hook.treeBrake))) < 1.0e-6
			lost += float(e.before) - float(e.after)
		if shown == "" and tr.size() > 0:
			shown = "planet %d at x %.0f: %d trunks snapped (the planner counted %d), speed %.0f to %.0f, %.0f lost to them; travel %.0f" % [
				int(p.sp[0]), float(p.sp[2]), tr.size(), int(r.hook.trees), float(tr[0].before), float(tr[tr.size() - 1].after), lost, float(r.travel)]
		var tw: Dictionary = _twin("TREE LINE", p, _clearKind)
		if not tw.is_empty():
			twinSnap += tw.log.filter(func(x): return x.k == "trunk").size()
			if shown != "" and not shown.contains("twin"):
				shown += ", the twin's %.0f" % float(tw.travel)
	ok(n > 0 and snapped > 0 and braked and twinSnap == 0, "trunks: TREE LINE in %d launches snapped %d trunks, each taking 12%% of his speed; the twin snapped %d" % [n, snapped, twinSnap])
	if shown != "":
		print("      " + shown)


func _prop(plays: Array) -> void:
	var n: int = 0
	var broke: int = 0
	var stopOk: int = 0
	var gone: int = 0
	var short: int = 0
	var over: int = 0
	var shown: String = ""
	for p in plays:
		var r: Dictionary = p.r
		var e: Array = r.log.filter(func(x): return x.k == "prop")
		if e.is_empty() and SimWrap.sdx(float(r.ctrlX), float(r.hook.propX)) * float(p.sg) > WorldContact.PROP_STOP:
			short += 1   # his journey ended before the prop: nothing to break (the planner's reach, not the hook)
			continue
		if e.is_empty() and r.log.any(func(x): return x.k == "prop_over"):
			over += 1   # he passed over its top: it stands (the planner's line test, not the hook)
			continue
		n += 1
		if e.size() != 1:
			continue
		broke += 1
		var d: float = absf(SimWrap.sdx(float(e[0].x), float(r.ctrlX)))
		if absf(SimWrap.sdx(float(e[0].x), float(e[0].stopX))) <= WorldContact.PROP_STOP + 1.0e-6 and d <= 2.0 * WorldContact.PROP_STOP + SimConst.COL:
			stopOk += 1
		if r.after == r.raw - 1 and (r.broken as PackedInt32Array).has(int(e[0].col)):
			gone += 1
		if shown == "":
			shown = "planet %d: a %s at x %.0f broke at speed %.0f (%s); he stopped at %.0f and came to rest at %.0f, %.1f damage; the ring's props %d, after %d" % [
				int(p.sp[0]), String(e[0].kind), float(e[0].x), float(e[0].speed), "in the air" if e[0].air else "on the ground", float(e[0].stopX), float(r.ctrlX), float(e[0].dmg), int(r.raw), int(r.after)]
	ok(n > 0 and broke == n and stopOk == n and gone == n, "prop: PROP SMASH in %d launches that reached the prop broke it %d times, he stopped at it %d times, and the prop query left it out after %d times (%d more stopped short of the prop and %d passed over its top: NEEDS FROM EP)" % [n, broke, stopOk, gone, short, over])
	if shown != "":
		print("      " + shown)


func _skid(plays: Array) -> void:
	var n: int = 0
	var handed: int = 0
	var sooner: int = 0
	var wet: int = 0
	var shown: String = ""
	for p in plays:
		var r: Dictionary = p.r
		var tw: Dictionary = _twin("ICE SKID", p, _clearKind)
		if r.skate <= 0.0 and not tw.is_empty() and tw.end == r.end:
			wet += 1   # the ice ran out first (a lead, the floe's edge) or he tumbled: no rock stop came before the real end
			continue
		n += 1
		if r.skate > 0.0:
			handed += 1
		if not tw.is_empty() and tw.end > r.end and r.skate > 0.0:
			sooner += 1
		if shown == "" and r.skate > 0.0 and not tw.is_empty():
			shown = "planet %d at x %.0f: control back after %d ticks at the rock stop (%.0f from the launch), the skate goes %.0f further on the ice; the twin holds him %d ticks" % [
				int(p.sp[0]), float(p.sp[2]), int(r.end), float(r.travel), float(r.skateD), int(tw.end)]
	ok(n > 0 and handed == n and sooner == n, "skid: ICE SKID in %d launches whose rock stop came first handed control back there with speed to skate %d times, and the twin held him longer %d times (in %d more the journey ended before any rock stop, the same with and without the hook)" % [n, handed, sooner, wet])
	if shown != "":
		print("      " + shown)


func _off(plays: Dictionary) -> void:
	DirLaunch.forceBiome = 0
	var n: int = 0
	var quiet: int = 0
	for nm in NAMES:
		for p in plays[nm]:
			if (p.r.plan as Dictionary).is_empty():
				continue   # the launch beat's: its plan is not handed out
			var r: Dictionary = _play(nm, p.sp, p.sg, p.pre, false, null, p.r.plan)
			if r.is_empty():
				continue
			n += 1
			if r.hook.is_empty() and r.log.is_empty():
				quiet += 1
	DirLaunch.forceBiome = 1
	ok(n > 0 and quiet == n, "off: with the switch off the same %d plans launch with no record and no hook plays (%d)" % [n, quiet])


func _repeat() -> void:
	for intro in [false, true]:
		var same: bool = true
		var n: int = 0
		var played: Dictionary = {}
		for m in range(8):
			var setup: Dictionary = _setup(int(SEEDS[m]), m % 2)
			if intro:
				setup["intro"] = {"play": true}
			var runs: Array = []
			for rep in range(2):
				var S := SimCore.createSim()
				SimCore.newMatch(S, 500 + m, {}, setup)
				WorldContact.hookLog.clear()
				var hs: Array = []
				for t in range(7200):
					SimCore.step(S)
					S.out.fx.clear()
					S.out.feed.clear()
					if t % 60 == 59:
						hs.append(str(SimHash.stateHash(S)))
					if S.game.ko != null and S.game.koT > 3.0:
						break
				hs.append(str(SimHash.stateHash(S)))
				if rep == 0:
					for e in WorldContact.hookLog:
						played[String(e.k)] = int(played.get(String(e.k), 0)) + 1
				runs.append(hs)
				SimCore.dispose(S)
			same = same and runs[0] == runs[1]
			n += runs[0].size()
		var parts: PackedStringArray = []
		for k in played:
			parts.append("%s %d" % [k, int(played[k])])
		ok(same, "repeat%s: the switch on, 8 gen 2 AI matches run twice: %d state hashes, all the same; hooks played in them: %s" % [
			(" with the intro" if intro else ""), n, ", ".join(parts) if not parts.is_empty() else "none"])
