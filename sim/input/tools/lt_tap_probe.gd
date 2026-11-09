extends SceneTree
## Controls' LT tap and hold probe (docs/controls/dash-handover.md): what the pad's LT does tick by tick, and how far a tapped LT carries a fighter. The real hub into the sim (the energy model on), a standing rival
## 3,000 units off, the left stick toward him. Rows: LT released at tick r after its press (r = 0 means held); the number of ticks the intent said dash and sprint, the distance in body heights (75 units) travelled in the
## 60 ticks after the press, the peak speed (units a second) and the speed on tick 1, 6 and 12 after the press.
##   godot --headless --path . --script res://sim/input/tools/lt_tap_probe.gd [-- --sep=3000] [--handover]

const BH: float = 75.0
const RELEASE: Array = [-1, 2, 4, 6, 7, 8, 12, 20, 0]   # -1: no LT at all (the stick alone), the control


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var sep: float = 3000.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sep="):
			sep = float(a.substr(6))
		elif a == "--handover":
			var sw: Dictionary = SimInputData.timing["switches"]
			sw["dashHandover"] = true
			SimInputData.invalidate()
	print("handover switch: %s ; separation %d" % [str(SimInputData.timing.get("switches", {}).get("dashHandover", "n/a")), int(sep)])
	print("(the stick is held toward him the whole 60 ticks, so even a tap travels on at the plain flight speed: read the distance against the control row)")
	print("released at | dash ticks | sprint ticks | travelled (bh) in 60 ticks | peak speed | speed at tick 1, 6, 12")
	for r in RELEASE:
		var o: Dictionary = _run(sep, r)
		print("%11s | %10d | %12d | %26.2f | %10d | %d, %d, %d" % ["no LT" if r < 0 else ("held" if r == 0 else str(r)), o["dash"], o["sprint"], o["bh"], int(o["peak"]), int(o["v1"]), int(o["v6"]), int(o["v12"])])
	quit(0)


func _run(sep: float, release_at: int) -> Dictionary:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	su["power"] = true
	su["travel"] = 1.5
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	b.x = SimWrap.wrap(a.x + sep)
	b.y = a.y
	var quiet := SimIntent.new()
	for t in range(30):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	for t in range(40):   # settle: nothing moves him
		a.vx = 0.0
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var x0: float = a.x
	var peak: float = 0.0
	var dash: int = 0
	var sprint: int = 0
	var v: Dictionary = {}
	hub.pad_stick(7, 1.0, 0.0)
	if release_at >= 0:
		hub.pad_trigger(7, "lt", 1.0)
	for t in range(1, 61):
		if release_at > 0 and t == release_at + 1:
			hub.pad_trigger(7, "lt", 0.0)
		var i: SimIntent = hub.intent(0)
		if i.dash:
			dash += 1
		if i.sprint:
			sprint += 1
		SimCore.step(S, [i, quiet])
		hub.consumed()
		S.out.fx.clear()
		peak = maxf(peak, absf(float(a.vx)))
		v[t] = absf(float(a.vx))
	var o := {"dash": dash, "sprint": sprint, "bh": absf(SimWrap.sdx(x0, a.x)) / BH, "peak": peak, "v1": v[1], "v6": v[6], "v12": v[12]}
	SimCore.dispose(S)
	return o
