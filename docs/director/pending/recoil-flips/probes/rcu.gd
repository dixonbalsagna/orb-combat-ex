extends SceneTree
## Unit probe: recoil flips, each case forced. Slot 0 is a scripted player, slot 1 the AI; the switch on in memory.
## Both stand on the ground 2 bh apart; slot 1 knocks slot 0 back (DirLaunch.knock) at the striker's tier, then slot 0
## taps the dodge at --tap live ticks (0: never) and presses X 2 ticks after his landing. Cases:
##   skid     tier 3 (6.5 bh: a journey; flipping it needs World's recoilEnd)
##   slide    tier 1 (3.5 bh: the upright slide)
##   edge     tier 3, the tap on the 10th live tick (the window's last: a flip)
##   late     tier 3, the tap on the 11th live tick (out of the window: no flip)
## --tap counts live ticks (S.T moves), as the window does; each line logs the window's ticks left.
##   none     tier 3, no tap (the flourish's cue only)
## Each prints the events of the next 60 ticks that matter, and a verdict.


func _init() -> void:
	DirInterrupt.data()["recoilFlip"]["enabled"] = true
	var out := []
	for cs in [["skid", 3.0, 3], ["slide", 1.0, 3], ["edge", 3.0, 10], ["late", 3.0, 11], ["none", 3.0, 0]]:
		out.append(_case(String(cs[0]), float(cs[1]), int(cs[2])))
	for o in out:
		print(JSON.stringify(o))
	quit()


func _case(name: String, tier: float, tap: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 7, {"p1": false, "p2": true}, {"v2": [true, true]})
	for k in range(30):
		SimCore.step(S, [SimIntent.new(), null])
		S.out.fx.clear()
		S.out.feed.clear()
	var me = S.fighters[0]
	var it = S.fighters[1]
	S.dirS.ex = null
	for f in [me, it]:
		f.state = "free"
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
		f.stunTicks = 0
	var x0 := 0.0
	while x0 < 150000.0 and not (WorldBiomes.biomeAt(x0) == "plains" and not WorldTerrain.seaAt(S, x0) and absf(WorldTerrain.groundY(S, x0) - WorldTerrain.groundY(S, x0 - 900.0)) < 20.0):
		x0 += 300.0
	me.x = x0
	it.x = x0 + 150.0
	me.y = WorldTerrain.groundY(S, me.x)
	it.y = WorldTerrain.groundY(S, it.x)
	it.tier = tier
	var r := {"x0": x0, "v2": [me.act.v2, it.act.v2], "case": name, "tier": tier, "tap": tap, "events": [], "flip": false, "journeyRecoil": false, "counter": false, "lunge": false}
	DirLaunch.knock(S, it, me, 1.0)
	for e in S.out.fx:
		if String(e.type) == "knockback" or (String(e.type) == "cue" and String(e.kind) == "recoil"):
			r.events.append("t0 " + _ev(e))
	S.out.fx.clear()
	S.out.feed.clear()
	var land := -1
	var live := 0
	for k in range(1, 61):
		var i := SimIntent.new()
		var t0: float = S.T
		if tap > 0 and live == tap - 1 and not r.flip:
			i.dodge = true
		if land > 0 and k == land + 2:
			i.light = true
		SimCore.step(S, [i, null])
		if S.T != t0:
			live += 1
		if k <= 14:
			r.events.append("t%d live %d left %d tapped %s" % [k, live, DirRecoil._g(me, DirRecoil.RC_LEFT), str(i.dodge)])
		for e in S.out.fx:
			var ty: String = String(e.type)
			var keep: bool = ty == "journey_end" or ty == "knockback" or (ty == "cue" and (String(e.kind) == "recoil" or String(e.kind) == "counter_rush" or String(e.kind) == "blow" or String(e.kind) == "lunge_light"))
			if keep:
				r.events.append("t" + str(k) + " " + _ev(e))
			if ty == "cue" and String(e.kind) == "recoil" and String(e.text) == "flip":
				r.flip = true
				land = k + int(e.dur)
			if ty == "journey_end" and String(e.kind) == "recoil":
				r.journeyRecoil = true
			if ty == "cue" and String(e.kind) == "counter_rush":
				r.counter = true
			if ty == "cue" and String(e.kind) == "blow" and String(e.source) == "lunge" and int(e.actor) == 0:
				r.lunge = true
		if k % 6 == 0 or k == land:
			r.events.append("t%d  me %s x=%d y=%d rush=%s" % [k, me.state, int(me.x), int(me.y - WorldTerrain.groundY(S, me.x)), str(me.rush != null)])
		S.out.fx.clear()
		S.out.feed.clear()
	return r


func _ev(e) -> String:
	var ty: String = String(e.type)
	if ty == "cue":
		return "cue %s %s %s actor=%d n=%d x=%d amount=%d dur=%d" % [String(e.kind), String(e.text), String(e.source), int(e.actor), int(e.n), int(e.x), int(e.amount), int(e.dur)]
	if ty == "knockback":
		return "knockback %s dist=%d end=%d" % [String(e.kind), int(e.amount), int(e.n)]
	return "%s %s" % [ty, String(e.kind)]
