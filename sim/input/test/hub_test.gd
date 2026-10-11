extends SceneTree
## Headless checks for the input hub (sim/input/hub.gd): device claiming, the shared keyboard, pads, the match setup
## and, through the real sim, what a human slot does with intent v2: guard, sprint, dodge, the attacks and the
## transform control. From the repo root:
##   godot --headless --path . --script res://sim/input/test/hub_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	_devices()
	_preset_and_hold()
	_disconnect()
	_rumble()
	_sim()
	_determinism()
	print("hub_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _tick(hub: SimInputHub, slot: int, n: int = 1) -> SimIntent:
	var i: SimIntent = null
	for k in range(n):
		i = hub.intent(slot)
		hub.consumed()
	return i


## hub.rumble_target: where a slot's rumble goes (read-only, for the host).
func _rumble() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(false, false)
	ok(hub.rumble_target(0)["kind"] == "none" and hub.rumble_target(1)["kind"] == "none", "rumble: no human slot, nowhere to send (an AI slot)")
	hub.set_humans(true, false)
	hub.key("KeyJ", true)
	hub.key("KeyJ", false)
	_tick(hub, 0)
	ok(hub.rumble_target(0) == {"kind": "kb", "id": -1} and hub.rumble_target(1)["kind"] == "none", "rumble: a keyboard player has a target of kind kb with no id (nothing to vibrate); the other slot is an AI")
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, true)
	_tick(hub, 1)
	var t1: Dictionary = hub.rumble_target(1)
	ok(t1["kind"] == "pad" and t1["id"] == 7, "rumble: a pad player's target is the pad's own device id (7)")
	hub.pad_button(3, "south", true)
	hub.pad_button(3, "south", false)
	var ids: Array = []
	for s in range(2):
		var tt: Dictionary = hub.rumble_target(s)
		if tt["kind"] == "pad":
			ids.append(tt["id"])
	ok(ids.has(7), "rumble: a second pad does not move player two's target")
	hub.touch_down(1, 400.0, 300.0, "attack")
	hub.touch_up(1)
	var kinds: Array = [hub.rumble_target(0)["kind"], hub.rumble_target(1)["kind"]]
	ok(kinds.has("pad") or kinds.has("touch") or kinds.has("kb"), "rumble: every slot answers with a known kind")
	for s in range(2):
		var r: Dictionary = hub.rumble_target(s)
		ok(["pad", "touch", "kb", "none"].has(r["kind"]) and typeof(r["id"]) == TYPE_INT, "rumble: slot %d answers {kind, id} with an integer id" % s)
	# Read-only: asking changes nothing in the intents.
	var h1 := SimInputHub.new()
	var h2 := SimInputHub.new()
	for h in [h1, h2]:
		h.set_humans(true, false)
		h.pad_button(5, "west", true)
	var same: bool = true
	for k in range(40):
		var a: int = SimIntent.pack(h1.intent(0))
		h2.rumble_target(0)
		h2.rumble_target(1)
		var b: int = SimIntent.pack(h2.intent(0))
		h1.consumed()
		h2.consumed()
		same = same and a == b
	ok(same, "rumble: asking for the target changes nothing in the intents")
	# A pad that goes away is no target.
	var hp := SimInputHub.new()
	hp.set_humans(true, false)
	hp.pad_button(9, "south", true)
	hp.pad_button(9, "south", false)
	_tick(hp, 0)
	ok(hp.rumble_target(0)["kind"] == "pad" and hp.rumble_target(0)["id"] == 9, "rumble: a pad slot points at its pad")
	hp.pad_disconnected(9)
	ok(hp.rumble_target(0)["kind"] != "pad" or hp.rumble_target(0)["id"] != 9, "rumble: and not at a pad that has gone")


func _devices() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	ok(hub.device_of(0) == "kb", "hub: a slot starts on the keyboard")
	ok(hub.key("KeyJ", true), "hub: J is a solo-preset key")
	ok(not hub.key("KeyZ", true), "hub: an unbound key is not")
	var i: SimIntent = hub.intent(0)
	ok(i.light, "hub: the keyboard drives slot 0 with one human")
	hub.consumed()
	hub.key("KeyJ", false)
	# A pad button with player one on the keyboard joins as player two (docs/controls/local-two-player.md); player one is
	# not disturbed.
	hub.key("Shift", true)
	hub.pad_button(0, "west", true)
	ok(hub.device_of(1) == "pad" and hub.device_of(0) == "kb" and hub.take_joins() == [1], "hub: a pad button joins as player two and asks the host for slot 1")
	hub.set_humans(true, true)
	var p2: SimIntent = hub.intent(1)
	i = hub.intent(0)
	ok(p2.light and i.guard, "hub: the pad's light for player two, and player one's keyboard guard is still held")
	hub.consumed()
	hub.pad_button(0, "west", false)
	hub.key("Shift", false)
	# Touch takes slot 0 when nobody plays, and everything else is let go.
	hub = SimInputHub.new()
	hub.set_humans(true, false)
	hub.touch_down(1, 700.0, 300.0, "guard")
	ok(hub.device_of(0) == "touch", "hub: a touch takes slot 0 when nobody is playing")
	ok(hub.intent(0).guard, "hub: touch guard")
	hub.touch_up(1)
	hub.consumed()
	# Two humans: the shared keyboard, left hand for slot 0 and right for slot 1.
	hub = SimInputHub.new()
	hub.set_humans(true, true)
	hub.key("KeyF", true)
	var a: SimIntent = hub.intent(0)
	var b: SimIntent = hub.intent(1)
	ok(a.light and not b.light, "hub: F is slot 0's light on the shared keyboard, and not slot 1's")
	ok(hub.device_of(0) == "kb", "hub: slot 0 on the keyboard")
	hub.consumed()
	hub.key("KeyF", false)
	hub.key("KeyH", true)
	b = hub.intent(1)
	ok(b.light, "hub: H is slot 1's light")
	hub.consumed()
	hub.key("KeyH", false)
	hub.key("KeyI", true)
	b = hub.intent(1)
	ok(b.my == 1.0, "hub: I moves slot 1 up (I J K L)")
	hub.key("KeyI", false)
	hub.consumed()
	# Two pads: the first takes slot 0, the second slot 1.
	hub = SimInputHub.new()
	hub.set_humans(true, true)
	hub.pad_button(3, "west", true)
	hub.pad_button(7, "west", true)
	ok(hub.slot_pad[0] == 3 and hub.slot_pad[1] == 7, "hub: two pads take one slot each")
	ok(hub.intent(0).light and hub.intent(1).light, "hub: and each drives its own")
	# The match setup.
	var su: Dictionary = hub.setup()
	ok(su["v2"] == [true, true] and su["assists"][0].is_empty(), "hub: setup marks both slots v2, no assists on Arena")
	hub.pad_preset = "simple-pad"
	su = hub.setup()
	ok(su["assists"][0].has("autoBurst") and su["assists"][0].has("specialAuto"), "hub: a Simple pad gets autoBurst and specialAuto")
	hub = SimInputHub.new()
	hub.set_humans(true, false)
	hub.touch_down(1, 700.0, 300.0, "guard")
	su = hub.setup()
	ok(su["assists"][0].has("autoBurst") and su["assists"][0].has("specialAuto"), "hub: touch Simple gets the assists")
	# Canonical intents: every stick value on the 1 / 127 grid.
	hub = SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(0, "west", true)
	hub.pad_stick(0, 0.55, 0.3)
	var c: SimIntent = hub.intent(0)
	ok(is_equal_approx(c.mx * 127.0, roundf(c.mx * 127.0)) and is_equal_approx(c.my * 127.0, roundf(c.my * 127.0)), "hub: the stick is on the 1/127 grid")
	ok(SimIntent.pack(c) == SimIntent.pack(SimIntent.canon(c)), "hub: canon is the identity on what the hub sends")


func _match(hub: SimInputHub) -> SimState:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, hub.setup())
	return S


## One sim tick for both human slots from the hub, as SimHost.tick does it.
func _step(S: SimState, hub: SimInputHub, n: int = 1) -> void:
	for k in range(n):
		hub.set_humans(S.fighters[0].ai == null, S.fighters[1].ai == null)
		var inputs: Array = [hub.intent(0), hub.intent(1)]
		if SimCore.step(S, inputs):
			hub.consumed()


func _sim() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, true)
	var S: SimState = _match(hub)
	var f = S.fighters[0]
	ok(f.act.v2 and S.fighters[1].act.v2, "sim: both slots are v2 from the setup")
	_step(S, hub, 3)
	ok(f.stance == 0.0, "sim: idle is Press")
	# Guard held: DEFENSIVE.
	hub.key("ShiftLeft", true)   # not bound: the code is "Shift"
	hub.key("Shift", true)
	_step(S, hub, 2)
	ok(f.stance == 1.0, "sim: guard held is DEFENSIVE (derived by the sim)")
	hub.key("Shift", false)
	_step(S, hub, 2)
	ok(f.stance == 0.0, "sim: released, back to Press")
	# A dodge tap: EVASIVE for the window, then back.
	hub.key("Space", true)
	_step(S, hub, 2)
	hub.key("Space", false)
	ok(f.stance == 2.0, "sim: a Space tap reads as Dodge")
	_step(S, hub, 14)
	ok(f.stance == 0.0, "sim: and the window closes")
	# Sprint away from the opponent (slot 1 is on +x): ESCAPE.
	hub.key("KeyA", true)
	hub.key("Space", true)
	_step(S, hub, 20)
	ok(f.stance == 3.0, "sim: Space held while moving away is ESCAPE")
	hub.key("Space", false)
	hub.key("KeyA", false)
	_step(S, hub, 15)
	# A light tap starts an exchange with slot 0 as the attacker, once the opening cooldown is over.
	S = _match(hub)
	f = S.fighters[0]
	_step(S, hub, 80)
	hub.key("KeyF", true)
	_step(S, hub, 2)
	hub.key("KeyF", false)
	var ex = S.dirS.ex
	# Close up the request starts the exchange; from range it starts an approach (DirBands.pending), the exchange coming at the wind-up.
	ok((ex != null and ex.A == f and ex.kind == "light") or DirBands.pending(f), "sim: a light request starts a light exchange or an approach")
	# The transform control: a form is ready, the chord is held 30 ticks, and the tier rises.
	S = _match(hub)
	f = S.fighters[0]
	_step(S, hub, 5)
	f.act.formReady = true
	var tier0: float = f.tier
	hub.key("Space", true)
	_step(S, hub, 2)
	hub.key("KeyQ", true)
	_step(S, hub, 20)
	ok(f.tier == tier0 and f.act.formReady, "sim: the chord does nothing before 30 ticks")
	_step(S, hub, 14)
	hub.key("Space", false)
	hub.key("KeyQ", false)
	_step(S, hub, 400)   # the transformation gathers in a pause (SimPause) before the tier rises
	ok(f.tier > tier0 and not f.act.formReady, "sim: the chord's transform raises the tier (the charge-hold fallback is no longer needed)")
	# Holding charge alone no longer transforms a v2 slot.
	S = _match(hub)
	f = S.fighters[0]
	_step(S, hub, 5)
	f.act.formReady = true
	hub.key("KeyQ", true)
	_step(S, hub, 60)
	hub.key("KeyQ", false)
	ok(f.tier == 1.0 and f.act.formReady, "sim: power held alone does not take the form on a v2 slot")
	# A single transform key.
	S = _match(hub)
	f = S.fighters[0]
	_step(S, hub, 5)
	f.act.formReady = true
	hub.set_humans(true, false)   # one human: the solo preset, where R is the transform key
	hub.key("KeyR", true)
	for k in range(40):
		if SimCore.step(S, [hub.intent(0), null]):
			hub.consumed()
	hub.key("KeyR", false)
	for k in range(400):
		if SimCore.step(S, [hub.intent(0), null]):
			hub.consumed()
	ok(f.tier == 2.0, "sim: the R key (solo) held 30 ticks takes the form")


## The same scripted human session twice from the same seed gives the same state, and the layer is what drove it.
func _determinism() -> void:
	var out: Array = []
	for run in range(2):
		var hub := SimInputHub.new()
		hub.set_humans(true, false)
		var S: SimState = SimCore.createSim()
		SimCore.newMatch(S, 9, {"p1": false, "p2": true}, hub.setup())
		for n in range(900):
			var c: int = n % 150
			match c:
				0: hub.key("Shift", true)
				20: hub.key("Shift", false)
				30: hub.key("Space", true)
				34: hub.key("Space", false)
				50: hub.key("KeyJ", true)
				52: hub.key("KeyJ", false)
				80: hub.key("KeyE", true)
				100: hub.key("KeyE", false)
				110: hub.key("KeyD", true)
				130: hub.key("KeyD", false)
			hub.set_humans(S.fighters[0].ai == null, S.fighters[1].ai == null)
			if SimCore.step(S, [hub.intent(0), null]):
				hub.consumed()
		out.append(str(SimHash.stateHash(S).gameplay))
		SimCore.dispose(S)
	ok(out[0] == out[1], "determinism: a scripted keyboard session replays to the same hash")


func _preset_and_hold() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(0, "west", true)
	ok(hub.intent(0).light, "preset: Arena's X is a light")
	hub.consumed()
	hub.pad_button(0, "west", false)
	ok(hub.pads.has(0), "preset: the pad layout is cached")
	hub.set_pad_preset("simple-pad")
	ok(hub.pads.is_empty() and hub.pad_preset == "simple-pad", "preset: set_pad_preset clears the cache")
	ok(hub.slot_pad[0] == 0, "preset: the slot's pad claim is kept")
	hub.pad_button(0, "west", true)
	var i: SimIntent = _tick(hub, 0, 3)
	ok(not i.light, "preset: on Simple, X down is not yet a light (it fires on release)")
	hub.pad_button(0, "west", false)
	ok(hub.intent(0).light, "preset: and is on release: the new preset took effect")
	hub.consumed()
	hub.set_pad_preset("nonsense")
	ok(hub.pad_preset == "simple-pad", "preset: an unknown preset id is ignored")
	# The transform hold ring, per slot, through the hub.
	hub = SimInputHub.new()
	hub.set_humans(true, false)
	hub.key("KeyR", true)
	_tick(hub, 0, 15)
	ok(absf(hub.transform_hold(0) - 0.5) < 0.04, "hold: the hub reports the transform key's progress")
	hub.key("KeyR", false)
	hub = SimInputHub.new()
	hub.set_humans(true, false)
	hub.touch_down(1, 400.0, 300.0, "context")
	_tick(hub, 0, 15)
	ok(absf(hub.transform_hold(0) - 0.5) < 0.04, "hold: and a touch Transform button's")
	hub.touch_up(1)
	# A pause through the hub: edges are dropped, holds re-read.
	hub = SimInputHub.new()
	hub.set_humans(true, false)
	hub.key("KeyJ", true)
	hub.drop_edges()
	ok(not hub.intent(0).light, "pause: the hub drops a press made during a pause")
	hub.consumed()
	hub.key("KeyJ", false)
	hub.key("Shift", true)
	hub.resume()
	ok(hub.intent(0).guard and not hub.intent(0).guardPress, "pause: a held guard is still held after it, with no fresh press edge")


func _disconnect() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, true)
	hub.pad_button(4, "lb", true)
	hub.pad_stick(4, 1.0, 0.0)
	hub.pad_button(9, "west", true)
	ok(hub.slot_pad[0] == 4 and hub.slot_pad[1] == 9, "disconnect: two pads hold a slot each")
	var i: SimIntent = hub.intent(0)
	ok(i.guard and i.mx == 1.0, "disconnect: pad 4 holds guard and the stick")
	hub.consumed()
	hub.pad_disconnected(4)
	ok(hub.device_of(0) == "kb" and hub.slot_pad[0] == -1 and not hub.pads.has(4), "disconnect: the slot returns to the keyboard and is free")
	i = hub.intent(0)
	ok(not i.guard and i.mx == 0.0, "disconnect: nothing stays held")
	ok(hub.device_of(1) == "pad" and hub.slot_pad[1] == 9, "disconnect: the other pad is untouched")
	hub.consumed()
	hub.pad_disconnected(99)
	ok(true, "disconnect: an unknown device is harmless")
	# Plugging back in works: the pad takes the free slot.
	hub.pad_button(4, "west", true)
	ok(hub.slot_pad[0] == 4 and hub.device_of(0) == "pad", "disconnect: a returning pad takes its slot again")
