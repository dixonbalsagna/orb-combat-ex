extends SceneTree
# A refused dig still buries (World, GW1c; docs/world/pending/globe-step2/bury-refused.md). From the repo root:
#   godot --headless --path . --script res://sim/world/tools/bury_check.gd -- [--negative-control]
# The shaft cap (globe-step2) refuses a dig on ground already as dented as the blow can dig. A refused dig returns no crater, and the contact buries a fighter only against a crater it dug, so a hard slam onto an old
# crater did not bury (vision.md: a hard impact buries). Proves, on the world players get (the data as shipped, planet 7, generation 3): a refusal leaves no record and no crater event and sends crater_refused (x, y, z, r,
# depth, energy, cause); a blow too weak to dig on fresh ground sends nothing; a slam that buries on fresh ground buries on an old crater of its own size and on a bigger one (it sends crater_refused and embed, digs no
# crater, and still plays its ring and debris); a slam too soft to bury on fresh ground does not bury on an old crater either; the same run twice is the same state. --negative-control is the stack before the fix
# (WorldContact.buryRefused false): the burying rows must then fail.
var fails: int = 0
var negative: bool = false
const FIELD: Dictionary = {"intro": false, "planet": 7, "touch": 1, "planetGen": 3}
const E_HARD: float = 20.6   # the energy of a tier 3 slam at speed 4000 here: its crater is 725 across the radius and 159 deep, deep enough to bury (a body is 75)


func ok(c: bool, what: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", what])
	if not c:
		fails += 1


func _mk() -> SimState:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, FIELD)
	for t in range(5):
		SimCore.step(S)
	return S


## The second fighter thrown down onto x at speed `spd`, 90 ticks: what the events say, whether he was buried, how many craters there are.
func _slam(S: SimState, x: float, spd: float) -> Dictionary:
	var a = S.fighters[0]
	var tg = S.fighters[1]
	a.x = SimWrap.wrap(x - 110.0)
	a.y = WorldTerrain.groundY(S, a.x) + 10.0
	a.vx = 0.0
	a.vy = 0.0
	a.tier = 3.0
	tg.x = SimWrap.wrap(x)
	tg.y = WorldTerrain.groundY(S, tg.x) + 300.0
	tg.vx = 0.0
	tg.vy = 0.0
	tg.tier = 3.0
	var n0: int = S.out.fx.size()
	DirLaunch.doLaunch(S, a, tg, {"ux": 0.0, "uy": -1.0, "name": "SLAM DOWN"}, spd, false)
	var embedT: float = 0.0
	for t in range(90):
		SimCore.step(S)
		embedT = maxf(embedT, float(tg.embedT))
	var cnt: Dictionary = {}
	var ev: Dictionary = {}
	for i in range(n0, S.out.fx.size()):
		var e = S.out.fx[i]
		cnt[e.type] = int(cnt.get(e.type, 0)) + 1
		if e.type == "crater_refused" or e.type == "embed" or e.type == "crater":
			ev[e.type] = e
	return {"cnt": cnt, "ev": ev, "embedT": embedT, "craters": S.craters.size(), "hash": str(SimHash.stateHash(S).gameplay)}


func _n(d: Dictionary, k: String) -> int:
	return int(d.cnt.get(k, 0))


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	WorldContact.buryRefused = not negative
	print("a refused dig")
	var S := _mk()
	var x: float = S.fighters[0].x + 900.0
	var r1 = WorldCrater.dig(S, x, E_HARD, S.fighters[0], "impact")
	ok(r1 != null and WorldCrater.refusal.is_empty() and WorldCrater.refusalBowl(S) == null, "a blow on fresh ground digs a crater (%s) and leaves no refusal" % ("depth %d, r %d" % [int(r1.depth), int(r1.r)] if r1 != null else "none"))
	var recs: int = S.craters.size()
	var store: int = WorldStore.count(S)
	var n0: int = S.out.fx.size()
	var r2 = WorldCrater.dig(S, x, E_HARD, S.fighters[0], "impact")
	var evs: Array = []
	for i in range(n0, S.out.fx.size()):
		evs.append(S.out.fx[i])
	var refused: Array = evs.filter(func(e): return e.type == "crater_refused")
	ok(r2 == null and S.craters.size() == recs and WorldStore.count(S) == store, "the same blow on the same spot is refused (no crater, no record: %d craters, %d store records, as before)" % [S.craters.size(), WorldStore.count(S)])
	ok(refused.size() == 1 and evs.size() == 1, "... and sends one crater_refused and nothing else (%d events)" % evs.size())
	var ev = refused[0] if refused.size() > 0 else null
	ok(ev != null and absf(float(ev.x) - SimWrap.wrap(x)) < 1.0e-6 and absf(float(ev.r) - float(r1.r)) < 1.0e-6 and absf(float(ev.energy) - E_HARD) < 1.0e-9 and float(ev.depth) > 0.0 and str(ev.cause) == "impact", "... its fields: x the spot, r the blow's radius (%d), energy %.1f, depth the dent there (%d), cause impact" % [int(ev.r) if ev != null else -1, E_HARD, int(ev.depth) if ev != null else -1])
	var b = WorldCrater.refusalBowl(S)
	ok(b != null and b.depth > 0.0 and b.depth <= float(WorldCrater.refusal.depth) and b.depth <= float(WorldCrater.refusal.dig) and absf((b.y - b.depth) - WorldTerrain.groundY(S, x)) < 1.0e-6, "the bowl it buries against is the dent that is there, never deeper than the blow would dig on fresh ground (depth %d of the dent %d), its floor the ground as it stands" % [int(b.depth) if b != null else -1, int(WorldCrater.refusal.depth)])
	var T := _mk()
	var n1: int = T.out.fx.size()
	var r3 = WorldCrater.dig(T, x, 0.01, T.fighters[0], "impact")
	ok(r3 == null and WorldCrater.refusal.is_empty() and T.out.fx.size() == n1, "a blow too weak to dig on fresh ground is not a refusal: no crater_refused, no bowl to bury against")
	print("a slam onto ground that is already dented")
	var F := _mk()
	var fresh: Dictionary = _slam(F, x, 4000.0)
	ok(_n(fresh, "crater") == 1 and _n(fresh, "embed") == 1 and fresh.embedT > 0.0, "control: a slam at speed 4000 on fresh ground digs a crater and buries him (embedT %.0f)" % fresh.embedT)
	var A := _mk()
	WorldCrater.dig(A, x, E_HARD, A.fighters[0], "impact")
	var same: Dictionary = _slam(A, x, 4000.0)
	ok(_n(same, "crater_refused") == 1 and _n(same, "crater") == 0 and same.craters == 1, "the same slam on an old crater of its own size is refused: crater_refused, no crater, still the one crater")
	ok(_n(same, "embed") == 1 and same.embedT > 0.0, "... and he is still buried (an embed event, embedT %.0f)" % same.embedT)
	ok(same.ev.has("embed") and float(same.ev.embed.depth) > 0.0 and float(same.ev.embed.depth) <= float(fresh.ev.embed.depth) + 1.0e-6, "... against the bowl that is there, no deeper than a fresh blow's (embed depth %d, fresh %d)" % [int(same.ev.embed.depth) if same.ev.has("embed") else -1, int(fresh.ev.embed.depth)])
	ok(_n(same, "ring") > 0 and _n(same, "debris") > 0, "... and the impact still plays its ring and debris (%d rings, %d debris)" % [_n(same, "ring"), _n(same, "debris")])
	var B := _mk()
	WorldCrater.dig(B, x, 45.2, B.fighters[0], "impact")
	var bigger: Dictionary = _slam(B, x, 4000.0)
	ok(_n(bigger, "crater_refused") == 1 and _n(bigger, "embed") == 1 and bigger.embedT > 0.0, "the same slam on an old crater bigger than it is refused and buries him too")
	var E2 := _mk()
	WorldCrater.dig(E2, x, 9.1, E2.fighters[0], "impact")
	var smaller: Dictionary = _slam(E2, x, 4000.0)
	ok(_n(smaller, "crater") == 1 and _n(smaller, "crater_refused") == 0 and _n(smaller, "embed") == 1 and smaller.embedT > 0.0, "a hard slam on a smaller old crater digs what the cap leaves it (%d deep, a fresh one digs %d) and buries him: the bowl he sits in is the whole dent" % [int(smaller.ev.crater.depth), int(fresh.ev.crater.depth)])
	var C := _mk()
	var soft_fresh: Dictionary = _slam(C, x, 2600.0)
	ok(_n(soft_fresh, "crater") == 1 and _n(soft_fresh, "embed") == 0, "control: a slam at speed 2600 digs a crater on fresh ground and is too soft to bury him (depth %d)" % int(soft_fresh.ev.crater.depth))
	var D := _mk()
	WorldCrater.dig(D, x, 45.2, D.fighters[0], "impact")
	var soft: Dictionary = _slam(D, x, 2600.0)
	ok(_n(soft, "embed") == 0 and soft.embedT == 0.0 and _n(soft, "crater") + _n(soft, "crater_refused") == 1, "the same soft slam on a deep old crater (a %s) does not bury him either: the old dent's depth does not make a soft blow hard" % ("refusal" if _n(soft, "crater_refused") == 1 else "crater only %d deep" % int(soft.ev.crater.depth)))
	var A2 := _mk()
	WorldCrater.dig(A2, x, E_HARD, A2.fighters[0], "impact")
	var same2: Dictionary = _slam(A2, x, 4000.0)
	ok(same2.hash == same.hash and _n(same2, "embed") == _n(same, "embed"), "the same run twice is the same state (hash %s)" % same.hash.substr(0, 12))
	WorldContact.buryRefused = true
	print("BURY: %d check(s) failed%s" % [fails, " (negative control)" if negative else ""])
	quit(0)
