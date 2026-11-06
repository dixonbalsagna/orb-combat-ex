extends SceneTree
## The peak launch's shot on the real rig (docs/camera/swing-view.md): a body sent up by the check, in a real match with idle fighters, at
## Game Design's sends. The launch is staged, since no rule in the sim earns it yet: the check writes the body's state and speed.
##   godot --headless --path . --script res://render/camera/tests/peak_shot_check.gd
## Ends with `peak_shot_check: N checks passed` or a line per failure.

const VW: float = 1280.0
const VH: float = 720.0

var fails: int = 0
var checks: int = 0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL ", what)


func _match(tier: float, su: Dictionary = {}) -> SimState:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 7, {"p1": false, "p2": false}, su)
	S.dt = SplitRig.DT
	for f in S.fighters:
		f.tier = tier
	return S


func _rig(S: SimState, on: bool = true, reduced: bool = false) -> SplitRig:
	var rig := SplitRig.new()
	rig.peak_launch = on
	rig.reduced_motion = reduced
	rig.reset(S, VW, VH)
	return rig


func _tick(S: SimState, rig: SplitRig) -> void:
	SimCore.step(S)
	var ev: Array = S.out.fx.duplicate()
	S.out.fx.clear()
	S.out.feed.clear()
	rig.step(S, VW, VH, ev)


func _send(S: SimState, speed: float, deg: float = 60.0) -> void:
	var f = S.fighters[1]
	f.state = "launched"
	f.stateT = 0.0
	f.launchT = 1.0
	f.vx = speed * cos(deg_to_rad(deg))
	f.vy = speed * sin(deg_to_rad(deg))
	f.y += 40.0


## Runs one shot and reads it. `until` a Callable taking (S, rig, tick) may stage an ending.
func _run(S: SimState, rig: SplitRig, ticks: int, until: Callable = Callable()) -> Dictionary:
	var r: Dictionary = {"maxw": 0.0, "split": 0, "cuts": 0, "jump": 0.0, "rate": 0.0, "foe_in": 0, "foe_n": 0, "peak_ticks": 0, "end": -1, "land": -1}
	var prev := Vector3.ZERO
	var pz: float = 0.0
	for t in range(ticks):
		if until.is_valid():
			until.call(S, rig, t)
		_tick(S, rig)
		var c: SplitFrame = rig.current()
		r["split"] = int(r["split"]) + (1 if rig.sep > 0.001 and rig._pk_phase != "" and rig._pk_phase != "back" else 0)
		r["cuts"] = int(r["cuts"]) + (1 if c.cut else 0)
		var z: float = c.cam_z[0]
		if pz > 0.0:
			var dzr: float = absf(log(z / pz)) * 60.0
			r["rate"] = maxf(float(r["rate"]), dzr)
			# how far the launcher moves on the screen in a tick, while he's on it: the frame's own steadiness
			var L = S.fighters[0]
			var lp := Vector2(VW * 0.5 + SimWrap.sdx(c.cam_x[0], L.x) * z, VH * CamParams.PLANE_Y - (L.y + CamParams.CHEST - c.cam_y[0]) * z)
			if not c.cut and t > 0 and lp.x > 0.0 and lp.x < VW and lp.y > 0.0 and lp.y < VH and Vector2(r.get("lp", lp)).x >= 0.0:
				var st: float = lp.distance_to(r.get("lp", lp)) / VW
				if st > float(r["jump"]):
					r["jump"] = st
					r["jump_at"] = "%d %s" % [t, rig._pk_phase]
			r["lp"] = lp
		prev = Vector3(c.cam_x[0], c.cam_y[0], z)
		pz = z
		if rig._pk_phase != "":
			r["peak_ticks"] = int(r["peak_ticks"]) + 1
			r["maxw"] = maxf(float(r["maxw"]), rig.peak_width)
		var foe = S.fighters[1]
		if rig._pk_phase == "fall" or rig._pk_phase == "rise" or rig._pk_phase == "hang":
			var px: float = VW * 0.5 + SimWrap.sdx(c.cam_x[0], foe.x) * z
			var py: float = VH * CamParams.PLANE_Y - (foe.y + CamParams.CHEST - c.cam_y[0]) * z
			r["foe_n"] = int(r["foe_n"]) + 1
			if px >= 0.0 and px <= VW and py >= 0.0 and py <= VH:
				r["foe_in"] = int(r["foe_in"]) + 1
		if rig._pk_phase == "hold" and int(r["land"]) < 0:
			r["land"] = t
			r["landw"] = rig.peak_width
		if rig._pk_phase == "back" and not r.has("seen"):
			r["seen"] = "%s h %.0f" % [S.fighters[1].state, float(S.fighters[1].y) - WorldTerrain.groundY(S, S.fighters[1].x)]
		if rig._pk_phase == "" and int(r["peak_ticks"]) > 0 and int(r["end"]) < 0:
			r["end"] = t
			r["why"] = rig._pk_ended
			break
	return r


func _initialize() -> void:
	# the top of the ladder: Game Design's 6,600 at 60 degrees
	var S: SimState = _match(4.0)
	var rig: SplitRig = _rig(S)
	for _t in range(30):
		_tick(S, rig)
	_send(S, 6600.0)
	var r: Dictionary = _run(S, rig, 1500)
	print("the top: most width %.0f, landing width %.0f at tick %d, ended %d (%s), foe in frame %d of %d, zoom rate up to %.2f e-folds/s, the launcher's biggest step %.3f of the width (%s), splits %d, cuts %d; at the end's start: %s" % [r.maxw, float(r.get("landw", 0.0)), r.land, r.end, String(r.get("why", "")), r.foe_in, r.foe_n, r.rate, r.jump, r.get("jump_at", ""), r.split, r.cuts, r.get("seen", "")])
	_ok(float(r.maxw) > 48000.0 and float(r.maxw) <= 53000.0, "the top's width was %f" % r.maxw)
	_ok(int(r.split) == 0, "the shot split")
	_ok(int(r.cuts) == 0, "the shot cut %d times" % r.cuts)
	_ok(int(r.land) > 0, "no landing was seen")
	_ok(String(r.get("why", "")) == "land", "ended on %s" % String(r.get("why", "")))
	_ok(float(r.rate) <= float(CamPlaces.data().peakRate) * 1.15, "the zoom ran %f e-folds a second" % r.rate)
	_ok(rig.current().split_record().get("peak_launch", false) == false, "the record still says peak_launch after the shot")
	_ok(float(r.get("landw", 0.0)) < 16000.0, "the landing's width was %f" % float(r.get("landw", 0.0)))
	_ok(float(r.foe_in) >= 0.85 * float(r.foe_n), "the foe in frame only %d of %d" % [r.foe_in, r.foe_n])

	# the record tells UI while the shot has the screen
	S = _match(4.0)
	rig = _rig(S)
	for _t in range(30):
		_tick(S, rig)
	_ok(not rig.current().split_record().has("peak_launch"), "the record says peak_launch with no shot")
	_send(S, 6600.0)
	for _t in range(40):
		_tick(S, rig)
	_ok(bool(rig.current().split_record().get("peak_launch", false)), "the record doesn't say peak_launch in the shot")

	# the ladder: the lower tier decides, and tier 1 keeps today's framing
	for row in [[1.0, 1400.0, false, 0.0], [2.0, 2600.0, true, 8000.0], [3.0, 3700.0, true, 16000.0], [4.0, 5100.0, true, 32000.0]]:
		S = _match(float(row[0]))
		rig = _rig(S)
		for _t in range(30):
			_tick(S, rig)
		_send(S, float(row[1]))
		r = _run(S, rig, 1000)
		print("tier %d, send %.0f: shot %s, most width %.0f" % [int(row[0]), float(row[1]), int(r.peak_ticks) > 0, r.maxw])
		_ok((int(r.peak_ticks) > 0) == bool(row[2]), "tier %d: shot %s" % [int(row[0]), int(r.peak_ticks) > 0])
		if bool(row[2]):
			_ok(float(r.maxw) <= float(row[3]) * 1.01 and float(r.maxw) > float(row[3]) * 0.6, "tier %d's width was %f against %f" % [int(row[0]), r.maxw, float(row[3])])
	# a strong fighter beating a weak one doesn't get the sky
	S = _match(4.0)
	S.fighters[0].tier = 2.0
	rig = _rig(S)
	for _t in range(30):
		_tick(S, rig)
	_send(S, 6600.0)
	r = _run(S, rig, 1000)
	_ok(float(r.maxw) <= 8000.0 * 1.01, "the lower tier didn't cap it: %f" % r.maxw)
	# a flat launch isn't this shot
	S = _match(4.0)
	rig = _rig(S)
	for _t in range(30):
		_tick(S, rig)
	_send(S, 6600.0, 25.0)
	r = _run(S, rig, 300)
	_ok(int(r.peak_ticks) == 0, "a flat launch got the shot")

	# he brakes: no landing, the shot ends where he stops
	S = _match(4.0)
	rig = _rig(S)
	for _t in range(30):
		_tick(S, rig)
	_send(S, 6600.0)
	var brake := func(St: SimState, _rg, t: int) -> void:
		if t == 300:
			St.fighters[1].state = "idle"
			St.fighters[1].vx = 0.0
			St.fighters[1].vy = 0.0
	r = _run(S, rig, 1200, brake)
	print("a brake: ended %d (%s), biggest step %.3f" % [r.end, String(r.get("why", "")), r.jump])
	_ok(String(r.get("why", "")) == "brake", "the brake ended on %s" % String(r.get("why", "")))

	# the launcher catches him in the air
	S = _match(4.0)
	rig = _rig(S)
	for _t in range(30):
		_tick(S, rig)
	_send(S, 6600.0)
	var catch_up := func(St: SimState, _rg, t: int) -> void:
		if t == 120:
			var A = St.fighters[0]
			var B = St.fighters[1]
			A.x = B.x
			A.y = B.y - 300.0
	r = _run(S, rig, 1200, catch_up)
	print("a catch: ended %d (%s), biggest zoom rate %.2f" % [r.end, String(r.get("why", "")), r.rate])
	_ok(String(r.get("why", "")) == "catch", "the catch ended on %s" % String(r.get("why", "")))

	# the motion setting: a cut at the release, still, a cut at the end
	S = _match(4.0)
	rig = _rig(S, true, true)
	for _t in range(30):
		_tick(S, rig)
	_send(S, 6600.0)
	r = _run(S, rig, 1500)
	print("motion: cuts %d, most width %.0f" % [r.cuts, r.maxw])
	_ok(int(r.cuts) == 2, "the motion setting cut %d times" % r.cuts)

	# off
	S = _match(4.0)
	rig = _rig(S, false)
	for _t in range(30):
		_tick(S, rig)
	_send(S, 6600.0)
	r = _run(S, rig, 200)
	_ok(int(r.peak_ticks) == 0 and rig.peak_shots == 0, "the switch off ran the shot")

	if fails == 0:
		print("peak_shot_check: %d checks passed" % checks)
	else:
		print("peak_shot_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 else 0)
