extends SceneTree
## Headless checks for the hold-or-toggle styles of Guard, Dodge, Power and Transform (docs/controls/hold-toggles.md). For each action, on the
## keyboard and on the Arena pad, a HELD sequence and the matching TOGGLED sequence (press to start, press again to stop) go through the real hub
## into SimCore: the packed intents must be equal tick by tick, and so must the state hash after the run. Two negative controls show the compare
## bites (a toggle that was not switched on, a stop press that never comes). Also: auto-repeat is not a second press, player 2's own style, the
## style going back to hold, a new match, the cancel of a toggled transform, the ring, let_go_toggles(). From the repo root:
##   godot --headless --path . --script res://sim/input/test/hold_toggle_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0
const TICKS: int = 160


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	_data_default()
	_guard()
	_dodge()
	_power()
	_transform_chord()
	_transform_single()
	_negative()
	_auto_repeat()
	_second_player()
	_back_to_hold()
	_cancel_and_ring()
	_let_go()
	print("hold_toggle_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


## ---- scripts: [tick, kind, name, down]; kind "k" a key, "b" a pad button, "t" a pad trigger (down is 1.0 or 0.0 on the wire)

func _ev(t: int, kind: String, name: String, down: bool) -> Array:
	return [t, kind, name, down]


## A stint of one control: down at a, up at b.
func _stint(kind: String, name: String, a: int, b: int) -> Array:
	return [_ev(a, kind, name, true), _ev(b, kind, name, false)]


## The toggled form of a held script: each press and each release of a toggled control becomes a press (and its release two ticks on).
func _toggled(script: Array, names: Array) -> Array:
	var out: Array = []
	for e in script:
		if names.has(e[2]):
			out.append(_ev(e[0], e[1], e[2], true))
			out.append(_ev(e[0] + 2, e[1], e[2], false))
		else:
			out.append(e)
	return out


func _send(hub: SimInputHub, e: Array) -> void:
	match String(e[1]):
		"k":
			hub.key(String(e[2]), bool(e[3]))
		"b":
			hub.pad_button(7, String(e[2]), bool(e[3]))
		"t":
			hub.pad_trigger(7, String(e[2]), 1.0 if bool(e[3]) else 0.0)


## One run of a script through the hub into the sim. Returns {packs: [packed intent per tick], hash: the state hash after the run}.
func _run(dev: String, script: Array, styles: Dictionary) -> Dictionary:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	if dev == "pad":
		hub.pad_button(7, "south", true)
		hub.pad_button(7, "south", false)
		hub.take_joins()
		hub.set_humans(true, false)
	for a in styles:
		hub.set_hold_style(String(a), String(styles[a]), 0)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 200.0)
	S.fighters[1].y = S.fighters[0].y
	var quiet := SimIntent.new()
	var packs: Array = []
	for t in range(TICKS):
		for e in script:
			if int(e[0]) == t:
				_send(hub, e)
		var i: SimIntent = hub.intent(0)
		packs.append(SimIntent.pack(i))
		SimCore.step(S, [i, quiet])
		hub.consumed()
		S.out.fx.clear()
	var h: String = String(SimHash.stateHash(S).gameplay)
	SimCore.dispose(S)
	return {"packs": packs, "hash": h}


## The first tick the two runs differ, or -1.
func _first_diff(a: Array, b: Array) -> int:
	for t in range(mini(a.size(), b.size())):
		if a[t] != b[t]:
			return t
	return -1


func _same(dev: String, what: String, held: Array, toggled: Array, styles: Dictionary, anything_in_it: Callable) -> void:
	var r1: Dictionary = _run(dev, held, {})
	var r2: Dictionary = _run(dev, toggled, styles)
	var d: int = _first_diff(r1.packs, r2.packs)
	ok(d < 0, "%s [%s]: held and toggled give the same intent on all %d ticks (first difference: %s)" % [what, dev, TICKS, "none" if d < 0 else "tick %d, %x vs %x" % [d, r1.packs[d], r2.packs[d]]])
	ok(r1.hash == r2.hash, "%s [%s]: ... and the same state hash (%s)" % [what, dev, r1.hash])
	ok(anything_in_it.call(r1.packs), "%s [%s]: ... and the run is not empty (the held sequence does what it should)" % [what, dev])


func _any_bit(packs: Array, bit: int) -> bool:
	for p in packs:
		if (int(p) >> bit) & 1 == 1:
			return true
	return false


func _count_bit(packs: Array, bit: int) -> int:
	var n: int = 0
	for p in packs:
		if (int(p) >> bit) & 1 == 1:
			n += 1
	return n


## Bit numbers in SimIntent.pack: guard 23, guardPress 24, dodge 25, sprint 26, power 27, powerPress 28, powerTap 29, light 30, ..., transform 34.
const B_GUARD: int = 23
const B_GUARD_PRESS: int = 24
const B_DODGE: int = 25
const B_SPRINT: int = 26
const B_POWER: int = 27
const B_POWER_PRESS: int = 28
const B_POWER_TAP: int = 29
const B_TRANSFORM: int = 34


func _data_default() -> void:
	var hub := SimInputHub.new()
	for a in ["guard", "dodge", "power", "transform"]:
		ok(hub.hold_style_of(a, 0) == "hold" and hub.hold_style_of(a, 1) == "hold", "default: %s is hold for both players" % a)
	hub.set_hold_style("guard", "toggle", 1)
	ok(hub.hold_style_of("guard", 1) == "toggle" and hub.hold_style_of("guard", 0) == "hold", "setter: one slot's style is that player's own")
	hub.set_hold_style("guard", "toggle")
	ok(hub.hold_style_of("guard", 0) == "toggle", "setter: with no slot it is both players'")
	hub.set_hold_style("no-such-action", "toggle")
	ok(hub.hold_style_of("no-such-action", 0) == "hold", "setter: an unknown action is ignored")
	hub.set_hold_style("guard", "banana")
	ok(hub.hold_style_of("guard", 0) == "hold", "setter: an unknown style reads as hold")


func _guard() -> void:
	# Stints, a short tap (the perfect-block edge) and an attack thrown while the guard is up.
	for dev in ["kb", "pad"]:
		var g: String = "Shift" if dev == "kb" else "lb"
		var gk: String = "k" if dev == "kb" else "b"
		var lt: String = "KeyJ" if dev == "kb" else "west"
		var held: Array = _stint(gk, g, 10, 40) + _stint(gk, g, 55, 58) + _stint(gk, g, 70, 100) + _stint(gk, lt, 20, 22) + _stint(gk, lt, 85, 87)
		_same(dev, "guard", held, _toggled(held, [g]), {"guard": "toggle"}, func(p): return _count_bit(p, B_GUARD) > 40 and _any_bit(p, B_GUARD_PRESS))


func _dodge() -> void:
	for dev in ["kb", "pad"]:
		var d: String = "Space" if dev == "kb" else "lt"
		var k: String = "k" if dev == "kb" else "t"
		var mv: Array = _stint("k", "KeyD", 35, 75) if dev == "kb" else []
		var held: Array = _stint(k, d, 10, 13) + _stint(k, d, 30, 80) + mv
		_same(dev, "dodge", held, _toggled(held, [d]), {"dodge": "toggle"}, func(p): return _any_bit(p, B_DODGE) and _any_bit(p, B_SPRINT))


func _power() -> void:
	for dev in ["kb", "pad"]:
		var pw: String = "KeyE" if dev == "kb" else "rt"
		var k: String = "k" if dev == "kb" else "t"
		var held: Array = _stint(k, pw, 10, 13) + _stint(k, pw, 30, 70)
		_same(dev, "power", held, _toggled(held, [pw]), {"power": "toggle"}, func(p): return _any_bit(p, B_POWER_TAP) and _count_bit(p, B_POWER) > 30)


## The transform chord is the dodge and power controls together. Three ways to set the styles; held and toggled streams for sent and for cancelled.
func _transform_chord() -> void:
	for dev in ["kb", "pad"]:
		var a: String = "Space" if dev == "kb" else "lt"
		var b: String = "KeyE" if dev == "kb" else "rt"
		var k: String = "k" if dev == "kb" else "t"
		# Sent: both down inside the chord window, held past the half second.
		var held: Array = [_ev(10, k, a, true), _ev(12, k, b, true), _ev(60, k, a, false), _ev(60, k, b, false)]
		var tog: Array = [_ev(10, k, a, true), _ev(12, k, b, true), _ev(14, k, a, false), _ev(15, k, b, false)]   # both down at once for a moment, no more
		_same(dev, "transform chord, sent", held, tog, {"transform": "toggle"}, func(p): return _count_bit(p, B_TRANSFORM) == 1)
		# Cancelled: let go before the half second is up; the toggled cancel is one press of a chord control, which does nothing else.
		var held_c: Array = [_ev(10, k, a, true), _ev(12, k, b, true), _ev(30, k, a, false), _ev(30, k, b, false)]
		var tog_c: Array = tog + [_ev(30, k, a, true), _ev(31, k, a, false)]   # one press of a chord control cancels
		_same(dev, "transform chord, cancelled", held_c, tog_c, {"transform": "toggle"}, func(p): return _count_bit(p, B_TRANSFORM) == 0 and _any_bit(p, B_DODGE) and _any_bit(p, B_POWER_PRESS))
		# All three toggled together: the stances the chord was made of go with the transform.
		var held_all: Array = [_ev(10, k, a, true), _ev(12, k, b, true), _ev(60, k, a, false), _ev(60, k, b, false)]
		var tog_all: Array = tog
		var styles: Dictionary = {"dodge": "toggle", "power": "toggle", "transform": "toggle"}
		var r1: Dictionary = _run(dev, held_all, {})
		var r2: Dictionary = _run(dev, tog_all, styles)
		ok(_first_diff(r1.packs, r2.packs) < 0 and r1.hash == r2.hash and _count_bit(r2.packs, B_TRANSFORM) == 1, "transform chord, dodge and power toggled too [%s]: sent once, the same intent and hash as holding (the toggled stances end with it)" % dev)
		# After it is sent, nothing is left on: no power, no sprint.
		ok(not _any_bit(r2.packs.slice(60), B_POWER) and not _any_bit(r2.packs.slice(60), B_SPRINT), "transform chord, all toggled [%s]: no stance is left on after it is sent" % dev)
		# Dodge and power toggled, transform held: the chord is held for as long as both are on, and ends with the first stop press.
		var held_h: Array = [_ev(10, k, a, true), _ev(12, k, b, true), _ev(60, k, a, false), _ev(60, k, b, false)]
		var tog_h: Array = [_ev(10, k, a, true), _ev(12, k, b, true), _ev(14, k, a, false), _ev(15, k, b, false), _ev(60, k, a, true), _ev(61, k, a, false), _ev(62, k, b, true), _ev(63, k, b, false)]
		var s1: Dictionary = _run(dev, held_h, {})
		var s2: Dictionary = _run(dev, tog_h, {"dodge": "toggle", "power": "toggle"})
		var dd: int = _first_diff(s1.packs, s2.packs)
		# The streams part at the stop presses (tick 60): holding lets both go at once, two stop presses cannot. Up to there they are the same, and one transform is sent in each.
		ok(dd < 0 or dd >= 60, "transform chord, dodge and power toggled, transform held [%s]: the same as holding up to the stop presses (first difference: %d)" % [dev, dd])
		ok(_count_bit(s2.packs, B_TRANSFORM) == 1, "transform chord, dodge and power toggled, transform held [%s]: one transform" % dev)


func _transform_single() -> void:
	# The solo keyboard's own transform key (R): held, then toggled.
	var held: Array = _stint("k", "KeyR", 10, 60)
	_same("kb", "transform key, sent", held, _stint("k", "KeyR", 10, 12), {"transform": "toggle"}, func(p): return _count_bit(p, B_TRANSFORM) == 1)   # one press starts it; no stop press after it is sent
	var held_c: Array = _stint("k", "KeyR", 10, 25)
	var tog_c: Array = _stint("k", "KeyR", 10, 12) + _stint("k", "KeyR", 25, 27)
	_same("kb", "transform key, cancelled", held_c, tog_c, {"transform": "toggle"}, func(p): return _count_bit(p, B_TRANSFORM) == 0)
	# Toggled and tapped once: it is sent a half second later, with no finger on it.
	var r: Dictionary = _run("kb", _stint("k", "KeyR", 10, 12), {"transform": "toggle"})
	ok(_count_bit(r.packs, B_TRANSFORM) == 1, "transform key toggled: one tap starts it and it is sent on its own")
	var r0: Dictionary = _run("kb", _stint("k", "KeyR", 10, 12), {})
	ok(_count_bit(r0.packs, B_TRANSFORM) == 0, "transform key held style: a tap is not enough (the half second is a hold)")


## The compare bites: it must see a toggle that was not switched on, and a stop press that never comes.
func _negative() -> void:
	var held: Array = _stint("k", "Shift", 10, 40) + _stint("k", "Shift", 70, 100)
	var tog: Array = _toggled(held, ["Shift"])
	var off: Dictionary = _run("kb", tog, {})
	var h: Dictionary = _run("kb", held, {})
	ok(_first_diff(h.packs, off.packs) >= 0, "negative control: the toggled stream with the style left at hold is NOT the held one (the compare bites)")
	var no_stop: Array = [_ev(10, "k", "Shift", true), _ev(12, "k", "Shift", false)]
	var ns: Dictionary = _run("kb", no_stop, {"guard": "toggle"})
	ok(_first_diff(h.packs, ns.packs) >= 0 and _count_bit(ns.packs, B_GUARD) > _count_bit(h.packs, B_GUARD), "negative control: with the stop press missing the guard stays on after the held run's end")
	ok((int(ns.packs[TICKS - 1]) >> B_GUARD) & 1 == 1, "negative control: it is still on at the very end (a latch, not a timer)")


func _auto_repeat() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.set_hold_style("guard", "toggle", 0)
	hub.intent(0)
	hub.key("Shift", true)
	hub.key("Shift", true)   # the keyboard's auto-repeat while the key is down
	hub.key("Shift", true)
	var i: SimIntent = hub.intent(0)
	hub.consumed()
	ok(i.guard, "auto-repeat: a held key's repeats are not a second press")
	hub.key("Shift", false)
	i = hub.intent(0)
	hub.consumed()
	ok(i.guard, "toggle: letting go changes nothing; it is still on")
	hub.key("Shift", true)
	hub.key("Shift", false)
	i = hub.intent(0)
	hub.consumed()
	ok(not i.guard, "toggle: the next press is the stop")
	hub.key("Shift", true)
	hub.key("Shift", false)
	i = hub.intent(0)
	hub.consumed()
	ok(i.guard, "toggle: and the one after starts it again")


func _second_player() -> void:
	# Two people on one keyboard (shared layouts): P1's Shift guard, P2's Semicolon guard. Only P2 toggles.
	var hub := SimInputHub.new()
	hub.set_humans(true, true)
	hub.set_hold_style("guard", "toggle", 1)
	hub.intent(0)
	hub.intent(1)
	hub.consumed()
	hub.key("Shift", true)
	hub.key("Semicolon", true)
	hub.key("Shift", false)
	hub.key("Semicolon", false)
	var i0: SimIntent = hub.intent(0)
	var i1: SimIntent = hub.intent(1)
	hub.consumed()
	ok(not i0.guard, "player 2's own style: player 1 (hold) lets go and guard falls")
	ok(i1.guard, "player 2's own style: player 2 (toggle) lets go and guard stays")
	hub.key("Semicolon", true)
	hub.key("Semicolon", false)
	hub.intent(0)
	i1 = hub.intent(1)
	hub.consumed()
	ok(not i1.guard, "player 2's own style: and their next press stops it")


func _back_to_hold() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.set_hold_style("dodge", "toggle", 0)
	hub.intent(0)
	hub.key("Space", true)
	hub.key("Space", false)
	var i: SimIntent = hub.intent(0)
	hub.consumed()
	for k in range(20):
		i = hub.intent(0)
		hub.consumed()
	ok(i.sprint, "back to hold: a toggled dodge keeps sprinting once the half second is up")
	hub.set_hold_style("dodge", "hold", 0)
	i = hub.intent(0)
	hub.consumed()
	ok(not i.sprint, "back to hold: switching the style back lets the toggled hold go at once")
	for k in range(3):   # the stance mask lets go after the release grace, as for a finger
		i = hub.intent(0)
		hub.consumed()
	ok(i.stanceMask == 0, "back to hold: ... and the stance is martial after the release grace")
	# The finger still down when the style goes back: it holds until it lifts.
	hub.set_hold_style("dodge", "toggle", 0)
	hub.intent(0)
	hub.consumed()
	hub.key("Space", true)
	hub.set_hold_style("dodge", "hold", 0)
	for k in range(20):
		i = hub.intent(0)
		hub.consumed()
	ok(i.sprint, "back to hold: a finger still down when the style goes back keeps the hold")
	hub.key("Space", false)
	i = hub.intent(0)
	hub.consumed()
	ok(not i.sprint, "back to hold: ... and lifting ends it")
	# A new match (release_all) lets every toggle go.
	hub.set_hold_style("guard", "toggle", 0)
	hub.intent(0)
	hub.key("Shift", true)
	hub.key("Shift", false)
	i = hub.intent(0)
	hub.consumed()
	ok(i.guard, "new match: a toggled guard is on")
	hub.release_all()
	i = hub.intent(0)
	hub.consumed()
	ok(not i.guard, "new match: release_all lets it go")


func _cancel_and_ring() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.set_hold_style("transform", "toggle", 0)
	hub.intent(0)
	hub.key("KeyR", true)
	hub.key("KeyR", false)
	for k in range(10):
		hub.intent(0)
		hub.consumed()
	var ring: float = hub.transform_hold(0)
	ok(ring > 0.2 and ring < 1.0, "ring: a toggled transform's ring keeps filling with no finger on it (%.2f)" % ring)
	hub.key("KeyR", true)
	hub.key("KeyR", false)
	hub.intent(0)
	hub.consumed()
	ok(hub.transform_hold(0) == 0.0, "ring: the cancelling press empties it")
	var sent: bool = false
	for k in range(60):
		var i: SimIntent = hub.intent(0)
		hub.consumed()
		sent = sent or i.transform
	ok(not sent, "cancel: a cancelled transform is never sent")


func _let_go() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.set_hold_style("guard", "toggle", 0)
	hub.set_hold_style("transform", "toggle", 0)
	hub.intent(0)
	hub.key("Shift", true)
	hub.key("Shift", false)
	hub.key("KeyR", true)
	hub.key("KeyR", false)
	var i: SimIntent = hub.intent(0)
	hub.consumed()
	ok(i.guard and hub.transform_hold(0) > 0.0, "let go: a toggled guard and a counting transform are on")
	hub.let_go_toggles(0)
	var sent: bool = false
	for k in range(60):
		i = hub.intent(0)
		hub.consumed()
		sent = sent or i.transform
	ok(not i.guard and not sent and hub.transform_hold(0) == 0.0, "let go: let_go_toggles(slot) puts them both away, and the transform is not sent")
