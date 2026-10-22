class_name DirCalm
## The calm-moment turn, the director's part (docs/director/calm-turn.md; Game Design's rulings-2026-10-19b.md section 1
## with 1e; World's WorldEpoch, docs/world/calm-turn-world.md). Behind data/director/interrupts.json calmTurn.enabled
## (false) and World's own switch (rings.json turn.on, or setup.arena.turn): with either off nothing here runs.
##  - The ask (World's loader needs it early): at a launch's send the director knows where it lands, so it asks World
##    for the candidate turns then (WorldEpoch.ask), pivoting on the predicted landing, on the side the fight was
##    pushed (the send's direction), and picks one at once (WorldEpoch.choose) by what each brings into view.
##  - The hold (WorldEpoch.tick's second argument, each live tick): true while the moment after a landing holds. A
##    fighter came to rest from a send within landedTicks, both are down or set (under setSpeed), and the director's own
##    part of calm is met: no exchange, approach, taunt, zip, catch or clinch, no recoil flip or counter-rush, no attack
##    waiting in either queue, no finisher. World adds its own check (nothing in flight) and swaps.
##  - The warm-up (Rendering's, 2026-10-22d): the host reads the picked ring at the rate the cue asks (warmRate: enough to
##    have it by the landing, from warmCols to warmColsMax columns a frame), so the swap waits the ring's columns over that
##    rate in ticks since the pick (counted in ticks, the same in any replay), and then
##    takes the moment after that landing, the sent fighter within pivotSlack of the pivot and the other within otherSlack. A new send cancels a pick
##    still waiting (World's cancel) and asks again for its own landing.
##  - The pick: each place a candidate brings into view scores by its kind (score), more for the rival's home and a
##    landmark when World has them; a tie goes to the smaller bearing. With no place, the smallest bearing.
## Stateless: it reads the match and World's epoch, and writes only through World's ask and choose.
## Not here yet: a form step's pause and a set piece's cutaway as moments (World's calm refuses an open set piece).


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("calmTurn", {})


static func on(S: SimState) -> bool:
	return bool(cfg().get("enabled", false)) and S.epoch != null


## A launch is sent (DirMelee.launchBeat, after doLaunch): the moment after its landing is coming. Ask World for the turns
## on the side it was sent, pivoting on where it lands, and pick one now, so World can read the ring while he flies.
static func atSend(S: SimState, att, tgt, best: Dictionary) -> void:
	if not on(S) or tgt.launchSpecial or String(best.get("name", "")) == "KNOCK BACK":
		return
	if S.epoch.next != null:
		var cn := Callable(WorldEpoch, "cancel")
		if not cn.is_valid():
			return
		cn.call(S)   # a new send: its landing is the moment now, so a pick still waiting gives way to it
	var p = best.get("p")
	var land: float = float(p.get("x", tgt.x)) if p is Dictionary else tgt.x   # where he comes to rest (the planner's estimate, his slide in it): the moment is there
	var mid: float = SimWrap.wrap(land + 0.5 * SimWrap.sdx(land, att.x))   # the pair's midpoint at the landing: the attacker where he stands
	var ux: float = float(best.get("ux", 0.0))   # the send's way along the ring: the side the fight was pushed
	var side: int = (1 if ux > 0.0 else -1) if ux != 0.0 else (1 if SimWrap.sdx(att.x, tgt.x) >= 0.0 else -1)
	var due: int = S.tick + int(round(float(p.get("t", 1.0)) * DirData.TICKS_PER_SEC)) if p is Dictionary else S.tick
	var cands: Array = WorldEpoch.ask(S, "landed", mid, side, due)
	if cands.is_empty():
		return
	var i: int = pick(S, cands, att)
	WorldEpoch.choose(S, i)
	SimFx.cue(S, att, "calm_turn", "asked", "landed")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(tgt))
	e.n = due
	e.x = mid
	e.amount = float(cands[i].bearing)
	e.k = float(warmRate(S)) if S.epoch.next != null else 0.0   # the host warms the ring this many columns a frame


## World's candidates on a side: the index of the one whose places score most (a tie: the smaller bearing).
static func pick(S: SimState, cands: Array, by) -> int:
	var sc: Dictionary = cfg().get("score", {})
	var best: int = 0
	var bestS: float = -INF
	for k in range(cands.size()):
		var s: float = 0.0
		for pl in cands[k].places:
			var kind: String = String(pl.get("kind", ""))
			var owner: int = int(pl.get("owner", -1))
			if owner >= 0 and owner != S.fighters.find(by):
				s += float(sc.get("rivalHome", 5.0))
			elif owner >= 0:
				s += float(sc.get("ownHome", 2.0))
			else:
				s += float(sc.get(kind, 0.0))
		if s > bestS + 0.0001 or (absf(s - bestS) <= 0.0001 and absf(float(cands[k].bearing)) < absf(float(cands[best].bearing))):
			bestS = s
			best = k
	return best


## The fighters are near the waiting pick's pivot: the one who came to rest last (the sent one) within pivotSlack, where
## World keeps the ground exactly as it was; the other within otherSlack, inside World's carry zone, where it fades.
static func _nearPivot(S: SimState) -> bool:
	var pv: float = float(int(S.epoch.next.pc)) * SimConst.COL
	var sent = null
	for f in S.fighters:
		if f.state == "down" or DirBrawl.returning(S, f):
			if sent == null or f.stateT < sent.stateT:
				sent = f
	for f in S.fighters:
		var sl: float = float(cfg().get("pivotSlack", 3000.0)) if (f == sent or sent == null) else float(cfg().get("otherSlack", 12000.0))
		if absf(SimWrap.sdx(f.x, pv)) > sl:
			return false
	return true


## The rate the host is asked to warm the picked ring at (columns a frame): enough to have it read by the moment the pick
## was for (its due tick, World keeps it), at least warmCols and at most warmColsMax. The calm_turn cue carries it.
static func warmRate(S: SimState) -> int:
	var nx: Dictionary = S.epoch.next
	var cols: int = int(nx.spec.get("cols", SimConst.NC)) if nx.get("spec") is Dictionary else SimConst.NC
	var lead: int = maxi(1, int(nx.get("due", nx.get("tick", S.tick))) - int(nx.get("tick", S.tick)))
	return clampi(int(ceil(float(cols) / float(lead))), int(cfg().get("warmCols", 16)), int(cfg().get("warmColsMax", 64)))


## The ticks the host needs to warm the picked ring at that rate (one frame a tick).
static func warmTicks(S: SimState) -> int:
	var nx: Dictionary = S.epoch.next
	var cols: int = int(nx.spec.get("cols", SimConst.NC)) if nx.get("spec") is Dictionary else SimConst.NC
	return int(ceil(float(cols) / float(warmRate(S))))


## WorldEpoch.tick's hold, each live tick: the moment after a landing, and the director's part of calm.
static func hold(S: SimState) -> bool:
	return why(S) == ""


## Why the hold is off now ("" when it holds): for the hold, and for the probes.
static func why(S: SimState) -> String:
	if not on(S) or S.epoch.next == null or S.game.ko != null:
		return "none"
	if S.tick - int(S.epoch.next.get("tick", S.tick)) < warmTicks(S):
		return "warming"
	if not _nearPivot(S):
		return "off pivot"
	if S.dirS.ex != null:
		return "exchange"
	if DirBands.who(S) >= 0:
		return "approach"
	if S.game.clash != null:
		return "beam clash"
	var c: Dictionary = cfg()
	var settle: float = float(c.get("landedTicks", 30)) * SimConst.DT
	var setV: float = float(c.get("setSpeed", 60.0))
	var landed: bool = false
	for f in S.fighters:
		if DirBands.taunting(f) or DirRecoil.flipping(S, f) or DirRecoil.due(S, f):
			return "taunt or flip"
		if not SimAct.peek(f).is_empty():
			return "queued"   # an attack waiting: a turn never swallows a press
		if f.brink and f.brinkOpen:
			return "brink"   # a finisher may start
		var down: bool = f.state == "down"
		var set: bool = f.state == "free" and f.rush == null and SimDetMath.hypot(f.vx, f.vy) < setV
		if not (down or set):
			return "moving"
		if f.stateT <= settle and (down or DirBrawl.returning(S, f)):
			landed = true   # he came to rest from a send within the settle
	return "" if landed else "no landing"
