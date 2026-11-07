extends SceneTree
## The controller audit (Controls, 2026-11-01): every stick direction, button, hold, tap and mash on the live Arena map, run through the REAL hub into SimCore on a real
## match (a new seed per case, a standing opponent), and what the sim did in the next 90 ticks. One line per case. From a tree with the right-hand work on:
##   godot --headless --path . --script res://sim/input/tools/audit_probe.gd [-- --soak]
## The columns: first = the first tick (from the input) the fighter's state, a rush, an exchange or his ki changed; ex = the exchange's template; ev = the sim's events
## by name (first 7); hit = damage to the opponent; ki = his change; st = the fighter's state at the end. --soak plays six seeds of a mash bot against the AI instead.
## Switches are set in memory (rightStick, quickRead on); timing.json need not carry them.

const WINDOW: int = 90

var rows: Array = []


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["quickRead"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	var args: PackedStringArray = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if args.has("--soak"):
		_soak()
	elif args.has("--defence"):
		_defence()
	else:
		_cases()
	quit(0)


# ---- scripted cases ----------------------------------------------------------------------------------------------------------------------------

func _tap(b: String, at: int = 0, len: int = 3) -> Array:
	return [[at, "b", b, true], [at + len, "b", b, false]]


func _hold(b: String, at: int = 0, len: int = 40) -> Array:
	return [[at, "b", b, true], [at + len, "b", b, false]]


func _mash(b: String, n: int = 8, gap: int = 6) -> Array:
	var out: Array = []
	for k in range(n):
		out.append([k * gap, "b", b, true])
		out.append([k * gap + 2, "b", b, false])
	return out


func _trig(t: String, at: int = 0, len: int = 3) -> Array:
	return [[at, "t", t, 1.0], [at + len, "t", t, 0.0]]


func _flick(side: String, dx: float, dy: float, at: int = 0, len: int = 3) -> Array:
	return [[at, side, "", dx, dy], [at + len, side, "", 0.0, 0.0]]


func _hold_stick(side: String, dx: float, dy: float, at: int = 0, len: int = 40) -> Array:
	return [[at, side, "", dx, dy], [at + len, side, "", 0.0, 0.0]]


func _cases() -> void:
	# what is held before the input (the stance layer)
	var layers: Array = [
		["none", []],
		["LB", [[-10, "b", "lb", true]]],
		["RB", [[-10, "b", "rb", true]]],
		["LT", [[-10, "t", "lt", 1.0]]],
		["RT", [[-10, "t", "rt", 1.0]]],
		["LB+RB", [[-10, "b", "lb", true], [-10, "b", "rb", true]]],
		["LT+RB", [[-10, "t", "lt", 1.0], [-10, "b", "rb", true]]],
		["LT+LB", [[-10, "t", "lt", 1.0], [-10, "b", "lb", true]]],
	]
	print("== AUDIT: Arena pad, right stick on, quick read on, a standing opponent 80 units away (close) or 250 (far); 90 ticks from the input ==")
	print("-- movement and the left hand")
	for d in [["right", 1.0, 0.0], ["left", -1.0, 0.0], ["up", 0.0, 1.0], ["down", 0.0, -1.0], ["up-right", 0.7, 0.7]]:
		_run("move %s (held 40)" % d[0], 250.0, [], _hold_stick("ls", d[1], d[2]))
	_run("dodge tap (LT)", 80.0, [], _trig("lt"))
	_run("dodge tap + stick right", 80.0, [[-2, "ls", "", 1.0, 0.0]], _trig("lt"))
	_run("dodge tap + stick up", 80.0, [[-2, "ls", "", 0.0, 1.0]], _trig("lt"))
	_run("dodge tap + stick away", 80.0, [[-2, "ls", "", -1.0, 0.0]], _trig("lt"))
	_run("dodge held 40 (LT)", 80.0, [], _trig("lt", 0, 40))
	_run("guard tap (LB)", 80.0, [], _tap("lb"))
	_run("guard held 40 (LB)", 80.0, [], _hold("lb"))
	_run("brace: LB held + flick up", 80.0, [[-12, "b", "lb", true]], _flick("ls", 0.0, 1.0))
	_run("brace: LB held + flick down", 80.0, [[-12, "b", "lb", true]], _flick("ls", 0.0, -1.0))
	_run("brace: LB held + flick right", 80.0, [[-12, "b", "lb", true]], _flick("ls", 1.0, 0.0))
	_run("brace: LB held + flick left", 80.0, [[-12, "b", "lb", true]], _flick("ls", -1.0, 0.0))
	_run("brace button (L3), stick up held", 80.0, [[-3, "ls", "", 0.0, 1.0]], _tap("l3"))
	_run("vanish: LB + LT together", 80.0, [], [[0, "b", "lb", true], [0, "t", "lt", 1.0], [8, "b", "lb", false], [8, "t", "lt", 0.0]])
	_run("vanish: LB + LT together, stick right", 80.0, [[-2, "ls", "", 1.0, 0.0]], [[0, "b", "lb", true], [0, "t", "lt", 1.0], [8, "b", "lb", false], [8, "t", "lt", 0.0]])
	_run("escape (R3)", 80.0, [], _tap("r3"))
	_run("transform chord (LT + RT)", 80.0, [], [[0, "t", "lt", 1.0], [0, "t", "rt", 1.0], [8, "t", "lt", 0.0], [8, "t", "rt", 0.0]])
	_run("mode toggle (RB tap)", 80.0, [], _tap("rb"))
	_run("power (RT held 40)", 80.0, [], _trig("rt", 0, 40))
	print("-- face buttons, by layer (X light, Y heavy, B signature, A context)")
	for lay in layers:
		for f in [["X", "west"], ["Y", "north"], ["B", "east"], ["A", "south"]]:
			_run("%s tap, layer %s" % [f[0], lay[0]], 80.0, lay[1], _tap(f[1]))
	for lay in [layers[0], layers[1], layers[2]]:
		for f in [["X", "west"], ["Y", "north"], ["B", "east"]]:
			_run("%s held 40, layer %s" % [f[0], lay[0]], 80.0, lay[1], _hold(f[1]))
			_run("%s mashed (8 in 48), layer %s" % [f[0], lay[0]], 80.0, lay[1], _mash(f[1]))
	_run("X tap, far (250)", 250.0, [], _tap("west"))
	_run("Y tap, far (250)", 250.0, [], _tap("north"))
	_run("B tap, far (250)", 250.0, [], _tap("east"))
	print("-- the right stick (strike class), by layer")
	for lay in layers:
		for d in [["right (toward)", 1.0, 0.0], ["left (away)", -1.0, 0.0], ["up", 0.0, 1.0], ["down", 0.0, -1.0]]:
			_run("stick %s flick, layer %s" % [d[0], lay[0]], 80.0, lay[1], _flick("rs", d[1], d[2]))
	for lay in [layers[0], layers[1], layers[2], layers[3], layers[6]]:
		_run("stick right HOLD 40 then release, layer %s" % lay[0], 80.0, lay[1], _hold_stick("rs", 1.0, 0.0, 0, 40))
		_run("stick right HOLD 70 then release, layer %s" % lay[0], 80.0, lay[1], _hold_stick("rs", 1.0, 0.0, 0, 70))
	_run("stick flick, far (250), no layer", 250.0, [], _flick("rs", 1.0, 0.0))
	_run("stick up flick, in the air", 80.0, [[-30, "ls", "", 0.0, 1.0], [-6, "ls", "", 0.0, 0.0]], _flick("rs", 0.0, 1.0))
	_run("stick mashed (8 flicks in 48)", 80.0, [], _stick_mash())
	_run("D-pad right (mirror off)", 80.0, [], _tap("dpad_right"))
	_run("D-pad up (mirror off)", 80.0, [], _tap("dpad_up"))
	_run("X then stick (claw order)", 80.0, [], _tap("west") + _flick("rs", 1.0, 0.0, 2))
	_run("stick then X (claw order)", 80.0, [], _flick("rs", 1.0, 0.0, 0) + _tap("west", 4))
	_run("B held + stick, layer RB (E131)", 80.0, [[-10, "b", "rb", true]], [[0, "b", "east", true], [3, "rs", "", 1.0, 0.0], [20, "rs", "", 0.0, 0.0], [40, "b", "east", false]])
	_run("RT charged 60, then X (special 1)", 80.0, [[-20, "t", "rt", 1.0]], [[40, "b", "west", true], [43, "b", "west", false]])
	_run("RT charged 60, then Y (special 2)", 80.0, [[-20, "t", "rt", 1.0]], [[40, "b", "north", true], [43, "b", "north", false]])
	_run("RT charged 60, then A (special 3)", 80.0, [[-20, "t", "rt", 1.0]], [[40, "b", "south", true], [43, "b", "south", false]])
	_run("start (pause)", 80.0, [], _tap("start"))
	_run("back (hints)", 80.0, [], _tap("back"))


func _stick_mash() -> Array:
	var out: Array = []
	for k in range(8):
		out.append([k * 6, "rs", "", 1.0, 0.0])
		out.append([k * 6 + 3, "rs", "", 0.0, 0.0])
	return out


func _apply(hub: SimInputHub, e: Array) -> void:
	match str(e[1]):
		"b":
			hub.pad_button(7, str(e[2]), bool(e[3]))
		"t":
			hub.pad_trigger(7, str(e[2]), float(e[3]))
		"ls":
			hub.pad_stick(7, float(e[3]), float(e[4]))
		"rs":
			hub.pad_stick_right(7, float(e[3]), float(e[4]))


func _run(name: String, dist: float, pre: Array, script: Array) -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	b.x = SimWrap.wrap(a.x + dist)
	b.y = a.y
	var quiet := SimIntent.new()
	for t in range(30):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	# the stance layer is held before tick 0 (negative offsets)
	var all: Array = pre + script
	var first_tick: int = -20
	var tpl: String = ""
	var names: Dictionary = {}
	var hp0: float = float(b.hp)
	var ki0: float = float(a.ki)
	var x0: float = a.x
	var y0: float = a.y
	var act0: Dictionary = _act_snapshot(a)
	var states: Dictionary = {}
	var all_ev: Dictionary = {}
	var act_ever: Dictionary = {}
	var edges: Dictionary = {}
	var ex_seen: bool = false
	var first: int = -1
	var rumble: Dictionary = {}
	var rs_start: int = -1
	for t in range(first_tick, WINDOW):
		for e in all:
			if int(e[0]) == t:
				_apply(hub, e)
		var i: SimIntent = hub.intent(0)
		for r in hub.take_haptics():
			rumble[String(r["kind"])] = true
		if t >= 0:
			for en in ["light", "heavy", "sig", "context", "dodge", "guardPress", "escape", "brace", "rsStart", "rsRelease", "rsCancel", "mode", "powerPress", "transform"]:
				if bool(i.get(en)):
					edges[en] = true
			if int(i.special) != 0:
				edges["special" + str(i.special)] = true
		if i.rsStart and rs_start < 0 and t >= 0:
			rs_start = t
		SimCore.step(S, [i, quiet])
		hub.consumed()
		if t >= 0:
			if S.dirS.ex != null and tpl == "":
				tpl = str(S.dirS.ex.tpl)
			states[str(a.state)] = true
			var snap_now: Dictionary = _act_snapshot(a)
			for k in snap_now:
				if snap_now[k] != act0.get(k):
					act_ever[k] = true
			var changed: bool = S.dirS.ex != null or a.rush != null or a.state != "free" or _act_snapshot(a) != act0
			for e in S.out.fx:
				var nm: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
				if nm != "press_ack" and int(e.actor) == 0 and names.size() < 8:
					names[nm] = true
				if nm != "press_ack":
					all_ev[nm] = true
			if changed and first < 0:
				first = t
		S.out.fx.clear()
	var dmg: float = hp0 - float(b.hp)
	var ch: Array = act_ever.keys()
	ch.sort()
	var ed: Array = edges.keys()
	ed.sort()
	var sts: Array = states.keys()
	sts.sort()
	var other: Array = []
	for k in all_ev:
		if not names.has(k):
			other.append(k)
	other.sort()
	var moved: float = SimWrap.sdx(x0, a.x)
	var ev: Array = names.keys()
	ev.sort()
	var kinds: Array = rumble.keys()
	kinds.sort()
	print("%-44s first %3s  ex %-10s hit %5.1f  ki %+6.1f  dx %+7.0f dy %+5.0f  st %s | act %s | in %s | ev %s%s%s" % [name, "-" if first < 0 else str(first), tpl if tpl != "" else "-", dmg, float(a.ki) - ki0, moved, float(a.y) - y0, ",".join(sts), ",".join(ch), ",".join(ed), ",".join(ev), (" +other: " + ",".join(other)) if other.size() > 0 else "", ("  rumble " + ",".join(kinds)) if kinds.size() > 0 else ""])
	SimCore.dispose(S)


## The fighter's act record as a dictionary of its plain values (what his presses changed).
func _act_snapshot(f) -> Dictionary:
	var out: Dictionary = {}
	for pr in f.act.get_property_list():
		var n: String = str(pr["name"])
		if int(pr["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var v = f.act.get(n)
		if v is int or v is bool or v is float:
			out[n] = v
	return out


# ---- real play: defence against the AI ---------------------------------------------------------------------------------------------------------

## What each defensive input does in a real fight: the AI attacks a standing player for 600 ticks, on eight seeds; the damage he takes, with each input
## repeated on a steady beat. The baseline is doing nothing.
func _defence() -> void:
	print("== DEFENCE in real play: the AI (opponent) attacks a pad player who only does the input named, 600 ticks, 8 seeds; mean HP lost by the player (lower is better) and by the AI ==")
	var plans: Array = [
		["nothing", []],
		["guard held (LB)", [[0, "b", "lb", true]]],
		["guard tapped every 20 ticks", _beat("b", "lb", 20, 6)],
		["dodge tapped every 30 ticks, stick away", [[0, "ls", "", -1.0, 0.0]] + _beat("t", "lt", 30, 3)],
		["dodge tapped every 30 ticks, no stick", _beat("t", "lt", 30, 3)],
		["brace: LB held + flick up every 40", [[0, "b", "lb", true]] + _flicks_left(40, 0.0, 1.0)],
		["brace: LB held + flick toward every 40", [[0, "b", "lb", true]] + _flicks_left(40, 1.0, 0.0)],
		["brace button (L3) every 40, stick up", [[0, "ls", "", 0.0, 1.0]] + _beat("b", "l3", 40, 3)],
		["vanish: LB + LT every 60", _vanish_beat(60)],
		["stick strike toward every 30", _flicks_right(30, 1.0, 0.0)],
		["X mash (light)", _beat("b", "west", 8, 3)],
		["Y every 40 (heavy)", _beat("b", "north", 40, 3)],
	]
	for pl in plans:
		var lost: float = 0.0
		var dealt: float = 0.0
		var n: int = 0
		for seed_ in [3, 11, 29, 47, 101, 202, 303, 404]:
			var r: Array = _fight(seed_, pl[1])
			lost += r[0]
			dealt += r[1]
			n += 1
		print("%-44s lost %6.1f   dealt %6.1f" % [pl[0], lost / float(n), dealt / float(n)])


func _beat(kind: String, ctl: String, every: int, len: int) -> Array:
	var out: Array = []
	var t: int = 10
	while t < 600:
		if kind == "b":
			out.append([t, "b", ctl, true])
			out.append([t + len, "b", ctl, false])
		else:
			out.append([t, "t", ctl, 1.0])
			out.append([t + len, "t", ctl, 0.0])
		t += every
	return out


func _flicks_left(every: int, dx: float, dy: float) -> Array:
	var out: Array = []
	var t: int = 12
	while t < 600:
		out.append([t, "ls", "", dx, dy])
		out.append([t + 3, "ls", "", 0.0, 0.0])
		t += every
	return out


func _flicks_right(every: int, dx: float, dy: float) -> Array:
	var out: Array = []
	var t: int = 12
	while t < 600:
		out.append([t, "rs", "", dx, dy])
		out.append([t + 3, "rs", "", 0.0, 0.0])
		t += every
	return out


func _vanish_beat(every: int) -> Array:
	var out: Array = []
	var t: int = 12
	while t < 600:
		out.append([t, "b", "lb", true])
		out.append([t, "t", "lt", 1.0])
		out.append([t + 8, "b", "lb", false])
		out.append([t + 8, "t", "lt", 0.0])
		t += every
	return out


## One fight against the AI: returns [hp the player lost, hp the AI lost] over 600 ticks.
func _fight(seed_: int, script: Array) -> Array:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {"p1": false, "p2": true}, su)
	for t in range(30):
		SimCore.step(S, [hub.intent(0), null])
		hub.consumed()
		S.out.fx.clear()
	var a = S.fighters[0]
	var b = S.fighters[1]
	var hp_a: float = float(a.hp)
	var hp_b: float = float(b.hp)
	for t in range(600):
		for e in script:
			if int(e[0]) == t:
				_apply(hub, e)
		SimCore.step(S, [hub.intent(0), null])
		hub.consumed()
		hub.take_haptics()
		S.out.fx.clear()
	var res: Array = [hp_a - float(a.hp), hp_b - float(b.hp)]
	SimCore.dispose(S)
	return res


# ---- real play: a mash bot against the AI ----------------------------------------------------------------------------------------------------

func _soak() -> void:
	print("== SOAK: a mash bot on the pad against the AI, six seeds of 3000 ticks, rightStick and quickRead on ==")
	var tot: Dictionary = {}
	for seed_ in [3, 11, 29, 47, 101, 2026]:
		var hub := SimInputHub.new()
		hub.set_humans(true, false)
		hub.pad_button(7, "south", true)
		hub.pad_button(7, "south", false)
		hub.take_joins()
		hub.set_humans(true, false)
		var su: Dictionary = hub.setup()
		su["intro"] = false
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed_, {"p1": false, "p2": true}, su)
		var lcg: int = seed_ * 7919 + 13
		var held: Dictionary = {}
		var counts: Dictionary = {}
		var hp_diff: float = 0.0
		for t in range(3000):
			lcg = (lcg * 1103515245 + 12345) & 0x7fffffff
			var r: int = lcg % 97
			if t % 5 == 0:
				# a random control, pressed or let go
				var ctl: Array = [["b", "west"], ["b", "north"], ["b", "east"], ["b", "south"], ["b", "lb"], ["b", "rb"], ["t", "lt"], ["t", "rt"], ["rs", ""], ["ls", ""], ["b", "l3"]]
				var c: Array = ctl[r % ctl.size()]
				match c[0]:
					"b":
						var key: String = "b" + str(c[1])
						var down: bool = not bool(held.get(key, false))
						held[key] = down
						hub.pad_button(7, str(c[1]), down)
					"t":
						var tk: String = "t" + str(c[1])
						var tv: float = 0.0 if float(held.get(tk, 0.0)) > 0.5 else 1.0
						held[tk] = tv
						hub.pad_trigger(7, str(c[1]), tv)
					"rs":
						var ang: float = float(lcg % 360)
						var m: float = 0.0 if float(held.get("rs", 0.0)) > 0.5 else 1.0
						held["rs"] = m
						hub.pad_stick_right(7, cos(deg_to_rad(ang)) * m, sin(deg_to_rad(ang)) * m)
					"ls":
						var ang2: float = float(lcg % 360)
						var m2: float = 0.0 if float(held.get("ls", 0.0)) > 0.5 else 1.0
						held["ls"] = m2
						hub.pad_stick(7, cos(deg_to_rad(ang2)) * m2, sin(deg_to_rad(ang2)) * m2)
			var i: SimIntent = hub.intent(0)
			if i.rsStart:
				counts["rsStart"] = int(counts.get("rsStart", 0)) + 1
			if i.rsRelease:
				counts["rsRelease"] = int(counts.get("rsRelease", 0)) + 1
			if i.brace:
				counts["brace"] = int(counts.get("brace", 0)) + 1
			if i.escape:
				counts["escape"] = int(counts.get("escape", 0)) + 1
			for rq in hub.take_haptics():
				counts["rumble_" + String(rq["kind"])] = int(counts.get("rumble_" + String(rq["kind"]), 0)) + 1
			SimCore.step(S, [i, null])
			hub.consumed()
			for e in S.out.fx:
				var nm: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
				if nm in ["stick_start", "stick_release", "stick_hit", "stick_charge", "beam_window", "brace_set", "vanish", "struggle_press"]:
					counts[nm] = int(counts.get(nm, 0)) + 1
			S.out.fx.clear()
			if float(S.fighters[0].hp) <= 0.0 or float(S.fighters[1].hp) <= 0.0:
				break
		hp_diff = float(S.fighters[1].hp) - float(S.fighters[0].hp)
		print("seed %4d: ticks %d, hp %.0f vs %.0f, %s" % [seed_, S.tick, float(S.fighters[0].hp), float(S.fighters[1].hp), str(counts)])
		for k in counts:
			tot[k] = int(tot.get(k, 0)) + int(counts[k])
		SimCore.dispose(S)
	print("total: " + str(tot))
