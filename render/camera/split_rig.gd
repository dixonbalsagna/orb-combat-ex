class_name SplitRig
extends RefCounted
## The dynamic split screen's brain (docs/camera/split-screen.md). It reads the sim state once per tick and produces a
## SplitFrame: whether the screen is one view or two panes, where the divider is, and each pane's camera. It never
## writes the sim, draws no sim random numbers and runs on the fixed DT, so it is a pure function of the ticks so far.
##
## Call step(S, vw, vh, events) after each SimCore.step (events: that tick's S.out.fx, before it is cleared), and
## frame(alpha) once per displayed frame for the interpolated result.

const DT: float = 1.0 / 60.0

# --- settings (the player's) ---
var solo_split: bool = true            # against the AI: split like two players (false: follow the human fighter alone when far)
var reduced_motion: bool = false
var pitch_deg: float = 0.0               # the cameras' pitch (Rendering's debug toggle sets it); 0 is straight on
var keep_opponent_in_view: bool = true      # the computer a human launched is followed by a pane, never held out of frame (see _keeps_in_view); false is the old behaviour
var test_human_slot: int = -2           # tools only: -2 reads the sim (a fighter with no AI is a human); 0 or 1 says that slot is the human, -1 none (probes that play AI against AI as player against computer)
var launch_follow: String = "auto"    # "auto" (a human who was launched chases; a human who launched the computer keeps the computer in a pane), "hold" (the old hybrid: stay with the human attacker, then the impact cut), "chase" or "split" (camera-v2.md section 3)
var zoom_pref: float = CamParams.ZOOM_PREF_DEFAULT   # the player's zoom setting, 0 to 10 (default 7)
var pane_request_fn: Callable = Callable()   # (slot) -> {"kind": "normal" | "search", ...}: the hiding hook, unused

# --- view ---
var vw: float = 1280.0
var vh: float = 720.0

# --- orientation (section 5) ---
var u: float = 0.0                     # held signed separation slot 0 to slot 1, shortest way, hysteretic
var sigma_u: int = 1                   # the sign the held separation asks for
var sigma_shown: int = 1               # the layout on screen
var phi: float = 0.0                   # smoothed tilt
var theta: float = 0.0                 # angle of the divider normal
var swing_t: float = -1.0
var _swing_th0: float = 0.0
var _swing_th1: float = 0.0
var _swing_dur: float = CamParams.T_SWING
var _flip_age: float = 99.0
var _prev_d: float = 0.0
var _prev_ad: float = 0.0
var _sep_rate: float = 0.0             # d|u|/dt, units a second (positive while they move apart)

# --- trigger and layout (sections 2, 6, 7) ---
var split_wanted: bool = false
var _view_lost: bool = false             # a fighter is outside the shared view as it is now (the split opens fast)
var sep: float = 0.0
var _below_t: float = 0.0
var _above_t: float = 0.0
var _layout_age: float = 99.0          # time since split_wanted last changed
var r_now: float = 1.0
var _slam_slot: int = -1
var _slam_sep0: float = 1.0
var _slam_last_rem: float = 9.0
var _flash: float = 0.0
var _slam_done: bool = false
var _mode_changes: Array = []          # times of split/merge decisions, for the tests
var _mode_reasons: Array = []          # why, in step with _mode_changes
var time: float = 0.0

# --- expansion and solo shots (sections 8 and 9) ---
var e: float = 0.0
var e_slot: int = -1
var e_target: float = 0.0
var e_hold: bool = false               # keep the pane expanded until the panes have merged
var sliver: float = 0.0
var solo_kind: String = ""
var solo_slot: int = -1
var solo_prio: int = 0
var solo_w: float = 0.0
var solo_target: float = 0.0
var solo_phase: String = ""
var solo_t: float = 0.0
var _solo_dur: float = 0.0
var _land_t: float = 0.0
var _launch_anchor_x: float = 0.5
var _prev_state: Array = ["free", "free"]
var _push: Array = [-1.0, -1.0]
var _shk: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])   # per-pane shake from the shake events {k, x}
var _aim: Array = [null, null]          # per fighter: the (x, y) of the building a brunt is aimed at (launch_depth, chain_link)
var _hit_t: Array = [-1.0, -1.0]        # seconds since this fighter's last building_hit, or -1
var _hit_amp: Array = [0.0, 0.0]
var _hit_hold: Array = [0.0, 0.0]
var _bounce_t: Array = [-1.0e9, -1.0e9]
var _journey_end_evt: Array = [false, false]   # World's journey_end this tick: the chase's follow is over (the state follows it the same tick)
var bounce_pushes: int = 0
var _launch_anchor_y: float = 0.62
var chase_slot: int = -1                # a split pane that chases a launched fighter (no solo shot)
var _chase_land_t: float = 0.0
var _launch_victim: int = -1            # a launched fighter the hybrid rule may hold on the attacker for
var _impact_evt: Array = [false, false]
var _last_pitch: float = 0.0
var _pitch_now: float = 0.0              # the pitch in use: the player's plus a shot's (the transformation's low break)
var _shot_pitch: float = 0.0
var _tf_ver: String = ""                 # the transformation shot's version: full, short ("" for a bare cinematic)
var _tf_phase: String = ""               # gather, break or settle
var _tf_g: int = 0                       # the beats in ticks (docs/design/moveset-rules.md 10.8)
var _tf_b: int = 0
var _tf_s: int = 0
var intro_active: bool = false           # between intro_start and clock_start (docs/architecture/intro-phase.md)
var rush_cuts: int = 0                   # long rushes the rusher's pane was cut ahead for (counted for the tests)
var _rush_pin: Array = [false, false]
var _rush_wait: Array = [0, 0]            # ticks before a long rush's cut ahead is made (a rush that ends in them is not cut for)
var lunge_holds: int = 0                 # lunges held for (counted for the tests); docs/camera/lunge-framing.md
var _lg_slot: int = -1                   # the attacker of a lunge being held for, else -1
var _lg_tgt: int = -1
var _wd_slot: int = -1                   # a one-way lunge's attacker during his wind-up (the incoming read counts down; no hold)
var _wd_tgt: int = -1
var _wd_until: float = -1.0e9
var _lg_until: float = -1.0e9            # the hold ends at this time
var _lg_strike: float = -1.0e9           # the sim time of the strike (end of the move out)
var _lg_sep: float = 0.0                 # the separation when the cue came (the one view's zoom holds at it)
var _lg_mid: float = 0.0                 # the pair's midpoint when the cue came (the box's x is counted from it)
var _lg_box: Array = [0.0, 0.0, 0.0, 0.0]   # the zip's frame: x0, x1 (from _lg_mid), y0, y1: the pair at the cue, widened by what the zip will do
var _lg_cap: float = -1.0e9              # the hold never runs past this time
var feather_mode: int = 0                # the feathered sweep of a layout change: 0 off (the default), 1 only under reduced flashing or reduced motion, 2 always
var _gov_arm_until: float = -1.0e9       # the scroll governor is armed (at a charge's cue) until this time ...
var _gov_arm_speed: float = 0.0          # ... as if the view were already moving this fast (units a second)
var flash_ask: Callable = Callable()     # (source, area as a fraction of the screen, step) -> whether the flash register grants it; SplitView sets it
var _tf_calm: bool = false               # this transformation's break is calm: no hard cut, no low angle (the register refused it, or reduced flashing)
var flash_reduced: bool = false          # the reduced-flashing setting (the host passes the register's `reduced`): calmer passes
var scroll_gov_ticks: int = 0            # ticks the scroll governor held the zoom back (counted for the tests)
var _vlx: Array = [0.0, 0.0]             # the velocity the follow point's lead uses, its change per tick limited (units a second)
var _vly: Array = [0.0, 0.0]
var _anchor_hold: Array = [Vector2.ZERO, Vector2.ZERO]   # the anchor a shot used last, held while the shot fades out
var _vsm: Array = [0.0, 0.0]             # each pane's focus speed, eased (units a second)
var scroll_caps: int = 0                # ticks the re-frame limiter held a pane's focus back (counted for the tests)
var _pfy: Array = [0.0, 0.0]
var _onset_cool: Array = [0, 0]          # ticks before another onset may arm the limiter
var _onset_run: Array = [0, 0]           # ticks the limiter has run in this onset
var _pvy_last: Array = [0.0, 0.0]         # the body's measured vertical velocity last tick (units a second), for the set-down test
var _pst: Array = [Vector2.ZERO, Vector2.ZERO]   # the focus step each pane took last tick (units): the limiter lets a step stay as large, never grow
var _ydefer: Array = [0, 0]              # ticks the focus holds its height after a body is set down on lower ground
var _onset: Array = [0, 0]               # ticks left of a motion's onset (his velocity just stepped): the re-frame limiter's window
var _pfx: Array = [0.0, 0.0]              # last tick's pane focus x
var _vsm_m: float = 0.0                  # the one view's
var dips: int = 0                        # brightness dips started (a safety cut, a rush's cut back, the intro's end), for the flash report
var dip_times: Array = []                # the last 64 of their times
var double_panels: int = 0               # double-hit close-ups made (counted for the tests)
var _dbl_start: float = -1.0e9           # the double hit: when its cue came,
var _dbl_contact: float = -1.0e9         # when its blows land,
var _dbl_until: float = -1.0e9           # and until when the main view keeps its rules (no push, the pull-back, half the shake)
var _dbl_last_t: float = -1.0e9          # the last close-up made (the ration)
var brawl_read: Callable = Callable()   # a test's stand-in for DirBrawl.centre (returns the same dictionary, or {})
var brawl_focus_ticks: int = 0           # ticks the merged focus followed a brawl's centre (counted for the tests)
var _bc_on: bool = false                 # the merged focus is the brawl's centre, eased (or easing back to the pair's middle)
var _bcx: float = 0.0
var _bcy: float = 0.0
var _bc_rel_t: float = 0.0
var _lg_rel: bool = false                # the hold has ended and the frame is easing back to the live pair (no step)
var _lg_rel_t: float = 0.0
var _lg_f: Array = [0.0, 0.0, 0.0, 0.0]  # the box as the camera follows it: centre x (from _lg_mid), width, centre y, height (eased, so the merged camera's velocity lead sees a motion and not a step)
var _nopin_until: Array = [-1.0e9, -1.0e9]   # a lunge or a charge by this fighter is not a one-way rush: no cut ahead
var _lead: Array = [0.0, 0.0]   # the lead room a chased launch gets: world units the focus is ahead of him, signed
var _rush_pin_t: Array = [-1.0e9, -1.0e9]   # the last time each pane was pinned (the tests give the arrival a moment)    # the pane is pinned on a rush's arrival point until the rush ends
var last_stand_shots: int = 0              # last-stand shots started (counted for the tests)
var intro_cuts: int = 0                  # the intro's hard cuts (counted for the tests)
var _in_phase: String = ""               # fall, land, stare or face
var _in_slot: int = -1
var _in_t: int = 0                       # rig ticks since intro_start
var _in_crater_r: float = 0.0
var _in_fall_h: float = 6000.0           # the fall's height, from the event
var _in_stare_t: int = -1                # ticks since the staredown began, -1 before it
var _in_stare_dur: int = 0
var _in_clock_t: float = -1.0            # seconds since the clock started (the push eases out), -1 when not
var _punch_amp: float = CamParams.LIVE_PUNCH
var _punch_len: float = CamParams.LIVE_PUNCH_LEN
var panel_mode: String = "full"          # the player's setting: "full", "still" (a frozen strip) or "off"; reduced motion means still
var panel_flash_off: Array = []   # [] since 2026-10-19 (the strips play as in d3f1ca0e); ["signature"] was: the strips that do not open while Reduce flashing is on (CamParams.PANEL_KINDS names): a signature strip opens on the fire beat, so its opening and its closing are two whole-strip steps that bracket the beam's own in one second (docs/camera/panel-flash.md); [] is the player's setting alone
var panels: int = 0                      # panel cut-ins started (counted for the tests and QA)
var panels_dropped: int = 0              # panel requests refused: the ration, a stronger panel running, no free band
var panel_log: Array = []                # [match time, kind, slot] of each panel started
var _pn: Dictionary = {}                 # the running panel: kind, slot, prio, dur, t, band
var _pn_earned_t: float = -1.0e9
var _derived_beams_t: float = -1.0e9      # when a swat or split cue last came: the new beams of that tick are not signatures
var _sig_attack_t: Array = [-1.0e9, -1.0e9]   # when each fighter last asked for a signature
var _sig_done: Array = [true, true]            # ... and whether its panel has been made    # when each fighter's last signature fire beat asked for a panel
var panel_floor: float = 0.0              # UI's lowest HUD edge at the top, px (UiHud.panel_floor_y()); the top band starts below it
var _beams_seen: Dictionary = {}         # instance ids of the beams already counted (a new one is a signature's fire beat)
var _parry_t: Array = [-1.0e9, -1.0e9]   # when each fighter last parried, for the riposte
var _stiff_w: float = 0.0               # 0..1: how far the slam's stiff filters have come in
var wreck_dir: int = 0                   # the winner's shot: +1 wreckage on the right of him, -1 on the left, 0 none to speak of
var wreck_score: float = 0.0             # the wreckage in view, summed (craters, ruined buildings, slide trenches)
var blow_push: bool = true               # a small push-in on each landed blow by its weight (docs/camera/feel.md); false: none
var blows: int = 0                         # blow pushes started (for the sweep)
var _bp_amp: float = 0.0
var _bp_t: float = -1.0
var _bp_hold: float = 0.0
var _live_punch_at: float = -1.0         # the live version: when the 6-tick punch-in starts (rig time)
var _punch_t: float = -1.0
var _ov_kind: String = ""               # a camera-only cut-in (building smash, crippling moment); "" when none
var _ov_t: float = 0.0
var _ov_dur: float = 0.0
var _ov_slot: int = -1
var _ov_pt: Vector3 = Vector3.ZERO
var _ov_r0: float = 0.11
var _ov_r1: float = 0.11
var _ov_times: Array = []               # start times of recent cut-ins, for the cooldown and the per-minute cap
var _clash_prev: bool = false
var _wide_t: float = -1.0                # a world-change or time-cap pause: the shared view pulls out and returns
var _wide_dur: float = 0.0
var cut_ins: int = 0                    # camera-only cut-ins started (counted for the tests)
var _cut_fade: float = 0.0              # seconds left of a safety cut's fade-in
var _cut_now: bool = false              # a safety cut happened this tick: the frame is a cut
var lag_whips: int = 0                  # ticks the hard bound had to pull a focus (counted for the tests)
var lag_cuts: int = 0                   # safety cuts (a fighter more than 1.5 screens off in one tick)
var _launch_evt: Array = [false, false]   # a `launch` event arrived for this fighter this tick
var fold_active: bool = false
var _fold: Vector3 = Vector3.ZERO

# --- cameras (section 4) ---
var _fx: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])    # focus point per pane (the fighter's chest, filtered)
var _fy: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])
var _zo: PackedFloat64Array = PackedFloat64Array([0.5, 0.5])    # own zoom per pane
var _mx: float = 0.0
var _my: float = 0.0
var _mz: float = 0.5
var _ppx: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])   # last tick's fighter positions, for measured velocities
var _ppy: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])
var _pmx: float = 0.0
var _pmy: float = 0.0
var _solo_decisions: Array = []

var _cur: SplitFrame = SplitFrame.new()
var _prev: SplitFrame = SplitFrame.new()
var _started: bool = false


# ---------------------------------------------------------------------------------------------------- public

func reset(S: SimState, p_vw: float, p_vh: float) -> void:
	vw = maxf(p_vw, 2.0)   # a view of no size (a page still loading, a hidden pane) must not leave a zero in the zoom maths
	vh = maxf(p_vh, 2.0)
	var A = S.fighters[0]
	var B = S.fighters[1]
	u = SimWrap.sdx(A.x, B.x)
	_prev_d = u
	_prev_ad = absf(u)
	sigma_u = 1 if u >= 0.0 else -1
	sigma_shown = sigma_u
	phi = _phi_target(A, B)
	theta = _theta_of(sigma_shown, phi)
	swing_t = -1.0
	_flip_age = 99.0
	split_wanted = false
	sep = 0.0
	e = 0.0
	e_slot = -1
	e_target = 0.0
	e_hold = false
	sliver = 0.0
	solo_kind = ""
	solo_slot = -1
	solo_prio = 0
	solo_w = 0.0
	solo_target = 0.0
	solo_phase = ""
	_slam_slot = -1
	_flash = 0.0
	_push = [-1.0, -1.0]
	_pn = {}
	intro_active = false
	_in_phase = ""
	_in_stare_t = -1
	_in_clock_t = -1.0
	_beams_seen = {}
	_sig_attack_t = [-1.0e9, -1.0e9]
	_sig_done = [true, true]
	_derived_beams_t = -1.0e9
	_rush_pin = [false, false]
	_rush_wait = [0, 0]
	_od_valid = false
	_od_shown = [false, false]
	_cl_rect = [Rect2(), Rect2()]
	_cl_have = [false, false]
	_cl_hold = [0.0, 0.0]
	_cl_sigma = [0.0, 0.0]
	_cl_shown_prev = [false, false]
	_cl_reg = [Rect2(), Rect2()]
	_cl_pc_ok = [false, false]
	_fz = [0.0, 0.0]
	_fzm = 0.0
	_fzo = [0.0, 0.0]
	_tb_cut_t = [-1.0e9, -1.0e9]
	_tb_lost = [0.0, 0.0]
	_lg_slot = -1
	_lg_rel = false
	_vsm = [0.0, 0.0]
	_vlx = [0.0, 0.0]
	_vly = [0.0, 0.0]
	_onset = [0, 0]
	_onset_run = [0, 0]
	_onset_cool = [0, 0]
	_ydefer = [0, 0]
	_pvy_last = [0.0, 0.0]
	_pst = [Vector2.ZERO, Vector2.ZERO]
	_vsm_m = 0.0
	_gov_arm_until = -1.0e9
	_bc_on = false
	_dbl_start = -1.0e9
	_dbl_contact = -1.0e9
	_dbl_until = -1.0e9
	_dbl_last_t = -1.0e9
	_lg_until = -1.0e9
	_lg_cap = -1.0e9
	_wd_slot = -1
	_wd_until = -1.0e9
	_nopin_until = [-1.0e9, -1.0e9]
	_lead = [0.0, 0.0]
	_pn_earned_t = -1.0e9
	_parry_t = [-1.0e9, -1.0e9]
	_shk = PackedFloat64Array([0.0, 0.0])
	_aim = [null, null]
	_hit_t = [-1.0, -1.0]
	_bp_t = -1.0
	_stg_on = [false, false]
	_stg_rel = [0, 0]
	_lens_ok = [false, false]
	_bld_evt_t = [-1.0e9, -1.0e9]
	_lh = [0, 0]
	_lh_gone = [0, 0]
	_lh_rel_t = [-1.0e9, -1.0e9]
	_lh_sky = [false, false]
	fold_active = false
	_below_t = 0.0
	_above_t = 0.0
	_layout_age = 99.0
	_mode_changes.clear()
	_mode_reasons.clear()
	_solo_decisions.clear()
	time = 0.0
	_prev_state = [A.state, B.state]
	r_now = _metric(S)
	split_wanted = r_now < _r_split()
	sep = 1.0 if split_wanted else 0.0
	_intro_adopt(S)
	_snap_cameras(S)
	_started = true
	_anchors_rep_ok = false
	_cur = _make_frame(S)
	_cur.cut = true
	_prev = _cur


## Advance one sim tick. `events` are that tick's fx events (tier_up, cinematic_start, cinematic_end, fold_start,
## unfold, relocate are read; the rest ignored).
func step(S: SimState, p_vw: float, p_vh: float, events: Array = []) -> void:
	if p_vw < 2.0 or p_vh < 2.0:
		return   # no view to frame yet (hidden, or not laid out): keep the last frame; the first real size resets
	if not _started or p_vw != vw or p_vh != vh:
		reset(S, p_vw, p_vh)
		return
	time += DT
	_layout_age += DT
	_flip_age += DT
	if flash_bundle:
		# edge-triggered: the pieces are set when the bundle turns on or off (the reduced-flashing setting changing), so a tool that sets one
		# of them by hand is not overwritten every tick
		var bundle_on: int = 1 if (flash_reduced or not flash_bundle_reduced_only) else 0
		if bundle_on != _fb_prev:
			if bundle_on == 1 or _fb_prev == 1:
				launch_hold = bundle_on == 1
				launch_hold_eager = bundle_on == 1
				slam_off = bundle_on == 1
				# (the merge zoom limit is not in the bundle: with it the pair that has come back together is drawn at 26 px for two to
				# five seconds, the zoom crawling in at 0.2 e-folds a second: Orb's "no idea what they were doing", 2026-10-16)
			_fb_prev = bundle_on
	var cut: bool = false
	for ev in events:
		if String(_ef(ev, "type", "")) == "relocate":
			cut = true
	_read_events(S, events)
	_rush_commit(S)
	_update_lunge(S)
	_update_brawl_focus(S)
	_update_shake(events)
	_flash = maxf(0.0, _flash - DT)
	_update_orientation(S)
	r_now = _metric(S)
	_update_solo(S)
	_update_panel(S)
	_update_intro(S)
	_impact_evt = [false, false]
	_journey_end_evt = [false, false]
	var clash_now: bool = S.game.clash != null
	if clash_now and not _clash_prev and not reduced_motion:
		_push = [0.0, 0.0]   # the beam struggle opens with the tier push's shape: in, hold, out
	_clash_prev = clash_now
	_pitch_now = pitch_deg + _shot_pitch
	if absf(_pitch_now - _last_pitch) > 0.01:
		_last_pitch = _pitch_now
		_cut_now = true
	_update_trigger(S)
	_update_layout()
	_update_pushes()
	_update_cameras(S)
	if cut:
		_snap_cameras(S)
	_cut_fade = maxf(0.0, _cut_fade - DT)
	_prev = _cur
	if cut:
		_cut_now = true   # a relocation is a cut for the foreground's state too
	_cur = _make_frame(S)
	_cur.cut = cut or _cut_now
	_cut_now = false
	for i in range(2):
		_prev_state[i] = S.fighters[i].state


## The frame to draw, interpolated between the last two ticks (alpha in 0..1).
func frame(alpha: float) -> SplitFrame:
	return SplitFrame.lerp_frames(_prev, _cur, clampf(alpha, 0.0, 1.0))


## The frame as of the last tick, uninterpolated.
func current() -> SplitFrame:
	return _cur


func mode_change_times() -> Array:
	return _mode_changes


func mode_change_reasons() -> Array:
	return _mode_reasons


## Whether the layout change at `t` was a shot's ending (a launch settling, a cinematic ending): those skip the dwell.
func launch_decision_at(t: float) -> bool:
	return _solo_decisions.has(t)


## Re-seat everything on the fighters at once (a relocation or a replay seek).
func cut(S: SimState) -> void:
	_snap_cameras(S)
	_cur.cut = true


# ---------------------------------------------------------------------------------------------------- trigger

## The one view's zoom for two fighters ad apart in x and dy in height (pixels per unit). m is the zoom setting's
## multiplier; with `floored` the camera never zooms out past the floor (the size it is aiming at), without it the
## number is the size the fight would like, which is what the split trigger judges.
static func zoom_u(vw_: float, vh_: float, ad: float, dy: float, tier: float, m: float = 1.0, floored: bool = false) -> float:
	var span_x: float = ad + CamParams.FIT_MARGIN_X / m
	var span_y: float = dy + CamParams.REF_MARGIN_Y
	var zcap: float = CamParams.R_MAX * m * vh_ / CamParams.BODY_H
	var z: float = minf(vw_ / span_x, vh_ * 0.8 / span_y)
	if CamParams.ZONE_W > 0.0:
		z = minf(z, CamParams.ZONE_W * vw_ / maxf(ad, 1.0))
	z = minf(z, zcap)
	z *= 1.0 - CamParams.REF_TIER * (tier - 1.0)
	if floored:
		z = maxf(z, CamParams.R_FLOOR * vh_ / CamParams.BODY_H)
	return clampf(z, CamParams.ZOOM_MIN, zcap)


## The zoom setting's multiplier on every size target.
func _m() -> float:
	return exp(CamParams.ZOOM_PREF_K * (zoom_pref - CamParams.ZOOM_PREF_DEFAULT))


func _zcap() -> float:
	return CamParams.R_MAX * _m() * vh / CamParams.BODY_H


## The vertical extent of the pair on the screen, in world units: their height difference, and at a pitch their depth
## difference too (a fighter 1,000 units farther back stands higher on the screen by 1,000 sin(pitch); the sweep found a
## pair 1,098 units apart in depth at 49 degrees, one in view and one below the screen, in a merged view that fitted them
## by height alone).
func _pair_dy(A, B) -> float:
	var pr: float = pitch_deg + _shot_pitch
	if pr == 0.0:
		return absf(A.y - B.y)
	return absf((A.y - B.y) * cos(deg_to_rad(pr)) - (float(A.z) - float(B.z)) * sin(deg_to_rad(pr)))


## r: a fighter's height as a fraction of the screen height in the one-view (reference) framing.
func _metric(S: SimState) -> float:
	var A = S.fighters[0]
	var B = S.fighters[1]
	var z: float = zoom_u(vw, vh, minf(absf(u), SimConst.HALF), _pair_dy(A, B), maxf(A.tier, B.tier))
	return CamParams.BODY_H * z / vh


func _r_split() -> float:
	return maxf(CamParams.R_SPLIT, CamParams.MIN_PX / vh)


func _r_merge() -> float:
	return maxf(CamParams.R_MERGE, CamParams.MIN_PX * CamParams.R_MERGE / CamParams.R_SPLIT / vh)


func _update_trigger(S: SimState) -> void:
	var A = S.fighters[0]
	var B = S.fighters[1]
	var ad: float = absf(u)
	var rs: float = _r_split()
	var rm: float = _r_merge()
	if S.game.clash != null:
		rs = minf(rs, maxf(CamParams.R_BEAM_MIN, CamParams.MIN_PX * 0.66 / vh))
		rm = minf(rm, rs * 1.15)
	# The closing guard: fighters that will be back over the split line soon do not open a split.
	var closing: float = (_prev_ad - ad) / DT
	# Smoothed: the raw rate spikes to +-24,000 units a second in a rush and its recoil, and the one view zooms out for
	# the separation it will have soon, so a spike was a zoom pulse (the sweep's jolt scan found 300 to 490 in a match).
	_sep_rate += (-closing - _sep_rate) * (1.0 - exp(-DT / CamParams.SEP_RATE_TAU))
	var guard_ok: bool = true
	if closing > 0.0:
		var z_pred: float = zoom_u(vw, vh, maxf(0.0, ad - closing * CamParams.CLOSING_LOOKAHEAD), _pair_dy(A, B), maxf(A.tier, B.tier))
		guard_ok = CamParams.BODY_H * z_pred / vh < rs
	_prev_ad = ad
	if fold_active:
		_set_split(false, "fold")
		_slam_slot = -1
		return
	if solo_kind != "":
		# The dwell timers wait while a shot has the screen; its end decides.
		return
	if _lg_slot >= 0:
		return   # a lunge out and back: the layout holds (lunge-framing.md)
	if _slam_slot >= 0 or _slam_step(S):
		return
	_view_lost = _outside_one_view(S) if sep < 0.5 else false
	if not split_wanted:
		_below_t = _below_t + DT if r_now < rs else 0.0
		var out_of_frame: bool = _view_lost
		# The hybrid launch rule: when the human knocked the opponent out of the shared view, stay with the human instead
		# of splitting; the impact cut follows (camera-v2.md section 3).
		if _launch_victim >= 0 and (out_of_frame or r_now <= maxf(CamParams.R_FLOOR, CamParams.MIN_PX / vh)) and S.fighters[_launch_victim].state == "launched":
			_begin_solo("hold", 1 - _launch_victim, 2, 0.0, S)
			return
		# A fighter already lost off the edge of the one view does not wait out the dwell or the full merged age.
		var age_ok: bool = _layout_age >= CamParams.MIN_MERGED_AGE or (out_of_frame and _layout_age >= CamParams.MIN_OUT_OF_FRAME_AGE)
		# A fighter knocked out of the shared view that is still flying apart (two humans: each on his own pane): no
		# waiting for the layout's age. Right after a slam closed the split the age was 0, so the split opened 0.25 s after
		# he left, with him 9,000 units away and out of his pane for the opening (the jolt scan's remaining failures).
		var knocked_apart: bool = chase_slot >= 0 and (out_of_frame or _sep_rate > CamParams.KNOCK_APART_RATE)
		if knocked_apart:
			age_ok = true
		# While they are still moving apart the shared zoom-out holds a little longer (a wide "flying around the world" beat).
		# It runs only between the split line and the floor: below the floor the shared view cannot zoom out any more.
		var floor_r: float = maxf(CamParams.R_FLOOR, CamParams.MIN_PX / vh)
		var dwell: float = CamParams.SPLIT_DWELL + (CamParams.WIDE_HOLD if _sep_rate > 500.0 and r_now > floor_r else 0.0)
		if r_now <= floor_r:
			dwell = 0.0
		if (_below_t >= dwell or out_of_frame or knocked_apart) and age_ok and (guard_ok or out_of_frame or knocked_apart):
			_set_split(true, "out of frame" if (_below_t < dwell or _layout_age < CamParams.MIN_MERGED_AGE) else "trigger")
	else:
		# A pair that is moving apart fast is judged on the separation it will have (MERGE_LOOKAHEAD seconds on): the shared view that merges them zooms
		# out as they part and the split opens again, a merge and a split within two seconds with a pan of 0.09 of the width in between (rushcity,
		# ticks 73 to 140; docs/camera/rushcity.md).
		var r_merge_now: float = r_now
		if merge_lookahead and _sep_rate > 0.0:
			var ad_p: float = minf(SimConst.HALF, ad + _sep_rate * CamParams.MERGE_LOOKAHEAD)
			r_merge_now = minf(r_now, CamParams.BODY_H * zoom_u(vw, vh, ad_p, _pair_dy(A, B), maxf(A.tier, B.tier)) / vh)
		_above_t = _above_t + DT if (r_merge_now > rm and chase_slot < 0) else 0.0   # not while one is being chased
		if _above_t >= CamParams.MERGE_DWELL and _layout_age >= CamParams.MIN_SPLIT_AGE:
			_set_split(false)
	_apply_solo_follow(S)


## Solo against the AI with the split off: the human's pane takes the screen instead of two panes.
func _solo_follow(S: SimState) -> bool:
	return not solo_split and _human_slot(S) >= 0


func _apply_solo_follow(S: SimState) -> void:
	if not _solo_follow(S) or solo_kind != "" or _slam_slot >= 0:
		return
	if split_wanted:
		e_slot = _human_slot(S)
		sliver = 0.0
		e_target = 1.0
		e_hold = false


## Whether the one-view camera, as it is now, has lost a fighter off its edge: the split opens without waiting.
func _outside_one_view(S: SimState) -> bool:
	for i in range(2):
		var f = S.fighters[i]
		var px: float = absf(SimWrap.sdx(_mx, f.x)) * _mz
		var py: float = vh * CamParams.PLANE_Y - (f.y + CamParams.CHEST - _my) * _mz
		if px > CamParams.FRAME_MARGIN * vw or py < 0.04 * vh or py > 0.96 * vh:
			return true
	return false


func _human_slot(S: SimState) -> int:
	var h: int = -1
	for i in range(2):
		if _is_human(S, i):
			if h >= 0:
				return -1
			h = i
	return h


func _is_human(S: SimState, k: int) -> bool:
	if test_human_slot != -2:
		return k == test_human_slot
	return S.fighters[k].ai == null


func _set_split(want: bool, why: String = "trigger") -> void:
	if want == split_wanted:
		return
	split_wanted = want
	if not want and e_target > 0.5 and solo_kind == "":
		e_hold = true   # a pane that has the screen keeps it until the panes are one
	_layout_age = 0.0
	_below_t = 0.0
	_above_t = 0.0
	_mode_changes.append(time)
	_mode_reasons.append(("split " if want else "merge ") + why)


## The slam: a rush toward the other fighter, seen while split, starts a lean, then a 0.14 s door-shut timed to the
## contact. Returns true while a slam owns the layout.
func _slam_step(S: SimState) -> bool:
	if (slam_off and (flash_reduced or reduced_motion)) or not split_wanted or sep < 0.5 or _solo_follow(S) or _lg_slot >= 0:
		return false
	# Not while a pane still holds the screen (e above 0.05, the ease back from a shot): the door sets e from its own clock,
	# so starting it then moved the divider 0.4 of the width in a tick (found by the jolt scan).
	if e > 0.05 and _slam_slot < 0:
		return false
	# Nor when one view cannot hold the pair (their size on the screen below the floor: a pair 2,600 units apart in depth
	# at 49 degrees): the door would shut on a view with one of them off the bottom of the screen for the dwell.
	if r_now < maxf(CamParams.R_FLOOR, CamParams.MIN_PX / vh) and _slam_slot < 0:
		return false
	for k in range(2):
		var f = S.fighters[k]
		if f.rush != null and f.rush.tgt != null and not _rush_pin[k]:   # a long rush has no door: his pane is already at the arrival
			var rem: float = f.rush.end - S.T
			if rem <= CamParams.SLAM_WINDOW and rem >= -DT:
				_slam_slot = k
				_slam_sep0 = sep
				_slam_last_rem = rem
				return true
	return false


func _slam_run(S: SimState) -> void:
	var f = S.fighters[_slam_slot]
	var window: float = CamParams.SLAM_WINDOW
	var slam_time: float = CamParams.SLAM_TIME_REDUCED if reduced_motion else CamParams.SLAM_TIME   # reduced motion: a near-cut
	var rem: float = _slam_last_rem
	var alive: bool = f.rush != null and f.rush.tgt != null
	if alive:
		rem = f.rush.end - S.T
		_slam_last_rem = rem
	elif _slam_last_rem > 2.0 * DT + 0.0001:
		# Feint or cancel: back to two panes.
		_slam_slot = -1
		e_target = 0.0
		return
	else:
		rem = 0.0   # the rush ended on contact this tick
	if rem > slam_time:
		var pr: float = clampf(1.0 - (rem - slam_time) / maxf(window - slam_time, 0.001), 0.0, 1.0)
		sep = move_toward(sep, 1.0 - CamParams.SLAM_LEAN * pr, DT / 0.3)
		_slam_sep0 = sep
		return
	var p: float = clampf(1.0 - rem / slam_time, 0.0, 1.0)
	e_slot = _slam_slot
	sliver = 0.0
	e = p * p * p
	e_target = 1.0
	sep = lerpf(_slam_sep0, 0.0, smoothstep(0.0, 1.0, p))
	if p >= 1.0 or rem <= 0.0:
		_slam_slot = -1
		sep = 0.0
		e = 0.0
		e_target = 0.0
		e_slot = -1
		split_wanted = false
		_layout_age = 0.0
		_mode_changes.append(time)
		_mode_reasons.append("merge slam")
		# (No divider flash here: the panes are one view on this tick and UI draws a divider only while they are open, so it
		# never reached the screen; the door's sweep, the push and the shake carry the slam. `_flash` stays 0.)
		_slam_done = true


# ---------------------------------------------------------------------------------------------------- orientation

func _phi_target(A, B) -> float:
	var dy: float = B.y - A.y
	return clampf(atan(CamParams.TILT_K * dy / maxf(absf(u), CamParams.TILT_FLOOR)), -CamParams.PHI_MAX, CamParams.PHI_MAX)


## Angle of the divider normal (screen, y down) for a layout: sigma +1 puts slot 1 on the right, and the tilt phi is
## positive when slot 1 is higher. The normal stays in the upper half plane when slot 1 is higher, so the panes swing
## through the vertical on the higher fighter's side.
static func _theta_of(sigma: int, ph: float) -> float:
	if ph >= 0.0:
		return -ph if sigma > 0 else -PI + ph
	return -ph if sigma > 0 else PI + ph


## Whether the pair has passed each other since the layout was set: the held separation says the sides are the other way
## round. The flip waits (for the dwell, for the pair to stop being merge-close, and for the panes to be one view or full
## apart), so a split that opens meanwhile opens with the fighters on the old sides and swings when it can.
func orientation_pending() -> bool:
	return (sigma_u > 0 and u < -CamParams.HYST_M0) or (sigma_u < 0 and u > CamParams.HYST_M0)


func _update_orientation(S: SimState) -> void:
	var A = S.fighters[0]
	var B = S.fighters[1]
	var d: float = SimWrap.sdx(A.x, B.x)
	var delta: float = d - _prev_d
	if delta > SimConst.HALF:
		delta -= SimConst.W
	elif delta < -SimConst.HALF:
		delta += SimConst.W
	_prev_d = d
	u += delta
	var m: float = CamParams.HYST_M * SimConst.W
	if u > SimConst.HALF + m:
		u -= SimConst.W
	elif u < -(SimConst.HALF + m):
		u += SimConst.W
	if swing_t >= 0.0:
		swing_t += DT / _swing_dur
		if swing_t >= 1.0:
			swing_t = -1.0
			sigma_shown = sigma_u
			theta = _theta_of(sigma_shown, phi)
		else:
			var s: float = swing_t * swing_t * swing_t * (swing_t * (swing_t * 6.0 - 15.0) + 10.0)
			theta = lerpf(_swing_th0, _swing_th1, s)
		return
	# The tilt follows the height difference, smoothed, rate limited and with a dead band.
	var target: float = _phi_target(A, B)
	var diff: float = target - phi
	if absf(diff) > CamParams.TILT_DEAD * 0.5:
		var step_: float = diff * (1.0 - exp(-DT / CamParams.TILT_TAU))
		var cap: float = CamParams.TILT_RATE_MAX * DT
		phi += clampf(step_, -cap, cap)
	# The layout flips when the held separation asks for it, at most once a second, never while opening or closing.
	var cand: int = 0
	if sigma_u > 0 and u < -CamParams.HYST_M0:
		cand = -1
	elif sigma_u < 0 and u > CamParams.HYST_M0:
		cand = 1
	# A pair that is close enough to merge again does not swing: the flip waits and is unseen once they are one view.
	var merging: bool = split_wanted and r_now > _r_merge() and swing_t < 0.0
	if cand != 0 and _flip_age >= CamParams.FLIP_DWELL and not merging:
		var hidden: bool = (e >= CamParams.INSTANT_SWAP_E and sliver <= 0.0)
		var full: bool = sep >= 0.999 and _slam_slot < 0
		if (sep <= 0.02 and e <= 0.02) or hidden:
			sigma_u = cand
			sigma_shown = cand
			_flip_age = 0.0
			theta = _theta_of(sigma_shown, phi)
			_cut_now = true   # the divider is all but invisible here: the frame is not interpolated into the new sides
		elif full:
			sigma_u = cand
			_flip_age = 0.0
			_swing_th0 = _theta_of(sigma_shown, phi)
			_swing_th1 = _theta_of(cand, phi)
			_swing_dur = CamParams.T_SWING_REDUCED if reduced_motion else CamParams.T_SWING
			swing_t = 0.0
		else:
			theta = _theta_of(sigma_shown, phi)
			return
	theta = _theta_of(sigma_shown, phi)


# ---------------------------------------------------------------------------------------------------- shots

## A lunge, a zip or a charge begins (Encounter's cue: kind lunge_light, lunge_heavy, charge_light, charge_heavy, and the
## zip's zip_light and zip_heavy; actor, target, amount = the wind-up's ticks, n = the move's ticks).
## - A zip goes out and comes back inside about a second, so the camera holds instead of chasing (docs/camera/lunge-framing.md).
## - A lunge (B0's, one way: he ends 2.5 body heights from the rival and stays) is followed as for any move; the cue only
##   starts the rival's incoming countdown at the wind-up. (Holding the camera through its wind-up was measured: 68 more
##   rush-class jolts in 13 matches, the catch-up when it let go.)
## - A charge is a one-way flight at a capped speed, treated as any rush (the cut-ahead for a long one).
## A lunge or a zip is not a rush to cut ahead for.
func _read_move_cue(S: SimState, ev, kind: String) -> void:
	var la: int = int(_ef(ev, "actor", -1))
	var lt: int = int(_ef(ev, "target", -1))
	if la < 0 or la > 1 or lt < 0 or lt > 1 or la == lt:
		return
	var wind: float = float(_ef(ev, "amount", 0))
	var mv: float = float(_ef(ev, "n", 0))
	if kind.begins_with("charge"):
		# The governor is armed from the cue, not from the speed: the pursuit that follows is at the capped speed (6,000 units a
		# second at most), and the zoom takes 0.35 s to come out; armed at the tell it is out when the flight starts.
		_gov_arm_speed = CamParams.GOV_ARM_SPEED
		_gov_arm_until = time + (wind + mv) * DT + CamParams.GOV_ARM_TAIL
		return   # a charge is a rush as before: a long one is cut ahead for (measured: following it costs 230 jolts in 13 matches)
	if solo_kind != "" or _ov_kind != "" or fold_active or intro_active or _slam_slot >= 0:
		return
	if not kind.begins_with("zip"):
		_wd_slot = la
		_wd_tgt = lt
		_wd_until = time + (wind + 1.0) * DT   # the wind-up and the tick the move starts, so the incoming read has no gap
		_lg_strike = S.T + (wind + mv) * DT
		_nopin_until[la] = time + (wind + mv) * DT + 0.5
		return
	# A zip (zip_light, zip_heavy). In a split (or a pane still holding the screen) nothing is held: the way in is a rush and
	# the slam's door and the lag bound already handle it, and a layout frozen while the pair closes put a fighter on the
	# wrong side of the divider (the sweep's three failures on Z1). The rival's countdown still starts at the tell.
	var total: float = float(_ef(ev, "dur", wind + 2.0 * mv + 20.0))   # ticks, the whole zip with the default exit
	if total <= 0.0:
		total = wind + 2.0 * mv + 20.0   # a cue without it
	_lg_strike = S.T + (wind + mv) * DT
	_nopin_until[la] = time + total * DT + 0.5
	if sep >= 0.5 or e > 0.05:
		_wd_slot = la
		_wd_tgt = lt
		_wd_until = time + (wind + mv + 1.0) * DT
		return
	_lg_slot = la
	_lg_tgt = lt
	_lg_rel = false
	_lg_cap = time + CamParams.ZIP_HOLD_MAX
	_lg_until = minf(time + total * DT + CamParams.ZIP_HOLD_MARGIN, _lg_cap)
	var d: float = SimWrap.sdx(S.fighters[la].x, S.fighters[lt].x)
	_lg_sep = minf(absf(d), SimConst.HALF)
	_lg_mid = S.fighters[la].x + d * 0.5
	var ya: float = S.fighters[la].y
	var yb: float = S.fighters[lt].y
	_lg_box = [minf(-d * 0.5, d * 0.5), maxf(-d * 0.5, d * 0.5), minf(ya, yb), maxf(ya, yb)]
	_lg_f = [0.5 * (float(_lg_box[0]) + float(_lg_box[1])), float(_lg_box[1]) - float(_lg_box[0]), 0.5 * (float(_lg_box[2]) + float(_lg_box[3])), float(_lg_box[3]) - float(_lg_box[2])]
	lunge_holds += 1


## The even mash ends in a double hit (Encounter's C1: the cue comes 8 ticks before the two blows land, n the tick they land,
## x and y the centre; then both slide 6 bh apart). Game Design's ruling (brawl-second-pass.md section 7): a picture-in-picture
## close-up of the two, opening 6 ticks before the contact and closing as they part, that REPLACES the impact push; the main
## view starts pulling back at the contact to hold both slides, takes no push, and keeps half its shake; the close-up is rationed:
## the first of a match, then at most once in 45 s (the rest play in the main view alone, with the same rules).
func _double_hit(S: SimState, ev) -> void:
	var a: int = int(_ef(ev, "actor", -1))
	if a < 0 or a > 1:
		return
	var ahead: float = float(_ef(ev, "amount", 8.0))
	_dbl_start = time
	_dbl_contact = time + ahead * DT
	_dbl_until = _dbl_contact + CamParams.DOUBLE_MAIN_RULES
	if time - _dbl_last_t < CamParams.DOUBLE_RATION:
		return
	_panel_request(S, "double", a)
	if not _pn.is_empty() and String(_pn["kind"]) == "double" and not _pn.has("cx"):
		_dbl_last_t = time
		double_panels += 1
		_pn["cx"] = float(_ef(ev, "x", S.fighters[a].x))
		_pn["cy"] = float(_ef(ev, "y", S.fighters[a].y))
		_pn["pw"] = absf(SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)) + 2.0 * CamParams.PANEL_BODY
		_pn["t"] = -(ahead - float(CamParams.DOUBLE_OPEN_BEFORE)) * DT   # it opens DOUBLE_OPEN_BEFORE ticks before the contact


## Widen the zip's frame by a point (world x counted from the pair's midpoint at the cue).
func _lg_extend(x: float, y: float) -> void:
	var rx: float = SimWrap.sdx(_lg_mid, x)
	_lg_box[0] = minf(float(_lg_box[0]), rx)
	_lg_box[1] = maxf(float(_lg_box[1]), rx)
	_lg_box[2] = minf(float(_lg_box[2]), y)
	_lg_box[3] = maxf(float(_lg_box[3]), y)


## The zip's blow lands: the exit point is known 6 or 10 ticks before he moves. The frame is widened to the whole way out (the
## sampled path with its bow, over or under the rival as the read says), so the zoom and the focus are where the pair will
## be before he goes, and he is neither chased nor cropped at the top of his arc.
func _zip_out(S: SimState, ev) -> void:
	var a: int = int(_ef(ev, "actor", -1))
	if a != _lg_slot or a < 0 or a > 1:
		return
	var f = S.fighters[a]
	var ex: float = float(_ef(ev, "x", f.x))
	var ey: float = float(_ef(ev, "y", f.y))
	var bx: float = SimWrap.sdx(f.x, ex)
	var by: float = ey - f.y
	# From the blow on the frame is what is left of the zip: the rival and the way out (not where he began: a far-side exit
	# ends on the other side, and keeping the start in would zoom the whole pair out for nothing).
	var rv = S.fighters[_lg_tgt]
	_lg_box = [SimWrap.sdx(_lg_mid, rv.x), SimWrap.sdx(_lg_mid, rv.x), rv.y, rv.y]
	# The path: the straight line to the exit, sampled (the bow is a body height or two, a fraction of the screen's height at
	# these zooms, so it is left out of the zoom's box and the sweep checks the bowed way out keeps its margin instead).
	for k in range(0, 9):
		var u: float = float(k) / 8.0
		_lg_extend(SimWrap.wrap(f.x + bx * u), f.y + by * u)
	_lg_extend(ex, ey)
	# the rest of the zip: the ticks he stays in reach after the blow and the way out, then the end cue decides
	var left: float = float(_ef(ev, "dur", 0.0)) + float(_ef(ev, "n", 0.0))
	_lg_until = minf(maxf(_lg_until, time + left * DT + CamParams.ZIP_HOLD_MARGIN), _lg_cap)


## zip_end is the return marker: he is home (or at his exit) after a `done`, and the hold runs 0.4 s more; any other end
## (stopped, outrun, countered, caught, shot, down) ends it at once, since nothing is coming home.
func _zip_end(ev) -> void:
	var a: int = int(_ef(ev, "actor", -1))
	if a != _lg_slot:
		return
	if String(_ef(ev, "text", "")) == "done":
		_lg_until = minf(time + CamParams.LUNGE_HOLD_AFTER, _lg_cap)
	else:
		_lg_end()


## A brawl's centre (DirBrawl.centre: the point midway between the two, the speed the pair moves at, empty when no brawl is
## running; a zip's ticks in reach are a quiet brawl and are the zip hold's), or a test's stand-in.
func _brawl_centre(S: SimState) -> Dictionary:
	if brawl_read.is_valid():
		return brawl_read.call(S)
	var ex = S.dirS.ex
	if ex == null or not DirBrawl.isBrawl(ex) or DirBrawl.quiet(ex):
		return {}
	return DirBrawl.centre(S, ex)


## The scroll governor: how much of its zoom a view that is moving fast gives up so the scenery crosses the screen no faster
## than SCROLL_MAX of the width a tick (SCROLL_MAX_REDUCED under reduced motion or reduced flashing). A charge or a pursuit at
## 6,000 units a second crossed a city at 0.1 of the width a tick, six screens a second, and the façades alternating light and
## dark were Tools' collapse clip's 4.5 flashes a second. The fighters stay at least R_FLOOR (23 px at 720p); a launched body
## is not governed (his launch chase has its own size and anchor).
func _gov_armed() -> float:
	return _gov_arm_speed if time < _gov_arm_until else 0.0


## The speed the body has (units a second): a launched fighter has it from the launch event, ten ticks before he moves (the hit-stop), so the
## zoom is out by the time he goes; the governor's measured speed (the focus's) comes only as he moves.
func _body_speed(f) -> float:
	var sp: float = Vector2(float(f.vx), float(f.vy)).length()
	return sp if sp < 60000.0 else 0.0


## `headroom` scales the limit: the governor aims at 0.9 of the travel budget, so the displayed camera (held to the budget) has a tenth
## of it to catch up with a lag the budget made, and a steady pursuit settles at no lag instead of a slow drift and a cut every half second.
func _scroll_gov(speed: float, z: float, headroom: float = CamParams.GOV_HEADROOM) -> float:
	var lim: float = (CamParams.SCROLL_MAX_REDUCED if (reduced_motion or flash_reduced) else CamParams.SCROLL_MAX) * headroom
	var w: float = speed * DT * z / vw
	if w <= lim:
		return 1.0
	scroll_gov_ticks += 1
	return lim / w


## The one view's focus in a brawl is the brawl's centre, eased (BRAWL_FOCUS_TAU) with its drift as the lead that cancels the
## ease's lag at a steady speed. A strike places its attacker and the pair's middle jumps up to a body height on 0 to 2 ticks of
## 85,000: a camera that took the fighters' midpoint stepped with it. At the brawl's end the focus eases back to the live
## middle (BRAWL_RELEASE), and a brawl's start takes the live middle, so neither is a step.
func _update_brawl_focus(S: SimState) -> void:
	var c: Dictionary = _brawl_centre(S)
	var A = S.fighters[0]
	var B = S.fighters[1]
	var d: float = SimWrap.sdx(A.x, B.x)
	var kb: float = 1.0 - exp(-DT / CamParams.BRAWL_FOCUS_TAU)
	if not c.is_empty():
		if not _bc_on:
			_bcx = SimWrap.wrap(A.x + d * 0.5)
			_bcy = (A.y + B.y) * 0.5
			_bc_on = true
		_bc_rel_t = 0.0
		var tx: float = float(c["x"]) + float(c.get("vx", 0.0)) * CamParams.BRAWL_FOCUS_TAU
		var ty: float = float(c["y"]) + float(c.get("vy", 0.0)) * CamParams.BRAWL_FOCUS_TAU
		_bcx = SimWrap.wrap(_bcx + SimWrap.sdx(_bcx, tx) * kb)
		_bcy += (ty - _bcy) * kb
		brawl_focus_ticks += 1
	elif _bc_on:
		_bc_rel_t += DT
		_bcx = SimWrap.wrap(_bcx + SimWrap.sdx(_bcx, A.x + d * 0.5) * kb)
		_bcy += ((A.y + B.y) * 0.5 - _bcy) * kb
		if _bc_rel_t > CamParams.BRAWL_RELEASE:
			_bc_on = false


## The hold ends: the layout, the incoming read and the rest stop at once, but the frame the camera was holding eases back to
## the live pair (_update_lunge) instead of stepping to it: a hold ended by a catch had stepped the merged camera 0.22 of a
## screen in one tick.
func _lg_end() -> void:
	if _lg_slot >= 0:
		_lg_rel = true
		_lg_rel_t = 0.0
	_lg_slot = -1


## The hold ends at its time, or when anything makes it not a zip out and back: a launch, a knock-down, a drop, a shot.
## While it holds, the frame takes in where they are and the camera follows it eased; after it, the frame eases back.
func _update_lunge(S: SimState) -> void:
	if _lg_slot < 0 and not _lg_rel:
		return
	if _lg_slot >= 0:
		var over: bool = time >= _lg_until or solo_kind != "" or fold_active or intro_active
		for f in S.fighters:
			if f.state == "launched" or f.state == "down" or f.state == "ko" or f.state == "dropped":
				over = true
		if over:
			_lg_end()
	var klg: float = 1.0 - exp(-DT / CamParams.ZIP_FRAME_TAU)
	var tgt: Array = []
	if _lg_slot >= 0:
		for f in S.fighters:
			_lg_extend(f.x, f.y)
		tgt = [0.5 * (float(_lg_box[0]) + float(_lg_box[1])), float(_lg_box[1]) - float(_lg_box[0]), 0.5 * (float(_lg_box[2]) + float(_lg_box[3])), float(_lg_box[3]) - float(_lg_box[2])]
	else:
		var A = S.fighters[0]
		var B = S.fighters[1]
		var d: float = SimWrap.sdx(A.x, B.x)
		tgt = [SimWrap.sdx(_lg_mid, A.x + d * 0.5), absf(d), (A.y + B.y) * 0.5, _pair_dy(A, B)]
		_lg_rel_t += DT
		if _lg_rel_t > CamParams.ZIP_RELEASE:
			_lg_rel = false
			return
	for q in range(4):
		_lg_f[q] = float(_lg_f[q]) + (float(tgt[q]) - float(_lg_f[q])) * klg


## Whether a rush of `ra` at `rt` is long enough, in screens at the rusher pane's zoom, to cut ahead for.
func _rush_far(S: SimState, ra: int, rt: int) -> bool:
	var rf = S.fighters[ra]
	var r_off: float = float(rf.rush.off) if rf.rush != null else 0.0
	var dr: float = absf(SimWrap.sdx(rf.x, S.fighters[rt].x + r_off))   # to the arrival point
	return dr * maxf(_zo[ra], 0.001) >= CamParams.RUSH_CUT_SCREENS * vw


func _rush_pin_now(ra: int) -> void:
	_rush_pin[ra] = true
	rush_cuts += 1
	_cut_now = true
	if reduced_motion:
		_cut_fade = CamParams.REDUCED_CUT_FADE


## The cut ahead of a long rush, RUSH_COMMIT_TICKS after its event, if it is still on and still long.
func _rush_commit(S: SimState) -> void:
	for i in range(2):
		if int(_rush_wait[i]) <= 0:
			continue
		_rush_wait[i] = int(_rush_wait[i]) - 1
		if int(_rush_wait[i]) > 0:
			continue
		var rf = S.fighters[i]
		if rf.rush == null or rf.rush.tgt == null or _rush_pin[i]:
			continue
		var rt: int = 1 - i
		if sep > 0.999 and solo_kind == "" and _ov_kind == "" and not fold_active and not intro_active and _slam_slot < 0 and time >= float(_nopin_until[i]) and _rush_far(S, i, rt):
			_rush_pin_now(i)


func _read_events(S: SimState, events: Array) -> void:
	for ev in events:
		var bt: String = String(_ef(ev, "type", ""))
		if bt == "damage" and int(_ef(ev, "attacker", -1)) >= 0:
			_blow(String(_ef(ev, "kind", "")), int(_ef(ev, "stop", 0)))
		elif bt == "launch":
			_blow("launch", 0)
		if String(_ef(ev, "type", "")) == "cue":
			var mk: String = String(_ef(ev, "kind", ""))
			if mk == "perfect_block":
				_blow("perfect_block", 4)
			if mk == "lunge_light" or mk == "lunge_heavy" or mk == "charge_light" or mk == "charge_heavy" or mk == "zip_light" or mk == "zip_heavy":
				_read_move_cue(S, ev, mk)
			elif mk == "double_hit":
				_double_hit(S, ev)
			elif mk == "zip_out":
				_zip_out(S, ev)
			elif mk == "zip_end":
				_zip_end(ev)
	for ev in events:
		match String(_ef(ev, "type", "")):
			"last_stand_ready":
				# The first brink of a fighter's match: his one free signature is open. Live, so nothing pauses: in one view a
				# 0.7 s cut-in on him (a close-up, then back), in a split a push on his pane; the face cut-in and the line are
				# UI's and Narrative's. Not in reduced motion (the HUD and the face carry it), not over a sim-owned shot.
				var lsa: int = int(_ef(ev, "actor", -1))
				if lsa >= 0 and lsa < 2 and not reduced_motion and not intro_active and solo_kind == "":
					last_stand_shots += 1
					if sep < 0.5 and not fold_active:
						_start_overlay("last_stand", lsa, Vector3.ZERO, CamParams.R_FIGHT, CamParams.R_FINISH, CamParams.LAST_STAND_DUR, false)
					else:
						_push[lsa] = 0.0
			"intro_start":
				intro_active = true
				_in_t = 0
				_in_phase = ""
				_in_stare_t = -1
				_in_clock_t = -1.0
				_pn = {}
			"entrance_fall":
				_intro_fall(S, int(_ef(ev, "actor", -1)), float(_ef(ev, "y", 0.0)), float(_ef(ev, "y1", 0.0)))
			"entrance_land":
				_intro_land(S, int(_ef(ev, "actor", -1)), float(_ef(ev, "r", 0.0)))
			"staredown_start":
				_intro_stare(S, int(float(_ef(ev, "dur", 2.5)) * 60.0 + 0.5))
			"clock_start":
				_intro_clock(S, String(_ef(ev, "kind", "full")))
			"rush":
				# A fighter rushes at the other (Camera: actor, target, arrival tick n). A long one, in a split, would be a
				# whip of a screen or more a tick for the rusher's pane and a door closing on cameras thousands of units
				# apart: the rusher's pane cuts to the arrival point at once and waits there for him (and the other pane
				# gets the incoming read). Short rushes follow as before.
				var ra: int = int(_ef(ev, "actor", -1))
				var rt: int = int(_ef(ev, "target", -1))
				if ra >= 0 and ra < 2 and rt >= 0 and rt < 2 and ra != rt and sep > 0.999 and solo_kind == "" and _ov_kind == "" and not fold_active and not intro_active and _slam_slot < 0 and time >= float(_nopin_until[ra]):
					if _rush_far(S, ra, rt):
						# Not at once: a rush that is knocked off in its first ticks (a blast landing, a parry) made a cut ahead
						# and a cut back two ticks later, a pair of whole-pane changes (Tools' collapse clip, ticks 1168 to 1172).
						# It is made after RUSH_COMMIT_TICKS if the rush is still on.
						if CamParams.RUSH_COMMIT_TICKS > 0:
							_rush_wait[ra] = CamParams.RUSH_COMMIT_TICKS
						else:
							_rush_pin_now(ra)
			"attack":
				# A signature is asked for: its panel waits for the fire beat, the outcome or the beam, whichever comes
				# first, and is made once for it (a clash makes more beams later; a swat and a split make some: none of
				# them is another signature).
				if String(_ef(ev, "kind", "")) == "sig":
					var sa: int = int(_ef(ev, "actor", -1))
					if sa >= 0 and sa < 2:
						_sig_attack_t[sa] = time
						_sig_done[sa] = false
			"cue":
				# Slice 8's beam plays (docs/director/agency-slice-8.md): beam_fire is the fire beat of a signature (the beam
				# then takes 20 ticks to arrive); a swat or a split adds beams to the state in the tick of its cue, and those
				# are the defender's play, not signatures: no panel for them.
				var cue_kind: String = String(_ef(ev, "kind", ""))
				if struggle_framing and not reduced_motion:
					var ctext: String = String(_ef(ev, "text", ""))
					if cue_kind == "beam_struggle":
						_st_t0 = time
						_st_t1 = time + maxf(float(_ef(ev, "n", 0.0)) - float(S.tick), 60.0) * DT
					elif cue_kind == "beam_surge" and not flash_reduced:
						_punch_t = 0.0
						_punch_len = 6.0 * DT
						_punch_amp = CamParams.STRUGGLE_SHARP_PUNCH if ctext == "sharp" else CamParams.STRUGGLE_SURGE_PUNCH
					elif cue_kind == "beam_end" and ctext == "detonate" and _wide_t < 0.0:
						_wide_t = 0.0
						_wide_dur = CamParams.STRUGGLE_DETONATE_WIDE
				if cue_kind == "beam_fire":
					_panel_request(S, "signature", int(_ef(ev, "actor", -1)))
				elif cue_kind == "beam_swat" or cue_kind == "beam_split":
					_derived_beams_t = time
			"beam_outcome":
				_panel_request(S, "signature", int(_ef(ev, "actor", -1)))   # the signature's outcome, 20 ticks after the fire beat in the dynamic profile (deduped against beam_fire)
			"ko":
				_panel_request(S, "ko", int(_ef(ev, "winner", -1)))
			"decisive":
				var dk: String = String(_ef(ev, "kind", ""))
				if dk == "clash" or dk == "beam_clash":
					_panel_request(S, "clash", int(_ef(ev, "winner", -1)))
			"parry":
				var pa: int = int(_ef(ev, "actor", -1))
				if pa >= 0 and pa < 2:
					_parry_t[pa] = time
			"rally_end":
				_panel_request(S, "rally", int(_ef(ev, "ender", -1)))   # the ping-pong's ender (event shape assumed; not in the sim yet)
			"tier_up":
				if not reduced_motion:
					var a: int = int(_ef(ev, "actor", -1))
					if a >= 0 and a < 2 and not (solo_kind == "transform" and solo_slot == a):
						_push[a] = 0.0
			"bounce", "land":
				# World's ground contact (docs/world/ground-contact.md section 4). The first contact of a journey is the
				# impact the human-attacker hold waits for; every bounce gets a small impact push on the pane that has him.
				var ca: int = int(_ef(ev, "actor", -1))
				if ca >= 0 and ca < 2:
					_impact_evt[ca] = true
					if String(_ef(ev, "type", "")) == "bounce" and not reduced_motion and (_hit_t[ca] < 0.0 or _hit_amp[ca] < CamParams.BOUNCE_PUSH):
						_hit_t[ca] = 0.0
						_hit_amp[ca] = CamParams.BOUNCE_PUSH
						_hit_hold[ca] = CamParams.BOUNCE_HOLD
						_bounce_t[ca] = time
						bounce_pushes += 1
			"drop_start":
				# A zipper shot out of his way out falls where the shot put him: nothing to hold for; the ordinary follow
				# (the zoom rate and the lag bound) keeps him on the screen.
				if _lg_slot >= 0 and int(_ef(ev, "actor", -1)) == _lg_slot:
					_lg_end()
			"journey_end":
				var ja: int = int(_ef(ev, "actor", -1))
				if ja >= 0 and ja < 2:
					_journey_end_evt[ja] = true
			"launch":
				var lb: int = int(_ef(ev, "target", -1))
				if lb >= 0 and lb < 2 and time - float(_parry_t[lb]) <= CamParams.PANEL_RIPOSTE_WINDOW:
					_panel_request(S, "riposte", lb)   # his parry, then his launch: a riposte
				# Encounter's S2 event (actor = the launched fighter): the follow starts on it. The state poll below stays
				# as the fallback for callers that pass no events.
				var la: int = int(_ef(ev, "actor", -1))
				if la >= 0 and la < 2:
					_launch_evt[la] = true
			"launch_depth", "chain_link":
				# B2: the launched fighter (victim) is aimed at a building at (x1, y1): the focus leads toward it.
				var v: int = int(_ef(ev, "victim", -1))
				if v >= 0 and v < 2:
					_aim[v] = Vector2(float(_ef(ev, "x1", 0.0)), float(_ef(ev, "y1", 0.0)))
					_bld_evt_t[v] = time
					_stage_set(v, float(_ef(ev, "x", S.fighters[v].x)), float(_ef(ev, "y", S.fighters[v].y)), float(_ef(ev, "x1", 0.0)), float(_ef(ev, "y1", 0.0)))
			"building_hit":
				# B2: an impact push, inside the sim's hold (0.35 s on the first hit, 0.12 s on each further one).
				var hv: int = int(_ef(ev, "victim", -1))
				if hv >= 0 and hv < 2:
					_impact_evt[hv] = true
					_bld_evt_t[hv] = time
					# The building-smash cut: the first hit on a building of some size cuts to a wide, low view of the wall.
					if int(_ef(ev, "link", 1)) <= 1 and float(_ef(ev, "h", 0.0)) >= 300.0 and not (depth_dolly and not reduced_motion):
						var bh: float = float(_ef(ev, "h", 0.0))
						var r_fit: float = clampf(0.7 * CamParams.BODY_H / minf(bh, 2500.0), CamParams.R_FLOOR, CamParams.R_FIGHT)
						_start_overlay("smash", -1, Vector3(float(_ef(ev, "x", 0.0)), float(_ef(ev, "y", 0.0)), float(_ef(ev, "z", 0.0))), r_fit, r_fit * 1.08, CamParams.OV_SMASH_DUR)
				if hv >= 0 and hv < 2 and not reduced_motion:
					var link: int = int(_ef(ev, "link", 1))
					_hit_t[hv] = 0.0
					_hit_amp[hv] = CamParams.HIT_PUSH if link <= 1 else CamParams.HIT_PUSH_LATER
					_hit_hold[hv] = CamParams.HIT_HOLD_FIRST if link <= 1 else CamParams.HIT_HOLD_LATER
					_aim[hv] = null
			"transform":
				# A transformation (I2b): the shot is a close-up on the face, the body, then a wide reveal over the sim's hold.
				var ta: int = int(_ef(ev, "actor", -1))
				var tdur: float = float(_ef(ev, "dur", 0.0))
				var tver: String = String(_ef(ev, "version", ""))
				if tver == "":
					tver = "full" if tdur >= 2.5 else ("short" if tdur >= CamParams.LIVE_STEP_MAX else "live")
				# SimPause (q10 plan) and Game Design's staging (moveset-rules.md 10.8): beats in ticks, full 60 / 30 / 90,
				# short 24 / 18 / 48, live 10 / 14 / 24. Full: a push in on the gather, one hard cut to a low wide angle on
				# the break, a hold on the pose and a pull back to frame both on the settle. Short: half the push, a snap
				# zoom out on the break (no cut), a straight pull back. Live: no shot; a 6-tick punch-in at the break.
				if tver == "live":
					if not reduced_motion:
						_punch_amp = CamParams.LIVE_PUNCH
						_punch_len = CamParams.LIVE_PUNCH_LEN
						_live_punch_at = time + float(CamParams.LIVE_PUNCH_AT) * DT
				elif ta >= 0 and ta < 2 and not fold_active:
					_push[ta] = -1.0   # the tier-up push is part of this shot
					# A shot already running on the other fighter (a launch chase) hands over with a cut: no ease between the two.
					_begin_solo("transform", ta, 3, CamParams.CINE_SLIVER, S, solo_kind != "" and solo_slot != ta)
					if solo_kind == "transform" and solo_slot == ta:
						_solo_dur = tdur
						_tf_ver = tver
						_tf_phase = "gather"
						_tf_g = 60 if tver == "full" else 24
						_tf_b = 30 if tver == "full" else 18
						_tf_s = 90 if tver == "full" else 48
			"pause_start":
				# A pausing set piece the sim runs (SimPause): the world change, the planet giving way, the time cap. The
				# transformation's shot comes from its own `transform` event. These get a slow pull-out of the shared view.
				var pk: String = String(_ef(ev, "kind", ""))
				if pk != "transform" and not reduced_motion:
					_wide_t = 0.0
					_wide_dur = maxf(float(_ef(ev, "dur", 0.0)), 0.5)
			"pause_end":
				if _wide_t >= 0.0 and _wide_t < _wide_dur:
					_wide_dur = _wide_t
			"finisher_start":
				# A finisher: the fighters are in contact and locked by the sim for `dur`; cut to the loser and dolly in.
				var ft: int = int(_ef(ev, "target", -1))
				_panel_request(S, "finisher", int(_ef(ev, "actor", -1)))
				if ft >= 0 and ft < 2 and not fold_active:
					_begin_solo("finisher", ft, 4, 0.0, S, true)
					if solo_kind == "finisher" and solo_slot == ft:
						_solo_dur = float(_ef(ev, "dur", 0.0))
			"region_broken":
				# A crippling moment: a quick cut to a close-up on the fighter who was broken.
				var ra: int = int(_ef(ev, "actor", -1))
				if ra >= 0 and ra < 2:
					_start_overlay("cripple", ra, Vector3.ZERO, CamParams.R_FIGHT, CamParams.R_FINISH, CamParams.OV_CRIPPLE_DUR)
					_panel_request(S, "crippling", ra)
			"cinematic_start":
				var kd: String = String(_ef(ev, "kind", ""))
				if kd == "transformation" or kd == "revision":
					_begin_solo("transform", int(_ef(ev, "actor", -1)), 3, CamParams.CINE_SLIVER)
					_solo_dur = float(_ef(ev, "dur", 0.0))
			"cinematic_end":
				if solo_kind == "transform":
					_end_solo(S)
			"fold_start":
				fold_active = true
				_fold = Vector3(float(_ef(ev, "x", 0.0)), float(_ef(ev, "y", 0.0)), float(_ef(ev, "r", 1.0)))
				_begin_solo_clear()
			"unfold":
				fold_active = false


## An event field from an FxEvent or a Dictionary.
static func _ef(ev, k: String, d):
	if ev is Dictionary:
		return ev.get(k, d)
	var v = ev.get(k)
	return d if v == null else v


## Each pane's shake from the tick's shake events {k, x} (Controls' shake pass, docs/controls/shake-pass.md): an event
## reaches a pane scaled by clamp(1 - d / 4000, 0.35, 1), d being the wrapped distance from the pane's view centre; with
## two panes the one farther from the event gets 35% of that. The amount decays as the fx consumer's does, 0.02 per
## second, and holds through a hit-stop freeze (the tick event's `frozen`).
func _update_shake(events: Array) -> void:
	var dt: float = DT
	var frozen: bool = false
	for ev in events:
		match String(_ef(ev, "type", "")):
			"shake":
				var k: float = float(_ef(ev, "k", 0.0))
				if time >= _dbl_start and time < _dbl_until:
					k *= 0.5   # the double hit: the main view keeps half its usual shake
				var x: float = float(_ef(ev, "x", _cur.cam_x[0]))
				var f: Array = [0.0, 0.0]
				for i in range(2):
					f[i] = clampf(1.0 - absf(SimWrap.sdx(_cur.cam_x[i], x)) / CamParams.SHAKE_FALLOFF, CamParams.SHAKE_FAR, 1.0)
				if sep > 0.5:
					var near: int = 0 if absf(SimWrap.sdx(_cur.cam_x[0], x)) <= absf(SimWrap.sdx(_cur.cam_x[1], x)) else 1
					f[1 - near] *= CamParams.SHAKE_FAR
				for i in range(2):
					_shk[i] = maxf(_shk[i], k * f[i])
			"tick":
				dt = float(_ef(ev, "dt", DT))
				frozen = bool(_ef(ev, "frozen", false))
	if not frozen:
		var d: float = pow(CamParams.SHAKE_DECAY, dt)
		_shk[0] *= d
		_shk[1] *= d


func _begin_solo_clear() -> void:
	solo_kind = ""
	solo_slot = -1
	solo_prio = 0
	solo_target = 0.0
	e_target = 0.0
	e_hold = false
	_slam_slot = -1


func _begin_solo(kind: String, slot: int, prio: int, sl: float, S: SimState = null, cut_in: bool = false) -> void:
	if slot < 0 or slot > 1 or fold_active:
		return
	if solo_kind != "" and prio < solo_prio:
		return
	# A shot that takes the screen from another fighter's pane while that pane still holds it (a launch chase ending
	# has e_hold keeping its pane up for the ease back; a transformation then begins on the other fighter) hands over
	# with a cut: easing from one fighter's pane to the other's moved the divider 0.4 of the width in a tick.
	if not cut_in and S != null and e > 0.02 and e_slot >= 0 and e_slot != slot:
		cut_in = true
		if reduced_motion:
			_cut_fade = CamParams.REDUCED_CUT_FADE   # a cut is a dissolve in reduced motion
	solo_kind = kind
	solo_slot = slot
	solo_prio = prio
	solo_t = 0.0
	_tf_phase = ""
	_tf_ver = ""
	_tf_calm = false
	_shot_pitch = 0.0
	solo_phase = "follow"
	_solo_dur = 0.0
	solo_target = 1.0
	e_target = 1.0
	e_slot = slot
	sliver = sl
	e_hold = false
	_slam_slot = -1
	_launch_anchor_x = 0.5
	_launch_anchor_y = 0.62
	# A launch out of the one view takes the screen at once, from where the fighter is in that view: the same zoom, the
	# same screen position, then it eases to the chase size and the trailing anchor. No ramp in which he can be lost.
	if cut_in and S != null:
		# A cut to the shot: the pane takes the screen at once, on the fighter, at the shot's first size.
		solo_w = 1.0
		e = 1.0
		_snap_focus(S, slot)
		_zo[slot] = _own_zoom_target(S, slot)
		_cut_now = true
	elif (kind == "launch" or kind == "hold") and S != null and sep < 0.5:
		var lf = S.fighters[slot]
		solo_w = 1.0
		var pi: int = slot if (_cur != null and _cur.shows(slot)) else 0
		if _cur != null and _cur.shows(pi):
			# From what is on the screen: the zoom of the pane that draws him and where he is in it (at any separation, pitch
			# and depth; the flat merged formula put him 0.2 of the width off at 49 degrees).
			_zo[slot] = _cur.cam_z[pi]
			var sp: Vector2 = _cur.screen_pos(pi, lf.x, lf.y + CamParams.CHEST, float(lf.z))
			_launch_anchor_x = clampf(sp.x / vw, 0.2, 0.8)
			_launch_anchor_y = clampf(sp.y / vh, 0.2, 0.85)
		else:
			_zo[slot] = _mz
			_launch_anchor_x = clampf(0.5 + SimWrap.sdx(_mx, lf.x) * _mz / vw, 0.2, 0.8)
			_launch_anchor_y = clampf(CamParams.PLANE_Y - (lf.y + CamParams.CHEST - _my) * _mz / vh, 0.2, 0.85)


## The shot's end: the layout the fighters need now, chosen at once (no dwell).
func _end_solo(S: SimState) -> void:
	var rm: float = _r_merge()
	if solo_kind == "":
		return
	var solo_kind_ended: String = solo_kind
	solo_kind = ""
	_tf_phase = ""
	_tf_ver = ""
	_tf_calm = false
	_shot_pitch = 0.0
	solo_prio = 0
	solo_phase = ""
	solo_target = 0.0
	if r_now >= rm:
		_set_split(false, "%s ended" % solo_kind_ended)
		e_hold = true
		e_target = 1.0
	else:
		if solo_w >= 0.99 and sep < 0.5:
			sep = 1.0
			e = maxf(e, 1.0)
		_set_split(true, "%s ended" % solo_kind_ended)
		e_hold = false
		e_target = 0.0
	_below_t = 0.0
	_above_t = 0.0
	_layout_age = 0.0
	_solo_decisions.append(time)


func _update_solo(S: SimState) -> void:
	# Polling the sim for launches until Encounter's launch event exists (S2).
	for i in range(2):
		var f = S.fighters[i]
		if f.state == "launched" and (_prev_state[i] != "launched" or _launch_evt[i]):
			var sp: float = sqrt(f.vx * f.vx + f.vy * f.vy)
			if sp >= CamParams.LAUNCH_MIN_SPEED and not fold_active:
				var lmode: String = _launch_mode(S, i)
				if lmode == "hold":
					_launch_victim = i
				elif lmode == "split":
					chase_slot = i
					_chase_land_t = 0.0
				elif solo_kind == "launch" and solo_slot == i:
					solo_phase = "follow"
					solo_t = 0.0
				elif solo_kind == "":
					_begin_solo("launch", i, 2, 0.0, S)
	_launch_evt = [false, false]
	if _launch_victim >= 0 and S.fighters[_launch_victim].state != "launched" and solo_kind != "hold" and solo_kind != "cut":
		_launch_victim = -1
	if chase_slot >= 0:
		if S.fighters[chase_slot].state != "launched":
			_chase_land_t += DT
			if _chase_land_t > CamParams.LAND_HOLD:
				chase_slot = -1
		else:
			_chase_land_t = 0.0
	for ai in range(2):
		if _aim[ai] != null and S.fighters[ai].state != "launched":
			_aim[ai] = null
	if S.game.ko != null and solo_kind != "ko" and solo_kind != "wreck" and not fold_active:
		var loser: int = 0 if S.fighters[0] == S.game.ko else 1
		_begin_solo("ko", loser, 4, 0.0)
	if solo_kind == "ko" and S.game.ko != null and S.game.koT >= CamParams.WRECK_AT:
		# After the loser's close-up: the winner, small, with the match's damage round him.
		var winner: int = 1 if S.fighters[0] == S.game.ko else 0
		_wreck_scan(S, winner)
		_begin_solo("wreck", winner, 4, 0.0, S, not reduced_motion)
	if (solo_kind == "ko" or solo_kind == "wreck") and S.game.ko == null:
		_end_solo(S)
	if solo_kind == "":
		return
	solo_t += DT
	var f = S.fighters[solo_slot]
	match solo_kind:
		"launch":
			if solo_phase == "follow":
				if f.state != "launched" or _journey_end_evt[solo_slot]:
					solo_phase = "land"
					_land_t = 0.0
					if reduced_motion:
						_snap_focus(S, solo_slot)
				elif solo_t >= CamParams.MAX_FOLLOW:
					_end_solo(S)
			elif solo_phase == "land":
				_land_t += DT
				if f.state == "launched":
					solo_phase = "follow"
					solo_t = 0.0
				elif _land_t >= CamParams.LAND_HOLD and f.slide <= 0.0 and not _lh_catching(S, solo_slot):
					_end_solo(S)
		"hold":
			# On the attacker until the impact (a building hit, or the landing, or the cap), then the cut to the victim.
			var v: int = _launch_victim
			if v < 0 or _impact_evt[v] or S.fighters[v].state != "launched" or solo_t >= CamParams.HOLD_MAX:
				if v >= 0:
					_start_cut(S, v)
				else:
					_end_solo(S)
		"cut":
			if solo_t >= CamParams.CUT_SHOT:
				_launch_victim = -1
				_end_solo(S)
		"transform":
			_transform_beats(S)
			if solo_kind == "transform" and _solo_dur > 0.0 and solo_t >= _solo_dur + 0.05:
				_end_solo(S)
		"finisher":
			if _solo_dur > 0.0 and solo_t >= _solo_dur + 0.05:
				_end_solo(S)
		"ko", "wreck":
			pass


## A panel cut-in (Orb's pick B): a slanted close-up strip over the live view, drawn by the compositor from an inset
## pane. The main view is untouched: no cut, nothing pauses. The peaks (a signature's fire beat, a finisher, a crippling
## blow, the KO) always play; the hits the player earned (a clash won, a riposte that launches, a ping-pong's ender) share
## one panel per PANEL_EARNED_GAP seconds. A stronger panel replaces a running weaker one; an equal or weaker one is
## dropped. `slot` is whose close-up it is: the attacker for a signature, a finisher and an earned hit, the broken
## fighter for a crippling blow, the winner for the KO (the main view is on the loser then).
func _panel_request(S: SimState, kind: String, slot: int) -> void:
	if panel_mode == "off" or slot < 0 or slot > 1 or fold_active or solo_kind == "transform" or intro_active:
		return
	if flash_reduced and panel_flash_off.has(kind):
		return
	var k: Dictionary = CamParams.PANEL_KINDS[kind]
	if kind == "signature":
		# One panel for each signature asked for, from whichever of the fire beat's cue, the outcome event and the new
		# beam comes first, within SIG_WINDOW of the request.
		if bool(_sig_done[slot]) or time - float(_sig_attack_t[slot]) > CamParams.SIG_WINDOW:
			return
		_sig_done[slot] = true
	if bool(k["earned"]) and time - _pn_earned_t < CamParams.PANEL_EARNED_GAP:
		panels_dropped += 1
		return
	if not _pn.is_empty() and int(k["prio"]) <= int(_pn["prio"]):
		panels_dropped += 1
		return
	var band: int = _panel_band(S)
	if band < 0:
		panels_dropped += 1
		return
	_pn = {"kind": kind, "slot": slot, "prio": int(k["prio"]), "dur": float(k["dur"]), "t": 0.0, "band": band}
	if bool(k["earned"]):
		_pn_earned_t = time
	panels += 1
	panel_log.append([time, kind, slot])


func _update_panel(S: SimState) -> void:
	# A signature's fire beat is a new beam in the state (the beam_outcome event only exists in the dynamic profile).
	var live: Dictionary = {}
	for b in S.beams:
		var id: int = b.get_instance_id()
		live[id] = true
		if not _beams_seen.has(id):
			if time - _derived_beams_t > DT * 1.5:   # not a beam the swat or the split just made
				_panel_request(S, "signature", S.fighters.find(b.A))
	_beams_seen = live
	if _pn.is_empty():
		return
	_pn["t"] = float(_pn["t"]) + DT
	if float(_pn["t"]) >= float(_pn["dur"]):
		_pn = {}


func _panel_rect(band: int) -> Rect2:
	var pw: float = vw * CamParams.PANEL_W
	var ph: float = vh * CamParams.PANEL_H
	var wb: float = pw + ph * CamParams.PANEL_SLANT
	var y0: float = maxf(vh * CamParams.PANEL_TOP_Y, panel_floor) if band == 0 else vh * CamParams.PANEL_BOTTOM_Y
	return Rect2((vw - wb) * 0.5, y0, wb, ph)


## The top band holds the strip only where UI's HUD leaves it the whole band (the plates, the toll chip and the pause
## button end above it); on phones and small windows they reach into it and the bottom band is the usual one.
func _top_band_fits() -> bool:
	return maxf(vh * CamParams.PANEL_TOP_Y, panel_floor) + vh * CamParams.PANEL_H <= vh * (CamParams.PANEL_TOP_Y + CamParams.PANEL_H) + 0.5


## The band the strip takes: the top one, or the bottom one when a fighter is in the top one; -1 when both are taken.
## Judged on the last frame's screen positions of both fighters (head to feet, a little wider than the body).
func _panel_band(S: SimState) -> int:
	if _cur == null:
		return 0
	for band in [0, 1]:
		if band == 0 and not _top_band_fits():
			continue
		var r: Rect2 = _panel_rect(band).grow(8.0)
		var free: bool = true
		for k in range(2):
			var f = S.fighters[k]
			var pi: int = k if _cur.shows(k) else 0
			var feet: Vector2 = _cur.screen_pos(pi, f.x, f.y, float(f.z))
			var head: Vector2 = _cur.screen_pos(pi, f.x, f.y + CamParams.BODY_H, float(f.z))
			var fh: float = absf(feet.y - head.y)
			if Rect2(feet.x - fh * 0.4, minf(head.y, feet.y), fh * 0.8, fh).intersects(r):
				free = false
		if free:
			return band
	return -1


## The panel in the frame: where the strip is and the inset's camera, in the inset viewport's own pixels. The camera
## frames the subject's upper body, with room to look into.
func _panel_frame(S: SimState) -> Dictionary:
	if _pn.is_empty():
		return {}
	var still: bool = reduced_motion or panel_mode == "still"
	var t: float = float(_pn["t"])
	var dur: float = float(_pn["dur"])
	var open: float = 1.0
	if not still:
		var t_open: float = CamParams.PANEL_OPEN_REDUCED if flash_reduced else CamParams.PANEL_OPEN   # under Reduce flashing the wipe takes 0.3 s: an area step eased
		var t_close: float = CamParams.PANEL_CLOSE_REDUCED if flash_reduced else CamParams.PANEL_CLOSE
		open = smoothstep(0.0, t_open, t) * (1.0 - smoothstep(dur - t_close, dur, t))
	var slot: int = int(_pn["slot"])
	var rect: Rect2 = _panel_rect(int(_pn["band"]))
	var ph: float = rect.size.y
	var f = S.fighters[slot]
	var z: float = CamParams.PANEL_FILL * ph / CamParams.PANEL_BODY
	if not still:
		z *= 1.0 + CamParams.PANEL_PUSH * clampf(t / dur, 0.0, 1.0)
	var w: float = -float(f.z)
	if absf(w) > 1.0:
		var den: float = 1.0 / z - w / (CamParams.K_FACTOR * ph)
		if den > 1e-6:
			z = 1.0 / den
	var fx: float = 0.40 if f.face >= 0.0 else 0.60   # room in front of him
	if String(_pn["kind"]) == "double" and _pn.has("cx"):
		# the pair at the contact: both bodies across the strip, at the point where the blows land, a small push of its own
		var zp: float = minf(CamParams.PANEL_FILL * ph / CamParams.PANEL_BODY, 0.92 * rect.size.x / maxf(float(_pn["pw"]), 1.0))
		if not still:
			zp *= 1.0 + CamParams.DOUBLE_PANEL_PUSH * clampf(t / dur, 0.0, 1.0)
		return {
			"kind": "double", "slot": slot, "open": open, "still": still, "band": int(_pn["band"]),
			"rect": rect, "slant": (1.0 if slot == 0 else -1.0) * ph * CamParams.PANEL_SLANT,
			"size": Vector2i(int(ceil(rect.size.x)), int(ceil(ph))),
			"cam_x": SimWrap.wrap(float(_pn["cx"])),
			"cam_y": clampf((float(_pn["cy"]) + CamParams.PANEL_FOCUS) - (ph * CamParams.PLANE_Y - ph * 0.5) / zp, CamParams.CAM_Y_MIN, SimConst.CEILING - CamParams.CAM_Y_TOP),
			"cam_z": zp,
		}
	return {
		"kind": _pn["kind"], "slot": slot, "open": open, "still": still, "band": int(_pn["band"]),
		"rect": rect, "slant": (1.0 if slot == 0 else -1.0) * ph * CamParams.PANEL_SLANT,
		"size": Vector2i(int(ceil(rect.size.x)), int(ceil(ph))),
		"cam_x": SimWrap.wrap(f.x - (fx - 0.5) * rect.size.x / z),
		"cam_y": clampf((f.y + CamParams.PANEL_FOCUS) - (ph * CamParams.PLANE_Y - ph * 0.5) / z, CamParams.CAM_Y_MIN, SimConst.CEILING - CamParams.CAM_Y_TOP),
		"cam_z": z,
	}


## Which side of the winner holds more wreckage: the craters (area times depth, a signature's double), the buildings
## lost (their face area, scaled by how much is gone) and the knockback trenches, inside the part of the screen that side
## will have, nearer counting more. Sets wreck_dir (+1 right, -1 left, 0 when little is in view) and wreck_score.
func _wreck_scan(S: SimState, w: int) -> void:
	var wf = S.fighters[w]
	var zf: float = CamParams.R_WRECK * _m() * vh / CamParams.BODY_H
	var reach: float = CamParams.WRECK_REACH * vw / maxf(zf, 0.01)
	var side: Array = [0.0, 0.0]   # [left, right]
	for c in S.craters:
		var d: float = SimWrap.sdx(wf.x, c.x)
		if absf(d) > reach + c.r:
			continue
		var wt: float = c.r * c.depth * (1.0 + c.special) * (1.0 - 0.5 * minf(1.0, absf(d) / reach))
		side[1 if d >= 0.0 else 0] += wt
	for b in S.buildings:
		if b.maxhp <= 0.0:
			continue
		var lost: float = 1.0 if not b.alive else 1.0 - clampf(b.hp / b.maxhp, 0.0, 1.0)
		if lost < 0.2:
			continue
		var d: float = SimWrap.sdx(wf.x, b.x)
		if absf(d) > reach:
			continue
		side[1 if d >= 0.0 else 0] += lost * b.w * b.h * CamParams.WRECK_BUILDING_W * (1.0 - 0.5 * absf(d) / reach)
	for sl in S.slides:
		var mid: float = SimWrap.wrap((sl.x0 + sl.x1) * 0.5)
		var d: float = SimWrap.sdx(wf.x, mid)
		if absf(d) > reach:
			continue
		side[1 if d >= 0.0 else 0] += sl.depth * absf(sl.x1 - sl.x0) * 0.5
	wreck_score = side[0] + side[1]
	wreck_dir = 0
	if wreck_score >= CamParams.WRECK_MIN and absf(side[1] - side[0]) >= 0.15 * wreck_score:
		wreck_dir = 1 if side[1] > side[0] else -1


## Who follows a launched fighter i: "chase" (a solo shot on him), "hold" (stay with the human attacker, then the impact
## cut) or "split" (a pane chases him, no solo). The hybrid of Orb's pick: one human who launched the opponent holds; one
## human who was launched chases; two humans use the split; no human (the demo) chases.
func _launch_mode(S: SimState, i: int) -> String:
	if launch_follow == "chase":
		return "chase"
	var humans: int = 0
	var h: int = -1
	for k in range(2):
		if _is_human(S, k):
			humans += 1
			h = k
	if launch_follow == "split" or humans >= 2:
		return "split"
	if humans == 1 and i != h:
		# Orb's first playtest (2026-10-16): the camera stayed with the human while the computer flew off, and he returned unseen. The opponent
		# now keeps a pane ("split": both are in the picture for the whole flight); "hold" is the old hybrid, kept as an option.
		if launch_follow == "hold":
			return "hold" if sep < 0.5 else "split"
		return "split"
	return "chase"


## The computer the human launched is kept in a pane for the whole flight, and the launch rule's hold (a frozen frame the body flies out of, one cut
## at the end) does not apply to him: Orb, 2026-10-16, "I felt like I had no idea what they were doing until they rushed back at me". Against
## the computer only; AI against AI (the clips) and two humans are as they were.
func _keeps_in_view(S: SimState, i: int) -> bool:
	if not keep_opponent_in_view or launch_follow == "hold" or launch_follow == "chase":
		return false
	var humans: int = 0
	var h: int = -1
	for k in range(2):
		if _is_human(S, k):
			humans += 1
			h = k
	return humans == 1 and i != h


## The cut to the impact: a hard cut to the launched fighter v at the push-in size, for CUT_SHOT seconds.
func _start_cut(S: SimState, v: int) -> void:
	solo_kind = "cut"
	solo_slot = v
	solo_prio = 2
	solo_t = 0.0
	solo_phase = "cut"
	solo_target = 1.0
	solo_w = 1.0
	e_target = 1.0
	e = 1.0
	e_slot = v
	sliver = 0.0
	_launch_anchor_x = 0.5
	_launch_anchor_y = 0.62
	_snap_focus(S, v)
	_zo[v] = _own_zoom_target(S, v)
	_cut_now = true


## A camera-only cut-in (a building smash, a crippling moment): a hard cut to a fixed or followed view for `dur` seconds,
## then a hard cut back. It runs in one view only, never over a launch hold, a cut or a sim-owned shot, with a cooldown
## and a per-minute cap so cuts stay events (docs/camera/camera-v2.md section 4).
func _start_overlay(kind: String, slot: int, pt: Vector3, r0: float, r1: float, dur: float, rationed: bool = true) -> void:
	if _ov_kind != "" or fold_active or sep >= 0.5 or reduced_motion or intro_active:
		return
	if solo_kind != "" and solo_kind != "launch":
		return
	if rationed and not _ov_times.is_empty() and time - float(_ov_times[-1]) < CamParams.OV_COOLDOWN:
		return
	var recent: int = 0
	for t0 in _ov_times:
		if time - float(t0) < 60.0:
			recent += 1
	if rationed and recent >= CamParams.OV_MAX_PER_MIN:
		return
	_ov_kind = kind
	_ov_t = 0.0
	_ov_dur = dur
	_ov_slot = slot
	_ov_pt = pt
	_ov_r0 = r0
	_ov_r1 = r1
	if rationed:
		_ov_times.append(time)
		if _ov_times.size() > 12:
			_ov_times.pop_front()
		cut_ins += 1
	_cut_now = true


func _overlay_cam(S: SimState) -> Vector3:
	var p: float = clampf(_ov_t / maxf(_ov_dur, 0.01), 0.0, 1.0)
	var r: float = lerpf(_ov_r0, _ov_r1, smoothstep(0.0, 1.0, p)) * _m()
	var z: float = clampf(r * vh / CamParams.BODY_H / cos(deg_to_rad(_pitch_now)), CamParams.ZOOM_MIN, _zcap() * 1.5)
	var fx: float = _ov_pt.x
	var fy: float = _ov_pt.y
	var fz: float = _ov_pt.z
	if _ov_slot >= 0:
		var f = S.fighters[_ov_slot]
		fx = f.x
		fy = f.y + CamParams.CHEST
		fz = float(f.z)
	_ov_focus_z = fz if depth_dolly else 0.0   # a cut-in's camera stands at its subject's depth
	return _cam_at(fx, fy, fz - _ov_focus_z, z, Vector2(vw * 0.5, vh * 0.62))


## The transformation shot's three beats. Full: the break is a hard cut to a low wide angle (the pitch drops, the fighter
## sits low in the frame against the sky), the settle cuts back to the pose and, halfway through, the shot ends and the
## camera pulls back to frame both. Short: the break is a snap zoom out, the settle a straight pull back.
func _transform_beats(S: SimState) -> void:
	if _tf_phase == "":
		return
	var ti: int = int(solo_t / DT + 0.5)
	var ph: String = "gather" if ti < _tf_g else ("break" if ti < _tf_g + _tf_b else "settle")
	if ph != _tf_phase:
		_tf_phase = ph
		# The break's hard cut to a low angle is a whole-frame change (more dark sky: 0.249 to 0.151 mean luminance in Tools' ai 4
		# clip) and the settle's cut back another within half a second. It asks the flash register as the break begins; refused,
		# or under reduced flashing, the break is calm: the same beats, the zoom easing (not snapped) and no cut or low angle.
		if _tf_ver == "full" and ph == "break":
			_tf_calm = flash_reduced or (flash_ask.is_valid() and not bool(flash_ask.call("transform_cut", 1.0, 0.4)))
		if _tf_ver == "full" and _tf_calm:
			pass   # the filters take the zoom to the break's and the settle's size: no cut, no snap
		elif _tf_ver == "full":
			_cut_now = true
			_snap_focus(S, solo_slot)
			_zo[solo_slot] = _own_zoom_target(S, solo_slot)
			_shot_pitch = _break_pitch() if ph == "break" else 0.0
		else:
			_zo[solo_slot] = _own_zoom_target(S, solo_slot)
	if _tf_ver == "full" and ti >= _tf_g + _tf_b + _tf_s / 2:
		_end_solo(S)
	elif _tf_ver == "short" and ti >= _tf_g + _tf_b:
		_end_solo(S)


## The break's pitch: BREAK_PITCH, limited so the camera stays above the ground at the fighter's feet. The camera orbits
## the plane point at the screen's centre at distance K vh / zoom, so with the chest `off` pixels below the centre it is
## CHEST + (off + K vh sin(pitch)) / zoom units above his feet (Rendering's rule, docs/rendering/README.md). The anchor
## is fixed (0.74 vh), so a low zoom setting, which makes `zoom` small, is what pulls the angle back toward 0.
func _break_pitch() -> float:
	return _low_pitch(CamParams.BREAK_PITCH, 0.74)


## The low angle `deg` (negative), limited so the camera stays above the ground at the fighter's feet when his chest is
## at `anchor_y` of the screen height (the rule above).
func _low_pitch(deg: float, anchor_y: float) -> float:
	var z: float = maxf(_zo[solo_slot], 0.01)
	var off: float = vh * (anchor_y - 0.5)
	var lim: float = ((CamParams.BREAK_CAM_MIN_H - CamParams.CHEST) * z - off) / (CamParams.K_FACTOR * vh)
	var total_min: float = rad_to_deg(asin(clampf(lim, -1.0, 1.0)))
	return minf(0.0, maxf(deg, total_min - pitch_deg))


# ---------------------------------------------------------------------------------------------------- the opening

## The sim's intro (docs/architecture/intro-phase.md) in the camera's shots: each fighter falls from the sky (the camera
## falls with him), lands in a crater (a cut to a low, wide angle, a push and a shake), then the staredown (a two-shot
## pushing in, two face cuts before the clock) and the clock (a 3-tick punch-in, then the ordinary framing). A press that
## skips it ends the shot in a 0.08 s fade. Reduced motion: no fall and no faces, no pitch, shake or punch, and each cut
## is a 0.3 s dissolve.
## A safety cut's brightness dip (the compositor darkens the screen by CUT_DIM, fading in over CUT_FADE; a dissolve of
## REDUCED_CUT_FADE in reduced motion). Logged, so the sweep can say how often dips come (Tools' flash analyser, 2026-10-06).
func _cut_dip() -> void:
	_cut_fade = CamParams.REDUCED_CUT_FADE if reduced_motion else CamParams.CUT_FADE
	if not reduced_motion:
		dip_times.append(time)
		if dip_times.size() > 64:
			dip_times.pop_front()
		dips += 1


func _intro_cut(S: SimState, slot: int) -> void:
	_cut_now = true
	intro_cuts += 1
	if reduced_motion:
		_cut_fade = CamParams.REDUCED_CUT_FADE
	if slot >= 0:
		_snap_focus(S, slot)
		_zo[slot] = _own_zoom_target(S, slot)


## A reset in the middle of a composed intro (the window resized or rotated, a page that laid out late, a replay seek):
## the intro's events are not repeated, so the shot is worked out from the sim's state instead. Without this the rig took the
## pair for far apart (one fighter is held 6,000 units up before his fall), opened a split with its divider across the
## screen, and did not know the intro was running (Camera's block of this fault: the black diagonal line in the EP's capture).
## The fighter falling gets the fall shot; one down with the other still held up gets the landing shot; both down is the
## staredown with the ticks left to the clock; both held up (before the first fall) is the one view, no shot yet.
func _intro_adopt(S: SimState) -> void:
	if S.intro == null or int(S.intro.left) <= 0:
		return
	intro_active = true
	_in_t = 0
	var held: Array = [false, false]
	var falling: int = -1
	for i in range(2):
		var f = S.fighters[i]
		if f.state == "intro" or f.state == "waiting":
			var g: float = WorldTerrain.groundY(S, f.x)
			if f.y >= g + SimIntro.fallHeight - 1.0:
				held[i] = true
			elif f.y > g + 4.0:
				falling = i
	# the intro's shots own the screen: not a split chosen from a pair that is far apart because one is up in the sky
	split_wanted = false
	sep = 0.0
	if falling >= 0:
		var fg: float = WorldTerrain.groundY(S, S.fighters[falling].x)
		_intro_fall(S, falling, fg, fg + SimIntro.fallHeight)
	elif held[0] != held[1]:
		var a: int = 1 if held[0] else 0
		var cr: float = 150.0
		for c in S.craters:
			if absf(SimWrap.sdx(c.x, S.fighters[a].x)) < 8.0:
				cr = c.r
		_intro_land(S, a, cr)
	elif not held[0] and not held[1]:
		_intro_stare(S, int(S.intro.left))


func _intro_fall(S: SimState, a: int, ground_y: float, top_y: float) -> void:
	if a < 0 or a > 1:
		return
	intro_active = true
	if reduced_motion:
		# The camera does not fall with him: it waits, level and still, on the spot he will land on, and he drops into frame.
		var f = S.fighters[a]
		_ov_kind = "intro"
		_ov_t = 0.0
		_ov_dur = 5.0
		_ov_slot = -1
		_ov_pt = Vector3(f.x, ground_y + 45.0, float(f.z))
		_ov_r0 = CamParams.INTRO_R_LAND_MIN
		_ov_r1 = CamParams.INTRO_R_LAND_MIN
		_intro_cut(S, -1)
		return
	_in_phase = "fall"
	_in_slot = a
	_in_fall_h = maxf(top_y - ground_y, 1.0)
	_begin_solo("intro", a, 5, 0.0, S, true)
	_shot_pitch = 0.0
	_intro_cut(S, a)


func _intro_land(S: SimState, a: int, crater_r: float) -> void:
	if a < 0 or a > 1:
		return
	intro_active = true
	_in_phase = "land"
	_in_slot = a
	_in_crater_r = crater_r
	if _ov_kind == "intro":
		_ov_kind = ""
	_begin_solo("intro", a, 5, 0.0, S, true)
	_shot_pitch = 0.0
	_zo[a] = _own_zoom_target(S, a)
	_shot_pitch = 0.0 if reduced_motion else _low_pitch(CamParams.INTRO_LAND_PITCH, CamParams.INTRO_LAND_ANCHOR_Y)
	_intro_cut(S, a)
	if not reduced_motion:
		_hit_t[a] = 0.0
		_hit_amp[a] = CamParams.INTRO_LAND_PUSH
		_hit_hold[a] = 0.1
		_shk[a] = maxf(_shk[a], CamParams.INTRO_SHAKE)
		_shk[1 - a] = maxf(_shk[1 - a], CamParams.INTRO_SHAKE * 0.5)


## One view at once: the shot's end normally lets the solo pane keep the screen until the panes are one (e_hold), which
## showed the staredown's two-shot with the last pane's camera for about 24 ticks, one fighter off the screen's edge.
func _force_merged(S: SimState) -> void:
	r_now = _metric(S)
	_end_solo(S)
	_shot_pitch = 0.0
	sep = 0.0
	e = 0.0
	e_target = 0.0
	e_hold = false
	e_slot = -1
	sliver = 0.0
	solo_w = 0.0
	solo_target = 0.0
	split_wanted = false
	_snap_merged(S)


func _intro_to_two_shot(S: SimState) -> void:
	_force_merged(S)
	_in_phase = "stare"
	_intro_cut(S, -1)
	_snap_cameras(S)


func _intro_stare(S: SimState, dur_ticks: int) -> void:
	intro_active = true
	_in_stare_t = 0
	_in_stare_dur = dur_ticks
	_intro_to_two_shot(S)


func _intro_clock(S: SimState, kind: String) -> void:
	if not intro_active:
		return
	intro_active = false
	var was_solo: bool = solo_kind == "intro"
	if was_solo or kind == "skip" or _in_phase != "stare":
		_force_merged(S)
		_snap_cameras(S)
		_cut_now = true
		_cut_dip()
	_in_phase = ""
	if kind == "skip":
		_in_stare_t = -1
		_in_clock_t = -1.0
		return
	_in_clock_t = 0.0
	if not reduced_motion:
		_punch_amp = CamParams.INTRO_BELL
		_punch_len = CamParams.INTRO_BELL_LEN
		_live_punch_at = time


## The two-shot's push, easing out after the clock.
func _intro_mult() -> float:
	if _in_stare_t < 0 or reduced_motion:
		return 1.0
	var p: float = smoothstep(0.0, 1.0, clampf(float(_in_stare_t) / maxf(float(_in_stare_dur), 1.0), 0.0, 1.0))
	var out: float = 1.0 if _in_clock_t < 0.0 else 1.0 - smoothstep(0.0, CamParams.INTRO_EASE_OUT, _in_clock_t)
	return 1.0 + CamParams.INTRO_STARE_PUSH * p * out


func _update_intro(S: SimState) -> void:
	if intro_active:
		_in_t += 1
	if _in_clock_t >= 0.0:
		_in_clock_t += DT
		if _in_clock_t > CamParams.INTRO_EASE_OUT:
			_in_clock_t = -1.0
			_in_stare_t = -1
	if not intro_active or _in_stare_t < 0:
		return
	_in_stare_t += 1
	if not CamParams.INTRO_FACES or reduced_motion or _in_stare_dur < CamParams.INTRO_FACES_MIN:
		return
	var left: int = _in_stare_dur - _in_stare_t
	if _in_phase == "stare" and left == CamParams.INTRO_FACE_LEAD:
		_in_phase = "face"
		_in_slot = 0
		_begin_solo("intro", 0, 5, 0.0, S, true)
		_shot_pitch = 0.0
		_intro_cut(S, 0)
	elif _in_phase == "face" and _in_slot == 0 and left == CamParams.INTRO_FACE_LEAD - CamParams.INTRO_FACE_TICKS:
		_in_slot = 1
		_begin_solo("intro", 1, 5, 0.0, S, true)
		_intro_cut(S, 1)
	elif _in_phase == "face" and _in_slot == 1 and left == CamParams.INTRO_FACE_LEAD - 2 * CamParams.INTRO_FACE_TICKS:
		_intro_to_two_shot(S)


func _punch_mult() -> float:
	return _punch_only() * _blow_mult()


func _punch_only() -> float:
	if _punch_t < 0.0:
		return 1.0
	return 1.0 + _punch_amp * (1.0 - absf(2.0 * _punch_t / _punch_len - 1.0))


## The blow push now: up over BLOW_UP, held for the blow's hit-stop, back over BLOW_DOWN.
func _blow_mult() -> float:
	if _bp_t < 0.0:
		return 1.0
	return 1.0 + _bp_amp * (smoothstep(0.0, CamParams.BLOW_UP, _bp_t) - smoothstep(CamParams.BLOW_UP + _bp_hold, CamParams.BLOW_UP + _bp_hold + CamParams.BLOW_DOWN, _bp_t))


## A landed blow of this kind (a key of CamParams.BLOW_PUSH) and its hit-stop in ticks: starts a push when it is bigger than what is left of the one running.
func _blow(kind: String, stop_ticks: int) -> void:
	if not blow_push or reduced_motion or intro_active or not CamParams.BLOW_PUSH.has(kind):
		return
	var amp: float = float(CamParams.BLOW_PUSH[kind])
	if amp <= _blow_mult() - 1.0:
		return
	_bp_amp = amp
	_bp_t = 0.0
	_bp_hold = float(clampi(stop_ticks, 0, 12)) * DT
	blows += 1


func _wide_mult() -> float:
	if _wide_t < 0.0:
		return 1.0
	var a: float = smoothstep(0.0, CamParams.WIDE_IN, _wide_t)
	var b: float = smoothstep(_wide_dur, _wide_dur + CamParams.WIDE_IN, _wide_t)
	return lerpf(1.0, CamParams.WIDE_PULL, a - b)


func _update_pushes() -> void:
	if _bp_t >= 0.0:
		_bp_t += DT
		if _bp_t > CamParams.BLOW_UP + _bp_hold + CamParams.BLOW_DOWN:
			_bp_t = -1.0
	if _live_punch_at >= 0.0 and time >= _live_punch_at:
		_live_punch_at = -1.0
		_punch_t = 0.0
	if _punch_t >= 0.0:
		_punch_t += DT
		if _punch_t > _punch_len:
			_punch_t = -1.0
	if _wide_t >= 0.0:
		_wide_t += DT
		if _wide_t > _wide_dur + CamParams.WIDE_IN:
			_wide_t = -1.0
	if _ov_kind != "":
		_ov_t += DT
		if _ov_t >= _ov_dur:
			_ov_kind = ""
			_cut_now = true
			_oz_valid = false   # the cut back is a cut: the drawn zoom does not ease down from the close-up (a fighter 1,700 units away was off the screen for 0.3 s while it did)
	for i in range(2):
		if _hit_t[i] >= 0.0:
			_hit_t[i] += DT
			if _hit_t[i] > maxf(CamParams.HIT_UP, _hit_hold[i]) + CamParams.HIT_DOWN:
				_hit_t[i] = -1.0
		if _push[i] >= 0.0:
			_push[i] += DT
			if _push[i] > CamParams.TIER_PUSH_IN + CamParams.TIER_PUSH_HOLD + CamParams.TIER_PUSH_OUT:
				_push[i] = -1.0


func _hit_mult(i: int) -> float:
	var t: float = _hit_t[i]
	if t < 0.0:
		return 1.0
	var end: float = maxf(CamParams.HIT_UP, _hit_hold[i])
	return 1.0 + _hit_amp[i] * (smoothstep(0.0, CamParams.HIT_UP, t) - smoothstep(end, end + CamParams.HIT_DOWN, t))


func _push_mult(i: int) -> float:
	var t: float = _push[i]
	if t < 0.0:
		return 1.0
	var a: float = smoothstep(0.0, CamParams.TIER_PUSH_IN, t)
	var b: float = smoothstep(CamParams.TIER_PUSH_IN + CamParams.TIER_PUSH_HOLD, CamParams.TIER_PUSH_IN + CamParams.TIER_PUSH_HOLD + CamParams.TIER_PUSH_OUT, t)
	return 1.0 + CamParams.TIER_PUSH * (a - b)


# ---------------------------------------------------------------------------------------------------- layout

func _update_layout() -> void:
	var slam_active: bool = _slam_slot >= 0
	if slam_active:
		pass   # _slam_run drives sep and e; it needs S, so it is called from _update_cameras' caller below
	else:
		var target: float = 1.0 if split_wanted else 0.0
		if fold_active:
			target = 0.0
		# A split that opens because a fighter has left the shared view, or because one was knocked away, opens fast: at
		# the normal rate the fighter was off the screen for most of it (0.3 s at 10,000 units a second is 3,000 units).
		var t_open: float = CamParams.T_OPEN_URGENT if (_view_lost or chase_slot >= 0) else CamParams.T_OPEN
		var rate: float = 1.0 / (t_open if target > sep else CamParams.T_CLOSE)
		if reduced_motion:
			rate *= 1.5
		sep = move_toward(sep, target, rate * DT)
		# e follows its target unless a slam owns it.
		var er: float = 1.0 / (CamParams.T_ENGAGE if e_target > e else CamParams.T_REVEAL)
		e = move_toward(e, e_target, er * DT)
		if e_hold and sep <= 0.001:
			e = 0.0
			e_target = 0.0
			e_hold = false
		if e <= 0.0 and e_target <= 0.0 and solo_kind == "":
			e_slot = -1
	var sr: float = 1.0 / (CamParams.T_ENGAGE if solo_target > solo_w else CamParams.T_SETTLE)
	solo_w = move_toward(solo_w, solo_target, sr * DT)
	if solo_w <= 0.0 and solo_target <= 0.0 and solo_kind == "":
		solo_slot = -1 if e <= 0.0 else solo_slot


# ---------------------------------------------------------------------------------------------------- cameras

func _snap_focus(S: SimState, i: int) -> void:
	var f = S.fighters[i]
	_fx[i] = f.x
	_fy[i] = f.y + CamParams.CHEST
	_ppx[i] = f.x
	_ppy[i] = f.y


func _snap_cameras(S: SimState) -> void:
	_oz_valid = false
	_od_valid = false
	_snap_focus_depth(S)
	for i in range(2):
		_snap_focus(S, i)
		_zo[i] = _own_zoom_target(S, i)
	_snap_merged(S)
	_outputs(S)


## The beam struggle's state this tick (Encounter's tug of war: `S.game.clash.mid`, 0 at the attacker's hands, 1 at the defender's, -1 none): the
## meeting point eased, and whether the struggle framing applies.
func _struggle_tick(S: SimState) -> void:
	var cl = S.game.clash
	var mv = null
	if struggle_framing and not reduced_motion and cl != null:
		mv = cl.get("mid")   # (Clash.mid is Simulation's slice: absent on a tree without it)
	var on: bool = mv != null and float(mv) >= 0.0
	if on:
		var m: float = float(mv)
		if not _st_on:
			_st_mid = m
			if _st_t1 <= time:
				_st_t0 = time
				_st_t1 = time + 3.0
		else:
			_st_mid += (m - _st_mid) * (1.0 - exp(-DT / CamParams.STRUGGLE_MID_TAU))
	_st_on = on
	if on:
		_st_a = maxi(0, S.fighters.find(cl.A))
		_st_d = maxi(0, S.fighters.find(cl.D))
	_st_w = move_toward(_st_w, 1.0 if on else 0.0, DT / CamParams.STRUGGLE_FADE)


func _merged_target(S: SimState) -> Vector3:
	if fold_active:
		var fit: float = minf(vw, vh) / (CamParams.FOLD_FIT * maxf(_fold.z, 1.0))
		return Vector3(_fold.x, _fold.y, clampf(fit, CamParams.ZOOM_MIN, _zcap()))
	var A = S.fighters[0]
	var B = S.fighters[1]
	var d: float = SimWrap.sdx(A.x, B.x)
	var mx: float = A.x + d * 0.5
	var my: float = clampf((A.y + B.y) * 0.5 + 40.0, CamParams.CAM_Y_MIN, SimConst.CEILING - CamParams.CAM_Y_TOP)
	var ahead: float = minf(SimConst.HALF, absf(d) + maxf(0.0, _sep_rate) * CamParams.ZOOM_OUT_LOOKAHEAD)
	var dy_pair: float = _pair_dy(A, B)
	var y_mid: float = (A.y + B.y) * 0.5
	if _bc_on and _lg_slot < 0 and not _lg_rel:
		mx = _bcx
		y_mid = _bcy
		my = clampf(y_mid + 40.0, CamParams.CAM_Y_MIN, SimConst.CEILING - CamParams.CAM_Y_TOP)
	if _lg_slot >= 0 or _lg_rel:
		# A zip out and back: the frame is the box the zip will use (the pair at the cue, widened to the exit and the bow at
		# the blow), so the zoom stays and the focus sits where the pair will be, not where the zipper is.
		ahead = minf(SimConst.HALF, float(_lg_f[1]))
		mx = _lg_mid + float(_lg_f[0])
		dy_pair = maxf(dy_pair, float(_lg_f[3]))
		y_mid = float(_lg_f[2])
		my = clampf(y_mid + 40.0, CamParams.CAM_Y_MIN, SimConst.CEILING - CamParams.CAM_Y_TOP)
	if time >= _dbl_contact - DT and time < _dbl_until:
		ahead = maxf(ahead, CamParams.DOUBLE_SLIDE_SPAN)   # the pull-back starts at the contact, to hold both slides (6 bh each way)
	var many_z: float = 0.0
	_many_marks = []
	if many_framing and S.fighters.size() > 2:
		var ms: Dictionary = _many_set(S, mx, ahead, dy_pair, y_mid)
		mx = float(ms["mx"])
		ahead = float(ms["ahead"])
		dy_pair = float(ms["dy"])
		y_mid = float(ms["y_mid"])
		my = clampf(y_mid + 40.0, CamParams.CAM_Y_MIN, SimConst.CEILING - CamParams.CAM_Y_TOP)
		many_z = CamParams.MANY_PIX_FLOOR / CamParams.BODY_H
	var z: float = zoom_u(vw, vh, ahead, dy_pair, maxf(A.tier, B.tier), _m(), true)
	var mult: float = maxf(_push_mult(0), _push_mult(1)) * _intro_mult()
	if _st_w > 0.0:
		# the struggle: the focus leans toward the meeting point, and the view tightens as the decision nears (all of it eased in and out by _st_w)
		var sw_st: float = smoothstep(0.0, 1.0, _st_w)
		var ca = S.fighters[_st_a]
		var cd = S.fighters[_st_d]
		var meet: float = SimWrap.wrap(ca.x + _st_mid * SimWrap.sdx(ca.x, cd.x))
		var shift: float = CamParams.STRUGGLE_FOCUS * sw_st * SimWrap.sdx(mx, meet)
		# the lean never takes a fighter toward the edge of the one view (a fighter lost off its edge opens the split): both stay inside 0.42 of the width
		var half_free: float = 0.42 * vw / maxf(z * mult, 0.001)
		var d_a: float = SimWrap.sdx(mx, ca.x)
		var d_d: float = SimWrap.sdx(mx, cd.x)
		var lo_s: float = maxf(d_a, d_d) - half_free
		var hi_s: float = minf(d_a, d_d) + half_free
		shift = clampf(shift, lo_s, hi_s) if lo_s <= hi_s else 0.0
		mx = SimWrap.wrap(mx + shift)
		var lean: float = absf(_st_mid - 0.5) * 2.0
		var frac: float = clampf((time - _st_t0) / maxf(_st_t1 - _st_t0, 0.5), 0.0, 1.0)
		var tight: float = CamParams.STRUGGLE_PUSH * smoothstep(0.3, 0.9, lean) + CamParams.STRUGGLE_TIME_PUSH * smoothstep(0.6, 1.0, frac)
		var d_far: float = maxf(absf(SimWrap.sdx(mx, ca.x)), absf(SimWrap.sdx(mx, cd.x)))
		var tight_cap: float = maxf(0.0, 0.44 * vw / maxf(d_far * z * mult, 1.0) - 1.0)   # the tightening leaves both fighters inside 0.44 of the width
		mult *= 1.0 + minf(tight * sw_st * (0.5 if flash_reduced else 1.0), tight_cap)
	if solo_kind == "ko":
		pass
	var pz: float = 1.0 / cos(deg_to_rad(_pitch_now))
	var gov_m: float = 1.0
	if A.state != "launched" and B.state != "launched":
		gov_m = _scroll_gov(maxf(_vsm_m, _gov_armed()), z * pz)   # the picture's scale is the zoom times the pitch's: that is what the scenery crosses at
	_gov_bind_m = gov_m < 0.999
	z = clampf(z * mult * pz * _wide_mult() * gov_m, maxf(CamParams.ZOOM_MIN, maxf(CamParams.R_FLOOR * vh / CamParams.BODY_H, many_z) * pz), _zcap() * pz * (1.0 + CamParams.TIER_PUSH))
	if _pitch_now != 0.0:
		# Put the pair's chest midpoint at 0.7 of the height, as the straight-on camera does: a few Newton steps on cam_y.
		var cwx: float = SimWrap.wrap(mx)
		var chest_y: float = y_mid + CamParams.CHEST
		var zmid: float = (float(A.z) + float(B.z)) * 0.5 - _fzm
		var cy: float = my
		for it in range(3):
			var s0: float = SplitFrame.project(cwx, cy, z, _pitch_now, vw, vh, cwx, chest_y, zmid).y
			var s1: float = SplitFrame.project(cwx, cy + 25.0, z, _pitch_now, vw, vh, cwx, chest_y, zmid).y
			var slope: float = (s1 - s0) / 25.0
			if absf(slope) < 1e-9:
				break
			cy += (vh * CamParams.PLANE_Y - s0) / slope
		my = clampf(cy, CamParams.CAM_Y_MIN, SimConst.CEILING - CamParams.CAM_Y_TOP)
	return Vector3(SimWrap.wrap(mx), my, z)


## The framing set of a match of more than two bodies (docs/camera/one-v-many.md section 3): the principals are the one
## (slot 0), the second principal (slot 1) and the one's partner now (the nearest of the others: a tag hands the fight to a
## guard, and he stands to striking distance). The others, nearest first, count by a weight: 1 while the zoom that fits them
## stays above the principals' pixel floor and MANY_KEEP of the principals' own, falling to 0 across a band of 10% either side of
## that limit, and the weight each body has *moves* (MANY_RATE a tick), so a body that joins or leaves never steps the frame:
## the extents, the focus pull and the span are weighted sums. A body higher than MANY_UP_BH over the principals, or deeper than
## MANY_DEPTH, has no weight (the first is a marker). The focus is the principals' midpoint, pulled toward the set's bounding
## centre by at most MANY_PULL of the width. Returns the target's mx, span (ahead), vertical spread and mid height, and
## fills `_many_marks`.
func _many_set(S: SimState, mx: float, ahead: float, dy: float, y_mid: float) -> Dictionary:
	var one = S.fighters[0]
	var n: int = mini(S.fighters.size(), _many_w.size())
	var near_k: int = 1
	var near_d: float = 1.0e18
	for k in range(1, n):
		var dk: float = absf(SimWrap.sdx(one.x, S.fighters[k].x))
		if dk < near_d:
			near_d = dk
			near_k = k
	var cur_d: float = absf(SimWrap.sdx(one.x, S.fighters[clampi(_many_partner, 1, n - 1)].x))
	if near_d + CamParams.MANY_PARTNER_BH * CamParams.BODY_H < cur_d:
		_many_partner = near_k
	var ps: int = clampi(_many_partner, 1, n - 1)
	var lo: float = 0.0
	var hi: float = 0.0
	var y_lo: float = float(one.y)
	var y_hi: float = float(one.y)
	var r1: float = SimWrap.sdx(one.x, S.fighters[1].x)
	lo = minf(lo, r1)
	hi = maxf(hi, r1)
	y_lo = minf(y_lo, float(S.fighters[1].y))
	y_hi = maxf(y_hi, float(S.fighters[1].y))
	var tier: float = 1.0
	for f in S.fighters:
		tier = maxf(tier, float(f.tier))
	var m: float = _m()
	var rel_mid: float = SimWrap.sdx(one.x, mx)
	var z0: float = zoom_u(vw, vh, maxf(ahead, hi - lo), maxf(dy, y_hi - y_lo), tier, m, false)
	var z_lim: float = minf(maxf(CamParams.MANY_PIX_PRINCIPAL / CamParams.BODY_H, z0 * CamParams.MANY_KEEP), z0)
	var order: Array = []
	if ps >= 2:
		order.append(ps)
	var rest: Array = []
	for k in range(2, n):
		if k != ps:
			rest.append(k)
	rest.sort_custom(func(a, b): return absf(SimWrap.sdx(one.x, S.fighters[a].x) - rel_mid) < absf(SimWrap.sdx(one.x, S.fighters[b].x) - rel_mid))
	order.append_array(rest)
	if ps == 1:
		order.push_front(-1)   # the second principal is already in; his weight stays 1
	var fz: float = (float(S.fighters[0].z) + float(S.fighters[1].z)) * 0.5
	var members: Array = []   # [slot, weight]
	for k in order:
		if k < 0:
			continue
		var g = S.fighters[k]
		var gy: float = float(g.y)
		var rk: float = SimWrap.sdx(one.x, g.x)
		var tgt: float = 0.0
		var side: int = 1 if rk >= rel_mid else -1
		var marked: bool = false
		if gy - maxf(y_hi, float(one.y)) > CamParams.MANY_UP_BH * CamParams.BODY_H:
			marked = true
			side = 0
		elif absf(float(g.z) - fz) > CamParams.MANY_DEPTH:
			tgt = 0.0   # out of the frame for sizing; drawn if he is on the screen
		elif k == ps:
			tgt = 1.0
		else:
			var nlo: float = minf(lo, rk)
			var nhi: float = maxf(hi, rk)
			var zc: float = zoom_u(vw, vh, maxf(ahead, nhi - nlo), maxf(dy, maxf(y_hi, gy) - minf(y_lo, gy)), tier, m, false)
			tgt = smoothstep(CamParams.MANY_JOIN * z_lim, CamParams.MANY_LEAVE * z_lim, zc)
		var w: float = float(_many_w[k])
		w = move_toward(w, tgt, CamParams.MANY_RATE)
		_many_w[k] = w
		if w > 0.0:
			var wlo: float = minf(lo, rk)
			var whi: float = maxf(hi, rk)
			lo = lerpf(lo, wlo, w)
			hi = lerpf(hi, whi, w)
			var wyl: float = minf(y_lo, gy)
			var wyh: float = maxf(y_hi, gy)
			y_lo = lerpf(y_lo, wyl, w)
			y_hi = lerpf(y_hi, wyh, w)
			members.append([k, w])
		if marked or w < 0.5:
			_many_marks.append([k, side])
	var centre: float = (lo + hi) * 0.5
	var pull_max: float = CamParams.MANY_PULL * vw / maxf(_mz, 0.1)
	var pull: float = clampf(centre - rel_mid, -pull_max, pull_max)
	var fx: float = SimWrap.wrap(mx + pull)
	_many_dbg = [snappedf(rel_mid, 1.0), snappedf(centre, 1.0), snappedf(pull, 1.0), _bc_on, snappedf(lo, 1.0), snappedf(hi, 1.0)]
	var rel_f: float = SimWrap.sdx(one.x, fx)
	var half: float = maxf(absf(rel_f), absf(r1 - rel_f))
	for mw in members:
		half = maxf(half, float(mw[1]) * absf(SimWrap.sdx(one.x, S.fighters[int(mw[0])].x) - rel_f))
	return {"mx": fx, "ahead": minf(SimConst.HALF, maxf(ahead, 2.0 * half)), "dy": maxf(dy, y_hi - y_lo), "y_mid": (y_lo + y_hi) * 0.5 if not _bc_on else y_mid}


## A pane's framing set in a match of more than two bodies (docs/camera/one-v-many.md sections 2 and 3): the pane's principal (slot i) and
## the bodies assigned to him: the one's partner and the guards nearer the one go with pane 0; the others with the second principal's pane.
## Each assigned body counts by a weight that moves at MANY_RATE a tick (a join or a leave steps nothing), 1 while the zoom that fits
## him with the others stays within MANY_KEEP of the pane's own size and above the principal's pixel floor. The pane's zoom takes the
## weighted fit (`_many_pzf`), and its focus is pulled toward the set's centre by at most MANY_PANE_PULL of the pane's width
## (`_many_pull`). Run once a tick per pane, only in a split view (a pane is half the width there).
func _many_pane_tick(S: SimState, i: int) -> void:
	_many_pzf[i] = 1.0
	_many_pull[i] = 0.0
	var n: int = mini(S.fighters.size(), 5)
	if not many_framing or n <= 2:
		return
	var pw: Array = _many_pw[i]
	var one = S.fighters[0]
	var f = S.fighters[i]
	var half: float = lerpf(1.0, 0.5, smoothstep(0.0, 1.0, sep))
	var vw_pane: float = vw * half
	var z_base: float = CamParams.R_PANE * _m() * vh / CamParams.BODY_H
	var ps: int = clampi(_many_partner, 1, n - 1)
	var lo: float = 0.0
	var hi: float = 0.0
	var y_lo: float = float(f.y)
	var y_hi: float = float(f.y)
	var tier: float = 1.0
	for g in S.fighters:
		tier = maxf(tier, float(g.tier))
	var z_floor_p: float = CamParams.MANY_PIX_PRINCIPAL / CamParams.BODY_H
	var z_lim: float = maxf(z_floor_p, z_base * CamParams.MANY_KEEP)
	var cands: Array = []
	for k in range(2, n):
		var mine: bool = false
		if i == 0:
			mine = k == ps or absf(SimWrap.sdx(one.x, S.fighters[k].x)) + CamParams.MANY_ASSIGN_BH * CamParams.BODY_H < absf(SimWrap.sdx(S.fighters[1].x, S.fighters[k].x))
		else:
			mine = k != ps and not (absf(SimWrap.sdx(one.x, S.fighters[k].x)) + CamParams.MANY_ASSIGN_BH * CamParams.BODY_H < absf(SimWrap.sdx(S.fighters[1].x, S.fighters[k].x)))
		if mine:
			cands.append(k)
		else:
			pw[k] = move_toward(float(pw[k]), 0.0, CamParams.MANY_RATE)
	cands.sort_custom(func(a, b): return absf(SimWrap.sdx(f.x, S.fighters[a].x)) < absf(SimWrap.sdx(f.x, S.fighters[b].x)))
	for k in cands:
		var g = S.fighters[k]
		var rk: float = SimWrap.sdx(f.x, g.x)
		var gy: float = float(g.y)
		var tgt: float = 0.0
		if gy - float(f.y) > CamParams.MANY_UP_BH * CamParams.BODY_H or absf(float(g.z) - float(f.z)) > CamParams.MANY_DEPTH:
			tgt = 0.0
		else:
			var span_c: float = maxf(hi, rk) - minf(lo, rk)
			var zc: float = zoom_u(vw_pane, vh, span_c, maxf(0.0, maxf(y_hi, gy) - minf(y_lo, gy)), tier, _m(), false)
			var lim_k: float = z_floor_p if (k == ps and i == 0) else z_lim   # the one's partner is held down to the principal's pixel floor, the others to three quarters of the pane's size
			tgt = smoothstep(CamParams.MANY_JOIN * lim_k, CamParams.MANY_LEAVE * lim_k, zc)
		var w: float = move_toward(float(pw[k]), tgt, CamParams.MANY_RATE)
		pw[k] = w
		if w > 0.0:
			lo = lerpf(lo, minf(lo, rk), w)
			hi = lerpf(hi, maxf(hi, rk), w)
			y_lo = lerpf(y_lo, minf(y_lo, gy), w)
			y_hi = lerpf(y_hi, maxf(y_hi, gy), w)
	if lo == 0.0 and hi == 0.0:
		return
	var span: float = hi - lo
	var zfit: float = zoom_u(vw_pane, vh, span, maxf(0.0, y_hi - y_lo), tier, _m(), false)
	_many_pzf[i] = clampf(zfit / maxf(z_base, 0.001), minf(CamParams.MANY_KEEP, z_floor_p / maxf(z_base, 0.001)), 1.0)
	var pull_max: float = CamParams.MANY_PANE_PULL * vw_pane / maxf(z_base * float(_many_pzf[i]), 0.1)
	_many_pull[i] = clampf((lo + hi) * 0.5, -pull_max, pull_max)


func _snap_merged(S: SimState) -> void:
	var t: Vector3 = _merged_target(S)
	_mx = t.x
	_my = t.y
	_mz = t.z
	_pmx = t.x
	_pmy = t.y


func _own_zoom_target(S: SimState, i: int) -> float:
	var f = S.fighters[i]
	var m: float = _m()
	var r: float = CamParams.R_PANE * m
	var pz: float = 1.0 / cos(deg_to_rad(_pitch_now))   # a pitched camera foreshortens a standing fighter by cos(pitch)
	if chase_slot == i:
		r = CamParams.R_LAUNCH * m
	var tier_f: float = 1.0 - CamParams.REF_TIER * (f.tier - 1.0)
	var alt_f: float = 1.0
	var h: float = (f.y - WorldTerrain.groundY(S, f.x)) / CamParams.BODY_H
	alt_f = maxf(CamParams.ALT_FLOOR, 1.0 / (1.0 + maxf(0.0, h - CamParams.ALT_START) / CamParams.ALT_SCALE))
	if chase_slot == i:
		alt_f = 1.0   # the altitude zoom-out is for a fighter in a fight; a chased launch stays one size so he stays readable
	if solo_kind != "" and solo_slot == i:
		match solo_kind:
			"launch":
				r = CamParams.R_LAUNCH * m
				alt_f = 1.0
			"cut":
				r = CamParams.R_LAUNCH * m * (1.0 + CamParams.CUT_PUSH)
				alt_f = 1.0
			"transform":
				r = CamParams.R_CINE * m
				if _tf_phase != "":
					match _tf_phase:
						"gather":
							var pg: float = clampf(solo_t / (float(_tf_g) * DT), 0.0, 1.0)
							var close: float = CamParams.TRANSFORM_R0 if _tf_ver == "full" else CamParams.TRANSFORM_R0_SHORT
							r = lerpf(CamParams.R_FIGHT, close, smoothstep(0.0, 1.0, pg)) * m
						"break":
							r = CamParams.TRANSFORM_R2 * m
						_:
							r = CamParams.R_FIGHT * m
				elif _solo_dur > 0.0:
					var tp: float = clampf(solo_t / _solo_dur, 0.0, 1.0)
					r = lerpf(CamParams.TRANSFORM_R0, CamParams.TRANSFORM_R1, smoothstep(0.25, 0.45, tp))
					r = lerpf(r, CamParams.TRANSFORM_R2, smoothstep(0.7, 0.95, tp)) * m
				alt_f = 1.0
			"finisher":
				var fp: float = clampf(solo_t / maxf(_solo_dur, 0.1), 0.0, 1.0)
				r = lerpf(CamParams.R_FIGHT, CamParams.R_FINISH, smoothstep(0.0, 1.0, fp)) * m
				alt_f = 1.0
			"ko":
				r = CamParams.R_KO * m
				alt_f = 1.0
			"intro":
				alt_f = 1.0
				match _in_phase:
					"fall":
						r = CamParams.INTRO_R_FALL * m
					"face":
						r = CamParams.INTRO_FACE_R * m
					_:
						var zf: float = CamParams.INTRO_LAND_FIT * vw / (2.0 * maxf(_in_crater_r, 60.0))
						r = clampf(zf * CamParams.BODY_H / vh, CamParams.INTRO_R_LAND_MIN, CamParams.INTRO_R_LAND_MAX) * m
			"wreck":
				var wp: float = 1.0 if reduced_motion else clampf(solo_t / CamParams.WRECK_T, 0.0, 1.0)
				r = lerpf(CamParams.R_WRECK_0, CamParams.R_WRECK, smoothstep(0.0, 1.0, wp)) * m
				alt_f = 1.0
	var z: float = r * vh / CamParams.BODY_H * tier_f * alt_f
	z *= _push_mult(i) * _hit_mult(i)
	if f.state != "launched" and chase_slot != i and not (solo_kind != "" and solo_slot == i):
		var zfl: float = CamParams.R_FLOOR * vh / CamParams.BODY_H
		if many_framing and S.fighters.size() > 2:
			zfl = maxf(zfl, CamParams.MANY_PIX_FLOOR / CamParams.BODY_H)   # a pane's pixel floor in a many-body match (a share of a phone's height is 12 px)
		var gv: float = _scroll_gov(maxf(maxf(float(_vsm[i]), _gov_armed()), _body_speed(f)), z * pz)
		_gov_bind[i] = gv < 0.999
		z = maxf(z * gv, minf(z, zfl))
	elif f.state == "launched" and not reduced_motion:
		# A launched body is followed at his size, but the scenery behind a launch at 6,000 units a second crosses a pane at
		# 0.06 of the width a tick, and a cliff face against sunlit sand swept 23,000 pixels twice in 14 ticks at ai seed
		# 4 (Tools: 3 flashes, the pair 6 and 5% over the area threshold). The same governor as any pursuit (the scenery no
		# faster than SCROLL_MAX of the width a tick), with a floor of his size: LAUNCH_FLOOR of the height.
		var zl: float = CamParams.LAUNCH_FLOOR * vh / CamParams.BODY_H
		var gvl: float = _scroll_gov(maxf(float(_vsm[i]), _body_speed(f)), z * pz)
		_gov_bind[i] = gvl < 0.999
		z = maxf(z * gvl, minf(z, zl))
	if bool(_stg_on[i]) and depth_dolly and not reduced_motion:
		# a stage frames both links: no larger than the zoom that puts them in (never under STAGE_ZOOM_MIN), nor than the shot's own
		z = minf(z, maxf(float(_stg_z[i]), CamParams.STAGE_ZOOM_MIN * vh / 720.0))
	if solo_kind == "launch" and solo_slot == i and solo_phase == "land":
		z *= 1.0 + CamParams.LAND_PUSH * sin(PI * clampf(_land_t / 0.3, 0.0, 1.0))
	var zmax: float = _zcap() * (1.0 + CamParams.TIER_PUSH)
	if solo_kind == "transform" or solo_kind == "ko" or solo_kind == "finisher" or solo_kind == "wreck" or solo_kind == "intro":
		zmax = maxf(zmax, CamParams.R_CLOSE * m * vh / CamParams.BODY_H)   # a close-up may go past the cap
	# A fighter in depth (Fighter.z, positive toward the camera) draws at s = d / (d + w) of his plane size, d = K / zoom.
	# The zoom that gives the apparent height the plane zoom z would have is 1 / (1/z - w / K); where that cannot be
	# reached (the back row) the cap is used, the biggest he can be.
	var w: float = -(float(f.z) - float(_fz[i]))
	if absf(w) > 1.0:
		var k: float = CamParams.K_FACTOR * vh
		var den: float = 1.0 / z - w / k
		z = zmax if den <= 1.0 / zmax else 1.0 / den
	if many_framing:
		z = maxf(z * float(_many_pzf[i]), minf(z, CamParams.MANY_PIX_PRINCIPAL / CamParams.BODY_H))   # the bodies assigned to this pane, down to the principal's pixel floor
	return clampf(z * pz, CamParams.ZOOM_MIN, zmax * pz)


func _anchor_rest(i: int) -> Vector2:
	var n: Vector2 = Vector2(cos(theta), sin(theta))
	var s: float = -1.0 if i == 0 else 1.0
	return Vector2(vw * 0.5, vh * 0.5 + CamParams.ANCHOR_DROP * vh) + s * Vector2(n.x * CamParams.ANCHOR_LX * vw, n.y * CamParams.ANCHOR_LY * vh)


func _half_extent_along_n(n: Vector2) -> float:
	return 0.5 * (absf(n.x) * vw + absf(n.y) * vh)


func _anchor(S: SimState, i: int) -> Vector2:
	var rest: Vector2 = _anchor_rest(i)
	var n: Vector2 = Vector2(cos(theta), sin(theta))
	var q: float = 0.0
	var target: Vector2 = rest
	var solo_pt: Vector2 = Vector2(vw * 0.5, vh * 0.62)
	if (solo_kind == "launch" or solo_kind == "hold") and solo_slot == i:
		var f = S.fighters[i]
		var want: float = CamParams.LAUNCH_TRAIL if f.vx >= 0.0 else 1.0 - CamParams.LAUNCH_TRAIL
		if solo_kind == "hold" and _launch_victim >= 0:
			# The attacker stands on the side away from where the opponent was thrown, so the throw has room.
			var to_v: float = SimWrap.sdx(f.x, S.fighters[_launch_victim].x)
			want = 0.4 if to_v >= 0.0 else 0.6
		_launch_anchor_x += (want - _launch_anchor_x) * (1.0 - exp(-DT / 0.25))
		_launch_anchor_y += (0.62 - _launch_anchor_y) * (1.0 - exp(-DT / 0.25))
		solo_pt.x = vw * _launch_anchor_x
		solo_pt.y = vh * _launch_anchor_y
	if solo_kind == "intro" and solo_slot == i:
		match _in_phase:
			"fall":
				solo_pt = Vector2(vw * 0.5, vh * CamParams.INTRO_FALL_ANCHOR_Y)
			"face":
				solo_pt = Vector2(vw * (0.42 if S.fighters[i].face >= 0.0 else 0.58), vh * 0.66)
			_:
				solo_pt = Vector2(vw * 0.5, vh * (CamParams.INTRO_LAND_ANCHOR_Y if not reduced_motion else 0.62))
	if solo_kind == "wreck" and solo_slot == i:
		var ap: float = 1.0 if reduced_motion else smoothstep(0.0, 1.0, clampf(solo_t / CamParams.WRECK_T, 0.0, 1.0))
		solo_pt = Vector2(vw * (0.5 - CamParams.WRECK_ANCHOR_X * float(wreck_dir) * ap), vh * 0.70)
	if solo_kind == "transform" and solo_slot == i and _tf_phase == "break" and _tf_ver == "full" and not _tf_calm:
		solo_pt.y = vh * 0.74   # low in the frame, the sky above him
	# A shot's anchor is held while the shot fades out (solo_w easing to 0 after it ended): the fallback was the default one,
	# and the picture jumped by the difference (0.13 of the width at the end of a launch's hold, tick 2167 of ai seed 1).
	if solo_kind != "" and solo_slot == i:
		_anchor_hold[i] = solo_pt
	elif solo_kind == "" and solo_slot == i and solo_w > 0.0 and Vector2(_anchor_hold[i]) != Vector2.ZERO:
		solo_pt = _anchor_hold[i]
	if e_slot >= 0:
		if i == e_slot:
			q = maxf(e, solo_w if solo_slot == i else 0.0)
			target = solo_pt
		elif sliver > 0.0:
			q = e
			var s: float = -1.0 if i == 0 else 1.0
			var hn: float = _half_extent_along_n(n)
			var delta: float = hn * (1.0 - 2.0 * sliver) * (1.0 if e_slot == 0 else -1.0)
			var mid: Vector2 = Vector2(vw * 0.5, vh * 0.5) + n * (delta + s * hn) * 0.5
			target = Vector2(mid.x, vh * 0.62)
	elif solo_slot == i and solo_w > 0.0:
		q = solo_w
		target = solo_pt
	return rest.lerp(target, smoothstep(0.0, 1.0, q))


func _cam_from_focus(i: int, z: float, p: Vector2, fz: float = 0.0) -> Vector3:
	return _cam_at(_fx[i], _fy[i], fz, z, p)


## The camera (x, y, zoom) that puts the world point (fx, fy) at depth fz on the screen point p.
func _cam_at(fx: float, fy: float, fz: float, z: float, p: Vector2) -> Vector3:
	# A deep fighter lands at C + (plane point - C) * s, so aim the plane mapping at C + (p - C) / s.
	var target: Vector2 = p
	if fz != 0.0:
		var d: float = CamParams.K_FACTOR * vh / z
		var s: float = maxf(d / maxf(d - fz, 1.0), CamParams.DEPTH_S_MIN)
		var c0 := Vector2(vw * 0.5, vh * 0.5)
		p = c0 + (p - c0) / s
	var x: float = SimWrap.wrap(fx - (p.x - vw * 0.5) / z)
	var y: float = clampf(fy - (vh * CamParams.PLANE_Y - p.y) / z, CamParams.CAM_Y_MIN, SimConst.CEILING - CamParams.CAM_Y_TOP)
	if _pitch_now == 0.0:
		return Vector3(x, y, z)
	return _refine_cam(Vector3(x, y, z), fx, fy, fz, target)


## With a pitch the plane mapping is a projection: refine the straight-on guess with Newton steps (a numerical Jacobian)
## until the fighter's chest lands on `target`.
func _refine_cam(cam: Vector3, fx: float, fy: float, fz: float, target: Vector2) -> Vector3:
	var cx: float = cam.x
	var cy: float = cam.y
	for it in range(3):
		var s0: Vector2 = SplitFrame.project(cx, cy, cam.z, _pitch_now, vw, vh, fx, fy, fz)
		var er: Vector2 = target - s0
		if er.length() < 0.2:
			break
		var sx: Vector2 = (SplitFrame.project(cx + 25.0, cy, cam.z, _pitch_now, vw, vh, fx, fy, fz) - s0) / 25.0
		var sy: Vector2 = (SplitFrame.project(cx, cy + 25.0, cam.z, _pitch_now, vw, vh, fx, fy, fz) - s0) / 25.0
		var det: float = sx.x * sy.y - sy.x * sx.y
		if absf(det) < 1e-12:
			break
		cx = SimWrap.wrap(cx + (sy.y * er.x - sy.x * er.y) / det)
		cy += (-sx.y * er.x + sx.x * er.y) / det
	return Vector3(cx, clampf(cy, CamParams.CAM_Y_MIN, SimConst.CEILING - CamParams.CAM_Y_TOP), cam.z)


## The perspective scale of fighter i at the depth he has now, for the pane's current zoom.
func _depth_s(S: SimState, i: int, z: float) -> float:
	var zz: float = float(S.fighters[i].z) - float(_fz[i])
	if zz == 0.0:
		return 1.0
	var d: float = CamParams.K_FACTOR * vh / z
	return maxf(d / maxf(d - zz, 1.0), CamParams.DEPTH_S_MIN)


static func _blend_cam(a: Vector3, b: Vector3, w: float) -> Vector3:
	if w <= 0.0:
		return a
	if w >= 1.0:
		return b
	return Vector3(SimWrap.wrap(a.x + SimWrap.sdx(a.x, b.x) * w), lerpf(a.y, b.y, w), exp(lerpf(log(a.z), log(b.z), w)))


var _oz: PackedFloat64Array = PackedFloat64Array([0.5, 0.5])
var _oz_valid: bool = false
var _outs: Array = [Vector3.ZERO, Vector3.ZERO]
var _cl_rect: Array = [Rect2(), Rect2()]   # what each pane's foreground is told to open, held and rate-limited
var _cl_have: Array = [false, false]
var _cl_hold: Array = [0.0, 0.0]           # seconds with nothing asking for more room
var _cl_sigma: Array = [0.0, 0.0]
var _cl_shown_prev: Array = [false, false]
var _cl_reg: Array = [Rect2(), Rect2()]   # the pane's room last tick, for how far its edges moved
var _cl_pc: Array = [Vector2.ZERO, Vector2.ZERO]   # the chest each pane's rectangle last saw, for the step it leads by
var _cl_pc_slot: Array = [-1, -1]
var _cl_pc_ok: Array = [false, false]
# The dolly (docs/camera/city-in-depth.md section 6): the depth the frame's scale is defined at follows the pair's depth, so a
# fight in any street is drawn at the plane's size. A switch until Rendering applies SplitFrame.focus_z (and the proof).
var depth_dolly: bool = false
var dolly_near_cap: bool = true                        # the approach cap (part of the dolly; a test can switch it off to compare)
var _lens_d: Array = [0.0, 0.0]                      # the displayed lens's depth last tick (for the approach cap)
var _lens_ok: Array = [false, false]
var dolly_near_caps: int = 0                           # ticks the approach cap held the focus back (counted for the tests)
# The building stage (docs/camera/buildings-in-frame.md section 3), behind the dolly's switch: a launch through buildings is a
# relay of held frames (the building he is in and the next), not a chase. Per launched fighter: the frame's centre, the zoom that
# fits both links, its age.
var _stg_on: Array = [false, false]
var _stg_x: Array = [0.0, 0.0]
var _stg_y: Array = [0.0, 0.0]
var _stg_z: Array = [0.0, 0.0]
var _stg_age: Array = [0, 0]
var _stg_post: Array = [0, 0]
var _bld_evt_t: Array = [-1.0e9, -1.0e9]               # when this fighter's last launch_depth, chain_link or building_hit arrived
var _stg_rel: Array = [0, 0]                           # ticks left of the hand-over from a stage to the ordinary follow
var stage_moves: int = 0                               # stages set or moved (counted for the tests)
# A launch too fast to follow (section 7), its own switch: the pane holds its frame, the body leaves it (a subject off the screen
# costs no flash), and after LH_WAIT of his being gone, or his landing, the pane pans to him at LH_STEP a tick (a cut only
# when he is farther than LH_CUT_UNITS).
var launch_hold: bool = false
var _lh: Array = [0, 0]                                # 0 none, 1 holding the frame, 2 panning to him
var _lh_gone: Array = [0, 0]
var slam_off: bool = false                             # no divider slam UNDER REDUCED FLASHING (or reduced motion): a rush's contact merges the panes the ordinary way (docs/camera/buildings-in-frame.md sections 14 and 15); off by default
var merge_zoom_limit: bool = false                      # the zoom comes in slowly while the panes merge (docs/camera/buildings-in-frame.md section 13); off by default
var _pair_near: bool = false                           # the pair is within MZ_NEAR of each other (for the merge zoom limit)
var _lh_dist: Array = [0.0, 0.0]                       # the width a fast body has covered since he became fast (the rule engages at LH_ENGAGE_W)
var _lh_rel_t: Array = [-1.0e9, -1.0e9]               # when the rule last ended for this pane (it engages at once again within a second)
var _lh_sky: Array = [false, false]                   # this flight began above LH_SKY_ALT: the rule leaves it
var _lh_slow: Array = [0, 0]                           # ticks he has been under LH_SLOW of the threshold
var flash_bundle: bool = false                          # OFF since 2026-10-19 (Orb: play first; the reduced mode plays as d3f1ca0e did, the launched body chased, not held then cut): the launch hold, its eager engage, the merge zoom limit and the reduced slam off, as one switch (docs/camera/buildings-in-frame.md sections 15 and 16) ...
var flash_bundle_reduced_only: bool = true              # ... on only while the reduced-flashing setting is on (the default of the game: EP's decision of 2026-10-16); the ordinary mode is what it was
var _fb_prev: int = -1                                  # the bundle's last state (-1 not yet seen)
var many_framing: bool = false                         # one versus many (docs/camera/one-v-many.md): the shared view frames the principals and the bodies that fit; off by default
var _many_w: Array = [1.0, 1.0, 0.0, 0.0, 0.0]          # each body's weight in the framing set, moved toward its target by MANY_RATE a tick (no step when one joins or leaves)
var _many_dbg: Array = []
var _many_pw: Array = [[0.0, 0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.0]]   # pane i's weight for body k in his framing set (moves at MANY_RATE a tick)
var _many_pzf: Array = [1.0, 1.0]                       # pane i's zoom factor for the bodies assigned to him (1 none)
var _many_pull: Array = [0.0, 0.0]                      # pane i's focus pull toward them, world units
var _many_partner: int = 1                              # the one's partner for framing: the nearest of the others, with a hold
var _many_marks: Array = []                             # the bodies outside the frame this tick, [slot, side]
var merge_lookahead: bool = true                        # a pair moving apart fast is not merged on its present separation (docs/camera/rushcity.md); on since 2026-10-16 (rushcity: 2.5 / 3.5 / 1 -> 2 / 2 / 1)
var struggle_framing: bool = false                      # the beam struggle: the shared view centred toward the meeting point, tightening as it nears a fighter, a punch at each surge (docs/camera/beam-struggle.md); off by default
var _st_mid: float = 0.5                                # the meeting point, eased (0 at the attacker's hands to 1 at the defender's)
var _st_on: bool = false
var _st_w: float = 0.0                                  # the framing's weight: 0 to 1 over STRUGGLE_FADE seconds in, and back out when the struggle ends (no step)
var _st_a: int = 0
var _st_d: int = 1
var _st_t0: float = 0.0
var _st_t1: float = 0.0                                 # the latest time the struggle ends by
var launch_hold_eager: bool = false                     # under reduced flashing the rule engages sooner (section 15); off by default
var launch_holds: int = 0                              # (counted for the tests)
var launch_pans: int = 0
var launch_hold_cuts: int = 0
var _fz: Array = [0.0, 0.0]            # each pane's own camera's focus depth (units, positive toward the camera)
var _fzm: float = 0.0                  # the merged camera's
var _fzt: Array = [0.0, 0.0]           # where each target was last tick (for its step)
var _fzmt: float = 0.0
var _fzo: Array = [0.0, 0.0]           # what each pane displays (the blend of the two, and a cut-in's own)
var _ov_focus_z: float = 0.0
# The travel budget (docs/camera/split-screen.md section 24h): the displayed camera of a pane moves, zooms and re-frames by at
# most TRAVEL_MAX of the screen's width a tick; where it cannot keep him in frame inside that, it cuts once.
var travel_budget: bool = false                        # the rule is a switch until the flash set has measured it (SplitView.set_travel_budget); its constants and the governor's headroom stay
var _od: Array = [Vector3.ZERO, Vector3.ZERO]          # the camera each pane displayed last tick
var _od_valid: bool = false
var _od_before: Array = [Vector3.ZERO, Vector3.ZERO]
var _scr: Array = [0.0, 0.0]                           # the picture's scroll each pane displayed this tick, px a tick at 1024 wide (0 on a cut)
var _gov_bind: Array = [false, false]                  # the scroll governor is holding pane i's zoom target back this tick
var _zr_pane: Array = [1.2, 1.2]
var _gov_bind_m: bool = false                          # ... and the merged camera's
var _zr_now: float = 1.2                               # this tick's comfort rate for the drawn zoom (e-folds a second)
var _od_shown: Array = [false, false]
var _tgt_prev: Array = [Vector3.ZERO, Vector3.ZERO]    # the unlimited target of last tick
var _tb_lost: Array = [0.0, 0.0]                       # seconds the pane has had a subject outside its picture, held back by the budget
var _tb_cut_t: Array = [-1.0e9, -1.0e9]                # when each pane last cut for the budget
var travel_limited: int = 0                            # ticks a pane's displayed camera was held to the budget (counted for the tests)
var travel_cuts: int = 0                               # cuts the budget made (counted for the tests)
var _anchors: Array = [Vector2.ZERO, Vector2.ZERO]
var _anchors_rep: Array = [Vector2.ZERO, Vector2.ZERO]   # what the frame reports: the anchor, moved at most ANCHOR_REPORT_STEP of the width a tick (the cameras are built from the true one)
var _anchors_rep_ok: bool = false
var _owns: Array = [Vector3.ZERO, Vector3.ZERO]


## The focus depth: the pair's, eased (DOLLY_TAU) and capped (3 bh a second in a brawl, 12 in a flight), inside the band. The
## panes' own cameras take their fighter's depth, the merged camera the pair's mean. Off: it is 0.0 and nothing below changes.
func _update_focus_depth(S: SimState) -> void:
	if not depth_dolly:
		if _fzm != 0.0 or float(_fz[0]) != 0.0 or float(_fz[1]) != 0.0:
			_fz = [0.0, 0.0]
			_fzm = 0.0
		return
	var A = S.fighters[0]
	var B = S.fighters[1]
	var flight: bool = A.state == "launched" or B.state == "launched" or chase_slot >= 0 or solo_kind == "launch"
	var cap: float = (CamParams.DOLLY_CAP_FLIGHT if flight else CamParams.DOLLY_CAP_BRAWL) * DT
	var k: float = 1.0 - exp(-DT / CamParams.DOLLY_TAU)
	# The focus never lags the pair by more than DOLLY_LAG: past a street a shove or a flight outruns the cap, and a fighter
	# a lens-distance ahead of the focus would be behind the camera.
	# A drift's onset: with the focus eased alone, a fighter who starts to drift is drawn 7.7% a second smaller for as long as
	# the filter has not moved (his own drift at 1.2 bh a second), and with a smoothed lead the stop took the lead back at 7%.
	# So the focus takes DOLLY_FEED of the target's own step this tick, outright, and eases the rest: the onset and the stop
	# are each (1 - DOLLY_FEED) of the drift (3.8% a second), and a steady drift's lag settles at 22 units.
	for i in range(2):
		var ti: float = clampf(float(S.fighters[i].z), CamParams.DOLLY_Z_BACK, CamParams.DOLLY_Z_FRONT)
		var di: float = clampf(ti - float(_fzt[i]), -cap, cap)
		_fzt[i] = ti
		var fi: float = float(_fz[i]) + CamParams.DOLLY_FEED * di + clampf((ti - float(_fz[i])) * k, -cap, cap)
		var lag_hi: float = CamParams.DOLLY_LAG   # (the focus trails a target that goes deeper from above: its bound is the upper one)
		# The lens does not run at a facade: going deeper, its approach to the nearest face straight ahead is no faster than
		# DOLLY_NEAR_RATE of the distance a second (a building 340 units off filled the screen and changed scale 4.4% a tick).
		if dolly_near_cap and fi < float(_fz[i]):
			var lens_i: float = float(_fz[i]) + CamParams.K_FACTOR * vh / maxf(float(_zo[i]), 0.05)
			var d_i: float = _face_ahead(S, float(_fx[i]), lens_i)
			var v_max: float = maxf(CamParams.DOLLY_NEAR_MIN, CamParams.DOLLY_NEAR_RATE * d_i) * DT
			if float(_fz[i]) - fi > v_max:
				fi = float(_fz[i]) - v_max
				lag_hi = CamParams.DOLLY_LAG_NEAR
				dolly_near_caps += 1
		_fz[i] = clampf(fi, ti - CamParams.DOLLY_LAG, ti + lag_hi)
	var tm: float = clampf((float(A.z) + float(B.z)) * 0.5, CamParams.DOLLY_Z_BACK, CamParams.DOLLY_Z_FRONT)
	var dm: float = clampf(tm - _fzmt, -cap, cap)
	_fzmt = tm
	var fm: float = _fzm + CamParams.DOLLY_FEED * dm + clampf((tm - _fzm) * k, -cap, cap)
	var lag_hi_m: float = CamParams.DOLLY_LAG
	if dolly_near_cap and fm < _fzm:
		var lens_m: float = _fzm + CamParams.K_FACTOR * vh / maxf(_mz, 0.05)
		var d_m: float = _face_ahead(S, _mx, lens_m)
		var vm_max: float = maxf(CamParams.DOLLY_NEAR_MIN, CamParams.DOLLY_NEAR_RATE * d_m) * DT
		if _fzm - fm > vm_max:
			fm = _fzm - vm_max
			lag_hi_m = CamParams.DOLLY_LAG_NEAR
	_fzm = clampf(fm, tm - CamParams.DOLLY_LAG, tm + lag_hi_m)


## The distance from the lens (at depth `lens`, over x `cam_x`) to the nearest building face straight ahead of it: a standing
## building between the lens and the plane whose camera-facing face is inside DOLLY_NEAR_LOOK and whose span meets the central
## DOLLY_NEAR_CENTRE of the view's width at that distance. 1e9 when there is none. Reads S.buildings and nothing else.
func _face_ahead(S: SimState, cam_x: float, lens: float) -> float:
	var best: float = 1.0e9
	var half_h: float = 0.5 / CamParams.K_FACTOR   # tan of the half vertical field
	var aspect: float = vw / maxf(vh, 1.0)
	for b in S.buildings:
		if not b.alive or b.h < 150.0:
			continue
		var face: float = b.z + b.d * 0.5   # the face toward the camera
		var d: float = lens - face
		if d <= 1.0 or d >= CamParams.DOLLY_NEAR_LOOK or d >= best:
			continue
		var half_w: float = half_h * aspect * d
		if absf(SimWrap.sdx(cam_x, b.x)) < 0.5 * b.w + CamParams.DOLLY_NEAR_CENTRE * half_w:
			best = d
	return best


func _snap_focus_depth(S: SimState) -> void:
	if not depth_dolly:
		_fz = [0.0, 0.0]
		_fzm = 0.0
		return
	for i in range(2):
		_fz[i] = clampf(float(S.fighters[i].z), CamParams.DOLLY_Z_BACK, CamParams.DOLLY_Z_FRONT)
		_fzt[i] = _fz[i]
	_fzm = clampf((float(S.fighters[0].z) + float(S.fighters[1].z)) * 0.5, CamParams.DOLLY_Z_BACK, CamParams.DOLLY_Z_FRONT)
	_fzmt = _fzm


## A stage for the launched fighter v: the frame of the two buildings x0 (the one he is at) and x1 (the next), the zoom that puts
## their near edges in with STAGE_MARGIN of the width each side. Held when the new pair is already inside the stage there is.
## Whether the panes are merging: a launch shot is giving the screen back, or the layout became one view within MZ_WINDOW.
func _merging_now() -> bool:
	# A launch shot giving the screen back is not limited (ai 12345's re-merge at tick 1376 to 1432 went from a pass to 3 / 4 / 2.5
	# with the zoom ramp slowed, at 0.0035 and at 0.008 a tick, where the unlimited ramp read 2.5 / 2.5 / 2.5): only the layout's
	# own closing into one view is.
	if solo_slot >= 0 and solo_w > 0.0 and solo_target <= 0.0:
		return false
	if split_wanted or _layout_age >= CamParams.MZ_WINDOW or sep >= 0.999:
		return false
	# a closing counts once the pair is near enough to be merging for certain: the closing that ends in a split's re-opening
	# (ai 12345, ticks 604 to 631: the pair at 490 units, then a dive) is not a merge
	return sep <= 0.001 or _pair_near


## Whether pane i is the only picture on the screen (the launch shot has taken it): the shared camera is hidden then.
func _pane_is_shown_alone(i: int) -> bool:
	return solo_slot == i and solo_w >= 0.99


## A launch shot's pane is still catching up with him (his offset from its focus over LH_CATCH_W, a second at most past the hold):
## the shot does not end and the panes do not merge over it.
func _lh_catching(S: SimState, i: int) -> bool:
	if not launch_hold or reduced_motion or _land_t > CamParams.LAND_HOLD + CamParams.LH_CATCH_MAX:
		return false
	var f = S.fighters[i]
	var ex: float = SimWrap.sdx(_fx[i], f.x) * _zo[i]
	var ey: float = (f.y + CamParams.CHEST - _fy[i]) * _zo[i]
	return sqrt(ex * ex + ey * ey) / vw > CamParams.LH_CATCH_W


func _stage_set(v: int, x0: float, y0: float, x1: float, y1: float) -> void:
	if not depth_dolly or reduced_motion or v < 0 or v > 1:
		return
	var dx: float = SimWrap.sdx(x0, x1)
	if bool(_stg_on[v]):
		var zs: float = maxf(float(_stg_z[v]), 0.001)
		var room: float = (0.5 - CamParams.STAGE_MARGIN) * vw / zs - CamParams.STAGE_BLD_HALF
		if absf(SimWrap.sdx(float(_stg_x[v]), x0)) <= room and absf(SimWrap.sdx(float(_stg_x[v]), x1)) <= room:
			_stg_age[v] = 0
			return
	var need: float = absf(dx) + 2.0 * CamParams.STAGE_BLD_HALF
	var zf: float = (1.0 - 2.0 * CamParams.STAGE_MARGIN) * vw / maxf(need, 1.0)
	_stg_z[v] = maxf(zf, CamParams.STAGE_ZOOM_MIN * vh / 720.0)
	_stg_x[v] = SimWrap.wrap(x0 + dx * 0.5)
	_stg_y[v] = (y0 + y1) * 0.5
	_stg_on[v] = true
	_stg_age[v] = 0
	_stg_post[v] = 0
	stage_moves += 1


func _update_stage(S: SimState) -> void:
	for i in range(2):
		if not bool(_stg_on[i]):
			continue
		var f = S.fighters[i]
		_stg_age[i] = int(_stg_age[i]) + 1
		var off: bool = (not depth_dolly) or reduced_motion or int(_stg_age[i]) > CamParams.STAGE_MAX
		if f.state != "launched":
			_stg_post[i] = int(_stg_post[i]) + 1
			if int(_stg_post[i]) > CamParams.STAGE_LODGE:
				off = true
		else:
			_stg_post[i] = 0
		# he has left the stage (faster than its relay): the ordinary follow takes him
		if absf(SimWrap.sdx(_fx[i], f.x)) * maxf(_zo[i], 0.001) > CamParams.STAGE_EXIT * vw:
			off = true
		if off:
			_stg_on[i] = false
			if depth_dolly and not reduced_motion:
				_stg_rel[i] = CamParams.STAGE_HANDOVER


func _update_cameras(S: SimState) -> void:
	_struggle_tick(S)
	_update_focus_depth(S)
	_update_stage(S)
	_pair_near = sqrt(pow(SimWrap.sdx(S.fighters[0].x, S.fighters[1].x), 2.0) + pow(S.fighters[1].y - S.fighters[0].y, 2.0)) < CamParams.MZ_NEAR
	if _slam_slot >= 0:
		_slam_run(S)
	var stiff: bool = _slam_slot >= 0 and e > 0.0
	# The slam's stiff filters come in over SLAM_STIFF_RAMP, not in one tick: a filter that goes from 0.14 s to 0.03 s at
	# once shoves the camera up to 0.3 of the screen width (the jolt scan's biggest ordinary one).
	_stiff_w = clampf(_stiff_w + DT / CamParams.SLAM_STIFF_RAMP, 0.0, 1.0) if stiff else 0.0
	var sw: float = smoothstep(0.0, 1.0, _stiff_w)
	var transition: bool = (sep > 0.001 and sep < 0.999) or e > 0.001 or solo_kind != "" or solo_w > 0.001 or stiff
	var zrate: float = CamParams.ZOOM_RATE_TRANS if transition else CamParams.ZOOM_RATE
	_zr_now = zrate
	for i in range(2):
		var f = S.fighters[i]
		var tau_x: float = CamParams.TAU_X
		var tau_y: float = CamParams.TAU_Y
		var freeze: bool = false
		if (solo_kind == "launch" and solo_slot == i and solo_phase == "follow") or chase_slot == i:
			tau_x = CamParams.LAUNCH_TAU
			tau_y = CamParams.TAU_Y * 0.7
			freeze = reduced_motion
		if stiff:
			tau_x = lerpf(tau_x, CamParams.SLAM_TAU, sw)
			tau_y = lerpf(tau_y, CamParams.SLAM_TAU, sw)
		# The follow point leads the fighter by its measured velocity times the filter's time constant, which cancels
		# the filter's lag at constant speed. Measured, not the sim's vx: a rush moves the fighter without setting vx.
		var vxm: float = SimWrap.sdx(_ppx[i], f.x) / DT
		var vym: float = (f.y - _ppy[i]) / DT
		_ppx[i] = f.x
		_ppy[i] = f.y
		# The lead follows the velocity with its change per tick limited. A body that goes from rest to 7,900 units a second
		# in one tick (a beam's launch out of hit-stop, ground that falls away under him) was followed by a camera that went
		# from rest to a tenth of the screen a tick in that tick, because the lead cancels the filter's lag exactly: a step of
		# 0.10 of the width a tick, and at 2145 of ai seed 1 one of Tools' counted changes. It now takes about three ticks.
		if absf(vxm) > 60000.0 or absf(vym) > 60000.0:
			_vlx[i] = 0.0
			_vly[i] = 0.0
		elif absf(vxm - float(_vlx[i])) > CamParams.ONSET_MAX or absf(vym - float(_vly[i])) > CamParams.ONSET_MAX_Y:
			_vlx[i] = vxm   # a fling (a step of over 12,000 units a second) is chased as before: it cannot be eased, only followed
			_vly[i] = vym
		else:
			if int(_onset_cool[i]) > 0:
				_onset_cool[i] = int(_onset_cool[i]) - 1
			elif absf(vxm - float(_vlx[i])) > CamParams.LEAD_SLEW or absf(vym - float(_vly[i])) > CamParams.LEAD_SLEW:
				_onset[i] = CamParams.CAP_TICKS   # his velocity stepped: a launch out of hit-stop, ground that fell away
				_onset_run[i] = 0
				_onset_cool[i] = CamParams.CAP_COOL
			_vlx[i] = float(_vlx[i]) + clampf(vxm - float(_vlx[i]), -CamParams.LEAD_SLEW, CamParams.LEAD_SLEW)
			_vly[i] = float(_vly[i]) + clampf(vym - float(_vly[i]), -CamParams.LEAD_SLEW, CamParams.LEAD_SLEW)
		var zc: float = maxf(_zo[i], 0.001)
		# A launch too fast to follow (launch_hold): the pane holds, then pans (see the variable's note).
		var lh_ph: int = 0
		if launch_hold and not reduced_motion:
			lh_ph = int(_lh[i])
			var spd_l: float = sqrt(vxm * vxm + vym * vym)
			var z_fl: float = CamParams.LAUNCH_FLOOR * vh / CamParams.BODY_H
			# A launch through buildings is the spectacle: a stage's, with the dolly on, and the rule leaves it for the chain and
			# 2.5 s after. With the dolly off there is no stage, and a launch is judged by its speed alone (the clip's victim at
			# 32,000 units a second crosses a city of buildings: the follow at 0.06 to 0.09 of the width a tick was the failure).
			var bld: bool = depth_dolly and time - float(_bld_evt_t[i]) < 2.5
			if bld:
				lh_ph = 0   # a building is in the flight: the follow takes him (a hold or pan under way ends)
			var speed_w: float = spd_l * z_fl / 60.0 / vw   # the picture's step at the floor's zoom, in widths a tick
			# (a flight high above the ground is over sky: a chase there changes no more than a gradient, and the rule's cut to the
			# landing would put a contrasty city on screen where the follow had shown none: ai 12345 at tick 2066, on 3dda977f,
			# read 2 / 2.5 / 2 with the follow and 3 / 3 / 3 with the rule)
			# Latched for the flight: he began it high, so the follow's picture is sky until his last few ticks, and the rule's
			# hold would put the camera behind and cut onto the city where he lands.
			if f.state != "launched":
				_lh_sky[i] = false
			elif lh_ph == 0 and not bool(_lh_sky[i]) and float(f.y) - WorldTerrain.groundY(S, f.x) > CamParams.LH_SKY_ALT:
				_lh_sky[i] = true
			var high: bool = bool(_lh_sky[i])
			var fast: bool = f.state == "launched" and speed_w > CamParams.LH_SPEED and not bld and not high and not _keeps_in_view(S, i)
			if lh_ph == 0:
				# Engage when a fast body has covered LH_ENGAGE_W of the width (at the pane's zoom): a spike that dies in a few
				# ticks (a knock-back out of a lock, 7,000 units a second for 5 ticks and then 1,200) is the ordinary follow's.
				if fast:
					var step_w: float = spd_l * zc / 60.0 / vw   # his step this tick at the pane's own zoom, in widths
					_lh_dist[i] = float(_lh_dist[i]) + step_w
					var eng_w: float = CamParams.LH_ENGAGE_W_REDUCED if (flash_reduced and launch_hold_eager) else CamParams.LH_ENGAGE_W
					var big_w: float = CamParams.LH_BIG_REDUCED if (flash_reduced and launch_hold_eager) else CamParams.LH_BIG
					if float(_lh_dist[i]) >= eng_w or step_w >= big_w or time - float(_lh_rel_t[i]) < 1.0:
						lh_ph = 1
						_lh_slow[i] = 0
						launch_holds += 1
				else:
					_lh_dist[i] = 0.0
			elif lh_ph == 1:
				# The frame is held while he is fast. When he has slowed (under LH_SLOW of the threshold for LH_SLOW_TICKS) or has
				# landed the rule ends: one cut if he is far from the frame (a flash, once a launch), else the ordinary follow takes
				# him, never a pan (a pan sweeps the scenery for ten ticks: five to ten counted changes).
				# (the sim's own velocity counts too: a hit-stop holds the body still for a few ticks with his speed intact, and
				# that is not a body that has slowed)
				var sim_w: float = sqrt(float(f.vx) * float(f.vx) + float(f.vy) * float(f.vy)) * z_fl / 60.0 / vw
				_lh_slow[i] = int(_lh_slow[i]) + 1 if (f.state != "launched" or maxf(speed_w, sim_w) < CamParams.LH_SLOW * CamParams.LH_SPEED) else 0
				if f.state != "launched" or int(_lh_slow[i]) >= CamParams.LH_SLOW_TICKS:
					var dx_l: float = SimWrap.sdx(_fx[i], f.x)
					var dy_l: float = f.y + CamParams.CHEST - _fy[i]
					var far_w: float = sqrt(dx_l * dx_l + dy_l * dy_l) * zc / vw
					if far_w > CamParams.LH_CUT_OFFSET:
						_fx[i] = f.x
						_fy[i] = f.y + CamParams.CHEST
						_cut_now = true
						_cut_dip()
						launch_hold_cuts += 1
					# the shared camera was frozen with the pane: it joins where it is wanted while it is hidden, so the merge that
					# follows has no offset left in it
					if solo_w >= 0.99 or not _pane_is_shown_alone(i):
						_snap_merged(S)
					lh_ph = 0
					_lh_dist[i] = 0.0
					_lh_rel_t[i] = time
			_lh[i] = lh_ph
		else:
			_lh[i] = 0
		var staged: bool = bool(_stg_on[i]) and depth_dolly and not reduced_motion
		var handover: float = 0.0
		if staged:
			tau_x = CamParams.STAGE_TAU
			tau_y = CamParams.STAGE_TAU
		elif int(_stg_rel[i]) > 0:
			handover = float(_stg_rel[i]) / float(CamParams.STAGE_HANDOVER)
			_stg_rel[i] = int(_stg_rel[i]) - 1
		if lh_ph == 1:
			freeze = true
		# Lead room: while a launched fighter is chased (a pane's chase, or a launch shot's follow) the focus sits a little
		# ahead of him, so more of the pane is in front of him than behind; smoothed so it never moves the picture quickly.
		var lead_t: float = 0.0
		if (chase_slot == i or (solo_kind == "launch" and solo_slot == i and solo_phase == "follow")) and f.state == "launched" and not reduced_motion and sep > 0.999 and e < 0.001:
			var lmax: float = CamParams.CHASE_LEAD_X * vw / zc
			if absf(_depth_s(S, i, zc) - 1.0) > 0.15:
				lmax = 0.0   # off the plane the lead shows larger (or smaller) and the depth framing has the pane's room: no lead
			lead_t = clampf(vxm * CamParams.CHASE_LEAD_T, -lmax, lmax)
		_lead[i] += (lead_t - _lead[i]) * (1.0 - exp(-DT / CamParams.CHASE_LEAD_TAU))
		var lead_c: float = _lead[i]
		# A body low over the ground (a bounce, a lip flight, a tumble) is not followed up: the focus stays at the ground
		# level until he is above LOW_AIR_DEAD, so a half-body-height bounce moves on the screen as it does in the world
		# (the chase otherwise follows each rise and the bounce nearly vanishes: 5 to 20 px for 1 to 2 body heights).
		var fy_ref: float = f.y + CamParams.CHEST
		var lead_w: float = 1.0
		if solo_kind == "intro" and _in_phase == "fall" and solo_slot == i and not reduced_motion:
			# The camera falls a little slower than he does, so he drops through the frame (INTRO_FALL_DROP units from the
			# top at the start to the anchor at the touchdown) and the ground comes up: pinned on him, the sky shows no fall.
			var kf: float = clampf(1.0 - CamParams.INTRO_FALL_DROP / _in_fall_h, 0.0, 1.0)
			var gf: float = WorldTerrain.groundY(S, f.x)
			fy_ref = gf + CamParams.CHEST + kf * (f.y - gf)
			lead_w = kf
		elif f.state == "launched" and not stiff and CamParams.LOW_AIR_DEAD > 0.0:
			var gnd: float = WorldTerrain.groundY(S, f.x)
			lead_w = smoothstep(CamParams.LOW_AIR_DEAD * 0.5, CamParams.LOW_AIR_DEAD * 1.5, f.y - gnd)
			fy_ref = lerpf(gnd + CamParams.CHEST, f.y + CamParams.CHEST, lead_w)
		if int(_rush_wait[i]) > 0 and not _rush_pin[i]:
			freeze = true   # a rush's pane waits RUSH_COMMIT_TICKS before its cut ahead: still, not following him (the whip of a pane chasing 18,000 units a second was 63 more rush jolts in the sweep)
		if _rush_pin[i]:
			var rp = f.rush
			if rp == null or rp.tgt == null or solo_kind != "" or sep < 0.999:
				_rush_pin[i] = false
				# The rush ended before he got there (a parry, a knock-back): a pane aimed far from him cuts back to him once,
				# instead of the lag bound whipping across.
				var ux: float = SimWrap.sdx(_fx[i], f.x) * zc
				var uy: float = (f.y + CamParams.CHEST - _fy[i]) * zc
				if sqrt(ux * ux + uy * uy) / vw > CamParams.LAG_HARD:
					_fx[i] = f.x
					_fy[i] = f.y + CamParams.CHEST
					rush_cuts += 1
					_cut_now = true
					_cut_dip()
			else:
				_rush_pin_t[i] = time
				_fx[i] = SimWrap.wrap(rp.tgt.x + rp.off)
				_fy[i] = rp.tgt.y + CamParams.CHEST
				freeze = true
		if not freeze:
			# The lag bound (camera-v2.md section 2). e is the fighter's offset from where the camera is aiming, in screen
			# widths: ordinary up to LAG_SOFT, the filters speed up to 7x by LAG_HARD, the focus is held to LAG_HARD beyond
			# it (a whip), and farther than LAG_CUT it jumps (a counted safety cut with a short fade).
			var rx: float = (SimWrap.sdx(_fx[i], f.x) + lead_c) * zc
			var ry: float = (fy_ref - _fy[i]) * zc
			var e_w: float = sqrt(rx * rx + ry * ry) / vw
			var lag_soft: float = CamParams.LAG_SOFT
			var lag_hard: float = CamParams.LAG_HARD
			var cut_w: float = CamParams.LAG_CUT
			if staged:
				lag_soft = CamParams.STAGE_LAG_HARD
				lag_hard = CamParams.STAGE_LAG_HARD + 0.01
			elif handover > 0.0:
				lag_soft = lerpf(CamParams.LAG_SOFT, CamParams.STAGE_LAG_HARD, handover)
				lag_hard = lerpf(CamParams.LAG_HARD, CamParams.STAGE_LAG_HARD + 0.01, handover)
			if lh_ph == 2:
				lag_soft = 1.0e9
				lag_hard = 1.0e9 + 1.0
				cut_w = CamParams.LH_CUT_UNITS * zc / vw
			if e_w > lag_soft:
				var gain: float = 1.0 + CamParams.LAG_GAIN * (minf(e_w, lag_hard) - lag_soft) / (lag_hard - lag_soft)
				if reduced_motion:
					gain = minf(gain, 3.0)
				tau_x /= gain
				tau_y /= gain
			if e_w > cut_w:
				_fx[i] = f.x
				_fy[i] = f.y + CamParams.CHEST
				if lh_ph == 2:
					launch_hold_cuts += 1
					_lh[i] = 0
				else:
					lag_cuts += 1
				_cut_now = true
				_cut_dip()
			var kx: float = 1.0 - exp(-DT / tau_x)
			var ky: float = 1.0 - exp(-DT / tau_y)
			# The lead that makes the discrete filter track a constant speed exactly: DT (1 - k) / k, about tau - DT / 2.
			# The velocity lead cancels the filter's lag at a steady speed; a rush that starts and stops inside one time constant (a
			# short blitz) would leave the focus up to 700 units past him and slide back when he stops, so in a rush it is bounded.
			var vlead_x: float = float(_vlx[i]) * DT * (1.0 - kx) / kx
			if f.rush != null:
				var vlim: float = CamParams.RUSH_LEAD_MAX * vw / zc
				vlead_x = clampf(vlead_x, -vlim, vlim)
			var tx: float = f.x + lead_c + vlead_x + float(_many_pull[i])
			var ty: float = fy_ref + float(_vly[i]) * lead_w * DT * (1.0 - ky) / ky
			# A body the sim sets down on lower ground (a floor that went from under him, a roof that fell: 206 units in one tick
			# at ai seed 4, tick 1809, with no flight before it) is a position step, not a motion: the focus holds its height for
			# SETDOWN_HOLD ticks and the pane's picture does not shift by 150 pixels in one tick (a third of the frame's edges
			# changing at once); he moves down the screen instead, and the filter takes him back after the hold.
			if f.state != "launched" and absf(vym) * DT > CamParams.SETDOWN_STEP and absf(float(_pvy_last[i])) < 1500.0 and not _cut_now:
				_ydefer[i] = CamParams.SETDOWN_HOLD
			if int(_ydefer[i]) > 0:
				_ydefer[i] = int(_ydefer[i]) - 1
				ty = _fy[i]
				# never so long that he is near the pane's edge: at most SETDOWN_ROOM of the height from the focus
				var room_y: float = CamParams.SETDOWN_ROOM * vh / zc
				var off_y: float = f.y + CamParams.CHEST - ty
				if absf(off_y) > room_y:
					ty = f.y + CamParams.CHEST - signf(off_y) * room_y
			# Aimed at a building (B2): the focus leads toward it, a bounded distance on screen, so it is in frame.
			if staged:
				# the stage's own frame: the centre of the building he is in and the next, held while he crosses it
				tx = float(_stg_x[i])
				ty = float(_stg_y[i]) + CamParams.CHEST
			elif _aim[i] != null and f.state == "launched":
				var zz: float = maxf(_zo[i], 0.001)
				tx += clampf(CamParams.LEAD_FRAC * SimWrap.sdx(f.x, _aim[i].x), -CamParams.LEAD_MAX_X * vw / zz, CamParams.LEAD_MAX_X * vw / zz)
				ty += clampf(CamParams.LEAD_FRAC * (_aim[i].y - f.y), -CamParams.LEAD_MAX_Y * vh / zz, CamParams.LEAD_MAX_Y * vh / zz)
			var stp_x: float = SimWrap.sdx(_fx[i], tx) * kx
			var stp_y: float = (ty - _fy[i]) * ky
			if staged or handover > 0.0 or lh_ph == 2:
				# the relay, the hand-over and the pan move the picture by at most STAGE_STEP (LH_STEP) of the width a tick
				var cap_u: float = (CamParams.LH_STEP if lh_ph == 2 else CamParams.STAGE_STEP) * vw / zc
				var len_u: float = sqrt(stp_x * stp_x + stp_y * stp_y)
				if len_u > cap_u:
					stp_x *= cap_u / len_u
					stp_y *= cap_u / len_u
			_fx[i] = SimWrap.wrap(_fx[i] + stp_x)
			_fy[i] += stp_y
			if not reduced_motion:
				var qd: float = SimWrap.sdx(_fx[i], f.x) + lead_c
				var qx: float = qd * zc
				var qy: float = (f.y + CamParams.CHEST - _fy[i]) * zc
				var q_w: float = sqrt(qx * qx + qy * qy) / vw
				if q_w > lag_hard:
					var back: float = (q_w - lag_hard) / q_w   # hold him at the bound: move the focus the excess toward him
					_fx[i] = SimWrap.wrap(_fx[i] + qd * back)
					_fy[i] += (f.y + CamParams.CHEST - _fy[i]) * back
					lag_whips += 1
			# The re-frame limiter: after his velocity steps (a beam's launch out of hit-stop, ground that falls away under him)
			# the focus may not take a larger step than SCROLL_CAP of the width a tick (0.03 under reduced motion or reduced
			# flashing) or than the step it took last tick: it can slow down at once, it cannot speed up, so the re-frame is
			# eased and not a jump (140 and 215 units in a tick at ai seed 1's impact: a dark cliff face swept across bright
			# sand in 3 ticks). Measured: allowing it any speeding-up at all (0.01 of the width a tick each tick) puts the sweep
			# back over the analyser's area threshold. It gives way where the lag has him (CAP_LAG, 0.14 of the width from the
			# focus: from there he is followed at his speed, so it never switches on and off at that edge), ends by itself when
			# the focus asks for no more than it may take, or after CAP_MAX ticks, and a cut, a snap or a jump over 1,500
			# units is not a re-frame.
			var lim_on: bool = int(_onset[i]) > 0
			if lim_on:
				_onset[i] = int(_onset[i]) - 1
				_onset_run[i] = int(_onset_run[i]) + 1
			if lim_on and not _cut_now and not (solo_kind == "intro" and solo_slot == i):
				var calm_c: bool = reduced_motion or flash_reduced
				var floor_u: float = (CamParams.SCROLL_MAX_REDUCED if calm_c else CamParams.SCROLL_CAP) * vw / zc
				var room: float = CamParams.CAP_LAG * vw / zc
				var pst: Vector2 = _pst[i]
				var sx: float = SimWrap.sdx(_pfx[i], _fx[i])
				var sy: float = _fy[i] - float(_pfy[i])
				var capped: bool = false
				# The step may be as large as it takes to keep him within CAP_LAG of the focus, so the limit never switches on
				# and off at that edge: a fling past it is followed at his speed, 0.14 behind.
				var step_x: float = maxf(maxf(floor_u, absf(pst.x)), absf(SimWrap.sdx(_pfx[i], f.x) + lead_c) - room)
				var step_y: float = maxf(maxf(floor_u, absf(pst.y)), absf(f.y + CamParams.CHEST - float(_pfy[i])) - room)
				if absf(sx) > step_x and absf(sx) < 1500.0:
					_fx[i] = SimWrap.wrap(_pfx[i] + signf(sx) * step_x)
					capped = true
				if absf(sy) > step_y and absf(sy) < 1500.0:
					_fy[i] = float(_pfy[i]) + signf(sy) * step_y
					capped = true
				if capped:
					scroll_caps += 1
					if int(_onset_run[i]) < CamParams.CAP_MAX:
						_onset[i] = maxi(int(_onset[i]), 1)
		# own zoom: first-order filter, then the rate cap
		# the scroll governor reads how fast the pane's camera is actually moving (a pinned pane is not: it waits)
		var dfx: float = absf(SimWrap.sdx(_pfx[i], _fx[i]))
		if dfx > 1500.0:
			dfx = 0.0   # a jump (a cut ahead, a seam) is not a scroll; a pinned pane that follows a fleeing target is one
		_vsm[i] = float(_vsm[i]) + (minf(dfx / DT, 60000.0) - float(_vsm[i])) * 0.2
		_pvy_last[i] = vym
		_pst[i] = Vector2(SimWrap.sdx(_pfx[i], _fx[i]), float(_fy[i]) - float(_pfy[i]))
		_pfx[i] = _fx[i]
		_pfy[i] = _fy[i]
		_many_pane_tick(S, i)
		var zt: float = _own_zoom_target(S, i)
		var tau_z: float = CamParams.TAU_Z
		if (solo_kind == "ko" or solo_kind == "finisher") and solo_slot == i:
			tau_z = CamParams.KO_DOLLY / 3.0
		if solo_kind == "wreck" and solo_slot == i:
			tau_z = 0.2 if reduced_motion else CamParams.WRECK_TAU
		if solo_kind == "intro" and solo_slot == i:
			tau_z = 0.12
		if solo_kind == "transform" and solo_slot == i and _tf_phase != "":
			tau_z = 0.12   # the beats are on a clock: the push has to land by the break
		if stiff:
			tau_z = lerpf(tau_z, CamParams.SLAM_TAU, sw)
		# A zoom-out the scroll governor asks for is taken with a short time constant (GOV_TAU, at the ordinary rate cap): a
		# pursuit at 6,000 units a second crossed 0.09 of the width a tick for the second the slow zoom took, and the travel
		# budget held the picture back (a cut every half second) for as long.
		var gov_out: bool = bool(_gov_bind[i]) and zt < _zo[i]
		if gov_out:
			tau_z = minf(tau_z, CamParams.GOV_TAU)
		var kz: float = 1.0 - exp(-DT / tau_z)
		var dz: float = (log(zt) - log(_zo[i])) * kz
		var cap: float = (CamParams.SLAM_ZOOM_RATE if stiff else zrate) * DT
		_zr_pane[i] = zrate
		dz = clampf(dz, -cap, cap)
		if lh_ph == 1:
			dz = 0.0   # the frame is held: no zoom either (a zoom is the whole picture moving)
		elif lh_ph == 2:
			dz = clampf(dz, -CamParams.LH_ZOOM_STEP, CamParams.LH_ZOOM_STEP)   # (no pan any more: phase 2 is never entered)
		elif merge_zoom_limit and not reduced_motion and _merging_now():
			dz = minf(dz, CamParams.MZ_RATE)   # the zoom comes in slowly while the panes merge
		_zo[i] = exp(log(_zo[i]) + dz)
	# the merged shadow camera: the reference camera's ease, snapped while two full panes are up
	var mt: Vector3 = _merged_target(S)
	# A launch the rule does not follow holds the shared frame too: the displayed camera is the blend of the shared and the
	# launched pane's while the pane takes the screen, and the shared one would otherwise zoom out and travel for the pair
	# (4% a tick, 200 units a tick) under it.
	var m_held: bool = launch_hold and not reduced_motion and (int(_lh[0]) != 0 or int(_lh[1]) != 0)
	if m_held:
		pass
	elif sep >= 0.999 and _slam_slot < 0 and solo_kind == "":
		_mx = mt.x
		_my = mt.y
		_mz = mt.z
	else:
		var tau_m: float = lerpf(CamParams.MERGED_TAU, CamParams.SLAM_TAU, sw) if stiff else CamParams.MERGED_TAU
		var edge: float = 0.0
		for fi in range(2):
			edge = maxf(edge, absf(SimWrap.sdx(_mx, S.fighters[fi].x)) * _mz / vw)
		if edge > 0.30:
			tau_m /= 1.0 + CamParams.LAG_GAIN * (minf(edge, 0.46) - 0.30) / 0.16
		var km: float = 1.0 - exp(-DT / tau_m)
		var vmx: float = SimWrap.sdx(_pmx, mt.x) / DT
		var vmy: float = (mt.y - _pmy) / DT
		if absf(vmx * DT) > 1500.0:
			vmx = 0.0   # the midpoint's target flipped across the antipode: not a motion
		var mx_old: float = _mx
		_mx = SimWrap.wrap(_mx + SimWrap.sdx(_mx, mt.x + vmx * DT * (1.0 - km) / km) * km)
		_vsm_m += (minf(absf(SimWrap.sdx(mx_old, _mx)) / DT, 60000.0) - _vsm_m) * 0.2
		_my += (mt.y + vmy * DT * (1.0 - km) / km - _my) * km
		var kzm: float = km
		if _gov_bind_m and mt.z < _mz:
			kzm = maxf(km, 1.0 - exp(-DT / CamParams.GOV_TAU))
		var dzm: float = (log(mt.z) - log(_mz)) * kzm
		var capm: float = (CamParams.SLAM_ZOOM_RATE if stiff else CamParams.ZOOM_RATE_TRANS) * DT
		dzm = clampf(dzm, -capm, capm)
		if merge_zoom_limit and not reduced_motion and _merging_now():
			dzm = minf(dzm, CamParams.MZ_RATE)
		_mz = exp(log(_mz) + dzm)
	_pmx = mt.x
	_pmy = mt.y
	if m_held:
		_vsm_m *= 0.8
	_outputs(S)


func _outputs(S: SimState) -> void:
	for i in range(2):
		_anchors[i] = _anchor(S, i)
		_owns[i] = _cam_from_focus(i, _zo[i], _anchors[i], float(S.fighters[i].z) - float(_fz[i]))
	var shared: Vector3 = Vector3(_mx, _my, _mz)
	var fz_sh: float = _fzm
	if solo_slot >= 0 and solo_w > 0.0:
		shared = _blend_cam(shared, _owns[solo_slot], smoothstep(0.0, 1.0, solo_w))
		fz_sh = lerpf(_fzm, float(_fz[solo_slot]), smoothstep(0.0, 1.0, solo_w))
	var w: float = 1.0 - _smootherstep(sep)
	var slam_now: bool = _slam_slot >= 0 and e > 0.0
	for i in range(2):
		var o: Vector3 = _blend_cam(_owns[i], shared, w)
		var fzo_i: float = lerpf(float(_fz[i]), fz_sh, w)   # the depth the displayed camera is defined at
		_fzo[i] = fzo_i
		var fz_i: float = float(S.fighters[i].z) - fzo_i
		if w > 0.0 and w < 1.0 and (_pitch_now != 0.0 or absf(fz_i) > 1.0 or absf(float(_fz[i]) - fz_sh) > 1.0) and solo_kind == "" and _ov_kind == "":
			# At a pitch or in depth the screen is not linear in the camera's y: blending the cameras let the fighter
			# leave the screen mid-blend (a pair 2,600 units apart in depth at 49 degrees: fighter 0 190 px below the
			# bottom while the split opened). Blend where he is on the screen instead: the camera that puts him at
			# the mix of his place in the shared view and his anchor, at the blended zoom.
			var f_i = S.fighters[i]
			var ps: Vector2 = SplitFrame.project(shared.x, shared.y, shared.z, _pitch_now, vw, vh, f_i.x, f_i.y + CamParams.CHEST, float(f_i.z) - fz_sh)
			o = _cam_at(f_i.x, f_i.y + CamParams.CHEST, fz_i, o.z, ps.lerp(_anchors[i], 1.0 - w))
		# Whatever the blends do, the drawn zoom never changes faster than the comfort limit; the slam's door gets the
		# higher SLAM_ZOOM_RATE (it was exempt: 0.2 of a log unit in one tick, the largest jolt in the sweep's scan).
		if _oz_valid:
			var cap: float = (CamParams.SLAM_ZOOM_RATE if slam_now else CamParams.ZOOM_RATE_TRANS) * DT
			var cap_up: float = cap
			if merge_zoom_limit and not reduced_motion and _merging_now():
				cap_up = minf(cap, CamParams.MZ_RATE)
			var z_held: float = exp(log(_oz[i]) + clampf(log(o.z) - log(_oz[i]), -cap, cap_up))
			# The approach cap's other half: the lens (the focus depth plus the camera's distance to it) is the same whatever moves
			# it, so a zoom that comes in while the focus goes deeper is held when the lens would close on the face ahead faster
			# than DOLLY_NEAR_RATE of its distance a second (by at most 2% a tick: never a pop).
			if depth_dolly and dolly_near_cap and bool(_lens_ok[i]) and not _cut_now:
				var lens_prev_i: float = float(_lens_d[i])
				var d_held: float = CamParams.K_FACTOR * vh / maxf(z_held, 0.05)
				if lens_prev_i - (fzo_i + d_held) > 0.0:
					var dface_i: float = _face_ahead(S, o.x, lens_prev_i)
					var vmax_i: float = maxf(CamParams.DOLLY_NEAR_MIN, CamParams.DOLLY_NEAR_RATE * dface_i) * DT
					if lens_prev_i - (fzo_i + d_held) > vmax_i:
						var d_need: float = lens_prev_i - vmax_i - fzo_i
						if d_need > d_held:
							z_held = maxf(CamParams.K_FACTOR * vh / d_need, z_held * 0.98)
							dolly_near_caps += 1
			var z_mis: float = absf(log(z_held) - log(o.z))
			if w <= 0.0 and z_mis > 0.02 and _ov_kind == "":
				# The comfort limit held the drawn zoom back from the pane's own: aim the camera for the zoom that is drawn, so the
				# focus still lands on his anchor. (Aimed for the target zoom, a pane zooming out for a fighter at 12,000 units a
				# second put him 620 px off his anchor, 1.5 widths past the pane's edge, for the second the zoom took: seed 17.)
				# Taken in as the mismatch grows (2% to 15%), so a small hold is the old picture and nothing pops.
				var aimed: Vector3 = _cam_from_focus(i, z_held, _anchors[i], fz_i)
				var k_aim: float = smoothstep(0.02, 0.15, z_mis)
				o = Vector3(SimWrap.wrap(o.x + SimWrap.sdx(o.x, aimed.x) * k_aim), lerpf(o.y, aimed.y, k_aim), z_held)
			o.z = z_held
		_lens_d[i] = fzo_i + CamParams.K_FACTOR * vh / maxf(o.z, 0.05)
		_lens_ok[i] = true
		_outs[i] = o
		_oz[i] = o.z
	if _ov_kind != "":
		var oc: Vector3 = _overlay_cam(S)
		_outs[0] = oc
		_outs[1] = oc
		_fzo[0] = _ov_focus_z
		_fzo[1] = _ov_focus_z
		_oz[0] = oc.z
		_oz[1] = oc.z
	_oz_valid = true
	_travel_budget(S)


## The pane's displayed travel in a tick, in widths of the screen: the camera's step at the new zoom, in x and y together, and
## half of the zoom's change (the scenery at the screen's edge moves by that much when the picture scales about its centre).
func _travel(a: Vector3, b: Vector3) -> float:
	var dx: float = SimWrap.sdx(a.x, b.x)
	var dy: float = b.y - a.y
	return sqrt(dx * dx + dy * dy) * b.z / maxf(vw, 1.0) + 0.5 * absf(log(maxf(b.z, 0.0001) / maxf(a.z, 0.0001)))


## Whether a fighter this pane is for would be outside its picture, less a pad of TRAVEL_PAD of the width, in camera `cam`: the
## pane's own half in a split (the anchor's distance to the nearer side of the screen), the whole screen in one view.
func _subject_leaving(S: SimState, i: int, cam: Vector3) -> bool:
	var subj: Array = []
	if sep < 0.5 or (e > 0.5 and e_slot == i):
		subj = [0, 1] if (sep < 0.5 and solo_slot < 0) else ([solo_slot] if solo_slot >= 0 else [i])
	else:
		subj = [i]
	var pad: float = CamParams.TRAVEL_PAD * vw
	var split_w: float = _smootherstep(sep) * (1.0 - clampf(e, 0.0, 1.0))
	var a: Vector2 = _anchors[i]
	var half: float = lerpf(0.5 * vw, minf(a.x, vw - a.x), split_w)
	var cx: float = lerpf(0.5 * vw, a.x, split_w)
	for k in subj:
		var f = S.fighters[int(k)]
		var ps: Vector2 = SplitFrame.project(cam.x, cam.y, cam.z, _pitch_now, vw, vh, f.x, f.y + CamParams.CHEST, float(f.z) - float(_fzo[i]))
		if absf(ps.x - cx) > half - pad or ps.y < pad or ps.y > vh - pad:
			return true
	return false


func _pane_shown(i: int) -> bool:
	if i == 0:
		return not (sep > 0.001 and e >= 0.999 and sliver <= 0.0 and e_slot == 1)
	return sep > 0.001 and not (e >= 0.999 and sliver <= 0.0 and e_slot == 0)


## The rule: whatever moves a pane's picture (a follow, a pan, a zoom, a re-frame, a pane opening or closing, a rush's
## follow), the displayed camera never moves it by more than TRAVEL_MAX of the screen's width in a tick (TRAVEL_MAX_REDUCED under
## reduced flashing or motion). The check counts a change when a quarter of a window of pixels turns by a tenth of the
## luminance within a second, and a picture that sweeps at 0.1 of its width a tick does that on every tick it sweeps;
## scenery at 0.045 does not, in the clips measured. Where the limited camera would put a subject outside his picture the
## budget's camera is left to bring him back (the HUD's edge arrow points at him), and the pane cuts to the target, with the
## cut dip asking the register, only when he has been gone for TRAVEL_WAIT, or at once when a layout change is opening a pane
## for him; at most once in TRAVEL_COOL. A cut costs a flash, a subject off the screen none (measured: a cut added a pair of
## 25,000 to 50,000-pixel changes to a clip that passed). A cut, a pane that is hidden, a first frame, a cut-in's camera, a
## composed intro, the fold and a zip are not limited.
func _travel_budget(S: SimState) -> void:
	if not travel_budget:
		for i in range(2):
			_od[i] = _outs[i]
			_od_shown[i] = _pane_shown(i)
			_tgt_prev[i] = _outs[i]
			_scr[i] = 0.0 if not _od_valid else absf(SimWrap.sdx(float(_od_before[i].x), float(_outs[i].x))) * float(_outs[i].z) * 1024.0 / maxf(vw, 1.0)
			_od_before[i] = _outs[i]
		_od_valid = true
		return
	var b: float = CamParams.TRAVEL_MAX_REDUCED if (reduced_motion or flash_reduced) else CamParams.TRAVEL_MAX
	var pm: float = _punch_mult()   # drawn after the filters (a 6-tick punch would be smoothed away), so it is in the picture: and in the budget
	for i in range(2):
		var o: Vector3 = _outs[i]
		var tgt: Vector3 = Vector3(o.x, o.y, o.z * pm)
		var tgt_full: Vector3 = tgt
		var shown: bool = _pane_shown(i)
		var t_t: float = _travel(_tgt_prev[i], tgt) if _od_valid else 0.0
		_od_before[i] = _od[i]
		# Not limited: a first frame, a pane that was hidden, a cut, a cut-in's own camera, a composed intro (authored shots, not
		# in the required clips), the fold's wide shot (a relocation across the planet) and a zip (the camera holds a frame box
		# there: what moves is the zipper, and its flash is the register's `zip_break`).
		if not (_od_valid and shown and bool(_od_shown[i]) and not _cut_now and _ov_kind == "" and not intro_active and not fold_active and _lg_slot < 0 and not _lg_rel):
			_od[i] = tgt
		else:
			var pd: Vector3 = _od[i]
			# The drawn zoom also keeps the comfort rate when it catches up with a target it was held back from.
			var zc_cap: float = (CamParams.SLAM_ZOOM_RATE if _slam_slot >= 0 and e > 0.0 else (CamParams.ZOOM_RATE_TRANS if sep < 0.5 else maxf(_zr_now, float(_zr_pane[i])))) * DT
			var dlz: float = clampf(log(tgt.z) - log(pd.z), -zc_cap, zc_cap)
			tgt = Vector3(tgt.x, tgt.y, exp(log(pd.z) + dlz))
			var t: float = _travel(pd, tgt)
			# Catching up with a target that has slowed or stopped goes no faster than TRAVEL_CATCH more than the target moves
			# (a pop on a fighter who has stopped is the camera's, however smooth: the calm-step check's 0.02).
			var b_now: float = minf(b, t_t + CamParams.TRAVEL_CATCH)
			if t > b_now:
				# The step scales together in x, y and ln z; the position term is taken at the limited zoom, so the factor is
				# found in three passes (the second-order error of one is 2 to 3% of the budget at a zoom that is moving).
				var k: float = b_now / t
				var lim: Vector3 = pd
				for _pass in range(3):
					lim = Vector3(SimWrap.wrap(pd.x + SimWrap.sdx(pd.x, tgt.x) * k), pd.y + (tgt.y - pd.y) * k, exp(log(pd.z) + (log(tgt.z) - log(pd.z)) * k))
					var tl: float = _travel(pd, lim)
					if tl <= 0.00001:
						break
					k *= b_now / tl
				lim = Vector3(SimWrap.wrap(pd.x + SimWrap.sdx(pd.x, tgt.x) * k), pd.y + (tgt.y - pd.y) * k, exp(log(pd.z) + (log(tgt.z) - log(pd.z)) * k))
				# A cut and its dip are one flash, and measured it costs one (a pair of changes of 25,000 to 50,000 pixels), where a
				# subject who is off the screen costs none: so the pane waits for the budget's camera to bring him back, and cuts
				# only when he has been gone for TRAVEL_WAIT, or at once when a layout change is opening a pane for him (its
				# target settles, and he is the reason for it). The HUD's edge arrow points at him meanwhile.
				var leaving: bool = _subject_leaving(S, i, Vector3(lim.x, lim.y, lim.z))
				_tb_lost[i] = float(_tb_lost[i]) + DT if leaving else 0.0
				var morphing: bool = sep > 0.001 and sep < 0.999
				var cool: float = CamParams.TRAVEL_COOL_MORPH if morphing else CamParams.TRAVEL_COOL
				var due: bool = leaving and time - float(_tb_cut_t[i]) >= cool and (morphing or float(_tb_lost[i]) >= CamParams.TRAVEL_WAIT)
				if due:
					_cut_now = true
					_cut_dip()
					_tb_cut_t[i] = time
					travel_cuts += 1
					_od[i] = tgt_full
				else:
					_od[i] = lim
					_outs[i] = Vector3(lim.x, lim.y, lim.z / pm)
					_oz[i] = lim.z / pm
					travel_limited += 1
			else:
				_tb_lost[i] = 0.0
				_od[i] = tgt
				_outs[i] = Vector3(tgt.x, tgt.y, tgt.z / pm)
				_oz[i] = tgt.z / pm
		_scr[i] = 0.0 if (_cut_now or not _od_valid or not bool(_od_shown[i])) else absf(SimWrap.sdx(float(_od_before[i].x), float(_od[i].x))) * float(_od[i].z) * 1024.0 / maxf(vw, 1.0)
		_od_shown[i] = shown
		_tgt_prev[i] = tgt_full
	_od_valid = true


static func _smootherstep(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


# ---------------------------------------------------------------------------------------------------- frame

func _mode_name() -> String:
	if fold_active or _ov_kind != "":
		return "solo"
	if _slam_slot >= 0:
		return "slam"
	if swing_t >= 0.0:
		return "swing"
	if solo_kind != "" or (e > 0.001 and sep > 0.001):
		return "solo"
	if sep >= 0.999:
		return "split"
	if sep <= 0.001:
		return "merged"
	return "opening" if split_wanted else "closing"


## The other fighter coming at fighter i, for the HUD's edge marker (the marker is UI's; this is what it says). `aimed`: a
## rush is on at him, and `eta` is its exact time to arrive (the rush's end); otherwise the other fighter is closing fast
## (the smoothed separation rate over INCOMING_MIN_CLOSING) and `eta` is the distance to contact over that rate. `active`
## when aimed, or closing fast and off the pane (not `shown`). `side` is +1 when he is to the right in the world,
## `screen_dir` the unit vector on the screen from the fighter to him (he may be far off it).
func _incoming_for(S: SimState, i: int, f: SplitFrame) -> Dictionary:
	var me = S.fighters[i]
	var other = S.fighters[1 - i]
	var d: float = SimWrap.sdx(me.x, other.x)
	var dist: float = sqrt(d * d + pow(other.y - me.y, 2.0))
	var r = other.rush
	var aimed: bool = r != null and r.tgt == me
	# A lunge's wind-up (he stands still, no rush yet): the countdown starts at the cue, not when he moves.
	var winding: bool = not aimed and r == null and S.T < _lg_strike and ((_lg_slot == 1 - i and _lg_tgt == i) or (_wd_slot == 1 - i and _wd_tgt == i and time <= _wd_until))
	var closing: float = maxf(0.0, -_sep_rate)
	var eta: float = -1.0
	if aimed:
		eta = maxf(0.0, r.end - S.T)
		closing = maxf(closing, maxf(0.0, dist - 150.0) / maxf(eta, DT))
	elif winding:
		aimed = true
		eta = maxf(0.0, _lg_strike - S.T)
	elif closing >= CamParams.INCOMING_MIN_CLOSING:
		eta = maxf(0.0, dist - 150.0) / closing
	var pi: int = i if f.shows(i) else 0   # in one view the screen is pane 0
	var pos: Vector2 = f.screen_pos(pi, other.x, other.y + CamParams.CHEST, float(other.z))
	var shown: bool = pos.x >= 0.0 and pos.x <= vw and pos.y >= 0.0 and pos.y <= vh and f.shows(pi)
	if shown and bool(f.active[0]) and bool(f.active[1]):
		var w1: float = f.weight1(pos)
		shown = (w1 >= 0.5) if pi == 1 else (w1 < 0.5)
	var mine: Vector2 = f.screen_pos(pi, me.x, me.y + CamParams.CHEST, float(me.z))
	var dir: Vector2 = (pos - mine).normalized() if (pos - mine).length() > 1.0 else Vector2(1.0 if d >= 0.0 else -1.0, 0.0)
	# `lost`: the rival is in neither pane (Orb, 2026-10-16: a launched rival flew off the picture and nothing said where he was). The read is active
	# then whether or not he is closing: a rival who flies away, lands far off and gets up is still somewhere the player cannot see.
	var seen: bool = bool(f.hud_anchor(0, other.x, other.y, float(other.z))["visible"]) or bool(f.hud_anchor(1, other.x, other.y, float(other.z))["visible"])
	var lost: bool = not seen
	return {"active": (eta >= 0.0 and (aimed or not shown)) or lost, "aimed": aimed, "eta": eta, "dist_u": dist, "dist_bh": dist / CamParams.BODY_H,
		"closing": closing, "side": 1 if d >= 0.0 else -1, "shown": shown, "lost": lost, "screen_dir": dir}


## The pane's picture's boxes the foreground must open for the action (section 2.1 of docs/camera/city-in-depth.md), as one
## rectangle in pane pixels plus the top of the action in world units. Empty size when the pane is not shown.
func _clear_demand(S: SimState, f: SplitFrame, i: int, region: Rect2) -> Dictionary:
	var subj: Array = [0, 1] if (f.sep < 0.5 and solo_slot < 0) else ([solo_slot] if solo_slot >= 0 else [i])
	var n_base: int = subj.size()
	if many_framing and S.fighters.size() > 2 and solo_slot < 0:
		# the bodies in the framing set are acted on too (one versus many): the shared view's set, or the pane's assigned bodies
		for mk in range(2, mini(S.fighters.size(), 5)):
			var wk: float = float(_many_w[mk]) if f.sep < 0.5 else float(_many_pw[i][mk])
			if wk >= 0.5:
				subj.append(mk)
	var box: Rect2 = Rect2()
	var have: bool = false
	var y_top: float = -1.0e9
	var h_ref: float = 0.0
	var pts: Array = []
	for k in subj:
		var fk = S.fighters[int(k)]
		var pos: Vector2 = f.screen_pos(i, fk.x, fk.y + CamParams.CHEST, float(fk.z))
		var h: float = maxf(f.apparent_height(i, fk.x, fk.y, float(fk.z)), 8.0)
		h_ref = maxf(h_ref, h)
		pts.append([pos, h])
		# where he is going on the screen: his step this tick (camera and body together), a few ticks ahead
		var kk: int = int(k)
		if bool(_cl_pc_ok[i]) and _cl_pc_slot[i] == kk:
			var vstep: Vector2 = pos - Vector2(_cl_pc[i])
			if vstep.length() < 0.5 * vw:
				pts.append([pos + vstep * CamParams.CLEAR_LEAD_TICKS, h])
		if n_base == 1 or kk == 0:
			_cl_pc[i] = pos
			_cl_pc_slot[i] = kk
			_cl_pc_ok[i] = true
		y_top = maxf(y_top, fk.y + 1.2 * CamParams.BODY_H)
		if fk.state == "launched":
			for tt in [0.25, 0.5]:
				var lx: float = SimWrap.wrap(fk.x + float(fk.vx) * float(tt))
				var ly: float = fk.y + float(fk.vy) * float(tt)
				pts.append([f.screen_pos(i, lx, ly + CamParams.CHEST, float(fk.z)), h])
				y_top = maxf(y_top, ly + 1.2 * CamParams.BODY_H)
	# the strip between the fighters: in one view the two chests; in a split, his own toward the rival, to the pane's edge
	if n_base == 2:
		pass   # both boxes are in pts; the bounding rectangle spans the gap
	elif n_base == 1 and f.sep >= 0.5:
		var rv = S.fighters[1 - i]
		var rp: Vector2 = f.screen_pos(i, rv.x, rv.y + CamParams.CHEST, float(rv.z))
		var own: Vector2 = pts[0][0]
		var d: Vector2 = rp - own
		var maxlen: float = CamParams.CLEAR_ROOM * region.size.x
		if d.length() > maxlen:
			d = d.normalized() * maxlen
		pts.append([own + d, float(pts[0][1])])
	# beams in flight: the polyline's two ends (a beam is straight)
	for b in S.beams:
		var bx0: float = float(b.ox)
		var by0: float = float(b.oy)
		var bx1: float = SimWrap.wrap(bx0 + float(b.ux) * float(b.len))
		var by1: float = by0 + float(b.uy) * float(b.len)
		pts.append([f.screen_pos(i, bx0, by0, float(b.oz)), h_ref])
		pts.append([f.screen_pos(i, bx1, by1, float(b.oz) + float(b.zs) * float(b.len)), h_ref])
		y_top = maxf(y_top, maxf(by0, by1))
	# a zip's frame box
	if _lg_slot >= 0 or _lg_rel:
		var cx: float = _lg_mid + float(_lg_f[0])
		var hw: float = 0.5 * float(_lg_f[1])
		var cy: float = float(_lg_f[2])
		var hh: float = 0.5 * float(_lg_f[3])
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				pts.append([f.screen_pos(i, SimWrap.wrap(cx + sx * hw), cy + sy * hh, 0.0), h_ref])
		y_top = maxf(y_top, cy + hh)
	for pe in pts:
		var c: Vector2 = pe[0]
		var hp: float = float(pe[1])
		var half: Vector2 = Vector2(0.3 * hp, 0.5 * hp) + Vector2.ONE * (CamParams.CLEAR_PAD * hp)
		var r: Rect2 = Rect2(c - half, half * 2.0)
		box = r if not have else box.merge(r)
		have = true
	return {"box": box, "have": have, "y_top": y_top, "h": h_ref}


func _make_clear(S: SimState, f: SplitFrame, i: int, two_up: bool) -> Dictionary:
	var shown: bool = bool(f.active[i])
	if not shown:
		_cl_have[i] = false
		_cl_shown_prev[i] = false
		_cl_hold[i] = 0.0
		_cl_sigma[i] = 0.0
		return {}
	# the pane's own room on the screen: the part of the screen on its side of the divider (and the blend across the
	# feather), as a box; the whole screen in one view
	var split_w: float = _smootherstep(sep) * (1.0 - clampf(e, 0.0, 1.0)) if two_up else 0.0
	var region: Rect2 = Rect2(Vector2.ZERO, Vector2(vw, vh))
	if split_w > 0.0 and bool(f.active[0]) and bool(f.active[1]):
		var side: float = 1.0 if i == 1 else -1.0
		var pts: Array = [Vector2(0.0, 0.0), Vector2(vw, 0.0), Vector2(vw, vh), Vector2(0.0, vh)]
		var kept: Array = []
		for k in range(4):
			var p0: Vector2 = pts[k]
			var p1: Vector2 = pts[(k + 1) % 4]
			var d0: float = side * (p0 - f.c).dot(f.n) + f.feather
			var d1: float = side * (p1 - f.c).dot(f.n) + f.feather
			if d0 >= 0.0:
				kept.append(p0)
			if (d0 >= 0.0) != (d1 >= 0.0):
				kept.append(p0.lerp(p1, d0 / (d0 - d1)))
		if kept.size() >= 3:
			var lo: Vector2 = kept[0]
			var hi: Vector2 = kept[0]
			for q in kept:
				lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
				hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
			region = Rect2(lo, hi - lo)
	var dm: Dictionary = _clear_demand(S, f, i, region)
	var target: Rect2 = Rect2()
	var hole_r: float = float(f.cutaway[i].get("radius_px", 0.0))
	if bool(dm["have"]):
		target = dm["box"]
	# the floor: today's hole round each subject (the rectangle is never smaller)
	if hole_r > 0.0:
		var fl: Vector2 = f.screen_pos(i, S.fighters[i].x, S.fighters[i].y + CamParams.CHEST, float(S.fighters[i].z))
		var fr: Rect2 = Rect2(fl - Vector2.ONE * hole_r, Vector2.ONE * hole_r * 2.0)
		target = fr if target.size == Vector2.ZERO else target.merge(fr)
	# the lead: toward where the action goes, by its speed times CLEAR_LEAD, at most CLEAR_LEAD_MAX of the width
	if _cl_have[i] and target.size != Vector2.ZERO:
		var drift: float = (target.get_center().x - _cl_rect[i].get_center().x) if _cl_rect[i].size != Vector2.ZERO else 0.0
		var lead: float = clampf(drift * CamParams.CLEAR_LEAD * 60.0, -CamParams.CLEAR_LEAD_MAX * region.size.x, CamParams.CLEAR_LEAD_MAX * region.size.x)
		if lead > 0.0:
			target.size.x += lead
		else:
			target.position.x += lead
			target.size.x -= lead
	target = target.intersection(region) if target.size != Vector2.ZERO else target
	var jump: bool = _cut_now or not _cl_have[i] or not bool(_cl_shown_prev[i]) or _cl_rect[i].size == Vector2.ZERO
	var r_now: Rect2 = _cl_rect[i]
	var grew: bool = false
	if jump or target.size == Vector2.ZERO:
		r_now = target
		_cl_hold[i] = 0.0 if jump else float(_cl_hold[i])
		grew = jump
	else:
		# the rectangle may grow by its pane's own growth too (the divider sweeping over the picture while the panes open),
		# never by more than CLEAR_GROW of the screen's width in a tick
		var reg_p: Rect2 = _cl_reg[i] if _cl_reg[i].size != Vector2.ZERO else region
		var g_cap: float = CamParams.CLEAR_GROW * vw
		var g: float = CamParams.CLEAR_GROW * region.size.x
		var g_l: float = minf(g_cap, g + maxf(0.0, reg_p.position.x - region.position.x))
		var g_r: float = minf(g_cap, g + maxf(0.0, region.end.x - reg_p.end.x))
		var sh: float = CamParams.CLEAR_SHRINK * region.size.x
		var can_shrink: bool = float(_cl_hold[i]) >= CamParams.CLEAR_HOLD
		var x0: float = r_now.position.x
		var x1: float = r_now.end.x
		var y0: float = r_now.position.y
		var y1: float = r_now.end.y
		var t0: float = target.position.x
		var t1: float = target.end.x
		var u0: float = target.position.y
		var u1: float = target.end.y
		if t0 < x0:
			x0 = maxf(t0, x0 - g_l)
			grew = true
		elif t0 > x0 and can_shrink:
			x0 = minf(t0, x0 + sh)
		if t1 > x1:
			x1 = minf(t1, x1 + g_r)
			grew = true
		elif t1 < x1 and can_shrink:
			x1 = maxf(t1, x1 - sh)
		if u0 < y0:
			y0 = maxf(u0, y0 - g)
			grew = true
		elif u0 > y0 and can_shrink:
			y0 = minf(u0, y0 + sh)
		if u1 > y1:
			y1 = minf(u1, y1 + g)
			grew = true
		elif u1 < y1 and can_shrink:
			y1 = maxf(u1, y1 - sh)
		r_now = Rect2(Vector2(x0, y0), Vector2(x1 - x0, y1 - y0))
	# the hold clock: it runs while nothing asked for more room, restarts at every growth
	if grew:
		_cl_hold[i] = 0.0
	elif target.size != Vector2.ZERO and r_now.encloses(target):
		_cl_hold[i] = float(_cl_hold[i]) + DT
	var p: float = (r_now.size.x * r_now.size.y) / maxf(region.size.x * region.size.y, 1.0) if r_now.size != Vector2.ZERO else 0.0
	var sig_t: float = smoothstep(CamParams.CLEAR_P0, CamParams.CLEAR_P1, p)
	var sig: float = float(_cl_sigma[i])
	if jump:
		sig = sig_t
	elif sig_t > sig:
		sig = minf(sig_t, sig + DT / CamParams.CLEAR_SINK)
	elif sig_t < sig and float(_cl_hold[i]) >= CamParams.CLEAR_HOLD and not grew:
		sig = maxf(sig_t, sig - DT / CamParams.CLEAR_STAND)
	_cl_sigma[i] = sig
	_cl_rect[i] = r_now
	_cl_reg[i] = region
	_cl_have[i] = true
	_cl_shown_prev[i] = true
	# world x of the rectangle's sides at the focus plane
	var z_i: float = maxf(f.cam_z[i], 0.0001)
	var wx0: float = SimWrap.wrap(f.cam_x[i] + (r_now.position.x - vw * 0.5) / z_i)
	var wx1: float = SimWrap.wrap(f.cam_x[i] + (r_now.end.x - vw * 0.5) / z_i)
	return {
		"rect": r_now, "region": region, "p": p, "sigma": sig, "y_top": float(dm["y_top"]), "x0": wx0, "x1": wx1,
		"holding": float(_cl_hold[i]) < CamParams.CLEAR_HOLD, "cut": jump, "hole": hole_r,
	}


func _make_frame(S: SimState) -> SplitFrame:
	var f := SplitFrame.new()
	f.vw = vw
	f.vh = vh
	f.mode = _mode_name()
	f.sep = sep
	f.e = e
	f.e_slot = e_slot
	f.sliver = sliver if e_slot >= 0 else 0.0
	f.many_off = _many_marks.duplicate(true)
	f.theta = theta
	f.n = Vector2(cos(theta), sin(theta))
	var hn: float = _half_extent_along_n(f.n)
	var delta: float = 0.0
	if e_slot >= 0:
		delta = e * hn * (1.0 - 2.0 * sliver) * (1.0 if e_slot == 0 else -1.0)
	f.c = Vector2(vw * 0.5, vh * 0.5) + f.n * delta
	var ss: float = _smootherstep(sep)
	f.gap = maxf(CamParams.GAP_MIN_PX, CamParams.GAP_FRAC * vw)
	f.feather = CamParams.FEATHER_FRAC * vw * (1.0 - ss) if swing_t < 0.0 else 0.0
	# The feathered sweep (a switch, off by default): while the panes open or close the blend between them is wide, so what changes
	# on the screen in a tick changes by little at a time (a cross-fade of the two pictures, not an edge crossing them).
	if swing_t < 0.0 and sep > 0.001 and sep < 0.999 and (feather_mode == 2 or (feather_mode == 1 and (reduced_motion or flash_reduced))):
		f.feather = maxf(f.feather, CamParams.SWEEP_FEATHER_FRAC * vw * sin(PI * sep))
	f.line_alpha = smoothstep(0.0, 0.45, sep)
	for i in range(2):
		f.cam_x[i] = _outs[i].x
		f.cam_y[i] = _outs[i].y
		f.cam_z[i] = _outs[i].z * _punch_mult()   # after the filters: a 6-tick punch would be smoothed away
		var a_rep: Vector2 = _anchors[i]
		if _anchors_rep_ok and not _cut_now:
			var d_rep: Vector2 = a_rep - Vector2(_anchors_rep[i])
			var lim_rep: float = CamParams.ANCHOR_REPORT_STEP * vw
			if d_rep.length() > lim_rep:
				a_rep = Vector2(_anchors_rep[i]) + d_rep.normalized() * lim_rep
		_anchors_rep[i] = a_rep
		f.anchor[i] = a_rep
		f.ring[i] = SimWrap.wrap(S.fighters[i].x) / SimConst.W * TAU
		if pane_request_fn.is_valid():
			var req = pane_request_fn.call(i)
			if req is Dictionary and req.has("kind"):
				f.kind[i] = String(req["kind"])
	_anchors_rep_ok = true
	f.swing = swing_t
	f.sigma = sigma_shown
	f.held_u = u
	f.flash = _flash
	f.slam = _slam_done
	f.shake = _shk.duplicate()
	f.pitch = _pitch_now
	f.focus_z = PackedFloat64Array([float(_fzo[0]), float(_fzo[1])])
	f.panel = _panel_frame(S)
	f.fade = clampf(_cut_fade / (CamParams.REDUCED_CUT_FADE if reduced_motion else CamParams.CUT_FADE), 0.0, 1.0) if _cut_fade > 0.0 else 0.0
	_slam_done = false
	# Which panes must be rendered.
	var show0: bool = true
	var show1: bool = sep > 0.001
	if show1 and e >= 0.999 and sliver <= 0.0:
		if e_slot == 0:
			show1 = false
		elif e_slot == 1:
			show0 = false
	f.active = [show0, show1]
	if many_framing and S.fighters.size() > 2 and sep >= 0.5:
		# in a split view a body is off the frame when neither pane shows him (the merged set's list is for the one view)
		var marks: Array = []
		for mk in range(2, mini(S.fighters.size(), 5)):
			var mg = S.fighters[mk]
			var seen: bool = false
			for pi in range(2):
				if bool(f.hud_anchor(pi, mg.x, mg.y, float(mg.z))["visible"]):
					seen = true
			if not seen:
				var np: int = 0 if absf(SimWrap.sdx(f.cam_x[0], mg.x)) <= absf(SimWrap.sdx(f.cam_x[1], mg.x)) else 1
				marks.append([mk, 1 if SimWrap.sdx(f.cam_x[np], mg.x) >= 0.0 else -1])
		f.many_off = marks
	var two_up: bool = show0 and show1
	for ci in range(2):
		var cf = S.fighters[ci]
		var h_px: float = f.apparent_height(ci, cf.x, cf.y, float(cf.z))
		var rad: float = maxf(CamParams.CUTAWAY_MIN_PX, CamParams.CUTAWAY_K * h_px)
		if solo_kind == "transform" and _tf_phase == "break" and _tf_ver == "full" and not _tf_calm:
			rad = maxf(rad, CamParams.CUTAWAY_BREAK_R * vh)   # keep the silhouette against the sky clear of a house in front
		f.cutaway[ci] = {"request": _ov_kind != "smash", "radius_px": rad, "only": ci if two_up else -1}
	for ci in range(2):
		f.clear[ci] = _make_clear(S, f, ci, two_up)
	f.incoming = [_incoming_for(S, 0, f), _incoming_for(S, 1, f)]
	# The scenery's speed across each pane (the governor's own measure, units a second eased), in px a tick at 1024 wide: the
	# shared camera's in one view. A fast pursuit past lit windows strobes the facades; Rendering fades their contrast with this.
	var scale_px: float = DT * 1024.0 / maxf(vw, 1.0)
	var sc_m: float = _vsm_m * f.cam_z[0] * scale_px
	if travel_budget:
		f.scroll = [float(_scr[0]), float(_scr[1])]   # what the pane's picture did this tick (the displayed camera's), not what the focus did
	else:
		f.scroll = [lerpf(float(_vsm[0]) * f.cam_z[0] * scale_px, sc_m, 1.0 - _smootherstep(sep)), lerpf(float(_vsm[1]) * f.cam_z[1] * scale_px, sc_m, 1.0 - _smootherstep(sep))]
	if _ov_kind != "":
		# A cut-in is one view: it draws its own camera over both panes, so the frame says one view with no divider. The
		# layout itself goes on deciding underneath (holding it let a fighter fly 6,000 units away during a cut-in and
		# the layout come back merged and wrong: an 8-screen jump), and the cut at the cut-in's end shows the result.
		f.sep = 0.0
		f.e = 0.0
		f.sliver = 0.0
		f.line_alpha = 0.0
		f.active = [true, false]
		f.swing = -1.0
	f.cut = false
	return f
