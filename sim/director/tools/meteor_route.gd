extends SceneTree
## The meteor by a real pad, through SimInputHub in the host's order, from a start at tier 4: what a player presses, tick by tick, with what
## lands. No scaffold: every stun is the game's own. Run with the page's switches on.
##   godot --headless --path . --script res://sim/director/tools/meteor_route.gd -- [tries]

var hub: SimInputHub
var held: Dictionary = {}
var log_: Array = []
var verbose: bool = false
var t: int = 0
var strikeAt: int = -1
var strikeLvl: int = -1
var sent: String = ""
var sentAt: int = -1
var flashAt: int = -1
var refused: int = 0


func _init() -> void:
	var u: PackedStringArray = OS.get_cmdline_user_args()
	var tries: int = int(u[0]) if u.size() > 0 else 12
	print("arc on %s, stick on %s, lightStops %s, bank %d, forms %s" % [str(DirArc.on()), str(DirStick.on()), str(DirStick.lightStops()), int(DirArc.cfg().bankFull), str(SimForms.enabled())])
	verbose = true
	var r0: Dictionary = _ignition(11, false, 16)
	print("IDLE, one try: ", str(r0))
	print("IDLE, B 4 after, traced:")
	print(str(_ignition(11, false, 4)))
	verbose = false
	for wait in [0, 2, 3, 4, 5, 6, 8, 12, 16, 20, 24, 30]:
		var n: Dictionary = {"METEOR": 0, "other": 0, "none": 0}
		for sd in range(1, 5):
			var r: Dictionary = _ignition(sd, false, wait)
			var k: String = String(r.sent)
			n[k if n.has(k) else ("none" if k == "" else "other")] += 1
		print("IDLE, B pressed %d ticks after the strike lands: %s" % [wait, str(n)])
	var ai: Dictionary = {"tries": 0, "stickLanded": 0, "level3": 0, "METEOR": 0, "HIGH ARC": 0, "other": 0, "none": 0}
	for sd in range(1, tries + 1):
		var r: Dictionary = _ignition(sd, true, 16)
		ai.tries += 1
		if int(r.lvl) >= 0:
			ai.stickLanded += 1
		if int(r.lvl) == 3:
			ai.level3 += 1
		var k: String = String(r.sent)
		if ai.has(k):
			ai[k] += 1
		elif k == "":
			ai.none += 1
		else:
			ai.other += 1
	print("AGAINST THE AI, one try a fight: ", str(ai))
	_natural(tries)
	quit(0)


func _make(sd: int, ai: bool) -> SimState:
	hub = SimInputHub.new()
	held = {}
	var su: Dictionary = hub.setup()
	su["intro"] = false
	su["planet"] = 7
	su["touch"] = 2
	su["planetGen"] = 3
	su["startTier"] = 4
	var S := SimCore.createSim()
	SimCore.newMatch(S, sd, {"p1": false, "p2": ai}, su)
	if not ai:
		S.fighters[1].ai = null
	S.fighters[0].ki = 100.0
	S.fighters[1].ki = 100.0
	hub.set_pad_has_right_stick(0, true)
	t = 0
	strikeAt = -1
	strikeLvl = -1
	sent = ""
	sentAt = -1
	flashAt = -1
	refused = 0
	log_ = []
	return S


func _btn(name: String, down: bool) -> void:
	if down == held.has(name):
		return
	if down:
		held[name] = true
	else:
		held.erase(name)
	hub.pad_button(0, name, down)
	if verbose:
		print("  tick %d: %s %s" % [t, name, "down" if down else "up"])


func _step(S: SimState) -> void:
	hub.set_humans(S.fighters[0].ai == null, S.fighters[1].ai == null)
	hub.set_struggle(0, SimDir.inStruggle(S, S.fighters[0]))
	var it: SimIntent = hub.intent(0)
	var pausing: bool = S.pause.left > 0
	if SimCore.step(S, [it, null if S.fighters[1].ai != null else SimIntent.new()]):
		hub.consumed()
	elif pausing:
		if S.pause.left > 0:
			hub.drop_edges()
		else:
			hub.resume()
	t += 1
	for e in S.out.fx:
		if e.type == "launch_plan" and sent == "" and S.fighters[1].state == "launched":
			sent = String(e.chosen)
			sentAt = t
		if e.type == "cue" and e.actor == 0.0:
			var k: String = String(e.kind)
			if k == "stick_hit":
				strikeAt = t
				strikeLvl = int(String(e.source))
			if k == "stick_refused":
				refused += 1
			if verbose and (k.begins_with("stick") or k == "blow" or k == "windup" or k == "arc_send" or k == "charge_full" or k == "brawl_start" or k == "launcher_close"):
				print("  tick %d: cue %s %s %s" % [t, k, String(e.text), String(e.source)])
		if e.type == "charge_full" or (e.type == "cue" and e.kind == "charge_full"):
			if flashAt < 0:
				flashAt = t
	hub.on_events(S.out.fx)
	S.out.fx.clear()
	S.out.feed.clear()


## Close the gap, tap X for a brawl, hold the stick up to level 3, let go, and press and hold B `wait` ticks after it lands, to the flash.
func _ignition(sd: int, ai: bool, wait: int) -> Dictionary:
	var S := _make(sd, ai)
	var A = S.fighters[0]
	var D = S.fighters[1]
	if ai:
		for _k in range(60):
			_walk(S)
			_step(S)
	else:
		D.x = SimWrap.wrap(A.x + 58.0)
		D.y = A.y
		for _k in range(5):
			_step(S)
	hub.pad_stick(0, 0.0, 0.0)
	_btn("west", true)
	_step(S)
	_btn("west", false)
	for _k in range(24):
		_step(S)
	# the stick up, to level 3
	var pressed: int = t
	hub.pad_stick_right(0, 0.0, 1.0)
	for _k in range(66):
		_step(S)
	hub.pad_stick_right(0, 0.0, 0.0)
	for _k in range(14):
		_step(S)
		if strikeAt >= 0:
			break
	var lvl: int = strikeLvl
	var landed: int = strikeAt
	var stun: int = D.stunTicks
	for _k in range(wait):
		_step(S)
	_btn("east", true)
	var stunAtB: int = D.stunTicks
	var heldFor: int = 0
	for _k in range(70):
		_step(S)
		heldFor += 1
		if DirBrawl._g(A, DirBrawl.CHG) == 2 or sent != "":
			break
	_btn("east", false)
	for _k in range(30):
		_step(S)
		if sent != "":
			break
	var r: Dictionary = {"sent": sent, "lvl": lvl, "stickHeld": 66, "landedAt": landed - pressed, "stunAfterLanding": stun, "stunAtB": stunAtB, "bHeld": heldFor, "sentAfterStrike": sentAt - landed if sentAt >= 0 and landed >= 0 else -1, "refused": refused, "state": String(D.state)}
	SimCore.dispose(S)
	return r


## No stick: fly in and hold B to the flash, let go, again. What comes of it against the AI, and how often a rival was weak when it landed.
func _natural(tries: int) -> void:
	var tally: Dictionary = {"METEOR": 0, "HIGH ARC": 0, "other": 0, "flashes": 0, "fights": 0}
	var first: Array = []
	var firstM: Array = []
	var weakWhen: Array = []
	for sd in range(1, mini(tries, 8) + 1):
		var S := _make(sd, true)
		var A = S.fighters[0]
		var D = S.fighters[1]
		var hold: int = 0
		var gotFirst: bool = false
		var gotM: bool = false
		var wasWeak: bool = false
		var was: String = ""
		while t < 21600 and S.game.ko == null:
			A.ki = maxf(A.ki, 60.0)
			_walk(S)
			if not gotM and not wasWeak and DirArc.weak(D) and D.stunTicks <= 0:
				wasWeak = true
				weakWhen.append(snappedf(float(t) / 3600.0, 0.1))
			if hold == 0 and DirBands.band(A, D) != DirBands.FAR and A.state != "launched" and A.state != "down":
				_btn("east", true)
				hold = 1
			elif hold > 0:
				hold += 1
				if DirBrawl._g(A, DirBrawl.CHG) == 2 or hold > 62:
					if DirBrawl._g(A, DirBrawl.CHG) == 2:
						tally.flashes += 1
					_btn("east", false)
					hold = -30
			elif hold < 0:
				hold += 1
			sent = ""
			_step(S)
			if sent != "" and sent != was and D.state == "launched":
				if sent == "METEOR" or sent == "HIGH ARC":
					tally[sent] += 1
					if not gotFirst:
						gotFirst = true
						first.append(snappedf(float(t) / 3600.0, 0.1))
					if sent == "METEOR" and not gotM:
						gotM = true
						firstM.append(snappedf(float(t) / 3600.0, 0.1))
				else:
					tally.other += 1
			was = sent if sent != "" else (was if D.state == "launched" else "")
		tally.fights += 1
		SimCore.dispose(S)
	print("B TO THE FLASH, against the AI, 6 minutes: ", str(tally))
	print("  first send by the curve, minutes: ", str(first), "; first meteor: ", str(firstM), "; rival first weak with no stun: ", str(weakWhen))


func _walk(S: SimState) -> void:
	var dx: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)
	var dy: float = S.fighters[1].y - S.fighters[0].y
	hub.pad_stick(0, signf(dx) if absf(dx) > 110.0 else 0.0, signf(dy) if absf(dy) > 40.0 else 0.0)
