extends SceneTree
## Headless checks for no input lost in a stall (docs/controls/stall-keep.md; timing.json switches.stallKeep, off): a page that hitches delivers a flick's press and release together and the steps after it read
## one snapshot, so the flick was never seen. With the switch on the layout keeps the strike stick's furthest point since its last build and reads it once (the left hand's brace and vanish need the stick out for a
## tick or two by their own rules, so a left flick shorter than that is the rule's, not the stall's);
## buttons were never lost (their edges are kept); a held stick, a half push and a charge are exactly what they were; and with the switch off nothing changes. From the repo root:
##   godot --headless --path . --script res://sim/input/test/stall_keep_test.gd
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
	_sw(true, false)
	_off()
	_sw(true, true)
	_flicks()
	_unchanged()
	_wobble()
	_keys()
	_buttons()
	_hub()
	_mirror()
	_pause()
	_sw(true, false)
	print("stall_keep_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(right: bool, keep: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	for k in ["quickRead", "beamAim", "hapticLadder", "hapticIncoming", "hapticRefused", "specialsOff", "signatureRtOnly", "driverOnRb"]:
		sw[k] = false   # the old behaviour, whatever the data ships
	sw["rightStick"] = right
	sw["stallKeep"] = keep
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _pad(preset: String = "arena") -> SimLayout:
	return SimLayout.new(SimInputData.preset(preset))


func _kb() -> SimLayout:
	return SimLayout.new(SimInputData.preset("kb-solo"))


## `n` empty builds, so the layout is past its start.
func _idle(l: SimLayout, n: int = 3) -> void:
	for t in range(n):
		l.build()
		l.consumed()


## What the builds after a stall show: a flick's rise and fall (the events), then `n` builds. Returns {start: tick or -1, release: tick or -1, dir, level, starts, releases}.
func _after(l: SimLayout, n: int = 12) -> Dictionary:
	var res: Dictionary = {"start": -1, "release": -1, "dir": 0, "level": -1, "starts": 0, "releases": 0}
	for t in range(n):
		var i: SimIntent = l.build()
		if i.rsStart:
			res["starts"] += 1
			if res["start"] < 0:
				res["start"] = t
				res["dir"] = i.rsDir
		if i.rsRelease:
			res["releases"] += 1
			if res["release"] < 0:
				res["release"] = t
				res["level"] = i.rsLevel
		l.consumed()
	return res


func _flick(l: SimLayout, x: float, y: float) -> void:
	l.axis("pad:rs", x, y)
	l.axis("pad:rs", 0.0, 0.0)


func _off() -> void:
	var l: SimLayout = _pad()
	_idle(l)
	_flick(l, 1.0, 0.0)
	var r: Dictionary = _after(l)
	ok(r["starts"] == 0 and r["releases"] == 0, "off: a flick that rose and fell between two builds is lost, as it was (starts %d)" % r["starts"])


func _flicks() -> void:
	var cases: Array = [[1.0, 0.0, SimStrikeRead.RIGHT], [-1.0, 0.0, SimStrikeRead.LEFT], [0.0, 1.0, SimStrikeRead.UP], [0.0, -1.0, SimStrikeRead.DOWN]]
	for c in cases:
		var l: SimLayout = _pad()
		_idle(l)
		_flick(l, c[0], c[1])
		var r: Dictionary = _after(l)
		ok(r["starts"] == 1 and r["releases"] == 1, "on: a flick toward (%.0f, %.0f) between two builds is one strike (starts %d, releases %d)" % [c[0], c[1], r["starts"], r["releases"]])
		ok(r["dir"] == c[2], "on: and its direction is kept (%d, wanted %d)" % [r["dir"], c[2]])
		ok(r["level"] == 0, "on: a quick strike, level 0")
	# two flicks between builds are one request: the furthest, and the first of equals
	var l2: SimLayout = _pad()
	_idle(l2)
	_flick(l2, 1.0, 0.0)
	_flick(l2, -1.0, 0.0)
	var r2: Dictionary = _after(l2)
	ok(r2["starts"] == 1 and r2["dir"] == SimStrikeRead.RIGHT, "on: two flicks in one stall are one strike, the first of equal reach (starts %d, dir %d)" % [r2["starts"], r2["dir"]])
	# a longer stall: the flick was made, then the stick was back at rest for nine builds
	var l3: SimLayout = _pad()
	_idle(l3)
	_flick(l3, 0.0, 1.0)
	var r3: Dictionary = _after(l3, 20)
	ok(r3["starts"] == 1 and r3["dir"] == SimStrikeRead.UP, "on: a stall of many builds with the stick at rest shows the one flick, once")
	# a push that never reached the request line is not a flick, on or off
	var l4: SimLayout = _pad()
	_idle(l4)
	_flick(l4, 0.5, 0.0)
	var r4: Dictionary = _after(l4)
	ok(r4["starts"] == 0, "on: a half push between builds is still not a request")
	# the peak is read once: the flick, then another stall with nothing, adds nothing
	var l5: SimLayout = _pad()
	_idle(l5)
	_flick(l5, 1.0, 0.0)
	_after(l5, 6)
	var r5: Dictionary = _after(l5, 12)
	ok(r5["starts"] == 0, "on: the kept point is spent by the build that read it")


## A stick held across builds is read exactly as it was: the whole intent stream equals the switch-off stream.
func _unchanged() -> void:
	var streams: Array = []
	for keep in [false, true]:
		_sw(true, keep)
		var l: SimLayout = _pad()
		var sig: Array = []
		for t in range(120):
			var m: float = 1.0 if (t >= 10 and t < 70) else (0.5 if (t >= 80 and t < 90) else 0.0)
			l.axis("pad:rs", m, 0.0)
			if t == 30:
				l.press("pad:west")
			if t == 33:
				l.release("pad:west")
			var i: SimIntent = l.build()
			sig.append([i.rsHeld, i.rsStart, i.rsRelease, i.rsDir, i.rsLevel, i.rsAim, i.light, i.lightHeld, i.rsMask])
			l.consumed()
		streams.append(sig)
	_sw(true, true)
	ok(streams[0] == streams[1], "unchanged: a held charge, a half push and a face press read the same with the switch on as off")


## A stick held out and wobbling, with two events between every pair of builds (the page at 120 Hz): the stream is the switch-off stream.
func _wobble() -> void:
	var streams: Array = []
	for keep in [false, true]:
		_sw(true, keep)
		var l: SimLayout = _pad()
		var sig: Array = []
		for t in range(100):
			if t >= 10 and t < 80:
				l.axis("pad:rs", 1.0, 0.1 * float((t % 3) - 1))
				l.axis("pad:rs", 0.92, 0.15 * float(((t + 1) % 3) - 1))
			else:
				l.axis("pad:rs", 0.0, 0.0)
			var i: SimIntent = l.build()
			sig.append([i.rsHeld, i.rsStart, i.rsRelease, i.rsDir, i.rsLevel, i.rsAim, i.rsMask])
			l.consumed()
		streams.append(sig)
	_sw(true, true)
	ok(streams[0] == streams[1], "unchanged: a held stick with two wobbling events a build reads the same with the switch on as off")


func _keys() -> void:
	# a strike key tap (the arrow key) that comes and goes between two builds
	var off: Dictionary
	for keep in [false, true]:
		_sw(true, keep)
		var l: SimLayout = _kb()
		_idle(l)
		l.press("kb:ArrowRight")
		l.release("kb:ArrowRight")
		var r: Dictionary = _after(l)
		if keep:
			ok(r["starts"] == 1 and r["dir"] == SimStrikeRead.RIGHT, "keys: an arrow key tap between two builds is a strike toward it with the switch on (starts %d, dir %d)" % [r["starts"], r["dir"]])
		else:
			ok(r["starts"] == 0, "keys: and lost with it off, as it was")
	_sw(true, true)


func _buttons() -> void:
	# buttons were never lost: the press edge is kept until the step takes it (docs/controls/stall-keep.md), on or off
	var l: SimLayout = _pad()
	_idle(l)
	for c in ["pad:west", "pad:north", "pad:east", "pad:south"]:
		l.press(c)
		l.release(c)
	var i: SimIntent = l.build()
	ok(i.light or i.heavy or i.sig or i.context, "buttons: a face press and release before a build still shows in the intent")
	l.consumed()
	var l2: SimLayout = _pad()
	_idle(l2)
	l2.press("pad:lb")
	l2.release("pad:lb")
	ok(l2.build().guardPress, "buttons: an LB tap before a build is a guard press (the perfect block's edge)")
	var l3: SimLayout = _pad()
	_idle(l3)
	l3.analog("pad:lt", 1.0)
	l3.analog("pad:lt", 0.0)
	ok(l3.build().dodge, "buttons: an LT tap before a build is a dodge")


## Through the real hub, a pad at device 7: the flick rises and falls before the host asks for the slot's intent, as in a hitch.
func _hub() -> void:
	var got: Array = []
	for keep in [false, true]:
		_sw(true, keep)
		var hub: SimInputHub = SimInputHub.new()
		hub.set_humans(true, false)
		hub.pad_button(7, "south", true)
		hub.pad_button(7, "south", false)
		hub.take_joins()
		hub.set_humans(true, false)
		var starts: int = 0
		var dir: int = 0
		for t in range(30):
			if t == 10:
				hub.pad_stick_right(7, 0.0, 1.0)
				hub.pad_stick_right(7, 0.0, 0.0)
			var i: SimIntent = hub.intent(0)
			if i.rsStart:
				starts += 1
				dir = i.rsDir
			hub.consumed()
		got.append([starts, dir])
	_sw(true, true)
	ok(got[0][0] == 0, "hub: off, a flick that rose and fell before the host read the slot is lost, as it was")
	ok(got[1][0] == 1 and got[1][1] == SimStrikeRead.UP, "hub: on, the hub hands the flick on: one strike, up (got %s)" % str(got[1]))


## The D-pad mirror turned off between the press and the step that reads it (the hub applies a setting at the build): a flick the mirror made does not outlive the setting.
func _mirror() -> void:
	var l: SimLayout = _pad()
	l.set_mirror_dpad(true)
	_idle(l)
	l.press("pad:dpad_right")
	l.release("pad:dpad_right")
	l.set_mirror_dpad(false)
	var r: Dictionary = _after(l)
	ok(r["starts"] == 0, "mirror: a D-pad flick made under the mirror is not thrown once the mirror is off (starts %d)" % r["starts"])
	var l2: SimLayout = _pad()
	l2.set_mirror_dpad(true)
	_idle(l2)
	l2.press("pad:dpad_right")
	l2.release("pad:dpad_right")
	var r2: Dictionary = _after(l2)
	ok(r2["starts"] == 1 and r2["dir"] == SimStrikeRead.RIGHT, "mirror: and with the mirror still on the D-pad tap is a flick (starts %d)" % r2["starts"])


func _pause() -> void:
	# what the stick did during a pause is not carried out of it
	var l: SimLayout = _pad()
	_idle(l)
	_flick(l, 1.0, 0.0)
	l.drop_edges()
	var r: Dictionary = _after(l)
	ok(r["starts"] == 0, "pause: a flick made during a pause (the edges are dropped) is not thrown after it")
