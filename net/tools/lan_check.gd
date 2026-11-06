extends SceneTree
## NetLan's part with no socket and no picture (docs/net/lan-v1.md): two NetLans over the loopback's links, each with a scripted player who presses and keeps pressing until told it went, as the hub does.
##   godot --headless --path . --script res://net/tools/lan_check.gd -- [--ticks=1200] [--negative-control]
## Passes only if, on lan and p120:
##   - the peers agree at the end (full SimHash and field walk), and their checkpoints matched;
##   - every press goes exactly once: each peer's stored inputs hold as many as its player pressed, within one still unsent;
##   - with a 12-tick freeze every 97 ticks, at most one press in ten lands on a frozen tick (a freeze that began after the press went can still eat it);
##   - the listener's filter lets in the home network's /24 and nothing else;
##   - a longer wait asked for on one PC alone holds on both, where the chooser by itself says 2;
##   - the fx and feed of each new tick stay for the game to draw: on lan, where nothing rolls back, both peers' games get the same number;
##   - with two fights and a player in each (--lan-2v2): the same, and each PC's S holds its own fight between ticks, and each player's presses reach the fighter in that PC's fight, and (lan, no
##     rollbacks) the other fight's record holds, after each frame, exactly the events the other PC's game drew from its own fight that tick, for the picture to draw;
##   - a trade (SimStage.trade, on both peers on every run of the tick) has the two players change fights, as partners do: each PC's S follows its player, and his presses still reach him;
##   - with hits across fights, KOs staged on both peers on every run of the tick: one player out doesn't end the match, his PC says so and shows his partner's fight; with both out it's over, and both say so.
## --negative-control: with the freeze rule off, at least three presses must land on frozen ticks; with the session clearing its output, the game must get none; with two fights, a PC that doesn't move S
## to its player's fight must be caught holding the wrong one, and with no map of players to slots the second player's fighter must never act, and with inputs left on the slot after a trade the traded player
## must stop acting, and with the session clearing its output nothing of the other fight's must stay for the picture, and a PC that keeps showing its out player's fight must be caught.
## Each must be caught.
## Verdict line: LAN: N check(s) failed

var fails: int = 0
var ticks: int = 1200


class Stand:
	var S: SimState
	var setup_used: Dictionary


## A player: light every 23 ticks, and it stays pressed until the tick says it went, as the hub's edges do.
class Player:
	var waiting: bool = false
	var made: int = 0
	var sent: int = 0
	var t: int = 0
	var slot: int = 0
	var mute: bool = false   # presses nothing: the trade rows, so a player's body acts only on its own player's presses

	func intent() -> SimIntent:
		t += 1
		if not waiting and not mute and t % 23 == 11 + slot:
			waiting = true
			made += 1
		var i := SimIntent.new()
		i.mx = 1.0 if slot == 0 else -1.0
		i.light = waiting
		i.lightHeld = waiting
		return i


func ok(c: bool, s: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + s)


func _run(pname: String, freezeRule: bool, keepOut: bool, askDelay: int = 0, twoFights: bool = false, entered: bool = true, slots: bool = true, tradeAt: int = -1, follow: bool = true, kos: Array = [], watch: bool = true) -> Dictionary:
	var prof: Dictionary = NetLoopback.PROFILES[pname]
	var ab := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 21)
	var ba := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 23)
	var clockMs: Array = [0.0]
	var lans: Array = []
	var players: Array = []
	var live: Array = [{}, {}]
	var setup: Dictionary = {"v2": [true, true, true, true], "assists": [[], [], [], []], "intro": false, "fights": 2} if twoFights else {"v2": [true, true], "assists": [[], []], "intro": false}
	if not kos.is_empty():
		setup["cross"] = true
	var aiNow: Dictionary = NetLan.AI2 if twoFights else NetLan.AI
	for k in range(2):
		var st := Stand.new()
		st.S = SimCore.createSim()
		SimCore.newMatch(st.S, NetLan.SEED, aiNow, setup)
		st.setup_used = setup
		var l := NetLan.new(st, {"lan-2v2": true} if twoFights else {})
		l.entered = entered
		l.watchPartner = watch
		l.sayTitle = false
		l.freezeRule = freezeRule
		l.keepOut = keepOut
		l.clock = func() -> float: return clockMs[0]
		l.local = k
		var key: String = NetHandshake.keyOf(NetLan.SEED, aiNow, setup)
		l.net = NetHost.new(NetLinkTransport.new(ab if k == 0 else ba, ba if k == 0 else ab, true), st.S, k, key, NetDelay.device(1.0), l.pad)
		if askDelay > 0 and k == 1:
			l.net.hs.opts = {"minDelay": askDelay}
		var kk: int = k
		l.net.configure = func(sess: NetSession) -> void:
			l.setUp(sess)
			if not slots:
				sess.slotOf = []
			sess.followBodies = follow
			sess.beforeTick = func(S: SimState, t: int) -> void:
				if tradeAt >= 0 and t >= tradeAt and NetSession.slotNow(S, 0) == 0:
					tradePartners(S)   # at the first quiet tick from tradeAt; the state says whether it's done, so every run agrees
				for e in kos:   # [tick, who falls, to whom], on every run of the tick
					if t == int(e[0]):
						var D = _body(S, String(e[1]))
						if not D.out:
							var was: int = S.stage.cur
							SimStage.enter(S, SimStage.fightOf(S, D))
							SimDamage.ko(S, D, _body(S, String(e[2])))
							SimStage.enter(S, was)
				if t % 97 == 50:
					S.dirS.stop = 12.0 * SimConst.DT   # a hit-stop on both peers on every run of the tick, so the rule has freezes to meet; with two fights, in both, whichever S holds
					if S.stage != null:
						for r in S.stage.fights:
							if r.dirS != null:   # the record of the fight in S holds a blank
								r.dirS.stop = 12.0 * SimConst.DT
			sess.perturb = func(S: SimState, t: int) -> void:
				live[kk][t] = S.stage.fights[1].T if twoFights and kk == 1 and S.stage.cur == 0 else S.T   # what the clock of this PC's fight read after tick t: it doesn't move on a frozen one
		lans.append(l)
		var p := Player.new()
		p.slot = k
		p.mute = tradeAt >= 0 and k == 1
		players.append(p)
	var fx: Array = [0, 0]
	var ownAt: Array = [{}, {}]     # tick -> the events of this PC's own fight that tick, as its game drained them
	var otherAt: Array = [{}, {}]   # tick -> the events in the other fight's record after the frame that ran it
	var wrongFight: int = 0
	var actedBefore: float = -1.0e9
	var traded: int = -1
	for frame in range(ticks):
		clockMs[0] += 1000.0 / 60.0
		for k in range(2):
			var S: SimState = lans[k].gameHost.S
			var before: int = lans[k].net.session.frame if lans[k].net != null and lans[k].net.session != null else -1
			if lans[k].tick(players[k].intent()):
				if players[k].waiting:
					players[k].waiting = false
					players[k].sent += 1
			if twoFights and lans[k].net.session != null and S.stage.cur != lans[k].viewSlot(S) / 2:
				wrongFight += 1
			if tradeAt >= 0 and k == 0 and traded < 0 and lans[0].net.session != null and NetSession.slotNow(S, 0) != 0:
				traded = lans[0].net.session.frame
				actedBefore = S.fighters[lans[0].hubSlot].lastAtkT
			fx[k] += S.out.fx.size()
			var sess: NetSession = lans[k].net.session
			if twoFights and sess != null and sess.frame > before and before >= 0:
				ownAt[k][sess.frame - 1] = S.out.fx.size()
				otherAt[k][sess.frame - 1] = S.stage.fights[1 - S.stage.cur].out.fx.size()
			S.out.feed.clear()
			S.out.fx.clear()
	return {"lans": lans, "players": players, "fx": fx, "live": live, "wrongFight": wrongFight, "traded": traded, "actedBefore": actedBefore, "ownAt": ownAt, "otherAt": otherAt}


## With two fights and no rollbacks: what each PC found in the other fight's record, tick by tick, against what the other PC's game drained from its own fight. [ticks compared, ticks that differ, events seen]
func _otherSeen(r: Dictionary, k: int) -> Array:
	var n: int = 0
	var bad: int = 0
	var seen: int = 0
	for t in r.otherAt[k]:
		if r.ownAt[1 - k].has(t):
			n += 1
			seen += int(r.otherAt[k][t])
			if int(r.otherAt[k][t]) != int(r.ownAt[1 - k][t]):
				bad += 1
	return [n, bad, seen]


func _pressesIn(sess: NetSession, k: int) -> Array:
	var ts: Array = []
	for t in sess.inputs[k]:
		if SimIntent.unpack(sess.inputs[k][t]).light:
			ts.append(int(t))
	return ts


## A press on tick t of a run: did tick t's clock stand still? The first tick of a freeze counts as frozen.
func _lost(sess: NetSession, k: int, live: Dictionary) -> int:
	var n: int = 0
	for t in _pressesIn(sess, k):
		if live.has(t) and live.has(t - 1) and live[t] == live[t - 1]:
			n += 1
	return n


static func _body(S: SimState, key: String):
	return SimStage.bodies(S).filter(func(f): return f.keys == key)[0]


## The two players change fights (with hits across fights on, a trade is between partners only).
static func tradePartners(S: SimState) -> bool:
	var bs: Array = SimStage.bodies(S)
	return SimStage.trade(S, bs.filter(func(f): return f.keys == "p1")[0], bs.filter(func(f): return f.keys == "p3")[0])


## With two fights: when the fighter this PC plays last asked for a blow, read from the fight in S's fields.
func _acted(l: NetLan) -> float:
	return l.gameHost.S.fighters[l.hubSlot].lastAtkT


func _close(r: Dictionary) -> void:
	for l in r.lans:
		SimCore.dispose(l.gameHost.S)


func _init() -> void:
	var negative: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a == "--negative-control":
			negative = true
	if negative:
		var r := _run("lan", false, true)
		var lost: int = _lost(r.lans[0].net.session, 0, r.live[0]) + _lost(r.lans[1].net.session, 1, r.live[1])
		print("control, no freeze rule: %d presses landed on a frozen tick" % lost)
		ok(lost >= 3, "with the freeze rule off, presses must land on frozen ticks (%d)" % lost)
		_close(r)
		r = _run("lan", true, false)
		print("control, the session clears its output: %d fx events reached the game" % (r.fx[0] + r.fx[1]))
		ok(r.fx[0] + r.fx[1] == 0, "with the session clearing its output, the game must get none")
		_close(r)
		r = _run("lan", true, false, 0, true)
		var os0: Array = _otherSeen(r, 0)
		var os1: Array = _otherSeen(r, 1)
		print("control, two fights, the session clears its output: the other fight's events seen %d and %d" % [os0[2], os1[2]])
		ok(os0[2] + os1[2] == 0, "with the session clearing its output, nothing of the other fight's must stay for the picture")
		_close(r)
		r = _run("lan", true, true, 0, true, true, true, -1, true, [[100, "p1", "p2"]], false)
		var cl: NetLan = r.lans[0]
		print("control, two fights, hits across, the first player out, his PC kept on his fight: it holds fight %d, his partner's is %d" % [cl.gameHost.S.stage.cur, SimStage.fightOf(cl.gameHost.S, _body(cl.gameHost.S, "p3"))])
		ok(cl.gameHost.S.stage.cur != SimStage.fightOf(cl.gameHost.S, _body(cl.gameHost.S, "p3")), "kept on his finished fight, a PC must be caught not showing the partner's")
		_close(r)
		r = _run("lan", true, true, 0, true, false)
		print("control, two fights, S not moved to the player's fight: %d frames held the wrong one" % r.wrongFight)
		ok(r.wrongFight > 0, "with S not moved, a PC must be caught holding the wrong fight")
		_close(r)
		r = _run("lan", true, true, 0, true, true, false)
		print("control, two fights, no map of players to slots: the second player's fighter's last blow is at %.3f" % _acted(r.lans[1]))
		ok(_acted(r.lans[1]) <= 0.0, "with no map, the second player's fighter must never act")
		_close(r)
		r = _run("lan", true, true, 0, true, true, true, 0, false)
		var hisNow: float = SimStage.bodies(r.lans[0].gameHost.S).filter(func(f): return f.keys == "p1")[0].lastAtkT
		print("control, two fights, inputs left on the slot after a trade at tick %d: his last blow at %.3f, the last before the trade at %.3f" % [r.traded, hisNow, r.actedBefore])
		ok(r.traded > 0 and hisNow <= r.actedBefore + 0.5, "with inputs left on the slot, the traded player must stop acting")
		_close(r)
		print("LAN: %d check(s) failed" % fails)
		quit(0 if fails == 0 else 1)
		return
	for pname in ["lan", "p120"]:
		var r := _run(pname, true, true)
		var a: NetSession = r.lans[0].net.session
		var b: NetSession = r.lans[1].net.session
		ok(a != null and b != null, "%s: both sessions started" % pname)
		var end: int = mini(a.frame, b.frame)
		ok(end > ticks / 2, "%s: the match ran (%d ticks)" % [pname, end])
		ok(a.desync.is_empty() and b.desync.is_empty() and a.checksMatched > 0, "%s: checkpoints: desync %s %s, matched %d" % [pname, str(not a.desync.is_empty()), str(not b.desync.is_empty()), a.checksMatched])
		for k in range(2):
			var s: NetSession = r.lans[k].net.session
			var pl: Player = r.players[k]
			var inMine: int = _pressesIn(s, k).size()
			ok(inMine == pl.sent, "%s: peer %d's inputs hold %d presses, and %d went" % [pname, k, inMine, pl.sent])
			ok(pl.made - pl.sent <= 1 and pl.sent > 20, "%s: peer %d pressed %d, %d went" % [pname, k, pl.made, pl.sent])
			var lost: int = _lost(s, k, r.live[k])
			# A freeze a press couldn't foresee (it began after the press went) can still eat it; a rollback's re-run too. Those are few.
			ok(lost * 10 <= pl.sent, "%s: peer %d: %d of %d presses landed on a frozen tick" % [pname, k, lost, pl.sent])
			print("  %-5s peer %d: pressed %d, went %d, on a frozen tick %d, fx to the game %d, rollbacks %d" % [pname, k, pl.made, pl.sent, lost, r.fx[k], s.rollbacks])
		ok(r.fx[0] > 0 and r.fx[1] > 0, "%s: fx reached the game (%d, %d)" % [pname, r.fx[0], r.fx[1]])
		if pname == "lan":
			ok(a.rollbacks == 0 and b.rollbacks == 0, "lan: no rollbacks (%d, %d)" % [a.rollbacks, b.rollbacks])
			ok(r.fx[0] == r.fx[1], "lan: both peers' games got the same fx (%d, %d)" % [r.fx[0], r.fx[1]])
		_close(r)
	for pname in ["lan", "p120"]:
		var r := _run(pname, true, true, 0, true)
		var a: NetSession = r.lans[0].net.session
		var b: NetSession = r.lans[1].net.session
		ok(a != null and b != null and mini(a.frame, b.frame) > ticks / 2, "%s, two fights: the match ran" % pname)
		ok(a.desync.is_empty() and b.desync.is_empty() and a.checksMatched > 0, "%s, two fights: checkpoints: desync %s %s, matched %d" % [pname, str(not a.desync.is_empty()), str(not b.desync.is_empty()), a.checksMatched])
		ok(r.wrongFight == 0, "%s, two fights: each PC's S holds its own fight between ticks (%d wrong)" % [pname, r.wrongFight])
		if pname == "lan":
			for k in range(2):
				var os: Array = _otherSeen(r, k)
				ok(os[0] > ticks / 2 and os[1] == 0 and os[2] > 0, "lan, two fights: peer %d finds the other fight's events in its record, tick by tick as the other PC's game drew them (%d ticks, %d differ, %d events)" % [k, os[0], os[1], os[2]])
				print("  lan   two fights, peer %d: the other fight's events, %d ticks compared, %d differ, %d events" % [k, os[0], os[1], os[2]])
		for k in range(2):
			var s: NetSession = r.lans[k].net.session
			var pl: Player = r.players[k]
			var inMine: int = _pressesIn(s, k).size()
			ok(inMine == pl.sent and pl.made - pl.sent <= 1 and pl.sent > 20, "%s, two fights: peer %d pressed %d, %d went, inputs hold %d" % [pname, k, pl.made, pl.sent, inMine])
			ok(_acted(r.lans[k]) > 0.0, "%s, two fights: peer %d's fighter acted" % [pname, k])
			ok(r.fx[k] > 0, "%s, two fights: fx reached peer %d's game" % [pname, k])
			print("  %-5s two fights, peer %d: pressed %d, went %d, fx to the game %d, rollbacks %d, checks matched %d" % [pname, k, pl.made, pl.sent, r.fx[k], s.rollbacks, s.checksMatched])
		_close(r)
	for pname in ["lan", "p120"]:
		var r := _run(pname, true, true, 0, true, true, true, 0)
		var a: NetSession = r.lans[0].net.session
		var b: NetSession = r.lans[1].net.session
		var l0: NetLan = r.lans[0]
		ok(r.traded > 0, "%s, a trade: it went through (tick %d)" % [pname, r.traded])
		ok(a.desync.is_empty() and b.desync.is_empty() and a.checksMatched > 0, "%s, a trade: checkpoints: desync %s %s, matched %d" % [pname, str(not a.desync.is_empty()), str(not b.desync.is_empty()), a.checksMatched])
		var l1: NetLan = r.lans[1]
		ok(r.wrongFight == 0 and l0.gameHost.S.stage.cur == 1 and l1.gameHost.S.stage.cur == 0, "%s, a trade: each PC's S follows its player into the other fight (%d wrong, they hold fights %d and %d)" % [pname, r.wrongFight, l0.gameHost.S.stage.cur, l1.gameHost.S.stage.cur])
		ok(l0.gameHost.S.fighters[l0.hubSlot].keys == "p1", "%s, a trade: the pad is on its player's place in the pair (%d)" % [pname, l0.hubSlot])
		ok(_acted(l0) > r.actedBefore + 1.0, "%s, a trade: his presses still reach him (last blow %.3f, before the trade %.3f)" % [pname, _acted(l0), r.actedBefore])
		print("  %-5s a trade at tick %d: the PCs now hold fights %d and %d, rollbacks %d, %d" % [pname, r.traded, l0.gameHost.S.stage.cur, l1.gameHost.S.stage.cur, a.rollbacks, b.rollbacks])
		_close(r)
	for pname in ["lan", "p120"]:
		var r := _run(pname, true, true, 0, true, true, true, -1, true, [[100, "p1", "p2"]])
		var a: NetSession = r.lans[0].net.session
		var b: NetSession = r.lans[1].net.session
		var l0: NetLan = r.lans[0]
		var S0: SimState = l0.gameHost.S
		ok(a.desync.is_empty() and b.desync.is_empty() and a.checksMatched > 0, "%s, hits across, one player out: checkpoints: desync %s %s, matched %d" % [pname, str(not a.desync.is_empty()), str(not b.desync.is_empty()), a.checksMatched])
		ok(not SimCore.ended(S0) and not SimCore.ended(r.lans[1].gameHost.S), "%s, hits across, one player out: the match goes on" % pname)
		ok(S0.stage.cur == SimStage.fightOf(S0, _body(S0, "p3")), "%s, hits across, one player out: his PC shows his partner's fight (%d)" % [pname, S0.stage.cur])
		ok(l0._state.begins_with("You're out") and r.lans[1]._state.begins_with("Connected"), "%s, hits across, one player out: the titles (%s; %s)" % [pname, l0._state, r.lans[1]._state])
		print("  %-5s hits across, the first player out at tick 100: his PC shows fight %d, says \"%s\"; the other says \"%s\"" % [pname, S0.stage.cur, l0._state, r.lans[1]._state])
		_close(r)
		r = _run(pname, true, true, 0, true, true, true, -1, true, [[100, "p1", "p2"], [300, "p3", "p4"]])
		ok(SimCore.ended(r.lans[0].gameHost.S) and SimCore.ended(r.lans[1].gameHost.S), "%s, hits across, both players out: the match is over on both PCs" % pname)
		ok(r.lans[0]._state.begins_with("The match is over") and r.lans[1]._state.begins_with("The match is over"), "%s, hits across, both out: the titles (%s; %s)" % [pname, r.lans[0]._state, r.lans[1]._state])
		ok(r.lans[0].net.session.desync.is_empty() and r.lans[1].net.session.desync.is_empty(), "%s, hits across, both out: no desync" % pname)
		_close(r)
	var pre: String = NetLan.prefixOf("10.0.0.135")
	ok(pre == "10.0.0.", "the /24 of an address (%s)" % pre)
	ok(NetEnetTransport.allowed("10.0.0.7", pre) and not NetEnetTransport.allowed("10.238.114.20", pre) and not NetEnetTransport.allowed("10.0.01.7", pre) and not NetEnetTransport.allowed("203.0.113.5", pre), "the filter lets in only the /24")
	var plain := _run("lan", true, true)
	ok(plain.lans[0].net.session.delay == 2, "on a LAN the chooser says 2 (%d)" % plain.lans[0].net.session.delay)
	_close(plain)
	var asked := _run("lan", true, true, 3)
	ok(asked.lans[0].net.session.delay == 3 and asked.lans[1].net.session.delay == 3, "3 asked on one PC holds on both (%d, %d)" % [asked.lans[0].net.session.delay, asked.lans[1].net.session.delay])
	ok(asked.lans[0].net.session.desync.is_empty() and asked.lans[0].net.session.checksMatched > 0, "at a wait of 3 the checkpoints match")
	print("  wait: 2 by the chooser, 3 when one PC asks")
	_close(asked)
	print("LAN: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
