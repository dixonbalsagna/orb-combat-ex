extends SceneTree
## Probe: the wall kick, the switch on in memory.
##  --mode=forced: slot 0 (a player) is sent by slot 1 into a city building's face at forces from low to high, until a
##    send meets a face that holds (building_hit "wall") at 1,500 or more into it. That send is played twice from the same
##    start: without a tap, and with a dodge tap 3 ticks out. Each: the outcome, his damage, his stun after, the wall_kick
##    cue, the journey's end, and where he is 30 ticks later against the rival.
##  --mode=ai: AI v AI, both starting in the city: wall slams, wall kicks (rush, push), by the fighter sent; minutes.
## -- <matches> <seed0> [--mode=forced|ai] [--ticks=10800]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var mode := "forced"
	var ticks := 10800
	for s in args:
		if s.begins_with("--mode="):
			mode = s.substr(7)
		elif s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	DirInterrupt.data()["wallKick"]["enabled"] = true
	var r := {"mode": mode, "on": DirWallKick.on()}
	if mode == "forced":
		r["found"] = null
		for bi in range(200):
			for force in [900.0, 1300.0, 1800.0, 2400.0, 3200.0]:
				var a := _send(seed0, bi, force, false)
				if a.is_empty() or String(a.get("outcome", "")) != "wall" or float(a.get("into", 0.0)) < 1500.0:
					continue
				r.found = {"building": bi, "force": force}
				r["noTap"] = a
				r["noTapPress"] = _send(seed0, bi, force, false, 0.0, 0.0, 12)
				r["tapNeutral"] = _send(seed0, bi, force, true)
				r["tapNeutralPress"] = _send(seed0, bi, force, true, 0.0, 0.0, 12)
				r["tapTowardPress"] = _send(seed0, bi, force, true, -1.0, 0.0, 4)
				r["tapUp"] = _send(seed0, bi, force, true, 0.0, 1.0)
				r["tapUpPress"] = _send(seed0, bi, force, true, 0.0, 1.0, 12)
				r["tapLatePress"] = _send(seed0, bi, force, true, 0.0, 0.0, 26)
				break
			if r.found != null:
				break
	else:
		r["matches"] = n
		r["walls"] = [0, 0]
		r["kicks"] = {"rush": [0, 0], "push": [0, 0]}
		r["rushBlows"] = [0, 0]
		r["minutes"] = 0.0
		for m in range(n):
			var S := SimCore.createSim()
			SimCore.newMatch(S, seed0 + m, {}, {})
			var xs := []
			var x := 0.0
			while x < 153600.0:
				if WorldBiomes.biomeAt(x) == "city":
					xs.append(x)
				x += 200.0
			if xs.size() > 0:
				var x0: float = float(xs[(m * xs.size()) / maxi(1, n) % xs.size()])
				S.fighters[0].x = x0
				S.fighters[1].x = SimWrap.wrap(x0 + 300.0)
			for t in range(ticks):
				SimCore.step(S)
				for e in S.out.fx:
					var ty: String = String(e.type)
					if ty == "building_hit" and String(e.outcome) == "wall" and int(e.actor) >= 0 and int(e.actor) < 2:
						r.walls[int(e.actor)] += 1
					elif ty == "cue" and String(e.kind) == "wall_kick":
						r.kicks[String(e.text)][int(e.actor)] += 1
					elif ty == "cue" and String(e.kind) == "counter_rush" and String(e.text) == "wall_kick":
						r.rushBlows[int(e.actor)] += 1
				S.out.fx.clear()
				S.out.feed.clear()
				if S.game.ko != null:
					break
			r.minutes += S.T / 60.0
		r["minutes"] = snappedf(r.minutes, 0.1)
	print(JSON.stringify(r))
	quit()


## One send of slot 0 into building bi's near face at force, from a fixed start; tap: a dodge tap 3 ticks out; (mx, my)
## his stick from the tap on (the rival is behind him, -x); pressAt: a light pressed that many ticks after the contact
## (-1 none). Reads (5c): the ticks from the contact to his control again (free, no rush), his speed then, the first
## move locked then, the rush blow's cue, and the tick his first blow lands on the rival.
func _send(seed: int, bi: int, force: float, tap: bool, mx: float = 0.0, my: float = 0.0, pressAt: int = -1) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": true}, {"v2": [true, true]})
	for k in range(30):
		SimCore.step(S, [SimIntent.new(), null])
	S.out.fx.clear()
	S.out.feed.clear()
	var cands := []
	for b in S.buildings:
		if b.alive and WorldBiomes.biomeAt(b.x) == "city" and not WorldBrunt.isHouse(b):
			cands.append(b)
	if bi >= cands.size():
		return {}
	var b = cands[bi]
	var me = S.fighters[0]
	var it = S.fighters[1]
	S.dirS.ex = null
	for f in [me, it]:
		f.state = "free"
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
		f.stunTicks = 0
	me.x = SimWrap.wrap(b.x - b.w * 0.5 - 700.0)
	it.x = SimWrap.wrap(me.x - 150.0)
	me.y = WorldTerrain.groundY(S, me.x) + 120.0
	it.y = me.y
	var plan = WorldBrunt.aim(S, it, me, b, force, 1.0)
	if plan == null:
		return {}
	DirLaunch.doLaunch(S, it, me, plan, force)
	var hp0: float = me.hp
	var out := {"tap": tap, "stick": [mx, my], "pressAt": pressAt, "outcome": "", "into": 0.0, "kick": "", "journey": "", "dmg": 0.0, "stunAfter": 0, "gap30": 0,
		"ctlBack": -1, "speedBack": 0, "lockedBack": false, "rushBlow": false, "blowAt": -1}
	var tapped := false
	var hitAt := -1
	var live := -1   # live ticks since the contact (presses and control back are read in live ticks: a press on a frozen tick is lost)
	var pressed := false
	for k in range(200):
		var i := SimIntent.new()
		if tap and not tapped and me.state == "launched" and me.aimB == b.idx:
			var t2c: float = maxf(0.0, absf(SimWrap.sdx(me.x, b.x)) - b.w * 0.5) / maxf(1.0, absf(me.vx) * SimConst.DT)
			if t2c <= 3.0:
				i.dodge = true
				tapped = true
		if tapped or hitAt >= 0:
			i.mx = mx
			i.my = my
		if pressAt >= 0 and hitAt >= 0 and not pressed and live >= pressAt:
			pressed = true
			i.light = true
		var vx: float = me.vx / me.launchT
		var t0: float = S.T
		SimCore.step(S, [i, null])
		if hitAt >= 0 and S.T != t0:
			live += 1
		for e in S.out.fx:
			var ty: String = String(e.type)
			if ty == "building_hit" and int(e.actor) == 0 and out.outcome == "":
				out.outcome = String(e.outcome)
				out.into = absf(vx)
				hitAt = k
				live = 0
			elif ty == "cue" and String(e.kind) == "wall_kick":
				out.kick = String(e.text) + " n=" + str(int(e.n)) + " sp=" + str(int(e.amount))
			elif ty == "journey_end" and int(e.actor) == 0 and out.journey == "":
				out.journey = String(e.kind)
			elif ty == "damage" and int(e.victim) == 0:
				out.dmg += float(e.amount)
			elif ty == "damage" and int(e.victim) == 1 and int(e.attacker) == 0 and out.blowAt < 0 and hitAt >= 0:
				out.blowAt = k - hitAt
				out["blowAtLive"] = live
			elif ty == "cue" and String(e.kind) == "counter_rush" and int(e.actor) == 0:
				out.rushBlow = true
		S.out.fx.clear()
		S.out.feed.clear()
		if hitAt >= 0 and k == hitAt + 1:
			out.stunAfter = me.stunTicks
		if hitAt >= 0 and out.ctlBack < 0 and k > hitAt and me.state == "free" and me.rush == null and me.stunTicks <= 0:
			out.ctlBack = k - hitAt
			out["ctlBackLive"] = live
			out.speedBack = int(SimDetMath.hypot(me.vx, me.vy))
			out.lockedBack = DirBrawl.moveLocked(S, me)
			out["brawlOn"] = DirBrawl.on()
			out["lockTicks"] = int(DirBrawl.cfg().get("firstMove", {}).get("lockTicks", 0))
		if hitAt >= 0 and k == hitAt + 30:
			out.gap30 = int(absf(SimWrap.sdx(me.x, it.x)))
			out["state30"] = me.state
		if hitAt >= 0 and k == hitAt + 120:
			break
	out.dmg = snappedf(out.dmg, 0.1)
	return out
