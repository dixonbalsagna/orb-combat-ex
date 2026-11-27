extends SceneTree
## Every hard cut asks the flash register before it's made (the audit's CD-04; VFX's ask_cut, docs/vfx/shared-register.md), and a
## refusal eases or holds: no cut, no dissolve, no unflagged jump.
##   godot --headless --path . --script res://render/camera/tests/cut_register_check.gd
## - real AI matches through the rig as Orb's build sets it, with a real VfxFlashRegistry wired as SplitView wires it (ask_cut when
##   the register has it, else its plain ask), normal and reduced flashing, and the motion setting: every cut frame has the
##   register's granted row on that tick, no cut skipped the gate (cut_unasked 0), and the picture never jumps more than
##   JUMP_LIMIT off a named cut, a whip or the slam (the motion setting's landing did, 5.6 widths, before it was a cut)
## - the same matches with the register kept full: no cut is made at all (each eased or held), and the shown picture never jumps
##   in their place: off a cut, a whip and the slam, its step changes by no more than with room, or JUMP_LIMIT of the width
## - every reason a cut can give (CamParams.CUT_REASONS), through the rig's gate: granted on an empty register with its row,
##   refused on a full one
## Negative control: on main's rig (no gate) the first and third parts fail.
const VW: float = 1280.0
const VH: float = 720.0
const SEEDS: Array = [4, 7, 12, 39, 77, 106]
const TICKS: int = 3600
const JUMP_LIMIT: float = 0.5   # a cut moves the picture a screen or more; the eased forms (a whip, a held frame) stay well under
var fails: int = 0
var checks: int = 0


func _ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  " + what)


func _wire(rig: SplitRig, reg: VfxFlashRegistry, S: SimState) -> void:
	rig.set("flash_ask", func(src: String, area: float, step: float = -1.0) -> bool: return reg.ask(src, Color(0.3, 0.3, 0.35), int(S.tick), area * 1024.0 * 768.0, step))
	rig.set("flash_note", func(src: String, area: float) -> void: reg.note(src, int(S.tick), area * 1024.0 * 768.0))
	if reg.has_method("ask_cut"):
		rig.set("flash_cut", func(why: String, area: float, step: float = -1.0) -> Dictionary: return reg.call("ask_cut", why, area, step, int(S.tick)))


func _row_for(reg: VfxFlashRegistry, from: int, why: String) -> bool:
	for k in range(from, reg.log.size()):
		var src: String = String(reg.log[k].source)
		if bool(reg.log[k].granted) and (src == "hard_cut" or src == "cut_" + why):
			return true
	return false


func _run(seed: int, reduced: bool, full: bool, motion: bool = false) -> Dictionary:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": true, "p2": true}, {"planet": 7, "touch": 1, "planetGen": 3, "intro": false})
	S.dt = SplitRig.DT
	var rig := SplitRig.new()
	for k in ["swing_view", "peak_launch", "launch_director", "close_brawl", "readable", "follow_through", "flight_reveal"]:
		rig.set(k, true)   # as main.gd sets the rig with tiles
	rig.flat_mode = "wide"
	rig.split_share = 0.7
	rig.flash_reduced = reduced
	rig.reduced_motion = motion   # the motion setting: its cuts take the place of moves
	var reg := VfxFlashRegistry.new()
	_wire(rig, reg, S)
	rig.reset(S, VW, VH)
	var r: Dictionary = {"cuts": {}, "unreg": [], "jump": 0.0, "jump_at": -1}
	var prev: SplitFrame = rig.current().duplicate()
	var last := Vector2.ZERO
	var fresh: bool = true
	for t in range(TICKS):
		reg.begin_tick(reduced or motion)
		if full:
			reg.note("filler", int(S.tick), VfxFlashRegistry.AREA_FULL * 4.0)   # the budget kept spent: every ask is refused
		SimCore.step(S)
		var ev: Array = S.out.fx.duplicate()
		S.out.fx.clear()
		S.out.feed.clear()
		var n0: int = reg.log.size()
		rig.step(S, VW, VH, ev)
		var f: SplitFrame = rig.current()
		var ii: int = 0 if f.sep < 0.5 else (f.e_slot if f.e_slot >= 0 else 0)
		var jj: int = 0 if prev.sep < 0.5 else (prev.e_slot if prev.e_slot >= 0 else 0)
		var st := Vector2(SimWrap.sdx(prev.cam_x[jj], f.cam_x[ii]) * f.cam_z[ii] / VW, (f.cam_y[ii] - prev.cam_y[jj]) * f.cam_z[ii] / VW)
		if f.cut:
			var why: String = String(rig.cut_why)
			r.cuts[why] = int(r.cuts.get(why, 0)) + 1
			if not _row_for(reg, n0, why):
				r.unreg.append("%s at %d" % [why, S.tick])
		elif t > 10 and ii == jj and not fresh and int(rig._wp_t[ii]) < 0 and rig._slam_slot < 0 and (st - last).length() > float(r.jump):   # (a whip and the slam are named moves, as launch_shots_check reads them)
			r.jump = (st - last).length()
			r.jump_at = S.tick
		fresh = f.cut or ii != jj   # a new picture: its first step is compared with nothing
		last = st
		prev = f.duplicate()
	for k in ["cut_asked", "cut_refused", "cut_unasked"]:
		r[k] = int(rig.get(k) if rig.get(k) != null else -1)
	SimCore.dispose(S)
	return r


## Every reason through the gate: granted with its row on an empty register, refused on a full one.
func _reasons() -> void:
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, 7, {"p1": true, "p2": true}, {"planet": 7, "touch": 1, "planetGen": 3, "intro": false})
	var rig := SplitRig.new()
	var reg := VfxFlashRegistry.new()
	_wire(rig, reg, S)
	rig.reset(S, VW, VH)
	var no_row: Array = []
	var granted_full: Array = []
	var has_gate: bool = rig.has_method("_cut_gate")
	for why in CamParams.CUT_REASONS.keys():
		reg.reset()
		reg.begin_tick(false)
		var n0: int = reg.log.size()
		var a: String = String(rig.call("_cut_gate", String(why))) if has_gate else ""
		if a != "cut" or not _row_for(reg, n0, String(why)):
			no_row.append(why)
		reg.reset()
		reg.begin_tick(true)
		reg.note("filler", 0, VfxFlashRegistry.AREA_FULL * 4.0)
		rig.set("_cut_hold_until", {})
		var b: String = String(rig.call("_cut_gate", String(why))) if has_gate else "cut"
		if b == "cut":
			granted_full.append(why)
	print("every reason (%d): not granted with a row on an empty register %s; granted on a full one %s" % [CamParams.CUT_REASONS.size(), str(no_row), str(granted_full)])
	_ok(has_gate and no_row.is_empty(), "reasons the gate doesn't grant with a register row: %s" % str(no_row))
	_ok(has_gate and granted_full.is_empty(), "reasons granted on a full register: %s" % str(granted_full))
	SimCore.dispose(S)


func _initialize() -> void:
	_reasons()
	var cut_free: int = 0
	var refused: int = 0
	for mode in ["normal", "reduced", "motion"]:
		var red: bool = mode == "reduced"
		var mot: bool = mode == "motion"
		for sd in (SEEDS if mode != "motion" else [7, 12]):
			var name: String = "seed %d, %s" % [sd, mode]
			var a: Dictionary = _run(sd, red, false, mot)
			print("%s: cuts %s; asked %d, refused %d, unasked %d; without a register row %d %s; biggest step change off a cut %.3f at %d" % [name, str(a.cuts), a.cut_asked, a.cut_refused, a.cut_unasked, a.unreg.size(), str(a.unreg.slice(0, 4)), a.jump, a.jump_at])
			_ok(a.unreg.is_empty(), "%s: %d cuts without the register's row: %s" % [name, a.unreg.size(), str(a.unreg.slice(0, 6))])
			_ok(int(a.cut_unasked) == 0, "%s: %d cuts skipped the gate" % [name, a.cut_unasked])
			_ok(float(a.jump) <= JUMP_LIMIT, "%s: the picture jumped %.3f of the width at %d with no cut named (a cut that asked nothing)" % [name, a.jump, a.jump_at])
			for k in a.cuts:
				cut_free += int(a.cuts[k])
			var b: Dictionary = _run(sd, red, true, mot)
			print("%s, the register full: cuts %s; asked %d, refused %d; biggest step change %.3f at %d" % [name, str(b.cuts), b.cut_asked, b.cut_refused, b.jump, b.jump_at])
			_ok(b.cuts.is_empty(), "%s: with the register full, cuts were made: %s" % [name, str(b.cuts)])
			_ok(float(b.jump) <= maxf(float(a.jump), JUMP_LIMIT) + 1.0e-6, "%s: with the register full the picture jumped %.3f at %d, against %.3f with room (an eased form that isn't)" % [name, b.jump, b.jump_at, a.jump])
			refused += int(b.cut_refused)
	print("cuts with room: %d; refusals with the register full: %d" % [cut_free, refused])
	_ok(cut_free > 0 and refused > 0, "the runs made no cut (%d) or refused none (%d): the check proves nothing" % [cut_free, refused])
	print("cut_register_check: %d checks, %d failed" % [checks, fails] if fails > 0 else "cut_register_check: %d checks passed" % checks)
	quit(1 if fails > 0 else 0)
