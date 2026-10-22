class_name DirWindows
## No window gets shorter for a freeze (Game Design's rulings-2026-10-19b.md 4c; docs/architecture/feel-core.md §2), while
## hit-stop by weight is on (S.hitstopOn, Simulation's switch: off, nothing here runs). Called once at the end of each
## live tick of the director (DirExchange.dirUpdate): if a hit-stop starts with it, the windows open now are set so that
## none loses a live tick to the freeze, and each one at least minLiveTicks long still has that many live ticks after it.
##  - A perfect block's window on a pending strike (and on a signature's fire): the exchange's clock holds through the
##    freeze, so the window keeps its ticks; one with fewer than minLiveTicks left has its strike (and, in a planned
##    exchange, every beat after it) put back so it has them. A brawl blow's line moves with it. A brawl light's whole
##    window is its 2-tick press-to-contact, under minLiveTicks, so it keeps what it has and its flurry's beat holds.
##  - The chain window counts live time: one ending sooner than minLiveTicks after the freeze is held open to it.
##  - The brawl's windows that count every tick (the riposte after a perfect block, the launcher's late window) are put
##    back by the freeze's ticks, and to at least minLiveTicks after it.
## Each strike put back sends a "window_hold" cue (actor the striker, target the defender, n the new contact, dur the
## ticks it moved), so the render can re-time its blow.

static func cfg() -> Dictionary:
	return DirInterrupt.data().get("freezeWindows", {})


static func afterTick(S: SimState) -> void:
	if not S.hitstopOn or S.dirS.stop <= 0.0 or S.game.ko != null:
		return
	var frozen: int = SimFx.stopTicks(S.dirS.stop, true)   # the freeze that starts with the next tick, counted as the step will (whole: hitstop2)
	if frozen <= 0:
		return
	var least: int = int(cfg().get("minLiveTicks", 5))
	if least <= 0:
		return   # (minLiveTicks 0: the rule is off in data)
	for f in S.fighters:
		DirBrawl.freezeWindows(S, f, frozen, least)
	var ex = S.dirS.ex
	if ex == null:
		return
	if ex.ext != null and S.T < ex.ext.until and (ex.ext.until - S.T) * DirData.TICKS_PER_SEC < float(least) - 0.001:
		ex.ext.until = S.T + float(least) * SimConst.DT   # the chain window: minLiveTicks after the freeze
	for f in [ex.D, ex.A]:
		_strikes(S, ex, f, least)


## The pending strikes on f whose perfect-block window is open now: each with fewer than `least` live ticks left (and a
## window at least that long) is put back so it has them.
static func _strikes(S: SimState, ex, f, least: int) -> void:
	var role: String = "A" if f == ex.A else "D"
	for b in ex.beats:
		if b.done:
			continue
		var cls: String = ""
		if b.op == "beamFire" and ex.kind == "sig" and f == ex.D:
			cls = "beam"
		elif b.op == "strike" and b.args != null and String(b.args.get("d", "")) == role and b.args.get("o") is Dictionary and not b.args.get("sure", false):
			cls = String(b.args.o.get("class", ""))
		if cls == "" or cls == "blow":
			continue   # no window, or a brawl light (its window is its own 2 ticks)
		var w: float = DirInterrupt._window(f, cls, ex.kind == "heavy")
		if w < float(least):
			continue
		var left: float = (b.t - ex.t) * DirData.TICKS_PER_SEC
		if left > w + 0.5 or left >= float(least) - 0.001:
			continue   # not open yet (it opens after the freeze, whole), or it has its ticks
		var d: int = int(ceil(float(least) - left - 0.001))
		var by: float = float(d) / DirData.TICKS_PER_SEC
		var at: float = b.t
		if DirBrawl.isBrawl(ex) and b.args.get("brawl", false):
			b.t += by   # a brawl blow is its own line: only it moves, and its line with it
			DirBrawl.holdBlow(S, ex.A if String(b.args.get("a", "A")) == "A" else ex.D, d)
		else:
			for x in ex.beats:
				if not x.done and x.t >= at:
					x.t += by   # a planned exchange keeps its rhythm: everything from the strike on moves together
		var striker = ex.A if (b.op == "beamFire" or String(b.args.get("a", "A")) == "A") else ex.D
		SimFx.cue(S, striker, "window_hold", cls, "")
		var e = S.out.fx[S.out.fx.size() - 1]
		e.target = float(S.fighters.find(f))
		e.n = S.tick + SimFx.stopTicks(S.dirS.stop, true) + int(round((b.t - ex.t) * DirData.TICKS_PER_SEC))
		e.dur = float(d)
		if not DirBrawl.isBrawl(ex):
			return   # the beats after it moved with it
