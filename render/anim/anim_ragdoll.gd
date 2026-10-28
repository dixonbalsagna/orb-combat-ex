class_name AnimRagdoll
extends RefCounted
## The active ragdoll of the animation overhaul (docs/animation/overhaul-plan.md, unit A, with the shapes, the flail and the hit
## table of unit D). Twelve angular degrees of freedom (data/anim/ragdoll.json) on springs around the posed target, added on top
## of the solved pose. It is driven by the body's own motion in the body frame (a streamer drag from the velocity, an inertial
## whip from the acceleration), by the fighter's own shapes (a tuck, a brace, a skid and a crumple, from Art's silhouettes), by
## an early-launch limb flail, and by impulses (a crumple, a hit). It is stepped once per sim tick, never per frame, so the
## picture is the same in a replay at any frame rate, draws no random number and writes nothing to the sim.

const N := 18          # the first 12 are the sagittal ones; the last 6 (flagged oop in the data) are out of the plane and run only with RenderAnim.rd_oop
const N_BASE := 12
const REGIONS := {"head": 0, "core": 1, "arms": 2, "legs": 3}

static var loaded: bool = false
static var bone_a := PackedInt32Array()
static var bone_b := PackedInt32Array()
static var share_a := PackedFloat32Array()
static var is_x := PackedByteArray()           # the sideways partner of the degree before it (a shoulder's sweep): solved with it as one turn
static var axis_c := PackedByteArray()         # the axis of each degree of freedom: 0 z, 1 x, 2 y
static var beta_c := PackedFloat32Array()
static var beta_s := PackedFloat32Array()
static var k_stiff := PackedFloat32Array()
static var k_loose := PackedFloat32Array()
static var damp := PackedFloat32Array()
static var drag := PackedFloat32Array()
static var inertia := PackedFloat32Array()
static var lo := PackedFloat32Array()
static var hi := PackedFloat32Array()
static var tsg := PackedFloat32Array()
static var tuck_t := PackedFloat32Array()      # the generic shape, used when a fighter has none of its own
static var brace_t := PackedFloat32Array()
static var crumple_k := PackedFloat32Array()
static var arch_k := PackedFloat32Array()        # per degree of freedom: the multiplier of its crumple when the BACK met the surface (an arch, not a fold)
static var var_hz: float = 0.18                  # RG0: how far one launch's flail may differ from the data's (shares of the frequency, the amplitude; radians of phase)
static var var_phase: float = 0.6
static var var_amp: float = 0.2
static var side_dead: float = 0.25               # the side-of-hit score under which a crumple is a plain fold
static var lag := PackedInt32Array()             # RG1: ticks a blow takes to reach each degree of freedom (it travels down the body)
static var tier_gain := PackedFloat32Array()     # RG1: the multiplier on impulses and the flail by the opponent's power tier (index tier - 1)
static var mass_of: Dictionary = {}              # RG1: roster id -> mass
static var mass_exp: float = 1.0
static var flail_amp := PackedFloat32Array()
static var flail_hz := PackedFloat32Array()
static var flail_fade := Vector2(0.35, 1.2)
var shape_key: String = ""
var hit_k := PackedFloat32Array()               # per degree of freedom: the flinch multiplier of this fighter's shape (data/anim/shapes.json)
const REDUCED_LIMIT := 0.5               # reduced motion: every joint may turn only this share of its range
static var shapes: Dictionary = {}              # shape key -> {tuck, brace, skid, crumple: PackedFloat32Array}
static var shape_of: Dictionary = {}            # roster id -> shape key
static var hit_gain: float = 1.6
static var hit_kx := PackedFloat32Array()       # N x 4 (head, core, arms, legs)
static var hit_ky := PackedFloat32Array()
static var hit_kc := PackedFloat32Array()
static var hit_vx := PackedFloat32Array()
static var hit_vx_var := PackedInt32Array()     # 1 u, 2 u2
static var hit_kc_var := PackedInt32Array()     # 1 u, 2 u2, 3 one
static var v0: float = 1500.0
static var a0: float = 6000.0
static var a_max: float = 40000.0
static var gate: float = 0.25
static var free_rate: float = 6.0
static var tuck_spin := Vector2(10.0, 15.0)
static var tuck_max: float = 0.7
static var tuck_after := Vector2(0.25, 0.6)
static var brace_time := Vector2(0.08, 0.3)
static var skid_w: float = 0.6
static var crumple_down_w: float = 0.6

var th := PackedFloat32Array()
var om := PackedFloat32Array()
var free: float = 0.0          # 0 the pose is in charge, 1 the body is loose
var out_w: float = 0.0         # how much of the motion is shown (it fades in and out)
var w_tuck: float = 0.0        # the controller's weights this tick
var w_brace: float = 0.0
var w_skid: float = 0.0
var w_crumple: float = 0.0
var w_flail: float = 0.0
var shape := {}                # this fighter's tuck, brace, skid and crumple targets
var phase: float = 0.0
var fv_hz := PackedFloat32Array()              # this launch's own flail: a factor on each degree of freedom's frequency and amplitude, and a phase shift (set_flail_seed)
var fv_amp := PackedFloat32Array()
var fv_ph := PackedFloat32Array()
var fam_amp := PackedFloat32Array()      # this launch's flail family: a multiplier on each degree's amplitude, on its rate, an offset on its phase and a resting bias (set_flail_seed)
var fam_hz := PackedFloat32Array()
var fam_ph := PackedFloat32Array()
var fam_bias := PackedFloat32Array()
var fam_dur: float = 1.0                       # the family's multiplier on how long the flail lasts
var fam_idx: int = -1
var launch_amp: float = 1.0                    # the launch's own power: a light pop flails gently, a full send frantically (ragdoll_motion.json weight.launch)
var launch_dur: float = 1.0
static var families: Array = []
static var comp_strength: float = 0.0   # how much of the springs' own low-pass the flail's target makes up for (a loose joint follows 2 or 3 Hz at a twentieth of the target)
static var comp_max: float = 1.0
static var launch_cfg: Dictionary = {}
static var group_of: PackedInt32Array = PackedInt32Array()   # 0 head, 1 spine, 2 arm, 3 leg, 4 out of the plane
static var side_of: PackedInt32Array = PackedInt32Array()    # -1 left, 1 right, 0 centre
static var ids: PackedStringArray = PackedStringArray()
var n_on: int = N_BASE                         # how many degrees of freedom run: all with RenderAnim.rd_oop, else the sagittal twelve
var weighted: bool = false                     # RG1 on: impulses are scaled by tier and mass and arrive down the body by the lag (set each tick by the fighter)
var mass: float = 1.0
var tier: float = 1.0
var _tick: int = 0
var _oop_live: bool = false                    # the out-of-plane joints have been running since they were last still
var _pend: Array = []                          # [due tick, degree of freedom, impulse] waiting for the lag


static func _varcode(s: String) -> int:
	match s:
		"u":
			return 1
		"u2":
			return 2
		"one":
			return 3
	return 0


static func setup() -> void:
	if loaded:
		return
	loaded = true
	AnimRig.setup()
	var d: Dictionary = AnimData.ragdoll
	var m: Dictionary = AnimData.ragdoll_motion
	var dofs: Array = d.get("dofs", [])
	bone_a.resize(N)
	bone_b.resize(N)
	for a in [share_a, beta_c, beta_s, k_stiff, k_loose, damp, drag, inertia, lo, hi, tsg, tuck_t, brace_t, crumple_k, arch_k, flail_amp, flail_hz, hit_vx]:
		a.resize(N)
	lag.resize(N)
	tier_gain.resize(4)
	for a in [hit_kx, hit_ky, hit_kc]:
		a.resize(N * 4)
	hit_vx_var.resize(N)
	hit_kc_var.resize(N)
	is_x.resize(N)
	axis_c.resize(N)
	for i in range(mini(N, dofs.size())):
		var e: Dictionary = dofs[i]
		bone_a[i] = AnimRig.index[String(e.bone)]
		bone_b[i] = AnimRig.index[String(e.bone2)] if e.has("bone2") else -1
		share_a[i] = float(e.get("share", 1.0))
		is_x[i] = 1 if (String(e.axis) == "x" and not bool(e.get("oop", false))) else 0
		axis_c[i] = 1 if String(e.axis) == "x" else (2 if String(e.axis) == "y" else 0)
		beta_c[i] = cos(float(e.beta))
		beta_s[i] = sin(float(e.beta))
		k_stiff[i] = float(e.k_stiff)
		k_loose[i] = float(e.k_loose)
		damp[i] = float(e.c)
		drag[i] = float(e.drag)
		inertia[i] = float(e.inertia)
		lo[i] = float(e.lo)
		hi[i] = float(e.hi)
		tsg[i] = float(e.tsg)
		tuck_t[i] = float(e.tuck)
		brace_t[i] = float(e.brace)
		crumple_k[i] = float(e.crumple)
		arch_k[i] = float(e.get("arch", 1.0))
		lag[i] = int(e.get("lag", 0))
	var wd: Dictionary = m.get("weight", {})
	mass_of = wd.get("mass", {})
	mass_exp = float(wd.get("mass_exp", 1.0))
	var tg: Array = wd.get("tier_gain", [1.0, 1.0, 1.0, 1.0])
	for ti in range(4):
		tier_gain[ti] = float(tg[mini(ti, tg.size() - 1)])
	var vr: Dictionary = d.get("variety", {})
	families = vr.get("families", [])
	comp_strength = float(vr.get("comp", {}).get("strength", 0.0))
	comp_max = float(vr.get("comp", {}).get("max", 1.0))
	launch_cfg = wd.get("launch", {})
	group_of.resize(N)
	side_of.resize(N)
	ids.resize(N)
	for gi in range(N):
		var gid: String = String(d.dofs[gi].id)
		ids[gi] = gid
		group_of[gi] = 4 if bool(d.dofs[gi].get("oop", false)) else (0 if gid.begins_with("head") else (1 if (gid.begins_with("spine") or gid.begins_with("pel")) else (2 if (gid.begins_with("ua") or gid.begins_with("fa")) else 3)))
		side_of[gi] = -1 if gid.contains("_l") else (1 if gid.contains("_r") else 0)
	var_hz = float(vr.get("hz", 0.18))
	var_phase = float(vr.get("phase", 0.6))
	var_amp = float(vr.get("amp", 0.2))
	side_dead = float(vr.get("side_dead", 0.25))
	var dr: Dictionary = d.get("drive", {})
	v0 = float(dr.get("v0", 1500.0))
	a0 = float(dr.get("a0", 6000.0))
	a_max = float(dr.get("a_max", 40000.0))
	gate = float(dr.get("gate", 0.25))
	free_rate = float(dr.get("free_rate", 6.0))
	var fl: Dictionary = m.get("flail", {})
	var fa: Array = fl.get("amp", [])
	var fh: Array = fl.get("hz", [])
	for i in range(mini(N, fa.size())):
		flail_amp[i] = float(fa[i])
		flail_hz[i] = float(fh[i])
	var ff: Array = fl.get("fade", [0.35, 1.2])
	flail_fade = Vector2(float(ff[0]), float(ff[1]))
	var rg: Dictionary = d.get("regimes", {})
	var rm: Dictionary = m.get("regimes", {})
	var ts: Array = rg.get("tuck_spin", [10.0, 15.0])
	tuck_spin = Vector2(float(ts[0]), float(ts[1]))
	tuck_max = float(rm.get("tuck_max", 0.7))
	var ta: Array = rm.get("tuck_after", [0.25, 0.6])
	tuck_after = Vector2(float(ta[0]), float(ta[1]))
	var bt: Array = rg.get("brace_time", [0.08, 0.3])
	brace_time = Vector2(float(bt[0]), float(bt[1]))
	skid_w = float(rm.get("skid_w", 0.6))
	crumple_down_w = float(rm.get("crumple_down_w", 0.6))
	shapes.clear()
	var sh: Dictionary = m.get("shapes", {})
	for k in sh:
		var one: Dictionary = {}
		for beat in sh[k]:
			var arr := PackedFloat32Array()
			arr.resize(N)
			var src: Array = sh[k][beat]
			for i in range(mini(N, src.size())):
				arr[i] = float(src[i])
			one[beat] = arr
		shapes[k] = one
	shape_of = m.get("fighters", {})
	var hd: Dictionary = m.get("hit", {})
	hit_gain = float(hd.get("gain", 1.6))
	var hdofs: Array = hd.get("dofs", [])
	for i in range(mini(N, hdofs.size())):
		var e2: Dictionary = hdofs[i]
		for r in range(4):
			hit_kx[i * 4 + r] = float(e2.kx[r])
			hit_ky[i * 4 + r] = float(e2.ky[r])
			hit_kc[i * 4 + r] = float(e2.kc[r])
		hit_vx[i] = float(e2.get("vx", 0.0))
		hit_vx_var[i] = _varcode(String(e2.get("vx_var", "u")))
		hit_kc_var[i] = _varcode(String(e2.get("kc_var", "u2")))


func _init() -> void:
	fv_hz.resize(N)
	fv_amp.resize(N)
	fv_ph.resize(N)
	for k in range(N):
		fv_hz[k] = 1.0
		fv_amp[k] = 1.0
		fv_ph[k] = 0.0
	setup()
	th.resize(N)
	om.resize(N)
	set_shape("")


## Picks the fighter's shape from its roster id (a placeholder map in the data until the four fighters have theirs).
func set_shape(roster_id: String) -> void:
	var key: String = String(shape_of.get(roster_id, shape_of.get("default", "")))
	shape = shapes.get(key, {})
	shape_key = key
	var ht: Dictionary = AnimData.shapes.get(key, {}).get("hit", {})
	hit_k.resize(N)
	for i in range(N):
		var bn: String = String(AnimRig.BONES[bone_a[i]][0])
		var grp: String = "legs"
		if bn.begins_with("head") or bn.begins_with("neck"):
			grp = "head"
		elif bn.begins_with("spine") or bn.begins_with("pelvis"):
			grp = "spine"
		elif bn.begins_with("upper_arm") or bn.begins_with("forearm") or bn.begins_with("clavicle"):
			grp = "arms"
		hit_k[i] = float(ht.get("gain", 1.0)) * float(ht.get(grp, 1.0))


## How much the body is moving on its own (for deciding whether to keep stepping).
func energy() -> float:
	var e: float = 0.0
	for i in range(N):
		e += absf(th[i]) + 0.05 * absf(om[i])
	return e


## Whether `energy()` is over `limit`: the same answer, but the sum stops as soon as it is (the terms are never negative).
func energy_over(limit: float) -> bool:
	var e: float = 0.0
	for i in range(N):
		e += absf(th[i]) + 0.05 * absf(om[i])
		if e > limit:
			return true
	return false


func reset() -> void:
	for i in range(N):
		th[i] = 0.0
		om[i] = 0.0
	free = 0.0
	out_w = 0.0
	w_tuck = 0.0
	w_brace = 0.0
	w_skid = 0.0
	w_crumple = 0.0
	w_flail = 0.0
	_pend.clear()


## One sim tick. v and a are the body's velocity (u/s) and non-gravitational acceleration (u/s^2) in the body frame (x
## forward, y up the body); free_t the looseness the regime asks for; the w_ weights (set by the controller) mix the tuck, brace,
## skid and crumple shapes and the flail in; tt the sim time (the flail's clock); amp scales the drive (reduced motion).
func step(dt: float, v: Vector2, a: Vector2, free_t: float, amp: float, tt: float) -> void:
	if not RenderAnim.tick_fast:
		_step_ref(dt, v, a, free_t, amp, tt)
		return
	# reduced motion also narrows every joint's range (a hard tumble saturates the limits at any amplitude, so the drive alone does not calm it)
	var lk: float = REDUCED_LIMIT if amp < 0.999 else 1.0
	_tick += 1
	if n_on < N:
		if _oop_live:
			_oop_live = false   # the out-of-plane joints were just switched off: set them still once
			for zi in range(n_on, N):
				th[zi] = 0.0
				om[zi] = 0.0
	else:
		_oop_live = true
	if not _pend.is_empty():
		var keep: Array = []
		for pi in _pend:
			if int(pi[0]) <= _tick:
				om[int(pi[1])] += float(pi[2])
			else:
				keep.append(pi)
		_pend = keep
	free = move_toward(free, free_t, dt * free_rate)
	var sp: float = clampf(v.length() / v0, 0.0, 2.0)
	var h: float = dt * 0.5
	var g: float = gate + (1.0 - gate) * free
	var s_tuck: PackedFloat32Array = shape.get("tuck", tuck_t)
	var s_brace: PackedFloat32Array = shape.get("brace", brace_t)
	var s_skid: PackedFloat32Array = shape.get("skid", tuck_t)
	var s_crum: PackedFloat32Array = shape.get("crumple", tuck_t)
	var wt: float = w_tuck * amp
	var wb: float = w_brace * amp
	var ws: float = w_skid * amp
	var wc: float = w_crumple * amp
	var wf: float = w_flail * amp
	if wf > 0.001:
		wf *= gain()
	# the joints do not touch each other: each one's spring term, target and drive are the same on both half steps, so they are worked out once and the half steps run on the joint
	for i in range(n_on):
		var kk: float = lerpf(k_stiff[i], k_loose[i], free)
		var target: float = tsg[i] * sp * free
		# a shape whose weight is zero adds nothing: its term is left out (the sum is in the same order)
		if wt != 0.0:
			target += wt * s_tuck[i]
		if wb != 0.0:
			target += wb * s_brace[i]
		if ws != 0.0:
			target += ws * s_skid[i]
		if wc != 0.0:
			target += wc * s_crum[i]
		if wf > 0.001:
			var fhz: float = flail_hz[i] * fv_hz[i] * fam_hz[i]
			var cmp: float = 1.0
			if comp_strength > 0.0:
				# the spring's gain at the flail's rate: the target is made bigger by what it will lose, so the joint swings the amplitude the data names
				var wn: float = sqrt(maxf(kk, 1.0))
				var rr: float = TAU * fhz / wn
				var zt: float = damp[i] / (2.0 * wn)
				var sg: float = 1.0 / sqrt((1.0 - rr * rr) * (1.0 - rr * rr) + 4.0 * zt * zt * rr * rr)
				cmp = pow(clampf(1.0 / maxf(sg, 0.05), 1.0, comp_max * (0.4 if group_of[i] == 4 else 1.0)), comp_strength)   # the out-of-plane joints are made up for less: a twist saturated in a tumble reads as a stuck rag
			target += wf * (flail_amp[i] * fv_amp[i] * fam_amp[i] * launch_amp * cmp * sin(tt * TAU * fhz + phase + fv_ph[i] + fam_ph[i] + float(i) * 1.7) + fam_bias[i])
		var nx: float = beta_c[i]
		var ny: float = beta_s[i]
		var drive: float = (-drag[i] * (v.x * nx + v.y * ny) / v0 - inertia[i] * (a.x * nx + a.y * ny) / a0) * g * amp
		var dmp: float = damp[i]
		var lo_i: float = lo[i] * lk
		var hi_i: float = hi[i] * lk
		for _s in range(2):
			var al: float = -kk * (th[i] - target) - dmp * om[i] + drive
			om[i] += al * h
			th[i] += om[i] * h
			if th[i] < lo_i:
				th[i] = lo_i
				om[i] = maxf(om[i], 0.0)
			elif th[i] > hi_i:
				th[i] = hi_i
				om[i] = minf(om[i], 0.0)


## The step as it was before the per-joint terms were worked out once (`--no-tick-fast`; the bench's before, and what `_test_tick_fast` compares the step with).
func _step_ref(dt: float, v: Vector2, a: Vector2, free_t: float, amp: float, tt: float) -> void:
	# reduced motion also narrows every joint's range (a hard tumble saturates the limits at any amplitude, so the drive alone does not calm it)
	var lk: float = REDUCED_LIMIT if amp < 0.999 else 1.0
	_tick += 1
	if n_on < N:
		if _oop_live:
			_oop_live = false   # the out-of-plane joints were just switched off: set them still once
			for zi in range(n_on, N):
				th[zi] = 0.0
				om[zi] = 0.0
	else:
		_oop_live = true
	if not _pend.is_empty():
		var keep: Array = []
		for pi in _pend:
			if int(pi[0]) <= _tick:
				om[int(pi[1])] += float(pi[2])
			else:
				keep.append(pi)
		_pend = keep
	free = move_toward(free, free_t, dt * free_rate)
	var sp: float = clampf(v.length() / v0, 0.0, 2.0)
	var h: float = dt * 0.5
	var g: float = gate + (1.0 - gate) * free
	var s_tuck: PackedFloat32Array = shape.get("tuck", tuck_t)
	var s_brace: PackedFloat32Array = shape.get("brace", brace_t)
	var s_skid: PackedFloat32Array = shape.get("skid", tuck_t)
	var s_crum: PackedFloat32Array = shape.get("crumple", tuck_t)
	var wt: float = w_tuck * amp
	var wb: float = w_brace * amp
	var ws: float = w_skid * amp
	var wc: float = w_crumple * amp
	var wf: float = w_flail * amp
	if wf > 0.001:
		wf *= gain()
	for _s in range(2):
		for i in range(n_on):
			var kk: float = lerpf(k_stiff[i], k_loose[i], free)
			var target: float = tsg[i] * sp * free + wt * s_tuck[i] + wb * s_brace[i] + ws * s_skid[i] + wc * s_crum[i]
			if wf > 0.001:
				var fhz: float = flail_hz[i] * fv_hz[i] * fam_hz[i]
				var cmp: float = 1.0
				if comp_strength > 0.0:
					# the spring's gain at the flail's rate: the target is made bigger by what it will lose, so the joint swings the amplitude the data names
					var wn: float = sqrt(maxf(kk, 1.0))
					var rr: float = TAU * fhz / wn
					var zt: float = damp[i] / (2.0 * wn)
					var sg: float = 1.0 / sqrt((1.0 - rr * rr) * (1.0 - rr * rr) + 4.0 * zt * zt * rr * rr)
					cmp = pow(clampf(1.0 / maxf(sg, 0.05), 1.0, comp_max * (0.4 if group_of[i] == 4 else 1.0)), comp_strength)   # the out-of-plane joints are made up for less: a twist saturated in a tumble reads as a stuck rag
				target += wf * (flail_amp[i] * fv_amp[i] * fam_amp[i] * launch_amp * cmp * sin(tt * TAU * fhz + phase + fv_ph[i] + fam_ph[i] + float(i) * 1.7) + fam_bias[i])
			var nx: float = beta_c[i]
			var ny: float = beta_s[i]
			var drive: float = (-drag[i] * (v.x * nx + v.y * ny) / v0 - inertia[i] * (a.x * nx + a.y * ny) / a0) * g * amp
			var al: float = -kk * (th[i] - target) - damp[i] * om[i] + drive
			om[i] += al * h
			th[i] += om[i] * h
			if th[i] < lo[i] * lk:
				th[i] = lo[i] * lk
				om[i] = maxf(om[i], 0.0)
			elif th[i] > hi[i] * lk:
				th[i] = hi[i] * lk
				om[i] = minf(om[i], 0.0)


## RG1: the scale of an impulse and of the flail: the opponent's tier over the body's mass. 1 with weighting off.
func gain() -> float:
	if not weighted:
		return 1.0
	var tf: float = clampf(tier, 1.0, 4.0) - 1.0
	var i0: int = int(floor(tf))
	var i1: int = mini(i0 + 1, 3)
	var tg: float = lerpf(tier_gain[i0], tier_gain[i1], tf - float(i0))
	return tg / pow(maxf(mass, 0.2), mass_exp)


## One impulse on one degree of freedom, scaled by gain() and, when weighted, held for the degree's lag so a blow travels down the body.
func _imp(i: int, w: float) -> void:
	if i >= n_on:
		return
	var v: float = w * gain()
	if weighted and lag[i] > 0:
		_pend.append([_tick + lag[i], i, v])
	else:
		om[i] += v


## An impulse on every degree of freedom along its crumple direction: a slam folds the body.
func crumple(sev: float, amp: float, side: float = 1.0) -> void:
	# side: +1 the front met the surface (a fold, as always), -1 the back (an arch: the data's `arch` multiplier), between them a blend; 0 a head or a foot first
	var m: float = clampf((side + 1.0) * 0.5, 0.0, 1.0)
	for i in range(N):
		_imp(i, crumple_k[i] * lerpf(arch_k[i], 1.0, m) * sev * amp)


## RG0: the flail of this launch, from a hash of the fighter's slot, the launch number and the render's count of his flights (an integer hash, no random draw: the same launch flails the
## same way in every replay). Called once as a flight begins; the factors it sets stay until the next one.
func set_flail_seed(slot: int, launch_n: int, flights: int, launch_speed: float = -1.0) -> void:
	phase = hash01(slot, launch_n, flights * 7 + 1) * TAU
	for i in range(N):
		fv_hz[i] = 1.0 + var_hz * (2.0 * hash01(slot * 31 + i, launch_n, flights * 7 + 2) - 1.0)
		fv_amp[i] = 1.0 + var_amp * (2.0 * hash01(slot * 31 + i, launch_n, flights * 7 + 3) - 1.0)
		fv_ph[i] = var_phase * (2.0 * hash01(slot * 31 + i, launch_n, flights * 7 + 4) - 1.0)
	_pick_family(slot, launch_n, flights, launch_speed)



## The family this launch flails in (a hash of the slot, the launch number and his flights, so a replay draws the same) and the launch's own power: each family is its own way of going limp or fighting the air (the rag, the windmill, the
## starfish, the frantic, the whip, the cartwheel), a light pop flails gently and a full send frantically.
func _pick_family(slot: int, launch_n: int, flights: int, launch_speed: float) -> void:
	fam_amp.resize(N)
	fam_hz.resize(N)
	fam_ph.resize(N)
	fam_bias.resize(N)
	for i in range(N):
		fam_amp[i] = 1.0
		fam_hz[i] = 1.0
		fam_ph[i] = 0.0
		fam_bias[i] = 0.0
	fam_dur = 1.0
	fam_idx = -1
	if not families.is_empty():
		fam_idx = int(hash01(slot, launch_n, flights * 7 + 5) * float(families.size())) % families.size()
		var F: Dictionary = families[fam_idx]
		var gn: Array = ["head", "spine", "arm", "leg", "oop"]
		var anti: Dictionary = F.get("anti", {})
		var phv: float = float(F.get("phase", 0.0))
		for i in range(N):
			var g: String = gn[group_of[i]]
			fam_amp[i] = float(F.get("amp", {}).get(g, 1.0))
			fam_hz[i] = float(F.get("hz", {}).get(g, 1.0))
			if phv > 0.0:
				fam_ph[i] = phv * (2.0 * hash01(slot * 31 + i, launch_n, flights * 7 + 6) - 1.0)
			if int(anti.get(g, 0)) == 1 and side_of[i] < 0:
				fam_ph[i] += PI   # the left against the right
			fam_bias[i] = float(F.get("bias", {}).get(String(ids[i]), 0.0))
		fam_dur = float(F.get("dur", 1.0))
	launch_amp = 1.0
	launch_dur = 1.0
	if launch_speed >= 0.0 and not launch_cfg.is_empty():
		var sr: Array = launch_cfg.get("speed", [0.25, 1.8])
		var u: float = clampf((launch_speed / float(launch_cfg.get("ref_speed", 1500.0)) - float(sr[0])) / maxf(float(sr[1]) - float(sr[0]), 0.01), 0.0, 1.0)
		var la: Array = launch_cfg.get("amp", [1.0, 1.0])
		var ld: Array = launch_cfg.get("dur", [1.0, 1.0])
		launch_amp = lerpf(float(la[0]), float(la[1]), u)
		launch_dur = lerpf(float(ld[0]), float(ld[1]), u)

## 0 to 1 from three integers, by a fixed integer mix (the same on every machine: no float in the mix, no random generator).
static func hash01(a: int, b: int, c: int) -> float:
	var h: int = (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	h = (h ^ (h >> 16)) & 0x7fffffff
	return float(h) / 2147483647.0


## An impulse on one degree of freedom (rad/s).
func kick(i: int, w: float) -> void:
	_imp(i, w)


## The hit-reaction kicks from the data table: dx, dy the blow's push in the body frame, force the scaled strength (wear and
## the variant included), region 0 to 3 (head, core, arms, legs), u and u2 the hit's deterministic variants (-1 to 1).
func hit(dx: float, dy: float, force: float, region: int, u: float, u2: float) -> void:
	var f: float = force * hit_gain
	for i in range(N):
		var k: int = i * 4 + region
		var vv: float = 0.0
		match hit_vx_var[i]:
			1:
				vv = u
			2:
				vv = u2
		var cv: float = 0.0
		match hit_kc_var[i]:
			1:
				cv = u
			2:
				cv = u2
			3:
				cv = 1.0
		_imp(i, f * (hit_k[i] if i < hit_k.size() else 1.0) * (hit_kx[k] * dx * (1.0 + hit_vx[i] * vv) + hit_ky[k] * dy + hit_kc[k] * cv))


## Adds the motion to the solved pose, shown at weight w; `scale` (one factor a degree of freedom, optional) lets a limb move less (a broken arm hangs heavy).
## With the joint limits on, every turn it adds is kept inside the joint's range (data/anim/joints.json): a turn that would take an elbow, a knee, a shoulder, a hip,
## the spine or the head past a limit is cut to the largest share of it that stays inside (a pure function of the pose and the turn, so replays agree), and
## a shoulder's lift and sweep are made as one turn about the axis between them, which adds no twist (two turns in a row do, and twist is what folds an elbow
## the wrong way).
func apply(q: Array[Quaternion], w: float, scale: PackedFloat32Array = PackedFloat32Array()) -> void:
	if w <= 0.001:
		return
	var limited: bool = AnimJoints.loaded and AnimJoints.enabled
	var i: int = 0
	while i < N:
		var t: float = th[i] * w * (scale[i] if scale.size() == N else 1.0)
		var ab: int = bone_a[i]
		var b2: int = bone_b[i]
		var pair: bool = limited and is_x[i] == 0 and b2 < 0 and i + 1 < N and is_x[i + 1] == 1 and bone_a[i + 1] == ab
		var t2: float = th[i + 1] * w * (scale[i + 1] if scale.size() == N else 1.0) if pair else 0.0
		var adv: int = 2 if pair else 1
		if absf(t) < 0.0005 and absf(t2) < 0.0005:
			i += adv
			continue
		var axis: Vector3 = Vector3(1, 0, 0) if axis_c[i] == 1 else (Vector3(0, 1, 0) if axis_c[i] == 2 else Vector3(0, 0, 1))
		if not limited:
			if b2 < 0:
				q[ab] = q[ab] * Quaternion(axis, t)
			else:
				var sa0: float = share_a[i]
				q[ab] = q[ab] * Quaternion(axis, t * sa0)
				q[b2] = q[b2] * Quaternion(axis, t * (1.0 - sa0))
		elif pair:
			var rv := Vector3(t2, 0.0, t)
			var ang: float = rv.length()
			_turn(q, ab, Quaternion(rv / ang, ang), -1, 0.0)
		elif b2 < 0:
			_turn(q, ab, Quaternion(axis, t), -1, 0.0)
		else:
			var sa: float = share_a[i]
			_turn(q, ab, Quaternion(axis, t * sa), b2, t * (1.0 - sa))
		i += adv


## Turns bone `ab` by `dq` (and `b2`, when it has one, by `tb` about the same axis as `dq`'s), by the largest share of the turn that keeps both inside their limits.
func _turn(q: Array[Quaternion], ab: int, dq: Quaternion, b2: int, tb: float) -> void:
	var axis_b := Vector3(1, 0, 0) if dq.x * dq.x > dq.z * dq.z else Vector3(0, 0, 1)
	var qa: Quaternion = q[ab] * dq
	var qb: Quaternion = q[b2] * Quaternion(axis_b, tb) if b2 >= 0 else Quaternion.IDENTITY
	if AnimJoints.fast_ok(qa, ab, shape_key) and (b2 < 0 or AnimJoints.fast_ok(qb, b2, shape_key)):
		q[ab] = qa
		if b2 >= 0:
			q[b2] = qb
		return
	var lo: float = 0.0
	var hi: float = 1.0
	for _it in range(6):
		var mid: float = (lo + hi) * 0.5
		var ma: Quaternion = q[ab] * Quaternion.IDENTITY.slerp(dq, mid)
		var mb: Quaternion = q[b2] * Quaternion(axis_b, tb * mid) if b2 >= 0 else Quaternion.IDENTITY
		if AnimJoints.fast_ok(ma, ab, shape_key) and (b2 < 0 or AnimJoints.fast_ok(mb, b2, shape_key)):
			lo = mid
		else:
			hi = mid
	if lo > 0.0:
		q[ab] = q[ab] * Quaternion.IDENTITY.slerp(dq, lo)
		if b2 >= 0:
			q[b2] = q[b2] * Quaternion(axis_b, tb * lo)
