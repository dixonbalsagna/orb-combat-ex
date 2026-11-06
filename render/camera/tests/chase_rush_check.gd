extends SceneTree
## A chase after a send, by a real pad, through the rig as Orb's build sets it (docs/camera/launch-director.md): no slam door on a target in the air, no flapping, and the picture's step and jolt within their limits.
##   godot --headless --path . --script res://render/camera/tests/chase_rush_check.gd
const STEP_LIMIT: float = 0.30   # the picture's step a tick, of the width, during this rush, once it eases up (chase-ease)
const JOLT_LIMIT: float = 0.10   # how much that step may change in a tick
const STEP_POWER: float = 0.06   # ... with the energy model on (power-core), at base power or on the meteor's own curve, where the peak shot has the frame
const JOLT_POWER: float = 0.03
const STEP_TOP: float = 0.25     # ... and an ordinary send at top power: the sharpest chase the model leaves
const JOLT_TOP: float = 0.12
var hard: bool = false
const FLAP_TICKS: int = 30       # one picture for less than this between two splits is a flap
var power: bool = false
var top: bool = false
var sent_at: float = 0.0
var plan: String = ""
var fails: int = 0
var checks: int = 0


func _ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL ", what)


var hub: SimInputHub
var held: Dictionary = {}
var sent: bool = false
var starts: int = 0
var catches: int = 0
var rig: SplitRig
var prev: SplitFrame = null
var last := [Vector2.ZERO, Vector2.ZERO]
var rec: Dictionary = {}
var fast_px: float = 0.0
var trace: bool = false
var lastA := Vector2.ZERO


func _make(sd: int, share: float) -> SimState:
	hub = SimInputHub.new()
	held = {}
	var su: Dictionary = hub.setup()
	su["intro"] = false
	su["planet"] = 7
	su["touch"] = 2
	su["planetGen"] = 3
	if power:
		su["power"] = true
	if top:
		su["startTier"] = 4
	var S := SimCore.createSim()
	SimCore.newMatch(S, sd, {"p1": false, "p2": false}, su)
	S.dt = SplitRig.DT
	S.fighters[1].ai = null
	S.fighters[0].ki = 100.0
	S.fighters[1].ki = 100.0
	S.fighters[1].hp = 100000.0
	hub.set_pad_has_right_stick(0, true)
	sent = false
	starts = 0
	catches = 0
	rig = SplitRig.new()
	rig.swing_view = true
	rig.peak_launch = true
	rig.launch_director = true
	rig.close_brawl = true
	rig.flat_mode = "wide"
	rig.flight_reveal = true
	rig.follow_through = true
	rig.readable = true
	rig.split_share = share
	rig.test_human_slot = 0
	rig.reset(S, 1280.0, 720.0)
	prev = null
	last = [Vector2.ZERO, Vector2.ZERO]
	lastA = Vector2(S.fighters[0].x, S.fighters[0].y)
	rec = {"jolt": 0.0, "jolt_at": "", "zj": 0.0, "cuts": {}, "off_a": 0, "off_a_run": 0, "off_d": 0, "off_d_run": 0, "rmin": 1.0, "modes": [], "spd": 0.0, "step": 0.0}
	return S


func _btn(name: String, down: bool) -> void:
	if down == held.has(name):
		return
	if down:
		held[name] = true
	else:
		held.erase(name)
	hub.pad_button(0, name, down)


func _step(S: SimState, watch: bool = true) -> void:
	hub.set_humans(S.fighters[0].ai == null, S.fighters[1].ai == null)
	hub.set_struggle(0, SimDir.inStruggle(S, S.fighters[0]))
	var it: SimIntent = hub.intent(0)
	var pausing: bool = S.pause.left > 0
	if SimCore.step(S, [it, SimIntent.new()]):
		hub.consumed()
	elif pausing:
		if S.pause.left > 0:
			hub.drop_edges()
		else:
			hub.resume()
	var ev: Array = S.out.fx.duplicate()
	for e in S.out.fx:
		if e.type == "launch_plan" and not sent and S.fighters[1].state == "launched":
			sent = true
			sent_at = Vector2(float(S.fighters[1].vx) / maxf(float(S.fighters[1].launchT), 0.001), S.fighters[1].vy).length()
			plan = String(e.chosen)
		if e.type == "cue" and e.actor == 0.0 and e.kind == "chase":
			if e.text == "start":
				starts += 1
			elif e.text == "catch":
				catches += 1
	hub.on_events(S.out.fx)
	S.out.fx.clear()
	S.out.feed.clear()
	rig.step(S, 1280.0, 720.0, ev)
	var f: SplitFrame = rig.current()
	if watch:
		_read(S, f)
	prev = f.duplicate()


func _read(S: SimState, f: SplitFrame) -> void:
	var A = S.fighters[0]
	var D = S.fighters[1]
	var sp: float = Vector2(SimWrap.sdx(lastA.x, A.x), A.y - lastA.y).length() * 60.0
	lastA = Vector2(A.x, A.y)
	rec.spd = maxf(float(rec.spd), sp)
	var mode: String = f.mode + ("/" + rig.solo_kind if rig.solo_kind != "" else "")
	if f.mode == "merged":
		rec.one = int(rec.get("one", 0)) + 1
	else:
		if f.mode == "opening" and int(rec.get("one", 0)) > 0 and int(rec.get("one", 0)) < FLAP_TICKS:
			rec.flaps = int(rec.get("flaps", 0)) + 1
		if f.mode != "closing":
			rec.one = 0
	if rec.modes.is_empty() or rec.modes[-1] != mode:
		rec.modes.append(mode)
	if f.cut:
		var why: String = String(rig.cut_why)
		rec.cuts[why] = int(rec.cuts.get(why, 0)) + 1
	var pa: Vector2 = f.screen_pos(0, A.x, A.y + CamParams.CHEST)
	var pd: Vector2 = f.screen_pos(1, D.x, D.y + CamParams.CHEST)
	var a_in: bool = (f.shows(0) and pa.x >= 0.0 and pa.x <= 1280.0 and pa.y >= 0.0 and pa.y <= 720.0 and f.weight1(pa) < 1.0)
	var d_in: bool = (f.shows(1) and pd.x >= 0.0 and pd.x <= 1280.0 and pd.y >= 0.0 and pd.y <= 720.0 and f.weight1(pd) > 0.0) or (f.sep < 0.5 and pd.x >= 0.0 and pd.x <= 1280.0 and pd.y >= 0.0 and pd.y <= 720.0)
	rec.off_a_run = 0 if a_in else int(rec.off_a_run) + 1
	rec.off_d_run = 0 if d_in else int(rec.off_d_run) + 1
	rec.off_a = maxi(int(rec.off_a), int(rec.off_a_run))
	rec.off_d = maxi(int(rec.off_d), int(rec.off_d_run))
	rec.rmin = minf(float(rec.rmin), f.cam_z[0] * CamParams.BODY_H / 720.0)
	if prev != null and not f.cut:
		var z: float = f.cam_z[0]
		var s0 := Vector2(SimWrap.sdx(prev.cam_x[0], f.cam_x[0]) * z / 1280.0, (f.cam_y[0] - prev.cam_y[0]) * z / 1280.0)
		var j: float = (s0 - Vector2(last[0])).length()
		rec.step = maxf(float(rec.step), s0.length())
		if j > float(rec.jolt):
			rec.jolt = j
			rec.jolt_at = "tick %d %s" % [S.tick, mode]
		rec.zj = maxf(float(rec.zj), absf(log(f.cam_z[0] / prev.cam_z[0])))
		last[0] = s0
		if trace:
			print("  %d %s sep %.2f e %.2f slot %d r %.3f step %.3f j %.3f A %s %.0f,%.0f D %s %.0f,%.0f a@%.0f,%.0f in %s chase %d slam %d" % [S.tick, mode, f.sep, f.e, f.e_slot, z * 75.0 / 720.0, s0.length(), j, A.state, SimWrap.sdx(lastA.x, A.x), A.y, D.state, D.vx, D.vy, pa.x, pa.y, a_in, rig.chase_slot, rig._slam_slot])


func _toSend(S: SimState) -> bool:
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(A.x + 58.0)
	D.y = A.y
	for k in range(5):
		_step(S, false)
	for tr in range(8):
		_btn("east", true)
		for k in range(70):
			_step(S, false)
			if DirBrawl._g(A, DirBrawl.CHG) == 2 or sent:
				break
		_btn("east", false)
		for k in range(40):
			_step(S, false)
			if sent:
				return D.state == "launched"
		D.x = SimWrap.wrap(A.x + 58.0)
		D.y = A.y
		D.state = "free"
	return false


func _one(sd: int, wait: int, share: float, chain: int, gap: int = 14) -> void:
	var S := _make(sd, share)
	if not _toSend(S):
		print("seed %d: no send" % sd)
		return
	for k in range(wait):
		_step(S)
	for n in range(chain):
		_btn("west", true)
		_step(S)
		_btn("west", false)
		for k in range(gap if chain > 1 else 2):
			_step(S)
	for k in range(180):
		_step(S)
	var name: String = "%sseed %d, %d after the send, %d taps, share %.1f" % [("energy model, top power, " if top else "energy model, base, ") if power else "", sd, wait, chain, share]
	print("%s: %s at %.0f, %d catches; step %.3f, jolt %.3f (%s), size down to %.3f; cuts %s; player off his picture %d ticks, rival %d; %s" % [name, plan, sent_at, catches, rec.step, rec.jolt, rec.jolt_at, rec.rmin, str(rec.cuts), rec.off_a, rec.off_d, " > ".join(PackedStringArray(rec.modes))])
	if not power:
		_ok(catches >= 1, "%s: he caught him" % name)
		_ok(chain == 1 or catches >= chain - 1, "%s: the chain caught him %d times" % [name, catches])
	_ok(float(rec.step) <= (STEP_TOP if hard else (STEP_POWER if power else STEP_LIMIT)), "%s: the picture stepped %.3f of the width" % [name, rec.step])
	_ok(float(rec.jolt) <= (JOLT_TOP if hard else (JOLT_POWER if power else JOLT_LIMIT)), "%s: a jolt of %.3f (%s)" % [name, rec.jolt, rec.jolt_at])
	_ok(int(rec.off_a) <= 15, "%s: the player off his picture for %d ticks" % [name, rec.off_a])
	_ok(rec.cuts.is_empty() or chain > 1, "%s: cuts %s" % [name, str(rec.cuts)])
	_ok(not ("slam" in rec.modes), "%s: a slam door on a target in the air" % name)
	_ok(int(rec.get("flaps", 0)) == 0, "%s: the view flapped: %s" % [name, str(rec.modes)])
	SimCore.dispose(S)


func _initialize() -> void:
	DirChaseTap.setForce(1)
	DirArc.setForce(1)
	for wait in [0, 8, 20]:
		_one(1, wait, 0.7, 1)
	_one(1, 8, 0.0, 1)
	_one(2, 0, 0.7, 4, 35)
	if FileAccess.file_exists("res://data/fight/power.json"):
		power = true
		for row in [[false, 1], [true, 1], [true, 0]]:
			top = row[0]
			DirArc.setForce(row[1])
			hard = row[1] == 0
			for wait in [0, 8, 20]:
				_one(1, wait, 0.7, 1)
			_one(1, 8, 0.0, 1)
			_one(2, 0, 0.7, 4, 35)
	DirChaseTap.setForce(-1)
	DirArc.setForce(-1)
	print("chase_rush_check: %d checks, %d failed" % [checks, fails] if fails > 0 else "chase_rush_check: %d checks passed" % checks)
	quit(1 if fails > 0 else 0)
