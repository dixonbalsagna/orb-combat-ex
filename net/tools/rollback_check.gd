extends SceneTree
## The rollback core's determinism check (docs/net/rollback.md section 6). For each seed it plays a straight,
## non-networked replay of the bots' inputs (SimReplay's recorder, so the run is a replay file too, which SimReplay.play
## then verifies), and for each network profile two peers over the loopback (net/loopback.gd), in verify mode. Passes
## (exit 0) only if, at every confirmed tick of both peers:
##   - SimHash.stateHash's gameplay hash equals the straight run's at that tick (every --hash-every ticks; 1 by default),
##   - the tick's feed lines and fx events (the director's decisions as the host sees them) equal the straight run's,
## and both peers' confirmed input logs and final states equal the straight run's, and neither peer's desync detection
## (NetSession.checkEvery, on at its default) fired. It also checks the state graph has no
## shared plain containers (NetSnapshot.aliasAudit) and that sessions free their objects.
##   godot --headless --path . --script res://net/tools/rollback_check.gd -- [--seeds=1,2,3] [--ticks=1200]
##     [--profiles=lan,p80j,...|all] [--setup=default|features|planet|calm] [--delay=2|auto] [--devices=1,1]
##     [--hash-every=1] [--sparse=K] [--negative-control]
##     [--takeover=T [--slot=K] [--by=owner|other|both]] [--drop=F [--slot=K] [--timeout=N]]
##     [--ai-level=easy|medium|hard]
## --delay=auto runs each profile at the delay its handshake agrees (NetLoopback.agree: both peers ping over links of
## that profile, propose NetDelay.choose for their own device, --devices' slowdowns, and the larger wins), against a
## straight run with that delay.
## --sparse=K runs the sessions as a game would (not in verify mode): a save only before a predicted tick, at most one
## every K ticks. The feed and fx of every confirmed tick and the final states are still compared; the SimHash only at
## the confirmed ticks whose state the session still holds (a save, or the present).
## --negative-control breaks the session on purpose, twice (a restore that leaves one bit of the RNG wrong; late inputs
## that never roll back), and passes only if the check catches both on every profile where an input arrived late.
##
## --ai (docs/net/rollback.md section 12): each slot's input comes from the fighter AI (NetAiDriver), run on its own peer
## from that peer's present state (predictions included) to a KO. --ticks is then the cap (45000 by default) and a run
## stops --tail ticks (120) after the KO. The inputs depend on what each peer saw, so the straight run replays the
## confirmed inputs the peers agreed on; and on every profile where no prediction was wrong (lan always), it also runs the
## AI itself, from the straight state, and its inputs must equal the peers' (the AI reads nothing the state does not
## carry). Each setup is played with v2 slots (the AI states its stance through held fields). With --negative-control it
## plants a third break, "impure": peer 0's AI runs on its live state, so its writes (S.rng draws, its timers) reach that
## sim alone; it must be caught on every profile.
## --ai=sim plays P2 as the sim's own AI (newMatch's ai flag): it runs inside every tick on the peer's state and is run
## again by every rollback, so it is rollback-safe only if the snapshot restores everything it reads and writes. P1 is the
## driver's, so inputs still arrive late. The "impure" break is P1's.
## In AI mode a planet setup with the calm turn (calm) is followed through its turns: each peer's confirmed states give
## the tick a turn was decided and the tick it swapped, every confirmed tick from the decision to 60 ticks after the swap
## is compared by its full SimHash, 60 ticks after each swap the whole state is walked field by field against the
## straight run's (NetDesync.firstDiffs: unhashed fields too), and the line counts the rollbacks that ran the swap
## again, that restored a state inside the turn's warm and preparation, and that ran any of those ticks again, and the
## slowest frame whose rollback ran a swap again (rollback.md section 13). The director's calm turn is off in the data
## (interrupts.json calmTurn.enabled), so no turn comes by itself:
##   --calm-director switches it on in this process (in memory, as parity.gd's gen 2 case does): the director asks World
##     in the tick, and its hold decides the swap;
##   --turn-at=N decides a turn before tick N on every run of it (the peers' first runs and re-runs, and the straight
##     run), as two_states_check's TURN_AT does, and World's own calm decides the swap.
##
## --takeover=T (rollback.md section 13): slot --slot (1, or 0 with --ai=sim) becomes the sim's own AI at tick T, agreed
## in the protocol. The proposer is the slot's own peer (a player who leaves) or the other (a host told the player left),
## --by; bot mode runs both. The proposer's player calls NetSession.proposeTakeover when its frame is T - delay, so the
## takeover lands at T, and every confirmed tick must equal a straight run that toggles the slot before tick T and plays
## it neutral from T. With --negative-control it plants "late" (the peer that did not propose switches at T + 1:
## caught wherever tick T is live; on a frozen tick no control runs, so the later switch gives the same state) and "once" (the proposer switches on tick T's first run only, not when a rollback runs it again:
## caught wherever a rollback ran tick T again).
## --drop=F: the slot's peer vanishes at loopback frame F (it runs, sends and receives nothing more; its packets in flight
## still land). The other peer drops the slot after --timeout frames (30) with no packet (NetSession.dropSlot): from its
## frame + delay the slot is the AI's, and its missing inputs below that are the ones its ticks ran with. The survivor's
## every confirmed tick must equal the straight replay of its confirmed inputs with the toggle at that tick. With
## --negative-control it plants "fill" (the missing inputs filled neutral, not with what the ticks ran with, and nothing
## rolled back): caught wherever those differ.

const SETUPS: Dictionary = {
	"default": {},
	"features": {"v2": [true, true], "forms": true, "brake": true, "flight": true, "hitstop": true, "ricochet": true},
	"planet": {"planet": 7, "touch": 3},
	"calm": {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}},   # the calm-moment turn: World's statics keyed by world
	"depth": {"depth": true},   # fight lanes: depth physical (data/combat/depth.json's switch, on for this match)
	"planet2": {"planet": 7, "touch": 3, "arena": {"cols": 2400}, "planetGen": 2, "intro": false},   # a gen 2 ring, as QA plays them (qa/godot/qa_planet.gd)
	"planet2depth": {"planet": 7, "touch": 3, "arena": {"cols": 2400}, "planetGen": 2, "intro": false, "depth": true},
}

## Containers the state reaches by two paths that are only read, never written in place (checked by reading the code,
## 2026-10-28): a snapshot splits them into two equal copies, which changes nothing. World's ring axis vectors: a turn
## replaces the ring and its vectors whole (world/epoch.gd, world/ringpick.gd). A gen 2 ring's fine biomes (checked
## 2026-10-28, ai-depth): S.fineCols and S.planetRing["fine"] are both the slice's array (core/sim.gd, world/planet_world.gd),
## and the calm turn builds a new one and sets both (world/epoch.gd); nothing writes either in place. A decided turn's
## ring (checked 2026-10-29, ai-takeover): WorldEpoch.choose puts the candidate's spec in E.next and in E.warm[0] (and
## tick() points E.next.spec at the warm ring it swaps on); the warm ticks write w.cols and w.ptk and tick() writes keys of
## E.next, never a spec, and ringFrom and turned only read one. Any other sharing fails the check.
const READ_ONLY_SHARED: Array = ["S.planetRing[c] and S.epoch[c0]", "S.planetRing[c] and S.epoch[ring][c]", "S.planetRing[t] and S.epoch[ring][t]", "S.fineCols and S.planetRing[fine]",
	"S.epoch[next][spec] and S.epoch[warm][0][spec]", "S.epoch[next][spec] and S.epoch[warm][1][spec]"]
const TURN_TAIL: int = 60   # AI mode: the full SimHash on every confirmed tick from a turn's decision to this many after its swap

var failures: int = 0
var sabotage: String = ""   # the negative control's current break: "", "restore", "norollback", "impure", "late", "once", "fill"
var sparse: int = 0         # 0: verify mode; K: the game's saving, one save at most every K ticks
var devices: Array = [NetDelay.device(1.0), NetDelay.device(1.0)]
var refs: Dictionary = {}   # [seed, delay, takeAt] -> the straight run
var aiMode: bool = false    # --ai: the fighter AI drives every slot, to a KO
var aiSim: bool = false     # --ai=sim: P2 is the sim's own AI (inside the tick, re-run by rollbacks); P1 the driver's
var aiFlags: Dictionary = {"p1": false, "p2": false}
var aiLevel: String = ""     # --ai-level: the computer's level, in the match setup as the start menu puts it
var tail: int = 120         # --ai: ticks played on after the KO
var takeAt: int = -1        # --takeover=T: the slot becomes the sim's AI at tick T
var takeSlot: int = -1      # --slot=K
var by: String = ""         # --by: who proposes the takeover (owner, other, both)
var dropAt: int = -1        # --drop=F: the slot's peer vanishes at loopback frame F
var timeout: int = 30       # --timeout=N: frames with no packet before the survivor drops the slot
var turnAt: int = -1        # --turn-at=N: a calm turn decided before tick N
var walkTicks: Dictionary = {}   # --walk-at=B,...: walk the peers' confirmed states after these ticks against the straight run's (a diagnosis; log mode)


## A player who hands a slot to the sim's AI at tick `at` (the test's signal that the slot's player left): when its
## session's frame is at - delay it proposes the takeover (NetSession.proposeTakeover, which lands at frame + delay),
## then answers as `inner` (a NetBot or a NetAiDriver) does.
class TakePlayer:
	var inner
	var session: NetSession
	var slot: int
	var at: int
	var proposed: int = -1

	func _init(inner_, session_: NetSession, slot_: int, at_: int) -> void:
		inner = inner_
		session = session_
		slot = slot_
		at = at_

	func next() -> int:
		if proposed < 0 and session.frame >= at - session.delay:
			proposed = session.proposeTakeover(slot)
		return inner.next()

	func close() -> void:
		if inner.has_method("close"):
			inner.close()


func _init() -> void:
	var seeds: Array = [1, 2, 3, 4]
	var ticks: int = -1
	var profiles: Array = NetLoopback.PROFILES.keys()
	var setupName: String = "default"
	var delay: int = 2
	var hashEvery: int = -1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--profiles=") and a.substr(11) != "all":
			profiles = Array(a.substr(11).split(","))
		elif a.begins_with("--setup="):
			setupName = a.substr(8)
		elif a.begins_with("--delay="):
			delay = -1 if a.substr(8) == "auto" else int(a.substr(8))
		elif a.begins_with("--devices="):
			devices = Array(a.substr(10).split(",")).map(func(s): return NetDelay.device(float(s)))
		elif a.begins_with("--hash-every="):
			hashEvery = maxi(1, int(a.substr(13)))
		elif a.begins_with("--sparse="):
			sparse = maxi(1, int(a.substr(9)))
		elif a == "--negative-control":
			sabotage = "on"
		elif a == "--ai" or a == "--ai=sim":
			aiMode = true
			aiSim = a == "--ai=sim"
			if aiSim:
				aiFlags = {"p1": false, "p2": true}
		elif a.begins_with("--tail="):
			tail = maxi(1, int(a.substr(7)))
		elif a.begins_with("--takeover="):
			takeAt = int(a.substr(11))
		elif a.begins_with("--slot="):
			takeSlot = clampi(int(a.substr(7)), 0, 1)
		elif a.begins_with("--by="):
			by = a.substr(5)
		elif a.begins_with("--drop="):
			dropAt = maxi(1, int(a.substr(7)))
		elif a.begins_with("--timeout="):
			timeout = maxi(1, int(a.substr(10)))
		elif a.begins_with("--turn-at="):
			turnAt = maxi(1, int(a.substr(10)))
		elif a.begins_with("--walk-at="):
			for w in a.substr(10).split(","):
				walkTicks[int(w)] = true
		elif a.begins_with("--ai-level="):
			aiLevel = a.substr(11)
		elif a == "--calm-director":
			DirInterrupt.data().calmTurn.enabled = true   # this process only: the data file says false
	if ticks < 0:
		ticks = 45000 if aiMode else 1200
	if hashEvery < 0:
		hashEvery = 60 if aiMode else 1
	if takeSlot < 0:
		takeSlot = 0 if aiSim else 1   # with --ai=sim, P2 is the AI already
	if by == "":
		by = "owner" if aiMode else "both"
	var setup: Dictionary = SETUPS[setupName]
	if aiLevel != "":
		setup = setup.duplicate()
		setup["aiLevel"] = aiLevel
	if aiMode:
		setup = setup.duplicate(true)
		setup["v2"] = [true, true]
	if takeAt >= 0 and (takeAt <= maxi(delay, 2) or takeAt >= ticks or dropAt >= 0):
		print("FAIL  --takeover=%d needs a tick past the input delay and below --ticks, and no --drop" % takeAt)
		quit(1)
		return
	print("Orb Combat EX rollback check   Godot %s   setup %s   %d ticks   delay %s   hash every %d   %s" % [Engine.get_version_info().string, setupName, ticks, str(delay) if delay >= 0 else "auto (handshake)", hashEvery, "verify mode" if sparse == 0 else "sparse saving, every %d" % sparse])
	if aiMode:
		print("fighter AI on every slot (%s), cap %d ticks, tail %d" % ["P1 NetAiDriver, P2 the sim's own AI" if aiSim else "NetAiDriver", ticks, tail])
	if takeAt >= 0:
		print("takeover: slot %d becomes the sim's AI at tick %d, proposed by %s" % [takeSlot, takeAt, "its own peer" if by == "owner" else ("the other peer" if by == "other" else "its own peer, then the other")])
	if dropAt >= 0:
		print("drop: slot %d's peer vanishes at frame %d; the other drops the slot after %d frames with no packet" % [takeSlot, dropAt, timeout])
	if turnAt >= 0 or bool(DirInterrupt.data().calmTurn.get("enabled", false)):
		print("calm turn: %s" % ("decided before tick %d on every run" % turnAt if turnAt >= 0 else "the director's, switched on in this process"))
	if sabotage != "":
		if takeAt >= 0 or dropAt >= 0:
			_takeNegative(seeds, setup, ticks, delay, hashEvery, profiles)
		elif aiMode:
			_aiNegative(seeds, setup, ticks, delay, hashEvery, profiles)
		else:
			_negative(seeds, setup, ticks, delay, hashEvery, profiles)
		return
	if aiMode or dropAt >= 0 or not walkTicks.is_empty():
		_logMain(seeds, setupName, setup, ticks, delay, hashEvery, profiles)
		return
	var objects0: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var sessions: int = 0
	var hashed: int = 0
	for seed in seeds:
		for pname in profiles:
			var d: int = _delayFor(seed, setupName, setup, pname, delay)
			if d < 0:
				continue
			var ref := _ref(seed, setup, ticks, d, hashEvery)
			for who in _proposers():
				var res := _session(seed, setup, ticks, d, hashEvery, NetLoopback.PROFILES[pname], ref, who)
				sessions += 1
				hashed += int(res.hashed)
				var tag: String = "ok  " if res.err == "" else "FAIL"
				var take: String = ("" if who < 0 else "  takeover by peer %d, late at %d peer(s)" % [who, res.late]) + res.turns
				print("  %s %-6s  delay %d  hashes %5d  outs %5d  rollbacks %5d  resim %6d  max depth %2d  stalls %4d  lost %4d/%d%s  %s" % [tag, pname, d, res.hashed, res.outs, res.rollbacks, res.resim, res.maxDepth, res.stalls, res.lost, res.sent, take, res.err])
				if res.err != "":
					failures += 1
	_worldCaches()
	var objects1: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	print("objects alive before %d, after %d" % [objects0, objects1])
	if objects1 > objects0 + 50:
		print("FAIL  sessions leak objects (%d more)" % (objects1 - objects0))
		failures += 1
	if sessions == 0:
		print("FAIL  no session ran")
		failures += 1
	print("%s  %d sessions, %d confirmed-tick hash comparisons, %d failure(s)" % ["PASS" if failures == 0 else "FAIL", sessions, hashed, failures])
	quit(0 if failures == 0 else 1)


## The peers that propose the takeover, one session each ([-1]: no takeover).
func _proposers() -> Array:
	if takeAt < 0:
		return [-1]
	if by == "owner":
		return [takeSlot]
	if by == "other":
		return [1 - takeSlot]
	return [takeSlot, 1 - takeSlot]


## Each break must be caught on every profile that rolls back (lan never does, so it is skipped).
func _negative(seeds: Array, setup: Dictionary, ticks: int, delay: int, hashEvery: int, profiles: Array) -> void:
	var missed: int = 0
	var caught: int = 0
	for seed in seeds:
		for brk in ["restore", "norollback"]:
			for pname in profiles:
				if pname == "lan":
					continue
				sabotage = ""
				var d: int = _delayFor(seed, "", setup, pname, delay)
				if d < 0:
					continue
				var ref := _ref(seed, setup, ticks, d, hashEvery)
				sabotage = brk
				var res := _session(seed, setup, ticks, d, hashEvery, NetLoopback.PROFILES[pname], ref)
				if res.mispred == 0:
					continue   # every input arrived in time: nothing was predicted wrong, so nothing to catch
				print("  %s %-10s %-6s  delay %d  %s" % ["caught" if res.err != "" else "MISSED", brk, pname, d, res.err])
				if res.err == "":
					missed += 1
				else:
					caught += 1
	print("%s  negative control: %d break(s) caught, %d missed" % ["PASS" if missed == 0 and caught > 0 else "FAIL", caught, missed])
	quit(0 if missed == 0 and caught > 0 else 1)


## The delay a profile's session runs at: the fixed one, or (fixed < 0) the one its handshake agrees; -1 on a failed
## handshake (a failure, counted).
func _delayFor(seed: int, setupName: String, setup: Dictionary, pname: String, fixed: int) -> int:
	if fixed >= 0:
		return fixed
	var ag: Dictionary = NetLoopback.agree(NetHandshake.keyOf(seed, aiFlags, setup), NetLoopback.PROFILES[pname], devices, seed * 131 + int(NetLoopback.PROFILES[pname].ping))
	if setupName != "":
		print("  handshake %-6s  proposals %d and %d -> delay %d   rtt median %.0f, %.0f ms   %d frames  %s" % [pname, ag.proposals[0], ag.proposals[1], ag.delay, ag.rttMedian[0], ag.rttMedian[1], ag.frames, ag.failed])
	if ag.failed != "" or ag.delay != maxi(ag.proposals[0], ag.proposals[1]):
		print("FAIL  handshake on %s: %s" % [pname, ag.failed if ag.failed != "" else "the delay is not the larger proposal"])
		failures += 1
		return -1
	return ag.delay


## The straight run for (seed, delay), made once and checked when made.
func _ref(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int) -> Dictionary:
	var key: Array = [seed, delay, takeAt]
	if refs.has(key):
		return refs[key]
	var ref := _straight(seed, setup, ticks, delay, hashEvery)
	if sabotage == "":
		print("seed %d  delay %d  straight: %d exchanges, %d ticks with feed or fx, replay %s, KO %s, aliases %s%s" % [seed, delay, ref.exN, ref.outTicks, "verified" if ref.replayOk else "FAILED", ref.ko, "none" if ref.aliases.is_empty() else str(ref.aliases), "" if takeAt < 0 else ", slot %d the AI's from tick %d" % [takeSlot, takeAt]])
		if not ref.replayOk or not ref.aliases.is_empty():
			failures += 1
	refs[key] = ref
	return ref


## The straight run: the same inputs, no network. {hash: tick -> gameplay hash, out: tick -> digest, final, inputs,
## exN, outTicks, replayOk, aliases, ko}. With --takeover the slot is toggled to the sim's AI before tick takeAt (the
## replay records the toggle) and plays neutral from it, as the session's confirmed inputs say.
func _straight(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int) -> Dictionary:
	var S := SimCore.createSim()
	var rec := SimReplay.recorder(S, seed, {"p1": false, "p2": false}, setup)
	var bots: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var hashes: Dictionary = {}
	var outs: Array = []
	var log: Array = [[], []]
	var aliases: Array = NetSnapshot.aliasAudit(S)
	var outTicks: int = 0
	for t in range(ticks):
		if t == takeAt:
			rec.toggle(takeSlot)
		var ins: Array = []
		for k in range(2):
			var p: int = NetSession.NEUTRAL if t < delay else bots[k].next()
			if takeAt >= 0 and k == takeSlot and t >= takeAt:
				p = NetSession.NEUTRAL
			log[k].append(p)
			ins.append(SimIntent.unpack(p))
		if turnAt >= 0:
			_forceTurn(S, t)
		rec.step(ins)
		var d: String = NetSession.outDigest(S)
		if d != "":
			outTicks += 1
		outs.append(d)
		S.out.feed.clear()
		S.out.fx.clear()
		if (t + 1) % hashEvery == 0 or t + 1 == ticks:
			hashes[t + 1] = SimHash.stateHash(S).gameplay
		if t + 1 == ticks / 2:
			aliases += NetSnapshot.aliasAudit(S)
	aliases += NetSnapshot.aliasAudit(S)
	aliases = aliases.filter(func(a): return not READ_ONLY_SHARED.has(a))
	var rp: Dictionary = rec.finish()
	var play: Dictionary = SimReplay.play(rp)
	var ref := {"hash": hashes, "out": outs, "final": hashes[ticks], "log": log, "exN": S.dirS.exN, "outTicks": outTicks,
		"replayOk": (play.ok and play.final == hashes[ticks]) or turnAt >= 0, "aliases": aliases, "ko": S.game.ko != null}   # a forced turn is not an input: no replay holds it
	SimCore.dispose(S)
	return ref


## The tests-only breaks a session carries for the current sabotage. A takeover's breaks: "late" on the peer that did not
## propose, "once" on the proposer; the drop's "fill" on the survivor.
func _plant(sess: NetSession, k: int, proposer: int) -> void:
	match sabotage:
		"restore":
			sess.afterRestore = func(S_: SimState) -> void: S_.rng.a ^= 1
		"norollback":
			sess.rollbackOn = false
		"late":
			if k != proposer:
				sess.aiLate = 1
		"once":
			if k == proposer:
				sess.aiOnce = true
		"fill":
			sess.fillWrong = true


func _session(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int, profile: Dictionary, ref: Dictionary, proposer: int = -1) -> Dictionary:
	var L := NetLoopback.make(seed, setup, profile, delay, seed, seed * 31 + int(profile.ping))
	var res := {"err": "", "hashed": 0, "outs": 0, "rollbacks": 0, "resim": 0, "maxDepth": 0, "mispred": 0, "stalls": 0, "lost": 0, "sent": 0, "late": 0, "turns": ""}
	var recs: Array = []   # per peer: its calm turns and rollbacks (_turnTrack, _turnLine)
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		sess.verify = sparse == 0
		sess.saveEvery = maxi(1, sparse)
		_plant(sess, k, proposer)
		if k == proposer:
			L.peers[k].bot = TakePlayer.new(L.peers[k].bot, sess, takeSlot, takeAt)
		if turnAt >= 0:
			sess.beforeTick = _forceTurn
		var r := {"rb": [], "win": [], "open": -1, "n": 0, "lastSwap": -1}
		recs.append(r)
		sess.onRollback = func(s: int, f: int) -> void: r.rb.append([s, f, 0])
		sess.onConfirmed = func(b: int, st, out: String) -> void:
			if st != null and st.epoch != null:
				_turnTrack(r, b, st.epoch)
			if res.err != "":
				return
			if out != ref.out[b - 1]:
				res.err = "peer %d: tick %d's feed and fx differ from the straight run" % [k, b]
				return
			res.outs += 1
			if ref.hash.has(b):
				if st == null:
					if sparse == 0:
						res.err = "peer %d: no state for confirmed tick %d" % [k, b]
					return
				if SimHash.stateHash(st).gameplay != ref.hash[b]:
					res.err = "peer %d: SimHash differs from the straight run after tick %d" % [k, b]
					return
				res.hashed += 1
	if not L.run(ticks):
		res.err = "did not confirm %d ticks in %d frames" % [ticks, L.frames]
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		res.rollbacks += sess.rollbacks
		res.resim += sess.resimTicks
		res.mispred += sess.mispredicted
		res.maxDepth = maxi(res.maxDepth, sess.maxDepth)
		res.stalls += sess.stalls
		res.lost += L.links[k].lost
		res.sent += L.links[k].sent
		res.late += 1 if sess.takeoverLate > 0 else 0
		if res.err == "" and not sess.desync.is_empty() and sabotage == "":
			res.err = "peer %d: desync detection fired at checkpoint %d" % [k, sess.desync.tick]
		if res.err == "" and proposer >= 0 and int(sess.aiFrom.get(takeSlot, -1)) != takeAt:
			res.err = "peer %d: the takeover is at tick %d, not %d" % [k, int(sess.aiFrom.get(takeSlot, -1)), takeAt]
		if res.err == "":
			if SimHash.stateHash(sess.S).gameplay != ref.final:
				res.err = "peer %d: final state differs from the straight run" % k
			else:
				for slot in range(2):
					for t in range(ticks):
						if res.err == "" and (not sess.hasInput(slot, t) or sess.confirmedInput(slot, t) != int(ref.log[slot][t])):
							res.err = "peer %d: confirmed input of slot %d at tick %d differs" % [k, slot, t]
	res.turns = _turnLine(recs, [0, 1], PackedInt32Array())
	L.close()
	return res


## --ai, and --drop: every seed on every profile (to a KO with the AI), against the straight replay of the inputs the
## peers confirmed.
func _logMain(seeds: Array, setupName: String, setup: Dictionary, cap: int, delay: int, hashEvery: int, profiles: Array) -> void:
	var objects0: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var sessions: int = 0
	var hashed: int = 0
	var digests: int = 0
	var kos: int = 0
	var own: int = 0
	for seed in seeds:
		for pname in profiles:
			var d: int = _delayFor(seed, setupName, setup, pname, delay)
			if d < 0:
				continue
			for who in _proposers():
				var t0: int = Time.get_ticks_msec()
				var res := _logSession(seed, setup, cap, d, hashEvery, pname, who)
				sessions += 1
				hashed += int(res.hashed)
				digests += int(res.digests)
				kos += 1 if res.ko >= 0 else 0
				own += 1 if res.own else 0
				var tag: String = "ok  " if res.err == "" else "FAIL"
				print("  %s seed %d %-6s  delay %d  KO %s  ticks %5d  exchanges %4d  digests %5d  hashes %4d  rollbacks %5d  resim %6d  max depth %2d  stalls %4d  lost %4d/%d%s%s%s%s  %.0f s  %s" % [tag, seed, pname, d, "tick %d" % res.ko if res.ko >= 0 else "none", res.until, res.exN, res.digests, res.hashed, res.rollbacks, res.resim, res.maxDepth, res.stalls, res.lost, res.sent, "  AI straight %s" % ("same" if res.own else "-") if aiMode else "", res.take, res.turns, res.walk, (Time.get_ticks_msec() - t0) / 1000.0, res.err])
				if res.err != "":
					failures += 1
	_worldCaches()
	var objects1: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	print("objects alive before %d, after %d" % [objects0, objects1])
	if objects1 > objects0 + 50:
		print("FAIL  sessions leak objects (%d more)" % (objects1 - objects0))
		failures += 1
	if sessions == 0:
		print("FAIL  no session ran")
		failures += 1
	if aiMode:
		print("%s  %d AI sessions, %d reached a KO, %d also matched the AI's own straight run, %d confirmed-tick digest and %d SimHash comparisons (every %d ticks), %d failure(s)" % ["PASS" if failures == 0 else "FAIL", sessions, kos, own, digests, hashed, hashEvery, failures])
	else:
		print("%s  %d sessions, %d confirmed-tick digest and %d SimHash comparisons, %d failure(s)" % ["PASS" if failures == 0 else "FAIL", sessions, digests, hashed, failures])
	quit(0 if failures == 0 else 1)


## --ai --negative-control: each break must be caught; "restore" and "norollback" wherever an input arrived late,
## "impure" everywhere.
func _aiNegative(seeds: Array, setup: Dictionary, cap: int, delay: int, hashEvery: int, profiles: Array) -> void:
	var missed: int = 0
	var caught: int = 0
	for seed in seeds:
		for brk in ["impure", "restore", "norollback"]:
			for pname in profiles:
				if pname == "lan" and brk != "impure":
					continue
				sabotage = ""
				var d: int = _delayFor(seed, "", setup, pname, delay)
				if d < 0:
					continue
				sabotage = brk
				var res := _logSession(seed, setup, cap, d, hashEvery, pname)
				if brk != "impure" and res.mispred == 0:
					continue
				print("  %s %-10s seed %d %-6s  delay %d  %s" % ["caught" if res.err != "" else "MISSED", brk, seed, pname, d, res.err])
				if res.err == "":
					missed += 1
				else:
					caught += 1
	sabotage = ""
	print("%s  AI negative control: %d break(s) caught, %d missed" % ["PASS" if missed == 0 and caught > 0 else "FAIL", caught, missed])
	quit(0 if missed == 0 and caught > 0 else 1)


## --takeover or --drop with --negative-control: "late" must be caught on every profile; "once" wherever a rollback on the
## proposer ran tick T again; "fill" wherever a filled input differs from the one its tick ran with.
func _takeNegative(seeds: Array, setup: Dictionary, cap: int, delay: int, hashEvery: int, profiles: Array) -> void:
	var missed: int = 0
	var caught: int = 0
	var skipped: int = 0
	var breaks: Array = ["fill"] if dropAt >= 0 else ["late", "once"]
	for seed in seeds:
		for brk in breaks:
			for pname in profiles:
				sabotage = ""
				var d: int = _delayFor(seed, "", setup, pname, delay)
				if d < 0:
					continue
				sabotage = brk
				var who: int = -1 if dropAt >= 0 else takeSlot
				var res := _logSession(seed, setup, cap, d, hashEvery, pname, who)
				var applies: bool = (brk == "late" and res.liveT) or (brk == "once" and res.crossT) or (brk == "fill" and res.fillDiff > 0)
				if not applies:
					skipped += 1
					print("  n/a    %-6s seed %d %-6s  delay %d  (%s)" % [brk, seed, pname, d, ("tick %d is frozen (no control runs): a switch a tick later gives the same state" % takeAt) if brk == "late" else ("no rollback ran tick %d again on the proposer" % takeAt if brk == "once" else "every filled input is the one its tick ran with")])
					continue
				print("  %s %-6s seed %d %-6s  delay %d  tick %d %s  %s" % ["caught" if res.err != "" else "MISSED", brk, seed, pname, d, takeAt, "live" if res.liveT else "frozen", res.err])
				if res.err == "":
					missed += 1
				else:
					caught += 1
	sabotage = ""
	print("%s  takeover negative control: %d break(s) caught, %d missed, %d not applicable" % ["PASS" if missed == 0 and caught > 0 else "FAIL", caught, missed, skipped])
	quit(0 if missed == 0 and caught > 0 else 1)


## The calm turn in a peer's confirmed states: a window opens when a turn is decided (E.next set) and closes at the swap
## (E.n grew) or a cancel. True for the ticks whose full SimHash is taken: a window's, and TURN_TAIL after a swap.
func _turnTrack(r: Dictionary, b: int, E) -> bool:
	var n: int = int(E.n)
	if int(r.open) < 0 and E.next != null:
		r.open = b
	if n > int(r.n):
		r.win.append([int(r.open) if int(r.open) >= 0 else b, b, true])   # [decided, swapped: the state after b ticks has swapped, true]
		r.open = -1
		r.n = n
		r.lastSwap = b
	elif int(r.open) >= 0 and E.next == null:
		r.win.append([int(r.open), b, false])   # cancelled
		r.open = -1
	return int(r.open) >= 0 or (int(r.lastSwap) >= 0 and b - int(r.lastSwap) <= TURN_TAIL)


## One match over the loopback (the fighter AI's with --ai, else the bots'), with any takeover or drop: the confirmed ticks
## of every peer still there against the straight replay of the inputs they confirmed.
func _logSession(seed: int, setup: Dictionary, cap: int, delay: int, hashEvery: int, pname: String, proposer: int = -1) -> Dictionary:
	var profile: Dictionary = NetLoopback.PROFILES[pname]
	var L := NetLoopback.make(seed, setup, profile, delay, seed, seed * 31 + int(profile.ping), false, aiFlags)
	var res := {"err": "", "hashed": 0, "digests": 0, "rollbacks": 0, "resim": 0, "maxDepth": 0, "mispred": 0, "stalls": 0, "lost": 0, "sent": 0, "ko": -1, "until": 0, "exN": 0, "own": false,
		"take": "", "turns": "", "crossT": false, "fillDiff": 0, "walk": "", "liveT": true}
	var walkPool := NetSnapshot.Pool.new()   # the confirmed states walked field by field after a swap
	var stepUs := PackedInt32Array()          # each loopback frame's wall time (both peers), for the frames that re-ran a swap
	var runAt := {"frame": 0}                 # the loopback frame being run, for the rollback log (a callback must not hold L: a cycle)
	# Per peer: {dig: [NetDesync.digest after tick b, at b - 1], hash: {b: SimHash gameplay hash, every hashEvery ticks},
	# out: [feed and fx digests], ko, rb: [[restored boundary, frame]] its rollbacks, win: its turns}. The full gameplay hash
	# costs some 15 ms a state, so a match of 30,000 ticks hashes every hashEvery ticks (and its last, and a calm turn's
	# ticks), and the desync digest (a third of a millisecond, the same fields in a cheaper fold) every tick.
	var rec: Array = []
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		sess.verify = sparse == 0
		sess.saveEvery = maxi(1, sparse)
		_plant(sess, k, proposer)
		if aiMode:
			var drv := NetAiDriver.new(k, seed, sess)
			drv.impure = sabotage == "impure" and k == 0
			L.peers[k].bot = drv
		if k == proposer:
			L.peers[k].bot = TakePlayer.new(L.peers[k].bot, sess, takeSlot, takeAt)
		if turnAt >= 0:
			sess.beforeTick = _forceTurn
		var r := {"dig": [], "hash": {}, "out": [], "ko": -1, "rb": [], "win": [], "open": -1, "n": 0, "lastSwap": -1, "walk": {}}
		rec.append(r)
		sess.onRollback = func(s: int, f: int) -> void: r.rb.append([s, f, int(runAt.frame)])
		sess.onConfirmed = func(b: int, st, out: String) -> void:
			r.out.append(out)
			r.dig.append(NetDesync.digest(st) if st != null else "")
			var turn: bool = st != null and st.epoch != null and _turnTrack(r, b, st.epoch)
			var near: bool = takeAt >= 0 and b > takeAt and b <= takeAt + TURN_TAIL   # a takeover's first ticks: SimHash holds the AI's timers, the digest does not
			if st != null and (b % hashEvery == 0 or b == res.until or turn or near):
				r.hash[b] = SimHash.stateHash(st).gameplay
			if st != null and ((int(r.lastSwap) >= 0 and b == int(r.lastSwap) + TURN_TAIL) or walkTicks.has(b)):
				r.walk[b] = NetSnapshot.take(st, walkPool)
			if r.ko < 0 and st != null and st.game.ko != null:
				r.ko = b
	var until: int = cap
	res.until = until
	var done: bool = false
	var dropped: int = -1
	while L.frames < cap * 4 + 600:
		var u0: int = Time.get_ticks_usec()
		runAt.frame = L.frames
		L.step(until)
		stepUs.append(Time.get_ticks_usec() - u0)
		if dropAt >= 0:
			if not L.gone[takeSlot] and L.frames >= dropAt:
				L.gone[takeSlot] = true
			var sv: int = 1 - takeSlot
			if L.gone[takeSlot] and dropped < 0 and L.frames - int(L.heard[sv]) >= timeout:
				dropped = L.peers[sv].session.dropSlot(takeSlot)
		var ko: int = -1
		for k in range(2):
			if not L.gone[k] and rec[k].ko >= 0:
				ko = rec[k].ko if ko < 0 else mini(ko, rec[k].ko)
		if ko >= 0:
			until = mini(cap, ko + tail)
		res.until = until
		done = true
		for k in range(2):
			if not L.gone[k] and (L.peers[k].session.frame < until or L.peers[k].session.finalTo < until):
				done = false
		if done:
			break
	res.until = until
	var live: Array = []   # the peers still there
	for k in range(2):
		if not L.gone[k]:
			live.append(k)
	res.ko = rec[live[0]].ko if rec[live[0]].ko >= 0 and rec[live[0]].ko <= until else -1
	if not done:
		res.err = "did not confirm %d ticks in %d frames" % [until, L.frames]
	for k in range(2):
		var sess: NetSession = L.peers[k].session
		res.rollbacks += sess.rollbacks
		res.resim += sess.resimTicks
		res.mispred += sess.mispredicted
		res.maxDepth = maxi(res.maxDepth, sess.maxDepth)
		res.stalls += sess.stalls
		res.lost += L.links[k].lost
		res.sent += L.links[k].sent
		res.fillDiff += sess.fillDiff
		if res.err == "" and not L.gone[k] and not sess.desync.is_empty() and sabotage == "":
			res.err = "peer %d: desync detection fired at checkpoint %d" % [k, sess.desync.tick]
		if k == proposer:
			for e in rec[k].rb:
				if int(e[0]) <= takeAt and int(e[1]) > takeAt:
					res.crossT = true   # a rollback on the proposer ran tick T again
	# The takeover: every peer still there agrees on it, and a proposed one is at T.
	var at: int = int(L.peers[live[0]].session.aiFrom.get(takeSlot, -1))
	if takeAt >= 0 or dropAt >= 0:
		for k in live:
			if res.err == "" and int(L.peers[k].session.aiFrom.get(takeSlot, -1)) != at:
				res.err = "the peers' takeovers differ (%s, %s)" % [str(L.peers[0].session.aiFrom), str(L.peers[1].session.aiFrom)]
		if res.err == "" and proposer >= 0 and at != takeAt:
			res.err = "the takeover is at tick %d, not %d" % [at, takeAt]
		if res.err == "" and dropAt >= 0 and dropped < 0:
			res.err = "the survivor never dropped the vanished slot"
		if res.err == "" and dropAt >= 0 and at != dropped:
			res.err = "the drop's tick %d is not the takeover's %d" % [dropped, at]
		var late: int = 0
		for k in live:
			late += 1 if L.peers[k].session.takeoverLate > 0 else 0
		res.take = "  %s at tick %d (late at %d peer(s))" % ["drop, AI" if dropAt >= 0 else "takeover by peer %d" % proposer, at, late]
	var log: Array = [[], []]
	if res.err == "":
		for slot in range(2):
			for t in range(until):
				var s0: NetSession = L.peers[live[0]].session
				if res.err == "" and not s0.hasInput(slot, t):
					res.err = "peer %d holds no confirmed input of slot %d at tick %d" % [live[0], slot, t]
				var v0: int = s0.confirmedInput(slot, t) if s0.hasInput(slot, t) else NetSession.NEUTRAL
				if live.size() == 2:
					var s1: NetSession = L.peers[live[1]].session
					if res.err == "" and (not s1.hasInput(slot, t) or s1.confirmedInput(slot, t) != v0):
						res.err = "the peers' confirmed inputs of slot %d at tick %d differ" % [slot, t]
				log[slot].append(v0)
	if res.err == "" and live.size() == 2 and (rec[0].ko != rec[1].ko):
		res.err = "the peers saw the KO at different ticks (%d, %d)" % [rec[0].ko, rec[1].ko]
	var toggles: Array = NetDesync.togglesOf(L.peers[live[0]].session.aiFrom, aiFlags, until)
	if res.err == "":
		var hashAt: Dictionary = {}
		var walkAt: Dictionary = {}   # b -> the live peers' confirmed states after b ticks, walked against the straight run's
		for k in live:
			for b in rec[k].hash:
				hashAt[b] = true
			for b in rec[k].walk:
				if not walkAt.has(b):
					walkAt[b] = []
				walkAt[b].append(rec[k].walk[b].root)
		var ref := _aiStraight(seed, setup, until, delay, hashEvery, log, toggles, hashAt, walkAt)
		if not ref.walk.is_empty():
			var clean: int = 0
			var diffs: Array = []
			for b in ref.walk:
				for dl in ref.walk[b]:
					if dl.is_empty():
						clean += 1
					else:
						diffs.append("after tick %d: %s" % [b, str(dl)])
			res.walk = "  field walks after a swap: %d clean%s" % [clean, "" if diffs.is_empty() else ", DIFFERENT " + "; ".join(diffs)]
		res.exN = ref.exN
		res.liveT = takeAt < 0 or not ref.frozen.has(takeAt)
		if not ref.replayOk:
			res.err = "the straight run's replay did not verify"
		elif not ref.aliases.is_empty():
			res.err = "the state shares containers: %s" % str(ref.aliases)
		elif ref.ko != res.ko:
			res.err = "the straight run's KO (tick %d) is not the peers' (%d)" % [ref.ko, res.ko]
		for k in live:
			for b in range(1, until + 1):
				if res.err != "":
					break
				if rec[k].out[b - 1] != ref.out[b - 1]:
					res.err = "peer %d: tick %d's feed and fx differ from the straight run" % [k, b]
				elif rec[k].dig[b - 1] == "":
					if sparse == 0:
						res.err = "peer %d: no state for confirmed tick %d" % [k, b]
				elif rec[k].dig[b - 1] != ref.dig[b - 1]:
					res.err = "peer %d: the state's digest differs from the straight run after tick %d" % [k, b]
				else:
					res.digests += 1
					if rec[k].hash.has(b):
						if rec[k].hash[b] != ref.hash.get(b, ""):
							res.err = "peer %d: SimHash differs from the straight run after tick %d" % [k, b]
						else:
							res.hashed += 1
		if res.err == "" and live.size() == 2 and SimHash.stateHash(L.peers[0].session.S).gameplay != SimHash.stateHash(L.peers[1].session.S).gameplay:
			res.err = "the peers' final states differ"
		# No prediction was wrong, so every state either peer's AI read was the straight run's: the AI run from the straight
		# state must give the same inputs, or it reads something the state does not carry.
		if res.err == "" and aiMode and res.mispred == 0 and dropAt < 0:
			var own := _aiStraight(seed, setup, until, delay, hashEvery, [], toggles, hashAt)
			for slot in range(2):
				for t in range(until):
					if res.err == "" and int(own.log[slot][t]) != int(log[slot][t]):
						res.err = "slot %d's AI input at tick %d differs from the AI run on the straight state" % [slot, t]
			if res.err == "" and own.final != ref.final:
				res.err = "the AI's own straight run ends in another state"
			res.own = res.err == ""
	res.turns = _turnLine(rec, live, stepUs)
	for k in range(2):
		for b in rec[k].walk:
			walkPool.put(rec[k].walk[b])
	walkPool.clear()
	L.close()
	return res


## World's process caches, once every sim is disposed: the calm turn's ring jobs and preparations stay keyed by a world
## that is gone (SimCore.dispose does not drop them; a turn decided and not swapped by the end leaves its own), and the
## planet memo keeps every ring read. They are World's, not a session's, so they are counted, reported and cleared
## (as parity.gd forgets the memo) before the check counts leaked objects.
func _worldCaches() -> void:
	var jobs: int = WorldEpoch._jobs.size()
	var plans: int = WorldEpoch._plans.size()
	if jobs + plans > 0:
		print("World's calm-turn caches of disposed sims at the end: %d ring job(s), %d preparation(s) (cleared before the object count)" % [jobs, plans])
	WorldEpoch._jobs.clear()
	WorldEpoch._plans.clear()
	WorldPlanet.forget()


## --turn-at: a calm turn decided before tick turnAt, on every run of it, as two_states_check's TURN_AT (and World's
## epoch_check) decide one: past the gap between turns, about the pair's midpoint, Encounter's pick of the third
## candidate at 64 columns a tick with a 2.5 degree fallback. The same write in the peers' runs and the straight run.
func _forceTurn(S: SimState, t: int) -> void:
	if t != turnAt or S.epoch == null:
		return
	var x0: float = S.fighters[0].x
	S.epoch.lastT = S.T - float(WorldEpoch.data().gapSeconds)
	WorldEpoch.ask(S, "rollback check", SimWrap.wrap(x0 + 0.5 * SimWrap.sdx(x0, S.fighters[1].x)), 1, 0)
	WorldEpoch.choose(S, 2, 64, 2.5)


## The calm turns the peers' confirmed states crossed, and the rollbacks that reached into them: "" for none. The slowest
## loopback frame (both peers' work, wall time) whose rollback ran a swap again, against the median frame: on a shared
## machine at below-normal priority, a pointer only.
func _turnLine(rec: Array, live: Array, stepUs: PackedInt32Array) -> String:
	var r0: Dictionary = rec[live[0]]
	if r0.win.is_empty() and int(r0.open) < 0:
		return ""
	var parts: Array = []
	for w in r0.win:
		parts.append(("decided %d swapped %d" % [w[0], w[1]]) if w[2] else ("decided %d cancelled %d" % [w[0], w[1]]))
	if int(r0.open) >= 0:
		parts.append("decided %d, open at the end" % int(r0.open))
	var across: int = 0   # rollbacks that ran the swap's tick again (restored before it, re-ran past it)
	var into: int = 0     # ... that restored a state inside the window (the warm reads and the preparation under way)
	var rerun: int = 0    # ... that ran any of the window's ticks again
	var slow: int = 0     # the slowest frame whose rollback ran a swap again, us
	for k in live:
		for w in rec[k].win:
			if not w[2]:
				continue
			for e in rec[k].rb:
				var s: int = int(e[0])
				var f: int = int(e[1])
				if s < int(w[1]) and f >= int(w[1]):
					across += 1
					if int(e[2]) < stepUs.size():
						slow = maxi(slow, stepUs[int(e[2])])
				if s >= int(w[0]) and s < int(w[1]):
					into += 1
				if s < int(w[1]) and f > int(w[0]):
					rerun += 1
	var sorted: Array = Array(stepUs)
	sorted.sort()
	var med: float = float(sorted[sorted.size() / 2]) / 1000.0 if not sorted.is_empty() else 0.0
	var timing: String = "" if stepUs.is_empty() else "; slowest frame re-running a swap %.1f ms (median frame %.1f ms)" % [slow / 1000.0, med]
	return "  turns: %s; rollbacks running the swap again %d, restoring inside a window %d, re-running window ticks %d%s" % [", ".join(parts), across, into, rerun, timing]


## The straight run of a logged match: the inputs of `log` ([slot] -> per tick), or with an empty log the AI itself
## (NetAiDriver on the straight state; tick t's input read after t - delay ticks, as a peer's is), with the takeovers'
## toggles ([tick, slot]: toggleAI before that tick; the slot then plays neutral). Hashes every hashEvery ticks, the last,
## and the ticks of hashAt. {dig, hash, out, log, final, replayOk, ko, exN, aliases}.
func _aiStraight(seed: int, setup: Dictionary, ticks: int, delay: int, hashEvery: int, log: Array, toggles: Array = [], hashAt: Dictionary = {}, walkAt: Dictionary = {}) -> Dictionary:
	var S := SimCore.createSim()
	var rec := SimReplay.recorder(S, seed, aiFlags, setup)
	var drivers: Array = []
	var played: Array = [[], []]
	var aiAt: Dictionary = {}   # slot -> its toggle's tick
	for e in toggles:
		aiAt[int(e[1])] = int(e[0])
	if log.is_empty():
		for k in range(2):
			drivers.append(NetAiDriver.new(k, seed, null, S))
			for t in range(delay):
				played[k].append(NetSession.NEUTRAL)
	var hashes: Dictionary = {}
	var aliases: Array = NetSnapshot.aliasAudit(S)
	var digs: Array = []
	var outs: Array = []
	var ko: int = -1
	var ti: int = 0
	var walk: Dictionary = {}   # b -> [NetDesync.firstDiffs of each peer state in walkAt[b] against this state after b ticks]
	var frozen: Dictionary = {}   # ticks whose step ran no control (SimCore.step returned false)
	for t in range(ticks):
		var ins: Array = []
		for k in range(2):
			var p: int
			if log.is_empty():
				played[k].append(drivers[k].think(S))   # the input for tick t + delay, read before tick t's switch, as a peer's driver reads its present
				p = played[k][t]
				if aiAt.has(k) and t >= int(aiAt[k]):
					p = NetSession.NEUTRAL   # the slot is the sim's AI from its takeover: its inputs are neutral
					played[k][t] = p
			else:
				p = log[k][t]
			ins.append(SimIntent.unpack(p))
		while ti < toggles.size() and int(toggles[ti][0]) == t:   # then, as NetSession._run: the takeover's switch, the test's write, the tick
			rec.toggle(int(toggles[ti][1]))
			ti += 1
		if turnAt >= 0:
			_forceTurn(S, t)
		if not rec.step(ins):
			frozen[t] = true   # no control ran this tick (hit-stop, a pausing set piece, the intro)
		outs.append(NetSession.outDigest(S))
		S.out.feed.clear()
		S.out.fx.clear()
		digs.append(NetDesync.digest(S))
		if (t + 1) % hashEvery == 0 or t + 1 == ticks or hashAt.has(t + 1):
			hashes[t + 1] = SimHash.stateHash(S).gameplay
		if walkAt.has(t + 1):
			walk[t + 1] = walkAt[t + 1].map(func(root): return NetDesync.firstDiffs(root, S, 4))
		if ko < 0 and S.game.ko != null:
			ko = t + 1
		if t + 1 == ticks / 2:
			aliases += NetSnapshot.aliasAudit(S)
	aliases += NetSnapshot.aliasAudit(S)
	aliases = aliases.filter(func(a): return not READ_ONLY_SHARED.has(a))
	var rp: Dictionary = rec.finish()
	var play: Dictionary = SimReplay.play(rp)
	var final: String = hashes[ticks]
	var out := {"dig": digs, "hash": hashes, "out": outs, "log": played if log.is_empty() else log, "final": final, "replayOk": (play.ok and play.final == final) or turnAt >= 0, "ko": ko, "exN": S.dirS.exN, "aliases": aliases, "walk": walk, "frozen": frozen}
	for drv in drivers:
		drv.close()
	SimCore.dispose(S)
	return out
