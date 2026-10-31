extends SceneTree
## A swing under rollback: the forced flip (docs/net/rollback.md section 15, docs/world/ring-any-angle/netcode.md). No director asks for a swing yet, so a stand-in does: on every run of a tick, a
## fighter whose last intent pressed Context asks for one, the first fighter one way and the second the other. Bots press it about 1% of ticks, and a prediction drops a press, so on a laggy link a peer
## runs ticks with no swing, or the other way round, and a late press flips it. As a director's decision would be, it is state derived from inputs; nothing new goes over the wire. A Signature press
## digs a crater into the planet store at the fighter's feet, so the store grows, and a rollback must take records back out.
##   godot --headless --path . --script res://net/tools/swing_check.gd [-- --ticks=600 --profiles=lan,p120,far --right-stick --one-way --negative-control]
## Passes (exit 0) only if:
##   - every profile: each peer's confirmed gameplay hash (which holds the line, the swing and the store) equals a straight run's, every --hash-every ticks; each checkpoint's digest equals the straight
##     run's and the peers agree on them; at the end the field walk finds nothing between the peers or against the straight run, poses included (the hash leaves those out);
##   - it was a real test: on a laggy profile, rollbacks changed the line, turned a swing on or off, and reversed one, at least once each, and the store held records;
##   - the digest: each of the line's and the swing's hashed fields, and the store's length and hash, changes the digest when changed one step; a swing changed on one peer before a checkpoint is reported
##     there and named by the walk.
##   - the rate rule (netcode.md section 3): data's flash governor x maxAhead is at most 20 degrees, and no rollback moved the line at the newest tick by more than twice that (one timeline turning each way).
## Prints each profile's correction: how far the line moved at the newest tick when a rollback ended, in degrees.
## --negative-control breaks it, and each must be caught: the swing's state or the line not restored by a rollback (the timeline being replaced is kept), the store not restored, late inputs ignored, a
## digest that leaves all of it out, and the rate cap lifted, which must break the bound.

const SETUP: Dictionary = {"planet": 7, "touch": 1, "planetGen": 3, "intro": false}
const SEED: int = 77
const DELAY: int = 2
const BOUND: float = 20.0   # degrees: rate x maxAhead, the most one timeline can run away (netcode.md section 3)

var fails: int = 0
var checks: int = 0
var ticks: int = 600
var hashEvery: int = 4
var profiles: Array = ["lan", "p120", "far"]
static var askRate: float = 60.0
static var askDeg: float = 40.0
static var oneWay: bool = false   # --one-way: both fighters ask the same way, so no ask reverses a running swing


func ok(c: bool, s: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  " + s)


## The stand-in for a director's ask, and for a blow's crater.
static func asker(S: SimState, _t: int = 0) -> void:
	for k in range(2):
		if S.fighters[k].input.sig:
			SimField.pointAt(S, S.fighters[k].x)
			WorldStore.add(S, SimField.ox, SimField.oy, SimField.oz, 300.0, 60.0, 0.0, 1.0, 0, k, S.T, 0)
		if S.fighters[k].input.context:
			SimSwing.ask(S, {"deg": askDeg if k == 0 or oneWay else -askDeg, "rate": askRate, "cause": "launch"})


## The great circle's normal: the same along one line wherever x0 stands, so two of them differ by the bearing and nothing else.
static func normal(fr) -> Array:
	return [fr.py * fr.tz - fr.pz * fr.ty, fr.pz * fr.tx - fr.px * fr.tz, fr.px * fr.ty - fr.py * fr.tx]


static func between(a: Array, b: Array) -> float:
	var cx: float = a[1] * b[2] - a[2] * b[1]
	var cy: float = a[2] * b[0] - a[0] * b[2]
	var cz: float = a[0] * b[1] - a[1] * b[0]
	return atan2(sqrt(cx * cx + cy * cy + cz * cz), a[0] * b[0] + a[1] * b[1] + a[2] * b[2]) * 180.0 / PI


func straight() -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, SEED, {"p1": false, "p2": false}, SETUP)
	var bots: Array = [NetBot.new(SEED, 0), NetBot.new(SEED, 1)]
	var hashes: Dictionary = {}
	var digests: Dictionary = {}
	var live: int = 0
	var asked: int = 0
	var storeMax: int = 0
	var at: int = -1   # a tick with a swing running at speed, for the field rows
	for t in range(ticks):
		if t % 60 == 0 and t > 0:
			digests[t] = NetDesync.digest(S)
		var ins: Array = []
		for k in range(2):
			ins.append(SimIntent.unpack(NetSession.NEUTRAL) if t < DELAY else NetSession.intentOf(bots[k].next(), bots[k].word))
		asker(S)
		SimCore.step(S, ins)
		S.out.feed.clear()
		S.out.fx.clear()
		live += 1 if S.swing.active else 0
		storeMax = maxi(storeMax, S.storeN)
		asked = S.swing.n
		if at < 0 and S.swing.active and S.swing.rate > 20.0:
			at = t
			fieldRows(S)
		if (t + 1) % hashEvery == 0:
			hashes[t + 1] = SimHash.stateHash(S).gameplay
	return {"S": S, "hash": hashes, "digest": digests, "live": live, "asked": asked, "store": storeMax}


## Every hashed field, one step: the digest must move, and with the digest blind it must not.
func fieldRows(S: SimState) -> void:
	var d0: String = NetDesync.digest(S)
	var rows: Array = []
	for k in SimState.Frame.HASHED:
		rows.append([S.frame, k])
	for k in SimSwing.HASHED:
		rows.append([S.swing, k])
	rows.append([S, "storeN"])
	rows.append([S, "storeHash"])
	for r in rows:
		var o = r[0]
		var k: String = r[1]
		var was = o.get(k)
		match typeof(was):
			TYPE_FLOAT:
				o.set(k, was + maxf(absf(was), 1e-3) * 2.3e-16)
			TYPE_INT:
				o.set(k, was + 1)
			TYPE_BOOL:
				o.set(k, not was)
			TYPE_STRING:
				o.set(k, was + "x")
		ok(NetDesync.digest(S) != d0, "the digest must read %s" % k)
		NetDesync.swingBlind = true
		var blind: String = NetDesync.digest(S)
		o.set(k, was)
		ok(NetDesync.digest(S) == blind, "the blind digest must not read %s (the control)" % k)
		NetDesync.swingBlind = false
		ok(NetDesync.digest(S) == d0, "%s put back" % k)


## Two peers, in verify mode. brk: "" or "swing", "frame", "store", "norollback". {bad, first, ...}
func session(pname: String, ref: Dictionary, brk: String = "") -> Dictionary:
	var L := NetLoopback.make(SEED, SETUP, NetLoopback.PROFILES[pname], DELAY, SEED, 3, true)
	var res := {"bad": 0, "first": -1, "ran": false, "flips": 0, "onoff": 0, "reversed": 0, "corr": PackedFloat64Array(), "digBad": 0}
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		sess.matchInfo = {"seed": SEED, "setup": SETUP, "ai": {"p1": false, "p2": false}}
		sess.verify = true
		sess.beforeTick = asker
		sess.rollbackOn = brk != "norollback"
		var seen: Dictionary = {}
		var lastLive: Dictionary = {}
		sess.perturb = func(S: SimState, t: int) -> void:
			var n: Array = normal(S.frame)
			var sw = S.swing
			if seen.has(t):
				var was: Array = seen[t]
				var a: float = between(was[0], n)
				if a > 0.0:
					res.flips = int(res.flips) + 1
				if bool(was[1]) != sw.active:
					res.onoff = int(res.onoff) + 1
				if bool(was[1]) and sw.active and float(was[2]) != sw.way:
					res.reversed = int(res.reversed) + 1
				if t == sess.frame - 1:
					res.corr.append(a)
			seen[t] = [n, sw.active, sw.way]
			for f in SimSwing.HASHED:
				lastLive[f] = sw.get(f)
			for f in SimState.Frame.HASHED:
				lastLive["fr." + f] = S.frame.get(f)
			lastLive["store"] = S.store.duplicate()
			lastLive["storeN"] = S.storeN
			lastLive["storeHash"] = S.storeHash
		if brk == "swing":
			sess.afterRestore = func(S: SimState) -> void:
				for f in SimSwing.HASHED:
					S.swing.set(f, lastLive[f])
		elif brk == "frame":
			sess.afterRestore = func(S: SimState) -> void:
				for f in SimState.Frame.HASHED:
					S.frame.set(f, lastLive["fr." + f])
		elif brk == "store":
			sess.afterRestore = func(S: SimState) -> void:
				S.store = lastLive["store"].duplicate()   # a log a rollback doesn't take records out of
				S.storeN = int(lastLive["storeN"])
				S.storeHash = int(lastLive["storeHash"])
		sess.onCheck = func(b: int, d: String) -> void:
			if ref.digest.has(b) and ref.digest[b] != d:
				res.digBad = int(res.digBad) + 1
		sess.onConfirmed = func(b: int, st: SimState, _o: String) -> void:
			if st != null and b % hashEvery == 0 and ref.hash.has(b) and SimHash.stateHash(st).gameplay != ref.hash[b]:
				res.bad = int(res.bad) + 1
				if int(res.first) < 0:
					res.first = b
	res.ran = L.run(ticks)
	var s0: NetSession = L.peers[0].session
	var s1: NetSession = L.peers[1].session
	res.rollbacks = s0.rollbacks + s1.rollbacks
	res.depth = maxi(s0.maxDepth, s1.maxDepth)
	res.desync = not s0.desync.is_empty() or not s1.desync.is_empty()
	res.matched = s0.checksMatched
	if brk == "":
		res.walk = NetDesync.firstDiffs(s0.S, s1.S)
		res.walkRef = NetDesync.firstDiffs(s0.S, ref.S)
	L.close()
	return res


func digestSession(pname: String, blind: bool) -> Dictionary:
	NetDesync.swingBlind = blind
	var L := NetLoopback.make(SEED, SETUP, NetLoopback.PROFILES[pname], DELAY, SEED, 5, true)
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		sess.matchInfo = {"seed": SEED, "setup": SETUP, "ai": {"p1": false, "p2": false}}
		sess.beforeTick = func(S: SimState, t: int) -> void:
			if t == 2:
				SimSwing.ask(S, {"deg": 500.0, "rate": 60.0, "cause": "launch"})   # still turning at the checkpoint
	L.peers[1].session.perturb = func(S: SimState, t: int) -> void:
		if t == 119:
			S.swing.left += maxf(absf(S.swing.left), 1e-3) * 2.3e-16
	L.run(300)
	var out := {"tick": int(L.peers[0].session.desync.get("tick", -1)), "tick1": int(L.peers[1].session.desync.get("tick", -1)), "paths": []}
	if out.tick >= 0 and not L.peers[1].session.desync.is_empty():
		var rep: Dictionary = NetDesync.report(L.peers[0].session, L.peers[1].session.desync.snap)
		for e in rep.vsPeer:
			out.paths.append(e.path)
	L.close()
	NetDesync.swingBlind = false
	return out


func _init() -> void:
	var negative: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--hash-every="):
			hashEvery = maxi(1, int(a.substr(13)))
		elif a.begins_with("--profiles="):
			profiles = Array(a.substr(11).split(","))
		elif a == "--right-stick":
			NetBot.setRightStick(true)
		elif a == "--one-way":
			oneWay = true
		elif a == "--negative-control":
			negative = true
	print("Orb Combat EX swing check   Godot %s   %d ticks   protocol %d   right stick %s%s" % [Engine.get_version_info().string, ticks, NetHandshake.PROTO, str(SimInputData.right_stick_on()), "   negative control" if negative else ""])
	var cap: float = float(SimSwing.data().flashRate) * float(NetSession.new(SimCore.createSim(), 0).maxAhead) / 60.0
	ok(cap <= BOUND, "the data's rate x maxAhead is within the rule: %.1f degrees" % cap)
	var ref := straight()
	print("straight: swings asked %d, ticks with one running %d of %d, store length at most %d" % [ref.asked, ref.live, ticks, ref.store])
	ok(int(ref.live) > ticks / 10, "swings ran (%d ticks)" % ref.live)
	ok(int(ref.store) > 0, "the store held records (%d)" % ref.store)
	if negative:
		for pname in profiles:
			if pname == "lan":
				continue
			for brk in ["swing", "frame", "store", "norollback"]:
				var r := session(pname, ref, brk)
				ok(int(r.bad) > 0, "%s: %s must be caught" % [pname, brk])
				print("  control %-10s %-5s bad hashes %4d, first at %d, digests off the straight run %d" % [brk, pname, r.bad, r.first, r.digBad])
		var pn: String = profiles[profiles.size() - 1]
		var b := digestSession(pn, true)
		ok(b.tick < 0, "%s: a digest that leaves out the swing must miss the change (reported at %d)" % [pn, b.tick])
		var d: Dictionary = SimSwing.data()
		d.limitOff = true
		d.flashRate = 2000.0
		d.small.peak = 2000.0
		d.causes.launch.peak = 2000.0
		d.causes.launch["in"] = 1.0   # no ease: a turn this large done within a rollback's depth, one timeline turned and the other not
		d.causes.launch.out = 1.0
		askRate = 2000.0
		askDeg = 170.0
		var u := session(pn, {"digest": {}, "hash": {}, "S": null}, "uncapped")
		var uc: PackedFloat64Array = u.corr
		uc.sort()
		var uw: float = uc[uc.size() - 1] if uc.size() > 0 else 0.0
		ok(uw > BOUND * 2.0, "%s: the rate cap lifted must break the bound (worst %.1f degrees)" % [pn, uw])
		print("  control uncapped   %-5s worst %.1f degrees against the bound %.0f" % [pn, uw, BOUND * 2.0])
	else:
		var flips: int = 0
		var onoff: int = 0
		var reversed: int = 0
		for pname in profiles:
			var r := session(pname, ref)
			ok(r.ran and int(r.bad) == 0, "%s: %d hashes differ from the straight run, first at %d" % [pname, r.bad, r.first])
			ok(not r.desync and int(r.digBad) == 0 and int(r.matched) > 0, "%s: digests: desync %s, off the straight run %d, matched %d" % [pname, str(r.desync), r.digBad, r.matched])
			ok(r.walk.is_empty(), "%s: the walk between the peers: %s" % [pname, str(r.walk)])
			ok(r.walkRef.is_empty(), "%s: the walk against the straight run: %s" % [pname, str(r.walkRef)])
			flips += int(r.flips)
			onoff += int(r.onoff)
			reversed += int(r.reversed)
			var c: PackedFloat64Array = r.corr
			c.sort()
			var nz: int = 0
			for x in c:
				nz += 1 if x > 0.0 else 0
			var p50: float = c[c.size() / 2] if c.size() > 0 else 0.0
			var p99: float = c[mini(c.size() - 1, c.size() * 99 / 100)] if c.size() > 0 else 0.0
			var mx: float = c[c.size() - 1] if c.size() > 0 else 0.0
			ok(mx <= BOUND * 2.0, "%s: the worst correction is within the rate rule (%.3f degrees)" % [pname, mx])
			print("  %-5s rollbacks %4d  deepest %2d   line changed on %4d re-run ticks, on or off %3d, reversed %3d   at a rollback's end, degrees: moved %d of %d, p50 %.3f, p99 %.3f, worst %.3f" % [pname, r.rollbacks, r.depth, r.flips, r.onoff, r.reversed, nz, c.size(), p50, p99, mx])
		if profiles.size() > 1:
			ok(flips > 0 and onoff > 0 and (reversed > 0 or oneWay), "the flips happened: the line %d, on or off %d, reversed %d" % [flips, onoff, reversed])
		var pn: String = profiles[profiles.size() - 1]
		var d := digestSession(pn, false)
		ok(d.tick == 120 and d.tick1 == 120, "%s: a swing changed before a checkpoint is reported there by both peers (%d, %d)" % [pn, d.tick, d.tick1])
		ok(d.paths.has("S.swing.left"), "%s: the walk names it: %s" % [pn, str(d.paths)])
	SimCore.dispose(ref.S)
	print("swing check %s: %d checks, %d failed" % ["passed" if fails == 0 else "FAILED", checks, fails])
	quit(0 if fails == 0 else 1)
