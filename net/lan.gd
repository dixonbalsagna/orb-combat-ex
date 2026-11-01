class_name NetLan
extends RefCounted
## A plain 1v1 between two PCs on a home network (docs/net/lan-v1.md): the game's own loop steps the sim through a NetHost, and the local pad is the host's "bot". Private builds only: the public desktop
## builds exclude net/ (Legal RL-204), and net/tools/lan_kit.mjs patches the two lines that call this into a scratch copy.
## SimHost.tick calls tick(its local intent) once a fixed tick, where it would call SimCore.step, and treats the answer the same way: true means the press went, so the hub may forget it.
## The window's title says how it's going. A small log goes to --lan-log.

const PORT: int = 47100
const SEED: int = 77
const SETUP: Dictionary = {"v2": [true, true], "assists": [[], []], "planet": 7, "touch": 3, "planetGen": 3, "intro": false}   # every key the hub's own setup has, so a saved layout can't make two PCs differ
const AI: Dictionary = {"p1": false, "p2": false}
const FOREVER: int = 1 << 30

var gameHost   # SimHost, or a test's stand-in with S and setup_used
var args: Dictionary
var net: NetHost = null
var pad := Pad.new()
var local: int = 0
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


## One fixed tick. True if the session took this intent and any press in it went.
func tick(i: SimIntent) -> bool:
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
	net.frame(now, FOREVER)
	if peer != null:
		peer.frame(now, FOREVER)
	_report(now)
	return net.session != null and net.session.frame > before and not held


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
	var key: String = NetHandshake.keyOf(SEED, AI, gameHost.setup_used)
	var tr: NetTransport
	if args.has("lan-loop"):
		var prof: Dictionary = NetLoopback.PROFILES[String(args.get("lan-loop"))] if NetLoopback.PROFILES.has(String(args.get("lan-loop"))) else NetLoopback.PROFILES["lan"]
		var ab := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 11)
		var ba := NetLoopback.Link.new(float(prof.ping) * 0.5, float(prof.jitter), float(prof.loss), 13)
		tr = NetLinkTransport.new(ab, ba, true)
		peerS = SimCore.createSim()
		SimCore.newMatch(peerS, SEED, AI, gameHost.setup_used)
		peer = NetHost.new(NetLinkTransport.new(ba, ab, true), peerS, 1, key, NetDelay.device(1.0), NetBot.new(SEED, 1))
	else:
		var host: bool = args.has("lan-host")
		var addr: String = String(args.get("lan-host" if host else "lan-join", ""))
		local = 0 if host else 1
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
	net.configure = func(sess: NetSession) -> void:
		sess.presentOut = keepOut


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
