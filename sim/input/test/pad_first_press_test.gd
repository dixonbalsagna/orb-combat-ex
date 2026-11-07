extends SceneTree
## One person's first press takes player one (the EP's rule, 2026-11-01, after Orb's first play): the start menu puts player one on "the first connected pad", which on a PC with a phantom
## or a second device is not the pad in the person's hands, so that person's first press used to join as player TWO. Scripted pads at device ids 0, 1, 2 through the real hub:
##   godot --headless --path . --script res://sim/input/test/pad_first_press_test.gd
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
	SimInputData.clear_overrides()
	_phantom()
	_proven_pad()
	_stick_counts()
	_second_person()
	_start_press()
	_keyboard_and_two_player()
	_reset()
	print("pad_first_press_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


## What _on_menu_started does for "Player 1 is Controller": slot 0 human, on the first connected pad, claimed.
func _menu_hub(pad0: int, pad1: int = -1) -> SimInputHub:
	var hub := SimInputHub.new()
	hub.set_humans(true, pad1 >= 0)
	hub.slot_device[0] = "pad"
	hub.slot_pad[0] = pad0
	hub.claimed[0] = true
	if pad1 >= 0:
		hub.slot_device[1] = "pad"
		hub.slot_pad[1] = pad1
		hub.claimed[1] = true
	return hub


func _phantom() -> void:
	for real in [1, 2]:
		var hub: SimInputHub = _menu_hub(0)
		hub.pad_button(real, "west", true)
		ok(int(hub.slot_pad[0]) == real and bool(hub.claimed[0]), "phantom: the menu put player one on pad 0; pad %d's first press takes slot 0 (slot 0 is pad %d)" % [real, hub.slot_pad[0]])
		ok(not hub.claimed[1] and hub.take_joins().is_empty(), "phantom: pad %d did not join as player two" % real)
		var i: SimIntent = hub.intent(0)
		ok(i.light, "phantom: the press that took the slot is player one's light blow")
		hub.consumed()
		hub.pad_button(real, "west", false)
		hub.pad_stick(real, 1.0, 0.0)
		var m: SimIntent = hub.intent(0)
		ok(m.mx > 0.5, "phantom: and the stick of pad %d now moves player one" % real)


func _proven_pad() -> void:
	# pad 0 was the right one and has pressed: pad 1 is a second person, who joins as player two
	var hub: SimInputHub = _menu_hub(0)
	hub.pad_button(0, "west", true)
	hub.pad_button(1, "west", true)
	ok(int(hub.slot_pad[0]) == 0 and int(hub.slot_pad[1]) == 1 and bool(hub.claimed[1]), "proven: pad 0 has pressed, so pad 1 is a second person and joins as player two")
	ok(hub.take_joins() == [1], "proven: the join is slot 1")
	# a trigger counts as used
	var h2: SimInputHub = _menu_hub(0)
	h2.pad_trigger(0, "rt", 1.0)
	h2.pad_button(1, "west", true)
	ok(int(h2.slot_pad[0]) == 0 and bool(h2.claimed[1]), "proven: a trigger pull counts as used")


func _stick_counts() -> void:
	var hub: SimInputHub = _menu_hub(0)
	hub.pad_stick(0, 1.0, 0.0)
	hub.pad_button(1, "west", true)
	ok(int(hub.slot_pad[0]) == 0 and bool(hub.claimed[1]), "stick: a stick pushed past half on pad 0 counts as used, so pad 1 joins as player two")
	var h2: SimInputHub = _menu_hub(0)
	h2.pad_stick(0, 0.2, 0.0)
	h2.pad_button(1, "west", true)
	ok(int(h2.slot_pad[0]) == 1 and not h2.claimed[1], "stick: a stick nudge under half does not count: pad 1's press takes player one")
	var h3: SimInputHub = _menu_hub(0)
	h3.pad_stick_right(0, 0.0, 1.0)
	h3.pad_button(2, "west", true)
	ok(int(h3.slot_pad[0]) == 0 and bool(h3.claimed[1]), "stick: the right stick pushed past half counts too")


func _second_person() -> void:
	# the phantom, the real person, then a real second person on pad 2
	var hub: SimInputHub = _menu_hub(0)
	hub.pad_button(1, "west", true)
	hub.pad_button(2, "west", true)
	ok(int(hub.slot_pad[0]) == 1 and int(hub.slot_pad[1]) == 2 and bool(hub.claimed[1]), "second person: pad 1 took player one, then pad 2 joined as player two")
	ok(hub.take_joins() == [1], "second person: one join, slot 1")
	# the phantom pressing later is a third device with both slots taken: it takes no slot
	hub.pad_button(0, "west", true)
	ok(int(hub.slot_pad[0]) == 1 and int(hub.slot_pad[1]) == 2, "second person: a third pad takes neither slot back")


func _start_press() -> void:
	var hub: SimInputHub = _menu_hub(0)
	ok(hub.start_joins(1), "start: Start on pad 1 would join (the host then hands the press to the hub)")
	hub.pad_button(1, "start", true)
	ok(int(hub.slot_pad[0]) == 1 and not hub.claimed[1], "start: and the hub gives it to player one, not player two")


func _keyboard_and_two_player() -> void:
	# player one on the keyboard: a pad's first press is a second person
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.key("KeyF", true)
	hub.key("KeyF", false)
	hub.pad_button(1, "west", true)
	ok(hub.slot_device[0] == "kb" and bool(hub.claimed[1]) and int(hub.slot_pad[1]) == 1, "keyboard: player one on the keyboard, a pad press is player two (unchanged)")
	# two players on two pads, both from the menu: each pad's own press finds its own slot
	var h2: SimInputHub = _menu_hub(0, 1)
	h2.pad_button(1, "west", true)
	h2.pad_button(0, "west", true)
	ok(int(h2.slot_pad[0]) == 0 and int(h2.slot_pad[1]) == 1, "two on pads: each pad keeps the slot the menu gave it, in any order of pressing")
	# two players on pads, a third pad that has not pressed: it takes player one from pad 0 only if pad 0 never pressed
	var h3: SimInputHub = _menu_hub(0, 1)
	h3.pad_button(2, "west", true)
	ok(int(h3.slot_pad[0]) == 2 and int(h3.slot_pad[1]) == 1, "two on pads: pad 0 never pressed, so a third pad's press takes player one")


func _reset() -> void:
	var hub: SimInputHub = _menu_hub(0)
	hub.pad_button(0, "west", true)
	hub.reset_claims()
	hub.set_humans(true, false)
	hub.slot_device[0] = "pad"
	hub.slot_pad[0] = 0
	hub.claimed[0] = true
	hub.pad_button(1, "west", true)
	ok(int(hub.slot_pad[0]) == 1, "reset: after reset_claims a pad that had pressed no longer counts as used")
