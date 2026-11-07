extends SceneTree
## The KO shot and a finished fight's winner in a 2v2 with hits across fights (sim/core/cross.gd, SimCore.ended): the rig
## shows the fight S holds.   godot --headless --path . --script res://render/camera/tests/cross_ko_check.gd
## - a first KO in the shown fight: the loser's close-up once, no wreck, the match goes on; then the winner's pane takes the
##   screen (the KO'd body is out of the match) and leads toward his focus across
## - the match then ends in the other fight: the final shot, the wreck round the shown fight's winner
## - a KO only in the other fight: no shot here
## - both fights finished, one standing on each team: no wreck, and the rejoin ends anything left of the KO
## - the switch off: a KO is the end, the close-up then the wreck, as before
## - a computer winner flies to the other fight (outside forced on): he stays in his picture, the moves ease, the lead
##   eases in over FOCUS_EASE
## The picture's step change (jolt) of a pane shown on both ticks, outside a cut, is read against the rig's 0.06.

const JOLT_LIMIT: float = 0.06
const OFF_LIMIT: int = 15        # ticks a body may be out of his own picture (launch-director.md, in frame)
const RELEASE_LIMIT: float = 0.30   # within RELEASE_TICKS of a rush's start or stop, as a launch's release in launch_shots_check
const RELEASE_TICKS: int = 10
const RUSH_LIMIT: float = 0.10     # while a pane follows a rush at today's speeds (chase_rush_check's limit)

var fails: int = 0
var checks: int = 0
var notes: Array = []
var rig: SplitRig
var prev: SplitFrame
var last: Array = [null, null]
var rec: Dictionary = {}


func _ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  " + what)


func _new(seed: int, cross: bool, ai: Array = [false, false, false, false]) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": ai[0], "p2": ai[1], "p3": ai[2], "p4": ai[3]}, {"intro": false, "fights": 2, "cross": cross})
	S.dt = SplitRig.DT
	rig = SplitRig.new()
	for k in ["swing_view", "peak_launch", "launch_director", "close_brawl", "readable", "follow_through", "flight_reveal"]:
		rig.set(k, true)   # as main.gd sets the rig with tiles
	rig.reset(S, 1280.0, 720.0)
	prev = null
	last = [null, null]
	rec = {"kinds": [], "ko_begins": 0, "wreck_slot": -1, "ko_slot": -1, "across_slot": -1, "jolt": 0.0, "jolt_at": "", "back_at": -1,
		"cuts": {}, "off_run": 0, "off_max": 0, "w_first": -1, "w_full": -1, "x0": 0.0, "travel": 0.0, "rushing": false, "rush_t": -999, "release": 0.0}
	return S


func _four(S: SimState) -> Array:
	var b: Array = SimStage.bodies(S)
	var out: Array = []
	for k in ["p1", "p2", "p3", "p4"]:
		for f in b:
			if f.keys == k:
				out.append(f)
	return out


## D falls to A in D's fight, between ticks.
func _ko(S: SimState, D, A) -> void:
	SimStage.enter(S, SimStage.fightOf(S, D))
	SimDamage.ko(S, D, A)
	SimStage.enter(S, 0)


func _steps(S: SimState, n: int, watch = null) -> void:
	for t in range(n):
		var wx: float = float(watch.x) if watch != null else 0.0
		SimCore.step(S)
		if watch != null:
			rec.travel = float(rec.travel) + absf(SimWrap.sdx(wx, float(watch.x)))
		var was: String = rig.solo_kind
		var w0: float = absf(float(rig.get("_ac_w") if rig.get("_ac_w") != null else 0.0))
		rig.step(S, 1280.0, 720.0, S.out.fx)
		for i in range(S.stage.fights.size()):
			var o = S.out if i == S.stage.cur else S.stage.fights[i].out
			o.fx.clear()
			o.feed.clear()
		var k: String = rig.solo_kind
		if k != was:
			rec.kinds.append(k if k != "" else "-")
			if k == "ko":
				rec.ko_begins = int(rec.ko_begins) + 1
				rec.ko_slot = rig.solo_slot
			if k == "wreck":
				rec.wreck_slot = rig.solo_slot
			if k == "across":
				rec.across_slot = rig.solo_slot
			if was == "ko" and k == "":
				rec.back_at = S.tick
		if w0 <= 0.0 and absf(float(rig.get("_ac_w") if rig.get("_ac_w") != null else 0.0)) > 0.0 and int(rec.w_first) < 0:
			rec.w_first = S.tick
		if absf(float(rig.get("_ac_w") if rig.get("_ac_w") != null else 0.0)) >= 1.0 and int(rec.w_full) < 0:
			rec.w_full = S.tick
		_read(S, watch)


func _read(S: SimState, watch) -> void:
	var f: SplitFrame = rig.current()
	if watch != null and (watch.rush != null) != bool(rec.rushing):
		rec.rushing = watch.rush != null
		rec.rush_t = S.tick
	if f.cut:
		var why: String = String(rig.cut_why)
		rec.cuts[why] = int(rec.cuts.get(why, 0)) + 1
		last = [null, null]   # a cut starts the step count again
	if prev != null and not f.cut:
		for i in range(2):
			if not (f.shows(i) and prev.shows(i)) or ((prev.sep <= 0.001) != (f.sep <= 0.001)):
				last[i] = null
				continue   # a pane coming into view, or the split opening or closing: a layout change, eased by its own rule, not a camera step
			var z: float = f.cam_z[i]
			var s0 := Vector2(SimWrap.sdx(prev.cam_x[i], f.cam_x[i]) * z / 1280.0, (f.cam_y[i] - prev.cam_y[i]) * z / 1280.0)
			if last[i] == null:
				last[i] = s0   # its first step: a jolt needs two
				continue
			var j: float = (s0 - Vector2(last[i])).length()
			if bool(rec.get("from_back", false)) and int(rec.back_at) < 0:
				rec.ko_start_jolt = maxf(float(rec.get("ko_start_jolt", 0.0)), j)   # the close-up's own start: main's, as in a 1v1
				last[i] = s0
				continue
			if S.tick - int(rec.rush_t) <= RELEASE_TICKS:
				rec.release = maxf(float(rec.release), j)
				last[i] = s0
				continue
			if watch != null and watch.rush != null:
				if j > float(rec.get("rush_jolt", 0.0)):
					rec.rush_jolt = j
				last[i] = s0
				continue
			if j > float(rec.jolt):
				rec.jolt = j
				rec.jolt_at = "tick %d pane %d %s" % [S.tick, i, rig.solo_kind]
			last[i] = s0
	if watch != null:
		var k: int = S.fighters.find(watch)
		var seen: bool = false
		for i in range(2):
			if f.shows(i):
				var p: Vector2 = f.screen_pos(i, watch.x, watch.y + CamParams.CHEST, float(watch.z))
				if p.x >= 0.0 and p.x <= 1280.0 and p.y >= 0.0 and p.y <= 720.0 and (f.sep < 0.5 or i == k or f.e > 0.5):
					seen = true
		rec.off_run = 0 if (seen or int(rec.back_at) < 0) else int(rec.off_run) + 1   # from the hand back: the close-up is the loser's
		rec.off_max = maxi(int(rec.off_max), int(rec.off_run))
	prev = f.duplicate()


func _firstThenLast() -> void:
	var S := _new(51, true)
	var q: Array = _four(S)
	_steps(S, 20)
	_ko(S, q[1], q[0])
	_steps(S, 480)
	_ok(int(rec.ko_begins) == 1 and rec.ko_slot == S.fighters.find(q[1]), "a first KO: one close-up, on him (%d, slot %d)" % [rec.ko_begins, rec.ko_slot])
	_ok(rec.back_at >= 0 and rec.wreck_slot < 0, "... it hands back, and no wreck (%s)" % str(rec.kinds))
	_ok(rig.solo_kind == "across" and rec.across_slot == S.fighters.find(q[0]), "... then the winner's pane has the screen (%s, slot %d)" % [rig.solo_kind, rec.across_slot])
	_ok(not SimCore.ended(S) and S.game.ko != null, "... the match goes on, the fight keeping its KO")
	_ok(float(rec.jolt) <= JOLT_LIMIT, "... every move eases: a jolt of %.3f (%s)" % [rec.jolt, rec.jolt_at])
	_ok(rec.cuts.is_empty(), "... and nothing cuts (%s)" % str(rec.cuts))
	notes.append("first KO: %s, back at tick %d, jolt %.3f, cuts %s" % [str(rec.kinds), rec.back_at, rec.jolt, str(rec.cuts)])
	_ko(S, q[3], q[2])
	_steps(S, 120)
	_ok(SimCore.ended(S), "the other fight's KO ends the match")
	_ok(rig.solo_kind == "wreck" and rec.wreck_slot == S.fighters.find(q[0]), "... the final shot: the wreck round this fight's winner (%s, slot %d)" % [rig.solo_kind, rec.wreck_slot])
	_ok(int(rec.ko_begins) == 1, "... and no second close-up of the first KO")
	SimCore.dispose(S)


func _otherOnly() -> void:
	var S := _new(52, true)
	var q: Array = _four(S)
	_steps(S, 20)
	_ko(S, q[3], q[2])
	_steps(S, 300)
	_ok(rec.kinds.is_empty() and S.game.ko == null, "a KO in the other fight only: no shot here (%s)" % str(rec.kinds))
	SimCore.dispose(S)


func _rejoin() -> void:
	var S := _new(53, true)
	var q: Array = _four(S)
	_steps(S, 20)
	_ko(S, q[1], q[0])
	_steps(S, 200)
	_ko(S, q[2], q[3])
	var n: int = 0
	while S.stage.rejoined == 0 and n < 1800:
		_steps(S, 1)
		n += 1
	_ok(S.stage.rejoined != 0, "both fights finished, one standing on each team: the rejoin comes (%d ticks)" % n)
	var j0: float = float(rec.jolt)
	_steps(S, 120)
	_ok(rec.wreck_slot < 0 and not SimCore.ended(S), "... no wreck, and the match goes on (%s)" % str(rec.kinds))
	_ok(rig.solo_kind != "ko" and rig.solo_kind != "wreck" and rig.solo_kind != "across", "... and nothing of the KO's shots is left after it (%s)" % rig.solo_kind)
	notes.append("rejoin after %d ticks: %s; jolt %.3f to the rejoin, %.3f with it (%s); S.game.ko %s" % [n, str(rec.kinds), j0, rec.jolt, rec.jolt_at, "cleared" if S.game.ko == null else "kept"])
	SimCore.dispose(S)


func _off() -> void:
	var S := _new(51, false)
	var q: Array = _four(S)
	_steps(S, 20)
	_ko(S, q[1], q[0])
	_steps(S, 420)
	_ok(SimCore.ended(S) and int(rec.ko_begins) == 1 and rec.wreck_slot == S.fighters.find(q[0]) and rec.across_slot < 0, "switch off: the close-up then the wreck, as before (%s)" % str(rec.kinds))
	SimCore.dispose(S)


func _flight() -> void:
	DirOutside.setForce(1)
	var S := _new(54, true, [true, false, true, true])
	var q: Array = _four(S)
	rec.from_back = true   # this case reads what's new: from the hand back on
	_steps(S, 20)
	_ko(S, q[1], q[0])
	_steps(S, 900, q[0])
	_ok(rec.across_slot == S.fighters.find(q[0]), "a computer winner: his pane takes the screen (%s)" % str(rec.kinds))
	_ok(float(rec.travel) > 5000.0, "... and he flies to the other fight (%.0f units)" % rec.travel)
	_ok(int(rec.off_max) <= OFF_LIMIT, "... staying in his picture: out at most %d ticks" % rec.off_max)
	_ok(float(rec.jolt) <= JOLT_LIMIT, "... every move eases: a jolt of %.3f (%s)" % [rec.jolt, rec.jolt_at])
	_ok(float(rec.release) <= RELEASE_LIMIT, "... and round his rush's start and stop, a jolt of %.3f" % rec.release)
	_ok(float(rec.get("rush_jolt", 0.0)) <= RUSH_LIMIT, "... and through his rush, a jolt of %.3f" % float(rec.get("rush_jolt", 0.0)))
	var ramp: int = int(rec.w_full) - int(rec.w_first)
	_ok(int(rec.w_first) >= 0 and ramp >= 10 and ramp <= 14, "... and the lead toward his focus eases in over about 12 ticks (%d)" % ramp)
	notes.append("flight: %s, flew %.0f units, out at most %d ticks, jolt %.3f (%s) from the hand back, %.3f round the rush's start and stop, %.3f through it (the close-up's own start %.3f), cuts %s, lead ramp %d ticks" % [str(rec.kinds), rec.travel, rec.off_max, rec.jolt, rec.jolt_at, rec.release, float(rec.get("rush_jolt", 0.0)), float(rec.get("ko_start_jolt", 0.0)), str(rec.cuts), ramp])
	DirOutside.setForce(-1)
	SimCore.dispose(S)


func _initialize() -> void:
	_firstThenLast()
	_otherOnly()
	_rejoin()
	_off()
	_flight()
	for n in notes:
		print("  " + n)
	print("cross_ko_check: %s" % (("%d checks passed" % checks) if fails == 0 else "%d of %d checks FAILED" % [fails, checks]))
	quit(0 if fails == 0 else 1)
