class_name DirCamIntent
## The camera-intent feed (docs/director/camera-intent.md; Research's docs/research/cinematic-storytelling.md,
## recommendations 1, 3, 13 and 16): the director publishes what it has decided, ahead of time, for the camera. Behind
## data/director/interrupts.json cameraIntent.enabled (false). It reads what is decided and writes cues only: no draw, no
## state, so play never moves (the golden's fx digest does fold its cues, as it folds every cue).
## One cue kind, cam_intent, by the cue list's rules (n an absolute tick, dur ticks, k a count, text the item):
##   plan    a planned exchange's start; each brawl blow the director decides (at its throw); the AI's string as it
##           starts it; the clinch's tie-up. Its scalars: source the template (or brawl, string, clinch), n the last beat's
##           tick, dur the span, k the story weight. The plan itself is the cue's metadata "plan" (Object meta, so no
##           field changes and no hash reads it):
##             beats    [{n, op, kind, w, a, d}]: each beat's tick, its op, its kind (light, medium, heavy, launch,
##                      window, set, move, pulse), its weight (0 to 4), the attacker's and defender's slots
##             contacts the ticks of the beats that strike
##             pauses   [[from, to]]: each strike's hit-stop, and the breaths between beats 12 ticks or more apart
##             noCut    [[from, to]]: runs of strikes under 12 ticks apart (a multi-hit string), a beam's fire to its
##                      impact, the clinch
##             launch   {n} when a launch is planned (its vector comes with the send)
##             set      true for a set piece (a launch, a finisher, a beam, a clash)
##             story    {w, tags}: first_blood, reversal, decisive, finisher, comeback, crippling
##   launch  the send, from the plan: source the candidate, k its kind, ux and uy its direction, x the predicted
##           touchdown, n its tick, amount the travel, dur the flight, y 1 in water; metadata "launch" adds rest (the
##           predicted point he comes to rest)
##   read    a perfect block marked at the guard press: n the contact it turns, actor the blocker

const WEIGHT: Dictionary = {"strike": 1, "chainStrike": 1, "window": 0, "dodge": 1, "slip": 1, "stagger": 3, "rush": 1,
	"launch": 4, "knockBack": 4, "guardBreak": 4, "clashResolve": 4, "clashWave": 4, "beamFire": 4, "beamImpact": 4}
const KIND: Dictionary = {"strike": "light", "chainStrike": "light", "window": "window", "dodge": "move", "slip": "move",
	"rush": "move", "stagger": "heavy", "launch": "launch", "knockBack": "launch", "guardBreak": "set",
	"clashResolve": "set", "clashWave": "set", "beamFire": "set", "beamImpact": "set"}
const DECISIVE: Array = ["launch", "knockBack", "guardBreak", "clashResolve", "beamFire", "beamImpact"]
const STRIKES: Array = ["strike", "chainStrike", "launch", "knockBack", "guardBreak", "beamImpact"]
const RUN_GAP: int = 12   # ticks: beats closer than this are one burst (no cut), farther ones leave a breath


static func on() -> bool:
	return bool(DirInterrupt.data().get("cameraIntent", {}).get("enabled", false))


static func _cue(S: SimState, f, o, text: String, source: String = ""):
	SimFx.cue(S, f, "cam_intent", text, source)
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(o)) if o != null else -1.0
	return e


## The S.tick a beat at exchange time t is due on (a hit-stop may move it by its ticks).
static func tickOf(S: SimState, ex, t: float) -> int:
	return S.tick + int(round((t - ex.t) * DirData.TICKS_PER_SEC))


static func _slot(S: SimState, f) -> int:
	return S.fighters.find(f)


## The story the beat tells (Research's rec 16: spend by story weight). a attacks, d defends; fav the side the plan
## favours (a, d or null); big: the plan has a launch, a heavy or a set piece.
static func _story(S: SimState, ex, a, d, fav, big: bool, finisher: bool) -> Dictionary:
	var tags: Array = []
	var fresh: bool = true
	for f in S.fighters:
		if float(f.hp) < float(f.maxhp):
			fresh = false
	if fresh:
		tags.append("first_blood")
	var tpl: String = String(ex.tpl) if ex != null else ""
	if tpl.contains("riposte") or tpl.contains("counter") or fav == d:
		tags.append("reversal")
	if big or a.brink or d.brink:
		tags.append("decisive")
	if finisher:
		tags.append("finisher")
	if fav != null:
		var other = d if fav == a else a
		if float(fav.hp) / maxf(1.0, float(fav.maxhp)) + 0.2 <= float(other.hp) / maxf(1.0, float(other.maxhp)):
			tags.append("comeback")
	var loser = null if fav == null else (d if fav == a else a)
	if loser != null and big:
		for r in [SimWounds.HEAD, SimWounds.CORE, SimWounds.ARMS, SimWounds.LEGS]:
			if SimWounds.battered(loser, r):
				tags.append("crippling")
				break
	return {"w": 5 if finisher else mini(5, tags.size()), "tags": tags}


## Pauses and do-not-cut spans from a list of beats (sorted by n): a strike's hit-stop is a pause, a gap of RUN_GAP or
## more between beats a breath, and a run of strikes closer than RUN_GAP one span not to cut.
static func _spans(beats: Array, stops: Dictionary) -> Array:
	var pauses: Array = []
	var noCut: Array = []
	var runStart: int = -1
	var runEnd: int = -1
	var prev: int = -1
	for b in beats:
		var n: int = int(b.n)
		if stops.has(n) and int(stops[n]) > 0:
			pauses.append([n, n + int(stops[n])])
		if prev >= 0 and n - prev >= RUN_GAP:
			pauses.append([prev + 1, n - 1])
		if STRIKES.has(String(b.op)) or String(b.op) == "pulse":
			if runStart >= 0 and n - runEnd < RUN_GAP:
				runEnd = n
			else:
				if runStart >= 0 and runEnd > runStart:
					noCut.append([runStart - 4, runEnd + 4])
				runStart = n
				runEnd = n
		prev = n
	if runStart >= 0 and runEnd > runStart:
		noCut.append([runStart - 4, runEnd + 4])
	return [pauses, noCut]


static func _send(S: SimState, a, d, src: String, plan: Dictionary) -> void:
	var e = _cue(S, a, d, "plan", src)
	var last: int = S.tick
	for b in plan.beats:
		last = maxi(last, int(b.n))
	e.n = last
	e.dur = float(last - S.tick)
	e.k = float(int(plan.story.w))
	e.set_meta("plan", plan)


## A planned exchange has its beats (DirExchange._start, after the alchemist dressed them).
static func exchange(S: SimState, ex) -> void:
	if not on() or ex == null:
		return
	var beats: Array = []
	var stops: Dictionary = {}
	var contacts: Array = []
	var launchAt: int = -1
	var big: bool = false
	var beam: Array = [-1, -1]
	var raw: Array = []
	for b in ex.beats:
		if not b.done and WEIGHT.has(b.op):
			raw.append(b)
	raw.sort_custom(func(x, y): return float(x.t) < float(y.t))
	var held: int = 0   # the hit-stops of the strikes before: they hold the exchange's clock while the ticks run on
	for b in raw:
		var n: int = tickOf(S, ex, b.t) + held
		var w: int = int(WEIGHT[b.op])
		var kind: String = String(KIND[b.op])
		var o2 = b.args.get("o") if b.args is Dictionary else null
		if (b.op == "strike" or b.op == "chainStrike") and o2 is Dictionary:
			var cls: String = String(o2.get("class", ""))
			if cls == "heavy" or cls == "ender" or bool(o2.get("big", false)):
				w = 3
				kind = "heavy"
			stops[n] = int(round(float(o2.get("stop", 0.0)) * DirData.TICKS_PER_SEC))
			held += int(stops[n])
		if DECISIVE.has(b.op):
			big = true
		if b.op == "launch" or b.op == "knockBack":
			launchAt = n
		if b.op == "beamFire":
			beam[0] = n
		if b.op == "beamImpact":
			beam[1] = n
		if STRIKES.has(b.op):
			contacts.append(n)
		var aa = b.args.get("a", "A") if b.args is Dictionary else "A"
		var att = ex.A if String(aa) == "A" else ex.D
		var dfn = ex.D if att == ex.A else ex.A
		beats.append({"n": n, "op": String(b.op), "kind": kind, "w": w, "a": _slot(S, att), "d": _slot(S, dfn)})
	if beats.is_empty():
		return
	beats.sort_custom(func(x, y): return int(x.n) < int(y.n))
	var sp: Array = _spans(beats, stops)
	if beam[0] >= 0 and beam[1] > beam[0]:
		sp[1].append([beam[0], beam[1]])
	var fav = null
	if int(ex.loser) >= 0:
		fav = ex.D if S.fighters[int(ex.loser)] == ex.A else ex.A
	var fin: bool = String(ex.tag) == "FINISHER" or String(ex.tpl).begins_with("finisher")
	var plan := {"ex": int(S.dirS.exN), "tpl": String(ex.tpl), "a": _slot(S, ex.A), "d": _slot(S, ex.D), "at": S.tick,
		"beats": beats, "contacts": contacts, "pauses": sp[0], "noCut": sp[1],
		"launch": ({"n": launchAt} if launchAt >= 0 else {}), "set": big or fin, "beam": beam[0] >= 0,
		"story": _story(S, ex, ex.A, ex.D, fav, big, fin)}
	_send(S, ex.A, ex.D, String(ex.tpl), plan)


## A brawl's blow is thrown (DirBrawl._throw): its contact, its weight and what it means are known now.
static func blow(S: SimState, f, o, args: Dictionary, contact: int) -> void:
	if not on():
		return
	var lau: bool = bool(args.get("launcher", false))
	var kind: String = "launch" if lau else String(args.get("strength", "light"))
	var w: int = 4 if lau else (3 if kind == "heavy" else (2 if kind == "medium" else 1))
	var o2 = args.get("o")
	var stop: int = int(round(float(o2.get("stop", 0.0)) * DirData.TICKS_PER_SEC)) if o2 is Dictionary else 0
	var closing: bool = bool(args.get("closing", false))
	var beats: Array = [{"n": contact, "op": "strike", "kind": kind, "w": w, "a": _slot(S, f), "d": _slot(S, o)}]
	var plan := {"ex": int(S.dirS.exN), "tpl": "brawl", "a": _slot(S, f), "d": _slot(S, o), "at": S.tick,
		"beats": beats, "contacts": [contact], "pauses": ([[contact, contact + stop]] if stop > 0 else []), "noCut": [],
		"launch": ({"n": contact, "safety": int(args.get("safety", 1)), "aim": int(args.get("aim", 0))} if lau else {}),
		"set": lau, "beam": false,
		"story": _story(S, S.dirS.ex, f, o, f if (lau or closing) else null, lau or closing or kind == "heavy", false)}
	_send(S, f, o, "brawl", plan)


## The AI starts a string (DirBrawl.aiInput): its presses are drawn now, `presses` of them `gap` ticks apart, each
## landing `lead` ticks after its press. One plan, one span not to cut.
static func aiString(S: SimState, f, o, presses: int, gap: int, lead: int) -> void:
	if not on() or presses <= 1 or gap <= 0:
		return
	var beats: Array = []
	var contacts: Array = []
	for k in range(presses):
		var n: int = S.tick + k * gap + lead
		beats.append({"n": n, "op": "strike", "kind": "light", "w": 1, "a": _slot(S, f), "d": _slot(S, o)})
		contacts.append(n)
	var plan := {"ex": int(S.dirS.exN), "tpl": "string", "a": _slot(S, f), "d": _slot(S, o), "at": S.tick,
		"beats": beats, "contacts": contacts, "pauses": [], "noCut": [[S.tick, int(contacts[contacts.size() - 1]) + 4]],
		"launch": {}, "set": false, "beam": false, "story": _story(S, S.dirS.ex, f, o, null, false, false)}
	_send(S, f, o, "string", plan)


## The brawl's double hit is on its way (DirBrawl._double).
static func doubleHit(S: SimState, ex, contact: int) -> void:
	if not on():
		return
	var beats: Array = [{"n": contact, "op": "strike", "kind": "heavy", "w": 3, "a": _slot(S, ex.A), "d": _slot(S, ex.D)},
		{"n": contact, "op": "strike", "kind": "heavy", "w": 3, "a": _slot(S, ex.D), "d": _slot(S, ex.A)}]
	var plan := {"ex": int(S.dirS.exN), "tpl": "double", "a": _slot(S, ex.A), "d": _slot(S, ex.D), "at": S.tick,
		"beats": beats, "contacts": [contact], "pauses": [], "noCut": [[S.tick, contact + 4]], "launch": {}, "set": true,
		"beam": false, "story": {"w": 2, "tags": ["decisive", "clash"]}}
	_send(S, ex.A, ex.D, "double", plan)


## The send, from the plan (DirMelee.launchBeat, before doLaunch).
static func launch(S: SimState, att, tgt, best: Dictionary) -> void:
	if not on():
		return
	var e = _cue(S, att, tgt, "launch", String(best.get("name", "")))
	e.k = float(DirBrawl.kindOfSend(best))
	e.ux = float(best.get("ux", 0.0))
	e.uy = float(best.get("uy", 0.0))
	var p = best.get("p")
	var meta := {"name": String(best.get("name", "")), "kind": int(e.k), "ux": e.ux, "uy": e.uy, "building": best.has("brunt")}
	if p is Dictionary:
		var ticks: int = int(round(float(p.get("t", 0.0)) * DirData.TICKS_PER_SEC))
		e.x = float(p.get("land", p.get("x", tgt.x)))
		e.y = 1.0 if bool(p.get("water", false)) else 0.0
		e.amount = float(p.get("travel", 0.0))
		e.dur = float(ticks)
		e.n = S.tick + ticks
		meta["land"] = {"x": e.x, "n": int(e.n)}
		meta["rest"] = {"x": float(p.get("x", tgt.x))}
		meta["travel"] = e.amount
		meta["water"] = bool(p.get("water", false))
	e.set_meta("launch", meta)


## A perfect block is marked at the guard press (DirInterrupt.guardPress).
static func read(S: SimState, d, ex, b) -> void:
	if not on() or ex == null or b == null:
		return
	var a = ex.A if d == ex.D else ex.D
	var e = _cue(S, d, a, "read", String(b.op))
	e.n = tickOf(S, ex, b.t)


## The clinch's tie-up (DirGrapple._tieUp): its pulses, and its span not to cut.
static func clinch(S: SimState, f, o, t0: int, most: int, pulse: int) -> void:
	if not on():
		return
	var beats: Array = []
	for k in range(1, most / maxi(1, pulse) + 1):
		beats.append({"n": t0 + k * pulse, "op": "pulse", "kind": "pulse", "w": 1, "a": _slot(S, f), "d": _slot(S, o)})
	var plan := {"ex": int(S.dirS.exN), "tpl": "clinch", "a": _slot(S, f), "d": _slot(S, o), "at": S.tick,
		"beats": beats, "contacts": [], "pauses": [], "noCut": [[t0, t0 + most]], "launch": {}, "set": false, "beam": false,
		"story": {"w": 1, "tags": ["grapple"]}}
	_send(S, f, o, "clinch", plan)
