class_name NetLan
extends RefCounted
## A match between two PCs on a home network (docs/net/lan-v1.md): the game's own loop steps the sim through a NetHost, and the local pad is the host's "bot". Private builds only: the public desktop
## builds exclude net/ (Legal RL-204), and net/tools/lan_kit.mjs patches the two lines that call this into a scratch copy.
## SimHost.tick calls tick(the intent of the fighter this PC plays, `local`) once a fixed tick, where it would call SimCore.step, and treats the answer the same way: true means the press went, so the hub may forget it.
## The window's title says how it's going. A small log goes to --lan-log.
## --lan-2v2: two fights on one line with a player in each and the computer as each one's opponent (docs/net/two-v-two-lan.md, step 3). Each PC keeps its own fight in S's fields between ticks, so to the
## game it's a 1v1 against the computer: the hub's first slot, its camera, its HUD and its drawing. The step puts fight 0 in place itself, and the hash and digest leave S holding the fight they found
## (Simulation's cross-fights). The other fight's events stay in its record until its next tick, as the sim leaves them, for the picture to draw (the session keeps a re-run's out).
## A trade (SimStage.trade) can move this PC's player into the other fight, or to the other place in a pair: S then holds the fight he's in, and the pad moves to his place in the hub.
## With hits across fights, a KO puts a fighter out and the match goes on until a team has nobody standing (SimCore.ended): a PC whose player is out shows his partner's fight.

const PORT: int = 47100
const SEED: int = 77
const SETUP: Dictionary = {"v2": [true, true], "assists": [[], []], "planet": 7, "touch": 3, "planetGen": 3, "intro": false}   # every key the hub's own setup has, so a saved layout can't make two PCs differ
const AI: Dictionary = {"p1": false, "p2": false}
const SETUP2X: Dictionary = {"v2": [true, true, true, true], "assists": [[], [], [], []], "planet": 7, "touch": 3, "planetGen": 3, "intro": false, "fights": 2, "cross": true, "outside": true}   # --lan-2v2-together: hits across the two fights (sim/core/cross.gd) and Encounter's blows from outside (Simulation's per-setup key, S.stage.outside), a team against a team
const SETUP2: Dictionary = {"v2": [true, true, true, true], "assists": [[], [], [], []], "planet": 7, "touch": 3, "planetGen": 3, "intro": false, "fights": 2}
const AI2: Dictionary = {"p1": false, "p2": true, "p3": false, "p4": true}
const SLOTS2: Array = [0, 2]   # the sim's slot each PC's player plays
const FOREVER: int = 1 << 30
const REDIAL_MS: float = 3000.0   # a call with no answer yet starts again this often, so the two PCs can press Start in any order, however far apart

var gameHost   # SimHost, or a test's stand-in with S and setup_used
var args: Dictionary
var net: NetHost = null
var pad := Pad.new()
var local: int = 0
var two: bool = false         # --lan-2v2 or --lan-2v2-together
var hubSlot: int = 0          # which of the hub's slots this PC's pad is, and which fighter it plays in the fight in S's fields
var entered: bool = true      # tests only: off for the negative control (S is left holding whatever fight the step left, not this PC's player's)
var watchPartner: bool = true # tests only: off for the negative control (a PC whose player is out keeps showing his finished fight)
var failed: String = ""
var clock: Callable   # tests only: () -> float, ms; the wall clock otherwise
var sayTitle: bool = true
var freezeRule: bool = true   # tests only: off for the negative control
var keepOut: bool = true      # tests only: off for the negative control
var peer: NetHost = null      # --lan-loop: the other PC, in this process, on a state of its own
var peerS: SimState = null
var _state: String = ""
var _logAt: float = 0.0
var _logTick: int = -1
var _addr: String = ""
var _dialAt: float = -1.0
var redials: int = 0


## The local player's intent for the next tick, as NetHost's bot reads it.
class Pad extends NetBot:
	var packed: int = 0

	func _init() -> void:
		super(0, 0)

	func next() -> int:
		return packed


func _init(gameHost_, args_: Dictionary) -> void:
	gameHost = gameHost_
	args = args_
	local = 1 if args.has("lan-join") or String(args.get("lan-as", "0")) == "1" else 0
	two = args.has("lan-2v2") or args.has("lan-2v2-together")
	hubSlot = 0 if two else local


## Whether the sim carries a setup's "outside" into the match (Simulation's per-setup key, S.stage.outside). Until it does, the checks force the blows from outside on for the together setup.
static func outsideKeyed() -> bool:
	return SimState.Stage.new().get("outside") != null


static func setupFor(args_: Dictionary) -> Dictionary:
	return SETUP2X if args_.has("lan-2v2-together") else (SETUP2 if args_.has("lan-2v2") else SETUP)


static func aiFor(args_: Dictionary) -> Dictionary:
	return AI2 if args_.has("lan-2v2") or args_.has("lan-2v2-together") else AI


## One fixed tick. True if the session took this intent and any press in it went.
func tick(i: SimIntent) -> bool:
	if i == null:   # the hub's slot holds the computer for a moment (a trade, before the pad moves)
		i = SimIntent.new()
	if net == null and failed == "":
		_open()
	if net == null:
		_say("Couldn't connect: " + failed)
		return false
	var held: bool = freezeRule and net.session != null and _frozenPast(gameHost.S, net.session.delay)
	var send: SimIntent = _heldOnly(i) if held else i
	pad.packed = SimIntent.pack(send)
	pad.word = SimIntent.pack2(send) if SimInputData.right_stick_on() else 0
	var before: int = net.session.frame if net.session != null else -1
	var now: float = clock.call() if clock.is_valid() else float(Time.get_ticks_usec()) / 1000.0
	_keepCalling(now)
	var S: SimState = gameHost.S
	net.frame(now, FOREVER)
	if two and entered:
		_follow(S)
	if peer != null:
		peer.frame(now, FOREVER)
	_report(now)
	return net.session != null and net.session.frame > before and not held


## The body in a slot of a two-fight match: fight i's pair are slots 2i and 2i + 1.
static func bodyAt(S: SimState, slot: int):
	var i: int = slot / 2
	return (S.fighters if i == S.stage.cur else S.stage.fights[i].fighters)[slot % 2]


## The slot whose fight this PC shows: its player's, or, once he's out, his partner's (the other PC's player) while the partner stands.
func viewSlot(S: SimState) -> int:
	var at: int = NetSession.slotNow(S, SLOTS2[local])
	if watchPartner and bodyAt(S, at).out:
		var mate: int = NetSession.slotNow(S, SLOTS2[1 - local])
		if not bodyAt(S, mate).out:
			return mate
	return at


## With two fights: S holds the fight this PC shows, and the hub's pad is its player's place in it.
func _follow(S: SimState) -> void:
	var at: int = viewSlot(S)
	SimStage.enter(S, at / 2)
	if at != NetSession.slotNow(S, SLOTS2[local]):
		return   # his partner's fight: the pad stays where it was, and what it sends goes to his own body, which is out
	if at % 2 != hubSlot:
		var hub = gameHost.get("hub")
		if hub != null:
			moveHub(hub, hubSlot, at % 2)
		hubSlot = at % 2


## The pad in the hub's slot `from` goes to slot `to`, as the joiner's does at the start.
static func moveHub(hub, from: int, to: int) -> void:
	hub.slot_device[to] = hub.slot_device[from]
	hub.slot_pad[to] = hub.slot_pad[from]
	hub.claimed[to] = hub.claimed[from]
	hub.slot_device[from] = "kb"
	hub.slot_pad[from] = -1
	hub.claimed[from] = false


## What the session needs from here, set as it starts.
func setUp(sess: NetSession) -> void:
	sess.presentOut = keepOut
	if two:
		sess.slotOf = SLOTS2


## A frame while the game is paused (SimHost.advance, as the kit patches it): the link and the packets go on, no tick runs, and the other PC is told.
func idle() -> void:
	if net == null:
		return
	var now: float = clock.call() if clock.is_valid() else float(Time.get_ticks_usec()) / 1000.0
	_keepCalling(now)
	net.idle(now)
	if peer != null:
		peer.frame(now, FOREVER)
	_report(now)


## The caller, before the other PC has answered: call again every few seconds.
func _keepCalling(now: float) -> void:
	if _addr == "" or local != 1 or net.session != null or not (net.tr is NetEnetTransport):
		return
	var t: NetEnetTransport = net.tr
	if t.connected():
		return
	if _dialAt < 0.0:
		_dialAt = now
	elif now - _dialAt >= REDIAL_MS:
		_dialAt = now
		redials += 1
		t.redial(_addr, PORT)


## A press now lands `delay` ticks on, and a frozen tick reads no input. So while the freeze lasts past that, keep it back (the hub holds a press, as it does through a hit-stop offline).
static func _frozenPast(S: SimState, delay: int) -> bool:
	var left: int = maxi(int(ceil(S.dirS.stop / SimConst.DT)), int(S.pause.left))
	return left > delay


## The held controls of an intent, with no single-tick presses: what goes out while a press is kept back.
static func _heldOnly(i: SimIntent) -> SimIntent:
	var o: SimIntent = SimIntent.new()
	SimIntent.applyIntent(o, i)
	for k in ["guardPress", "dodge", "powerPress", "powerTap", "light", "heavy", "sig", "context", "transform", "escape", "rsStart", "rsRelease", "rsCancel", "brace"]:
		o.set(k, false)
	o.upgrade = 0
	o.special = 0
	o.braceDir = 0
	o.rsLag = 0
	o.stance = -1.0
	return o


func _open() -> void:
	var S: SimState = gameHost.S
	var key: String = NetHandshake.keyOf(SEED, aiFor(args), gameHost.setup_used)
	var tr: NetTransport
	if args.has("lan-loop"):
		var prof: Dictionary = NetLoopback.PROFILES[String(args.get("lan-loop"))] if NetLoopback.PROFILES.has(String(args.get("lan-loop"))) else NetLoopback.PROFILES["lan"]
		var ab := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 11)
		var ba := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 13)
		tr = NetLinkTransport.new(ab, ba, true)
		peerS = SimCore.createSim()
		SimCore.newMatch(peerS, SEED, aiFor(args), gameHost.setup_used)
		peer = NetHost.new(NetLinkTransport.new(ba, ab, true), peerS, 1 - local, key, NetDelay.device(1.0), NetBot.new(SEED, 1 - local))
		peer.configure = func(sess: NetSession) -> void:
			if two:
				sess.slotOf = SLOTS2
	else:
		var host: bool = args.has("lan-host")
		var addr: String = String(args.get("lan-host" if host else "lan-join", ""))
		_addr = addr
		var t: NetEnetTransport = NetEnetTransport.listen(addr, PORT) if host else NetEnetTransport.dial(addr, PORT)
		if t.failed != "":
			failed = "this PC's address has changed, or the port's in use"   # the address stays out of the log (Legal RL-230)
			return
		if host:
			t.allowPrefix = prefixOf(addr)
		tr = t
	net = NetHost.new(tr, S, local, key, NetDelay.device(1.0), pad)
	if args.has("lan-delay"):
		net.hs.opts = {"minDelay": int(args["lan-delay"])}   # on a LAN the chooser always says 2, as nothing is predicted there. The larger proposal wins, so one PC asking is enough
	net.configure = setUp


## The /24 of an address, as a prefix: "10.0.0." for 10.0.0.135.
static func prefixOf(addr: String) -> String:
	return addr.left(addr.rfind(".") + 1)


## The window's title, and a line in the log every ten seconds and every 600 ticks.
func _report(now: float) -> void:
	var sess: NetSession = net.session
	if net.hs.failed != "":
		_say("Couldn't start: " + net.hs.failed)
	elif sess == null:
		_say("Waiting for the other PC")
	elif not sess.desync.is_empty():
		_say("OUT OF STEP at tick %d. Close both and tell the EP" % int(sess.desync.get("tick", -1)))
	elif not net.tr.isOpen():
		_say("The other PC has gone")
	elif net.paused:
		_say("Paused. The other PC waits for you")
	elif net.remotePaused:
		_say("Paused by the other player")
	elif SimCore.ended(gameHost.S):
		_say("The match is over. Close both windows")
	elif two and bodyAt(gameHost.S, NetSession.slotNow(gameHost.S, SLOTS2[local])).out:
		_say("You're out. Your partner fights on")
	else:
		_say("Connected, input wait %d ticks" % sess.delay)
	if now - _logAt >= 10000.0 or (sess != null and sess.frame % 600 == 0 and sess.frame != _logTick):
		_logAt = now
		_logTick = sess.frame if sess != null else -1
		_log(now)


func _say(s: String) -> void:
	if s == _state:
		return
	_state = s
	_log(0.0)
	if sayTitle and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Orb Combat EX, LAN test: " + s)


func _log(_now: float) -> void:
	if not args.has("lan-log"):
		return
	var sess: NetSession = net.session if net != null else null
	var line: String = "%s; %s" % [Time.get_datetime_string_from_system(), _state]
	if sess != null:
		line += "; tick %d, delay %d, rollbacks %d, deepest %d, checks matched %d, ping %.1f ms, packets in %d out %d" % [sess.frame, sess.delay, sess.rollbacks, sess.maxDepth, sess.checksMatched, net.rttMs(), net.tr.pktIn, net.tr.pktOut]
	var path: String = String(args["lan-log"])
	var f := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(line)
		f.close()
