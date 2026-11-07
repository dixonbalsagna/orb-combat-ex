extends SceneTree
## The scheme gauntlet's player (Tools; docs/tools/feel.md): one scripted pad on the real input hub plays whole seeded matches against the computer at one level, and the run is read the same way for every arm and every scheme.
##   godot --headless --path <tree copy with qa/godot/qa_planet.gd> --script <this file> -- <matches> <baseSeed> --arm=stick|masher|timing|beam|circle|orbs --level=easy|medium|hard [--capsec=900] [--wall=300] [--budget=3600]
## The arms (the pad is slot 0 in every match, so a spawn side effect is in all alike; every arm walks at the rival with the left stick):
##   stick   a right-stick flick in one of the four directions every 8 to 24 ticks (nothing else)
##   orbs    (asked for by name, not in the default five) Orb's scheme: a right-stick flick every 30 to 48 ticks (thumb pace) and LB for 10 ticks on every wind-up of his; nothing else
##   masher  X every 8 ticks (nothing else)
##   timing  LB for 10 ticks when his blow winds up (a heavy's wind-up or any "windup" start cue, lights too; the perfect block's window), then X straight after; X every 8 ticks otherwise
##   beam    RB held and the right stick held toward him for 40 ticks, then let go to fire, then RB off; X every 8 ticks to build energy while it cannot pay
##   circle  LT held, the left stick toward, up, down, away or neutral, and a face button (X 60%, Y 25%, B 15%) every 8 to 16 ticks (the flight strike's grammar)
## Reads, for the pad: the match won or lost, presses made, refusals (every cue that says a press was not honoured) by reason, ticks without control (locked, launched, down, stunned, reeling), beams fired, hits landed and taken.
## Read-only with respect to sim/. One line, GAUNTLET <json>.
const QaPlanet = preload("res://qa/godot/qa_planet.gd")
const NOT_HONOURED: Array = ["refused", "double", "zip", "lapsed", "stunned", "chase_no_ki", "chase_late"]

var hub: SimInputHub
var held: Dictionary = {}
var _bm = null
var _foe_windup_t: int = -100   # the tick of the rival's last "windup" start cue (every wound blow, lights included): the timing pad guards on it


func _init() -> void:
	var pos: Array = []
	var arm: String = "stick"
	var level: String = "medium"
	var capsec: float = 900.0
	var wall: float = 300.0
	var budget: float = 3600.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--arm="):
			arm = a.substr(6)
		elif a.begins_with("--level="):
			level = a.substr(8)
		elif a.begins_with("--capsec="):
			capsec = float(a.substr(9))
		elif a.begins_with("--wall="):
			wall = float(a.substr(7))
		elif a.begins_with("--budget="):
			budget = float(a.substr(9))
		else:
			pos.append(a)
	var n: int = int(pos[0]) if pos.size() > 0 else 10
	var base: int = int(pos[1]) if pos.size() > 1 else 1
	SimInputData.load_and_apply()
	var dai = load("res://sim/director/ai.gd")
	var dend = load("res://sim/director/ending.gd") if ResourceLoader.exists("res://sim/director/ending.gd") else null
	dai.set("level", level)
	var tot := {"won": 0, "lost": 0, "draws": 0, "timeouts": 0, "capped": 0, "presses": 0, "refused": 0, "noControl": 0, "ticks": 0, "beams": 0, "foeBeams": 0, "hits": 0, "hitsTaken": 0}
	var by: Dictionary = {}
	var lens: Array = []
	var done: int = 0
	var stopped: bool = false
	var t_all: int = Time.get_ticks_msec()
	for m in range(n):
		if float(Time.get_ticks_msec() - t_all) / 1000.0 > budget:
			stopped = true
			break
		var seed_: int = base + m
		var S := _make(seed_)
		if QaPlanet.fellBack(S, seed_):
			quit(3)
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_
		var st := {"next": 20, "rel": {}, "rsTo": -1, "aim": Vector2.ZERO, "ltTo": -1, "stk": Vector2.ZERO, "beam": 0, "bTo": 0, "cool": 0, "lbTo": -1, "xAt": -1, "gNext": 0, "presses": 0}
		_btn("west", true)       # as the stick player of qa/godot/stickplay.gd begins: one X, so the pad is the human
		st.rel[2] = ["west"]
		var t0: int = Time.get_ticks_msec()
		var result: String = "timeout"
		var koSeen: int = -1
		var cap: int = int(capsec * 60.0)
		for t in range(cap):
			_drive(arm, S, t, st, rng)
			_step(S, t, tot, by)
			if S.game.ko != null and koSeen < 0:
				koSeen = t
			if koSeen >= 0 and S.game.koT > 3.0:
				result = "won" if S.game.ko == S.fighters[1] else "lost"
				break
			if dend != null and bool(dend.noContest(S)):
				result = "draw"
				break
			if (Time.get_ticks_msec() - t0) / 1000.0 > wall:
				result = "capped"
				break
		tot.ticks += S.tick
		tot.presses += int(st.presses)
		lens.append(float(S.tick) / 60.0)
		match result:
			"won":
				tot.won += 1
			"lost":
				tot.lost += 1
			"draw":
				tot.draws += 1
			"capped":
				tot.capped += 1
			_:
				tot.timeouts += 1
		done += 1
		for k in held.keys():
			_btn(k, false)
		SimCore.dispose(S)
	lens.sort()
	var med: float = lens[lens.size() / 2] if lens.size() > 0 else 0.0
	var out: Dictionary = tot.duplicate()
	out["arm"] = arm
	out["level"] = level
	out["n"] = n
	out["done"] = done
	out["budgetStopped"] = stopped
	out["medianSec"] = snappedf(med, 0.1)
	out["refusedBy"] = by
	print("GAUNTLET " + JSON.stringify(out))
	quit()


func _make(seed_: int) -> SimState:
	hub = SimInputHub.new()
	held = {}
	var su: Dictionary = QaPlanet.setup(seed_, hub.setup())
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {"p1": false, "p2": true}, su)
	hub.set_pad_has_right_stick(0, true)
	return S


func _btn(name: String, down: bool) -> void:
	if down == held.has(name):
		return
	if down:
		held[name] = true
	else:
		held.erase(name)
	hub.pad_button(0, name, down)


func _walk(S: SimState) -> void:
	var dx: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)
	var dy: float = S.fighters[1].y - S.fighters[0].y
	hub.pad_stick(0, signf(dx) if absf(dx) > 110.0 else 0.0, signf(dy) if absf(dy) > 40.0 else 0.0)


func _aim(S: SimState, dir: int) -> Vector2:
	var side: float = 1.0 if SimWrap.sdx(S.fighters[0].x, S.fighters[1].x) >= 0.0 else -1.0
	match dir:
		1:
			return Vector2(0.0, 1.0)
		2:
			return Vector2(0.0, -1.0)
		3:
			return Vector2(side, 0.0)
	return Vector2(-side, 0.0)


## A press of the face buttons for two ticks.
func _tap(st: Dictionary, t: int, names: Array) -> void:
	for nm in names:
		_btn(nm, true)
	st.rel[t + 2] = names
	st.presses = int(st.presses) + 1


func _drive(arm: String, S: SimState, t: int, st: Dictionary, rng: RandomNumberGenerator) -> void:
	var me = S.fighters[0]
	var foe = S.fighters[1]
	var walking: bool = true
	if st.rel.has(t):
		for nm in st.rel[t]:
			_btn(nm, false)
		st.rel.erase(t)
	match arm:
		"stick":
			if t >= int(st.next):
				st.aim = _aim(S, rng.randi_range(1, 4))
				st.rsTo = t + 3
				st.presses = int(st.presses) + 1
				st.next = t + rng.randi_range(8, 24)
			if t < int(st.rsTo):
				hub.pad_stick_right(0, st.aim.x, st.aim.y)
			elif t == int(st.rsTo):
				hub.pad_stick_right(0, 0.0, 0.0)
		"orbs":
			# Orb's scheme, fair: the right thumb flicks (three ticks out, never faster than about two a second: every 30 to 48 ticks) and the left hand guards, LB for 10 ticks, on every wind-up of his (the same wind-up read as the timing pad), walking as the others do
			if t >= int(st.next):
				st.aim = _aim(S, rng.randi_range(1, 4))
				st.rsTo = t + 3
				st.presses = int(st.presses) + 1
				st.next = t + rng.randi_range(30, 48)
			if t < int(st.rsTo):
				hub.pad_stick_right(0, st.aim.x, st.aim.y)
			elif t == int(st.rsTo):
				hub.pad_stick_right(0, 0.0, 0.0)
			var wound: bool = (not DirBrawl.winding(S, foe).is_empty()) or (t - _foe_windup_t <= 3)
			if int(st.lbTo) >= 0:
				if t >= int(st.lbTo):
					_btn("lb", false)
					st.lbTo = -1
			elif wound and t >= int(st.gNext):
				_btn("lb", true)
				st.lbTo = t + 10
				st.gNext = t + 14
				st.presses = int(st.presses) + 1
		"masher":
			if t >= int(st.next):
				_tap(st, t, ["west"])
				st.next = t + 8
		"timing":
			var winding: bool = (not DirBrawl.winding(S, foe).is_empty()) or (t - _foe_windup_t <= 3)   # a heavy's wind-up, or any "windup" start cue of the rival's (the lights too)
			if int(st.lbTo) >= 0:
				if t >= int(st.lbTo):
					_btn("lb", false)
					st.lbTo = -1
					_tap(st, t, ["west"])
					st.next = t + 8
			elif winding and t >= int(st.next):
				_btn("lb", true)
				st.lbTo = t + 10
				st.presses = int(st.presses) + 1
			elif t >= int(st.next):
				_tap(st, t, ["west"])
				st.next = t + 8
		"beam":
			var b: int = int(st.beam)
			if b == 0:
				if me.ki >= 30.0 and me.state == "free" and t >= int(st.cool):
					_btn("rb", true)
					st.beam = 1
					st.bTo = t + 40
					st.presses = int(st.presses) + 1
				elif t >= int(st.next):
					_tap(st, t, ["west"])
					st.next = t + 8
			elif b == 1:
				var a: Vector2 = _aim(S, 3)
				hub.pad_stick_right(0, a.x, a.y)
				if t >= int(st.bTo):
					hub.pad_stick_right(0, 0.0, 0.0)
					st.beam = 2
					st.bTo = t + 6
			else:
				if t >= int(st.bTo):
					_btn("rb", false)
					st.beam = 0
					st.cool = t + 30
		"circle":
			if int(st.ltTo) >= 0 and t > int(st.ltTo):
				hub.pad_trigger(0, "lt", 0.0)
				st.ltTo = -1
			if t >= int(st.next):
				var side: float = 1.0 if SimWrap.sdx(me.x, foe.x) >= 0.0 else -1.0
				var bi: int = rng.randi_range(0, 4)
				st.stk = [Vector2.ZERO, Vector2(side, 0.0), Vector2(0.0, 1.0), Vector2(0.0, -1.0), Vector2(-side, 0.0)][bi]
				st.ltTo = t + 8
				hub.pad_trigger(0, "lt", 1.0)
				var r: float = rng.randf()
				_tap(st, t, ["west" if r < 0.6 else ("north" if r < 0.85 else "east")])
				st.next = t + rng.randi_range(8, 16)
			if int(st.ltTo) >= t:
				hub.pad_stick(0, st.stk.x, st.stk.y)
				walking = false
	if walking:
		_walk(S)


func _refusal(e) -> bool:
	var k: String = str(e.kind)
	if k == "press_ack":
		return NOT_HONOURED.has(str(e.text))
	if k == "press_refused" and (str(e.source) == "stun_limit" or str(e.text) == "stun_limit"):
		return false   # a blow that landed on an already stunned rival (about 700 a match): it is a landed hit, not a refusal (the EP, 2026-11-07)
	return k.ends_with("_refused")


func _reason(e) -> String:
	var k: String = str(e.kind)
	if k == "press_ack":
		return "press_" + str(e.text) + "/" + str(e.source)
	if k == "stick_refused":
		return "stick/" + str(e.source)
	var s: String = str(e.source) if str(e.source) != "" else str(e.text)
	return k + ("/" + s if s != "" else "")


## One tick in the host's order (render/core/sim_host.gd tick), read as it goes.
func _step(S: SimState, t: int, tot: Dictionary, by: Dictionary) -> void:
	hub.set_humans(S.fighters[0].ai == null, S.fighters[1].ai == null)
	# The push word, as the host passes it (sim_host.gd): in a stick-push struggle the right stick pushes. Called by name, so an older tree (no pushModeOf, a two-argument set_struggle) still runs.
	if _bm == null:
		_bm = load("res://sim/director/beam.gd")
	var hb: Object = hub
	var in_s: bool = SimDir.inStruggle(S, S.fighters[0])
	if _bm != null and _bm.has_method("pushModeOf"):
		hb.call("set_struggle", 0, in_s, str(_bm.call("pushModeOf", S, S.fighters[0])) == "stick")
	else:
		hb.call("set_struggle", 0, in_s)
	var it: SimIntent = hub.intent(0)
	var pausing: bool = S.pause.left > 0
	if SimCore.step(S, [it, null]):
		hub.consumed()
	elif pausing:
		if S.pause.left > 0:
			hub.drop_edges()
		else:
			hub.resume()
	for e in S.out.fx:
		if e.type == "cue":
			var who: int = int(e.actor)
			var k: String = str(e.kind)
			if k == "windup" and who == 1 and str(e.text) == "start":
				_foe_windup_t = t
			if k == "beam_fire":
				tot["beams" if who == 0 else "foeBeams"] += 1
			elif who == 0 and _refusal(e):
				tot.refused += 1
				var why: String = _reason(e)
				by[why] = int(by.get(why, 0)) + 1
		elif e.type == "damage":
			if int(e.attacker) == 0 and int(e.victim) != 0:
				tot.hits += 1
			elif int(e.victim) == 0 and int(e.attacker) != 0:
				tot.hitsTaken += 1
	var f = S.fighters[0]
	if f.state == "locked" or f.state == "launched" or f.state == "down" or f.stunTicks > 0 or f.embedT > 0:
		tot.noControl += 1
	hub.on_events(S.out.fx)
	S.out.fx.clear()
	S.out.feed.clear()
