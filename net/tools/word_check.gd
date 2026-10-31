extends SceneTree
## The intent's second word on the net (docs/net/rollback.md section 14). switches.rightStick is on in this process, except where a row says off.
##   godot --headless --path . --script res://net/tools/word_check.gd [-- --ticks=600 --profiles=lan,p120,far --negative-control]
## Passes (exit 0) only if:
##   - the wire: a packet without a word is the bytes it always was; one with a word survives the round trip, and a malformed one is refused;
##   - a prediction keeps a held strike and drops the edges; a late word that differs rolls back when the first word agrees, and one that doesn't, doesn't;
##   - two peers, every profile: every confirmed tick's gameplay hash equals a straight run's. Nothing in the sim reads the word yet, so a stand-in does: each tick a throw
##     spends ki and a brace spends some too, on every run of the tick, so a lost word stays in the state as a director's reading of it would;
##   - the digest: a word changed on one peer, on the tick before a checkpoint, is reported there and named by the field walk;
##   - the report's replay: its entries hold the word, it survives JSON, it plays, its re-simulated state has the session's digest, and a changed word is caught;
##   - the match key differs with the switch on and off, and peers on either side are refused at the handshake;
##   - off: the bots write no word, a word handed in reaches no hash and no digest, and every packet is kind 1.
## --negative-control breaks it three ways, and each must be caught: words received are dropped; a late word doesn't roll back; the digest leaves the word out.

const SEED: int = 11
const DELAY: int = 2

var fails: int = 0
var checks: int = 0
var ticks: int = 600
var profiles: Array = ["lan", "p120", "far"]


func ok(c: bool, s: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  " + s)


## The stand-in for a director reading the word: state from the fighters' last intents, the same on every run of a tick and in the straight run.
static func reader(S: SimState, _t: int = 0) -> void:
	for f in S.fighters:
		var i: SimIntent = f.input
		if i.rsRelease:
			f.ki = maxf(f.ki - float(i.rsLevel + 1), 0.0)
		if i.rsCancel:
			f.ki = minf(f.ki + 1.0, 100.0)
		if i.brace:
			f.ki = maxf(f.ki - 0.5 * float(i.braceDir), 0.0)


func straight(ticks_: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, SEED, {"p1": false, "p2": false}, {})
	var bots: Array = [NetBot.new(SEED, 0), NetBot.new(SEED, 1)]
	var hashes: Dictionary = {}
	var digests: Dictionary = {}
	var used: int = 0
	for t in range(ticks_):
		var ins: Array = []
		for k in range(2):
			if t < DELAY:
				ins.append(SimIntent.unpack(NetSession.NEUTRAL))
			else:
				var p: int = bots[k].next()
				used += 1 if bots[k].word != 0 else 0
				ins.append(NetSession.intentOf(p, bots[k].word))
		reader(S)
		SimCore.step(S, ins)
		S.out.feed.clear()
		S.out.fx.clear()
		hashes[t + 1] = SimHash.stateHash(S).gameplay
		digests[t + 1] = NetDesync.digest(S)
	SimCore.dispose(S)
	return {"hash": hashes, "digest": digests, "used": used}


## Two peers over the bytes of the wire, reading the word, in verify mode. break_: "" or "lost" or "norollback". {bad, first, rollbacks, words, bytes, ran}
func session(pname: String, ref: Dictionary, break_: String = "") -> Dictionary:
	var L := NetLoopback.make(SEED, {}, NetLoopback.PROFILES[pname], DELAY, SEED, 3, true)
	var res := {"bad": 0, "first": -1, "ran": false}
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		sess.verify = true
		sess.beforeTick = reader
		sess.wordsLost = break_ == "lost"
		sess.wordRollback = break_ != "norollback"
		var me: int = k
		sess.onConfirmed = func(b: int, st: SimState, _o: String) -> void:
			if st != null and b <= ticks and SimHash.stateHash(st).gameplay != ref.hash[b]:
				res.bad = int(res.bad) + 1
				if int(res.first) < 0:
					res.first = b
					res.who = me
	res.ran = L.run(ticks)
	res.rollbacks = L.peers[0].session.rollbacks + L.peers[1].session.rollbacks
	res.mis = L.peers[0].session.mispredicted + L.peers[1].session.mispredicted
	res.depth = maxi(L.peers[0].session.maxDepth, L.peers[1].session.maxDepth)
	res.bytes = L.peers[0].transport.bytesOut + L.peers[1].transport.bytesOut
	res.words = L.peers[0].session.words[0].size() + L.peers[0].session.words[1].size()
	L.close()
	return res


func wire() -> void:
	var pk := {"from": 0, "frame": 9, "ack": 3, "first": 4, "inputs": PackedInt64Array([NetSession.NEUTRAL, NetSession.NEUTRAL | (1 << 30)]), "chk": [], "ts": 1.0, "echo": 2.0, "age": 0.0, "adv": 0.0}
	var plain: PackedByteArray = NetTransport.encode(pk)
	ok(plain[0] == 1 and plain.size() == 40 + 16, "a packet without a word: kind 1, its old size (%d, %d)" % [plain[0], plain.size()])
	var dp = NetTransport.decode(plain)
	ok(dp != null and not dp.has("words"), "a packet without a word comes back without one")
	var withW: Dictionary = pk.duplicate()
	var w0: int = (1 << 26) - 1
	withW["words"] = PackedInt32Array([0, w0])
	var b: PackedByteArray = NetTransport.encode(withW)
	ok(b[0] == 3 and b.size() == plain.size() + 8, "a packet with a word: kind 3, 4 bytes an input (%d, %d)" % [b[0], b.size()])
	var dw = NetTransport.decode(b)
	ok(dw != null and dw.has("words") and dw.words == withW.words and dw.inputs == withW.inputs and float(dw.ts) == 1.0, "the words survive the round trip")
	var withAi: Dictionary = withW.duplicate()
	withAi["ai"] = [[1, 44]]
	var da = NetTransport.decode(NetTransport.encode(withAi))
	ok(da != null and da.words == withW.words and da.ai == [[1, 44]], "words and a takeover in one packet")
	var high: PackedByteArray = b.duplicate()
	high[1 + 1 + 4 + 4 + 4 + 1 + 16 + 4 + 3] = 0x04   # the second word's top byte: bit 26
	ok(NetTransport.decode(high) == null, "a word past 26 bits on the wire is refused")
	ok(NetTransport.decode(b.slice(0, b.size() - 30)) == null, "a truncated kind 3 packet is refused")
	var kind1: PackedByteArray = b.duplicate()
	kind1[0] = 1
	ok(NetTransport.decode(kind1) == null, "kind 1 with kind 3's body is refused")
	var over: Dictionary = pk.duplicate()
	over["words"] = PackedInt32Array([0, 1 << 26])
	ok(NetTransport.encode(over)[0] == 2, "a word past 26 bits isn't a game packet")
	var short: Dictionary = pk.duplicate()
	short["words"] = PackedInt32Array([1])
	ok(NetTransport.encode(short)[0] == 2, "words and inputs of different lengths aren't a game packet")


func prediction() -> void:
	var i := SimIntent.new()
	i.rsHeld = true
	i.rsDir = 4
	i.rsLevel = 3
	i.rsMask = 15
	i.rsAim = 31
	var held: int = SimIntent.pack2(i)
	ok(NetSession.predictWord(held) == held, "a prediction keeps every held field")
	i.rsStart = true
	i.rsRelease = true
	i.rsCancel = true
	i.rsLag = 15
	i.brace = true
	i.braceDir = 4
	var all: int = SimIntent.pack2(i)
	ok(all == (1 << SimIntent.BITS2) - 1 or all == held | 2 | 4 | 8 | (15 << 18) | (1 << 22) | (4 << 23), "every field of the word is set here, so a new one would show")
	ok(NetSession.predictWord(all) == held, "a prediction drops every edge")
	i.rsHeld = false
	ok(NetSession.predictWord(SimIntent.pack2(i)) == 0, "after a throw's last tick, the next is 0")
	ok(NetSession.predictWord(0) == 0, "no word predicts no word")
	var S := SimCore.createSim()
	SimCore.newMatch(S, SEED, {"p1": false, "p2": false}, {})
	var sess := NetSession.new(S, 0, DELAY)
	sess.addInput(1, DELAY, NetSession.NEUTRAL, held | 2)
	for t in range(DELAY + 4):
		sess.advance(NetSession.NEUTRAL)
	var ranWord: int = int(sess.usedW[1].get(DELAY + 1, 0))
	ok(ranWord == held, "the tick after a start ran with the held fields (%d)" % ranWord)
	var r0: int = sess.rollbacks
	sess.addInput(1, DELAY + 1, NetSession.NEUTRAL, held)
	sess.sync()
	ok(sess.rollbacks == r0, "a word the prediction got right rolls nothing back")
	var m0: int = sess.mispredicted
	sess.addInput(1, DELAY + 2, NetSession.NEUTRAL, 0)
	sess.sync()
	ok(sess.mispredicted == m0 + 1 and sess.rollbacks == r0 + 1, "a late word that differs rolls back though the first word agrees")
	sess.close()
	SimCore.dispose(S)


func digestRow(pname: String) -> void:
	var at: int = 180   # a checkpoint; the change is on the tick before it, since the next tick's intent replaces it
	for blind in [false, true]:
		NetDesync.wordBlind = blind
		var L := NetLoopback.make(SEED, {}, NetLoopback.PROFILES[pname], DELAY, SEED, 5, true)
		for k in range(2):
			L.peers[k].session.matchInfo = {"seed": SEED, "setup": {}, "ai": {"p1": false, "p2": false}}
		L.peers[1].session.perturb = func(S: SimState, t: int) -> void:
			if t == at - 1:
				S.fighters[0].input.rsLag = (S.fighters[0].input.rsLag + 1) & 15
		L.run(at + 120)
		var d0: Dictionary = L.peers[0].session.desync
		if blind:
			ok(d0.is_empty(), "%s: a digest that leaves the word out misses the change (the control)" % pname)
		else:
			ok(not d0.is_empty() and int(d0.tick) == at, "%s: a word changed before a checkpoint is reported there (%s)" % [pname, str(d0.get("tick", "none"))])
			if not d0.is_empty():
				var snap: NetSnapshot = L.peers[1].session.desync.snap if not L.peers[1].session.desync.is_empty() else null
				var rep: Dictionary = NetDesync.report(L.peers[0].session, snap)
				var named: bool = false
				for e in rep.get("vsPeer", []):
					named = named or String(e.path).ends_with("rsLag")
				ok(named, "%s: the field walk names it: %s" % [pname, str(rep.get("vsPeer", []))])
				ok(rep.get("vsReplay", ["x"]).is_empty(), "%s: the clean peer agrees with its own replay: %s" % [pname, str(rep.get("vsReplay", []))])
		L.close()
	NetDesync.wordBlind = false


func replayRow() -> void:
	var L := NetLoopback.make(SEED, {}, NetLoopback.PROFILES["p120"], DELAY, SEED, 7, true)
	var sess: NetSession = L.peers[0].session
	var info := {"seed": SEED, "setup": {}, "ai": {"p1": false, "p2": false}}
	L.run(ticks)
	var rp: Dictionary = NetDesync.replayOf(sess, info, ticks)
	var five: int = 0
	var last: int = -1
	for e in rp.inputs:
		if e.size() == 5:
			five += 1
			last = int(e[0])
		ok(e.size() == 4 or (e.size() == 5 and int(e[4]) > 0), "an entry holds its word only where it isn't 0")
	ok(five > 8, "the replay holds the words (%d entries)" % five)
	var back = JSON.parse_string(JSON.stringify(rp))
	var r: Dictionary = SimReplay.play(back)
	ok(r.ok, "the report's replay plays after JSON (%s)" % r.reason)
	var atWord: int = -1   # the first tick that follows a word still in the intent: a tick whose entry has one and the next tick's doesn't change it
	for e in rp.inputs:
		if e.size() == 5 and int(e[0]) > DELAY:
			atWord = int(e[0]) + 1
			break
	var snapS := NetDesync.replayState(back, atWord)
	var ref := straightPlain(atWord)
	ok(snapS != null and NetDesync.digest(snapS) == ref.digest and SimIntent.pack2(snapS.fighters[0].input) + SimIntent.pack2(snapS.fighters[1].input) != 0, "its re-simulated state has the straight run's digest, with a word in it")
	if snapS != null:
		SimCore.dispose(snapS)
	var bad: Dictionary = back.duplicate(true)
	for e in bad.inputs:
		if e.size() == 5 and int(e[0]) + 1 == atWord:
			e[4] = int(e[4]) ^ (1 << 13)
	var badS := NetDesync.replayState(bad, atWord)
	ok(badS != null and NetDesync.digest(badS) != ref.digest, "a changed word in the replay is caught")
	if badS != null:
		SimCore.dispose(badS)
	var old: Dictionary = back.duplicate(true)
	var kept: Array = []
	for e in old.inputs:
		kept.append(e.slice(0, 4))
	old.inputs = kept
	ok(SimReplay.play(old).ok, "four-number entries still play, as word 0")
	L.close()


## The sim's own run with no stand-in reader, to a tick, for the replay row.
func straightPlain(upto: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, SEED, {"p1": false, "p2": false}, {})
	var bots: Array = [NetBot.new(SEED, 0), NetBot.new(SEED, 1)]
	for t in range(upto):
		var ins: Array = []
		for k in range(2):
			ins.append(SimIntent.unpack(NetSession.NEUTRAL) if t < DELAY else NetSession.intentOf(bots[k].next(), bots[k].word))
		SimCore.step(S, ins)
		S.out.feed.clear()
		S.out.fx.clear()
	var out := {"digest": NetDesync.digest(S), "hash": SimHash.stateHash(S).gameplay}
	SimCore.dispose(S)
	return out


func keyRow() -> void:
	var on: String = NetHandshake.keyOf(SEED, {"p1": false, "p2": false}, {})
	NetBot.setRightStick(false)
	var off: String = NetHandshake.keyOf(SEED, {"p1": false, "p2": false}, {})
	NetBot.setRightStick(true)
	ok(on != off, "the match key says whether the switch is on")
	var r: Dictionary = NetLoopback.agree("", NetLoopback.PROFILES["lan"], [NetDelay.device(1.0), NetDelay.device(1.0)], 9, [on, off])
	ok(String(r.failed).contains("another match"), "peers on either side are refused at the handshake: %s" % r.failed)
	r = NetLoopback.agree("", NetLoopback.PROFILES["lan"], [NetDelay.device(1.0), NetDelay.device(1.0)], 9, [on, on])
	ok(r.failed == "", "the same key passes: %s" % r.failed)


func offRow() -> void:
	NetBot.setRightStick(false)
	var b := NetBot.new(SEED, 0)
	var any: int = 0
	for t in range(2000):
		b.next()
		any |= b.word
	ok(any == 0, "off: a bot writes no word")
	var L := NetLoopback.make(SEED, {}, NetLoopback.PROFILES["p80j"], DELAY, SEED, 3, true)
	L.run(120)
	ok(L.peers[0].session.words[0].is_empty() and L.peers[0].session.words[1].is_empty() and L.peers[0].session.localSince(0)[2].is_empty(), "off: a session holds and sends no word")
	L.close()
	var hs: Array = []
	var ds: Array = []
	for w in [0, 1 | (3 << 4) | (2 << 7)]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, SEED, {"p1": false, "p2": false}, {})
		var sess := NetSession.new(S, 0, DELAY)
		for t in range(60):
			sess.addInput(1, t + DELAY, NetSession.NEUTRAL, w)
			sess.advance(NetSession.NEUTRAL, w)
		hs.append(SimHash.stateHash(S).gameplay)
		ds.append(NetDesync.digest(S))
		sess.close()
		SimCore.dispose(S)
	ok(hs[0] == hs[1] and ds[0] == ds[1], "off: a word handed in reaches no hash and no digest")
	NetBot.setRightStick(true)


func _init() -> void:
	var negative: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--profiles="):
			profiles = Array(a.substr(11).split(","))
		elif a == "--negative-control":
			negative = true
	NetBot.setRightStick(true)
	print("Orb Combat EX word check   Godot %s   %d ticks   protocol %d%s" % [Engine.get_version_info().string, ticks, NetHandshake.PROTO, "   negative control" if negative else ""])
	var ref := straight(ticks)
	if negative:
		for pname in profiles:
			var lost := session(pname, ref, "lost")
			ok(int(lost.bad) > 0, "%s: words dropped on arrival must be caught" % pname)
			print("  control lost        %-5s bad ticks %4d, first at %d" % [pname, lost.bad, lost.first])
			if pname != "lan":
				var nr := session(pname, ref, "norollback")
				ok(int(nr.bad) > 0, "%s: a late word that doesn't roll back must be caught" % pname)
				print("  control no rollback %-5s bad ticks %4d, first at %d" % [pname, nr.bad, nr.first])
		digestRow(profiles[0])
	else:
		wire()
		prediction()
		ok(int(ref.used) > ticks / 4, "the bots use the word (%d of %d inputs)" % [ref.used, ticks * 2])
		for pname in profiles:
			var res := session(pname, ref)
			ok(res.ran and int(res.bad) == 0, "%s: %d confirmed ticks differ from the straight run, first at %d (peer %s)" % [pname, res.bad, res.first, str(res.get("who", ""))])
			print("  %-5s  bad ticks %d   rollbacks %4d   mispredicted %4d   deepest %2d   words held %4d   wire %d bytes" % [pname, res.bad, res.rollbacks, res.mis, res.depth, res.words, res.bytes])
		digestRow(profiles[1] if profiles.size() > 1 else profiles[0])
		replayRow()
		keyRow()
		offRow()
	print("word check %s: %d checks, %d failed" % ["passed" if fails == 0 else "FAILED", checks, fails])
	quit(0 if fails == 0 else 1)
