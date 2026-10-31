class_name SimStrikeLaw
extends RefCounted
## The no-claw law for the strike stick (docs/controls/right-hand-attacks.md section 6, rules K1 to K3; docs/controls/right-thumb.md). It is applied by
## the layout to the intent it just built, on actions, never on device names, so it holds the same on a pad, a keyboard, a swapped pad and a D-pad mirror:
##
##   K3  while a strike is in the sim's hands, or its stick is still out after it was thrown or cancelled, the face buttons are INERT: a press queues
##       (3 deep, `queueTicks` live) and starts, in its order, the first tick the stick is quiet;
##   K2  a face press after a stick command (the throw or the cancel) waits `lockout` ticks (L); a strike request after a face press waits
##       `reverseLockout` ticks (R). The request's start is held by the reader's `floor_tick`, from here;
##   K1  a face press and a crossing on the same tick: the face press wins, the strike starts R later. (A request that has not started does not hold
##       the faces, so the press goes through and sets the floor.)
##
## What counts as a face press: the intent's light, heavy, sig, context and special edges. The shoulders (guard, dodge, mode, power, transform) are
## the other thumb or the index fingers and are never held. Pure: no engine, no clock; the layout passes `tick`.

var lockout: int = 6            # L
var reverse_lockout: int = 8    # R
var depth: int = 3
var expiry: int = 36

var last_face: int = -1000000   # the tick a face press last went through
var stick_until: int = -1000000 # the first tick the faces are free after a stick command
var queue: Array = []           # [{k, v, t}]: a pressed face button waiting for the stick to be quiet


func _init(swapped: bool = false) -> void:
	lockout = SimInputData.ti(["strike", "swapLockout" if swapped else "lockout"], 6)
	reverse_lockout = SimInputData.ti(["strike", "swapReverseLockout" if swapped else "reverseLockout"], 8)
	depth = SimInputData.ti(["strike", "queueDepth"], 3)
	expiry = SimInputData.ti(["strike", "queueTicks"], 36)


## The earliest tick a strike request may start, after the last face press that went through (R). 0 for none.
func floor_tick() -> int:
	return 0 if last_face < 0 else last_face + reverse_lockout


## A struggle: the faces are free now, and nothing waiting from before goes out as a surge.
func free_faces() -> void:
	queue.clear()
	stick_until = -1000000


## A stick command just ended (the throw or the cancel) at `tick`: the faces are free L later.
func note_stick_end(tick: int) -> void:
	stick_until = tick + lockout


## The faces this build: `busy` is true while a strike is in the sim's hands or its stick is out (the layout decides). The intent `i` is changed in place:
## a press that must wait is taken out of it (edges and held levels) and queued; a queued press that may go is put back, one a build.
func filter(i: SimIntent, tick: int, busy: bool) -> void:
	var edges: Array = []
	if i.light:
		edges.append({"k": "light", "v": 0, "t": tick})
	if i.heavy:
		edges.append({"k": "heavy", "v": 0, "t": tick})
	if i.sig:
		edges.append({"k": "sig", "v": 0, "t": tick})
	if i.context:
		edges.append({"k": "context", "v": 0, "t": tick})
	if i.special != 0:
		edges.append({"k": "special", "v": i.special, "t": tick})
	var inert: bool = busy or tick < stick_until
	# A press older than `expiry` is gone.
	var keep: Array = []
	for q in queue:
		if tick - int(q["t"]) <= expiry:
			keep.append(q)
	queue = keep
	if inert:
		_strip(i, true)
		for e in edges:
			_enqueue(e)
		return
	if queue.is_empty():
		if not edges.is_empty():
			last_face = tick
		return
	# Free again with presses waiting: they go in their order, one a build, behind the ones already waiting.
	_strip(i, false)
	for e in edges:
		_enqueue(e)
	var first: Dictionary = queue.pop_front()
	_put(i, first)
	last_face = tick


func _enqueue(e: Dictionary) -> void:
	queue.append(e)
	while queue.size() > depth:
		queue.pop_front()   # newest wins


## The held levels of the face buttons are off while a strike is in the sim's hands.
func strip_levels(i: SimIntent) -> void:
	i.lightHeld = false
	i.heavyHeld = false
	i.sigHeld = false
	i.contextHeld = false


## Take the face edges out of i (and, while the stick is out, the held levels too: nothing about a charge is changed by a face button).
func _strip(i: SimIntent, levels: bool) -> void:
	i.light = false
	i.heavy = false
	i.sig = false
	i.context = false
	i.special = 0
	if levels:
		i.lightHeld = false
		i.heavyHeld = false
		i.sigHeld = false
		i.contextHeld = false


func _put(i: SimIntent, e: Dictionary) -> void:
	match str(e["k"]):
		"light":
			i.light = true
		"heavy":
			i.heavy = true
		"sig":
			i.sig = true
		"context":
			i.context = true
		"special":
			i.special = int(e["v"])


## Everything let go (a pause, a new match).
func reset() -> void:
	queue.clear()
	last_face = -1000000
	stick_until = -1000000
