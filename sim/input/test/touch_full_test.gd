extends SceneTree
## Headless checks for the Full touch preset (touch-full, for tablets): the layout on screens, the hit tests, every
## button through the SimLayout, the stick's flick and sprint, several fingers at once, the display state and the hub's
## switch between Simple and Full. From the repo root:
##   godot --headless --path . --script res://sim/input/test/touch_full_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_data()
	_layout()
	_buttons()
	_armed_display()
	_top_limit()
	_stick()
	_fingers()
	_hub()
	print("touch_full_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _mk() -> SimTouch:
	var t := SimTouch.new()
	t.dp = 2.75
	t.set_preset("touch-full")
	t.set_stance_oneshot(false)   # these tests are of the hold semantics; the one-shot (touch Full's default) is in stance_test.gd
	return t


func _run(t: SimTouch, n: int) -> SimIntent:
	var i: SimIntent = null
	for k in range(n):
		i = t.build()
		t.consumed()
	return i


func _at(lay: Dictionary, name: String) -> Vector2:
	return Vector2(float(lay[name].x), float(lay[name].y))


func _layout() -> void:
	var names: Array = ["light", "heavy", "signature", "context", "power", "mode", "transform", "dodge", "guard"]
	for cfgv in [[844.0 * 2.75, 390.0 * 2.75, 2.75, false, false], [844.0 * 2.75, 390.0 * 2.75, 2.75, false, true],
			[1280.0 * 1.5, 800.0 * 1.5, 1.5, false, false], [2360.0, 1640.0, 2.0, false, false], [2360.0, 1640.0, 2.0, false, true],
			[360.0 * 3.0, 800.0 * 3.0, 3.0, true, false], [810.0 * 2.0, 1080.0 * 2.0, 2.0, true, false]]:
		var vw: float = cfgv[0]
		var vh: float = cfgv[1]
		var dpv: float = cfgv[2]
		var port: bool = cfgv[3]
		var lh: bool = cfgv[4]
		var lay: Dictionary = SimTouch.layout(vw, vh, dpv, port, lh, 8.0, true)
		var tag: String = "%dx%d %s%s" % [int(vw), int(vh), "portrait" if port else "landscape", " left-handed" if lh else ""]
		ok(lay.has("stick"), "full %s: the stick zone is there" % tag)
		for n in names:
			ok(lay.has(n), "full %s: %s exists" % [tag, n])
		for a in range(names.size()):
			var c: Dictionary = lay[names[a]]
			ok(float(c.x) - float(c.r) >= 0.0 and float(c.x) + float(c.r) <= vw and float(c.y) - float(c.r) >= 0.0 and float(c.y) + float(c.r) <= vh, "full %s: %s is on screen" % [tag, names[a]])
			ok(float(c.r) >= 24.0 * dpv - 0.01, "full %s: %s is a 48 dp target" % [tag, names[a]])
			for b in range(a + 1, names.size()):
				var d: Dictionary = lay[names[b]]
				var dist: float = sqrt((float(c.x) - float(d.x)) * (float(c.x) - float(d.x)) + (float(c.y) - float(d.y)) * (float(c.y) - float(d.y)))
				ok(dist >= float(c.r) + float(d.r) + 2.0 * dpv, "full %s: %s and %s do not touch" % [tag, names[a], names[b]])
		var t := SimTouch.new()
		t.dp = dpv
		t.set_preset("touch-full")
		for n in names:
			ok(t.widget_at(float(lay[n].x), float(lay[n].y), lay) == n, "full %s: the centre of %s hits %s" % [tag, n, n])
		ok(t.widget_at(vw * 0.5, 4.0, lay) == "", "full %s: the top of the screen hits nothing" % tag)
	# Simple's layout is untouched by the new parameter.
	var simple: Dictionary = SimTouch.layout(2321.0, 1072.0, 2.75, false)
	ok(simple.has("attack") and not simple.has("light"), "the default layout is still Simple's")


func _buttons() -> void:
	var t := _mk()
	t.touch_down(1, 0.0, 0.0, "light")
	var i: SimIntent = t.build()
	ok(i.light and not i.heavy, "full: Light is a light on the tick it lands (no wait, no gesture)")
	t.consumed()
	t.touch_up(1)
	t.touch_down(2, 0.0, 0.0, "heavy")
	t.touch_down(3, 0.0, 0.0, "signature")
	i = t.build()
	ok(i.heavy and i.sig, "full: Heavy and Signature")
	t.consumed()
	t.touch_up(2)
	t.touch_up(3)
	t.touch_down(4, 0.0, 0.0, "context")
	ok(t.build().context, "full: Context")
	t.consumed()
	t.touch_up(4)
	# Guard: held, with its press edge.
	t.touch_down(5, 0.0, 0.0, "guard")
	i = t.build()
	ok(i.guard and i.guardPress, "full: Guard is held, with its press edge")
	t.consumed()
	t.touch_up(5)
	ok(not t.build().guard, "full: and lets go")
	t.consumed()
	# Dodge: tap is a dodge and a lunge; held 12 ticks is a sprint.
	t.touch_down(6, 0.0, 0.0, "dodge")
	i = t.build()
	ok(i.dodge and i.dash and not i.sprint, "full: Dodge tap is the dodge edge and a lunge")
	t.consumed()
	i = _run(t, 13)
	ok(i.sprint, "full: Dodge held 12 ticks is a sprint")
	t.touch_up(6)
	_run(t, 2)
	# Power: press, tap, channel, and the layer.
	t.touch_down(7, 0.0, 0.0, "power")
	i = t.build()
	ok(i.powerPress and i.power and not i.charge, "full: Power down is powerPress, not yet the channel")
	t.consumed()
	i = _run(t, 13)
	ok(i.charge, "full: Power held 12 ticks is the channel")
	t.touch_up(7)
	i = t.build()
	ok(not i.powerTap, "full: a hold has no tap")
	t.consumed()
	t.touch_down(8, 0.0, 0.0, "power")
	_run(t, 4)
	t.touch_up(8)
	ok(t.build().powerTap, "full: a quick Power is powerTap")
	t.consumed()
	t.touch_down(9, 0.0, 0.0, "power")
	_run(t, 2)
	t.touch_down(10, 0.0, 0.0, "light")
	i = t.build()
	ok(i.special == 1 and not i.light, "full: Power held then Light is special 1 (west)")
	t.consumed()
	t.touch_up(10)
	t.touch_down(11, 0.0, 0.0, "heavy")
	ok(t.build().special == 2, "full: then Heavy is special 2 (north)")
	t.consumed()
	t.touch_up(11)
	t.touch_down(12, 0.0, 0.0, "context")
	ok(t.build().special == 3, "full: then Context is special 3 (south)")
	t.consumed()
	t.touch_up(12)
	t.touch_down(13, 0.0, 0.0, "signature")
	i = t.build()
	ok(i.sig and i.special == 0, "full: then Signature is the signature (east)")
	t.consumed()
	t.touch_up(13)
	t.touch_up(9)
	ok(not t.build().powerTap, "full: letting go of Power after a layer press fires no tap")
	t.consumed()
	# Mode: a toggle, with a cooldown.
	_run(t, 14)
	ok(t.build().mode == 0, "full: the mode starts physical")
	t.touch_down(14, 0.0, 0.0, "mode")
	ok(t.build().mode == 1, "full: the Mode button toggles to energy")
	t.consumed()
	t.touch_up(14)
	# Transform: the button held 30 ticks.
	t.touch_down(15, 0.0, 0.0, "transform")
	var i2: SimIntent = _run(t, 15)
	ok(absf(t.transform_hold() - 0.5) < 0.04 and not i2.transform, "full: the Transform button is half way at 15 ticks")
	var got: bool = false
	for k in range(16):
		i2 = t.build()
		t.consumed()
		got = got or i2.transform
	ok(got, "full: the Transform edge at 30 ticks")
	t.touch_up(15)
	ok(t.transform_hold() == 0.0, "full: the ring resets")
	# The display state names every held widget.
	t.touch_down(16, 0.0, 0.0, "light")
	t.touch_down(17, 0.0, 0.0, "guard")
	var d: Dictionary = t.display_state()
	ok(d.has("full") and d["full"].has("light") and d["full"].has("guard") and d.guard.down, "full: display_state lists the held widgets")
	t.release_all()
	d = t.display_state()
	ok(d["full"].is_empty() and not d.guard.down, "full: and is empty after release_all")


## The layout as it was before `top_limit` existed: the offsets from the bottom corners, written out here as the reference.
func _old_layout(vw: float, vh: float, dpv: float, port: bool, lh: bool, margin: float) -> Dictionary:
	var src: Dictionary = SimTouch.FULL_PORT if port else SimTouch.FULL_LAND
	var out: Dictionary = {}
	for k in src:
		var a: Array = src[k]
		var x: float = vw - margin + float(a[0]) * dpv
		if a.size() > 3 and a[3] == "L":
			x = margin + float(a[0]) * dpv
		if lh:
			x = vw - x
		out[k] = {"x": x, "y": vh - margin + float(a[1]) * dpv, "r": float(a[2]) * dpv}
	return out


## top_limit: the Full preset fits under the nameplates on a short screen, and with no limit nothing changes.
func _top_limit() -> void:
	var cases: Array = [[1560.0, 720.0, 2.0, false, 213.0], [2400.0, 1080.0, 2.6, false, 324.0], [2340.0, 1080.0, 2.75, false, 324.0], [2532.0, 1170.0, 3.0, false, 351.0],
		[2560.0, 1600.0, 2.0, false, 480.0], [1920.0, 1200.0, 1.5, false, 360.0], [1280.0, 800.0, 1.0, false, 240.0], [2048.0, 1536.0, 2.0, false, 300.0],
		[1280.0, 720.0, 1.0, false, 216.0], [844.0, 390.0, 1.0, false, 117.0], [1560.0, 720.0, 2.0, false, 200.0], [1560.0, 720.0, 2.0, false, 230.0],
		[1170.0, 2532.0, 3.0, true, 456.0], [828.0, 1792.0, 2.0, true, 320.0], [390.0, 844.0, 1.0, true, 150.0]]
	var fitted: int = 0
	for cs in cases:
		var vw: float = cs[0]
		var vh: float = cs[1]
		var dpv: float = cs[2]
		var port: bool = cs[3]
		var lim: float = cs[4]
		for lh in [false, true]:
			var tag: String = "limit %dx%d dp %.2f %s %s at %d" % [int(vw), int(vh), dpv, "portrait" if port else "landscape", "left" if lh else "right", int(lim)]
			# No limit (omitted, -1, or one nothing reaches): exactly the old layout.
			var old: Dictionary = _old_layout(vw, vh, dpv, port, lh, 8.0)
			var same: bool = true
			for lay in [SimTouch.layout(vw, vh, dpv, port, lh, 8.0, true), SimTouch.layout(vw, vh, dpv, port, lh, 8.0, true, -1.0), SimTouch.layout(vw, vh, dpv, port, lh, 8.0, true, 0.0)]:
				for k in old:
					same = same and absf(float(lay[k].x) - float(old[k].x)) < 1e-9 and absf(float(lay[k].y) - float(old[k].y)) < 1e-9 and absf(float(lay[k].r) - float(old[k].r)) < 1e-9
			ok(same, "%s: with no limit the layout is exactly what it was" % tag)
			var lay2: Dictionary = SimTouch.layout(vw, vh, dpv, port, lh, 8.0, true, lim)
			var simple_same: bool = str(SimTouch.layout(vw, vh, dpv, port, lh, 8.0, false, lim)) == str(SimTouch.layout(vw, vh, dpv, port, lh, 8.0, false))
			ok(simple_same, "%s: the Simple layout ignores a limit" % tag)
			var changed: bool = false
			for k in old:
				changed = changed or absf(float(lay2[k].y) - float(old[k].y)) > 1e-9
			var top_of_old: float = 1.0e9
			for k in old:
				top_of_old = minf(top_of_old, float(old[k].y) - float(old[k].r))
			ok(changed == (top_of_old < lim - 0.01), "%s: it moves only when the old layout reached the limit" % tag)
			if changed:
				fitted += 1
			var names: Array = old.keys()
			var view := Rect2(0.0, 0.0, vw, vh)
			var up: bool = true
			var small: bool = true
			var clash: bool = true
			var on: bool = true
			var hits: bool = true
			var t := SimTouch.new()
			t.dp = dpv
			t.set_preset("touch-full")
			for i in range(names.size()):
				var a: Dictionary = lay2[names[i]]
				up = up and float(a.y) - float(a.r) >= lim - 0.01 if changed else up
				small = small and float(a.r) >= 24.0 * dpv - 0.01
				on = on and view.encloses(Rect2(float(a.x) - float(a.r), float(a.y) - float(a.r), 2.0 * float(a.r), 2.0 * float(a.r)))
				for j in range(i + 1, names.size()):
					var b: Dictionary = lay2[names[j]]
					var dx: float = float(a.x) - float(b.x)
					var dy: float = float(a.y) - float(b.y)
					clash = clash and sqrt(dx * dx + dy * dy) >= float(a.r) + float(b.r) + 2.0 * dpv - 0.01
				# What is drawn is what is hit: the centre and a point just inside the edge, in four directions.
				hits = hits and t.widget_at(float(a.x), float(a.y), lay2) == names[i]
				for dir in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
					hits = hits and t.widget_at(float(a.x) + dir.x * float(a.r) * 0.85, float(a.y) + dir.y * float(a.r) * 0.85, lay2) == names[i]
			ok(up, "%s: no button's top edge is above the limit" % tag)
			ok(small, "%s: no button is under the 48 dp floor" % tag)
			ok(clash, "%s: no two buttons touch (2 dp gap kept)" % tag)
			ok(on, "%s: every button is on screen" % tag)
			ok(hits, "%s: the centre and the inside of every button hit that button" % tag)
			ok(float(lay2["stick"].y0) >= lim - 0.01 or not changed, "%s: the stick zone starts under the limit when it moved" % tag)
	ok(fitted >= 6, "limit: the short screens are the ones that fit (%d cases moved)" % fitted)
	# Rendering's case: 1560 x 720, density 2, plates to 213 px. The old layout's DODGE top was 168.
	var r: Dictionary = SimTouch.layout(1560.0, 720.0, 2.0, false, false, 8.0, true, 213.0)
	ok(float(r["dodge"].y) - float(r["dodge"].r) >= 212.99 and float(r["power"].y) - float(r["power"].r) >= 212.99 and float(r["mode"].y) - float(r["mode"].r) >= 212.99, "limit: at 1560 x 720 density 2 DODGE, POWER and ENERGY clear the plates")
	# A screen too short for any fit still gives the tightest, valid layout (radii at the floor or more, no crash).
	var tight: Dictionary = SimTouch.layout(640.0, 360.0, 1.0, false, false, 8.0, true, 300.0)
	var floor_ok: bool = tight.size() == 10
	for k in tight:
		if k != "stick":
			floor_ok = floor_ok and float(tight[k].r) >= 24.0 - 0.01
	ok(floor_ok, "limit: an impossible limit returns the tightest layout, radii at the floor")


func _tap(t: SimTouch, w: String, id: int) -> void:
	t.touch_down(id, 0.0, 0.0, w)
	_run(t, 3)
	t.touch_up(id)


## The HUD's view of the arming in display_state()["full"][id]: `armed` is the share of the 90 ticks left, `latched` is energy's latch.
func _armed_display() -> void:
	var t := SimTouch.new()
	t.dp = 2.75
	t.set_preset("touch-full")   # the one-shot is on by default here
	ok(t.display_state()["full"].is_empty() and t.armed_share() == 0.0 and t.armed_stance() == 0 and not t.energy_latched(), "armed: nothing listed at rest")
	# A tap on Guard arms it: listed, not down, nearly the whole window.
	_tap(t, "guard", 1)
	_run(t, 1)
	var g: Dictionary = t.display_state()["full"].get("guard", {})
	ok(g.has("armed") and not g["down"] and g["armed"] > 0.95 and g["latched"] == false and t.armed_stance() == 1 and t.armed_share() > 0.95, "armed: a tap on Guard lists it armed with nearly the whole window")
	ok(not t.display_state()["full"].has("dodge") and not t.display_state()["full"].has("power") and not t.display_state()["full"].has("mode"), "armed: the other stance widgets are not listed")
	# It runs down.
	_run(t, 44)
	var half: float = t.display_state()["full"]["guard"]["armed"]
	ok(absf(half - 0.5) < 0.06 and half < g["armed"], "armed: about half left at 45 ticks (%.3f)" % half)
	# And lapses.
	_run(t, 50)
	ok(t.display_state()["full"].is_empty() and t.armed_share() == 0.0 and t.armed_stance() == 0, "armed: after the 90 ticks it lapses and is no longer listed")
	# A second tap cancels.
	_tap(t, "power", 2)
	_run(t, 2)
	ok(t.display_state()["full"]["power"]["armed"] > 0.9 and t.armed_stance() == 4, "armed: Power armed")
	_tap(t, "power", 3)
	_run(t, 2)
	ok(not t.display_state()["full"].has("power") and t.armed_stance() == 0, "armed: a second tap cancels it")
	# Two armed: both listed, the newest is the stance.
	_tap(t, "dodge", 4)
	_run(t, 6)
	_tap(t, "guard", 5)
	_run(t, 2)
	var f2: Dictionary = t.display_state()["full"]
	ok(f2["dodge"]["armed"] > 0.0 and f2["guard"]["armed"] > f2["dodge"]["armed"] and t.armed_stance() == 1, "armed: two armed are both listed, the newer is the stance")
	# A blow spends what is armed.
	t.touch_down(6, 0.0, 0.0, "light")
	_run(t, 2)
	t.touch_up(6)
	_run(t, 1)
	ok(t.display_state()["full"].is_empty() and t.armed_stance() == 0, "armed: the blow spends the arming")
	# A held stance widget is listed with no arming.
	t.touch_down(7, 0.0, 0.0, "guard")
	_run(t, 20)
	var h: Dictionary = t.display_state()["full"]["guard"]
	ok(h["down"] and h["armed"] == 0.0 and h["latched"] == false, "armed: a held Guard is down, not armed, not latched")
	t.touch_up(7)
	_run(t, 20)
	# The energy latch: a tap on Mode latches (and does not arm), a blow does not spend it, the next tap puts it away.
	_tap(t, "mode", 8)
	_run(t, 2)
	var m: Dictionary = t.display_state()["full"].get("mode", {})
	ok(m.has("latched") and m["latched"] and m["armed"] == 0.0 and not m["down"] and t.energy_latched() and t.armed_stance() == 0, "armed: a tap on Mode latches energy and arms nothing")
	t.touch_down(9, 0.0, 0.0, "light")
	_run(t, 2)
	t.touch_up(9)
	_run(t, 40)
	ok(t.display_state()["full"]["mode"]["latched"] and t.energy_latched(), "armed: the latch outlives a blow and the 90 ticks")
	_tap(t, "mode", 10)
	_run(t, 2)
	ok(not t.display_state()["full"].has("mode") and not t.energy_latched(), "armed: the second tap puts it away")
	# Simple touch has no arming at all.
	var s := SimTouch.new()
	s.dp = 2.75
	ok(s.armed_share() == 0.0 and s.armed_stance() == 0 and not s.energy_latched(), "armed: Simple touch reads as nothing armed")
	# Reading it changes nothing: identical intents with and without the reads.
	var a := SimTouch.new()
	var b := SimTouch.new()
	for x in [a, b]:
		x.dp = 2.75
		x.set_preset("touch-full")
	var same: bool = true
	for k in range(120):
		if k == 4:
			a.touch_down(1, 0.0, 0.0, "dodge")
			b.touch_down(1, 0.0, 0.0, "dodge")
		if k == 8:
			a.touch_up(1)
			b.touch_up(1)
		var ia: int = SimIntent.pack(a.build())
		b.display_state()
		b.armed_share()
		var ib: int = SimIntent.pack(b.build())
		a.consumed()
		b.consumed()
		same = same and ia == ib
	ok(same, "armed: the reads change nothing in the intents")


func _stick() -> void:
	var t := _mk()
	t.touch_down(1, 200.0, 700.0, "stick")
	t.touch_move(1, 200.0, 700.0 - 30.0 * 2.75)
	var i: SimIntent = _run(t, 8)
	ok(i.my > 0.0 and i.my < 1.0 and is_equal_approx(i.my * 16.0, roundf(i.my * 16.0)) and i.mx == 0.0, "full stick: a partial push, quantised, up is positive")
	t.touch_up(1)
	t.consumed()
	# A flick is the dodge edge and a dash in the flick direction.
	t.touch_down(2, 200.0, 700.0, "stick")
	t.touch_move(2, 200.0 + 44.0 * 2.75, 700.0)
	i = t.build()
	ok(i.dodge and i.dash and i.mx == 1.0, "full stick: a flick is the dodge edge and a dash to the right")
	t.consumed()
	t.touch_move(2, 200.0, 700.0)
	i = _run(t, 8)
	ok(i.dash and i.mx == 1.0, "full stick: the dash holds its direction")
	t.touch_up(2)
	_run(t, 12)
	# A sprint from the outer ring.
	t.touch_down(3, 200.0, 700.0, "stick")
	_run(t, 8)
	t.touch_move(3, 200.0 + 80.0 * 2.75, 700.0)
	i = _run(t, 8)
	ok(i.sprint and i.dash, "full stick: the outer ring is a sprint")
	t.touch_up(3)
	i = _run(t, 2)
	ok(not i.sprint, "full stick: and ends on release")


func _fingers() -> void:
	# Five fingers at once: the stick, Guard, Light, Power and Dodge.
	var t := _mk()
	t.touch_down(1, 200.0, 700.0, "stick")
	t.touch_move(1, 200.0 + 40.0 * 2.75, 700.0)
	t.touch_down(2, 0.0, 0.0, "guard")
	t.touch_down(3, 0.0, 0.0, "light")
	t.touch_down(4, 0.0, 0.0, "power")
	t.touch_down(5, 0.0, 0.0, "dodge")
	var i: SimIntent = t.build()
	ok(i.mx > 0.0 and i.dodge and i.powerPress and not i.guard and i.stanceMask == 4, "fingers: five touches at once register; RT dominates, so Guard goes neutral (a stance is exclusive)")
	t.consumed()
	t.release_all()
	i = t.build()
	ok(not i.guard and not i.power and i.mx == 0.0, "fingers: and nothing sticks after release_all")
	# One finger per button.
	t.touch_down(6, 0.0, 0.0, "guard")
	t.touch_down(7, 0.0, 0.0, "guard")
	t.touch_up(7)
	ok(t.build().guard, "fingers: a second finger on a held button does not let go of it")


func _hub() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	ok(hub.touch_preset == "touch-simple" and not hub.touch.full_mode, "hub: touch starts on Simple")
	hub.set_touch_preset("touch-full")
	ok(hub.touch.full_mode and hub.touch_preset == "touch-full", "hub: set_touch_preset switches to Full")
	hub.touch_down(1, 0.0, 0.0, "light")
	ok(hub.intent(0).light and hub.device_of(0) == "touch", "hub: a Full button drives slot 0")
	hub.consumed()
	hub.touch_up(1)
	ok(hub.setup()["assists"][0].is_empty(), "hub: Full has no assists")
	hub.set_touch_preset("nonsense")
	ok(hub.touch_preset == "touch-full", "hub: an unknown preset is ignored")
	hub.set_touch_preset("touch-simple")
	ok(not hub.touch.full_mode, "hub: and back to Simple")
	hub.touch_down(2, 0.0, 0.0, "guard")
	hub.set_touch_preset("touch-full")
	ok(not hub.intent(0).guard, "hub: switching the preset lets everything go")
	# Pause handling reaches the Full layout.
	hub.touch_down(3, 0.0, 0.0, "light")
	hub.drop_edges()
	ok(not hub.intent(0).light, "hub: a press made during a pause is dropped in Full too")
	hub.consumed()
	hub.touch_up(3)
	hub.touch_down(4, 0.0, 0.0, "transform")
	_run_hub(hub, 12)
	hub.resume()
	_run_hub(hub, 15)
	ok(hub.transform_hold(0) < 0.6, "hub: the transform ring restarts after a pause")
	# Through the real sim: Guard in Full is DEFENSIVE.
	hub = SimInputHub.new()
	hub.set_humans(true, false)
	hub.set_touch_preset("touch-full")
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": true}, hub.setup())
	hub.touch_down(1, 0.0, 0.0, "guard")
	for k in range(4):
		hub.set_humans(S.fighters[0].ai == null, S.fighters[1].ai == null)
		if SimCore.step(S, [hub.intent(0), null]):
			hub.consumed()
	ok(S.fighters[0].stance == 1.0, "sim: a held Full Guard is DEFENSIVE")
	SimCore.dispose(S)


func _run_hub(hub: SimInputHub, n: int) -> void:
	for k in range(n):
		hub.intent(0)
		hub.consumed()
