extends SceneTree
## NetLan's part with no socket and no picture (docs/net/lan-v1.md): two NetLans over the loopback's links, each with a scripted player who presses and keeps pressing until told it went, as the hub does.
##   godot --headless --path . --script res://net/tools/lan_check.gd -- [--ticks=1200] [--negative-control]
## Passes only if, on lan and p120:
##   - the peers agree at the end (full SimHash and field walk), and their checkpoints matched;
##   - every press goes exactly once: each peer's stored inputs hold as many as its player pressed, within one still unsent;
##   - with a 12-tick freeze every 97 ticks, at most one press in ten lands on a frozen tick (a freeze that began after the press went can still eat it);
##   - the listener's filter lets in the home network's /24 and nothing else;
##   - a longer wait asked for on one PC alone holds on both, where the chooser by itself says 2;
##   - the fx and feed of each new tick stay for the game to draw: on lan, where nothing rolls back, both peers' games get the same number.
## --negative-control: with the freeze rule off, at least three presses must land on frozen ticks; with the session clearing its output, the game must get none. Each must be caught.
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

	func intent() -> SimIntent:
		t += 1
		if not waiting and t % 23 == 11 + slot:
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


func _run(pname: String, freezeRule: bool, keepOut: bool, askDelay: int = 0) -> Dictionary:
	var prof: Dictionary = NetLoopback.PROFILES[pname]
	var ab := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 21)
	var ba := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 23)
	var clockMs: Array = [0.0]
	var lans: Array = []
	var players: Array = []
	var live: Array = [{}, {}]
	var setup: Dictionary = {"v2": [true, true], "assists": [[], []], "intro": false}
	for k in range(2):
		var st := Stand.new()
		st.S = SimCore.createSim()
		SimCore.newMatch(st.S, NetLan.SEED, NetLan.AI, setup)
		st.setup_used = setup
		var l := NetLan.new(st, {})
		l.sayTitle = false
		l.freezeRule = freezeRule
		l.keepOut = keepOut
		l.clock = func() -> float: return clockMs[0]
		l.local = k
		var key: String = NetHandshake.keyOf(NetLan.SEED, NetLan.AI, setup)
		l.net = NetHost.new(NetLinkTransport.new(ab if k == 0 else ba, ba if k == 0 else ab, true), st.S, k, key, NetDelay.device(1.0), l.pad)
		if askDelay > 0 and k == 1:
			l.net.hs.opts = {"minDelay": askDelay}
		var kk: int = k
		l.net.configure = func(sess: NetSession) -> void:
			sess.presentOut = l.keepOut
			sess.beforeTick = func(S: SimState, t: int) -> void:
				if t % 97 == 50:
					S.dirS.stop = 12.0 * SimConst.DT   # a hit-stop on both peers on every run of the tick, so the rule has freezes to meet
			sess.perturb = func(S: SimState, t: int) -> void:
				live[kk][t] = S.T   # what the clock read after tick t: it doesn't move on a frozen one
		lans.append(l)
		var p := Player.new()
		p.slot = k
		players.append(p)
	var fx: Array = [0, 0]
	for frame in range(ticks):
		clockMs[0] += 1000.0 / 60.0
		for k in range(2):
			var S: SimState = lans[k].gameHost.S
			if lans[k].tick(players[k].intent()):
				if players[k].waiting:
					players[k].waiting = false
					players[k].sent += 1
			fx[k] += S.out.fx.size()
			S.out.feed.clear()
			S.out.fx.clear()
	return {"lans": lans, "players": players, "fx": fx, "live": live}


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
