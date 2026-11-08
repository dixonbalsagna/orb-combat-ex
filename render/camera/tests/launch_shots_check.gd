extends SceneTree
## Every high-velocity shot through the real rig (docs/camera/launch-director.md): launches by tier, flat and fast, the meteor, a body through a
## tower, a chase, and real AI fights with whatever's in them. It fails on a jolt, a lost subject or a cut with no named reason. The launches
## are staged (the check writes the body's state and speed), since no rule in the sim earns most of them yet. Nothing else writes the sim.
##   godot --headless --path . --script res://render/camera/tests/launch_shots_check.gd -- [--fights=3] [--ticks=3600] [--measure]
## --measure prints and doesn't fail. Ends with `launch_shots_check: N checks passed` or a line per failure.

const VW: float = 1280.0
const VH: float = 720.0
const DT: float = 1.0 / 60.0

var fails: int = 0
var checks: int = 0
var measure: bool = false
var director: bool = true
var allmoves: bool = false
## A jolt is the picture's step changing in a tick, of the width. A blow's release may start hard (its first ticks: the blow hides the start, as a cut on action does);
## nothing else may. Lost is the subject off the frame in a run of ticks: a launch's climb may leave the top for the first 0.8 s, on Research's reading.
const LIMITS: Dictionary = {"jolt": 0.06, "release": 0.30, "release_zoom": 0.03, "zjolt": 0.012, "lost": 50, "small": 90, "off": 15}
const RELEASE_TICKS: int = 10


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL ", what)


func _match(tier: float, ai: bool = false, seed: int = 77, planet: int = 7) -> SimState:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": ai, "p2": ai}, {"planet": planet, "touch": 1, "planetGen": 3, "intro": false})
	S.dt = DT
	if tier > 0.0:
		for f in S.fighters:
			f.tier = tier
	return S


func _rig(S: SimState, setup: Callable = Callable()) -> SplitRig:
	var rig := SplitRig.new()
	rig.swing_view = true
	rig.peak_launch = true
	rig.launch_director = director
	if allmoves:
		rig.set("flat_mode", "wide")
		rig.set("flight_reveal", true)
		rig.set("follow_through", true); rig.set("close_brawl", true); rig.set("readable", true)
	if setup.is_valid():
		setup.call(rig)
	rig.reset(S, VW, VH)
	return rig


func _send(f, speed: float, deg: float, side: float = 1.0) -> void:
	f.state = "launched"
	f.stateT = 0.0
	f.launchT = 1.0
	f.vx = side * speed * cos(deg_to_rad(deg))
	f.vy = speed * sin(deg_to_rad(deg))
	f.y += 40.0


## The picture's step this tick, per pane: x and y of the camera in widths, and half the zoom's change. A jolt is the step's own change.
func _steps(a: SplitFrame, b: SplitFrame, i: int) -> Vector3:
	var z: float = b.cam_z[i]
	return Vector3(SimWrap.sdx(a.cam_x[i], b.cam_x[i]) * z / VW, (b.cam_y[i] - a.cam_y[i]) * z / VW, 0.5 * log(b.cam_z[i] / a.cam_z[i]))


## Runs a staged or a real stretch and reads every tick. `subject`: a Callable(S, rig) giving who must be in the frame now (a slot), or -1.
func _watch(S: SimState, rig: SplitRig, ticks: int, subject: Callable, stage: Callable = Callable()) -> Dictionary:
	var small_run: int = 0
	var off_run: int = 0
	var r: Dictionary = {"off": 0, "off_at": "", "small": 0, "small_at": "", "release": 0.0, "jolt": 0.0, "jolt_at": "", "zjolt": 0.0, "zjolt_at": "", "lost": 0, "lost_run": 0, "lost_at": "", "cuts": {}, "unnamed": 0, "ticks": 0, "whips0": rig.whips}
	var prev: SplitFrame = rig.current()
	var st: Array = [Vector3.ZERO, Vector3.ZERO]
	var fresh: Array = [true, true]
	var run: int = 0
	var since: int = 0 if S.fighters[1].state == "launched" else 999
	var was: Array = [S.fighters[0].state, S.fighters[1].state]
	for t in range(ticks):
		if stage.is_valid():
			stage.call(S, rig, t)
		var why0: String = rig.cut_why
		rig.cut_why = ""
		SimCore.step(S)
		var ev: Array = S.out.fx.duplicate()
		S.out.fx.clear()
		S.out.feed.clear()
		rig.step(S, VW, VH, ev)
		var f: SplitFrame = rig.current()
		r.ticks += 1
		since += 1
		for k in range(2):
			if S.fighters[k].state != was[k]:
				if S.fighters[k].state == "launched" or was[k] == "launched":
					since = 0
				was[k] = S.fighters[k].state
		for e in ev:
			if String(e.type) == "land":
				since = 0   # a body landing hard is a release too: a skid landing keeps him "launched", and the frame that chased him stops with him, under the impact's own shake and debris
		if f.cut:
			var why: String = rig.cut_why
			if why == "" or not CamParams.CUT_REASONS.has(why):
				r.unnamed += 1
				why = "?" if why == "" else why
			r.cuts[why] = int(r.cuts.get(why, 0)) + 1
		elif rig.cut_why == "":
			rig.cut_why = why0
		for i in range(2):
			if f.cut or not f.shows(i) or not prev.shows(i) or (f.e > 0.5 and f.e_slot != i):   # (a sliver's camera isn't a picture anyone's reading)
				fresh[i] = true
				continue
			var s: Vector3 = _steps(prev, f, i)
			if not bool(fresh[i]) and rig._wp_t[i] < 0:
				var o: Vector3 = st[i]
				var j: float = Vector2(s.x - o.x, s.y - o.y).length()
				if measure and j > 0.25:
					print("    big tick %d pane %d: j %.3f prev step %.3f now %.3f mode %s solo %s %s e %.2f sep %.2f slam %d lag %d rush %s state %s/%s" % [S.tick, i, j, Vector2(o.x, o.y).length(), Vector2(s.x, s.y).length(), f.mode, rig.solo_kind, rig.solo_phase, rig.e, rig.sep, rig._slam_slot, rig.lag_whips, rig._rush_pin[i], S.fighters[0].state, S.fighters[1].state])
				if rig._slam_slot >= 0 or t < 10:
					pass   # the slam is a named move, 12 eased frames (director.md section 11), and a match's first ticks are its framing arriving
				elif since <= RELEASE_TICKS:
					r.release = maxf(float(r.release), j)
				elif j > float(r.jolt):
					r.jolt = j
					r.jolt_at = "tick %d pane %d: %s, %s, %s, step %.3f, %s" % [S.tick, i, f.mode, rig.solo_kind + " " + rig.solo_phase, S.fighters[i].state, Vector2(s.x, s.y).length(), rig.scape_now]
				var zj: float = absf(s.z - o.z)
				if since <= RELEASE_TICKS:
					_ok(zj <= float(LIMITS.release_zoom), "a release's zoom jolt of %.4f at tick %d" % [zj, S.tick])
				elif rig._slam_slot >= 0:
					pass   # the slam's own door, as for the jolt above
				elif zj > float(r.zjolt):
					r.zjolt = zj
					r.zjolt_at = "tick %d pane %d: %s, %s, %s, zoom step %.4f" % [S.tick, i, f.mode, rig.solo_kind + " " + rig.solo_phase, S.fighters[i].state, s.z]
			st[i] = s
			fresh[i] = false
		if "readable" in rig and rig.readable:
			# a body out of the pane that's his: the player always sees himself
			var gone: bool = false
			for i1 in range(2):
				var f1 = S.fighters[i1]
				if f.shows(i1) and rig._slam_slot < 0 and rig._pk_phase == "" and (rig.solo_kind == "" or rig.solo_slot == i1) and f.sep >= 0.999:
					var sp: Vector2 = f.screen_pos(i1, f1.x, f1.y + CamParams.CHEST)
					if sp.x < 0.0 or sp.x > VW or sp.y < 0.0 or sp.y > VH or f.weight1(sp) != (1.0 if i1 == 1 else 0.0):
						gone = true
			off_run = off_run + 1 if gone else 0
			if off_run > int(r.off):
				r.off = off_run
				r.off_at = "tick %d: %s, %s" % [S.tick, f.mode, rig.solo_kind]
			# small and slow: the rule asks for a size and the picture is well under it
			var sm: bool = false
			for i0 in range(2):
				var want_r: float = rig.read_size(S, i0)
				if f.shows(i0) and want_r > 0.0 and f.cam_z[i0] * CamParams.BODY_H / VH < want_r * 0.9:
					sm = true
			small_run = small_run + 1 if sm else 0
			if small_run > int(r.small):
				r.small = small_run
				r.small_at = "tick %d: %s, %s, %s/%s" % [S.tick, f.mode, rig.solo_kind, S.fighters[0].state, S.fighters[1].state]
		var who: int = subject.call(S, rig) if subject.is_valid() else -1
		var off: bool = false
		if who >= 0:
			var seen: bool = false
			var fw = S.fighters[who]
			for i in range(2):
				if f.shows(i):
					var p: Vector2 = f.screen_pos(i, fw.x, fw.y + CamParams.CHEST, float(fw.z))
					if p.x >= -20.0 and p.x <= VW + 20.0 and p.y >= -20.0 and p.y <= VH + 20.0:
						seen = true
			off = not seen
		if off:
			run += 1
			r.lost += 1
			if run > int(r.lost_run):
				r.lost_run = run
				r.lost_at = "tick %d: %s, %s, sep %.2f, slot %d %s" % [S.tick, f.mode, rig.solo_kind + " " + rig.solo_phase, rig.sep, who, S.fighters[who].state]
		else:
			run = 0
		prev = f
	r.whips = rig.whips - int(r.whips0)
	return r


func _say(name: String, r: Dictionary, jolt_limit: float = -1.0) -> void:
	print("%-22s release %.3f jolt %.3f zoom %.4f lost %d (run %d) whips %d cuts %s" % [name, r.release, r.jolt, r.zjolt, r.lost, r.lost_run, r.whips, r.cuts])
	if measure:
		print("    jolt: %s" % r.jolt_at)
		print("    zoom: %s" % r.zjolt_at)
		if int(r.lost_run) > 0:
			print("    lost: %s" % r.lost_at)
	if measure:
		return
	_ok(int(r.unnamed) == 0, "%s: %d cuts with no named reason %s" % [name, r.unnamed, r.cuts])
	_ok(float(r.release) <= float(LIMITS.release), "%s: a release's jolt of %.3f" % [name, r.release])
	_ok(float(r.jolt) <= (jolt_limit if jolt_limit > 0.0 else float(LIMITS.jolt)), "%s: a jolt of %.3f of the width (%s)" % [name, r.jolt, r.jolt_at])
	_ok(float(r.zjolt) <= float(LIMITS.zjolt), "%s: a zoom jolt of %.4f (%s)" % [name, r.zjolt, r.zjolt_at])
	_ok(int(r.lost_run) <= int(LIMITS.lost), "%s: the subject lost for %d ticks (%s)" % [name, r.lost_run, r.lost_at])


## A send like the reel's: 9,000 units a second, nearly flat, at low power: he stays in the picture.
func _in_frame() -> void:
	var setup := func(rig0) -> void:
		rig0.set("readable", true)
		rig0.set("flat_mode", "wide")
		rig0.set("flight_reveal", true)
	for row in [[1.0, 9000.0, 5.0], [2.0, 6000.0, 10.0], [1.0, 9900.0, 0.0]]:
		var r: Dictionary = _staged("in frame, tier %d, %d" % [int(row[0]), int(row[1])], float(row[0]), float(row[1]), float(row[2]), 420, setup, 0.16)
		print("    out of his picture: at most %d ticks %s" % [r.off, r.off_at])
		_ok(int(r.off) <= int(LIMITS.off), "in frame: out of his picture for %d ticks (%s)" % [r.off, r.off_at])


func _flier(_S, _rig0) -> int:
	return 1


func _launched_flier(S, _rig0) -> int:
	return 1 if S.fighters[1].state == "launched" else -1


func _staged(name: String, tier: float, speed: float, deg: float, ticks: int, setup: Callable = Callable(), jolt_limit: float = -1.0) -> Dictionary:
	var S: SimState = _match(tier)
	var rig: SplitRig = _rig(S, setup)
	for _t in range(30):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		rig.step(S, VW, VH, [])
	_send(S.fighters[1], speed, deg)
	var r: Dictionary = _watch(S, rig, ticks, Callable(self, "_launched_flier"))
	_say(name, r, jolt_limit)
	return r


## Game Design's curve (docs/world/ring-any-angle/meteor-arc.md), staged by writing the body's place each tick, as the sim will.
func _arc(t: float, x0: float, g0: float) -> Vector2:
	var H: float = 16400.0
	var D: float = 1.551 * H
	var c: float = 0.581
	var e: float = tan(PI / 4.0 * (1.0 - t / c)) if t < c else tan(PI / 4.0 * (t - c) / (1.0 - c))
	var u: float = 0.5805 * (1.0 - e) if t < c else 0.5805 + 0.4195 * e
	var w: float = u - 0.328 * u * (1.0 - u)
	return Vector2(x0 + D * u, g0 + 4.0 * H * w * (1.0 - w))


func _meteor_arc() -> void:
	var S: SimState = _match(4.0)
	var rig: SplitRig = _rig(S)
	for _t in range(30):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		rig.step(S, VW, VH, [])
	var f = S.fighters[1]
	var x0: float = f.x
	var g0: float = f.y
	var T: int = 372
	var last: Array = [x0, g0]
	var in_frame: Array = [0, 0]
	var stage := func(St: SimState, _r, t: int) -> void:
		var f1 = St.fighters[1]
		if t >= T:
			if t == T:
				f1.state = "down"
				f1.stateT = 0.0
				f1.vx = 0.0
				f1.vy = 0.0
				f1.y = WorldTerrain.groundY(St, f1.x)
			return
		var p: Vector2 = _arc(float(t + 1) / float(T), x0, g0)
		f1.state = "launched"
		f1.launchT = 1.0
		f1.vx = (p.x - float(last[0])) * 60.0
		f1.vy = (p.y - float(last[1])) * 60.0
		f1.x = SimWrap.wrap(p.x)
		f1.y = p.y
		last[0] = p.x
		last[1] = p.y
	var r: Dictionary = _watch(S, rig, 560, Callable(self, "_launched_flier"), stage)
	_say("meteor, the curve", r)


func _tower() -> void:
	var S: SimState = _match(3.0, false, 77, 7)
	var best = null
	for b in S.buildings:
		if b.alive and (best == null or b.h > best.h):
			best = b
	if best == null:
		print("no tower on this planet: skipped")
		return
	S.fighters[0].x = SimWrap.wrap(best.x - 2500.0)
	S.fighters[1].x = SimWrap.wrap(best.x - 2300.0)
	S.fighters[0].y = WorldTerrain.groundY(S, S.fighters[0].x)
	S.fighters[1].y = WorldTerrain.groundY(S, S.fighters[1].x) + 120.0
	var rig: SplitRig = _rig(S)
	for _t in range(10):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
		rig.step(S, VW, VH, [])
	_send(S.fighters[1], 7000.0, 4.0)
	_say("through a tower", _watch(S, rig, 240, Callable(self, "_launched_flier")))


func _chase() -> void:
	var S: SimState = _match(3.0)
	var rig: SplitRig = _rig(S)
	for f0 in S.fighters:
		f0.state = "launched"
		f0.launchT = 1.0
		f0.vx = 0.0
		f0.vy = 0.0
		f0.y = WorldTerrain.groundY(S, f0.x) + 900.0
	rig.reset(S, VW, VH)
	var hold := func(St: SimState, _r, t0: int) -> void:
		for f in St.fighters:
			f.state = "launched"
			f.launchT = 1.0
			f.vx = 9000.0 * minf(1.0, float(t0) / 30.0)   # a sprint comes up to speed
			f.vy = 0.0
			f.y = WorldTerrain.groundY(St, f.x) + 900.0
	_say("flat-out chase", _watch(S, rig, 420, Callable(self, "_flier"), hold))


## A swing waiting at no speed (a form's pause) isn't a running swing, so its shot doesn't hold the size.
func _stall() -> void:
	var S: SimState = _match(0.0, true, 12345)
	var rig: SplitRig = _rig(S)
	rig.set("readable", true)
	S.swing.active = true
	S.swing.cause = "form"
	S.swing.left = 40.0
	S.swing.rate = 0.0
	for t in range(40):
		rig.step(S, VW, VH, [])
	_ok(int(rig._sw_ticks) == 0, "a stalled swing ran the swing's shot for %d ticks" % rig._sw_ticks)
	S.swing.active = false


func _fights(n: int, ticks: int) -> void:
	for seed in range(1, n + 1):
		var S: SimState = _match(0.0, true, seed, [7, 3, 11, 25][seed % 4])
		var rig: SplitRig = _rig(S)
		var r: Dictionary = _watch(S, rig, ticks, Callable(self, "_who"))
		_say("AI fight %d" % seed, r, 0.16)
		if S.get("powerOn") == true:
			_ok(float(r.jolt) <= 0.10, "AI fight %d, energy model: a jolt of %.3f" % [seed, r.jolt])
			_ok(float(r.release) <= 0.05, "AI fight %d, energy model: a release's jolt of %.3f" % [seed, r.release])
		if "readable" in rig and rig.readable:
			print("    small and slow: at most %d ticks %s; a flying body out of his picture: at most %d ticks %s" % [r.small, r.small_at, r.off, r.off_at])
			_ok(int(r.off) <= int(LIMITS.off), "AI fight %d: a flying body out of his picture for %d ticks (%s)" % [seed, r.off, r.off_at])
			_ok(int(r.small) <= int(LIMITS.small), "AI fight %d: a small, slow fighter for %d ticks (%s)" % [seed, r.small, r.small_at])


## In a fight the subject is who a solo shot is on; otherwise nobody may be lost from a pane that's his.
func _who(S: SimState, rig: SplitRig) -> int:
	return rig.solo_slot if rig.solo_slot >= 0 and rig.solo_kind == "launch" else -1


func _initialize() -> void:
	var nf: int = 3
	var tf: int = 3600
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fights="):
			nf = int(a.substr(9))
		elif a.begins_with("--ticks="):
			tf = int(a.substr(8))
		elif a == "--measure":
			measure = true
		elif a == "--off":
			director = false
		elif a == "--all":
			allmoves = true
	_staged("tier 1 up", 1.0, 1400.0, 60.0, 240)
	_staged("tier 2 up", 2.0, 2600.0, 60.0, 360)
	_staged("tier 3 up", 3.0, 3700.0, 60.0, 500)
	_staged("tier 4 up", 4.0, 5100.0, 60.0, 720)
	_staged("meteor (old send)", 4.0, 6600.0, 60.0, 900)
	_staged("flat 5,000", 2.0, 5000.0, 20.0, 360)
	# past the eye's ceiling (director.md section 5), where a follow can only be as soft as this: 0.16 of the width a tick
	_staged("flat 10,800", 2.0, 10800.0, 12.0, 420, Callable(), 0.16)
	_staged("flat 26,700", 3.0, 26700.0, 8.0, 420, Callable(), 0.16)
	_meteor_arc()
	_tower()
	_chase()
	_stall()
	if "readable" in SplitRig.new():
		_in_frame()
	_fights(nf, tf)
	if measure:
		print("launch_shots_check: measured")
	elif fails == 0:
		print("launch_shots_check: %d checks passed" % checks)
	else:
		print("launch_shots_check: %d of %d checks FAILED" % [fails, checks])
	quit(1 if fails > 0 and not measure else 0)
