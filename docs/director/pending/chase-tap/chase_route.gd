extends SceneTree
## The chase by a real pad, through SimInputHub in the host's order, after a real send (B held to the flash). Run with the page's switches on.
##   godot --headless --path . --script res://sim/director/tools/chase_route.gd

var hub: SimInputHub
var held: Dictionary = {}
var t: int = 0
var sentAt: int = -1
var sentName: String = ""
var starts: Array = []
var catches: Array = []
var acks: Array = []
var ends: Array = []
var fastest: float = 0.0


func _init() -> void:
	print("tap on %s, follow on %s, stick on %s, arc on %s" % [str(DirChaseTap.on()), str(DirFollow.on()), str(DirStick.on()), str(DirArc.on())])
	for wait in [0, 2, 4, 8, 12, 20, 30, 45, 60, 90]:
		var line: Array = []
		for sd in range(1, 4):
			line.append(_one(sd, wait, "west"))
		print("X %d ticks after the send: %s" % [wait, " | ".join(line)])
	for btn in ["north", "east"]:
		print(btn, " 20 after the send: ", _one(2, 20, btn))
	print("chain, X as soon as he can: ", _chain(2))
	quit(0)


func _make(sd: int) -> SimState:
	hub = SimInputHub.new()
	held = {}
	var su: Dictionary = hub.setup()
	su["intro"] = false
	su["planet"] = 7
	su["touch"] = 2
	su["planetGen"] = 3
	var S := SimCore.createSim()
	SimCore.newMatch(S, sd, {"p1": false, "p2": false}, su)
	S.fighters[1].ai = null
	S.fighters[0].ki = 100.0
	S.fighters[1].ki = 100.0
	S.fighters[1].hp = 100000.0
	hub.set_pad_has_right_stick(0, true)
	t = 0
	sentAt = -1
	sentName = ""
	starts = []
	catches = []
	acks = []
	ends = []
	fastest = 0.0
	return S


func _btn(name: String, down: bool) -> void:
	if down == held.has(name):
		return
	if down:
		held[name] = true
	else:
		held.erase(name)
	hub.pad_button(0, name, down)


func _step(S: SimState) -> void:
	hub.set_humans(S.fighters[0].ai == null, S.fighters[1].ai == null)
	hub.set_struggle(0, SimDir.inStruggle(S, S.fighters[0]))
	var it: SimIntent = hub.intent(0)
	var pausing: bool = S.pause.left > 0
	var ox: float = S.fighters[0].x
	var oy: float = S.fighters[0].y
	if SimCore.step(S, [it, SimIntent.new()]):
		hub.consumed()
		var sp: float = SimDetMath.hypot(SimWrap.sdx(ox, S.fighters[0].x), S.fighters[0].y - oy) / SimConst.DT
		if DirChase.chasing(S.fighters[0]):
			fastest = maxf(fastest, sp)
	elif pausing:
		if S.pause.left > 0:
			hub.drop_edges()
		else:
			hub.resume()
	t += 1
	for e in S.out.fx:
		if e.type == "launch_plan" and sentAt < 0 and S.fighters[1].state == "launched":
			sentAt = t
			sentName = String(e.chosen)
		if e.type == "cue" and e.actor == 0.0:
			if e.kind == "chase":
				if e.text == "start":
					starts.append(t)
				elif e.text == "catch":
					catches.append(t)
				else:
					ends.append(String(e.text))
			if e.kind == "press_ack":
				acks.append(String(e.text))
	hub.on_events(S.out.fx)
	S.out.fx.clear()
	S.out.feed.clear()


func _toSend(S: SimState) -> bool:
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(A.x + 58.0)
	D.y = A.y
	for _k in range(5):
		_step(S)
	for _try in range(8):
		_btn("east", true)
		for _k in range(70):
			_step(S)
			if DirBrawl._g(A, DirBrawl.CHG) == 2 or sentAt >= 0:
				break
		_btn("east", false)
		for _k in range(40):
			_step(S)
			if sentAt >= 0:
				return D.state == "launched"
		D.x = SimWrap.wrap(A.x + 58.0)
		D.y = A.y
		D.state = "free"
	return false


func _one(sd: int, wait: int, btn: String) -> String:
	var S := _make(sd)
	if not _toSend(S):
		SimCore.dispose(S)
		return "no send"
	var A = S.fighters[0]
	var D = S.fighters[1]
	acks = []
	for _k in range(wait):
		_step(S)
	var inAir: bool = D.state == "launched"
	var d0: float = DirBands.dist(A, D)
	var hp: float = D.hp
	var k0: float = A.ki
	_btn(btn, true)
	_step(S)
	_btn(btn, false)
	var pressed: int = t
	for _k in range(240):
		_step(S)
		if not DirChase.chasing(A) and starts.size() > 0:
			break
		if starts.is_empty() and _k > 40:
			break
	var r: String = "%s %s %.0f away: %s to catch, %.0f u/s, took %.0f, ki %.0f, %s %s" % [sentName, "air" if inAir else D.state, d0, str(catches[0] - pressed) if catches.size() > 0 else "no catch", fastest, hp - D.hp, k0 - A.ki, str(ends), str(acks)]
	SimCore.dispose(S)
	return r


func _chain(sd: int) -> String:
	var S := _make(sd)
	if not _toSend(S):
		SimCore.dispose(S)
		return "no send"
	var A = S.fighters[0]
	var D = S.fighters[1]
	var out: Array = []
	var was: int = 0
	var downAt: int = -1
	for _k in range(1200):
		if D.state != "launched":
			downAt = t
			break
		if not DirChase.chasing(A) and catches.size() >= was:
			_btn("west", true)
			_step(S)
			_btn("west", false)
			if DirChase.chasing(A):
				was = catches.size() + 1
				out.append("t%d ki%.0f" % [t, A.ki])
			elif not acks.is_empty() and acks[acks.size() - 1] == "chase_no_ki":
				out.append("no ki at t%d" % t)
				break
		_step(S)
	var r: String = ", ".join(out) + "; catches %d; down at %d, sent at %d" % [catches.size(), downAt, sentAt]
	SimCore.dispose(S)
	return r
