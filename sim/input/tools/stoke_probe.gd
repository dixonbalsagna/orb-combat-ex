extends SceneTree
## Bolus's stoke and the claw law (docs/controls/stoke-and-chin.md): RT held and the right stick pumped back and forth, with a face press (X) made in the middle of the pumping.
## (a blow is the intent's light, or a special when RT is held: with RT down X is the power layer's special). Prints, for each pump period, what the stick does under RT today (requests started), and when the face press lands against a press made with the stick still.
##   godot --headless --path . --script res://sim/input/tools/stoke_probe.gd

func _init() -> void:
	SimInputData.load_and_apply()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	print("X alone: RT held lands %d ticks after the press, RT not held %d" % [_run(0, false, true, 30), _run(0, false, false, 30)])
	for rt in [true, false]:
		for period in [6, 8, 10, 12, 16]:
			for through in [true, false]:
				var starts: int = _count_starts(period, through, rt)
				var lands: Array = []
				for press_at in range(28, 28 + period * 2):
					lands.append(_run(period, through, rt, press_at))
				var worst: int = 0
				var sum: int = 0
				for v in lands:
					worst = maxi(worst, v)
					sum += v
				print("%s, period %2d ticks (%s): requests started %2d in 80 ticks; the X press lands %.1f ticks after the press on average, %d at worst (over %d press ticks)" % [
					"RT held   " if rt else "RT not held", period, "through the centre" if through else "rim to rim      ", starts, float(sum) / float(lands.size()), worst, lands.size()])
	quit(0)


func _pad() -> SimLayout:
	return SimLayout.new(SimInputData.preset("arena"))


## The stick at tick t of a pump of `period` ticks: right for half, then left (through the centre for a tick, or straight across).
func _stick(t: int, period: int, through: bool) -> float:
	if t < 10:
		return 0.0
	var k: int = (t - 10) % period
	var half: int = period / 2
	if k < half:
		if through and k == half - 1:
			return 0.0
		return 1.0
	if through and k == period - 1:
		return 0.0
	return -1.0


func _count_starts(period: int, through: bool, rt: bool) -> int:
	var l: SimLayout = _pad()
	var n: int = 0
	for t in range(80):
		if t == 2 and rt:
			l.analog("pad:rt", 1.0)
		l.axis("pad:rs", _stick(t, period, through) if period > 0 else 0.0, 0.0)
		var i: SimIntent = l.build()
		if i.rsStart:
			n += 1
		l.consumed()
	return n


## Ticks from the X press until the light blow is in the intent (0 = the press tick); -1 if never within 40 ticks.
func _run(period: int, through: bool, rt: bool, press_at: int) -> int:
	var l: SimLayout = _pad()
	var got: int = -1
	for t in range(press_at + 40):
		if t == 2 and rt:
			l.analog("pad:rt", 1.0)
		if t == press_at:
			l.press("pad:west")
		if t == press_at + 2:
			l.release("pad:west")
		l.axis("pad:rs", _stick(t, period, through) if (period > 0 and t < press_at + 20) else 0.0, 0.0)
		var i: SimIntent = l.build()
		if t >= press_at and (i.light or i.special > 0) and got < 0:
			got = t - press_at
		l.consumed()
	return got
