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
##   - a pause of 60 s on the second PC (its game paused: idle() each frame): the first PC says "Paused by the other player" and waits, the paused one keeps sending, and after it the match goes on
##     with every press going once and the checkpoints matching;
##   - 2v2 together (NetLan's --lan-2v2-together, with the blows from outside on as the kit has them, the pairs started side by side): the peers agree under rollbacks, each player's presses go
##     once, and blows from outside happened;
##   - with hits across fights, KOs staged on both peers on every run of the tick: one player out doesn't end the match, his PC says so and shows his partner's fight once the camera's KO close-up has
##     played, NetLan.PARTNER_TICKS sim ticks after the tick on which his fight's KO clock first reads NetLan.PARTNER_AT, not before; with both out it's over, and both say so;
##   - the view, 2v2 together with the second PC hitching (frames with no tick, then the game loop's catch-up of up to six), and with a pause on p120 whose rollback re-runs ticks: each PC holds its
##     own player's fight before every tick, where the game draws, all the time he stands, and NetLan never finds S moved between ticks;
##   - the LAN's tuning with the second PC hitching: the first PC's deepest rollback stays within NetLan.LAN_AHEAD (and one save), and time sync never waits more than NetLan.SYNC_MAX_WAIT frames in a row;
##   - the log line has the frames and the view;
##   - a saved match (NetLan.save, with the scripted hit-stops off so the inputs are the whole match): both PCs' files play back through SimReplay.play,
##     every checkpoint and the final hash matching, the two PCs' replays the same, in 1v1 (lan, p120), 2v2 together (p120) and together with the second PC
##     gone (its seat's toggle on the sim's slot, p3's);
##   - NetLan's own setups (SETUP, SETUP2, SETUP2X: the folder's 1v1, 2v2 apart and together) start both PCs with the energy model on, the dash and its slip's brake, and the page's travel of 1.5,
##     and a short match on each stays in step;
##   - CD-10 (the audit's F-10), a hostile second PC: a hello asking for an input wait of 100,000 ticks fails the handshake (no session, the title says why); one
##     packet handing slot 200 to the AI is dropped whole and the match goes on in step; a flood of far-ahead inputs is dropped and the first PC's inputs stay
##     bounded; and a gone second PC (nothing from it after frame 600): its seat goes to the computer, the match goes on, the title says so and the game gets a banner;
##     in 2v2 together it's the second player's body (p3) the computer takes.
## --negative-control: with the freeze rule off, at least three presses must land on frozen ticks; with the session clearing its output, the game must get none; with two fights, a PC that doesn't move S
## to its player's fight must be caught holding the wrong one, and with no map of players to slots the second player's fighter must never act, and with inputs left on the slot after a trade the traded player
## must stop acting, and with the session clearing its output nothing of the other fight's must stay for the picture, and a PC that keeps showing its out player's fight must be caught, and a pause that
## doesn't put the view back after its rollback must be caught showing fight 0 while the player stands; with CD-10's checks off, the huge wait must be taken, the bad
## slot must reach the session (which refuses it, with no script error) and the flood must fill it; and with the hand-over off, a gone PC must freeze the match; and a LAN setup without its "power" word
## must be caught starting with the model off; a saved match with one input changed, and one whose dropped seat's toggle names the session's index
## instead of the sim's slot, must each fail to play back.
## Each must be caught.
## Verdict line: LAN: N check(s) failed

var fails: int = 0
var ticks: int = 1200


## The second PC's transport playing a broken or hostile peer (CD-10): a huge delay in its hello, one packet handing a slot that doesn't exist to
## the AI, or a flood of inputs far ahead. Through the codec, as a real link's bytes.
class Hostile extends NetLinkTransport:
	var mode: String = ""
	var fromFrame: int = 0
	var floodN: int = 0
	var bad: int = 0

	func send(now: float, pk: Dictionary) -> void:
		if mode == "delay" and str(pk.get("hs", "")) == "hello":
			pk = pk.duplicate()
			pk["delay"] = 100000
			bad += 1
		elif pk.has("from") and int(pk.get("frame", 0)) >= fromFrame:
			if mode == "slot" and bad == 0:
				pk = pk.duplicate()
				pk["ai"] = [[200, int(pk.frame) + 4]]
				bad += 1
			elif mode == "flood":
				super.send(now, pk)
				for i in range(floodN):
					var f: Dictionary = pk.duplicate()
					var ins := PackedInt64Array()
					ins.resize(255)
					f["inputs"] = ins
					f.erase("words")
					f["first"] = int(pk.frame) + 5000 + bad * 255
					bad += 1
					super.send(now, f)
				return
		super.send(now, pk)


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


func _run(pname: String, freezeRule: bool, keepOut: bool, askDelay: int = 0, twoFights: bool = false, entered: bool = true, slots: bool = true, tradeAt: int = -1, follow: bool = true, kos: Array = [], watch: bool = true, together: bool = false, pauseAt: int = -1, pauseFor: int = 0, opts: Dictionary = {}) -> Dictionary:
	var stallEvery: int = int(opts.get("stallEvery", 0))   # the second PC hitches: the last stallFor frames of every stallEvery run no tick, then the game loop catches up (up to 6 ticks a frame)
	var stallFor: int = int(opts.get("stallFor", 0))
	var pauseEvery: int = int(opts.get("pauseEvery", 0))   # the second PC's game paused pauseLen frames in every pauseEvery (idle() each frame), so some pause meets a late input
	var pauseLen: int = int(opts.get("pauseLen", 0))
	var pure: bool = bool(opts.get("pure", false))   # no scripted hit-stops: the inputs are the whole match, so a saved replay can reproduce it
	var goneAt: int = int(opts.get("goneAt", -1))   # the second PC is gone from this frame: no tick, nothing sent
	var hostile: Hostile = null
	var prof: Dictionary = NetLoopback.PROFILES[pname]
	var ab := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 21)
	var ba := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 23)
	var clockMs: Array = [0.0]
	var lans: Array = []
	var players: Array = []
	var live: Array = [{}, {}]
	var setup: Dictionary = {"v2": [true, true, true, true], "assists": [[], [], [], []], "intro": false, "fights": 2} if twoFights else {"v2": [true, true], "assists": [[], []], "intro": false}
	if not kos.is_empty() or together:
		setup["cross"] = true
	if together:
		setup["outside"] = true   # NetLan.SETUP2X's key; until the sim reads it, forced
	DirOutside.setForce(1 if together and not NetLan.outsideKeyed() else -1)
	var aiNow: Dictionary = NetLan.AI2 if twoFights else NetLan.AI
	for k in range(2):
		var st := Stand.new()
		st.S = SimCore.createSim()
		SimCore.newMatch(st.S, NetLan.SEED, aiNow, setup)
		if together and not pure:   # crosswise inside the first pair, each enemy of the other fight nearer to a player than his own rival, so the fights meet at once
			var way: float = signf(SimWrap.sdx(st.S.fighters[0].x, st.S.fighters[1].x))
			st.S.stage.fights[1].fighters[1].x = SimWrap.wrap(st.S.fighters[0].x + way * 150.0)
			st.S.stage.fights[1].fighters[0].x = SimWrap.wrap(st.S.fighters[1].x - way * 150.0)
		st.setup_used = setup
		var l := NetLan.new(st, {"lan-2v2": true} if twoFights else {})
		l.entered = entered
		l.watchPartner = watch
		l.sayTitle = false
		l.freezeRule = freezeRule
		l.keepOut = keepOut
		l.followInIdle = bool(opts.get("followInIdle", true))
		l.handOver = bool(opts.get("handOver", true))
		l.saveDir = String(opts.get("saveDir", ""))
		l.dropAfter = float(opts.get("dropAfter", NetLan.DROP_MS))
		if opts.has("log") and k == 0:
			l.args["lan-log"] = String(opts["log"])
		l.clock = func() -> float: return clockMs[0]
		l.local = k
		var key: String = NetHandshake.keyOf(NetLan.SEED, aiNow, setup)
		var link: NetTransport = NetLinkTransport.new(ab if k == 0 else ba, ba if k == 0 else ab, true)
		if k == 1 and opts.has("hostile"):
			hostile = Hostile.new(ba, ab, true)
			hostile.mode = String(opts["hostile"])
			hostile.fromFrame = int(opts.get("hostileFrom", 200))
			hostile.floodN = int(opts.get("floodN", 0))
			link = hostile
		l.net = NetHost.new(link, st.S, k, key, NetDelay.device(1.0), l.pad)
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
				if t % 97 == 50 and not pure:
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
	var ownLive: Array = [0, 0]      # frames that began (before the tick, where the game draws) with S off the PC's own player's fight while he stands
	var partnerAt: int = -1          # the first PC's frame when it first held his partner's fight, his player out
	var crossAt: int = -1            # the first PC's frame when his fight's KO clock first read NetLan.PARTNER_AT, his player out
	var paused: int = 0
	var waitRun: Array = [0, 0]      # the first PC's time sync: the current and the longest run of frames in a row that waited
	var stalled: int = 0
	var banners: int = 0            # the first PC's game: banners about a gone PC
	var pause := {"titles": {}, "sentDuring": 0, "frameAt": -1, "frameAfter": -1}   # with pauseAt: what the first PC's title said during the pause, the packets the paused one sent, the first PC's frame at its start and end
	var outside: Dictionary = {}   # with together: blows from outside seen by the first PC, "start", "hit", "whiff" -> count
	var actedBefore: float = -1.0e9
	var traded: int = -1
	for frame in range(ticks):
		clockMs[0] += 1000.0 / 60.0
		for k in range(2):
			var S: SimState = lans[k].gameHost.S
			if twoFights and lans[k].net != null and lans[k].net.session != null:
				var own: int = NetSession.slotNow(S, NetLan.SLOTS2[k])
				if not NetLan.bodyAt(S, own).out and S.stage.cur != own / 2:
					ownLive[k] += 1
				if k == 0 and partnerAt < 0 and NetLan.bodyAt(S, own).out:
					var g = NetLan.gameOf(S, own / 2)
					if crossAt < 0 and g != null and g.ko != null and float(g.koT) >= NetLan.PARTNER_AT:
						crossAt = lans[0].net.session.frame
					if S.stage.cur != own / 2:
						partnerAt = lans[0].net.session.frame
			if k == 1 and pauseEvery > 0 and frame > 60 and frame % pauseEvery < pauseLen:
				lans[1].idle()
				paused += 1
				continue
			if k == 1 and goneAt >= 0 and frame >= goneAt:
				continue   # the second PC is gone
			var reps: int = 1
			if k == 1 and stallEvery > 0 and stallFor > 0 and frame > 0:
				var ph: int = frame % stallEvery
				if ph >= stallEvery - stallFor:
					stalled += 1
					continue   # the second PC's frame is stuck: no tick, nothing sent
				if ph == 0:
					reps = mini(stallFor + 1, 6)   # the game loop's catch-up after it (SimHost.advance: acc += min(0.1, frame))
			var before: int = lans[k].net.session.frame if lans[k].net != null and lans[k].net.session != null else -1
			var w0: int = lans[k].net.waits if lans[k].net != null else 0
			if k == 1 and pauseAt >= 0 and frame >= pauseAt and frame < pauseAt + pauseFor:
				var out0: int = lans[1].net.tr.pktOut
				lans[1].idle()
				pause.sentDuring += lans[1].net.tr.pktOut - out0
				if frame == pauseAt:
					pause.frameAt = lans[0].net.session.frame
				if frame == pauseAt + pauseFor - 1:
					pause.frameAfter = lans[0].net.session.frame
				continue
			if k == 0 and pauseAt >= 0 and frame >= pauseAt + 60 and frame < pauseAt + pauseFor:
				pause.titles[lans[0]._state] = int(pause.titles.get(lans[0]._state, 0)) + 1
			for rr in range(reps):
				if lans[k].tick(players[k].intent()):
					if players[k].waiting:
						players[k].waiting = false
						players[k].sent += 1
			if k == 0 and lans[0].net != null:
				waitRun[0] = waitRun[0] + 1 if lans[0].net.waits > w0 else 0
				waitRun[1] = maxi(waitRun[1], waitRun[0])
			if twoFights and lans[k].net.session != null and S.stage.cur != lans[k].viewSlot(S) / 2:
				wrongFight += 1
			if tradeAt >= 0 and k == 0 and traded < 0 and lans[0].net.session != null and NetSession.slotNow(S, 0) != 0:
				traded = lans[0].net.session.frame
				actedBefore = S.fighters[lans[0].hubSlot].lastAtkT
			if k == 0:
				for e in S.out.fx:
					if str(e.type) == "banner" and (str(e.text).begins_with("THE OTHER PC") or str(e.text).begins_with("THE COMPUTER PLAYS")):
						banners += 1
			fx[k] += S.out.fx.size()
			var sess: NetSession = lans[k].net.session
			if together and k == 0 and sess != null and sess.frame > before and before >= 0:
				for o in [S.out] + S.stage.fights.map(func(f): return f.out):
					for e in o.fx:
						if str(e.type) == "cue" and str(e.kind) == "outside":
							outside[str(e.text)] = int(outside.get(str(e.text), 0)) + 1
			if twoFights and sess != null and sess.frame > before and before >= 0:
				ownAt[k][sess.frame - 1] = S.out.fx.size()
				otherAt[k][sess.frame - 1] = S.stage.fights[1 - S.stage.cur].out.fx.size()
			S.out.feed.clear()
			S.out.fx.clear()
	DirOutside.setForce(-1)
	return {"lans": lans, "players": players, "fx": fx, "live": live, "wrongFight": wrongFight, "traded": traded, "actedBefore": actedBefore, "ownAt": ownAt, "otherAt": otherAt, "outside": outside, "pause": pause,
		"ownLive": ownLive, "partnerAt": partnerAt, "crossAt": crossAt, "waitRun": waitRun[1], "stalled": stalled, "paused": paused,
		"banners": banners, "hostile": hostile}


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
		r = _run("p120", true, true, 0, true, true, true, -1, true, [], true, true, -1, 0, {"followInIdle": false, "pauseEvery": 61, "pauseLen": 12})
		print("control, 2v2 together, pauses on p120 that don't put the view back (%d frames paused): the paused PC began %d frames off its standing player's fight" % [r.paused, r.ownLive[1]])
		ok(r.ownLive[1] > 0, "a pause whose rollback leaves fight 0 in S must be caught showing it while the player stands")
		_close(r)
		var savedN: int = ticks
		ticks = 240
		NetHandshake.capDelay = false
		r = _run("lan", true, true, 0, false, true, true, -1, true, [], false, false, -1, 0, {"hostile": "delay"})
		NetHandshake.capDelay = true
		var dd: int = r.lans[0].net.session.delay if r.lans[0].net.session != null else -1
		print("control, CD-10, a hello asking for 100,000 ticks with the cap off: the first PC agreed %d" % dd)
		ok(dd > NetHandshake.MAX_DELAY, "with the cap off, the huge wait must be taken")
		_close(r)
		ticks = 600
		NetHost.check = false
		r = _run("lan", true, true, 0, false, true, true, -1, true, [], false, false, -1, 0, {"hostile": "slot", "hostileFrom": 200})
		var refusedThere: int = r.lans[0].net.session.takeoverRefused if r.lans[0].net.session != null else 0
		print("control, CD-10, a takeover of slot 200 with the host's checks off: it reached the session, which refused it %d time(s) (slot 200 taken: %s)" % [refusedThere, str(r.lans[0].net.session.aiFrom.has(200))])
		ok(refusedThere > 0, "with the host's checks off, the bad slot must reach the session (which refuses it)")
		_close(r)
		r = _run("lan", true, true, 0, false, true, true, -1, true, [], false, false, -1, 0, {"hostile": "flood", "hostileFrom": 200, "floodN": 4})
		NetHost.check = true
		var held: int = r.lans[0].net.session.inputs[1].size() if r.lans[0].net.session != null else 0
		print("control, CD-10, a flood of far-ahead inputs with the checks off: the first PC holds %d of the second's inputs after %d ticks" % [held, r.lans[0].net.session.frame])
		ok(held > 10000, "with the checks off, the flood must fill the session")
		_close(r)
		ticks = 1500
		r = _run("lan", true, true, 0, false, true, true, -1, true, [], false, false, -1, 0, {"goneAt": 600, "dropAfter": 1000.0, "handOver": false})
		print("control, CD-10, the second PC gone at frame 600 with the hand-over off: the first PC stopped at tick %d" % r.lans[0].net.session.frame)
		ok(r.lans[0].net.session.frame < 600 + 2 * NetLan.LAN_AHEAD + 10, "with the hand-over off, a gone PC must freeze the match")
		_close(r)
		ticks = savedN
		var bare: Dictionary = NetLan.SETUP.duplicate(true)
		bare.erase("power")
		var bp: Array = _setupPower(bare)
		print("control, a LAN setup without its power word: the model on %s, travel %.2f" % [str(bp[0]), bp[1]])
		ok(not bp[0], "a LAN setup without its power word must be caught with the model off")
		var noSlip: Dictionary = NetLan.SETUP.duplicate(true)
		noSlip["slip"] = false
		var sp: Array = _setupPower(noSlip)
		print("control, a LAN setup with its slip word off: the model, dash and slip on %s" % str(sp[0]))
		ok(not sp[0], "a LAN setup with the slip's brake off must be caught")
		var saveTo: String = OS.get_user_data_dir().path_join("lan_check_saved")
		DirAccess.make_dir_recursive_absolute(saveTo)
		var keepN: int = ticks
		ticks = 1200
		r = _run("p120", true, true, 0, false, true, true, -1, true, [], false, false, -1, 0, {"pure": true, "saveDir": saveTo})
		var bent: Dictionary = _savedPlay(r, saveTo, func(d: Dictionary) -> void:
			var ins: Array = d.replay.inputs
			for i in range(ins.size() / 2, ins.size()):   # one input after tick 200 becomes another real one (a valid intent, a different press)
				if int(ins[i][0]) > 200 and ins[i][2] != null and ins[0][2] != null and (ins[0][2] != ins[i][2] or ins[0][3] != ins[i][3]):
					ins[i][2] = ins[0][2]
					ins[i][3] = ins[0][3]
					break)
		print("control, a saved match with one input changed: play back %s" % str(bent.reasons))
		ok(not bool(bent.ok), "a saved match with one input changed must fail to play back")
		_close(r)
		r = _run("p120", true, true, 0, true, true, true, -1, true, [], true, true, -1, 0, {"pure": true, "saveDir": saveTo, "goneAt": 600, "dropAfter": 1000.0})
		var wrongSeat: Dictionary = _savedPlay(r, saveTo, func(d: Dictionary) -> void:
			for tg in d.replay.toggles:
				tg[1] = 1.0)   # the session's index of the gone PC's player, as before the fix: a computer's body
		print("control, a saved 2v2 with the gone seat's toggle on the session's index: play back %s" % str(wrongSeat.reasons))
		ok(not bool(wrongSeat.ok), "a dropped seat's toggle on the session's index must fail to play back")
		_close(r)
		ticks = keepN
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
		var g0 = S0.game if S0.stage.cur == 0 else S0.stage.fights[0].game
		ok(g0.ko != null and a.frame > ticks - 100 and b.frame > ticks - 100, "%s, hits across, one player out: his fight has its KO and both PCs played on past it (KO %s, frames %d, %d)" % [pname, str(g0.ko != null), a.frame, b.frame])
		ok(S0.stage.cur == SimStage.fightOf(S0, _body(S0, "p3")), "%s, hits across, one player out: his PC shows his partner's fight (%d)" % [pname, S0.stage.cur])
		ok(r.crossAt > 100 and r.partnerAt - r.crossAt == NetLan.PARTNER_TICKS, "%s, hits across, one player out: his PC keeps his own fight through the KO close-up and shows his partner's %d sim ticks after his fight's KO clock first reads %.1f (it read it at tick %d, the partner's fight at tick %d)" % [pname, NetLan.PARTNER_TICKS, NetLan.PARTNER_AT, r.crossAt, r.partnerAt])
		ok(l0._state.begins_with("You're out") and r.lans[1]._state.begins_with("Connected"), "%s, hits across, one player out: the titles (%s; %s)" % [pname, l0._state, r.lans[1]._state])
		print("  %-5s hits across, the first player out at tick 100: his PC shows fight %d from tick %d (his fight's KO clock read %.1f at tick %d), says \"%s\"; the other says \"%s\"" % [pname, S0.stage.cur, r.partnerAt, NetLan.PARTNER_AT, r.crossAt, l0._state, r.lans[1]._state])
		_close(r)
		if pname == "lan":   # the same first KO in 2v2 together (hits across and the blows from outside on, the pairs side by side)
			r = _run(pname, true, true, 0, true, true, true, -1, true, [[100, "p1", "p2"]], true, true)
			var T0: SimState = r.lans[0].gameHost.S
			var tg = T0.game if T0.stage.cur == 0 else T0.stage.fights[0].game
			ok(tg.ko != null and not SimCore.ended(T0) and not SimCore.ended(r.lans[1].gameHost.S) and r.lans[0]._state.begins_with("You're out") and r.lans[0].net.session.frame > ticks - 100 and r.lans[0].net.session.desync.is_empty(), "lan, 2v2 together, the first player out: one fight's KO, the match goes on (%s; frames %d)" % [r.lans[0]._state, r.lans[0].net.session.frame])
			_close(r)
		r = _run(pname, true, true, 0, true, true, true, -1, true, [[100, "p1", "p2"], [300, "p3", "p4"]])
		ok(SimCore.ended(r.lans[0].gameHost.S) and SimCore.ended(r.lans[1].gameHost.S), "%s, hits across, both players out: the match is over on both PCs" % pname)
		ok(r.lans[0]._state.begins_with("The match is over") and r.lans[1]._state.begins_with("The match is over"), "%s, hits across, both out: the titles (%s; %s)" % [pname, r.lans[0]._state, r.lans[1]._state])
		ok(r.lans[0].net.session.desync.is_empty() and r.lans[1].net.session.desync.is_empty(), "%s, hits across, both out: no desync" % pname)
		_close(r)
	var saved: int = ticks
	ticks = 1200 + 3600
	for pname in ["lan", "p120"]:
		var r := _run(pname, true, true, 0, false, true, true, -1, true, [], true, false, 600, 3600)
		var a: NetSession = r.lans[0].net.session
		var b: NetSession = r.lans[1].net.session
		var pz: Dictionary = r.pause
		ok(pz.titles.size() == 1 and pz.titles.has("Paused by the other player"), "%s, a 60 s pause: the first PC says so all through it (%s)" % [pname, str(pz.titles)])
		ok(int(pz.sentDuring) > 3000, "%s, a 60 s pause: the paused PC kept sending (%d packets)" % [pname, pz.sentDuring])
		ok(int(pz.frameAfter) - int(pz.frameAt) <= a.maxAhead + 1, "%s, a 60 s pause: the first PC waited, at most its lead past the last input it holds (it moved %d ticks)" % [pname, int(pz.frameAfter) - int(pz.frameAt)])
		ok(a.frame > 1000 and b.frame > 1000 and a.desync.is_empty() and b.desync.is_empty() and a.checksMatched > 10, "%s, a 60 s pause: the match went on after it (frames %d, %d, checks matched %d)" % [pname, a.frame, b.frame, a.checksMatched])
		for k in range(2):
			var pl: Player = r.players[k]
			ok(_pressesIn(r.lans[k].net.session, k).size() == pl.sent and pl.made - pl.sent <= 1, "%s, a 60 s pause: peer %d pressed %d, %d went" % [pname, k, pl.made, pl.sent])
		print("  %-5s a 60 s pause on the second PC: the first said %s, the paused one sent %d packets, the first moved %d ticks; after it frames %d and %d, checks matched %d" % [pname, str(pz.titles), pz.sentDuring, int(pz.frameAfter) - int(pz.frameAt), a.frame, b.frame, a.checksMatched])
		_close(r)
	ticks = saved
	for pname in ["lan", "p120"]:
		var r := _run(pname, true, true, 0, true, true, true, -1, true, [], true, true)
		var a: NetSession = r.lans[0].net.session
		var b: NetSession = r.lans[1].net.session
		ok(a.desync.is_empty() and b.desync.is_empty() and a.checksMatched > 0, "%s, 2v2 together: checkpoints: desync %s %s, matched %d" % [pname, str(not a.desync.is_empty()), str(not b.desync.is_empty()), a.checksMatched])
		for k in range(2):
			var pl: Player = r.players[k]
			ok(_pressesIn(r.lans[k].net.session, k).size() == pl.sent and pl.made - pl.sent <= 1 and pl.sent > 20, "%s, 2v2 together: peer %d pressed %d, %d went" % [pname, k, pl.made, pl.sent])
		if pname == "lan":   # the same presses on p120 meet other moments, as predictions differ: the count there is read, not required
			ok(int(r.outside.get("start", 0)) > 0, "lan, 2v2 together: blows from outside happened (%s)" % str(r.outside))
		print("  %-5s 2v2 together: rollbacks %d, %d, checks matched %d, blows from outside %s" % [pname, a.rollbacks, b.rollbacks, a.checksMatched, str(r.outside)])
		_close(r)
	for pname in ["lan", "p120"]:   # the view, with the second PC hitching (20 frames in every 240: a third of a second) and, on p120, a pause whose rollback re-runs ticks
		var r := _run(pname, true, true, 0, true, true, true, -1, true, [], true, true, -1, 0, {"stallEvery": 240, "stallFor": 20, "pauseEvery": 61 if pname == "p120" else 0, "pauseLen": 12})
		var a: NetSession = r.lans[0].net.session
		var b: NetSession = r.lans[1].net.session
		ok(a.desync.is_empty() and b.desync.is_empty() and a.checksMatched > 0 and int(r.stalled) > 0, "%s, 2v2 together, the second PC hitching: checkpoints match (desync %s %s, matched %d, frames stuck %d)" % [pname, str(not a.desync.is_empty()), str(not b.desync.is_empty()), a.checksMatched, r.stalled])
		ok(r.ownLive[0] == 0 and r.ownLive[1] == 0, "%s, 2v2 together, the second PC hitching%s: each PC shows its own fight before every tick while its player stands (%d and %d frames off it)" % [pname, ", pauses" if pname == "p120" else "", r.ownLive[0], r.ownLive[1]])
		ok(r.lans[0].viewMoves == 0 and r.lans[1].viewMoves == 0 and r.lans[0].ownLiveWrong == 0 and r.lans[1].ownLiveWrong == 0, "%s, 2v2 together, hitching: NetLan never found S moved between ticks, nor ended a tick off its standing player's fight (%d, %d; %d, %d)" % [pname, r.lans[0].viewMoves, r.lans[1].viewMoves, r.lans[0].ownLiveWrong, r.lans[1].ownLiveWrong])
		ok(a.maxDepth <= NetLan.LAN_AHEAD + NetLan.SAVE_EVERY and b.maxDepth <= NetLan.LAN_AHEAD + NetLan.SAVE_EVERY, "%s, the second PC hitching: the deepest rollback stays within the LAN's lead and a save (%d, %d; at most %d)" % [pname, a.maxDepth, b.maxDepth, NetLan.LAN_AHEAD + NetLan.SAVE_EVERY])
		ok(int(r.waitRun) <= NetLan.SYNC_MAX_WAIT, "%s, the second PC hitching: time sync waits at most %d frames in a row (%d)" % [pname, NetLan.SYNC_MAX_WAIT, r.waitRun])
		ok(a.maxAhead == NetLan.LAN_AHEAD and a.saveEvery == NetLan.SAVE_EVERY and r.lans[0].net.sync.maxWait == NetLan.SYNC_MAX_WAIT and r.lans[0].net.sync.every == NetLan.SYNC_EVERY, "%s: the LAN's tuning is set (lead %d, saves every %d, waits %d every %d)" % [pname, a.maxAhead, a.saveEvery, r.lans[0].net.sync.maxWait, r.lans[0].net.sync.every])
		print("  %-5s 2v2 together, the second PC stuck %d frames in all, paused %d: off its own fight %d and %d, deepest rollbacks %d and %d, longest wait %d, rollbacks %d and %d" % [pname, r.stalled, r.paused, r.ownLive[0], r.ownLive[1], a.maxDepth, b.maxDepth, r.waitRun, a.rollbacks, b.rollbacks])
		_close(r)
	var logPath: String = OS.get_user_data_dir().path_join("lan_check_log.txt")
	if FileAccess.file_exists(logPath):
		DirAccess.remove_absolute(logPath)
	var lr := _run("p120", true, true, 0, true, true, true, -1, true, [], true, false, -1, 0, {"stallEvery": 240, "stallFor": 20, "log": logPath})
	var logText: String = FileAccess.get_file_as_string(logPath)
	ok(logText.contains("frames: worst ") and logText.contains("over 100 ms") and logText.contains("most re-run in a frame") and logText.contains("view fight 0 (his own)"), "the log line has the frames and the view")
	print("  log: %s" % logText.strip_edges().get_slice("\n", 1).get_slice("; ", 3).left(160))
	_close(lr)
	DirAccess.remove_absolute(logPath)
	for nm in ["SETUP", "SETUP2", "SETUP2X"]:
		var su: Dictionary = {"SETUP": NetLan.SETUP, "SETUP2": NetLan.SETUP2, "SETUP2X": NetLan.SETUP2X}[nm]
		var pr: Array = _setupPower(su)
		ok(pr[0] and is_equal_approx(pr[1], 1.5) and pr[2], "NetLan.%s: both PCs start with the energy model, the dash and the slip's brake on and travel 1.5, and 300 ticks stay in step (on %s, travel %.2f, in step %s)" % [nm, str(pr[0]), pr[1], str(pr[2])])
		print("  NetLan.%s: the energy model, dash and slip on %s, travel %.2f, 300 ticks in step %s" % [nm, str(pr[0]), pr[1], str(pr[2])])
	var keep: int = ticks
	ticks = 240
	var hd := _run("lan", true, true, 0, false, true, true, -1, true, [], false, false, -1, 0, {"hostile": "delay"})
	ok(hd.lans[0].net.session == null and hd.lans[0].net.hs.failed.contains("input wait") and hd.lans[0]._state.begins_with("Couldn't start"), "CD-10, a hello asking for an input wait of 100,000 ticks: no session, the title says why (%s)" % hd.lans[0]._state)
	print("  CD-10 a huge wait asked for: %s" % hd.lans[0]._state)
	_close(hd)
	ticks = 1200
	for mode in ["slot", "flood"]:
		var hr := _run("lan", true, true, 0, false, true, true, -1, true, [], false, false, -1, 0, {"hostile": mode, "hostileFrom": 200, "floodN": 4})
		var ha: NetSession = hr.lans[0].net.session
		var hb: NetSession = hr.lans[1].net.session
		ok(ha != null and hb != null and ha.frame > ticks - 100 and ha.desync.is_empty() and hb.desync.is_empty() and ha.checksMatched > 0, "CD-10, %s: the match went on in step (frames %d, checks matched %d)" % [mode, ha.frame if ha else -1, ha.checksMatched if ha else -1])
		ok(hr.lans[0].net.rejected >= 1 and hr.lans[0].net.rejected >= hr.hostile.bad - 2 * maxi(1, hr.hostile.floodN), "CD-10, %s: every bad packet that arrived was dropped (%d dropped, %d sent, the last frame's still on the way)" % [mode, hr.lans[0].net.rejected, hr.hostile.bad])
		if mode == "slot":
			ok(ha.aiFrom.is_empty() and ha.takeoverRefused == 0, "CD-10, a takeover of slot 200: the host dropped it, so nothing reached the session (%s, refused there %d)" % [str(ha.aiFrom), ha.takeoverRefused])
		else:
			ok(ha.inputs[1].size() < ha.frame + 400, "CD-10, a flood of far-ahead inputs: the first PC holds %d of the second's inputs after %d ticks" % [ha.inputs[1].size(), ha.frame])
		print("  CD-10 %-5s: dropped %d of %d bad packets, frames %d, checks matched %d, the second's inputs held %d" % [mode, hr.lans[0].net.rejected, hr.hostile.bad, ha.frame, ha.checksMatched, ha.inputs[1].size()])
		_close(hr)
	ticks = 1500
	for two in [false, true]:
		var gr := _run("lan", true, true, 0, two, true, true, -1, true, [], true, two, -1, 0, {"goneAt": 600, "dropAfter": 1000.0})
		var g0: NetLan = gr.lans[0]
		var gs: NetSession = g0.net.session
		var gS: SimState = g0.gameHost.S
		var seat = _body(gS, "p3") if two else gS.fighters[1]
		var what: String = "2v2 together" if two else "1v1"
		ok(g0.droppedAt > 400 and gs.frame > ticks - 200 and gs.desync.is_empty(), "CD-10, %s, the second PC gone at frame 600: its seat went to the computer from tick %d and the match went on (frame %d)" % [what, g0.droppedAt, gs.frame])
		ok(seat.ai != null, "CD-10, %s: the computer plays the gone PC's fighter (%s)" % [what, "p3" if two else "p2"])
		if two:
			ok(_body(gS, "p2").ai != null and _body(gS, "p1").ai == null, "CD-10, 2v2 together: the computer's own fighter is unchanged and the first PC's player is still his")
		ok(g0._state.begins_with("The other PC has gone: the computer plays") or g0._state.begins_with("You're out") or g0._state.begins_with("The match is over"), "CD-10, %s: the title says so (%s)" % [what, g0._state])
		ok(int(gr.banners) >= 2, "CD-10, %s: the game got banners about it (%d)" % [what, gr.banners])
		print("  CD-10 %s, the second PC gone at frame 600: the computer from tick %d, frame %d at the end, banners %d, title \"%s\"" % [what, g0.droppedAt, gs.frame, gr.banners, g0._state])
		_close(gr)
	ticks = keep
	var saveTo: String = OS.get_user_data_dir().path_join("lan_check_saved")
	DirAccess.make_dir_recursive_absolute(saveTo)
	var keepT: int = ticks
	ticks = 1200
	for row in [["lan", false, -1], ["p120", false, -1], ["p120", true, -1], ["p120", true, 600]]:
		var sr := _run(String(row[0]), true, true, 0, bool(row[1]), true, true, -1, true, [], true, bool(row[1]), -1, 0, {"pure": true, "saveDir": saveTo, "goneAt": int(row[2]), "dropAfter": 1000.0})
		var what: String = "%s %s%s" % [String(row[0]), "2v2 together" if bool(row[1]) else "1v1", ", the second PC gone at frame 600" if int(row[2]) >= 0 else ""]
		var sp: Dictionary = _savedPlay(sr, saveTo)
		ok(bool(sp.ok) and int(sp.n) > 5, "a saved match, %s: both PCs' files play back to every checkpoint and the final hash (%d checkpoints, %d with a final, %s)" % [what, sp.n, sp.finals, str(sp.reasons)])
		if int(row[2]) < 0:
			ok(bool(sp.same), "a saved match, %s: the two PCs saved the same inputs and toggles" % what)
		else:
			ok(sr.lans[0].droppedAt > 0 and (sp.toggles as Array).size() >= 1 and int(sp.toggles[0][1]) == 2, "a saved match, %s: the gone PC's seat is a toggle on the sim's slot 2 (%s)" % [what, str(sp.toggles)])
		print("  saved match, %s: %d checkpoints, finals %d, play %s, same %s, toggles %s" % [what, sp.n, sp.finals, str(sp.reasons), str(sp.same), str(sp.toggles)])
		_close(sr)
	ticks = keepT
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


## A setup's energy model on two PCs: [on, travel, in step]. Each PC starts its match from the setup and plays 300 ticks of the computer against the
## computer; in step means the two SimHashes agree after (the same seed, the same setup), as two PCs' do.
func _setupPower(su: Dictionary) -> Array:
	var ai: Dictionary = {"p1": true, "p2": true, "p3": true, "p4": true} if su.has("fights") else {"p1": true, "p2": true}
	var hs: Array = []
	var on: bool = true
	var trav: float = -1.0
	for k in range(2):
		var S: SimState = SimCore.createSim()
		SimCore.newMatch(S, NetLan.SEED, ai, su)
		on = on and S.powerOn and (S.get("dashOn") == null or bool(S.get("dashOn")))   # the dash too, once the sim has it (Simulation's power-dash)
		on = on and S.get("slipOn") == true   # and the slip's brake (Simulation's dash-slip; the setup's "slip"): this row needs it
		trav = S.powerTravel
		for t in range(300):
			SimCore.step(S, null)
		hs.append(SimHash.stateHash(S).gameplay)
		SimCore.dispose(S)
	return [on, trav, hs[0] == hs[1]]


## Both PCs save; each file is read back and played through SimReplay.play. mutate (tests): (doc) -> void, applied to each doc before it
## plays. Returns {ok: every file played back to its checkpoints and final, same: the two replays' inputs and toggles alike, n: checkpoints,
## finals: how many carried a final hash, reasons: SimReplay.play's reasons, toggles: the first file's toggles, files: the names}.
func _savedPlay(r: Dictionary, dir: String, mutate: Callable = Callable()) -> Dictionary:
	var docs: Array = []
	var files: Array = []
	for k in range(2):
		var fn: String = r.lans[k].save("test")
		files.append(fn)
		var j = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(fn))) if fn != "" else null
		docs.append(j)
	var out := {"ok": true, "same": true, "n": 0, "finals": 0, "reasons": [], "toggles": [], "files": files}
	for d in docs:
		if not (d is Dictionary) or not (d.get("replay") is Dictionary) or String(d.get("kind", "")) != "orb-lan-match":
			out.ok = false
			out.reasons.append("no file")
			continue
		if mutate.is_valid():
			mutate.call(d)
		var rp: Dictionary = d.replay
		var res: Dictionary = SimReplay.play(rp)
		out.reasons.append(String(res.reason))
		out.n = maxi(int(out.n), (rp.checkpoints as Array).size())
		if String(rp.final) != "":
			out.finals = int(out.finals) + 1
		if not bool(res.ok) or (rp.checkpoints as Array).is_empty():
			out.ok = false
	if docs.size() == 2 and docs[0] is Dictionary and docs[1] is Dictionary:
		var a: Dictionary = docs[0].replay
		var b: Dictionary = docs[1].replay
		var n: int = mini(int(a.ticks), int(b.ticks))
		out.same = JSON.stringify((a.inputs as Array).filter(func(e): return int(e[0]) < n)) == JSON.stringify((b.inputs as Array).filter(func(e): return int(e[0]) < n)) and JSON.stringify(a.toggles) == JSON.stringify(b.toggles)
		out.toggles = a.toggles
	for fn in files:
		if fn != "":
			DirAccess.remove_absolute(dir.path_join(fn))
	return out
