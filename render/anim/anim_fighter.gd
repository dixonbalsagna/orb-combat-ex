class_name AnimFighter
extends RefCounted
## The animator of one fighter (slice A1 of docs/animation/pose-pipeline.md): from the sim's state and events it solves a
## pose on rig R1 once a frame, and every pane's mannequin is written from it. Key poses come from data/anim/; between
## them it does the timing, easing, lag, overshoot and reactions. Render only: it reads the sim (fighter state, the running
## exchange's beats, events) and never writes it, draws no sim random numbers, and moves no anchor: a strike's contact
## pose lands on the beat's own time.
##
## The provisional part cue (until Combat's composer emits one): the running exchange is read straight from
## S.dirS.ex.beats. Its `strike` beats say when each blow lands and who throws it, its `rush` beats when a fighter
## closes, and every beat is scheduled before it fires, so the wind-up can start early enough. The pose layers, in order:
##   base (state, stance, movement, smoothed) -> cue pose -> approach or strike part -> beam -> reaction -> drift,
##   shiver and spring chains on the extras.
## What is not here yet (later slices): IK to the defender's socket and the ground, situation adaptation, the style
## modifier stack, inertialisation across parts, interpolation between tick states.

const DT := 1.0 / 60.0
const STANCES := ["aggressive", "defensive", "evasive", "escape"]

var slot: int = 0
var q: Array[Quaternion] = []
var hips := Vector3.ZERO
var curl := Vector2.ZERO
var root_off := Vector3.ZERO
var gq: Array[Quaternion] = []
var gp := PackedVector3Array()
var frame: int = -1
var version: int = 0                   # bumped by every real solve; a body skips its bone writes when it has this one
var _lag_k: float = -1.0
var _settle: int = 0
var _bkey: int = -1
var _bkey2: int = -1
var _was_down: bool = false              # polish: a get-up after a fall (the rise out of the crouch is slower when worn)
var _rise_t0: float = -1.0
var _rise_dur: float = 0.3
var _air_w: float = 0.0                  # hovering, for the bob
var _lean: float = 0.0                  # the lean into acceleration, smoothed (rad)
var _prev_x: float = 0.0
var _have_x: bool = false
var _prev_cx: float = 0.0
var _smear: float = 0.0                 # the contact catch: how far behind the anchor the body is drawn (model units), decaying
var _smear_t0: float = -10.0
var press: Dictionary = {}             # press styles (docs/animation/press-styles.md): the style of the blow playing and where it is, for VFX (empty when none)
var _gest: Dictionary = {}              # an intro gesture playing: {id, t0, dur, w, mask (group names), pose (a single pose, not a sequence)}
var riposte: Dictionary = {}           # a riposte blow playing (press-styles.md section 12): {kind light or heavy, reversal, sure, ticks_to_contact}, for VFX; empty when none
var _rip_cue: Dictionary = {}          # the riposte cue's word (kind, the tick it came, ticks ahead): shown to VFX until the blow's own beat takes over
var _stag_t0: float = -10.0            # when a stagger cue last played his stagger (the old stunTicks watch yields to it)
var zip: Dictionary = {}               # the LT zip (docs/animation/zip.md): its phase and look for VFX, empty when no zip is playing
var zip_path: Array = []               # where the zipping body was over the last solves: {T, x, y, phase}, newest last (the path of the body for the blur)
var _zip: Dictionary = {}              # the zip told to this body (AnimZip.start), cleared when it is over
var _zh: Dictionary = {}               # held by a zip (carried, lifted): {kind, t0, dur}
var _zip_tilt: float = 0.0             # the body turned along its path (rad), smoothed
var _zip_dy: float = 0.0               # the lifted fighter's cosmetic rise (model units)
var _zip_phase: String = ""
var zip_cue: Dictionary = {}              # the plan the last zip_light or zip_heavy cue announced: {kind, tell, in, dur, reach_before, reach_after, T} (VFX, Camera)
var zip_exit: Dictionary = {}             # the last zip_out cue: {kind, x, y, out, reading, T}
var _drop: Dictionary = {}                # a drop in progress: {t0, landed}
var _zip_end: Dictionary = {}           # the zip_end cue's word for the live zip: {reason, T}
var _zip_last_end: String = ""         # how the last live zip ended (for VFX and the tests)
var _zip_depth: float = 0.0            # a pass: how far toward the camera the body is drawn (model units), render only
var _zblend: Dictionary = {}           # the carry from the last zip pose into the next pose: {t0, n, q, hips, curl}
var _zq: Array[Quaternion] = []        # the last zip pose (solved each tick of a live zip)
var _zh0 := Vector3.ZERO
var _zc0 := Vector2(0.5, 0.5)
var press_ring: Array = []             # the last solved poses while a styled blow plays, newest last: {T, q, hips, root_off}: the afterimages (press_pose)
var press_path: Array = []             # the striking limb's tip over the same solves (model space, root_off included), newest last: {T, tip}
var _ci_latch: Array = [Vector2.ZERO, Vector2.ZERO]   # the contact point a styled blow landed on (the first limb, the second), kept through the hold
var _ci_latch_tc: Array = [-1.0, -1.0]
var _pr_cache: Dictionary = {}         # blow id -> its press style, decided the first time the blow is seen
var _pr_dx: float = 0.0                # the body drawn this far ahead (model units): the wind-up's lean back, the release's lunge
var _pr_q: Array[Quaternion] = []      # the pose of the last styled solve (before the contact solve) ...
var _pr_hips := Vector3.ZERO
var _pr_curl := Vector2.ZERO
var _pr_T: float = -10.0
var _pr_blow: int = -1
var _pc_q: Array[Quaternion] = []      # ... and the one the previous blow ended on, which a blow with `carry` blends out of
var _pc_hips := Vector3.ZERO
var _pc_curl := Vector2.ZERO
var _pc_ok: bool = false
var _full_fk: bool = false
const _LEG_BONES := [16, 17, 19, 20]                  # thigh_l, shin_l, thigh_r, shin_r
const LEG_CHAIN := [0, 1, 16, 17, 18, 19, 20, 21]   # root, pelvis, thigh, shin, foot of each leg
const SOCKET_CHAIN := [0, 1, 2, 3, 4, 5, 11, 12, 13, 14]   # root, pelvis, spines, neck, head, near clavicle, arm, forearm, hand
const SPINE_CHAIN: Array = [0, 1, 2, 3, 4, 5]   # root, pelvis, spine_1, spine_2, neck, head: the flight lead reads the spine
const SOCKET_SET := ["root", "pelvis", "spine_1", "spine_2", "neck", "head", "clavicle_r", "upper_arm_r", "forearm_r", "hand_r"]

var _base: Array[Quaternion] = []
var _base_hips := Vector3.ZERO
var _base_curl := Vector2(0.5, 0.5)
var _tq: Array[Quaternion] = []
var _last_T: float = -1.0
var _cue: Dictionary = {}
var _seq: Dictionary = {}          # a pose sequence of Encounter's step 3 cues (data/anim/waves/step3.*): {id, t0, dur}
var _gc_hold_t0: float = -1.0           # a held ground-contact pose (the brace of a tumble) from this time ...
var _ag_sq: Dictionary = {}            # the agency slice's own sequence (the embed: its own, so a ground contact's sequence at the same tick cannot replace it)
var _lead_w: float = 0.0               # the flight lead (docs 9.23): how hard it is chasing its aim now, and the turn it holds (a world angle added to the sim's own, radians)
var _lead_d: float = 0.0
var _seq_next: Dictionary = {}          # the sequence that follows `_seq` when it ends (the ceiling's slam, then its rebound)
var _gr: Dictionary = {}                # the clinch's hold read (on_hold): partner, kind, role, grade, side, grips
var _gr_w: float = 0.0                 # the hold's weight now: in over ramp_ticks, out over the same
var _rc: Dictionary = {}                # the recoil exit playing (on_recoil): kind, t0, dur, cfg, seq, the surface's normal
var _fid: String = ""                 # this body's roster id, kept from the ragdoll's tick (for the per-fighter sequences)
var _ack: Dictionary = {}               # the press-tick anticipation playing (on_press_ack): pose, weight, start, hold, end, the hits taken at the start
var _str_w: float = 0.0                # the beam struggle's dig-in: how far he is being pushed back (0 to 1), eased
var _str_lead: float = 0.0             # ... and how far he is winning (0 to 1)
var _str_slide: float = 0.0            # ... and how far the drawn body has been dragged back along the ground, in model units
var _gr_gs: float = 0.0               # the grip's grade as drawn, eased a step at a time (five stages)
var _gr_pm_side: int = 0              # which hand the next pummel swims in with (alternates)
var _rv_last: String = ""                # the variant the last blow picked (the next one never does)
var _ar_prev: String = ""                # the state at the last solve (the air recovery watches a launch end)
var _ar_t0: float = -10.0               # when the air recovery began
var _ar_p: float = 0.0                  # how hard he was going (0.3 to 1)
var _ar_side: float = 1.0
var _ar_speed: float = 0.0              # the speed he had in the launch, decaying
var _fw_x := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])   # follow-through: head, upper back, forearms (angle and speed)
var _fw_v := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _fw_vw := Vector2.ZERO
var _fw_have: bool = false
var _fw_src: Dictionary = {}   # the follow-through data the tables below were read from, and the fighter they were read for (`_fw_read`): the data does not change in a match, so a tick reads arrays, not dictionaries
var _fw_fid: String = ""
var _fw_n: int = 0
var _fw_ref0: float = 1.0
var _fw_ref1: float = 1.0
var _fw_scale: float = 1.0
var _fw_damp: float = 1.0
var _fw_force_ref: float = 1.0
var _fw_gx: Array = []
var _fw_gy: Array = []
var _fw_stiff: Array = []
var _fw_dmp: Array = []
var _fw_max: Array = []
var _fw_hit: Array = []
var _fw_bone: Array = []
var _fw_arm: Array = []
var _pop: Dictionary = {}                # the pop phase now (kind, t0, dur, amt, set)
var _pop_pw: Dictionary = {}             # the pop's pose weights, each moved toward its target
var _pop_cap: Dictionary = {}            # the most each pose has been asked for (a ramp is 6 or more ticks from nothing to that)
var _gl_act: float = 0.0               # ground locomotion: how far it is on, eased
var _gl_have: bool = false
var _gl_grounded: bool = true
var _gl_prev_vy: float = 0.0
var _gl_ph: float = 0.0                # the gait's phase, in cycles
var _gl_gw: float = 0.0                # how much gait is on (by speed), eased
var _gl_to_t0: float = -10.0           # the kick-off's start and weight
var _gl_to_p: float = 0.0
var _gl_ld_t0: float = -10.0           # the landing's start, weight, surface row and the way he was going
var _gl_ld_p: float = 0.0
var _gl_ld_row: String = "soil"
var _gl_ld_dir: float = 0.0
var _gl_surface_override: String = ""
var _lo_act: float = 0.0               # flight locomotion: how far it is on (it stands aside while he is busy), eased
var _lo_have: bool = false
var _lo_vf: float = 0.0                # the forward speed at the last solve
var _lo_hd: float = 0.0                # the velocity's heading at the last solve
var _lo_af: float = 0.0                # the forward acceleration, filtered
var _lo_om: float = 0.0                # the heading's turn rate, filtered
var _lo_lean: float = 0.0              # the lean spring's position (1 is the full lean) and speed
var _lo_lv: float = 0.0
var _lo_flare: float = 0.0
var _lo_bank: float = 0.0
var _lo_dash: bool = false
var _lo_dash_t0: float = -10.0
var _ab_on: bool = false                # the sim's air brake is on (an air_brake event)
var _ab_w: float = 0.0                 # the skid's weight now: in over enter_ticks, out over exit_ticks
var _ab_str: float = 0.0               # how hard it is from the deceleration he shows (0 to 1)
var _ab_speed: float = -1.0
var _ab_aim: float = 0.0               # the lean the flight lead is to turn the body to while it brakes (screen radians, against the velocity)
var _lead_vm := Vector2.ZERO           # his velocity as measured over the last sim tick, and where he was
var _lead_px: float = 0.0
var _lead_py: float = 0.0
var _lead_tk: int = -1
var pair_key: String = ""              # the launch-pair fighter this body plays as (data/anim/fighters.json: protagonist, antihero), "" for none (docs/animation/pair-live.md)
var _taunt_last: String = ""           # the last far taunt gesture he played (never the same one twice running)
var _taunt_n: int = 0                  # how many far taunts he has played this match
var _taunt_id: String = ""             # the far taunt gesture playing (his own, or the shared shrug)
var _en_pose: String = ""              # the energy layer's held pose (a charge, a release, a shot into a crater ...), eased in and out like the agency hold
var _en_prev: String = ""              # ... the pose it took over from, crossfaded over 0.08 s
var _en_sw: float = -10.0
var _en_t0: float = -1.0
var _en_t1: float = -1.0               # (-1: open, a charge held until the shot, a cancel or the cap)
var _en_in: float = 0.1
var _en_out: float = 0.15
var _en_w: float = 0.9
var _en_last_bolt: int = -100000       # the tick of his last bolt: a bolt inside the spray gap of it is a spray beat
var _ag_hold: String = ""              # the agency slice's held pose (a knockback, a charge: docs 9.22) from _ag_t0 ...
var _ag_kind: String = ""              # ... of this kind (a key of data/anim/agency.json)
var _ag_t0: float = -1.0
var _ag_t1: float = -1.0               # ... until this time (-1: until the exchange, a fall or the cap ends it)
var _ag_w: float = 0.0
var _ag_in: float = 0.1
var _ag_out: float = 0.15
var _ag_fast: bool = false             # the charge hold was ended by a launch or a fall: it lets go in a few ticks, not in 0.15 s (the lean of a charge does not ride a flight)
var _ls_t0: float = -1.0               # the last stand's window open from this time (the held resolve), -1 when closed ...
var _ls_t1: float = -1.0               # ... and closed at this time (the resolve fades out)
var _intro: Dictionary = {}           # the opening, from the sim's events: {on, fall_t, fall_dur, land_t, stare_t, stare_dur} (seconds on the sim's tick)
var _gc_hold_w: float = 0.5            # how much of the pose the brace is (set when it starts: firmer when slow and unworn, looser when fast and worn)
var _gc_hold_t1: float = -1.0           # ... until this one (-1 while it lasts)
var _stun_prev: int = 0
var _stun_watch: int = 0           # ticks left to see this fighter staggered after a perfect block or a reversal (a DEFLECT staggers nobody)
var _stun_seq: String = ""
var _stun_t0: float = 0.0
var _shove_watch: int = 0          # ticks left to see the burst shove this fighter (a jump in his own speed)
var _shove_vx: float = 0.0
var _reacts: Array = []
var _sx := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0])
var _sv := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0])
var _spring_dt: float = 0.0
var _spring_bones := PackedInt32Array()
var _lag := PackedFloat32Array()
var _prof: Dictionary = {}
var _part: String = ""                 # the key set playing this frame, "" for none (for tools)
var debug := {"contact_frames": 0, "contact_err_max": 0.0, "parts": 0, "nan": 0, "ik_frames": 0, "gap_max": 0.0, "gap_sum": 0.0, "gap_n": 0, "face_flips": 0, "gaps": [], "notes": [], "blows": 0, "late": 0, "late_notes": [], "variants": {}, "wound_strikes": 0, "wound_bad": 0, "skims": 0, "ground_events": 0, "rd_ticks": 0, "rd_usec": 0, "catches": 0, "slope_frames": 0, "aims": 0, "pre_brace": 0, "near_miss": 0, "guard_kicks": 0, "personality": 0, "feet_usec": 0, "feet_n": 0, "survey": 0, "ko_falls": 0, "leans": 0, "overcommits": 0, "blocked": 0, "turn_steps": 0, "bursts": 0, "brakes": 0, "shocks": 0}

## The facing the mannequin is drawn with (-1 or 1). The sim's `face` can lag a dodge warp or a swap of sides, so this one
## is derived from the opponent in an exchange and from the travel direction otherwise (A2, docs/animation section 9.3).
var vface: float = 1.0
var _face_key: int = -1
var _face_init: bool = false
var _face_want_t: float = -1.0
const IDLE_FAR := 700.0               # an idle fighter farther than this from the opponent relaxes
const FACE_DEAD := 14.0                # closer than this (on the shortest arc) the opponent gives no side
const FACE_HOLD := 0.03                # a new side must hold this long (s) before the turn starts
const TRAVEL_FACE := 250.0             # free of an exchange, faster than this faces the travel direction
const NEAR_LOOK := 900.0               # an idle fighter this close looks at the opponent

# the blow being thrown this frame, for the contact solve: weight, limb, target region, mirror, the defender
# Inertialisation (A2): when the solved pose jumps (a part starts or ends, a cue or a reaction lands, a mirrored key set
# follows its other-side twin), the jump is taken as an offset that decays over a short eased time, so nothing pops and the new
# pose is reached by itself. The offset is dropped on a blow's contact frame, so the contact key stays exact.
const INERTIA_JUMP := 0.5              # rad: a bone turning more than this in one solve is a join
const INERTIA_SNAPPY := 0.1            # s, how long a join takes to settle on a snappy fighter
const INERTIA_FLUID := 0.18
var _ip_raw: Array[Quaternion] = []
var _ip_off: Array[Quaternion] = []
var _ip_hraw := Vector3.ZERO
var _ip_hoff := Vector3.ZERO
var _ip_cur: Array[Quaternion] = []
var _ip_hcur := Vector3.ZERO
var _ip_t: float = 0.0
var _ip_acc: float = 0.0              # tick time since the last solve; a hit-stop still lets a join settle, at half speed
var _ip_dur: float = 0.1
var _ip_active: bool = false
var _ip_have: bool = false
var _ip_cos: float = cos(INERTIA_JUMP * 0.5)
# The active ragdoll (overhaul unit A): stepped once per sim tick from the fighter's own state, shown at out_w.
var _rd := AnimRagdoll.new()
var _rd_tier_tk: int = -1000              # the tick the ragdoll's tier and mass were last read
var _rd_flights: int = 0               # RG0: how many flights this body has begun (with the slot and the launch number, the seed of the flail)
var _rd_prev_flying: bool = false
var _rd_rot: float = 0.0                # the body's last turn (the sim's rot): the side of a hit is judged against it
var _rd_have: bool = false
var _rd_vw := Vector2.ZERO              # last tick's world velocity (for the acceleration)
var _rd_prev_state: String = ""
var _rd_prev_slide: bool = false
var _rd_prev_speed: float = 0.0
var _skim_t0: float = -1.0
var _shape_set: bool = false
var _skip_inertia: bool = false
var _blow_snap: bool = false             # this solve is the snap of a blow into its contact key: the authored jump, not a join to settle
var _lean_id: int = -1                  # the dodge already leaned away from
var _over_id: int = -1                  # the whiff already over-committed on
var _lean_t0: float = -10.0             # sim time of the lean-away, the over-commit and the blocked recoil
var _over_t0: float = -10.0
var _block_t0: float = -10.0
var _bank: float = 0.0                 # roll into a turn (flight overhaul, unit G), smoothed
var _burst_t0: float = -10.0           # a dash start and a stop: when they were seen (sim time)
var _brake_t0: float = -10.0
var _shock_t0: float = -10.0           # a nearby impact: when, and how hard
var _shock_amp: float = 0.0
var _gait_speed: float = 0.0
var _turn_t0: float = -10.0            # a turn-around is a step: when the visual facing last flipped, and to which side
var _turn_dir: float = 1.0
var _stance_prev: int = -1
var _base_r := PackedFloat32Array()
var _hit_w: float = 0.0                 # how much of the fighter's own flinch shape is pulled in after a hit (decays)
var _hit_crum: float = 0.0              # ... and how much of it is the crumple (a heavy blow) rather than the brace (a light one)
var _miss_id: int = -1                  # the last near miss flinched at
var _sp_vw := Vector2.ZERO
var _sp_have: bool = false
var _look_target: float = 0.0
var _look: float = 0.0                 # the head's pitch toward the opponent, smoothed
var _leg_dq: Array[Quaternion] = []
var _leg_tick: int = -10
var _gf_gtick: int = -100
var _gf_gx: float = 0.0
var _gf_g0c: float = 0.0
var _gf_x_valid: bool = false
var _gf_x: float = 0.0
var _gf_face: float = 1.0
var _gf_tick: int = -100
var _gf_g0: float = 0.0
var _gf_dF: float = 0.0
var _gf_dB: float = 0.0
var _gf_sl: float = 0.0
var _foot_w: float = 0.0               # how much the feet are placed on a slope now (eases in and out)
var _foot_shift: float = 0.0           # the pelvis shift of the last placement (for tools)
var _foot_dh := Vector2.ZERO           # the ground under each foot relative to under him (for tools)
var _skid_pitch: float = 0.0
var _hit_n: int = 0                     # hits taken (the variant hash)
var _stop_pk: float = 0.0                # the longest hit-stop seen in this freeze, in seconds (the shake scales by its weight)
var _shake_t0: float = -10.0            # sim time of the last blow that carried no hit-stop of its own (a mash's later blows): the drawn-only shake keyed to the contact
var _shake_k: float = 0.0               # its strength, 0 to 1 of the profile's shiver
var _hit_free: float = 0.0              # how loose a hit leaves the limbs; decays, slower with wear
var layers: String = ""                # tools: which layers shaped this frame (set only with debug_checks)
var _rushing: bool = false
var _contact_now: bool = false
# Battle damage (rule-of-cool feature 1), read from the wounds state the sim already has: how worn the fighter is (breathing),
# how close to the brink (the stagger and the sagging stance), and whether the arms or the legs are broken (one arm hangs, one
# leg is favoured; which one is a hash of the fighter's slot, since the sim keeps no side).
var _worn: float = 0.0
var _brinkp: float = 0.0
var audit: Dictionary = {}               # joint audit (RenderAnim.joint_audit): stage -> the violations found there (A before the contact solve, B after it, C after the ragdoll, D after every layer)
var _arm_broken: bool = false
var _leg_broken: bool = false
var _hang_right: bool = false
var _leg_right: bool = false
var _form: Dictionary = {}           # the running transformation: {t0, version}
var _seen_tc: int = -1
var _cx_n: int = -1                  # the parried exchange whose parry time is remembered
var _cx_t: float = 0.0               # ... its exchange time when the parry was first seen
var _tc_left: float = -1.0            # seconds to the next blow's contact, -1 when none is coming
var _ci_w: float = 0.0
var _ci_limb: String = "hand_r"
var _ci_target: String = "chest"
var _ci_side: bool = false
var _ci_limb2: String = ""             # a second striking limb of a two-limb blow (a key set's limb2), or ""
var _ci_step: float = -1.0              # the key set's own step-in limit (model units), or -1 for the limb's default in sockets.json
var launcher: Dictionary = {}              # the launcher's signal (cue launcher_open): {role: "target" or "actor", n: the tick the stagger ends, text: the stagger's kind, T}; empty once it closes
var windup_cue: Dictionary = {}            # the last `windup` cue (text start or end): {text, source, dur, n, k, T}: what the sim says this fighter's wind-up is and how it ended
var miss_cue: Dictionary = {}              # the last `miss` cue: {text, n (the ticks he is open), T}
var energy_cue: Dictionary = {}            # the last energy_reach or energy_land cue: {kind, text, x, y, k, T}
var double_cue: Dictionary = {}            # the last double_hit cue: {n (the tick the two blows land), bits (who is hit), T}
var hold_coil: float = 0.0               # how far a held heavy has loaded beyond its own wind-up (0 to 1; the tools and VFX read it)
var _held_ks: String = ""                # the wound blow whose wind-up was last drawn (key set, mirrored side, style): what a hold past its landing keeps showing
var _held_side: bool = false
var _held_style: String = ""
var armoured: bool = false               # a heavy is winding or charging in him: set by the dispatch just before a hit (a light barely moves him)
var charge_full_t: float = -1.0          # the time of the charge's flash (cue charge_full): the held coil trembles from there
var depth_on: bool = false               # a match with depth on (S.depthOn): everything below is 0 and idle without it
var depth_yaw: float = 0.0               # the body's turn about the vertical (radians, eased): positive turns his front toward the camera, toward the rival's depth, so the line reads as an angle; Rendering turns the body by it (AnimBody.set_yaw)
var depth_line: float = 0.0              # the pair's line from the street, in degrees (positive: the rival is nearer the camera)
var depth_vz: float = 0.0                # his speed in depth, units a tick (positive: toward the camera)
var _dz_prev: float = 0.0
var _dz_tick: int = -1
var _stride: float = 0.0                 # footfall phase of a step in depth
var waiting_kind: String = ""            # what a body that is in the fight and not the partner is doing (circle, guard, step_in, settle, flinch); "" with two bodies or in his own exchange
var _chase_t: float = -1.0
var _row_cache: Dictionary = {}          # a style's row as this fighter plays it (`_style_row`), by style
var _pin_until: float = -1.0             # the time the plain light's pin on the rival ends (its contact plus the pin): read by the rival's hit, which hangs for the rest of it
var hand_shine: float = 0.0              # the striking hand's shine while a held hit's window is open (0 to 1; VFX and Rendering draw it) and which limb
var hand_shine_limb: String = ""
var tech_cue: float = -1.0               # the time of the last air tech (cue `tech`)
var chase_state: String = ""             # "", start, blow, end: the chase's cue (cue `chase`), for the body and for VFX
var cast: Dictionary = {}                # the beam being cast now: {state: charge or fire, pose, w, bone} (the beam layer's own pose; `cast_origin()` is where it leaves); empty when none
var chase_n: int = 0                     # the number of the chase's blow now (1 to 6, from the cue's `k`)
var chase_tick: int = 0                  # the contact tick of the last `blow` or `arrive` (the cue's `n`, an absolute tick)
var _chase_arrived_t: float = -1.0       # the time of the `arrive` cue: the dive eases out over 4 ticks after it
var interject: Dictionary = {}           # a ring guard's interjection, from its windup cue: {land, dur}
var _cash_in_now: bool = false
var _mr_blow: int = -1                   # the march's memory: the blow being drawn, the contact of this one and of the one before
var _mr_cur_tc: float = -1.0
var _mr_prev_tc: float = -1.0
var press_lean: float = 0.0              # the mash's forward lean this solve (radians; debug and tests)
var _sl_prev: Array = []                 # the free arm's last drawn upper-arm and forearm rotations (`_free_arm_slew`)
var _sl_have: bool = false
var _wing_w: Array = [0.0, 0.0]          # how far each free arm is drawn to the guard now (`_free_arm_slew`)
var press_bob: float = 0.0               # the mash's beat this solve: how far the pelvis is dipped on the blow (units; debug and tests)
var march_w: float = 0.0                 # the mashed heavy's footfall pulse this solve (0 to 1; debug and tests)
var dig_w: float = 0.0                   # the held X's dig-in weight this solve (debug and tests)
var burst_set: float = 0.0               # how far the burst's set pose is laid over the body this tick (0 to 0.9; VFX and the tools read it)
var _ci_step_k: float = 1.0                # the share of that step a medium on 12 ticks takes (Combat's w6: a half step)
var _ci_opp = null
var _ci_tc: float = 0.0
var _ci_dmg: float = 0.0
var _gap_tc: float = -1.0
var _recoil_y: float = 0.0
var _recoil_x: float = 0.0
var _step_x: float = 0.0               # the step-in a blow takes toward a defender beyond the arm and the hips' lunge


func _init(slot_: int) -> void:
	slot = slot_
	_hang_right = (_hash(slot_, 11, 3) & 1) == 0
	_leg_right = (_hash(slot_, 12, 5) & 1) == 0
	q = AnimPose.identity_q()
	_base = AnimPose.identity_q()
	_tq = AnimPose.identity_q()
	gq.resize(AnimRig.N)
	gp.resize(AnimRig.N)
	for nm in ["x_pack", "x_sash_a1", "x_sash_a2", "x_sash_b1", "x_sash_b2"]:
		_spring_bones.append(AnimRig.index[nm])
	_lag.resize(AnimRig.N)


# ------------------------------------------------------------------ events (called once a tick by RenderAnim)

func on_tick(dt: float, frozen: bool, S: SimState = null, f = null) -> void:
	_spring_dt += dt * (0.1 if frozen else 1.0)
	_ip_acc += dt * (0.5 if frozen else 1.0)
	if S != null and f != null:
		update_face(S, f)   # the facing is decided once per sim tick too, so everything keyed on it replays
		_wound_read(f)   # the wear is read on the tick too (it was read at solve time, so at two ticks a frame the first tick stepped the ragdoll on the last tick's wear)
		# a stagger with no cue of its own (the 12 ticks a blocked string leaves its attacker, the loser of a finisher's set-up): a short one
		var sn: int = int(f.stunTicks)
		if sn > 0 and _stun_prev == 0 and RenderAnim.step3_cues and _seq.is_empty() and _stun_watch == 0 and f.state == "free" and AnimData.entries.has("s3.stagger_short"):
			_seq = {"id": "s3.stagger_short", "t0": S.T, "dur": clampf(float(sn), 8.0, 30.0) / 60.0}
			debug["step3"] = int(debug.get("step3", 0)) + 1
		_stun_prev = sn
		if _stun_watch > 0:
			_stun_watch -= 1
			if S.T - _stag_t0 < 0.5:
				_stun_watch = 0   # the stagger cue has played it, fitted to its ticks: the watch yields
			elif int(f.stunTicks) > 0 and AnimData.entries.has(_stun_seq):
				_seq = {"id": _stun_seq, "t0": _stun_t0, "dur": float(AnimData.entries[_stun_seq].dur) / 60.0}
				debug["step3"] = int(debug.get("step3", 0)) + 1
				_stun_watch = 0
		if _shove_watch > 0:
			_shove_watch -= 1
			if absf(f.vx - _shove_vx) > 250.0 and AnimData.cue_map.has("burst") and AnimData.entries.has(String(AnimData.cue_map.burst.get("other_if_shoved", ""))):
				var sid2: String = String(AnimData.cue_map.burst.other_if_shoved)
				_seq = {"id": sid2, "t0": S.T, "dur": float(AnimData.entries[sid2].dur) / 60.0}
				_shove_watch = 0
		# a change of stance kicks the arms toward the new guard on the tick it happens (it was read at solve time, so a change on an odd tick
		# came a tick late at two ticks a frame and the ragdoll state differed)
		var st_now: int = clampi(int(f.stance), 0, 3)
		if _stance_prev != st_now:
			if _stance_prev >= 0 and RenderAnim.layer("transitions"):
				_stance_kick(_stance_prev, st_now)
			_stance_prev = st_now
		_spring_tick(S, f, dt, frozen)
		_follow_tick(S, f, dt, frozen)
		if not frozen:
			_rd_tick(S, f, dt)
			if RenderAnim.layer("look"):
				_look_tick(S, f, dt)


## A crater was dug near him (the sim's crater event): a hover shudders and the arms start; amp 0 to 1 from the energy and the distance.
func on_shock(T: float, amp: float) -> void:
	if amp <= 0.02:
		return
	_shock_t0 = T
	_shock_amp = minf(1.0, _shock_amp * exp(-(T - _shock_t0) / 0.5) + amp)
	var a: float = _rd_amp() * amp
	_rd.kick(2, 4.0 * a)
	_rd.kick(5, 4.0 * a)
	_rd.kick(1, -2.0 * a)
	_rd.out_w = 1.0
	debug["shocks"] += 1


## A launched fighter skipped off water (the sim's skim event): the body arches and flares for an instant.
func on_skim(T: float, spd: float) -> void:
	_skim_t0 = T
	var amp: float = _rd_amp()
	_rd.kick(0, 5.0 * amp)
	_rd.kick(1, 6.0 * amp)
	_rd.kick(2, -4.0 * amp)
	_rd.kick(5, -4.0 * amp)
	debug["skims"] += 1


## World's ground-contact events (left_ground, bounce, land, tumble_end; docs/world/ground-contact.md section 4). They plug
## into the same body: a bounce whips it by the normal speed, a slam or a skid folds it, the end of a tumble lets it go.
## The agency slice's events (data/anim/agency.json): a knockback holds a pose for as long as he is sent back, the embed plays its sequence over the held-down
## ticks, the far taunt a shrug over the flight, the charges a held flight pose until the exchange starts; a feint peels off (docs/director/agency-slice-3.md).
func on_agency(kind: String, T: float, e: Dictionary) -> void:
	var A: Dictionary = AnimData.agency
	if not RenderAnim.agency_poses or A.is_empty():
		return
	var wt: float = 0.6 if RenderAnim.reduced_motion else 1.0
	# the cues that end a taunt (his dodge cut it, it was answered, it took off into a charge) or a charge (the dodge-cancel, a meeting in the middle) at once
	if A.get("taunt", {}).get("cut_kinds", []).has(kind) and _is_taunt(String(_seq.get("id", ""))):
		_seq = {}
	if A.get("charge", {}).get("end_kinds", []).has(kind) and _ag_kind.begins_with("charge_") and _ag_t1 < 0.0:
		_ag_t1 = T
		return
	match kind:
		"knockback":
			var kk: Dictionary = A.get("knockback", {}).get(String(e.get("kind", "slideShort")), {})
			if kk.is_empty() or not AnimData.pose_exists(String(kk.hold)):
				return
			_ag_hold = String(kk.hold)
			_ag_fast = false
			_ag_kind = "knockback"
			_ag_t0 = T
			_ag_t1 = T + clampf(float(e.get("dur", 0.5)), 0.1, 3.0)
			_ag_w = float(kk.weight) * wt
			_ag_in = float(kk.get("in", 0.08))
			_ag_out = float(kk.get("out", 0.15))
			debug["agency"] = int(debug.get("agency", 0)) + 1
		"embed":
			var em: Dictionary = A.get("embed", {})
			if AnimData.entries.has(String(em.get("seq", ""))):
				# starts after the landing's own bounce (the first tenth of a second), and runs to the end of the held-down time
				var dur: float = maxf(float(e.get("dur", 1.0)) - 0.12, 0.3)
				_ag_sq = {"id": String(em.seq), "t0": T + 0.12, "dur": dur, "wt": float(em.get("weight", 1.0)) * wt}
				debug["agency"] = int(debug.get("agency", 0)) + 1
		"taunt_start":
			var tn: Dictionary = A.get("taunt", {})
			var tid: String = String(tn.get("seq", ""))
			var gest: Array = AnimData.pair.get("roles", {}).get(pair_key, {}).get("taunts", []) if (RenderAnim.pair_live and pair_key != "") else []
			if not gest.is_empty():   # his own far taunts (docs/animation/pair-live.md): the first of a stand-off is his first gesture; after that one he may use, by a hash of the tick, never the same twice running
				var air: bool = bool(e.get("air", false))
				var first: String = String(AnimData.pair.get("roles", {}).get(pair_key, {}).get("taunt_first", ""))
				var gid: String = ""
				if first != "" and _taunt_n == 0 and not bool(e.get("traded", true)) and AnimData.entries.has(first):
					gid = first
				else:
					var elig: Array = []
					for g in gest:
						var gate: String = String(AnimData.entries.get(String(g), {}).get("_gate", ""))
						if (gate == "ground" and air) or (gate == "air" and not air) or (String(g) == _taunt_last and gest.size() > 1):
							continue
						elig.append(String(g))
					if not elig.is_empty():
						gid = String(elig[_hash(int(T * 60.0), slot, 29) % elig.size()])
				if gid != "" and AnimData.entries.has(gid):
					tid = gid
					_taunt_last = gid
					_taunt_n += 1
			if AnimData.entries.has(tid):
				_taunt_id = tid
				_seq = {"id": tid, "t0": T, "dur": float(AnimData.entries[tid].dur) / 60.0, "wt": float(tn.get("weight", 0.7)) * wt}
				debug["agency"] = int(debug.get("agency", 0)) + 1
		"charge_light", "charge_heavy", "charge_feint":
			var which: String = kind.substr(7)
			var cc: Dictionary = A.get("charge", {}).get(which, {})
			if cc.is_empty() or not AnimData.pose_exists(String(cc.hold)):
				return
			_ag_hold = String(cc.hold)
			_ag_fast = false
			_ag_kind = "charge_" + which
			_ag_t0 = T
			_ag_t1 = (T + float(cc.ticks) / 60.0) if cc.has("ticks") else -1.0
			_ag_w = float(cc.weight) * wt
			_ag_in = float(cc.get("in", 0.1))
			_ag_out = float(cc.get("out", 0.15))
			debug["agency"] = int(debug.get("agency", 0)) + 1


## Recoil exits and ricochets (docs/combat/choreography-feel.md sections 1 and 2; data/anim/recoil.json). Encounter's cue `recoil` names the kind and the landing tick: the shapes of the body play as a sequence in the body's own frame
## and this layer turns the whole body over about its middle, lifts it along an arc and lands it. The sim's knock-back is the path; the layer only turns and lifts the drawn body, and never moves a position.
func on_recoil(kind: String, ticks: int, T: float, nx: float = 0.0, ny: float = 1.0) -> void:
	var R: Dictionary = AnimData.recoil
	if R.is_empty() or not RenderAnim.recoil_flips or ticks < 4:
		return
	var cfg: Dictionary = R.get("kinds", {}).get(kind, {})
	if cfg.is_empty():
		return
	var seq: String = String(R.get("fighters", {}).get(_fid, {}).get(kind, cfg.get("seq", "")))
	if not AnimData.entries.has(seq):
		return
	_rc = {"kind": kind, "t0": T, "dur": float(ticks) * DT, "cfg": cfg, "seq": seq, "nx": nx, "ny": ny}
	_rd.out_w = 1.0
	debug["recoils"] = int(debug.get("recoils", 0)) + 1


## True while an exit is drawn (the lead layer stands aside, the lead scan reads it).
func recoiling() -> bool:
	return not _rc.is_empty()


func _recoil_layer(S: SimState, f, dt: float) -> void:
	if _rc.is_empty():
		return
	var R: Dictionary = AnimData.recoil
	var T: float = S.T
	var u: float = (T - float(_rc.t0)) / maxf(float(_rc.dur), 0.001)
	if u >= 1.0 or R.is_empty() or not RenderAnim.recoil_flips:
		_rc = {}
		return
	u = clampf(u, 0.0, 1.0)
	var cfg: Dictionary = _rc.cfg
	_entry_layer(float(_rc.t0), float(_rc.dur), String(_rc.seq), T, DT, 1.0, true)
	var turns: float = float(cfg.get("turns", 0.0))
	var phi: float = 0.0
	var arc: float = float(cfg.get("arc", 0.0))
	if RenderAnim.reduced_motion:
		turns = 0.0
		arc *= 0.4
	if turns > 0.0:
		# a back flip: the head goes back first (the model's own positive turn about z), eased in and out so the take-off and the landing are slow and the middle quick
		phi = turns * TAU * smoothstep(0.0, 1.0, u)
	elif cfg.has("plant") and not RenderAnim.reduced_motion:
		# a ricochet: the body turns so its feet face the surface along the normal (the surface's normal points out toward him), then springs back upright
		var pl: float = float(cfg.plant)
		var nx: float = float(_rc.nx)
		var ny: float = float(_rc.ny)
		var to: float = atan2(-nx, ny) * vface * 1.2
		phi = to * (smoothstep(0.0, pl, u) - smoothstep(pl + 0.08, 1.0, u))
	var py: float = float(R.get("pivot_y", 34.0))
	if absf(phi) > 0.0005:
		q[0] = Quaternion(Vector3(0, 0, 1), phi) * q[0]
		root_off += Vector3(py * sin(phi), py * (1.0 - cos(phi)), 0.0)
	root_off.y += arc * sin(PI * u)
	_lead_d = 0.0
	_lead_w = 0.0


## The press-tick anticipation (docs/animation/press-ack.md; data/anim/press_ack.json). A player's press that has to wait (a cooldown after an exchange) is acknowledged by the sim on its own tick (Encounter's cue press_ack,
## text queued): the body commits at once, the first frames of a wind-up mixed over the idle stance at a part weight, and hands over to the real wind-up when the exchange starts. It carries no information the sim doesn't
## (nothing is drawn on the fighters): the lean, the weight shifted forward or sunk, the shoulder turning in.
func on_press_ack(cell: String, n: int, wait: int, T: float) -> void:
	var A: Dictionary = AnimData.press_ack
	if A.is_empty() or not RenderAnim.press_ack:
		return
	if wait >= 0 and wait < int(A.get("min_wait", 3)):
		return   # the exchange starts before it could read
	var cfg: Dictionary = A.get("cells", {}).get(cell, {})
	if cfg.is_empty():
		return
	var id: String = String(A.get("fighters", {}).get(_fid, {}).get(cell, cfg.get("pose", "")))
	if not AnimData.pose_exists(id):
		return
	var hold_ticks: int = wait if wait >= 0 else int(A.get("max_ticks", 36))
	_ack = {"pose": id, "w": float(cfg.get("w", 0.6)), "t0": T, "hold": float(hold_ticks) * DT, "end": -1.0, "hits": _hit_n, "wind": float(windup_cue.get("T", -10.0))}
	debug["acks"] = int(debug.get("acks", 0)) + 1


## The mid-band lunge's wind-up crouch (docs/animation/lunge-crouch.md; data/anim/press_ack.json `lunge`). The sim reacts to a press from 225 units or more on the press tick (a rush event, the cue lunge_light or lunge_heavy with `amount` the
## wind-up's ticks, press_ack started) and the body moves only when the wind-up ends: light 6 ticks, heavy 10, and 10 for the return from a send. No pose drew that crouch. Here the cell's pose (the press-ack's, the fighter's own) deepens over
## the cue's own ticks and is let go over `exit_ticks` as the travel starts (the layer ends when the rush begins), so the body hands over to the lunge with no snap. A shorter wind-up than 6 ticks is drawn over 6 (the crouch overlaps the travel's first ticks, handed over by the exit ramp: the snappy profile solves on twos, so a ramp under 6 reads as a snap); under 3 ticks nothing is drawn.
func on_lunge_crouch(weight: String, wind: int, T: float) -> void:
	var A: Dictionary = AnimData.press_ack
	if A.is_empty() or not RenderAnim.press_ack or wind < 3:
		return
	var L: Dictionary = A.get("lunge", {}).get(weight, {})
	if L.is_empty():
		return
	var cell: String = String(L.get("cell", "x"))
	var id: String = String(A.get("fighters", {}).get(_fid, {}).get(cell, A.get("cells", {}).get(cell, {}).get("pose", "")))
	if not AnimData.pose_exists(id):
		return
	_ack = {"pose": id, "w": float(L.get("w", 0.9)), "t0": T, "hold": float(wind) * DT, "enter": float(maxi(wind, 6)) * DT, "end": -1.0, "hits": _hit_n, "wind": float(windup_cue.get("T", -10.0))}
	debug["lunge_crouches"] = int(debug.get("lunge_crouches", 0)) + 1


## Flight locomotion (docs/animation/flight-locomotion.md; data/anim/locomotion.json). A free fighter moves with weight: an acceleration lean on a spring that overshoots (the shoulders lead, the pelvis, neck and head follow), a braking
## flare when he stops hard from speed, a dash's anticipation (a short coil with the weight back, which the surge then carries forward), a bank into a curve and a hover that breathes. Everything is read from the sim's velocity, the dash
## input and the height above the ground; nothing is written. Every ramp is 6 ticks or more (the snappy profile solves on twos: a shorter ramp reads as a snap). It stands aside while the fighter is in an exchange, a lock, a rush, a hold,
## a recoil or a launch (they draw the body themselves) and eases away over `enter_ticks` rather than cutting.
func _loco_layer(S: SimState, f, dt: float) -> void:
	var L: Dictionary = AnimData.locomotion
	if L.is_empty() or not RenderAnim.flight_loco:
		_lo_act = 0.0
		return
	var T: float = S.T
	var ex = S.dirS.ex
	var busy: bool = f.state != "free" or f.rush != null or (ex != null and (ex.A == f or ex.D == f)) or f.beamCharge != null or not _gr.is_empty() or not _rc.is_empty() or not _ack.is_empty()
	var adv: bool = dt > 0.0005   # a frame with no sim time passing draws the state as it is and moves nothing (a 144 Hz view solves several times a tick)
	var dts: float = maxf(dt, 0.0005)
	_lo_act = move_toward(_lo_act, 0.0 if busy else 1.0, dt * 60.0 / maxf(float(L.get("enter_ticks", 8)), 6.0))
	var vf: float = f.vx * vface
	var vy: float = f.vy
	var speed: float = Vector2(vf, vy).length()
	var first: bool = not _lo_have
	var af: float = 0.0 if first else (vf - _lo_vf) / dts
	var heading: float = atan2(vy, vf) if speed > 60.0 else _lo_hd
	var om: float = 0.0
	if not first and speed > 60.0:
		om = wrapf(heading - _lo_hd, -PI, PI) / dts
	if adv:
		_lo_vf = vf
		_lo_hd = heading
		_lo_have = true
	var Ln: Dictionary = L.lean
	var lk: float = 1.0 - exp(-dts / maxf(float(Ln.get("filter_s", 0.05)), 0.005))
	if adv:
		_lo_af += (af - _lo_af) * lk
		_lo_om += (om - _lo_om) * lk
	# the dash: the press starts a short coil with the weight back, which the surge's own forward lean then takes over
	var dash_on: bool = bool(f.input.dash) if f.input != null else false
	if dash_on and not _lo_dash:
		_lo_dash_t0 = T
	_lo_dash = dash_on
	var D: Dictionary = L.dash
	var dt_n: float = (T - _lo_dash_t0) / (maxf(float(D.get("dash_ticks", 8)), 6.0) * DT)
	var pre: float = smoothstep(0.0, 0.75, dt_n) * (1.0 - smoothstep(0.75, 1.6, dt_n)) if (_lo_dash_t0 > -5.0 and dt_n < 1.7) else 0.0
	# the lean spring: forward acceleration pitches the torso forward, braking back; underdamped, so the lean overshoots as the speed settles
	var tgt: float = clampf(_lo_af / float(Ln.get("acc_ref", 2600.0)), -1.0, 1.0) - float(D.get("lean_back", 0.5)) * pre
	var FPx: Dictionary = L.get("fighters", {}).get(_fid, {})   # his own: the Protagonist floaty (a softer damping, more overshoot), the Anti-hero crisp
	var stiff: float = float(Ln.get("stiff", 110.0))
	var damp: float = float(Ln.get("damp", 9.0)) * float(FPx.get("damp", 1.0))
	if adv:
		_lo_lv += (-stiff * (_lo_lean - tgt) - damp * _lo_lv) * dts
		_lo_lean += _lo_lv * dts
	var calm: float = 0.5 if RenderAnim.reduced_motion else 1.0
	var ix: Dictionary = AnimRig.index
	var a: float = _lo_act
	var lv: float = clampf(_lo_lean, -1.5, 1.5)
	if lv < 0.0:
		lv *= float(Ln.get("back_scale", 0.75))   # braking leans back less than accelerating leans forward
	var lean_rad: float = deg_to_rad(float(Ln.get("max_deg", 11.0))) * lv * a * calm * float(FPx.get("lean", 1.0))
	# forward is a negative turn about z in the model (the hair streams back on a positive one): the shoulders lead
	var lag: Dictionary = Ln.get("lag", {})
	q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), -lean_rad * 0.4)
	q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), -lean_rad * 0.55)
	q[ix["pelvis"]] = q[ix["pelvis"]] * Quaternion(Vector3(0, 0, 1), -lean_rad * float(lag.get("pelvis", -0.22)))
	q[ix["neck"]] = q[ix["neck"]] * Quaternion(Vector3(0, 0, 1), lean_rad * float(lag.get("neck", 0.25)))
	q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 0, 1), lean_rad * float(lag.get("head", 0.3)))
	hips.y -= float(D.get("dip", 2.4)) * pre * a * calm
	# the braking flare: stopping hard from speed throws the legs forward and the arms out (the brake skid's own pose, a part weight)
	var Fl: Dictionary = L.flare
	var flare_t: float = 0.0
	if vf > float(Fl.get("min_speed", 330.0)) and _lo_af < -float(Fl.get("brake_ref", 1800.0)):
		flare_t = smoothstep(float(Fl.get("brake_ref", 1800.0)), 2.0 * float(Fl.get("brake_ref", 1800.0)), -_lo_af)
	_lo_flare = move_toward(_lo_flare, flare_t, dt * 60.0 / maxf(float(Fl.get("ticks", 8)), 6.0))
	if _lo_flare > 0.002 and AnimData.pose_exists(String(Fl.get("pose", ""))):
		_mix_pose(AnimData.pose(String(Fl.pose)), float(Fl.get("w", 0.45)) * _lo_flare * a * calm)
	# the bank: the velocity's heading turning rolls the body about its forward axis and leans it into the turn
	var B: Dictionary = L.bank
	var bank_t: float = clampf(_lo_om / float(B.get("omega_ref", 3.2)), -1.0, 1.0) * smoothstep(float(B.get("min_speed", 280.0)) * 0.6, float(B.get("min_speed", 280.0)) * 1.6, speed)
	_lo_bank = move_toward(_lo_bank, bank_t, dt * 60.0 / 8.0)
	var roll: float = deg_to_rad(float(B.get("roll_deg", 12.0))) * _lo_bank * a * calm
	if absf(roll) > 0.0005:
		q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(1, 0, 0), roll * 0.5)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(1, 0, 0), roll * 0.6)
		q[ix["pelvis"]] = q[ix["pelvis"]] * Quaternion(Vector3(1, 0, 0), -roll * 0.35)
		q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(1, 0, 0), -roll * 0.5)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), -absf(roll) * float(B.get("lean_in", 0.35)))
	# the hover breathes: the chest and the shoulders rise and settle, the head eases against them, the hips float, at his own rate and depth
	var H: Dictionary = L.hover
	var g: float = WorldWater.floorAt(S, f.x, f.z)
	var airborne: float = smoothstep(float(H.get("off_ground", 8.0)) * 0.5, float(H.get("off_ground", 8.0)) * 2.0, f.y - g)
	var still: float = 1.0 - smoothstep(float(H.get("still_speed", 140.0)) * 0.5, float(H.get("still_speed", 140.0)), speed)
	var hv: float = still * airborne * a
	if hv > 0.002:
		var FP: Dictionary = L.get("fighters", {}).get(_fid, {})
		var rate: float = float(H.get("rate_hz", 0.3)) * float(FP.get("rate", 1.0))
		var depth: float = float(FP.get("depth", 1.0)) * hv * calm
		var br: float = sin(T * TAU * rate + float(slot) * 1.7)
		var br2: float = sin(T * TAU * rate * 0.5 + float(slot) * 0.9)
		var ch: float = deg_to_rad(float(H.get("chest_deg", 1.6))) * depth
		q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), -ch * 0.6 * br)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), -ch * br)
		q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 0, 1), ch * 0.7 * br)
		var sh: float = deg_to_rad(float(H.get("shoulder_deg", 2.4))) * depth
		q[ix["clavicle_r"]] = q[ix["clavicle_r"]] * Quaternion(Vector3(0, 0, 1), sh * br)
		q[ix["clavicle_l"]] = q[ix["clavicle_l"]] * Quaternion(Vector3(0, 0, 1), sh * br)
		hips.y += float(H.get("bob", 0.9)) * depth * (br2 * 0.6 + br * 0.4)
	if RenderAnim.debug_checks:
		debug["loco_lean"] = _lo_lean
		debug["loco_flare"] = _lo_flare
		debug["loco_bank"] = _lo_bank
		debug["loco_hover"] = hv


## The surface under a free fighter, as a row of data/anim/ground_motion.json `surfaces`: World's gen 2 look class when WorldContact.lookAt exists (ice, snow, frost, mud, turf, litter, ash, crust, shingle, mapped by `look`), else the
## surface class World already has (WorldContact.surfaceAt: soil, sand, rock, paving, rubble, water).
func _ground_surface(S: SimState, f, G: Dictionary) -> String:
	if _gl_surface_override != "":
		return _gl_surface_override   # a test's, or a study's, own surface
	var look := Callable(WorldContact, "lookAt")
	if look.is_valid():
		var lc: String = String(look.call(S, f.x))
		if G.get("look", {}).has(lc):
			return String(G.look[lc])
		if G.get("surfaces", {}).has(lc):
			return lc
	var sk: String = String(WorldContact.surfaceAt(S, f.x))
	return sk if G.get("surfaces", {}).has(sk) else "soil"


## The pop (docs/animation/pop-juggle.md; data/anim/pop.json). Encounter's cue `pop` (text up, slam, tech, burst, land; the actor the popped fighter, `n` the landing tick, `dur` the ticks up, `amount` the height in body heights).
## The sim's arc carries him; here the body shows the phases of it. `_pop` is the phase now; `_pop_pw` the pose weights, each moved toward its target over `ramp_ticks` (6 or more), so every handover (a phase, a second cue, the end) is smooth.
func on_pop(text: String, n: int, dur: float, amount: float, T: float) -> void:
	var P: Dictionary = AnimData.pop
	if P.is_empty() or not RenderAnim.pop_juggle:
		return
	if text == "tech":
		on_tech(T)   # the air tech's own sequence (rt.air_tech): thrown open, then tucked
		_pop = {}
		return
	_pop = {"kind": text, "t0": T, "dur": maxf(dur, 6.0) * DT, "amt": clampf(amount / maxf(float(P.get("height_ref", 3.0)), 0.1), 0.0, 1.0), "set": n == 1, "spike": text == "land" and amount >= 0.5}
	debug["pops"] = int(debug.get("pops", 0)) + 1


func _pop_layer(S: SimState, f, dt: float) -> void:
	var P: Dictionary = AnimData.pop
	if P.is_empty() or not RenderAnim.pop_juggle:
		_pop = {}
		_pop_pw.clear()
		_pop_cap.clear()
		return
	var want: Dictionary = {}
	if not _pop.is_empty():
		var T: float = S.T
		var kind: String = String(_pop.kind)
		var age: float = T - float(_pop.t0)
		var big: float = 0.6 + 0.4 * float(_pop.amt)
		if kind == "up":
			var u: float = age / float(_pop.dur)
			var U: Dictionary = P.up
			var rs: Dictionary = U.rise
			var ap: Dictionary = U.apex
			var fl: Dictionary = U.fall
			var rise: float = 1.0 - smoothstep(float(rs.to[0]), float(rs.to[1]), u)
			var apex: float = smoothstep(float(ap["in"][0]), float(ap["in"][1]), u) * (1.0 - smoothstep(float(ap.out[0]), float(ap.out[1]), u))
			var fall: float = smoothstep(float(fl.from[0]), float(fl.from[1]), u)
			want[String(rs.pose)] = float(rs.w) * rise * big
			want[String(ap.pose)] = float(ap.w) * apex * big
			want[String(fl.pose)] = float(fl.w) * fall * big
			if u > 1.4:
				_pop = {}
		elif kind == "slam" or kind == "burst" or kind == "spike":
			var K: Dictionary = P.get(kind, {})
			if age < float(K.get("ticks", 8)) * DT:
				want[String(K.pose)] = float(K.w)
			else:
				_pop = {}
		elif kind == "land":
			var K2: Dictionary = P.land.spike if bool(_pop.spike) else (P.land.set if bool(_pop.set) else P.land.reel)
			if age < float(K2.ticks) * DT:
				want[String(K2.pose)] = float(K2.w)
			else:
				_pop = {}
		else:
			_pop = {}
	var bz: float = float(P.get("busy_scale", 0.35)) if not _seq.is_empty() else 1.0   # a beat plays on him (he strikes or guards from the apex): the pop gives way to it
	for wk in want.keys():
		want[wk] = float(want[wk]) * bz
	if f.state == "launched" or f.state == "dropped" or f.state == "down" or f.state == "locked":
		want.clear()   # a launch, a knockdown or a lock has the body
	var step: float = dt * 60.0 / maxf(float(P.get("ramp_ticks", 6)), 6.0)
	var calm: float = 0.6 if RenderAnim.reduced_motion else 1.0
	for pid in want:
		if not _pop_pw.has(pid):
			_pop_pw[pid] = 0.0
		_pop_cap[pid] = maxf(float(_pop_cap.get(pid, 0.0)), float(want[pid]))
	for pid in _pop_pw.keys():
		_pop_pw[pid] = move_toward(float(_pop_pw[pid]), float(want.get(pid, 0.0)), step * maxf(float(_pop_cap.get(pid, 0.5)), 0.2))
		if float(_pop_pw[pid]) <= 0.001 and not want.has(pid):
			_pop_pw.erase(pid)
			_pop_cap.erase(pid)
			continue
		if AnimData.pose_exists(String(pid)):
			_mix_pose(AnimData.pose(String(pid)), float(_pop_pw[pid]) * calm)
	debug["pop_w"] = _pop_pw.size()


## The air recovery (docs/animation/air-recovery.md; data/anim/locomotion.json `recover`). When control comes back in the air (he was launched or dropped and is free again, well off the ground), the body catches itself: the arms fling wide and
## the legs come under (the brake skid's entry pose, a part weight), and the torso rocks once past upright and settles, by how fast he was going. Read from the sim's state and speed; nothing is written. Ramps are 6 ticks or more (the snappy
## profile solves on twos); it stands aside while he is busy and ends over `ticks`.
func _air_recover_layer(S: SimState, f, dt: float) -> void:
	var L: Dictionary = AnimData.locomotion
	var Rc: Dictionary = L.get("recover", {})
	var st: String = String(f.state)
	var T: float = S.T
	if not Rc.is_empty() and RenderAnim.air_recover and st == "free" and (_ar_prev == "launched" or _ar_prev == "dropped") and f.rush == null:
		var g: float = WorldWater.floorAt(S, f.x, f.z)
		var spd: float = Vector2(f.vx, f.vy).length()
		spd = maxf(spd, _ar_speed)
		if f.y - g > float(Rc.get("min_air", 40.0)) and spd > float(Rc.get("min_speed", 250.0)):
			_ar_t0 = T
			_ar_p = clampf(spd / float(Rc.get("ref_speed", 1500.0)), 0.3, 1.0)
			_ar_side = 1.0 if f.spin >= 0.0 else -1.0
	if st == "launched" or st == "dropped":
		_ar_speed = maxf(_ar_speed * pow(0.95, dt * 60.0), Vector2(f.vx, f.vy).length())
	else:
		_ar_speed = _ar_speed * pow(0.95, dt * 60.0)
	_ar_prev = st
	if _ar_t0 < -5.0 or Rc.is_empty():
		return
	var u: float = (T - _ar_t0) / (maxf(float(Rc.get("ticks", 24)), 24.0) * DT)
	if u >= 1.0:
		_ar_t0 = -10.0
		return
	var exr = S.dirS.ex
	var busy: bool = st != "free" or f.rush != null or not _rc.is_empty() or not _ack.is_empty() or (exr != null and (exr.A == f or exr.D == f)) or f.beamCharge != null or not _gr.is_empty()
	if busy:
		_ar_t0 = -10.0
		return
	var env: float = smoothstep(0.0, 0.25, u) * (1.0 - smoothstep(0.25, 1.0, u))
	var calm: float = 0.6 if RenderAnim.reduced_motion else 1.0
	var pid: String = String(Rc.get("pose", ""))
	if AnimData.pose_exists(pid):
		_mix_pose(AnimData.pose(pid), float(Rc.get("w", 0.5)) * env * _ar_p * calm)
	# the torso rocks once past upright and settles
	var rock: float = float(Rc.get("rock", 0.2)) * sin(u * TAU) * (1.0 - u) * _ar_p * calm
	var ix: Dictionary = AnimRig.index
	q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), -rock * 0.5)
	q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), -rock * 0.7)
	q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 0, 1), rock * 0.5)
	q[ix["pelvis"]] = q[ix["pelvis"]] * Quaternion(Vector3(1, 0, 0), rock * 0.35 * _ar_side)
	if RenderAnim.debug_checks:
		debug["ar_env"] = env
		debug["ar_u"] = u


## Ground locomotion (docs/animation/ground-locomotion.md; data/anim/ground_motion.json). A free fighter on the ground walks and runs on a gait (thighs swinging in turn, the swing knee lifting, the hips bobbing, the shoulders against the
## pelvis; a cycle every `stride` units covered, so it follows his speed and his direction), kicks off the ground when he rises from it and absorbs his landing by how fast he arrived and what he arrived on (sand slides and sinks, rock is
## crisp, rubble stumbles, water wades). Read from the sim's velocity and ground; nothing is written. Every ramp is 6 ticks or more (the snappy profile solves on twos). It stands aside while he is in an exchange, a lock, a rush, a hold,
## a recoil, a press-ack or a launch, and eases away over `enter_ticks`.
func _ground_layer(S: SimState, f, dt: float) -> void:
	var G: Dictionary = AnimData.ground_motion
	if G.is_empty() or not RenderAnim.ground_loco:
		_gl_act = 0.0
		return
	var T: float = S.T
	var ex = S.dirS.ex
	var busy: bool = f.state != "free" or f.rush != null or (ex != null and (ex.A == f or ex.D == f)) or f.beamCharge != null or not _gr.is_empty() or not _rc.is_empty() or not _ack.is_empty()
	_gl_act = move_toward(_gl_act, 0.0 if busy else 1.0, dt * 60.0 / maxf(float(G.get("enter_ticks", 8)), 6.0))
	var g: float = WorldWater.floorAt(S, f.x, f.z)
	var grounded: bool = f.y - g < 6.0 and f.state == "free"
	var vy: float = f.vy
	var vf: float = f.vx * vface
	var sp: float = absf(vf)
	var surf_key: String = _ground_surface(S, f, G)
	var SR: Dictionary = G.get("surfaces", {}).get(surf_key, {})
	if _gl_have and not busy:
		var TO: Dictionary = G.takeoff
		var LD: Dictionary = G.land
		if _gl_grounded and not grounded and vy > float(TO.get("min_vy", 150.0)):
			_gl_to_t0 = T
			_gl_to_p = clampf(vy / 1000.0, 0.25, 1.0)
		elif (not _gl_grounded) and grounded and _gl_prev_vy < -float(LD.get("min_vy", 140.0)):
			_gl_ld_t0 = T
			_gl_ld_p = clampf(-_gl_prev_vy / float(LD.get("ref_vy", 1400.0)), 0.12, 1.0)
			_gl_ld_row = surf_key
			_gl_ld_dir = signf(vf) if absf(vf) > 40.0 else 0.0
	_gl_grounded = grounded
	_gl_prev_vy = vy
	_gl_have = true
	var calm: float = 0.5 if RenderAnim.reduced_motion else 1.0
	var a: float = _gl_act * calm
	var ix: Dictionary = AnimRig.index
	var FP: Dictionary = G.get("fighters", {}).get(_fid, {})
	var Gt: Dictionary = G.gait
	# the gait: a phase of the distance covered (signed: backing up runs the cycle the other way)
	var cad: float = float(FP.get("cadence", 1.0))
	# the cycle's rate is capped at 6.5 a second (the bob is twice that, under the 15 Hz the twos solve can show)
	_gl_ph = fposmod(_gl_ph + clampf(vf / maxf(float(Gt.get("stride", 64.0)), 10.0) * cad, -6.5, 6.5) * dt, 1.0)
	var gw: float = smoothstep(float(Gt.get("min_speed", 40.0)), float(Gt.get("full_speed", 130.0)), sp) * (1.0 - smoothstep(float(Gt.get("run_speed", 520.0)), float(Gt.get("max_speed", 900.0)), sp))
	gw *= 1.0 if grounded else 0.0
	_gl_gw = move_toward(_gl_gw, gw, dt * 60.0 / 8.0)
	if _gl_gw > 0.002:
		var u: float = clampf((sp - float(Gt.get("full_speed", 130.0))) / maxf(float(Gt.get("run_speed", 520.0)) - float(Gt.get("full_speed", 130.0)), 1.0), 0.0, 1.0)
		var th: Array = Gt.get("thigh", [0.12, 0.46])
		var kn: Array = Gt.get("knee", [0.4, 1.0])
		var bb: Array = Gt.get("bob", [0.5, 1.7])
		var tw: Array = Gt.get("twist", [0.02, 0.07])
		var amp: float = float(FP.get("amp", 1.0)) * float(SR.get("amp", 1.0)) * _gl_gw * a
		var A: float = lerpf(float(th[0]), float(th[1]), u) * amp
		var K: float = lerpf(float(kn[0]), float(kn[1]), u) * amp * float(SR.get("lift", 1.0))
		var s: float = sin(TAU * _gl_ph)
		var c: float = cos(TAU * _gl_ph)
		q[ix["thigh_r"]] = q[ix["thigh_r"]] * Quaternion(Vector3(0, 0, 1), A * s)
		q[ix["thigh_l"]] = q[ix["thigh_l"]] * Quaternion(Vector3(0, 0, 1), -A * s)
		q[ix["shin_r"]] = q[ix["shin_r"]] * Quaternion(Vector3(0, 0, 1), -K * maxf(0.0, c))
		q[ix["shin_l"]] = q[ix["shin_l"]] * Quaternion(Vector3(0, 0, 1), -K * maxf(0.0, -c))
		hips.y += lerpf(float(bb[0]), float(bb[1]), u) * float(FP.get("bob", 1.0)) * _gl_gw * a * (0.5 - 0.5 * cos(2.0 * TAU * _gl_ph))
		var twr: float = lerpf(float(tw[0]), float(tw[1]), u) * _gl_gw * a
		q[ix["pelvis"]] = q[ix["pelvis"]] * Quaternion(Vector3(0, 1, 0), twr * s)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 1, 0), -twr * s * 1.2)
		q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), -deg_to_rad(float(Gt.get("lean_deg", 2.5))) * u * _gl_gw * a * signf(vf))
	# the kick-off: the legs trail behind and the body stretches as he rises from the ground
	var TO2: Dictionary = G.takeoff
	var tt: float = (T - _gl_to_t0) / (maxf(float(TO2.get("ticks", 12)), 6.0) * DT)
	if _gl_to_t0 > -5.0 and tt < 1.0:
		var tr: float = minf(6.0 / maxf(float(TO2.get("ticks", 12)), 6.0), 0.5)   # in and out over 6 ticks at the least
		var e: float = (smoothstep(0.0, tr, tt) * (1.0 - smoothstep(tr, 1.0, tt))) * _gl_to_p * a
		q[ix["thigh_r"]] = q[ix["thigh_r"]] * Quaternion(Vector3(0, 0, 1), -float(TO2.get("kick", 0.32)) * e)
		q[ix["thigh_l"]] = q[ix["thigh_l"]] * Quaternion(Vector3(0, 0, 1), -float(TO2.get("kick", 0.32)) * e * 0.7)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), float(TO2.get("stretch", 0.18)) * e)
		hips.y += float(TO2.get("lift", 1.6)) * e
	# the landing: the hips sink by how fast he arrived, the knees flex, he settles; by surface
	var LD2: Dictionary = G.land
	var LR: Dictionary = G.get("surfaces", {}).get(_gl_ld_row, {})
	var lt: float = (T - _gl_ld_t0) / (maxf(float(LD2.get("ticks", 18)) * float(LR.get("ticks", 1.0)), 6.0) * DT)
	if _gl_ld_t0 > -5.0 and lt < 1.0:
		var lr: float = minf(6.0 / maxf(float(LD2.get("ticks", 18)) * float(LR.get("ticks", 1.0)), 6.0), 0.5)   # in over 6 ticks at the least
		var env: float = smoothstep(0.0, lr, lt) * (1.0 - smoothstep(lr, 1.0, lt))
		var sk2: Array = LD2.get("sink", [3.0, 9.5])
		var fl2: Array = LD2.get("flex", [0.2, 0.62])
		var pp: float = _gl_ld_p
		var e2: float = env * a
		hips.y -= lerpf(float(sk2[0]), float(sk2[1]), pp) * float(LR.get("sink", 1.0)) * e2
		var fx: float = lerpf(float(fl2[0]), float(fl2[1]), pp) * e2
		var st: float = float(LR.get("stumble", 0.0))
		q[ix["thigh_r"]] = q[ix["thigh_r"]] * Quaternion(Vector3(0, 0, 1), fx * (1.0 + 0.5 * st))
		q[ix["thigh_l"]] = q[ix["thigh_l"]] * Quaternion(Vector3(0, 0, 1), fx * (1.0 - 0.4 * st))
		q[ix["shin_r"]] = q[ix["shin_r"]] * Quaternion(Vector3(0, 0, 1), -fx * float(LD2.get("knee", 1.15)) * (1.0 + 0.5 * st))
		q[ix["shin_l"]] = q[ix["shin_l"]] * Quaternion(Vector3(0, 0, 1), -fx * float(LD2.get("knee", 1.15)) * (1.0 - 0.4 * st))
		q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), -fx * 0.25)
		if st > 0.0:
			q[ix["pelvis"]] = q[ix["pelvis"]] * Quaternion(Vector3(1, 0, 0), 0.09 * st * e2 * pp)   # the hips hitch as a knee catches
			hips.y += sin(lt * TAU * 1.5) * 0.8 * st * e2 * pp
		root_off.x += float(LR.get("slide", 0.0)) * pp * _gl_ld_dir * (1.0 - smoothstep(0.0, 1.0, lt)) * a   # this layer runs after the root's offset is made: it adds to it
	if RenderAnim.debug_checks:
		debug["gl_gait"] = _gl_gw
		debug["gl_phase"] = _gl_ph
		debug["gl_surface"] = surf_key


func _ack_layer(S: SimState, f, dt: float) -> void:
	if _ack.is_empty():
		return
	var A: Dictionary = AnimData.press_ack
	var T: float = S.T
	if A.is_empty() or not RenderAnim.press_ack:
		_ack = {}
		return
	if float(_ack.end) < 0.0:
		# the exchange starts: the sim's wind-up cue, a blow taken, his state or an approach leaving the idle stand; or the wait runs out
		var why: String = ""
		if float(windup_cue.get("T", -10.0)) > float(_ack.wind):
			why = "windup"
		elif _hit_n != int(_ack.hits):
			why = "hit"
		elif String(f.state) != "free":
			why = "state " + String(f.state)
		elif f.rush != null:
			why = "rush"
		elif T - float(_ack.t0) >= float(_ack.hold):
			why = "wait"
		if why != "":
			_ack.end = T
			debug["ack_end"] = why
	var w: float = smoothstep(0.0, maxf(float(_ack.get("enter", float(A.get("enter_ticks", 3)) * DT)), 0.001), T - float(_ack.t0))
	if float(_ack.end) >= 0.0:
		var x: float = (T - float(_ack.end)) / maxf(float(A.get("exit_ticks", 3)) * DT, 0.001)
		if x >= 1.0:
			_ack = {}
			return
		w *= 1.0 - smoothstep(0.0, 1.0, x)
	if RenderAnim.reduced_motion:
		w *= 0.6
	_mix_pose(AnimData.pose(String(_ack.pose)), w * float(_ack.w))


## The beam struggle's dig-in (docs/animation/struggle-dig-in.md; data/anim/struggle.json). Encounter's struggle writes the meeting point `S.game.clash.mid` (0 at A's hands, 1 at D's). The fighter it is pushing back
## digs in: the squash pose's legs, pelvis and spine mixed in by how far past the middle the point is on his side, a tremble from the strain, and the drawn body dragged back along the ground (the feet carving it).
## The winner leans in a little. Position is the sim's: only the drawn root moves. Weights ramp over `enter_ticks` (6 or more: the snappy profile solves on twos, so a shorter ramp reads as a snap).
func _struggle_layer(S: SimState, f, dt: float) -> void:
	var C: Dictionary = AnimData.struggle
	var c = S.game.clash
	var losing: float = 0.0
	var winning: float = 0.0
	if not C.is_empty() and RenderAnim.struggle_dig and c != null and float(c.mid) >= 0.0 and (c.A == f or c.D == f):
		var m: float = float(c.mid) if c.A == f else 1.0 - float(c.mid)   # 0.5 even; under it the point is nearer his hands and he is the one being pushed back
		losing = clampf((0.5 - m) * 2.0, 0.0, 1.0)
		winning = clampf((m - 0.5) * 2.0, 0.0, 1.0)
	var step: float = dt * 60.0 / maxf(float(C.get("enter_ticks", 10)), 6.0)
	_str_w = move_toward(_str_w, losing, step)
	_str_lead = move_toward(_str_lead, winning, step)
	var rate: float = float(C.get("slide_rate", 14.0)) if losing * float(C.get("slide_max", 9.0)) > _str_slide else float(C.get("return_rate", 10.0))
	_str_slide = move_toward(_str_slide, losing * float(C.get("slide_max", 9.0)), dt * rate)
	if _str_w <= 0.001 and _str_lead <= 0.001 and _str_slide <= 0.01:
		_str_w = 0.0
		_str_lead = 0.0
		_str_slide = 0.0
		return
	var calm: float = 0.4 if RenderAnim.reduced_motion else 1.0
	if _str_w > 0.001:
		var sp: Dictionary = AnimData.press.get("squash_pose", {})
		var pid: String = String(sp.get("by_fighter", {}).get(pair_key, sp.get("default", "brace")))
		if AnimData.pose_exists(pid):
			var spp: AnimPose = AnimData.pose(pid)
			var w: float = float(C.get("dig_w", 0.85)) * _str_w
			for bn in sp.get("bones", []):
				var bi: int = AnimRig.index[String(bn)]
				_press_slerp(bi, spp.q[bi], w)
			hips.y = minf(hips.y, lerpf(hips.y, spp.hips.y, w))
	# the feet carve: dragged back by the strain, trembling; the winner leans in
	_pr_dx += -_str_slide * calm + float(C.get("lead_dx", 2.5)) * _str_lead + _signed(S.tick, slot) * float(C.get("tremble", 0.6)) * _str_w * calm


## The clinch's grip layer (docs/animation/clinch-sizing.md slice C2; data/anim/clinch.json). The sim's hold arrives as a read, `on_hold(read, T)`: {partner (a fighter's slot), kind (tie, pummel, brace, pin, carry, strain, whiff,
## apart), role ("holder" or "held"), grade (-2 to 2), side ("l" or "r": the pummel's hand), grips ({"hand_r": "collar_r", ...}: each gripping hand to a region of the partner's body)}. The layer runs after the pose is made and
## before the flight lead: it mixes the pose of the kind in at a weight that ramps over `ramp_ticks`, then solves each gripping hand onto its region (IK, never bending past a limit: a hand that cannot reach ends short, and the
## shortfall is counted). The sim places the pair; this layer never moves a position.
func on_hold(read: Dictionary, T: float) -> void:
	var from: String = ""
	if not _gr.is_empty() and bool(_gr.get("on", false)) and _gr_w > 0.5 and String(_gr.get("kind", "")) != String(read.get("kind", "")):
		from = String(_gr.get("kind", ""))   # the kind changes while he is held: the old pose gives way over kind_ticks
	else:
		_gr_gs = float(read.get("grade", 0.0))
	_gr = read.duplicate(true)
	_gr["on"] = true
	_gr["t0"] = T
	if from != "":
		_gr["from"] = from
		_gr["k_t0"] = T


func on_hold_end(_T: float) -> void:
	if not _gr.is_empty():
		_gr["on"] = false


## True while a hold is drawn.
func gripping() -> bool:
	return _gr_w > 0.001


## The pose a hold's kind plays (data/anim/clinch.json): the pinned body has its own brace, a tie-up is the even seat (the grade is mixed in over it), the pummel is its hand's, the rest are named.
func _hold_pose_id(kind: String, held_role: bool, P: Dictionary, C: Dictionary) -> String:
	if held_role and C.get("held_poses", {}).has(kind):
		return String(C.held_poses[kind])
	if kind == "tie":
		return String(P.get("seat", ""))
	if kind == "pummel":
		return String(P.get("pummel_" + String(_gr.get("side", "l")), ""))
	return String(P.get(kind, ""))


## The grip fed from the sim (docs/animation/grip-stages.md; data/anim/grip_feed.json). Every frame the hold's read is built from Encounter's DirGrapple.now (mode tell or clinch, role catcher or caught, grip the grade
## this fighter holds, -2 to 2): a catch's tell shows the catcher's reach and the caught nothing, the clinch is the tie-up and the grade mixes the five stages in, the end of the grapple lets the hold go. With the grapple
## off there is no read and nothing plays. The pummel and the end come as cues (`on_grip_pummel`).
func _hold_feed(S: SimState, f, T: float) -> void:
	if not RenderAnim.grip_feed or AnimData.grip_feed.is_empty() or AnimData.clinch.is_empty():
		return
	if not DirGrapple.on():
		return   # no grapple, no read: a hold something else began (a test, a later feed) is left alone
	_feed_from(S, f, DirGrapple.now(S, f), T)


## The read from a grapple state (DirGrapple.now's shape; a seam for the tests): {} ends a hold this feed began.
func _feed_from(S: SimState, f, g: Dictionary, T: float) -> void:
	var fed: bool = bool(_gr.get("fed", false))
	if g.is_empty():
		if fed and bool(_gr.get("on", false)):
			on_hold_end(T)
		return
	var mode: String = String(g.get("mode", ""))
	if mode == "tell" and String(g.get("role", "")) != "catcher":
		return   # the caught shows nothing: a blow can still beat the grab
	var opp = SimRoster.opp(S, f)
	var pi: int = S.fighters.find(opp)
	if pi < 0:
		return
	var kind: String = "reach" if mode == "tell" else "tie"
	var grade: float = float(g.get("grip", 0)) if mode == "clinch" else 0.0
	if fed and bool(_gr.get("on", false)) and String(_gr.get("kind", "")) == kind and int(_gr.get("partner", -1)) == pi:
		_gr["grade"] = grade   # the same hold: only the grade moves, and the layer eases to it
		return
	var grips: Dictionary = AnimData.grip_feed.get("grips", {}).get(kind, {})
	on_hold({"partner": pi, "kind": kind, "role": "holder", "grade": grade, "side": "l", "grips": grips, "fed": true}, T)


## A pummel for the better grip (cue grapple_pummel, text step or sharp): the free hand swims in over the seat, the hand alternating.
func on_grip_pummel(_text: String, T: float) -> void:
	if _gr.is_empty() or not bool(_gr.get("fed", false)) or String(_gr.get("kind", "")) != "tie":
		return
	_gr_pm_side = 1 - _gr_pm_side
	_gr["pm_t"] = T
	_gr["pm_side"] = "l" if _gr_pm_side == 0 else "r"
	debug["grip_pummels"] = int(debug.get("grip_pummels", 0)) + 1


## The grapple's end as a throw (Encounter's cue grapple_end: text throw_across, thrown_up, thrown_down or reversal, the actor the thrower; data/anim/throws.json). The leader has been in his set (the grip stage at two ahead);
## the sim sends the other body on this tick, so the thrower's own sequence (the wave pair3, prefix zq: load, release, follow) plays from here as the release and the follow-through, and the hold lets go over a few ticks
## without the hands chasing the body that has left. `past`: the send went behind him (the stick away), the throw of the other facing. The thrown body is the sim's and the ragdoll's.
func on_grip_throw(text: String, past: bool, T: float) -> void:
	if not RenderAnim.grip_feed or AnimData.throws.is_empty():
		return
	var send: String = ""
	match text:
		"throw_across", "reversal":
			send = "across_away" if past else "across_toward"
		"thrown_up":
			send = "up"
		"thrown_down":
			send = "down"
	if send == "":
		return
	var id: String = String(AnimData.throws.get("sends", {}).get(send, {}).get(pair_key, ""))
	if id == "" or not AnimData.entries.has(id):
		return
	var en: Dictionary = AnimData.entries[id]
	var dur: float = float(en.get("dur", 14))
	# the sim has already sent him on this tick: the sequence is started so that its release lands on it, and the set the hold was in (the load) stands behind it, fading with the hold
	var lead: float = float(en.phases[0].get("ticks", 0)) * DT
	_seq = {"id": id, "t0": T - lead, "dur": dur * DT, "wt": 0.6 if RenderAnim.reduced_motion else 1.0, "fit": true}
	if not _gr.is_empty():
		_gr["on"] = false
		_gr["thrown"] = true
	debug["grip_throws"] = int(debug.get("grip_throws", 0)) + 1


func _grip_layer(S: SimState, f, dt: float) -> void:
	var C: Dictionary = AnimData.clinch
	if C.is_empty() or not RenderAnim.grip_layer or _gr.is_empty():
		_gr_w = 0.0
		return
	var ramp: float = maxf(float(C.get("ramp_ticks", 6)), 1.0)
	if _gr.get("on", true) == false and RenderAnim.grip_feed and not AnimData.grip_feed.is_empty() and bool(_gr.get("fed", false)):
		ramp = maxf(ramp, float(AnimData.grip_feed.get("release_ticks", 10)))
		if bool(_gr.get("thrown", false)):
			ramp = maxf(float(AnimData.grip_feed.get("throw_release_ticks", 6)), 1.0)   # the other body has left: the hands let go sooner, and do not chase him
	var want: float = 1.0 if bool(_gr.get("on", false)) else 0.0
	_gr_w = move_toward(_gr_w, want, dt * 60.0 / ramp)
	if _gr_w <= 0.001 and want <= 0.0:
		_gr = {}
		_gr_w = 0.0
		return
	var pi: int = int(_gr.get("partner", -1))
	if pi < 0 or pi >= S.fighters.size() or S.fighters[pi] == f:
		return
	var opp = S.fighters[pi]
	var oaf: AnimFighter = RenderAnim.fighter(S, opp)
	if oaf.version == 0:
		return
	var w: float = _gr_w * (0.6 if RenderAnim.reduced_motion else 1.0)
	var kind: String = String(_gr.get("kind", "tie"))
	# the two bodies pass in depth by a few units (render only: the sim's plane is flat), the lower slot nearer the camera, so two arms reaching across do not pass through one another
	root_off.z += float(C.get("depth_offset", 0.0)) * (1.0 if slot < pi else -1.0) * w
	var P: Dictionary = C.get("poses", {})
	var held_role: bool = String(_gr.get("role", "holder")) == "held"
	# the pose of the kind: a tie-up is the even seat mixed toward the ahead or the behind pose by the grade; the pummel is its own hand's; the pinned body has its own brace
	var pid: String = _hold_pose_id(kind, held_role, P, C)
	var F: Dictionary = AnimData.grip_feed if RenderAnim.grip_feed else {}
	var ku: float = 1.0
	if _gr.has("from"):
		ku = smoothstep(0.0, maxf(float(F.get("kind_ticks", 6)), 1.0) * DT, S.T - float(_gr.get("k_t0", 0.0)))
		if ku < 1.0:
			var opid: String = _hold_pose_id(String(_gr.from), held_role, P, C)
			if opid != "" and AnimData.pose_exists(opid):
				_mix_pose(AnimData.pose(opid), w)
	if pid != "" and AnimData.pose_exists(pid):
		_mix_pose(AnimData.pose(pid), w * ku)
	if kind == "tie" and not held_role:
		# the five stages: the grade the sim gives eases a step at a time, so the bodies walk from one to the next
		_gr_gs = move_toward(_gr_gs, float(_gr.get("grade", 0.0)), dt * 60.0 / maxf(float(F.get("grade_ticks", 8)), 1.0))
		var g: float = clampf(_gr_gs / 2.0, -1.0, 1.0)
		var gid: String = String(P.get("ahead" if g > 0.0 else "behind", ""))
		if absf(g) > 0.001 and AnimData.pose_exists(gid):
			_mix_pose(AnimData.pose(gid), w * absf(g))
		if not F.is_empty():
			# the last step of each end: the leader sets his hips (the throw can only come from here), the one two behind caves
			var top: float = smoothstep(0.5, 1.0, absf(g))
			var eid: String = String(F.get("set_pose", "")) if g > 0.0 else String(F.get("cave_pose", ""))
			if top > 0.001 and AnimData.pose_exists(eid):
				_mix_pose(AnimData.pose(eid), w * top)
			# a pummel: the free hand swims in over the seat for a few ticks, in and out smoothly
			if _gr.has("pm_t"):
				var PM: Dictionary = F.get("pummel", {})
				var pt: float = (S.T - float(_gr.pm_t)) / DT
				var pin: float = maxf(float(PM.get("in_ticks", 4)), 1.0)
				var phold: float = float(PM.get("hold_ticks", 3))
				var pout: float = maxf(float(PM.get("out_ticks", 6)), 1.0)
				var pe: float = smoothstep(0.0, pin, pt) * (1.0 - smoothstep(pin + phold, pin + phold + pout, pt))
				var pmid: String = String(P.get("pummel_" + String(_gr.get("pm_side", "l")), ""))
				if pe > 0.001 and AnimData.pose_exists(pmid):
					_mix_pose(AnimData.pose(pmid), w * pe * float(PM.get("w", 0.8)))
	# the grips: each hand onto its region of the partner (not once he has been thrown: the hands would chase him through the air)
	for hand in (_gr.get("grips", {}) if not bool(_gr.get("thrown", false)) else {}):
		_grip_one(S, f, opp, oaf, String(hand), String(_gr.grips[hand]), w)


## One hand to one region of the partner's body: the wrist goes to the region's point, short of it by `hand_back` of the hand's length, in this body's own model space (the partner's point through the world and back). IK keeps the elbow on the side the pose has it.
func _grip_one(S: SimState, f, opp, oaf: AnimFighter, hand: String, region: String, w: float) -> void:
	var C: Dictionary = AnimData.clinch
	var sk: Dictionary = AnimData.sockets.get("limbs", {}).get("hand", {})
	if sk.is_empty() or not hand.begins_with("hand_"):
		return
	var sfx: String = hand.substr(hand.length() - 1)
	var rp: Vector3 = oaf._region_point(region)
	var dx: float = SimWrap.sdx(f.x, opp.x)
	var mx: float = (dx + oaf.vface * rp.x) * vface
	var my: float = (opp.y - f.y) + rp.y
	var ix: Dictionary = AnimRig.index
	var ch: Array = sk["chain"]
	var a: int = ix[String(ch[0]) + "_" + sfx]
	var b: int = ix[String(ch[1]) + "_" + sfx]
	var c: int = ix[hand]
	var tgt := Vector3(mx - float(C.get("hand_back", 0.7)) * float(sk.get("end_len", 6.0)), my, rp.z - root_off.z)
	AnimPose.fk(q, hips, gq, gp)
	_full_fk = true
	var qa0: Quaternion = q[a]
	var qb0: Quaternion = q[b]
	var pole: Vector3 = gp[b]
	AnimPose.ik_limb(q, gq, gp, a, b, c, tgt, pole, 1.0, _rd.shape_key, 0.0, RenderAnim.source_limits)
	q[a] = AnimJoints.slerp_limb(qa0, q[a], w) if AnimJoints.ik_limits else qa0.slerp(q[a], w)
	q[b] = qb0.slerp(q[b], w)
	if RenderAnim.source_limits and AnimJoints.ik_limits:
		if AnimJoints.bone_excess(q, a, _rd.shape_key) > 0.0:
			AnimJoints.clamp_bone(q, a, _rd.shape_key)
		if AnimJoints.bone_excess(q, b, _rd.shape_key) > 0.0:
			AnimJoints.clamp_bone(q, b, _rd.shape_key)
	AnimPose.fk(q, hips, gq, gp)
	var gap: float = (tgt - gp[c]).length()
	debug["grip_gap_max"] = maxf(float(debug.get("grip_gap_max", 0.0)), gap) if w > 0.95 else float(debug.get("grip_gap_max", 0.0))
	debug["grips"] = int(debug.get("grips", 0)) + 1


## The mid-air skid (docs/animation/ragdoll-physics-paper.md section 3a). The sim's brake state arrives as an `air_brake` event (text start or end, kind the reason, amount the speed): while it is on and the body is flying
## free, he is braced against his own velocity. On the sim's start the weight ramps in over `enter_ticks`; on its end, out over `exit_ticks`.
func on_air_brake(phase: String, _reason: String, _speed: float, _T: float) -> void:
	if phase == "start":
		_ab_on = true
		_ab_speed = -1.0
	elif phase == "end":
		_ab_on = false


## True while the skid is drawn (the lead scan reads it: feet leading is right for these frames).
func braking() -> bool:
	return _ab_w > 0.05


## The skid's layer, before the flight lead: the poses mixed in at the weight of the deceleration he is showing, and the lean the lead is to turn the body to (against the way he travels, never head first).
func _air_brake_layer(S: SimState, f, dt: float) -> void:
	var B: Dictionary = AnimData.brake
	if B.is_empty() or not RenderAnim.air_brake:
		_ab_w = 0.0
		_ab_str = 0.0
		_ab_on = false
		return
	if not _ab_on and _ab_w <= 0.0:
		_ab_str = 0.0
		_ab_speed = -1.0   # nothing to show: no speed is tracked until the sim's brake starts
		return
	var flying: bool = (f.state == "launched" or f.state == "dropped") and f.slide <= 0.0
	var v := Vector2(f.vx, f.vy)
	var vmv: Vector2 = _lead_measure(S, f)
	if vmv.length() > v.length() * 1.5:
		v = vmv
	var sp: float = v.length()
	var want: float = 1.0 if (_ab_on and flying) else 0.0
	var step: float = dt * 60.0 / maxf(float(B.get("enter_ticks", 4)) if want > _ab_w else float(B.get("exit_ticks", 8)), 1.0)
	var was: float = _ab_w
	_ab_w = move_toward(_ab_w, want, step)
	if _ab_w <= 0.001:
		_ab_w = 0.0
		_ab_str = 0.0
		_ab_speed = sp
		return
	var dec: float = maxf(0.0, (_ab_speed - sp) / maxf(dt, 0.0001)) if _ab_speed >= 0.0 else 0.0
	_ab_speed = sp
	var target: float = clampf(dec / float(B.get("decel_ref", 3000.0)), float(B.get("min_w", 0.35)), 1.0)
	if was <= 0.001:
		_ab_str = float(B.get("min_w", 0.35))
	_ab_str += (target - _ab_str) * (1.0 - exp(-dt * 12.0))
	var ids: Dictionary = B.get("poses", {})
	var w: float = _ab_w * _ab_str
	if RenderAnim.reduced_motion:
		w *= 0.6
	if _ab_on and flying:
		if AnimData.pose_exists(String(ids.get("enter", ""))):
			_mix_pose(AnimData.pose(String(ids.enter)), w * (1.0 - _ab_w))
		if AnimData.pose_exists(String(ids.get("hold", ""))):
			_mix_pose(AnimData.pose(String(ids.hold)), w * _ab_w)
	elif AnimData.pose_exists(String(ids.get("exit", ""))):
		_mix_pose(AnimData.pose(String(ids.exit)), w)
	# the judder of the skid: the arms and the head shudder against the air (friction made visible), more the harder he brakes
	if _ab_on and flying and float(B.get("judder", 0.0)) > 0.0:
		var jt: float = float(B.get("judder", 0.0)) * w * (0.5 if RenderAnim.reduced_motion else 1.0)
		var jph: float = S.T * TAU * float(B.get("judder_hz", 9.0)) + float(slot) * 1.3
		var jx: Dictionary = AnimRig.index
		q[jx["forearm_l"]] = q[jx["forearm_l"]] * Quaternion(Vector3(0, 0, 1), sin(jph) * jt)
		q[jx["forearm_r"]] = q[jx["forearm_r"]] * Quaternion(Vector3(0, 0, 1), sin(jph + 2.1) * jt)
		q[jx["head"]] = q[jx["head"]] * Quaternion(Vector3(0, 0, 1), sin(jph + 4.2) * jt * 0.6)
	var lean: Array = B.get("lean_deg", [18.0, 45.0])
	_ab_aim = deg_to_rad(lerpf(float(lean[0]), float(lean[1]), _ab_str)) * (signf(v.x) if absf(v.x) > 1.0 else 1.0)


## The flight lead (GB-006, docs/animation/pose-pipeline.md 9.23): the sim's body spin halves every 0.5 s and leaves a launched fighter at whatever angle the tumble
## stopped at, still flying at speed: feet first, laid out along the flight line. Once the spin is low and the speed high the whole body turns about its middle (the
## view's pivot) until the head leads along the velocity, never the feet: blown back he flies on his back, head first. Landing into a skid it turns upright. The turn
## `_lead_d` is a world-space angle added to the sim's own (the view's pivot turns by -rot): it chases its aim by the short way, holds when the flight slows and
## is let go when the launch ends. It is the root's rotation and a shift that keeps the middle in place. Read from the sim's state only.
func _lead_layer(S: SimState, f, dt: float) -> void:
	if not _rc.is_empty():
		return   # a recoil exit turns the body itself
	var L: Dictionary = AnimData.flight
	if L.is_empty() or not RenderAnim.flight_lead:
		_lead_d = 0.0
		_lead_w = 0.0
		return
	var rate: float = float(L.get("rate", 6.0))
	# the spine's own angle in the pose as it stands (pelvis to head, model space, beta = 0 upright), and on screen with the sim's turn and the turn held
	AnimPose.fk_chain(q, hips, gq, gp, SPINE_CHAIN)
	var ax: Vector3 = gp[5] - gp[1]
	var beta: float = atan2(-ax.x * vface, ax.y)
	var net: float = beta - f.rot + _lead_d
	var gain: float = 0.0
	var aim: float = 0.0
	if f.state == "launched" or f.state == "dropped":
		var v := Vector2(f.vx, f.vy)
		var vmv: Vector2 = _lead_measure(S, f)   # a knockback carries him by position and leaves f.vx small: the motion he has is what he is turned along
		if vmv.length() > v.length() * 1.5:
			v = vmv
		var sp: float = v.length()
		var head_first: float = atan2(-v.x, v.y)   # the spine along the velocity: (-sin a, cos a) = v
		if f.slide > 0.0:
			# landing into a skid: the pose's own lean without the sim's turn (it is easing him upright), only faster; a body the pose lays out along the skid is flown head first
			var lay: float = smoothstep(float(L.lay[0]), float(L.lay[1]), absf(sin(beta)))
			if sp > 1.0:
				# the pose leans against the way he travels (a lip's launch drawn leaning into the facing while the shove carries him backwards): the feet lead, whatever the lean's size, so he is flown head first
				var dot_b: float = (-sin(beta) * v.x + cos(beta) * v.y) / sp
				lay = maxf(lay, smoothstep(-0.2, -0.55, dot_b))
			aim = beta + lay * wrapf(head_first - beta, -PI, PI) if sp > 1.0 else beta
			gain = float(L.get("skid_rate", 20.0)) / maxf(rate, 0.001)
		else:
			var spd: Array = L.speed
			var spn: Array = L.spin
			gain = smoothstep(float(spd[0]), float(spd[1]), sp) * (1.0 - smoothstep(float(spn[0]), float(spn[1]), absf(f.spin)))
			if f.vy < 0.0:
				var st: Array = L.steep
				gain *= 1.0 - smoothstep(float(st[0]), float(st[1]), -f.vy / maxf(absf(f.vx), 1.0))
			aim = head_first
		if _ab_w > 0.01 and RenderAnim.air_brake and f.slide <= 0.0:
			# braking in the air: the body is turned to lean back against the way he travels, not laid out head first
			aim = aim + _ab_w * wrapf(_ab_aim - aim, -PI, PI)
			gain = maxf(gain, float(AnimData.brake.get("lead_rate", 18.0)) / maxf(rate, 0.001) * _ab_w)
		var delta: float = wrapf(aim - net, -PI, PI)
		var fastk: float = 1.0 + 3.0 * smoothstep(float(L.speed[1]), float(L.speed[1]) * 3.0, sp)   # a body flying at 2,000 units a second is aligned in a few ticks, not in a tenth of a second
		if sp > 300.0 and absf(delta) > 1.2 and _ab_w < 0.3:
			# a turn that has to pass through "feet first" on the short way (an upside-down body landing into a skid, turned upright through the horizontal) goes the long way, through head first
			var mid: float = net + delta * 0.5
			var dm: float = (-sin(mid) * v.x + cos(mid) * v.y) / sp
			if dm < -0.5:
				delta -= signf(delta) * TAU
		_lead_d += delta * (1.0 - exp(-dt * rate * gain * fastk))
	else:
		# on his feet or flying free and carried fast (a knockback moves him by position, not by velocity): a body folded or laid out with the feet leading is stood up
		# to a tilt of `tilt` degrees at most; otherwise the turn is let go, back to the sim's own angle, the short way
		var want_d: float = 0.0
		var vm: Vector2 = _lead_measure(S, f)
		var spm: float = vm.length()
		var a0: float = wrapf(beta - f.rot, -PI, PI)
		if spm > 1.0 and absf(a0) < 2.1:
			var cap: float = deg_to_rad(float(L.get("tilt", 35.0)))
			var dot0: float = (-sin(a0) * vm.x + cos(a0) * vm.y) / spm
			var spd2: Array = L.speed
			var g: float = smoothstep(float(spd2[0]), float(spd2[1]), spm) * smoothstep(-0.1, -0.5, dot0)
			want_d = g * (clampf(a0, -cap, cap) - a0)
			gain = g
		_lead_d += (want_d - _lead_d) * (1.0 - exp(-dt * float(L.get("tilt_rate", 45.0))))   # (quick: a knockback is over in a few frames)
	_lead_d = wrapf(_lead_d, -PI, PI)
	_lead_w = gain
	debug["lead_probe"] = [rad_to_deg(beta), rad_to_deg(f.rot), rad_to_deg(aim), rad_to_deg(net), gain, f.slide]
	if absf(_lead_d) < 0.0005:
		_lead_d = 0.0
		return
	var phi: float = vface * _lead_d   # a turn of the model about z shows as vface * phi on screen
	q[0] = Quaternion(Vector3(0, 0, 1), phi) * q[0]
	var py: float = float(L.get("pivot_y", 34.0))
	root_off += Vector3(py * sin(phi), py * (1.0 - cos(phi)), 0.0)
	debug["lead"] = int(debug.get("lead", 0)) + 1
	debug["lead_w"] = gain
	debug["lead_d"] = _lead_d
	debug["lead_phi"] = phi


## The fighter's velocity as the sim moved him over the last tick: a knockback and a rush carry a fighter by position and leave f.vx as it was.
func _lead_measure(S: SimState, f) -> Vector2:
	if S.tick != _lead_tk:
		var gap: int = S.tick - _lead_tk
		if _lead_tk >= 0 and gap > 0 and gap <= 4:
			_lead_vm = Vector2(SimWrap.sdx(_lead_px, f.x), f.y - _lead_py) * (60.0 / float(gap))
		else:
			_lead_vm = Vector2.ZERO
		_lead_tk = S.tick
		_lead_px = f.x
		_lead_py = f.y
	return _lead_vm


## A far taunt's sequence: the shared shrug, or one of his own gestures.
func _is_taunt(id: String) -> bool:
	return id != "" and (id == String(AnimData.agency.get("taunt", {}).get("seq", "")) or id == _taunt_id)


## His own pick (docs/animation/pair-live.md): the key set of a blow from his light or heavy list (every strike of his strike waves, never the tail), walked as go-live
## step 1's lists are: the walk starts at a hash of the exchange and the fighter and takes every third entry (every fifth when the list is a multiple of three), so
## nothing repeats inside ten blows; a two-limb key set is skipped when a limb of its kind is broken; the gated key sets join only while their gate is open. "" when he
## is not one of the pair, the live pair is off, or no key set of his fits.
func _pair_pick(S: SimState, f, ex, ordinal: int, heavy: bool, piece: String = "") -> String:
	if pair_key == "" or not RenderAnim.pair_live or not AnimData.pair_ready(pair_key):
		return ""
	var lst: Dictionary = AnimData.pair_lists[pair_key]
	# the planner's own pick, when the beat carries it (args.piece, "strike.jab": the alchemist's beats will)
	var named: String = AnimData.resolve_strike(pair_key, String(piece))
	if named != "":
		debug["pair_picks"] = int(debug.get("pair_picks", 0)) + 1
		return named
	var which: String = "heavy" if heavy else "light"
	var cand: Array = (lst[which] as Array).duplicate()
	var opp = ex.D if ex.A == f else ex.A
	for g in lst.gated:
		if String(g.weight) != which:
			continue
		var open: bool = false
		match String(g.gate):
			"both_ground":
				open = f.y - WorldWater.floorAt(S, f.x, f.z) < 8.0 and opp != null and opp.y - WorldWater.floorAt(S, opp.x, opp.z) < 8.0
			"striker_air":
				open = f.y - WorldWater.floorAt(S, f.x, f.z) > 20.0
		if open:
			cand.append(String(g.id))
	var n: int = cand.size()
	if n == 0:
		return ""
	var stepw: int = 3 if n % 3 != 0 else 5
	var h: int = _hash(int(ex.n), slot, 11)
	for tries in range(n):
		var id: String = String(cand[(h + stepw * (ordinal + tries)) % n])
		var ks = AnimData.keysets.get(id)
		if ks == null:
			continue
		var two: String = String(ks.get("limb2", ""))
		if two != "" and ((_arm_broken and (two.begins_with("hand") or two.begins_with("elbow"))) or (_leg_broken and (two.begins_with("foot") or two.begins_with("knee")))):
			continue
		debug["pair_picks"] = int(debug.get("pair_picks", 0)) + 1
		return id
	return ""


## ---- the energy press and the pair's own events (data/anim/pair_live.json; docs/animation/pair-live.md). The sim's cues blast_windup, blast_charge, blast_full, blast_cancel and
## buried_blast, its shot_fire and shot_deflect events, and the cues it does not send yet (taunt_close, drop_the_act, regalia_release, energy_shove) start the pose or
## sequence of his own that his role names. Inside an exchange none of them play: a blast press there is a link of the string, drawn by the strike's own poses.
func _en_role(role: String) -> Dictionary:
	if pair_key == "" or not RenderAnim.pair_live:
		return {}
	return AnimData.pair.get("roles", {}).get(pair_key, {}).get(role, {})


func _en_busy(S: SimState, f) -> bool:
	var ex = S.dirS.ex
	return ex != null and (ex.A == f or ex.D == f)


func _en_play_seq(id: String, t0: float) -> void:
	if AnimData.entries.has(id):
		_seq = {"id": id, "t0": t0, "dur": float(AnimData.entries[id].dur) / 60.0, "wt": 0.6 if RenderAnim.reduced_motion else 1.0}
		debug["energy"] = int(debug.get("energy", 0)) + 1


## A pose held and eased: a fresh hold, or (while one is on) a switch to the next pose of the same envelope (the charge to the flash to the release).
func _en_hold(pose: String, T: float, ticks: float, tin: float, tout: float, w: float) -> void:
	if not AnimData.pose_exists(pose):
		return
	var on: bool = _en_t0 >= 0.0 and (_en_t1 < 0.0 or T < _en_t1 + _en_out)
	if on:
		_en_prev = _en_pose
		_en_sw = T
	else:
		_en_prev = ""
		_en_t0 = T
		_en_in = tin
	_en_pose = pose
	_en_t1 = (T + ticks / 60.0) if ticks > 0.0 else -1.0
	_en_out = tout
	_en_w = w * (0.6 if RenderAnim.reduced_motion else 1.0)
	debug["energy"] = int(debug.get("energy", 0)) + 1


func _en_hold_spec(spec: Dictionary, T: float) -> void:
	_en_hold(String(spec.get("pose", "")), T, float(spec.get("ticks", 20)), float(spec.get("in", 0.06)), float(spec.get("out", 0.15)), float(spec.get("w", 0.9)))


func on_blast_cue(kind: String, T: float, S: SimState, f) -> void:
	if not RenderAnim.pair_live or pair_key == "":
		return
	var act: String = String(AnimData.pair.get("cues", {}).get(kind, ""))
	var busy: bool = _en_busy(S, f)
	match act:
		"windup":
			if not busy and _en_role("bolt").has("seq"):
				_en_play_seq(String(_en_role("bolt").seq), T)
		"charge":
			var rc: Dictionary = _en_role("charged")
			if not busy and not rc.is_empty():
				_en_hold(String(rc.get("charge", "")), T, -1.0, 0.12, 0.15, 0.9)
		"full":
			var rf: Dictionary = _en_role("charged")
			if not rf.is_empty() and _en_t0 >= 0.0 and _en_t1 < 0.0:
				_en_hold(String(rf.get("full", "")), T, -1.0, 0.12, 0.15, 0.9)
		"cancel":
			if _en_t0 >= 0.0 and _en_t1 < 0.0:
				_en_t1 = T
		"crater":
			_en_hold_spec(_en_role("crater"), T)
		"volley":
			if not busy and _en_role("volley").has("seq"):
				_en_play_seq(String(_en_role("volley").seq), T)
		"taunt_close":
			var rt: Dictionary = _en_role("taunt_close")
			if f.y - WorldWater.floorAt(S, f.x, f.z) > 20.0 and _en_role("taunt_close_air").has("seq"):   # in the air its first phase needs the ground: his own start for it, in the same 60 ticks
				rt = _en_role("taunt_close_air")
			if rt.has("seq"):
				_en_play_seq(String(rt.seq), T)
				_taunt_id = String(rt.seq)
		"drop_the_act":
			if _en_role("drop_the_act").has("seq"):
				_en_play_seq(String(_en_role("drop_the_act").seq), T)
		"crown_release":
			_en_hold_spec(_en_role("crown_release"), T)
		"shove":
			_en_hold_spec(_en_role("shove"), T)


## A shot left him (`link` the volley's group): its kind picks the role. A bolt is the wind-up's sequence aligned so that its fire beat is the shot; a bolt inside the spray
## gap of his last one is a spray beat; a charged shot's release takes over from the charge.
func on_shot(kind: String, T: float, S: SimState, f, tick: int, link: int) -> void:
	if not RenderAnim.pair_live or pair_key == "" or _en_busy(S, f):
		return
	var role: String = String(AnimData.pair.get("kinds", {}).get(kind, ""))
	if role == "":
		return
	match role:
		"bolt":
			var gap: int = tick - _en_last_bolt
			_en_last_bolt = tick
			if gap >= 0 and gap < int(AnimData.pair.get("spray_gap", 10)) and _en_role("spray").has("seq"):
				_en_play_seq(String(_en_role("spray").seq), T)
			elif _en_role("bolt").has("seq"):
				_en_play_seq(String(_en_role("bolt").seq), T - float(_en_role("bolt").get("wind_ticks", 4)) / 60.0)
		"charged":
			var rr: Dictionary = _en_role("charged").get("release", {})
			if not rr.is_empty():
				_en_hold_spec(rr, T)
		"rain":
			_en_hold_spec(_en_role("rain"), T)
		_:
			if _en_role(role).has("seq"):
				_en_play_seq(String(_en_role(role).seq), T)


## He swatted a shot wild (the wild deflect): the swat, unless the perfect block's own sequence is playing.
func on_deflect(T: float, S: SimState, f) -> void:
	if not RenderAnim.pair_live or pair_key == "" or _en_busy(S, f) or String(_seq.get("id", "")).begins_with("s3."):
		return
	if _en_role("swat").has("seq"):
		_en_play_seq(String(_en_role("swat").seq), T)


## The held energy pose: eased in, held, eased out (an open charge ends in an exchange, a launch, a fall or after 2.5 s: the sim's hold cap is 45 ticks).
func _energy_layer(S: SimState, f, T: float) -> void:
	if _en_t0 < 0.0 or not AnimData.pose_exists(_en_pose):
		return
	if _en_t1 < 0.0 and (T - _en_t0 > 2.5 or f.state == "launched" or f.state == "down" or f.state == "dropped" or _en_busy(S, f)):
		_en_t1 = T
	var wgt: float = smoothstep(0.0, _en_in, T - _en_t0)
	if _en_t1 >= 0.0:
		wgt *= 1.0 - smoothstep(0.0, _en_out, T - _en_t1)
		if T - _en_t1 >= _en_out:
			_en_t0 = -1.0
			_en_t1 = -1.0
			_en_pose = ""
			_en_prev = ""
			return
	wgt *= _en_w
	if wgt <= 0.001:
		return
	var u: float = smoothstep(0.0, 0.08, T - _en_sw)
	if _en_prev != "" and u < 1.0 and AnimData.pose_exists(_en_prev):
		var pp: AnimPose = AnimData.pose(_en_prev)
		AnimPose.mix(q, pp.q, wgt * (1.0 - u))
		hips = hips.lerp(pp.hips, wgt * (1.0 - u))
		curl = curl.lerp(pp.curl, wgt * (1.0 - u))
	var ap: AnimPose = AnimData.pose(_en_pose)
	AnimPose.mix(q, ap.q, wgt * u)
	hips = hips.lerp(ap.hips, wgt * u)
	curl = curl.lerp(ap.curl, wgt * u)


## The held agency pose: eased in, held, eased out. A charge ends by itself when its exchange starts (the sim begins it at the wind-up), when he falls or at its cap.
func _agency_layer(S: SimState, f, T: float) -> void:
	if not _ag_sq.is_empty():
		if T > float(_ag_sq.t0) + float(_ag_sq.dur) + 0.1:
			_ag_sq = {}
		elif T >= float(_ag_sq.t0):
			_entry_layer(float(_ag_sq.t0), float(_ag_sq.dur), String(_ag_sq.id), T, DT, float(_ag_sq.wt))
	if _ag_t0 < 0.0 or not AnimData.pose_exists(_ag_hold):
		return
	var cfg: Dictionary = AnimData.agency
	if _ag_kind.begins_with("charge_") and (f.rush != null or _lead_measure(S, f).length() > float(cfg.get("charge", {}).get("cut_speed", 300.0))):
		# he is carried off at speed (a rush, a lunge, a knock-back drift or a bounce) with the charge's leaned-back flight pose still held: the pose does not ride a flight at any state, so it is let go at once
		# (the lead scan found him laid out feet first at 718 u/s on the launcher build's heavy)
		_ag_t0 = -1.0
		_ag_t1 = -1.0
		_ag_kind = ""
		return
	if _ag_kind.begins_with("charge_") and _ag_t1 < 0.0:
		var cap: float = float(cfg.get("charge", {}).get(_ag_kind.substr(7), {}).get("max_ticks", 90)) / 60.0
		var ex = S.dirS.ex
		if T - _ag_t0 > cap or f.state == "launched" or f.state == "down" or f.state == "dropped" or (ex != null and (ex.A == f or ex.D == f)):
			_ag_t1 = T
			_ag_fast = f.state == "launched" or f.state == "dropped" or f.state == "down"   # a charge's lean does not ride a flight or a get-up
	var wgt: float = smoothstep(0.0, _ag_in, T - _ag_t0)
	if _ag_t1 >= 0.0:
		var out_t: float = minf(_ag_out, 0.05) if _ag_fast else _ag_out
		wgt *= 1.0 - smoothstep(0.0, out_t, T - _ag_t1)
		if T - _ag_t1 >= out_t:
			_ag_t0 = -1.0
			_ag_t1 = -1.0
			return
	wgt *= _ag_w
	if wgt > 0.001:
		var ap: AnimPose = AnimData.pose(_ag_hold)
		AnimPose.mix(q, ap.q, wgt)
		hips = hips.lerp(ap.hips, wgt)
		curl = curl.lerp(ap.curl, wgt)


## The last stand (docs/architecture/last-stand.md): ready starts his steadying beat in his own shape and the held resolve; end `used` lets the resolve go
## (the signature's own animation takes over), `expired` slumps him.
func on_last_stand(kind: String, t: float, dur: float, end_kind: String) -> void:
	var L: Dictionary = AnimData.last_stand
	if not RenderAnim.last_stand_poses or L.is_empty():
		return
	if kind == "last_stand_ready":
		var sk: String = _rd.shape_key
		var sid: String = String(L.get("ready", {}).get(sk, L.get("ready", {}).get("default", "")))
		if AnimData.entries.has(sid):
			_seq = {"id": sid, "t0": t, "dur": float(AnimData.entries[sid].dur) / 60.0, "wt": 0.6 if RenderAnim.reduced_motion else 1.0}
			debug["last_stand"] = int(debug.get("last_stand", 0)) + 1
		_ls_t0 = t
		_ls_t1 = -1.0
	elif kind == "last_stand_end":
		if _ls_t0 >= 0.0 and _ls_t1 < 0.0:
			_ls_t1 = t
		if end_kind == "expired" and AnimData.entries.has("ls.slump"):
			_seq = {"id": "ls.slump", "t0": t, "dur": float(AnimData.entries["ls.slump"].dur) / 60.0, "wt": 0.6 if RenderAnim.reduced_motion else 1.0}


## The opening's pose from the sim's tick: waiting or falling (the body one narrow line, head first), the landing (a deep compression with one open hand on
## the ground and the head up, held, then up through a half crouch), the staredown (upright and loose, one small beat of character for his shape, then the
## tension in the last stretch before the clock). Reduced motion: no fall and no landing: he drops into frame and stands.
func _intro_layer(S: SimState, f) -> void:
	var I: Dictionary = AnimData.intro
	var tk: float = float(S.tick) / 60.0
	var reduced: bool = RenderAnim.reduced_motion
	var dq: float = 1.0 / 60.0
	var set_p: AnimPose = AnimData.pose("in.hold.set")
	var landed: bool = float(_intro.land_t) >= 0.0 and tk >= float(_intro.land_t)
	var pose_in: AnimPose = AnimData.pose("in.hold.fall") if not reduced else set_p
	if not landed:
		AnimPose.mix(q, pose_in.q, 1.0)
		hips = pose_in.hips
		curl = pose_in.curl
		return
	var tl: float = tk - float(_intro.land_t)
	var land_dur: float = float(AnimData.entries["in.land"].dur) / 60.0 if AnimData.entries.has("in.land") else 1.0
	if tl < land_dur and not reduced and AnimData.entries.has("in.land"):
		if tl < 0.12:
			_skip_inertia = true   # the touchdown snaps (the join from the fall is the blow of the landing, not something to ease)
		_entry_layer(float(_intro.land_t), land_dur, "in.land", tk, dq)
		return
	AnimPose.mix(q, set_p.q, 1.0)
	hips = set_p.hips
	curl = set_p.curl
	var st: float = float(_intro.stare_t)
	if st < 0.0:
		return
	# the tension in the last stretch of the staredown
	var tense_p: AnimPose = AnimData.pose("in.hold.tense")
	var lead: float = float(I.get("tense_lead", 1.8))
	var ramp: float = float(I.get("tense_ramp", 0.8))
	var t_end: float = st + float(_intro.stare_dur)
	var tw: float = smoothstep(t_end - lead, t_end - lead + ramp, tk) if not reduced else 0.0
	if tw > 0.001:
		AnimPose.mix(q, tense_p.q, tw)
		hips = hips.lerp(tense_p.hips, tw)
		curl = curl.lerp(tense_p.curl, tw)
	# one small beat of character for his shape, early in the staredown
	var sk: String = String(AnimRagdoll.shape_of.get(String(f.id), AnimRagdoll.shape_of.get("default", "")))
	var beat: Dictionary = I.get("beats", {}).get(sk, {})
	if not beat.is_empty() and not reduced and AnimData.entries.has(String(beat.get("seq", ""))):
		var b0: float = st + float(beat.get("at", 1.0))
		var bd: float = float(AnimData.entries[String(beat.seq)].dur) / 60.0
		if tk >= b0 and tk < b0 + bd + 0.05:
			_entry_layer(b0, bd, String(beat.seq), tk, dq)


## The opening's events (docs/architecture/intro-phase.md), at their own tick in seconds: the match clock is frozen, so this is the only time there is.
func on_intro(kind: String, t: float, dur: float, clock_kind: String) -> void:
	if not RenderAnim.intro_poses or AnimData.intro.is_empty():
		return
	match kind:
		"intro_start":
			_intro = {"on": true, "fall_t": -1.0, "fall_dur": 0.6, "land_t": -1.0, "stare_t": -1.0, "stare_dur": 2.6}
		"entrance_fall":
			if not _intro.is_empty():
				_intro["fall_t"] = t
				_intro["fall_dur"] = maxf(dur, 0.1)
		"entrance_land":
			if not _intro.is_empty():
				_intro["land_t"] = t
		"staredown_start":
			if not _intro.is_empty():
				_intro["stare_t"] = t
				_intro["stare_dur"] = maxf(dur, 0.5)
		"clock_start":
			_intro = {}


## The side of the body that met the ground at a ground event: the normal is (-slope, 1) over its length, or the event's own nx, ny (World's interior contacts carry them).
func _event_side(e: Dictionary) -> float:
	if e.has("nx") and e.has("ny"):
		return _hit_side(float(e.nx), float(e.ny))
	var sl: float = float(e.get("slope", 0.0))
	var l: float = sqrt(sl * sl + 1.0)
	return _hit_side(-sl / l, 1.0 / l)


## The chain inside a tower (docs/animation/ragdoll-physics-paper.md section 4; Game Design's values in data/anim/chain.json). World's `interior_contact` event arrives for each slab or face the body meets inside a building:
## surface (face, floor, ceiling, wall), the normal nx, ny, vn, vt, keep, punch (the slab broke), k (the contact's number in the chain) and stop (ticks held). The brake is off inside the chain.
func on_interior_contact(e: Dictionary, T: float) -> void:
	var C: Dictionary = AnimData.chain
	if C.is_empty() or not RenderAnim.chain_poses:
		return
	_ab_on = false   # Game Design: the brake is off inside the chain until he lodges or leaves by a face
	var amp: float = _rd_amp()
	var surf: String = String(e.get("surface", "floor"))
	var vn: float = absf(float(e.get("vn", 0.0)))
	var side: float = _event_side(e)
	var red: float = 0.6 if RenderAnim.reduced_motion else 1.0
	debug["chain_contacts"] = int(debug.get("chain_contacts", 0)) + 1
	match surf:
		"ceiling":
			var cc: Dictionary = C.get("ceiling", {})
			var w: float = clampf(vn / float(cc.get("ref", 1800.0)), float(cc.get("min", 0.35)), 1.0) * red
			_rd.crumple(clampf(vn / 2500.0, 0.3, 1.5) * 0.8, amp, side)
			_rd.kick(1, clampf(float(e.get("vt", 0.0)) * vface / 220.0, -9.0, 9.0) * amp)
			var s1: String = String(C.get("poses", {}).get("slam", "ce.slam"))
			var s2: String = String(C.get("poses", {}).get("rebound", "ce.rebound"))
			if AnimData.entries.has(s1) and AnimData.entries.has(s2):
				var d1: float = float(AnimData.entries[s1].dur) / 60.0
				_seq = {"id": s1, "t0": T, "dur": d1, "wt": w}
				_seq_next = {"id": s2, "t0": T + d1, "dur": float(AnimData.entries[s2].dur) / 60.0, "wt": w}
		"floor":
			if bool(e.get("punch", false)):
				# going through a slab: the body folds over its edge for a few ticks and goes on; the streamer and the flail carry it, no pose of its own
				_rd.crumple(clampf(vn / 2500.0, 0.2, 1.0) * 0.5, amp, side)
				_rd.kick(1, -3.0 * amp)
			else:
				on_ground_event("bounce", {"vn": vn, "vt": float(e.get("vt", 0.0)), "nx": float(e.get("nx", 0.0)), "ny": float(e.get("ny", 1.0)), "surface": "paving"}, T)
		"face":
			# the building's face: a hard stop (Game Design: 15 ticks) before he goes through or comes off it
			_rd.crumple(clampf(vn / 2500.0, 0.3, 1.5), amp, side)
			var stop: int = int(e.get("stop", int(C.get("face_stop_ticks", 15))))
			if stop > 0 and AnimData.entries.has("gc.bounce"):
				_seq = {"id": "gc.bounce", "t0": T, "dur": float(stop) / 60.0, "wt": 1.0 * red, "fit": true}
		_:
			_rd.crumple(clampf(vn / 2500.0, 0.2, 1.0) * 0.5, amp, side)


## Lodged in a building (World's `lodge` event, held `hold` seconds): the slump, then the climb out and the stand, fitted to the hold and a short climb.
func on_lodge(hold: float, T: float) -> void:
	var C: Dictionary = AnimData.chain
	if C.is_empty() or not RenderAnim.chain_poses:
		return
	_ab_on = false
	var id: String = String(C.get("poses", {}).get("climb", "lg.climb"))
	if not AnimData.entries.has(id):
		return
	var climb: float = float(C.get("lodge_climb_ticks", 20)) / 60.0
	_seq = {"id": id, "t0": T, "dur": maxf(hold, 0.2) + climb, "wt": 0.6 if RenderAnim.reduced_motion else 1.0}
	_seq_next = {}


func on_ground_event(kind: String, e: Dictionary, T: float) -> void:
	var amp: float = _rd_amp()
	debug["ground_events"] += 1
	var G: Dictionary = AnimData.ground
	var poses_on: bool = RenderAnim.ground_poses and not G.is_empty() and AnimData.entries.has("gc.bounce")
	var surf: float = float(G.get("surface", {}).get(String(e.get("surface", "soil")), 1.0))
	match kind:
		"bounce":
			var vn: float = absf(float(e.get("vn", 0.0)))
			_rd.crumple(clampf(vn / 2500.0, 0.2, 1.5) * 0.6 * surf, amp, _event_side(e))
			# the tangent speed whips the body the way it travels
			_rd.kick(1, clampf(float(e.get("vt", 0.0)) * vface / 220.0, -9.0, 9.0) * amp)
			if poses_on:
				var bw: float = clampf(vn / float(G.get("bounce", {}).get("ref", 1800.0)), float(G.get("bounce", {}).get("min", 0.35)), 1.0) * clampf(surf, 0.6, 1.0)
				_seq = {"id": "gc.bounce", "t0": T, "dur": float(AnimData.entries["gc.bounce"].dur) / 60.0, "wt": bw * (0.6 if RenderAnim.reduced_motion else 1.0)}
				debug["gc_poses"] = int(debug.get("gc_poses", 0)) + 1
		"left_ground":
			var cause: String = String(e.get("cause", ""))
			if poses_on and cause != "bounce" and cause != "":
				var lw: float = clampf(float(e.get("spd", 1000.0)) / float(G.get("launch", {}).get("ref", 2000.0)), float(G.get("launch", {}).get("min", 0.4)), 1.0)
				_seq = {"id": "gc.lip_launch", "t0": T, "dur": float(AnimData.entries["gc.lip_launch"].dur) / 60.0, "wt": lw * (0.6 if RenderAnim.reduced_motion else 1.0)}
				_gc_hold_t1 = T if _gc_hold_t0 >= 0.0 and _gc_hold_t1 < 0.0 else _gc_hold_t1
				debug["gc_poses"] = int(debug.get("gc_poses", 0)) + 1
		"land":
			var lk: String = String(e.get("kind", ""))
			if lk == "slam":
				_rd.crumple(1.0, amp, _event_side(e))
				if poses_on:
					_seq = {"id": "gc.bounce", "t0": T, "dur": float(AnimData.entries["gc.bounce"].dur) / 60.0, "wt": 1.0}
			elif lk == "skid":
				_rd.crumple(0.5, amp)
			elif lk == "tumble":
				_rd.crumple(0.5 * surf, amp, _event_side(e))
				if poses_on and (_gc_hold_t0 < 0.0 or _gc_hold_t1 >= 0.0):
					_gc_hold_t0 = T
					_gc_hold_t1 = -1.0
					var H: Dictionary = G.get("hold", {})
					var spd_k: float = lerpf(float(H.get("slow_k", 1.4)), float(H.get("fast_k", 0.7)), smoothstep(float(H.get("slow_speed", 300.0)), float(H.get("fast_speed", 1500.0)), float(e.get("spd", 800.0))))
					var wear_k: float = 1.0 - float(H.get("worn_loosen", 0.5)) * smoothstep(float(H.get("worn_from", 0.5)), 1.0, maxf(_worn, _brinkp))
					_gc_hold_w = clampf(float(H.get("weight", 0.5)) * spd_k * wear_k, 0.0, float(H.get("max", 0.85)))
					if RenderAnim.reduced_motion:
						_gc_hold_w *= 0.6
					debug["gc_poses"] = int(debug.get("gc_poses", 0)) + 1
		"tumble_end":
			_rd.free = minf(_rd.free, 0.3)
			if _gc_hold_t0 >= 0.0 and _gc_hold_t1 < 0.0:
				_gc_hold_t1 = T
			if poses_on and String(e.get("kind", "")) == "recover" and AnimData.entries.has("gc.tech_flip"):
				_seq = {"id": "gc.tech_flip", "t0": T, "dur": float(AnimData.entries["gc.tech_flip"].dur) / 60.0, "wt": 1.0}
				debug["gc_poses"] = int(debug.get("gc_poses", 0)) + 1
		"journey_end":
			if _gc_hold_t0 >= 0.0 and _gc_hold_t1 < 0.0:
				_gc_hold_t1 = T


func on_cue(kind: String, T: float, t_event: float = -1.0) -> void:
	if RenderAnim.step3_cues and AnimData.cue_map.has(kind):
		var sid: String = String(AnimData.cue_map[kind].get("actor", ""))
		if AnimData.entries.has(sid):
			_seq = {"id": sid, "t0": t_event if t_event >= 0.0 else T, "dur": float(AnimData.entries[sid].dur) / 60.0}
			debug["step3"] = int(debug.get("step3", 0)) + 1
		return
	if AnimData.cue_poses.has(kind) and RenderLook.CUE_POSES.has(kind):
		_cue = {"kind": kind, "t0": T, "dur": float(RenderLook.CUE_POSES[kind].dur)}


## The stagger cue's perfect_block and reversal texts (press-styles.md section 12): the fighter who is staggered (the cue's actor) reels in place for `n` ticks, the step 3 stagger fitted to them (every
## phase scaled together, so the whole reel takes the sim's ticks: a 24-tick sequence at 20 plays at 0.83, a 16-tick one at 1.25). The old stunTicks watch yields to it. Other staggers (flurry, heavy) are the
## stunTicks path, as before.
## The launcher's signal (Encounter's cue `launcher_open`, brawl-plan.md section 10.3; Animation's signal for B): the staggered fighter shows a stagger that is plain to see for the ticks it lasts (`n` the tick
## it ends; `tick` now): knocked back, doubled over and dazed with the arms hanging, then coming up (the fit sequence `lq.open`, wave launch1). The fighter who may launch carries the cue for VFX and the tools.
func on_launcher_open(role: String, text: String, n: int, tick: int, T: float) -> void:
	launcher = {"role": role, "n": n, "text": text, "T": T}
	if role != "target" or not AnimData.entries.has("lq.open") or n <= tick:
		return
	_seq = {"id": "lq.open", "t0": T, "dur": float(n - tick) * DT, "wt": 0.6 if RenderAnim.reduced_motion else 1.0, "fit": true}
	_stun_watch = 0
	debug["launcher_open"] = int(debug.get("launcher_open", 0)) + 1


## The close of the window (`launcher_close`, text used or lapsed): the cue is cleared. A stagger that lapsed ends on its own tick (the fit sequence's last phase brings the head up); a launch that used it is
## the core's own `launch` event.
func on_launcher_close(text: String) -> void:
	launcher = {}
	if text == "used" and String(_seq.get("id", "")) == "lq.open":
		_seq = {}   # the launch has taken him: the stagger look must not hold the body the tumble starts from


## A wind-up the sim names (cue `windup`: text start with `source` the cell, `dur` the ticks, `n` the landing tick; text end with `k` how it ended: 1 thrown, 2 stopped by a blow, 3 lost, 4 a miss). The body
## already winds up from the blow's beat; the cue is kept for VFX and the tools, and a wind-up that ended stopped (2) or lost (3) lets go of its tell at once (the blow's layers end with the beat).
func on_windup(text: String, source: String, dur: float, n: int, k: int, T: float, tick: int = 0) -> void:
	windup_cue = {"text": text, "source": source, "dur": dur, "n": n, "k": k, "T": T, "tick": tick}
	if text == "interject":
		# a ring guard's interjection (Encounter's one-versus-many): he names the landing tick `n` and his wind-up's length `dur` in ticks; the guard shows it with his own tell, which `_waiting_layer` draws
		var land: float = T + float(maxi(n - tick, 0)) * DT
		interject = {"land": land, "dur": maxf(dur, 6.0) * DT}
		debug["interjections"] = int(debug.get("interjections", 0)) + 1
		return
	if text == "start":
		charge_full_t = -1.0
	var wk: String = "windup_" + text + ("_k" + str(k) if text == "end" else "")
	debug[wk] = int(debug.get(wk, 0)) + 1


## The heavy's charge is full (cue `charge_full`): the held coil is at its deepest and trembles from here to the release (a few hundredths of a unit a tick, no light: the flash is VFX's).
func on_charge_full(T: float) -> void:
	charge_full_t = T


## A wound blow that met nothing (cue `miss`: text gave_ground, reach or dodge; `n` the ticks he is open): the blow goes through empty air and he is off balance and open for those ticks (a fit sequence of
## wave miss1: through, open, recover, one for each word).
## The air tech (cue `tech`; the tenth round's chase: a guard press timed to the chaser's arrival breaks it): the rival throws himself open and then tucks, 14 ticks, a flash at the opening (VFX's).
func on_tech(T: float) -> void:
	tech_cue = T
	debug["techs"] = int(debug.get("techs", 0)) + 1
	if AnimData.entries.has("rt.air_tech"):
		_seq = {"id": "rt.air_tech", "t0": T, "dur": 14.0 * DT, "wt": 0.6 if RenderAnim.reduced_motion else 1.0, "fit": true}


## The chase (cue `chase`, text start, blow or end; `n` the blow's number): the chaser follows his own send as drawn travel and beats the rival down in the air, up to six blows. The body shows it as the dive
## `rt.chase.dive` mixed over the travel from the start to the end; each blow is an ordinary beat (in the air, on the stance of the air).
func on_chase(text: String, k: int, n: int, T: float, tick: int = 0) -> void:
	# Encounter's agreed list (docs/director/pending/return/cues.md): `k` the blow's number (1 to 6) on `blow`; `n` is always an absolute tick: the contact tick on `blow` and `arrive`
	if text == "arrive":
		_chase_arrived_t = T
		chase_tick = n
		debug["chase_arrive"] = int(debug.get("chase_arrive", 0)) + 1
		return   # the state stays what it was (`start` or `blow`): the dive eases out in `_waiting_layer`
	chase_state = text
	chase_n = k if text == "blow" else (0 if text == "start" else chase_n)
	if text == "blow":
		chase_tick = n
	if text == "start":
		_chase_arrived_t = -1.0
		_chase_t = T
	debug["chase_" + text] = int(debug.get("chase_" + text, 0)) + 1


func on_miss(text: String, n: int, T: float) -> void:
	miss_cue = {"text": text, "n": n, "T": T}
	var id: String = "mi." + text
	if not AnimData.entries.has(id) or n <= 0:
		return
	_seq = {"id": id, "t0": T, "dur": float(maxi(n, 10)) * DT, "wt": 0.6 if RenderAnim.reduced_motion else 1.0, "fit": true}
	debug["misses"] = int(debug.get("misses", 0)) + 1


## The double hit (cue `double_hit`: both fighters throw a straight blow that lands on tick `n`): the blows are ordinary strike beats (`double` true), so the body needs nothing but the record for VFX and Camera.
func on_double_hit(n: int, bits: int, T: float) -> void:
	double_cue = {"n": n, "bits": bits, "T": T}
	debug["double_hits"] = int(debug.get("double_hits", 0)) + 1


## A point-blank bolt or blast (cues `energy_reach` and `energy_land`): kept for VFX (docs/vfx/reach.md); the blow itself is the key set the beat names (pk.* and rk.*).
func on_energy(kind: String, text: String, x: float, y: float, k: int, T: float) -> void:
	energy_cue = {"kind": kind, "text": text, "x": x, "y": y, "k": k, "T": T}
	debug[kind + "_" + text] = int(debug.get(kind + "_" + text, 0)) + 1


func on_stagger(text: String, n: int, T: float) -> void:
	if not RenderAnim.step3_cues or n <= 0:
		return
	var id: String = "s3.stagger_blocked" if (text == "perfect_block" or text == "zip") else ("s3.stagger_countered" if (text == "reversal" or text == "counter") else "")
	if id == "" or not AnimData.entries.has(id):
		return
	_seq = {"id": id, "t0": T, "dur": float(n) * DT, "wt": 1.0, "fit": true}
	_stun_watch = 0
	_stag_t0 = T
	debug["step3"] = int(debug.get("step3", 0)) + 1
	debug["staggers"] = int(debug.get("staggers", 0)) + 1


## The zip's cues are edges (zip.md sections 9 and 12): the read (DirZip.read) is what the body poses from. zip_light and zip_heavy start a zip: the plan the sim announced is kept for VFX and Camera
## (`zip_cue`), and the last end word is cleared. zip_out is the exit becoming known (6 or 10 ticks before the way out): the exit point and the ticks are kept (`zip_exit`).
func on_zip_cue(kind: String, amount: int, n_in: int, dur: float, rx: int, ry: int, T: float) -> void:
	_zip_end = {}
	_zblend = {}
	zip_cue = {"kind": "heavy" if kind == "zip_heavy" else "strike", "tell": amount, "in": n_in, "dur": dur, "reach_before": rx, "reach_after": ry, "T": T}


func on_zip_out(text: String, x: float, y: float, n: int, k: int, T: float) -> void:
	zip_exit = {"kind": text, "x": x, "y": y, "out": n, "reading": ["speed", "tech", "held"][clampi(k, 0, 2)], "T": T}


## A drop (SimFighter.drop: a zipper shot down on his way out): he falls for the ticks the sim says. The body is the tumble's (the ragdoll's flail from the pose he was in, the flight lead keeping a
## steep fall feet down, the brace before the ground) and the zip's layers are already gone (the read went empty on the same tick: the end word `down`).
func on_drop_start(T: float) -> void:
	_drop = {"t0": T, "landed": false}
	_zip = {}
	_zblend = {}
	debug["drops"] = int(debug.get("drops", 0)) + 1


## He reached the ground in his drop: nothing hurts. The soft catch of a tumble's landing at the data's weight (zip.json `dropped.land_w`), held until the drop ends; no slam, no crumple.
func on_drop_land(T: float) -> void:
	if _drop.is_empty():
		return
	_drop["landed"] = true
	var w: float = float(AnimData.zip.get("dropped", {}).get("land_w", 0.35))
	if RenderAnim.reduced_motion:
		w *= 0.6
	if AnimData.pose_exists("gc.hold.brace_tumble"):
		_gc_hold_t0 = T
		_gc_hold_t1 = -1.0
		_gc_hold_w = w


## The drop is over: `end` when the ticks ran out (the catch is let go, the stance takes over), or the sim's own word for a tech (a table in zip.json: `recover` plays the tech flip). A word with no entry plays as `end`.
func on_drop_end(kind: String, T: float) -> void:
	_drop = {}
	if _gc_hold_t0 >= 0.0 and _gc_hold_t1 < 0.0:
		_gc_hold_t1 = T
	var tech: Dictionary = AnimData.zip.get("dropped", {}).get("tech", {})
	var id: String = String(tech.get(kind, ""))
	if id != "" and AnimData.entries.has(id):
		_seq = {"id": id, "t0": T, "dur": float(AnimData.entries[id].dur) / 60.0, "wt": 1.0}
		debug["gc_poses"] = int(debug.get("gc_poses", 0)) + 1


## The riposte cue (the blocker's counter blow is coming): kept for VFX until the blow's own beat takes over; the posing is the beat's. `n` is the contact tick: a tick number after the
## cue's own, or the ticks ahead when it is smaller (the sim has not fixed which; see the report).
func on_riposte(text: String, n: int, tick_now: int) -> void:
	var ahead: int = n - tick_now if n > tick_now else n
	_rip_cue = {"kind": text if text == "heavy" else "light", "tick": tick_now, "ahead": maxi(ahead, 0)}


## A riposte's or a reversal's beat: the style and grade the data gives a riposte when the beat names none (a perfect timing: tech and perfect for a light, heavy for a heavy), and `_rip` marks it
## for the strike block (the wind-up cut to the data's 2 ticks or 3, no squash). Any other beat is returned as it is.
func _rip_args(args: Dictionary, cls: String) -> Dictionary:
	if not (bool(args.get("riposte", false)) or bool(args.get("reversal", false))):
		return args
	var R: Dictionary = AnimData.press.get("riposte", {})
	if R.is_empty():
		return args
	var a: Dictionary = args.duplicate()
	a["_rip"] = true
	if not a.has("style") and R.has("style"):
		a["style"] = String((R.style as Dictionary).get("heavy" if cls == "heavy" else "light", ""))
	if not a.has("grade") and R.has("grade"):
		a["grade"] = String(R.grade)
	return a


## How much of the block pose is left (1 to 0): it fades over the riposte's `fade` ticks ending on the blow's contact tick, and is gone after it. The riposte is read from the exchange's beats (this
## fighter's own blows that carry riposte or reversal); 1 when there is none.
func _rip_fade(S: SimState, f, T: float) -> float:
	var ex = S.dirS.ex
	if ex == null or (ex.A != f and ex.D != f):
		return 1.0
	var R: Dictionary = AnimData.press.get("riposte", {})
	if R.is_empty():
		return 1.0
	var role: String = "A" if ex.A == f else "D"
	var t0: float = T - ex.t
	var span: float = maxf(float(R.get("fade", 4)), 1.0) * DT
	var w: float = 1.0
	for b in ex.beats:
		if b.op == "strike" and String(b.args.a) == role and (bool(b.args.get("riposte", false)) or bool(b.args.get("reversal", false))):
			var tc: float = t0 + b.t
			w = minf(w, 1.0 - smoothstep(0.0, 1.0, (T - (tc - span)) / span))
	return w


## The other fighter of a step 3 cue (the one who staggers after a perfect block or a reversal, the one who absorbs a burst); a burst shoves him
## only if his own speed jumps in the next ticks (the sim decides the range), so that one waits for the shove.
func on_cue_other(kind: String, t_event: float) -> void:
	if not RenderAnim.step3_cues or not AnimData.cue_map.has(kind):
		return
	var m: Dictionary = AnimData.cue_map[kind]
	if m.has("other_if_stunned"):
		if t_event - _stag_t0 >= 0.0 and t_event - _stag_t0 < 0.5:
			return   # the stagger cue came first and has played it
		_stun_watch = 3
		_stun_seq = String(m.other_if_stunned)
		_stun_t0 = t_event
	elif m.has("other"):
		var sid: String = String(m.other)
		if AnimData.entries.has(sid):
			_seq = {"id": sid, "t0": t_event, "dur": float(AnimData.entries[sid].dur) / 60.0}
			debug["step3"] = int(debug.get("step3", 0)) + 1
	elif m.has("other_if_shoved"):
		_shove_watch = 4
		_shove_vx = _rd_vw.x if _rd_have else 0.0


## `front`: the blow came from the side the victim faces. amp 0 to 1 from the hit's strength.
## `d` is the way the blow pushes, in the body frame (x forward: a blow from the front pushes him toward -x); `force` the
## damage over 60 (0.15 to 1.6). The reaction is the pose (a flinch) plus the ragdoll's own motion along d: a head snap, a torso
## fold or arch, limbs thrown by the push, a step; scaled by the blow's force and by the victim's wear, with a deterministic
## variant per hit (a hash of the tick, the slot and the hit count: no random stream, so a replay shows the same).
func on_hit(T: float, region: String, front: bool, amp: float, kind: String = "", d: Vector2 = Vector2.ZERO, force: float = -1.0, tick: int = 0, hang: float = 0.0, duel: int = 0, stop: int = -1) -> void:
	if d == Vector2.ZERO:
		d = Vector2(-1.0 if front else 1.0, 0.0)
	if force < 0.0:
		force = amp * 70.0 / 60.0
	if armoured and kind != "guard" and amp < 0.8:
		force = (force if force >= 0.0 else amp * 70.0 / 60.0) * 0.3   # armour (a heavy winding or charging): a light does 0.3 of its worth to him, and shows it
		amp = maxf(0.2, amp * 0.5)
	_hit_n += 1
	if kind != "guard":
		_follow_kick(front, force)
	if RenderAnim.shiver_by_weight and stop == 0 and kind != "guard":
		# a blow that flows with no hit-stop (GD section 6: a mash freezes only its first) still shakes the struck body, small for a light, drawn only
		_shake_t0 = T
		_shake_k = 0.3 + 0.4 * clampf(amp, 0.2, 1.0)
	var h: int = _hash(tick, slot, _hit_n)
	var u: float = float(h & 1023) / 511.5 - 1.0
	var u2: float = float((h >> 10) & 1023) / 511.5 - 1.0
	var fmax: float = 1.6 + 0.2 * float(mini(duel, 8))   # a duel of perfects' amplified send: each level a fifth more, to level 8
	var vid: String = _pick_reaction(region, front, clampf(force, 0.15, fmax), d, h, kind)
	var wcl: String = _rv_weight(clampf(force, 0.15, fmax), AnimData.reactions) if not AnimData.reactions.is_empty() else "light"
	var life: float = 0.7   # a variant keeps its blow until its recovery has played
	if vid != "":
		for rec in AnimData.reactions.get("recover", []):
			if _rv_has(rec.weight, wcl):
				life = maxf(life, float(rec.start) + float(rec.dur))
	_reacts.append({"t0": T, "region": region, "front": front, "amp": clampf(amp, 0.2, 1.0), "kind": kind, "dx": d.x, "dy": d.y, "f": clampf(force, 0.15, fmax), "u": u, "hang": hang, "var": vid, "wc": wcl, "life": life})
	if _reacts.size() > 4:
		_reacts.pop_front()
	if not RenderAnim.layer("ragdoll"):
		return
	var ra: float = _rd_amp()
	var wear_k: float = 1.0 + 0.7 * _worn + 0.5 * _brinkp
	var F: float = clampf(force, 0.15, fmax) * wear_k * (1.0 + 0.25 * u) * ra
	if kind == "guard":
		F *= 0.4
	_rd.hit(d.x, d.y, F, int(AnimRagdoll.REGIONS.get(region, 1)), u, u2)
	_hit_free = minf(1.0, _hit_free + 0.5 * F + 0.3 * _worn)
	# the fighter's own shapes are the flinch keys: a light blow pulls in his brace shape, a heavy one his crumple shape
	var heavy_s: float = smoothstep(0.5, 1.1, force * wear_k)
	_hit_crum = heavy_s
	_hit_w = minf(1.0, _hit_w + 0.5 + 0.3 * heavy_s)
	_rd.out_w = 1.0


## A transformation took place (the sim's `transform` event). Its three beats (data/anim/forms.json) play over the pause's
## own ticks (full and short) or over sim time (live).
func on_transform(T: float, version: String) -> void:
	if AnimData.forms.has(version):
		_form = {"t0": T, "version": version}
		debug["variants"]["transform_" + version] = int(debug["variants"].get("transform_" + version, 0)) + 1


func socket(name: String) -> Vector3:
	if not _full_fk and not SOCKET_SET.has(name):
		AnimPose.fk(q, hips, gq, gp)
		_full_fk = true
	return gp[AnimRig.index[name]] + root_off


## The head's centre in model space (for the head flashes).
func head_center() -> Vector3:
	var h: int = AnimRig.index["head"]
	return gp[h] + gq[h] * Vector3(0, 6, 0) + root_off


## The visual facing for this frame (computed once a frame, whichever pane asks first).
func update_face(S: SimState, f) -> float:
	var key: int = RenderAnim._frame_key(S)
	if key == _face_key:
		return vface
	_face_key = key
	if not _face_init:
		_face_init = true
		vface = f.face
		return vface
	var want: float = _wanted_face(S, f)
	if want == vface or want == 0.0:
		_face_want_t = -1.0
	elif _face_want_t < 0.0:
		_face_want_t = S.T
	elif S.T - _face_want_t >= FACE_HOLD:
		vface = want
		_face_want_t = -1.0
		_turn_t0 = S.T
		_turn_dir = want
		debug["face_flips"] += 1
	return vface


## Fighters in depth (docs/animation/fighters-in-depth.md; Game Design's depth.md): what the body reads from the sim's depth, all inert without it (`S.depthOn` false: every field 0, nothing posed).
## The pair's line turns him: `depth_yaw` is the angle (eased over 0.12 s, at most 0.6 rad, fading as the two part along the street) from his front to the rival, so a fight at 20 degrees to the street shows as two
## bodies turned toward each other and not as a slide. His own speed in depth is read from his depth tick to tick, so a step in depth needs no cue.
func _depth_read(S: SimState, f, dt: float) -> void:
	if not S.depthOn:
		if depth_on:
			depth_on = false
			depth_yaw = 0.0
			depth_line = 0.0
			depth_vz = 0.0
		_dz_prev = f.z
		_dz_tick = S.tick
		return
	depth_on = true
	var o = _opponent(S, f)
	var dz: float = (o.z - f.z) if o != null else 0.0
	var dx: float = absf(SimWrap.sdx(f.x, o.x)) if o != null else 1.0e9
	var ang: float = atan2(dz, maxf(dx, 1.0)) * (1.0 - smoothstep(300.0, 700.0, dx))
	ang = clampf(ang, -0.6, 0.6)
	if f.state == "launched" or f.state == "dropped" or f.state == "down":
		ang = 0.0   # a body in the air or on the ground turns by the sim's own rotation, not by the line
	depth_line = rad_to_deg(ang)
	var k: float = 1.0 if dt <= 0.0 else 1.0 - exp(-dt / 0.12)
	depth_yaw = lerpf(depth_yaw, ang, k)   # positive: the front turned toward the camera (z is positive toward it)
	var n: int = maxi(1, S.tick - _dz_tick) if _dz_tick >= 0 else 1
	depth_vz = (f.z - _dz_prev) / float(n)
	_dz_prev = f.z
	_dz_tick = S.tick


## A step in depth (the sidestep's 1 bh in 15 ticks, a brawl's drift, a slide along a face): the feet alternate as he goes, so it reads as a step and not a slide. Two poses (wave depth1: the near foot lifts and
## crosses, then the far foot catches up), mixed by the footfall phase of the distance he has moved (a footfall every 36 units); the stepping side follows the direction (the mirrored pair for the other way).
## Only on the ground, and only when he is free: a blow, a cue or a reaction draws over it.
func _depth_step_layer(S: SimState, f) -> void:
	if not depth_on or f.state != "free" or absf(f.y - WorldWater.floorAt(S, f.x, f.z)) > 8.0:
		return
	var v: float = absf(depth_vz)
	if v < 0.25:
		return
	_stride += v / 36.0
	var amp: float = smoothstep(0.6, 2.0, v) * 0.85
	if amp <= 0.001 or not AnimData.pose_exists("dp.cross_a.step"):
		return
	var ph: float = fposmod(_stride * 0.5, 1.0)
	var mir: bool = (depth_vz < 0.0) != (vface < 0.0)   # toward the camera or away, in his own model space (he is turned by his face)
	if ph < 0.5:
		_mix_pose(AnimData.pose("dp.cross_a.step", mir), sin(PI * ph * 2.0) * amp)
	else:
		_mix_pose(AnimData.pose("dp.cross_b.step", mir), sin(PI * (ph - 0.5) * 2.0) * amp)


## His rival: the one in his exchange, else the nearest (shortest arc, and depth when it is on). With two bodies it is the other one, as it always was; with more (a guard beside the Empress, one versus many) a body that
## is in the fight and not the partner looks at, and is looked at by, the nearest.
func _opponent(S: SimState, f):
	# the hold's partner when the sim gives one (a view field it will carry, `holdPartner`): in a clinch the right other body is not always the nearest
	var hp = f.get("holdPartner")
	if hp != null and S.fighters.has(hp) and hp != f:
		return hp
	var ex = S.dirS.ex
	if ex != null:
		if ex.A == f and ex.D != null:
			return ex.D
		if ex.D == f and ex.A != null:
			return ex.A
	var best = null
	var best_d: float = 1.0e18
	for o in S.fighters:
		if o == f:
			continue
		var dx: float = SimWrap.sdx(f.x, o.x)
		var dz: float = (o.z - f.z) if S.depthOn else 0.0
		var d: float = dx * dx + dz * dz
		if d < best_d:
			best_d = d
			best = o
	return best


## A body that is in the fight and not the partner (a guard waiting his turn, the Empress's other guard: one versus many, Encounter's model): free, with an exchange running that is not his. He does not stand in his
## idle: ninety ticks (1.5 s) make one round, so he interjects at most once in that time: he circles (a shuffle of small steps), raises his guard, takes one step in, and settles; and a blow that lands on the partner's
## rival within 400 units makes him flinch. From poses that exist (stance, move, react); the weights are the whole of it. Nothing with two bodies: `waiting_kind` stays "".
func _waiting_layer(S: SimState, f) -> void:
	waiting_kind = ""
	# the chase: the chaser is dived toward the rival from the start cue to the end cue (two bodies or many)
	if chase_state == "start" or chase_state == "blow":
		var cw: float = smoothstep(0.0, 4.0 * DT, S.T - _chase_t) if chase_state == "start" else 1.0
		if _chase_arrived_t >= 0.0:
			cw *= 1.0 - 0.75 * smoothstep(0.0, 4.0 * DT, S.T - _chase_arrived_t)   # arrived: the blows' own beats draw the body, the dive keeps a quarter
		if AnimData.pose_exists("rt.chase.dive") and f.state == "free":
			_mix_pose(AnimData.pose("rt.chase.dive", vface < 0.0), 0.55 * cw)
	elif chase_state == "end":
		chase_state = ""
	if not interject.is_empty():
		var tl: float = S.T
		var land: float = float(interject.land)
		var dur: float = float(interject.dur)
		if tl > land + 4.0 * DT:
			interject = {}
		elif AnimData.pose_exists("rt.interject.tell") and f.state == "free":
			var iw: float = smoothstep(land - dur, land - dur * 0.55, tl) * (1.0 - smoothstep(land, land + 4.0 * DT, tl))
			_mix_pose(AnimData.pose("stance.aggressive"), 0.4 * iw)
			_mix_pose(AnimData.pose("rt.interject.tell", vface < 0.0), 0.85 * iw)
			waiting_kind = "interject"
			return
	if S.fighters.size() <= 2 or f.state != "free":
		return
	var ex = S.dirS.ex
	if ex == null or ex.A == f or ex.D == f:
		return
	var ph: int = (S.tick + slot * 23) % 90
	var kind: String = "circle"
	var w_g: float = 0.35   # the guard's baseline: a little raised
	if ph >= 45 and ph < 61:
		kind = "guard"
		w_g = lerpf(0.35, 0.75, smoothstep(45.0, 50.0, float(ph)) * (1.0 - smoothstep(56.0, 61.0, float(ph))))
	elif ph >= 61 and ph < 73:
		kind = "step_in"
	elif ph >= 73:
		kind = "settle"
		w_g = lerpf(0.5, 0.35, smoothstep(73.0, 89.0, float(ph)))
	var sd: AnimPose = AnimData.pose("stance.defensive")
	_mix_pose(sd, w_g)
	var vface_s: bool = vface < 0.0
	match kind:
		"circle":
			var half: int = (ph / 22) % 2
			var tt: float = float(ph % 22) / 22.0
			_mix_pose(AnimData.pose("move.step_f" if half == 0 else "move.step_b", vface_s), 0.3 * sin(PI * tt))
		"step_in":
			var tt2: float = float(ph - 61) / 12.0
			_mix_pose(AnimData.pose("move.step_f", vface_s), 0.55 * sin(PI * tt2))
			_mix_pose(AnimData.pose("stance.aggressive"), 0.35 * sin(PI * tt2))
	# a blow lands on one of the two in the exchange close by: a flinch for the length of his reaction, by distance
	for rv in [ex.A, ex.D]:
		if rv == null or rv == f:
			continue
		var rf: AnimFighter = RenderAnim.fighter(S, rv)
		if not rf._reacts.is_empty():
			var near: float = 1.0 - smoothstep(150.0, 400.0, absf(SimWrap.sdx(f.x, rv.x)))
			if near > 0.01:
				kind = "flinch"
				_mix_pose(AnimData.pose("react.flinch_b", vface_s), 0.5 * near)
	waiting_kind = kind


func _wanted_face(S: SimState, f) -> float:
	var opp = _opponent(S, f)
	var dx: float = SimWrap.sdx(f.x, opp.x) if opp != null else 0.0
	var ex = S.dirS.ex
	var engaged: bool = (ex != null and (ex.A == f or ex.D == f)) or f.state == "locked" or f.beamCharge != null
	if engaged:
		return signf(dx) if absf(dx) > FACE_DEAD else 0.0
	if f.state == "free" and absf(f.vx) > TRAVEL_FACE:
		var travel: float = signf(f.vx)
		# backing away from a close opponent keeps the face on him (the retreat pose); any other run faces the way it goes
		if travel != signf(dx) or absf(dx) > NEAR_LOOK or int(f.stance) == 3:
			return travel
		return signf(dx)
	if f.state == "free" and opp != null and absf(dx) > FACE_DEAD and absf(dx) < NEAR_LOOK and int(f.stance) != 3:
		return signf(dx)
	return f.face


static func _hash(a: int, b: int, c: int) -> int:
	var h: int = (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return (h ^ (h >> 16)) & 0xFFFFFFFF


static func _ease_out_back(u: float, ov: float) -> float:
	return 1.0 - (1.0 - u) * (1.0 - u) + ov * sin(PI * u) * u


func _mixh(dst_h: Vector3, src_h: Vector3, w: float) -> Vector3:
	return dst_h.lerp(src_h, w)


# ------------------------------------------------------------------ the solve

func solve(S: SimState, f, prof: Dictionary) -> void:
	_prof = prof
	# On twos: a snappy fighter with nothing happening (no exchange, cue, reaction or beam) solves every second tick and the
	# bone writes are skipped on the others. A blow always solves, so no contact frame is missed.
	if version > 0 and float(prof.get("solve_hz", 60.0)) < 59.0 and (S.tick & 1) == 1 and _idle(S, f):
		frame = RenderAnim._frame_key(S)
		return
	version += 1
	update_face(S, f)
	_wound_read(f)
	var T: float = S.T
	var dt: float = clampf(T - _last_T, 0.0, 0.1) if _last_T >= 0.0 else 0.0
	_depth_read(S, f, dt)
	var first: bool = _last_T < 0.0
	_last_T = T
	_set_lag(float(prof.get("lag", 0.3)))
	# 1. the base pose: what the fighter is doing when no blow, cue or reaction is on (a launch or a power-up moves on the
	# fluid profile, the rest on the default)
	_target_base(S, f, T)
	var bprof: Dictionary = _part_prof("launch") if f.state == "launched" else (_part_prof("power") if f.state == "charging" else prof)
	var k: float = 1.0 if first else 1.0 - exp(-dt / maxf(float(bprof.get("base_tau", 0.08)), 0.001))
	if _settle <= 40 or first:
		if RenderAnim.layer("transitions") and not first and _base_lagged():
			# the arms and hands follow the torso a little later (a guard comes up with overlap, not as one block)
			var e0: float = 1.0 - k
			for i in range(AnimRig.N):
				var kt: float = 1.0 - pow(e0, _base_r[i])
				_base[i] = AnimJoints.slerp_limb(_base[i], _tq[i], kt) if (AnimJoints.ik_limits and AnimJoints.is_limb[i] == 1) else _base[i].slerp(_tq[i], kt)
		else:
			AnimPose.mix(_base, _tq, k)
		_base_hips = _base_hips.lerp(_tq_hips, k)
		_base_curl = _base_curl.lerp(_tq_curl, k)
	elif _settle == 41:
		for i in range(AnimRig.N):
			_base[i] = _tq[i]
		_base_hips = _tq_hips
		_base_curl = _tq_curl
	for i in range(AnimRig.N):
		q[i] = _base[i]
	hips = _base_hips
	curl = _base_curl
	_depth_step_layer(S, f)
	_waiting_layer(S, f)
	# 2. a cue pose from Combat's cue events
	if not _cue.is_empty():
		var t: float = T - float(_cue.t0)
		var d: float = float(_cue.dur)
		if t >= d:
			_cue = {}
		elif t >= 0.0:
			var w: float = smoothstep(0.0, RenderLook.CUE_IN, t) * (1.0 - smoothstep(d - RenderLook.CUE_OUT, d, t))
			var cp: AnimPose = AnimData.pose(String(AnimData.cue_poses[_cue.kind]))
			AnimPose.mix(q, cp.q, w * 0.9)
			hips = hips.lerp(cp.hips, w * 0.9)
			curl = curl.lerp(cp.curl, w * 0.9)
	if not _seq.is_empty():
		if T >= float(_seq.t0) + float(_seq.dur) + 0.05:
			_seq = _seq_next
			_seq_next = {}
		else:
			var sq_w: float = float(_seq.get("wt", 1.0))
			var sq_id: String = String(_seq.id)
			if sq_id.begins_with("s3.perfect_block") or sq_id.begins_with("s3.reversal"):
				sq_w *= _rip_fade(S, f, T)   # the block pose gives way to the riposte that leaves from it
			_entry_layer(float(_seq.t0), float(_seq.dur), sq_id, T, 1.0 / float(_prof.get("solve_hz", 60.0)), sq_w, bool(_seq.get("fit", false)))
	if f.state == "intro" and RenderAnim.intro_poses and not AnimData.intro.is_empty():
		if _intro.is_empty():
			# the first frame, before any event has been drained (the sim sets the state at the start, the events come with the first tick): he is already falling
			_intro = {"on": true, "fall_t": -1.0, "fall_dur": 0.6, "land_t": -1.0, "stare_t": -1.0, "stare_dur": 2.6}
		_intro_layer(S, f)
	if _ls_t0 >= 0.0 and AnimData.pose_exists("ls.hold.resolve") and f.state == "free":
		var LS: Dictionary = AnimData.last_stand
		var lw: float = smoothstep(0.0, float(LS.get("in", 0.6)), T - _ls_t0)
		if _ls_t1 >= 0.0:
			lw *= 1.0 - smoothstep(0.0, float(LS.get("out", 0.5)), T - _ls_t1)
			if T - _ls_t1 >= float(LS.get("out", 0.5)):
				_ls_t0 = -1.0
				_ls_t1 = -1.0
		lw *= float(LS.get("hold_weight", 0.3)) * (0.6 if RenderAnim.reduced_motion else 1.0)
		if lw > 0.001:
			var rp: AnimPose = AnimData.pose("ls.hold.resolve")
			AnimPose.mix(q, rp.q, lw)
			hips = hips.lerp(rp.hips, lw)
			curl = curl.lerp(rp.curl, lw)
	_agency_layer(S, f, T)
	_energy_layer(S, f, T)
	if not _gest.is_empty():
		_gesture_layer(S, f, T)
	if _gc_hold_t0 >= 0.0 and AnimData.pose_exists("gc.hold.brace_tumble"):
		var hin: float = float(AnimData.ground.get("hold", {}).get("in", 0.08))
		var hout: float = float(AnimData.ground.get("hold", {}).get("out", 0.15))
		var hw: float = smoothstep(0.0, hin, T - _gc_hold_t0)
		if _gc_hold_t1 >= 0.0:
			hw *= 1.0 - smoothstep(0.0, hout, T - _gc_hold_t1)
			if T - _gc_hold_t1 >= hout:
				_gc_hold_t0 = -1.0
				_gc_hold_t1 = -1.0
		if hw > 0.001:
			var bt: AnimPose = AnimData.pose("gc.hold.brace_tumble")
			AnimPose.mix(q, bt.q, hw * _gc_hold_w)
			hips = hips.lerp(bt.hips, hw * _gc_hold_w)
			curl = curl.lerp(bt.curl, hw * _gc_hold_w)
	if _skim_t0 >= 0.0:
		var sk_t: float = T - _skim_t0
		if sk_t > 0.35:
			_skim_t0 = -1.0
		elif sk_t >= 0.0:
			_mix_pose(AnimData.pose("skip.water"), smoothstep(0.0, 0.04, sk_t) * (1.0 - smoothstep(0.12, 0.35, sk_t)) * 0.85)
	# 3. the exchange: approach and strike parts
	_part = ""
	_skip_inertia = false
	_blow_snap = false
	_ci_w = 0.0
	_rushing = false
	_contact_now = false
	_tc_left = -1.0
	_pr_dx = 0.0
	press = {}
	riposte = {}
	AnimZip.layers(self, S, f, T, dt)
	var ex = S.dirS.ex
	if ex != null and (ex.A == f or ex.D == f):
		_exchange_layers(S, f, ex, T)
	if riposte.is_empty() and not _rip_cue.is_empty():
		# the riposte cue has come and the blow's own beat is not in the exchange yet: VFX is told what is coming
		var rip_left: int = int(_rip_cue.ahead) - (S.tick - int(_rip_cue.tick))
		if rip_left >= -12:
			riposte = {"kind": String(_rip_cue.kind), "reversal": false, "sure": false, "ticks_to_contact": rip_left, "cue": true}
		else:
			_rip_cue = {}
	# 4. the signature beam, and a transformation
	_beam_layer(S, f, T)
	_struggle_layer(S, f, dt)
	if not _form.is_empty():
		_transform_layer(S, T)
	# 4a. the head looks at the opponent
	if RenderAnim.layer("look"):
		_look_at(S, f, dt)
	# 4b. a broken arm hangs, a broken leg is favoured
	if _arm_broken or _leg_broken:
		_wound_limbs(f, T)
	# 5. reactions to blows
	_recoil_x = 0.0
	_recoil_y = 0.0
	_step_x = 0.0
	_reaction_layer(T)
	# 5a. feet on the slope under him, a skid pitched to the ground (before the contact solve, so a blow reaches from the new stance)
	if RenderAnim.layer("feet"):
		var tf: int = Time.get_ticks_usec() if RenderAnim.debug_checks else 0
		_ground_feet(S, f, dt)
		if RenderAnim.debug_checks:
			debug["feet_usec"] += Time.get_ticks_usec() - tf
			debug["feet_n"] += 1
	if RenderAnim.joint_audit:
		audit = {"A": AnimJoints.violations(q, _rd.shape_key)}
	# 5b. the striking limb reaches the defender (the contact solve)
	if _ci_w > 0.001:
		_contact_ik(S, f)
	if RenderAnim.joint_audit:
		audit["B"] = AnimJoints.violations(q, _rd.shape_key)
	# 5c. the active ragdoll: the body's own motion on top of the pose (the pose is in charge while a blow is thrown)
	if _rd.out_w > 0.001:
		_rd.apply(q, _rd.out_w * (0.3 if (_part != "" or _ci_w > 0.001) else 1.0), _rd_scale())
	if RenderAnim.joint_audit:
		audit["C"] = AnimJoints.violations(q, _rd.shape_key)
	# 5d00. flight overhaul (unit G): the burst and the brake poses, the bank, the shudder of a nearby impact
	if RenderAnim.layer("flight"):
		_flight_layers(T, f)
	# 5d01. the winner in the wreckage (unit K)
	if RenderAnim.layer("personality"):
		_win_layer(S, f, T)
	# 5d0. idles and transitions with personality (overhaul unit F): the weight shift, the knee bounce and the breath of the stance and
	# the form, and a turn-around as a step
	if RenderAnim.layer("personality") and (f.state == "free" or f.state == "locked") and _part == "" and _ci_w < 0.001:
		var calm: float = 1.0 - clampf(absf(f.vx) / 300.0, 0.0, 1.0)
		if f.state == "free" and calm > 0.05:
			_personality_layer(T, int(f.stance), clampi(int(f.tier) - 1, 0, 3), calm)
		_turn_layer(T)
	# 5d. polish: lean into acceleration (free flight and movement), the hover bob
	if RenderAnim.layer("lean"):
		if absf(_lean) > 0.002:
			q[AnimRig.index["pelvis"]] = q[AnimRig.index["pelvis"]] * Quaternion(Vector3(0, 0, 1), -_lean * 0.6)
			q[AnimRig.index["spine_2"]] = q[AnimRig.index["spine_2"]] * Quaternion(Vector3(0, 0, 1), -_lean * 0.4)
		if _air_w > 0.3:
			hips.y += sin(T * TAU * 0.7 + slot * 1.3) * 1.4 * _air_w * _rd_amp()
			q[AnimRig.index["spine_2"]] = q[AnimRig.index["spine_2"]] * Quaternion(Vector3(0, 0, 1), sin(T * TAU * 0.5 + slot) * 0.03 * _air_w * _rd_amp())
	# 6. moving hold, hit-stop shiver, spring chains
	var drift: float = float(prof.get("hold_drift", 0.0))
	if drift > 0.0:
		q[AnimRig.index["spine_2"]] = q[AnimRig.index["spine_2"]] * Quaternion(Vector3(0, 0, 1), sin(T * 2.3 + slot * 1.7) * 0.014 * drift)
		q[AnimRig.index["head"]] = q[AnimRig.index["head"]] * Quaternion(Vector3(0, 0, 1), sin(T * 1.7 + slot) * 0.02 * drift)
	if _worn > 0.04 or _brinkp > 0.4:
		_wear_motion(f, T)
	var shiver: float = float(prof.get("shiver", 0.0))
	if S.dirS.stop > 0.0:
		_stop_pk = maxf(_stop_pk, S.dirS.stop)
	else:
		_stop_pk = 0.0
	var shv := Vector3.ZERO
	if S.dirS.stop > 0.0 and shiver > 0.0:
		# the shake follows the stop's weight: a mashed light's 2 ticks a little over half the profile's, 8 ticks as before, a launch's 12 a fifth more, a decisive blow's 20 and the KO's 24 at most 1.6
		var wk: float = clampf(sqrt(_stop_pk * 60.0 / 8.0), 0.5, 1.6) if RenderAnim.shiver_by_weight else 1.0
		shv = Vector3(_signed(S.tick, slot), _signed(S.tick + 13, slot) * 0.6, 0.0) * shiver * wk
	elif RenderAnim.shiver_by_weight and shiver > 0.0 and S.T - _shake_t0 < SHAKE_S:
		var sk: float = _shake_k * (1.0 - (S.T - _shake_t0) / SHAKE_S)
		shv = Vector3(_signed(S.tick, slot), _signed(S.tick + 13, slot) * 0.6, 0.0) * shiver * sk
	root_off = shv   # the root's own offset starts again from nothing each frame, as it did
	if RenderAnim.debug_checks:
		debug["shiver"] = shv.length()
	root_off.x += _recoil_x + _step_x + _pr_dx
	root_off.y += _zip_dy
	if _lean_t0 > -5.0 or _over_t0 > -5.0 or _block_t0 > -5.0:
		root_off.x += _evade_offsets(T)
	root_off.y += _recoil_y
	if _smear != 0.0:
		root_off.x += _smear_now(T)
		if T - _smear_t0 >= 0.05:
			_smear = 0.0
	_springs(f)
	_follow_apply()
	# 6a. inertialisation: a join in the solved pose decays instead of popping
	_inertialise(dt, prof)
	if RenderAnim.debug_checks:
		layers = ("cue:" + String(_cue.get("kind", "")) + " " if not _cue.is_empty() else "") + ("rush " if _rushing else "") + ("react " if not _reacts.is_empty() else "") + ("ik " if _ci_w > 0.001 else "") + ("beam " if f.beamCharge != null else "") + (f.state + " ")
	_hold_feed(S, f, T)
	_grip_layer(S, f, dt)
	_ack_layer(S, f, dt)
	_loco_layer(S, f, dt)
	_ground_layer(S, f, dt)
	_pop_layer(S, f, dt)
	_air_recover_layer(S, f, dt)
	_air_brake_layer(S, f, dt)
	_recoil_layer(S, f, dt)
	_lead_layer(S, f, dt)
	if not zip.is_empty() or absf(_zip_tilt) > 0.002 or _zip_depth != 0.0 or (f.rush != null and float(f.rush.arc) != 0.0):
		AnimZip.orient(self, S, f, dt)
	_free_arm_slew(dt, String(f.state))
	# 6b. the limb pass: elbows and knees stay hinges in human range, arms stay out of the shoulder's blind spot
	if RenderAnim.joint_audit:
		audit["D"] = AnimJoints.violations(q, _rd.shape_key)
	debug["limit_fix"] = AnimPose.limit_limbs(q, _rd.shape_key)
	# 7. sockets: only the chains the views read (the head and the near hand); the rest is on demand
	AnimPose.fk_chain(q, hips, gq, gp, SOCKET_CHAIN)
	_full_fk = false
	if RenderAnim.press_styles:
		_press_record(T, f)
	if is_nan(q[0].x) or is_nan(q[5].w):
		debug["nan"] += 1
		q[0] = Quaternion.IDENTITY
	elif RenderAnim.debug_checks:
		for i in range(AnimRig.N):
			if is_nan(q[i].x) or is_nan(q[i].w):
				debug["nan"] += 1
				q[i] = Quaternion.IDENTITY
	frame = RenderAnim._frame_key(S)


## Nothing is asking for a precise pose this tick.
func _idle(S: SimState, f) -> bool:
	var ex = S.dirS.ex
	return (ex == null or (ex.A != f and ex.D != f)) and _cue.is_empty() and _seq.is_empty() and _shove_watch == 0 and _stun_watch == 0 and _reacts.is_empty() and f.beamCharge == null and S.beams.is_empty() and S.dirS.stop <= 0.0 and _form.is_empty() and _rd.out_w <= 0.001


## A blow counts as heavy from the exchange kind, the strike's own weight (o.big) or its damage.
static func _is_heavy(ex, args: Dictionary) -> bool:
	var o = args.get("o")
	return ex.kind == "heavy" or (o != null and bool(o.get("big", false))) or float(args.get("dmg", 0.0)) >= 40.0


static func _signed(tick: int, s: int) -> float:
	return float(_hash(tick, s, 7) & 1023) / 511.5 - 1.0


var _tq_hips := Vector3.ZERO
var _tq_curl := Vector2(0.5, 0.5)


func _target_base(S: SimState, f, T: float) -> void:
	var stance: int = clampi(int(f.stance), 0, 3)
	var vf: float = f.vx * vface
	var state: String = f.state
	# The blend weights, quantised to sixteenths: while they and the stance do not change the target is not rebuilt (the
	# base smoothing hides the steps), and once it has settled the smoothing stops too.
	var w1: float = 0.0
	var w2: float = 0.0
	var w3: float = 0.0
	var w4: float = 0.0              # hovering
	var w5: float = 0.0              # climbing
	var w6: float = 0.0              # diving
	var w7: float = 0.0              # winded (1) or relaxed (0.5) idle
	var w8: float = 0.0              # sprint, on top of the dash
	var w9: float = 0.0              # a guarded step forward
	var w10: float = 0.0             # a guarded step back
	var w11: float = 0.0             # the stance sagging toward the brink
	var w12: float = 0.0             # skidding on the back (moving away from the way he faces)
	var w13: float = 0.0             # skidding face down
	var w15: float = 0.0             # the push-up stage of a get-up
	var w16: int = 0                 # the winner's beat (1 stand, 2 survey, 3 the end)
	var w17: float = 0.0             # a KO's fall, 0 to 1 over the first half second down
	var w14: float = 0.0             # the rise out of the crouch after it (slower when worn)
	if state == "down":
		_was_down = true
	elif _was_down:
		_was_down = false
		_rise_t0 = T
		_rise_dur = 0.25 + 0.55 * maxf(_worn, _brinkp)
		if RenderAnim.ground_poses and RenderAnim.layer("transitions") and AnimData.entries.has("gc.getup_quick") and _seq.is_empty():
			var slow: bool = maxf(_worn, _brinkp) > float(AnimData.ground.get("getup", {}).get("slow_above", 0.45))
			_seq = {"id": "gc.getup_slow" if slow else "gc.getup_quick", "t0": T, "dur": _rise_dur, "wt": 1.0, "getup": true}
			_rise_t0 = -1.0   # the sequence is the rise; the blend toward down.getup would double it
	if _rise_t0 >= 0.0 and RenderAnim.layer("transitions"):
		var rt: float = T - _rise_t0
		if rt >= _rise_dur:
			_rise_t0 = -1.0
		elif state == "free":
			w14 = 1.0 - smoothstep(0.0, _rise_dur, rt)
	_air_w = 0.0
	var mode: int = 0
	if f.slide > 0.0:
		mode = 1
		var sk: float = smoothstep(250.0, 600.0, absf(f.vx))
		if vf < 0.0:
			w12 = sk
		else:
			w13 = sk
	elif state == "launched" or state == "dropped":
		var speed: float = Vector2(f.vx, f.vy).length()
		w1 = smoothstep(700.0, 2200.0, speed)
		w2 = (1.0 - smoothstep(150.0, 600.0, speed)) * 0.7
		mode = 2
	elif state == "down":
		if RenderAnim.ragdoll_enabled:
			w1 = smoothstep(0.5, 0.72, f.stateT)
			w15 = smoothstep(0.28, 0.5, f.stateT)
		else:
			w1 = smoothstep(0.42, 0.72, f.stateT)
		mode = 7 if is_same(S.game.ko, f) else 3
		w17 = smoothstep(0.0, 0.5, f.stateT) if RenderAnim.layer("personality") else 1.0
	elif state == "charging":
		mode = 4
	elif S.game.ko != null and not is_same(S.game.ko, f) and S.game.koT > float(AnimData.winner.get("start", 0.8)) and state == "free":
		mode = 6
		w16 = _win_phase(S.game.koT, String(f.id)) if RenderAnim.layer("personality") else 4
	else:
		w1 = smoothstep(140.0, 720.0, vf)
		w2 = smoothstep(140.0, 520.0, -vf) * (1.0 - w1)
		if w1 > 0.01:
			w3 = clampf(atan2(f.vy, maxf(absf(f.vx), 60.0)), -0.9, 0.9) * 0.7 * w1
		w8 = smoothstep(1000.0, 2200.0, vf)
		w9 = smoothstep(50.0, 180.0, vf) * (1.0 - smoothstep(300.0, 600.0, vf))
		w10 = smoothstep(50.0, 160.0, -vf) * (1.0 - smoothstep(260.0, 480.0, -vf))
		mode = 5
		if state == "free":
			w11 = smoothstep(0.35, 1.0, _brinkp) * 0.7
		# the variants: hovering (feet off the ground), climbing, diving; on the ground a winded idle when the ki is spent and
		# a relaxed one far from the opponent
		if state == "free" and w1 < 0.05 and w2 < 0.05:
			var air: float = smoothstep(30.0, 70.0, f.y - WorldWater.floorAt(S, f.x, f.z))
			if air > 0.0:
				w4 = air
				_air_w = air
				w5 = air * smoothstep(150.0, 600.0, f.vy)
				w6 = air * smoothstep(150.0, 600.0, -f.vy)
			elif f.ki < 6.0:
				w7 = 1.0
			elif int(f.stance) < 2 and absf(f.vx) < 100.0:
				var opp = _opponent(S, f)
				if opp != null and absf(SimWrap.sdx(f.x, opp.x)) > IDLE_FAR:
					w7 = 0.5
	var key: int = mode | (stance << 3) | (int(w1 * 16.0) << 5) | (int(w2 * 16.0) << 10) | (int((w3 + 1.0) * 24.0) << 15) | (int(w4 * 8.0) << 21) | (int(w5 * 8.0) << 25) | (int(w6 * 8.0) << 29) | (int(w7 * 2.0) << 33) | (int(w8 * 8.0) << 35) | (int(w9 * 8.0) << 39) | (int(w10 * 8.0) << 43) | (int(w11 * 8.0) << 47) | (int(w12 * 8.0) << 50) | (int(w13 * 8.0) << 54)
	var key2: int = int(w15 * 8.0) | (int(w14 * 8.0) << 4) | (w16 << 8) | (int(w17 * 8.0) << 11)
	if key == _bkey and key2 == _bkey2:
		_settle += 1
		return
	_bkey = key
	_bkey2 = key2
	_settle = 0
	var vk: String = ""
	if mode == 7:
		vk = "ko"
	elif mode == 6:
		vk = "victory"
	elif w4 > 0.5:
		vk = "hover" if w5 < 0.5 and w6 < 0.5 else ("climb" if w5 >= w6 else "dive")
	elif w8 > 0.5:
		vk = "sprint"
	elif w9 > 0.5 or w10 > 0.5:
		vk = "step"
	elif w7 >= 1.0:
		vk = "winded"
	elif w7 > 0.0:
		vk = "relaxed"
	if vk != "":
		debug["variants"][vk] = int(debug["variants"].get(vk, 0)) + 1
	var sp: AnimPose = AnimData.pose("stance." + STANCES[stance])
	for i in range(AnimRig.N):
		_tq[i] = sp.q[i]
	_tq_hips = sp.hips
	_tq_curl = sp.curl
	match mode:
		1:
			_blend_target("slide.brake", 1.0)
			_blend_target("skid.back", w12)
			_blend_target("skid.front", w13)
		2:
			_blend_target("launch.spread", 1.0)
			_blend_target("launch.stream", w1)
			_blend_target("launch.tuck", w2)
		3:
			_blend_target("down.prone", 1.0)
			_blend_target("getup.push", w15)
			_blend_target("down.getup", w1)
		4:
			_blend_target("charge.hold", 1.0)
		6:
			match w16:
				1:
					_blend_target("win.stand", 1.0)
				2:
					_blend_target("win.survey", 1.0)
				_:
					_blend_target("emote.victory" if (w16 == 4 or _win_end(String(f.id)) == "victory") else "win.survey", 1.0)
		7:
			# a KO falls: a stagger first, then flat on the back
			_blend_target("react.stagger", (1.0 - w17) * 0.8)
			_blend_target("down.ko", w17)
		_:
			_blend_target("move.dash", w1)
			_blend_target("move.retreat", w2)
			_blend_target("move.sprint", w8)
			_blend_target("move.step_f", w9)
			_blend_target("move.step_b", w10)
			_blend_target("wound.sag", w11)
			_blend_target("down.getup", w14 * 0.75)
			_blend_target("stance.air", w4)
			_blend_target("move.ascend", w5)
			_blend_target("move.descend", w6)
			if w7 >= 1.0:
				_blend_target("idle.winded", 1.0)
			elif w7 > 0.0:
				_blend_target("idle.relaxed", 0.8)
			if w3 != 0.0:
				var pi_: int = AnimRig.index["pelvis"]
				_tq[pi_] = _tq[pi_] * Quaternion(Vector3(0, 0, 1), w3)


func _blend_target(id: String, w: float) -> void:
	if w <= 0.001:
		return
	var p: AnimPose = AnimData.pose(id)
	AnimPose.mix(_tq, p.q, w)
	_tq_hips = _tq_hips.lerp(p.hips, w)
	_tq_curl = _tq_curl.lerp(p.curl, w)


func _mix_pose(p: AnimPose, w: float) -> void:
	AnimPose.mix(q, p.q, w)
	hips = hips.lerp(p.hips, w)
	curl = curl.lerp(p.curl, w)


func _set_pose(p: AnimPose) -> void:
	for i in range(AnimRig.N):
		q[i] = p.q[i]
	hips = p.hips
	curl = p.curl


# ------------------------------------------------------------------ the exchange

## How heavy a blow is, continuously: the damage over 70 (a chain link, which carries no damage, counts as 1). It stretches the
## load, the follow-through and the recovery and deepens the overshoot (overhaul unit D); the contact tick never moves.
static func _blow_weight(args: Dictionary) -> float:
	if not RenderAnim.ragdoll_enabled:
		return 0.7   # neutral: the A/B off switch leaves the blow's timing as it was
	var d: float = float(args.get("dmg", -1.0))
	if d < 0.0:
		var o = args.get("o")
		return 1.0 if (o != null and bool(o.get("big", false))) else 0.6
	return clampf(d / 70.0, 0.2, 1.4)


## Go-live step 1 (docs/combat/pending/golive-step1.md), only with RenderAnim.wave1_live (--wave1-live, OFF by default): the key set of a blow of the
## Anti-hero's shape from wave 1's lists. The list is walked, not hashed blow by blow: it starts at a hash of the exchange and the fighter and takes
## every third entry (every fifth when the list has a multiple of three), so nothing repeats inside ten blows; a two-limb key set is skipped when a
## limb of its kind is drawn as broken; the gated key sets (the sweep with both fighters on the ground, the drop kick with the striker in the air)
## join the list only while their gate is open. Returns "" when not applicable (the flag is off, another fighter's shape, no data).
func _live_pick(S: SimState, f, ex, ordinal: int, heavy: bool) -> String:
	if not RenderAnim.wave1_live:
		return ""
	var lv: Dictionary = AnimData.live
	if lv.is_empty():
		return ""
	var sk: String = String(AnimRagdoll.shape_of.get(String(f.id), AnimRagdoll.shape_of.get("default", "")))
	if not (lv.get("shapes", []) as Array).has(sk):
		return ""
	var which: String = "heavy" if heavy else "light"
	var cand: Array = (lv.picks[which] as Array).duplicate()
	var opp = ex.D if ex.A == f else ex.A
	for g in lv.get("gated", []):
		if String(g.weight) != which:
			continue
		var open: bool = false
		match String(g.gate):
			"both_ground":
				open = f.y - WorldWater.floorAt(S, f.x, f.z) < 8.0 and opp != null and opp.y - WorldWater.floorAt(S, opp.x, opp.z) < 8.0
			"striker_air":
				open = f.y - WorldWater.floorAt(S, f.x, f.z) > 20.0
		if open:
			cand.append(String(g.keyset))
	var n: int = cand.size()
	if n == 0:
		return ""
	var stepw: int = 3 if n % 3 != 0 else 5
	var h: int = _hash(int(ex.n), slot, 11)
	for tries in range(n):
		var id: String = String(cand[(h + stepw * (ordinal + tries)) % n])
		var ks = AnimData.keysets.get(id)
		if ks == null:
			continue
		var two: String = String(ks.get("limb2", ""))
		if two != "" and ((_arm_broken and (two.begins_with("hand") or two.begins_with("elbow"))) or (_leg_broken and (two.begins_with("foot") or two.begins_with("knee")))):
			continue
		debug["live_picks"] = int(debug.get("live_picks", 0)) + 1
		return id
	return ""


## An entry (data/anim/waves/*.entries.json, parked: no live beat names one yet): a sequence of poses over `dur` seconds. A phase with
## `ticks` holds that long, the others share the rest by their weight `w`; the poses cross-fade over three ticks at each boundary. The
## strike that follows takes over from here by its own load (the join is inertialised).
func _entry_layer(es: float, dur: float, id: String, T: float, dq: float, wt: float = 1.0, fit: bool = false) -> void:
	var en = AnimData.entries.get(id)
	if en == null or T < es - 0.0001 or T >= es + dur + 0.05:
		return
	var ph: Array = en.phases
	var fixed: float = 0.0
	var sumw: float = 0.0
	for p in ph:
		if p.has("ticks"):
			fixed += float(p.ticks) * DT
		else:
			sumw += float(p.get("w", 1.0))
	var flex: float = maxf(dur - fixed, DT)
	var bounds: Array = [0.0]
	for p in ph:
		var seg: float = float(p.ticks) * DT if p.has("ticks") else flex * float(p.get("w", 1.0)) / maxf(sumw, 0.001)
		bounds.append(float(bounds[-1]) + seg)
	if fit and float(bounds[-1]) > 0.0001:
		# a zip plays an entry at its own speed: every phase shrinks together so the whole sequence fits the zip's ticks
		var fk: float = dur / float(bounds[-1])
		for bi in range(bounds.size()):
			bounds[bi] = float(bounds[bi]) * fk
	var tt: float = floorf(clampf(T - es, 0.0, dur) / dq + 0.0001) * dq
	var e: float = 1.5 * DT
	var base_q: Array[Quaternion] = []
	var base_h: Vector3 = hips
	var base_c: Vector2 = curl
	if wt < 0.999:
		base_q = q.duplicate()
	_mix_pose(AnimData.pose(String(ph[0].pose)), 1.0)
	for i in range(1, ph.size()):
		var w: float = smoothstep(float(bounds[i]) - e, float(bounds[i]) + e, tt)
		if w > 0.001:
			_mix_pose(AnimData.pose(String(ph[i].pose)), w)
	if wt < 0.999:
		for i in range(AnimRig.N):
			q[i] = base_q[i].slerp(q[i], wt)
		hips = base_h.lerp(hips, wt)
		curl = base_c.lerp(curl, wt)
	debug["entries"] = int(debug.get("entries", 0)) + 1


func _exchange_layers(S: SimState, f, ex, T: float) -> void:
	burst_set = 0.0
	dig_w = 0.0
	hold_coil = 0.0
	var role: String = "A" if ex.A == f else "D"
	var t0: float = T - ex.t
	var strikes: Array = []
	var rushes: Array = []
	var entries: Array = []   # parked entry sequences (data/anim/waves/*.entries.json), played by an `entry` beat or a rush beat that names one
	var ordinal: int = 0
	# a parried exchange: only the blows timed before the parry are drawn (the sim keeps listing, and later firing, the rest of
	# the string; Encounter will end it there)
	var ct: float = 1.0e9
	if ex.cancel:
		if _cx_n != int(ex.n):
			_cx_n = int(ex.n)
			_cx_t = ex.t
		ct = _cx_t
	for b in ex.beats:
		if b.op == "strike":
			var who: String = String(b.args.a)
			if who == role and (not ex.cancel or b.t <= ct + 0.0001):
				var scls: String = "heavy" if _is_heavy(ex, b.args) else "light"
				strikes.append([t0 + b.t, ordinal, _rip_args(b.args, scls), scls])
			ordinal += 1
		elif b.op == "chainStrike":
			if role == "A" and (not ex.cancel or b.t <= ct + 0.0001):
				var cargs: Dictionary = {"o": {"big": true}}
				if b.args != null:
					cargs.merge(b.args, true)   # B0: a chainStrike carries a, d and the beat fields (style, grade, k, n, closing, charge, hand, ender) as a strike does
				strikes.append([t0 + b.t, ordinal, cargs, "chain"])
			ordinal += 1
		elif b.op == "entry" and String(b.args.get("who", "A")) == role:
			entries.append([t0 + b.t, float(b.args.dur), AnimData.resolve_entry(pair_key, String(b.args.get("id", "")))])
		elif b.op == "rush" and role == "A":
			rushes.append([t0 + b.t, float(b.args.dur), AnimData.resolve_entry(pair_key, String(b.args.get("entry", "")))])
		elif b.op == "finRush" and String(b.args.w) == role:
			rushes.append([t0 + b.t, float(b.args.dur), ""])
	# approach: launch-off, flight, arrival (a rush is snappy)
	var rprof: Dictionary = _part_prof("rush")
	var rdq: float = 1.0 / float(rprof.get("solve_hz", 60.0))
	for en in entries:
		_entry_layer(float(en[0]), maxf(float(en[1]), DT), String(en[2]), T, rdq)
	for r in rushes:
		var rs: float = r[0]
		var dur: float = maxf(r[1], DT)
		if String(r[2]) != "" and AnimData.entries.has(String(r[2])):
			_entry_layer(rs, dur, String(r[2]), T, rdq)
			continue
		if T >= rs and T < rs + dur + 0.05:
			var tq: float = rs + floorf((T - rs) / rdq) * rdq
			var p: float = clampf((tq - rs) / dur, 0.0, 1.0)
			# the streak holds to the last tick: the fastest ticks of a rush are its end, and they must not be drawn in a standing pose
			var fly: float = smoothstep(0.0, 0.18, p) * (1.0 - smoothstep(0.93, 1.0, p))
			_rushing = true
			_mix_pose(AnimData.pose("move.dash"), fly)
			var off: float = 1.0 - smoothstep(0.0, minf(4.0 * DT / dur, 0.3), p)
			_mix_pose(AnimData.pose("approach.launch"), off * 0.9)
	_beat_layers(ex, role, t0, T)
	# a wound blow the sim is holding past its landing tick (the button still down at the wind-up's end: the tap rule's wait, the heavy's charge): the body stays in its chamber and loads, it does not throw the blow
	if _held_layer(S, f, T):
		return
	# strikes: the one whose window (load, snap, follow, recover) holds now, latest start first. Each blow keeps the
	# profile of its own kind: light and chain blows snappy, heavy blows fluid.
	var best: int = -1
	var best_start: float = -1.0e9
	var lens: Array = []
	var gaps: Array = []   # the ticks from the last blow's contact to each blow's own (a style row may narrow a blow thrown tight on the last: gap_amp)
	var profs: Array = []
	var psts: Array = []
	var prev_tc: float = -1.0e9
	for n in range(strikes.size()):
		var tc: float = strikes[n][0]
		var psn: String = _press_style(S, f, ex, strikes[n])
		var sp: Dictionary = _part_prof(String(strikes[n][3]))
		if psn != "":
			var pa: Dictionary = strikes[n][2]
			var cw: int = _cue_windup(tc, pa, psn)
			if cw > 0:
				debug["cue_windups"] = int(debug.get("cue_windups", 0)) + 1
				pa = pa.duplicate()
				pa["windup"] = maxi(1, roundi(float(cw) / (0.75 + 0.35 * _blow_weight(pa))))   # the sim's own wind-up, drawn whole (the window's length is this over the blow's weight factor)
			sp = _press_prof(sp, psn, pa)
			if bool(strikes[n][2].get("zip", false)):
				sp["load_ticks"] = {"light": 2, "heavy": 3}   # a zip's tell was the wind-up: the blow lands on the arrival
				sp["load_ease"] = 1.0
			elif bool(strikes[n][2].get("_rip", false)):
				var rw: Dictionary = AnimData.press.get("riposte", {}).get("windup", {})
				sp["load_ticks"] = {"light": int(rw.get("light", 2)), "heavy": int(rw.get("heavy", 3))}   # the block was the wind-up: the blow leaves from it
				sp["load_ease"] = 1.0
		profs.append(sp)
		psts.append(psn)
		var Fn: float = float(sp.get("follow_ticks", 6)) * DT * (0.85 + 0.25 * _blow_weight(strikes[n][2]))
		var Hn: float = float(sp.get("hold_ticks", 0)) * DT
		var Rn: float = float(sp.get("recover_ticks", 10)) * DT
		var Sn_: float = float(sp.get("snap_ticks", 3)) * DT
		var bw: float = _blow_weight(strikes[n][2])
		var lnom: float = float(sp.get("load_ticks", {}).get("heavy" if strikes[n][3] == "heavy" else "light", 12)) * DT * (0.75 + 0.35 * bw)
		var gap: float = tc - prev_tc
		gaps.append(gap / DT)
		var L: float = clampf(minf(lnom, gap - 0.5 * Fn), Sn_ + 2.0 * DT, lnom)
		lens.append(L)
		var start: float = tc - L
		if T >= start and T < tc + Fn + Hn + Rn and start > best_start:
			best = n
			best_start = start
		prev_tc = tc
	if best < 0:
		# between a burst's blows (the 16-tick gap after its first light, once that blow's own window is over): the set pose still shows
		var prev: int = -1
		for n2 in range(strikes.size()):
			if float(strikes[n2][0]) <= T and psts[n2] == "burst" and (prev < 0 or float(strikes[n2][0]) > float(strikes[prev][0])):
				prev = n2
		if prev >= 0:
			var brow: Dictionary = AnimData.press.get("styles", {}).get("burst", {})
			if brow.has("set"):
				_burst_set(brow.set, strikes, float(strikes[prev][0]), T)
		_x_hold_set(S, f, T, strikes)
		_dig_in(strikes, psts, T, "")
		return
	var prof: Dictionary = profs[best]
	_set_lag(float(prof.get("lag", 0.3)))
	var Sn: float = float(prof.get("snap_ticks", 3)) * DT
	var bw2: float = _blow_weight(strikes[best][2])
	var H: float = float(prof.get("hold_ticks", 0)) * DT   # the contact key held (a tech blow's beat), then the follow-through
	var F: float = float(prof.get("follow_ticks", 6)) * DT * (0.85 + 0.25 * bw2) + H
	var R: float = float(prof.get("recover_ticks", 10)) * DT * (0.9 + 0.2 * bw2)
	var dq: float = 1.0 / float(prof.get("solve_hz", 60.0))
	var tc2: float = strikes[best][0]
	var L2: float = lens[best]
	var heavy2: bool = strikes[best][3] == "heavy"
	var side: bool = (_hash(int(ex.n), int(strikes[best][1]), slot + 1) & 1) == 1
	var pstyle: String = String(psts[best])
	var ppiece: String = String(strikes[best][2].get("piece", ""))
	var prow: Dictionary = _style_row(pstyle, ppiece.begins_with("strike.bolt_") or ppiece.begins_with("strike.blast_")) if pstyle != "" else {}
	if pstyle != "" and (bool(strikes[best][2].get("zip", false)) or bool(strikes[best][2].get("_rip", false))):
		prow = prow.duplicate()
		prow["squash"] = 0.0
	var bargs: Dictionary = strikes[best][2]
	if bool(bargs.get("_rip", false)):
		riposte = {"kind": String(strikes[best][3]), "reversal": bool(bargs.get("reversal", false)), "sure": bool(bargs.get("sure", false)), "ticks_to_contact": roundi((tc2 - T) / DT)}
	var bw3: float = bw2
	if pstyle != "":
		var BT: Dictionary = AnimData.press.get("beat", {})
		if bargs.has("hand"):
			side = String(bargs.hand) == "l"   # B0: the beat names the striking side (the planner's own; today it alternates by k)
		elif bool(prow.get("alternate", false)):
			side = ((best + (_hash(int(ex.n), 0, slot + 1) & 1)) & 1) == 1   # no side on the beat: a mashed string alternates its limbs
		if pstyle == "tech" and bargs.has("grade"):
			var gd: Dictionary = BT.get("grade", {}).get(String(bargs.grade), {})
			if gd.has("ghosts"):
				prow = prow.duplicate()
				prow["ghosts"] = int(gd.ghosts)
		if pstyle == "heavy" and bargs.has("charge"):
			var cw: Dictionary = BT.get("charge", {})
			bw3 = lerpf(float(cw.get("tapped", bw2)), float(cw.get("held", 1.0)), clampf(float(bargs.charge), 0.0, 1.0))
	var picks: Array = AnimData.picks["heavy" if heavy2 else "light"]
	var ksid: String = String(picks[_hash(int(ex.n), int(strikes[best][1]), 3 + slot) % picks.size()])
	var live_id: String = _pair_pick(S, f, ex, int(strikes[best][1]), heavy2, String(strikes[best][2].get("piece", strikes[best][2].get("strike", ""))))   # his own waves first (docs/animation/pair-live.md), then go-live step 1
	if live_id == "":
		live_id = _live_pick(S, f, ex, int(strikes[best][1]), heavy2)
	if live_id != "":
		ksid = live_id
	if RenderAnim.force_keyset != "" and AnimData.keysets.has(RenderAnim.force_keyset):
		ksid = RenderAnim.force_keyset
	var ks: Dictionary = AnimData.keysets[ksid]
	var mrule: Dictionary = _medium_rule(pstyle, ksid, bargs)   # Combat's rule for a medium on 12 ticks (w4 to w8), {} for any other blow
	if ks.has("hold_t"):
		var dh: float = float(ks.hold_t) * DT - H   # a key set's own hold of the contact key (data `hold_t`): the arm does not stay up after the blow (Legal b09, h05, L1)
		H += dh
		F += dh
	# a broken arm does not strike and a broken leg does not kick: the blow uses the other limb (the sim keeps no side)
	var lb: String = String(ks.get("limb", "hand_r"))
	if lb.begins_with("hand") and _arm_broken:
		side = _hang_right
	elif lb.begins_with("foot") and _leg_broken:
		side = _leg_right
	if _arm_broken or _leg_broken:
		debug["wound_strikes"] += 1
		if (lb.begins_with("hand") and _arm_broken and (side == _hang_right) == false) or (lb.begins_with("foot") and _leg_broken and (side == _leg_right) == false):
			debug["wound_bad"] += 1
	_part = ksid
	var pc: AnimPose = AnimData.pose(String(ks["keys"][0]["pose"]), side)
	if pstyle != "" and ["medium", "super", "heavy"].has(pstyle) and bool(strikes[best][2].get("brawl", false)):
		_held_ks = ksid
		_held_side = side
		_held_style = pstyle
	var pk: AnimPose = AnimData.pose(String(ks["keys"][1]["pose"]), side)
	var pf: AnimPose = AnimData.pose(String(ks["keys"][2]["pose"]), side)
	var tq2: float = tc2 + floorf((T - tc2) / dq + 0.0001) * dq
	if T >= tc2 - 0.0001 and T < tc2 + 0.0001:
		tq2 = tc2
	var dtc: float = tq2 - tc2
	var blow_id: int = int(ex.n) * 64 + int(strikes[best][1])
	if _seen_tc != blow_id:
		# a blow the sim announced fewer than 4 ticks ahead cannot be wound up (the pose pops to its contact key)
		_seen_tc = blow_id
		debug["blows"] += 1
		var kcount: Dictionary = debug.get("keysets", {})
		kcount[ksid] = int(kcount.get(ksid, 0)) + 1
		debug["keysets"] = kcount
		if T > tc2 - 3.5 * DT:
			debug["late"] += 1
			if debug["late_notes"].size() < 30:
				debug["late_notes"].append("tick %d %s (%s), %s, the blow %.0f ms ahead" % [S.tick, ex.kind, ex.tag, role, (tc2 - T) * 1000.0])
	if T < tc2 - 0.0001:
		_tc_left = tc2 - T
	debug["parts"] += 1
	var ul: float = 1.0
	var hw: float = 1.0   # how far the hand has taken its tip: closes over the wind-up, opens over the return
	if pstyle != "":
		_press_track(blow_id, T)
	if dtc < -Sn:
		var u: float = clampf((tq2 - (tc2 - L2)) / maxf(L2 - Sn - float(prow.get("breath_ticks", 0)) * DT, DT), 0.0, 1.0)   # a style's held breath (data `breath_ticks`): the chamber is reached that many ticks early and held in plain sight
		ul = u
		hw = smoothstep(0.0, 0.7, u)
		u = clampf(u / maxf(0.05, float(ks.get("tell_at", 1.0))), 0.0, 1.0)   # a super-heavy's tell (data `tell_at`): the chamber is reached this far into the wind-up and held in plain sight to the blow
		u = pow(u, float(prof.get("load_ease", 2.0)))
		if mrule.has("u_cap"):
			u = minf(u, float(mrule.u_cap))   # a medium on 12 ticks: the chamber is cut (a flatter wind-up)
		_mix_pose(pc, u)
		if pstyle != "" and bool(prow.get("carry", false)):
			_press_carry(prow, blow_id, tq2 - (tc2 - L2))
	elif dtc < 0.0:
		_set_pose(pc)
		var u2: float = clampf((tq2 - (tc2 - Sn)) / Sn, 0.0, 1.0)
		AnimPose.mix_lag(q, pk.q, u2, _lag, 1.0)
		hips = pc.hips.lerp(pk.hips, u2)
		curl = pc.curl.lerp(pk.curl, u2)
	elif dtc < F:
		_set_pose(pk)
		var u3: float = clampf((dtc - H) / maxf(F - H, DT), 0.0, 1.0)
		var w3: float = _ease_out_back(u3, float(prof.get("overshoot", 0.1)) * (0.6 + 0.8 * bw2))
		AnimPose.mix(q, pf.q, w3)
		hips = pk.hips.lerp(pf.hips, w3)
		curl = pk.curl.lerp(pf.curl, w3)
	else:
		_set_pose(pf)
		var u4: float = clampf((dtc - F) / R, 0.0, 1.0)
		var w4: float = u4 * u4 * (3.0 - 2.0 * u4)
		if pstyle != "":
			AnimPose.mix(q, _base, w4)   # the return of a styled blow goes by swing and twist: a plain slerp from a long follow-through folds the arm's own twist
		else:
			for i in range(AnimRig.N):
				q[i] = q[i].slerp(_base[i], w4)
		hips = pf.hips.lerp(_base_hips, w4)
		curl = pf.curl.lerp(_base_curl, w4)
		hw = 1.0 - w4
	var gamp: float = _gap_amp(prow, float(gaps[best]))
	if gamp < 0.999 and _base.size() == AnimRig.N:
		AnimPose.mix(q, _base, 1.0 - gamp)   # a burst: the closer the blows, the shorter each one (the pose stays nearer the guard it came from)
		hips = hips.lerp(_base_hips, 1.0 - gamp)
		curl = curl.lerp(_base_curl, 1.0 - gamp)
	if pstyle != "":
		_cash_in_now = bool(bargs.get("cash_in", false))
		_press_body(prow, pstyle, ul, dtc, Sn, H, F, bw3, ks, side, blow_id, best, tc2, T)
		if not press.is_empty():
			if _cash_in_now:
				press["cash_in"] = true   # the instant heavy (RT + B inside a perfect window): VFX flashes it
			press["sure"] = bool(bargs.get("sure", false))
			press["riposte"] = bool(bargs.get("_rip", false))
		if prow.has("set"):
			_burst_set(prow.set, strikes, tc2, T)
		_x_hold_set(S, f, T, strikes)
		if prow.has("hold") and dtc < 0.0:
			_hold_coil(prow.hold, (tq2 - (tc2 - L2)) / DT, L2 / DT, dtc, T)
	if RenderAnim.hand_tips:
		_hand_tip(ks, side, heavy2, strikes[best][2], hw)
	if RenderAnim.press_styles and bool(bargs.get("check", false)):
		_guard_layer(ks, side, hw)
	# the step from the wind-up into the contact key is the blow itself (on twos it is one step): inertialisation must not take it for a join
	# and smooth it over the next 0.1 s, or the fist reaches the defender late (--blowjoin restores the old behaviour for an A/B)
	_blow_snap = dtc >= -(Sn + dq) - 0.0001 and dtc <= 0.0001
	# timing fidelity: on the frame of contact the pose must be the contact key (checked before the contact solve moves it)
	if absf(T - tc2) < DT * 0.5:
		var err: float = 0.0
		var eb: int = 0
		var kref: Array[Quaternion] = pk.q
		if gamp < 0.999 and _base.size() == AnimRig.N:
			# a burst's blow lands short of the key by design (the closer the blows, the shorter each one: the pose is mixed toward its guard by 1 - gamp): the key it is held to is that mix
			kref = pk.q.duplicate()
			AnimPose.mix(kref, _base, 1.0 - gamp)
		for i in range(AnimRig.N):
			var ea: float = q[i].angle_to(kref[i])
			if ea > err:
				err = ea
				eb = i
		if err > float(debug["contact_err_max"]):
			debug["contact_err_bone"] = AnimRig.BONES[eb][0]
			debug["contact_err_info"] = "style %s ks %s side %s args %s prow_keys %s" % [pstyle, ksid, str(side), str(bargs), str(prow.keys())]
		_contact_now = true
		debug["contact_frames"] += 1
		debug["contact_err_max"] = maxf(float(debug["contact_err_max"]), err)
	_run_layers(strikes, best, gaps, prow, dtc, ul, blow_id, tc2, String(ks.get("_combat", "")))
	_dig_in(strikes, psts, T, String(ks.get("limb", "hand_r")))
	# the contact solve's weight: in over the snap, full at the contact tick and through the first of the follow-through,
	# out over the rest of it
	var cw: float = 0.0
	var pin_t: float = float(prof.get("ci_pin", 0)) * DT
	var cw_end: float = F + R * 0.4
	if pin_t > 0.0:
		cw_end = maxf(cw_end, pin_t + 3.0 * DT)
	if dtc >= -Sn and dtc < cw_end:
		if dtc < 0.0:
			cw = smoothstep(0.0, 1.0, (dtc + Sn) / Sn)
		elif pin_t > 0.0 and not ks.has("ci_end"):
			cw = 1.0 - smoothstep(pin_t, pin_t + 3.0 * DT, dtc)   # a plain light's pin: the contact solve holds the hand on him for `pin_ticks`, then lets go over 3
		elif ks.has("ci_end"):
			cw = 1.0 - smoothstep(H, maxf(H + DT, float(ks.ci_end) * DT), dtc)   # a key set's own release of the contact solve (data `ci_end`, ticks after the contact): the follow key takes the limb
		elif dtc < H + (F - H) * 0.5:
			cw = 1.0
		else:
			cw = 1.0 - smoothstep(H + (F - H) * 0.5, F + R * 0.4, dtc)
	if pin_t > 0.0:
		_pin_until = tc2 + pin_t
		hand_shine = 0.0
		if dtc >= 0.0 and dtc < pin_t + 3.0 * DT:
			hand_shine = 1.0 - smoothstep(pin_t, pin_t + 3.0 * DT, dtc)   # the hand that is held on him shines while the window is open (a held hit)
			hand_shine_limb = String(press.get("limb", String(ks.get("limb", "hand_r")))) if not press.is_empty() else String(ks.get("limb", "hand_r"))
	if cw > 0.001:
		_ci_w = cw
		_ci_limb = String(ks.get("limb", "hand_r"))
		_ci_step = float(ks.get("step_max", -1.0))
		_ci_step_k = float(mrule.get("step", 1.0))
		_ci_limb2 = String(ks.get("limb2", ""))
		_ci_target = String(ks.get("target", "chest")) if RenderAnim.force_target == "" else RenderAnim.force_target
		_ci_side = side
		_ci_opp = ex.D if role == "A" else ex.A
		_ci_tc = tc2
		_ci_dmg = float(strikes[best][2].get("dmg", 0.0))


## The guard layer a check is thrown over (data/anim/press_styles.json `guard`): the arm that is not striking stays in the guard pose, closing over the wind-up and opening over the return. A hand
## or elbow blow guards the other arm; a foot, knee or head blow guards both. Only the arm bones and the finger curl change, so the strike and its contact solve are the key set's own.
func _guard_layer(ks: Dictionary, side: bool, w: float) -> void:
	var G: Dictionary = AnimData.press.get("guard", {})
	if G.is_empty() or w <= 0.001 or not AnimData.pose_exists(String(G.get("pose", ""))):
		return
	var gp: AnimPose = AnimData.pose(String(G.pose))
	var lb: String = String(ks.get("limb", "hand_r"))
	var right_strikes: bool = lb.ends_with("r") != side if lb.contains("_") else true
	var sides: Array = []
	if lb.begins_with("hand") or lb.begins_with("elbow"):
		sides = ["l" if right_strikes else "r"]
	else:
		sides = ["l", "r"]
	var ww: float = clampf(w * float(G.get("weight", 0.9)), 0.0, 1.0)
	for sd in sides:
		for bn in G.get("bones", []):
			var bi: int = AnimRig.index[String(bn) + "_" + String(sd)]
			_press_slerp(bi, gp.q[bi], ww)
		if sd == "l":
			curl.x = lerpf(curl.x, gp.curl.x, ww)
		else:
			curl.y = lerpf(curl.y, gp.curl.y, ww)
	debug["guards"] = int(debug.get("guards", 0)) + 1


## The hand state of a blow's tip (data/anim/tips.json): the beat's own `tip` (the generator's move part), else the fighter's rule for a key set posed
## with another tip (the rival's heavies close to a fist). Only the striking hand's finger curl changes, by `w`; nothing about the pose, the reach
## or the contact solve does. Blade and palm are both an open hand on this rig (one curl a hand).
func _hand_tip(ks: Dictionary, side: bool, heavy: bool, args: Dictionary, w: float) -> void:
	var T: Dictionary = AnimData.tips
	if T.is_empty() or not bool(T.get("enabled", true)) or w <= 0.001:
		return
	var curls: Dictionary = T.get("curl", {})
	var want: String = String(args.get("tip", ""))
	if not curls.has(want):
		var rule: Dictionary = T.get("swap", {}).get(pair_key, {}).get("heavy" if heavy else "light", {})
		want = String(rule.get(String(ks.get("tip", "")), ""))
	if not curls.has(want):
		return
	var target: float = float(curls[want])
	for key in ["limb", "limb2"]:
		var lb: String = String(ks.get(key, ""))
		if not lb.begins_with("hand"):
			continue
		var right: bool = lb.ends_with("r")
		if side:
			right = not right
		if right:
			curl.y = lerpf(curl.y, target, w)
		else:
			curl.x = lerpf(curl.x, target, w)
	debug["hand_tips"] = int(debug.get("hand_tips", 0)) + 1


## An intro gesture (Narrative's intents: acknowledge, appraise, dismiss, defer, brace, ease, claim, check, soften, harden; docs/narrative/dynamic-intros.md section 11): the sim's
## `intro_gesture {actor, intent, at}` starts the fighter's own small motion for the intent from data/anim/pair_live.json `gestures` (a sequence or a pose, a weight, the groups of bones it
## plays on: head, torso, arms, legs, in `gesture_groups`), played over whatever he is standing in and eased in and out. A fighter with no motion for the intent plays nothing (a silent skip).
func on_gesture(intent: String, T: float, tick_clock: bool = false) -> void:
	if not RenderAnim.pair_live or not RenderAnim.intro_gestures or pair_key == "":
		return
	var tbl: Dictionary = AnimData.pair.get("roles", {}).get(pair_key, {}).get("gestures", {})
	if not tbl.has(intent):
		debug["gesture_skips"] = int(debug.get("gesture_skips", 0)) + 1
		return
	var g: Dictionary = tbl[intent]
	var id: String = String(g.get("seq", ""))
	var dur: float = 0.0
	var is_pose: bool = false
	if AnimData.entries.has(id):
		dur = float(AnimData.entries[id].dur) / 60.0
	elif AnimData.pose_exists(id):
		dur = float(g.get("hold", 0.5))
		is_pose = true
	else:
		debug["gesture_skips"] = int(debug.get("gesture_skips", 0)) + 1
		return
	_gest = {"id": id, "t0": T, "dur": dur, "w": float(g.get("w", 1.0)), "mask": g.get("mask", ["head", "torso", "arms"]), "pose": is_pose, "intent": intent, "tb": tick_clock}
	debug["gestures"] = int(debug.get("gestures", 0)) + 1


func _gesture_layer(S: SimState, f, T: float) -> void:
	var g: Dictionary = _gest
	if bool(g.tb):
		T = float(S.tick) / 60.0   # the intro runs on the sim's tick: its clock is frozen at 0 until the match starts
	var u: float = T - float(g.t0)
	var fade: float = 0.15
	if u < -0.0001:
		return
	if u > float(g.dur) + fade or f.state == "launched" or f.state == "down" or f.state == "dropped" or _en_busy(S, f):
		_gest = {}
		return
	var env: float = smoothstep(0.0, 0.1, u) * (1.0 - smoothstep(float(g.dur), float(g.dur) + fade, u)) * float(g.w) * (0.6 if RenderAnim.reduced_motion else 1.0)
	if env <= 0.001:
		return
	var base_q: Array[Quaternion] = q.duplicate()
	var base_h: Vector3 = hips
	var base_c: Vector2 = curl
	if bool(g.pose):
		_mix_pose(AnimData.pose(String(g.id)), 1.0)
	else:
		_entry_layer(float(g.t0), float(g.dur), String(g.id), T, DT, 1.0)
	# only the groups of bones the gesture plays on take it (a bow does not move the feet); the rest keep what they were
	var on: Dictionary = {}
	var groups: Dictionary = AnimData.pair.get("gesture_groups", {})
	for gn in g.mask:
		for bn in groups.get(String(gn), []):
			on[int(AnimRig.index[String(bn)])] = true
	var all: bool = on.is_empty()
	for i in range(AnimRig.N):
		if all or on.has(i):
			q[i] = base_q[i].slerp(q[i], env)
		else:
			q[i] = base_q[i]
	if all or on.has(int(AnimRig.index["pelvis"])):
		hips = base_h.lerp(hips, env)
	else:
		hips = base_h
	curl = base_c.lerp(curl, env) if (all or on.has(int(AnimRig.index["hand_r"]))) else base_c


## The press style of a blow (data/anim/press_styles.json, only with RenderAnim.press_styles): the beat's own `style` when the director
## stamps one, else the striker's press log read now (Controls' SimPressRead through DirAlchemy.read: rhythm = tech, mash = speed), a
## heavy blow is always heavy. "" is the profile the blow plays today. Decided the first time the blow is seen, then kept.
func _press_style(S: SimState, f, ex, sk: Array) -> String:
	if not RenderAnim.press_styles or AnimData.press.is_empty() or not bool(AnimData.press.get("enabled", true)):
		return ""
	var key: int = int(ex.n) * 64 + int(sk[1])
	if _pr_cache.has(key):
		return String(_pr_cache[key])
	if _pr_cache.size() > 32:
		_pr_cache.clear()
	var rows: Dictionary = AnimData.press.get("styles", {})
	var st: String = ""
	var args: Dictionary = sk[2]
	var brawl_beat: bool = bool(args.get("brawl", false))
	if brawl_beat and args.has("strength") and not rows.has(String(args.get("style", ""))):
		RenderAnim.hook_seen = true   # a brawl beat with a strength and no style of its own: Encounter's hook has landed
	if RenderAnim.strength_styles and brawl_beat and ["speed", "heavy"].has(String(args.get("style", ""))):
		# forced (a switch, off by default): a brawl beat's own `style` is only a default (speed for a light, heavy for a wound blow): its strength and its burst number say which row it is
		if int(args.get("burst", 0)) > 0 and rows.has("burst"):
			st = "burst"
		else:
			var sm: Dictionary = AnimData.press.get("strength", {})
			var sv: String = String(args.get("strength", ""))
			if sm.has(sv) and rows.has(String(sm[sv])):
				st = String(sm[sv])
	if bool(args.get("cash_in", false)) and rows.has("cash_in"):
		st = "cash_in"   # the cash-in's own row (data `styles.cash_in`): a heavy thrown at once, no tell
	elif bool(args.get("cash_in", false)) and rows.has("super"):
		st = "super"   # no row of its own in the data: the super row's follow-through, with no tell
	if st != "":
		pass
	elif rows.has(String(args.get("style", ""))):
		st = String(args.style)
	elif bool(args.get("burst", false)) and rows.has("burst"):
		st = "burst"
	elif args.has("strength") and AnimData.press.get("strength", {}).has(String(args.strength)) and rows.has(String(AnimData.press.strength[String(args.strength)])):
		st = String(AnimData.press.strength[String(args.strength)])   # any beat that carries a strength and names no style of its own (light, medium, heavy, and in C2t bolt and blast): the map, whether or not it is in a flurry
	elif String(sk[3]) == "heavy":
		st = "heavy"
	elif f.act.dirI.size() >= DirAlchemy.SIZE:
		var rd: Dictionary = DirAlchemy.read(S, f)
		st = String(AnimData.press.get("read", {}).get(String(rd.get("style", "none")), ""))
		if st == "heavy":
			st = ""   # a hold that is not a heavy blow (a light one thrown during the press) plays as it does today
	_pr_cache[key] = st
	var pn: Dictionary = debug.get("press_n", {})
	pn[st] = int(pn.get(st, 0)) + 1
	debug["press_n"] = pn
	return st


## The style's timing over the part's, then what the beat tells (B0's fields, data/anim/press_styles.json `beat`): a tech blow's grade sets its held beat (a perfect press holds the full
## beat, a good one less, an off one least); the closing blow of a string and a string's ender hold their follow-through at least that long (the blow that ends it lands and stays);
## a held heavy winds up for its whole time and a tapped one for less.
func _gap_amp(row: Dictionary, gap_ticks: float) -> float:
	var ga = row.get("gap_amp")
	if not (ga is Dictionary):
		return 1.0
	var g0: float = float(ga.get("from", 3.0))
	var g1: float = float(ga.get("to", 6.0))
	return lerpf(float(ga.get("min", 0.6)), 1.0, clampf((gap_ticks - g0) / maxf(g1 - g0, 0.001), 0.0, 1.0))


## A style's row as THIS fighter plays it (the moveset distinction, fighter-pipeline.md section 8): the global row of data/anim/press_styles.json with his own `ease` overrides of data/anim/fighters.json laid over it
## (`prof` merged key by key, any other key replaced). The one clock is unchanged: a blow's wind-up, contact tick and total length are the sim's and the cue's; what a fighter's ease changes is how the
## blow arrives (the load's curve), what it does after the contact (overshoot, hold, follow, return, carry, twist). Fluid is more overshoot, a longer follow and a longer carry; snappy is a dead stop.
func _style_row(style: String, energy: bool = false) -> Dictionary:
	var key: String = style + ("+e" if RenderAnim.fighter_ease and not energy else "")
	if _row_cache.has(key):
		return _row_cache[key]
	var base: Dictionary = AnimData.press.get("styles", {}).get(style, {})
	var ov: Dictionary = AnimData.fighters_cfg.get(pair_key, {}).get("ease", {}).get(style, {}) if (RenderAnim.fighter_ease and not energy) else {}   # energy in reach keeps the global row: its tests and Legal's e09 read it
	var out: Dictionary = base
	if not ov.is_empty():
		out = base.duplicate(true)
		for k in ov:
			if k == "prof":
				var pm: Dictionary = out.get("prof", {}).duplicate()
				pm.merge(ov.prof, true)
				out["prof"] = pm
			else:
				out[k] = ov[k]
	_row_cache[key] = out
	return out


func _press_prof(sp: Dictionary, style: String, args: Dictionary = {}) -> Dictionary:
	var out: Dictionary = sp.duplicate()
	out.merge(_style_row(style, String(args.get("piece", "")).begins_with("strike.bolt_") or String(args.get("piece", "")).begins_with("strike.blast_")).get("prof", {}), true)
	if bool(args.get("cash_in", false)):
		if style != "cash_in":   # the cash-in (RT + B inside a perfect window) has its row's load of 2 ticks and no snap; without the row it is the super row at 2 ticks
			out["load_ticks"] = {"light": 2, "heavy": 2}
			out["snap_ticks"] = 0
	elif args.has("windup"):
		# a held blow winds up for as long as it was held (the sim's or the study's count, in ticks): the whole window is the wind-up
		var wu: int = clampi(int(args.windup), 1, 120)
		out["load_ticks"] = {"light": wu, "heavy": wu}
	var B: Dictionary = AnimData.press.get("beat", {})
	if B.is_empty():
		return out
	if (String(args.get("strength", "")) == "bolt" or String(args.get("piece", "")).begins_with("strike.bolt_")) and B.has("bolt_recover_add"):
		out["recover_ticks"] = int(out.get("recover_ticks", 7)) + int(B.bolt_recover_add)   # a bolt's return is longer: the contact solve lets the arm go as it comes home, not while it is still stretched
	if style == "speed" and B.has("plain_light") and (bool(args.get("plain", false)) or (RenderAnim.plain_pin and String(args.get("strength", "")) == "light" and not bool(args.get("flurry", false)) and int(args.get("k", 1)) <= 1 and int(args.get("burst", 0)) == 0 and bool(args.get("brawl", false)))):
		out["ci_pin"] = int(B.plain_light.get("pin_ticks", 6))   # the hand stays set on him (riding his reaction) while the body follows through: not a frozen pose
	if style == "tech" and args.has("grade"):
		var g: Dictionary = B.get("grade", {}).get(String(args.grade), {})
		if g.has("hold_ticks"):
			out["hold_ticks"] = int(g.hold_ticks)
	if bool(args.get("closing", false)) or bool(args.get("ender", false)):
		out["hold_ticks"] = maxi(int(out.get("hold_ticks", 0)), int(B.get("closing", {}).get("hold_ticks", 0)))
	if style == "heavy" and args.has("charge"):
		var lm: float = float(B.get("charge", {}).get("load_min", 1.0))
		var lt: Dictionary = (out.get("load_ticks", {}) as Dictionary).duplicate()
		var ck: float = lerpf(lm, 1.0, clampf(float(args.charge), 0.0, 1.0))
		for key in lt:
			lt[key] = maxi(1, roundi(float(lt[key]) * ck))
		out["load_ticks"] = lt
	return out


## A new blow of a styled string: what the last blow ended on is kept to blend out of (a blow with `carry`).
func _press_track(blow_id: int, T: float) -> void:
	if _pr_blow == blow_id:
		return
	_pc_ok = T - _pr_T <= 0.05 and _pr_q.size() == AnimRig.N
	if _pc_ok:
		_pc_q = _pr_q.duplicate()
		_pc_hips = _pr_hips
		_pc_curl = _pr_curl
	_pr_blow = blow_id


## The wind-up the sim named for this blow (the cue `windup` start: `dur` live ticks, `n` the landing tick): the cue's duration when its landing is this blow's, else 0. Only for a brawl's wound blows
## (a medium's 12 ticks, a heavy's 28, the launcher's 14), whose beats carry no `windup` of their own.
func _cue_windup(tc: float, args: Dictionary, style: String) -> int:
	if not RenderAnim.second_pass() or not bool(args.get("brawl", false)) or args.has("windup") or not ["medium", "super", "heavy"].has(style):
		return 0
	if String(windup_cue.get("text", "")) != "start":
		return 0
	var land_t: float = float(windup_cue.T) + float(int(windup_cue.n) - int(windup_cue.get("tick", 0))) * DT
	if absf(land_t - tc) > 4.0 * DT:
		return 0   # another blow's (a hit-stop in between shifts a real landing a little: 4 ticks of tolerance)
	return clampi(int(roundf(float(windup_cue.dur))), 4, 100)


## A wound blow held past its landing tick. The sim waits with the blow after its wind-up while the button is down (the tap rule's wait; the heavy's charge from tick 32, full at 44, by itself at 70) and its read
## `DirBrawl.winding` says `left` -1 while it does. The beat's own contact tick passes meanwhile: without this the body threw the blow at its 28th tick, stood idle through the charge and threw a second, four ticks
## long, at the release. Here it keeps the chamber of the blow it was winding and the style's `hold` row loads it (sinking, the shoulders winding, a shudder at the flash); the release is the sim's next beat, four
## ticks long, which the carry blends out of this pose. Returns true when it drew the body.
func _held_layer(S: SimState, f, T: float) -> bool:
	if not RenderAnim.second_pass() or _held_ks == "" or not AnimData.keysets.has(_held_ks):
		return false
	var wnd: Dictionary = DirBrawl.winding(S, f)
	if wnd.is_empty() or int(wnd.get("left", 0)) >= 0:
		return false
	var row: Dictionary = AnimData.press.get("styles", {}).get(_held_style, {})
	var ks: Dictionary = AnimData.keysets[_held_ks]
	_set_pose(AnimData.pose(String(ks["keys"][0]["pose"]), _held_side))
	_set_lag(0.3)
	if row.has("hold"):
		hold_coil = 0.0
		_hold_coil(row.hold, float(wnd.get("n", 0)), 200.0, -1.0, T)
	press = {"style": _held_style, "phase": "hold", "blow": _pr_blow, "ordinal": 0, "ticks_to_contact": -1, "limb": String(ks.get("limb", "hand_r")), "bone": "hand_r", "side": _held_side, "smear": false, "ghosts": 0, "weight": 1.0, "squash": hold_coil, "stretch": 0.0, "twist": 0.0, "dx": 0.0, "held": true, "charge": float(wnd.get("charge", 0.0))}
	if _pr_q.size() != AnimRig.N:
		_pr_q.resize(AnimRig.N)
	for i in range(AnimRig.N):
		_pr_q[i] = q[i]
	_pr_hips = hips
	_pr_curl = curl
	_pr_T = T
	return true


## The heavy's held charge (Game Design, brawl-second-pass section 3: B still down at 32 ticks keeps charging, full at 44, by itself at 70; Orb's test "can I move my character when the opponent is charging up an
## attack?"): a wind-up that runs longer than the style's `hold.from` ticks (the blow's own window is the whole hold) keeps loading: after `from` the body sinks toward the squash pose and leans back a little more
## every tick up to `to` ticks, whatever the key set's own squash (the tier's pieces draw their tell in the chamber alone). No light: the flash is VFX's. Gone as the blow lands.
func _hold_coil(row: Dictionary, elapsed: float, span: float, dtc: float, t_now: float) -> void:
	var from: float = float(row.get("from", 28.0))
	if span <= from + 2.0 or elapsed <= from:
		return
	var k: float = smoothstep(from, float(row.get("to", 70.0)), elapsed) * (1.0 - smoothstep(-3.0 * DT, 0.0, dtc))
	if k <= 0.001:
		return
	var sp: Dictionary = AnimData.press.get("squash_pose", {})
	var pid: String = String(row.get("pose", {}).get(pair_key, ""))   # the hold's own body (a held Y's and a held B's differ); else the style's squash pose
	if pid == "" or not AnimData.pose_exists(pid):
		pid = String(sp.get("by_fighter", {}).get(pair_key, sp.get("default", "brace")))
	if not AnimData.pose_exists(pid):
		return
	var ix: Dictionary = AnimRig.index
	var s: float = k * float(row.get("squash", 0.5))
	var spp: AnimPose = AnimData.pose(pid)
	for bn in sp.get("bones", []):
		var bi: int = ix[String(bn)]
		_press_slerp(bi, spp.q[bi], s)
	hips.y = minf(hips.y, lerpf(hips.y, spp.hips.y, s))
	var lean: float = float(row.get("lean_back", 0.12)) * k
	q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), lean * 0.5)
	q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), lean * 0.5)
	q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 0, 1), -lean * 0.5)
	hold_coil = k
	# the strain of a held blow (data `hold.tremor`, homework 4b: a held medium and a held heavy must not read as a tap that is only slower): the body shakes with what it holds, more the longer
	# it is held, a unit or less
	var tb: float = deg_to_rad(float(row.get("twist_back", 0.0))) * k * (-1.0 if not _held_side else 1.0)   # the shoulders wind back the way the blow will come from
	if tb != 0.0:
		q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 1, 0), tb * 0.4)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 1, 0), tb * 0.6)
	var tr: float = float(row.get("tremor", 0.0)) * k * (0.5 if RenderAnim.reduced_motion else 1.0)
	if tr > 0.0:
		hips.x += tr * sin(elapsed * 1.9)
		hips.y += 0.7 * tr * sin(elapsed * 2.7 + 1.0)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 1, 0), 0.03 * tr * sin(elapsed * 2.3 + 2.0))
	if charge_full_t >= 0.0 and t_now >= charge_full_t:
		var tt: float = (t_now - charge_full_t) * 60.0
		hips.x += 0.35 * sin(tt * 2.3)   # at full the body shudders, a third of a unit and no more: it is holding something in; the flash itself is VFX's
		hips.y += 0.25 * sin(tt * 3.1 + 1.0)


## What a run of blows adds to the body (the nine cells' look audit, numbers 4 and 7; data on the style rows, drawn after the contact-frame check like the dig-in):
## `press_run` (the mash presses): a forward lean that grows with each blow of a run (gaps of `gap` ticks or less), `deg_per_blow` to `max_deg`, with a dip of the head, so a mashed X or Y is pressure and not
## six taps; it fades over 10 ticks after the last blow's contact. `march` (a mashed heavy advances): a heavy that follows another within `gap` ticks takes a footfall, `step` units forward and a dip of the legs
## by `dip` of the squash pose at the contact, for `dip_ticks` (the dust is VFX's: `press.march` is set on the contact).
func _run_layers(strikes: Array, best: int, gaps: Array, prow: Dictionary, dtc: float, ul: float, blow_id: int, tc: float, piece: String) -> void:
	press_lean = 0.0
	press_bob = 0.0
	march_w = 0.0
	# the contact of the blow before this one (a heavy's own blows are far apart: the exchange keeps one beat at a time, so his own memory holds it)
	if blow_id != _mr_blow:
		_mr_prev_tc = _mr_cur_tc
		_mr_blow = blow_id
	_mr_cur_tc = tc
	var ix: Dictionary = AnimRig.index
	var pr: Dictionary = prow.get("press_run", {})
	if not pr.is_empty() and RenderAnim.mash_press and best < gaps.size() and not piece.begins_with("strike.bolt_") and not piece.begins_with("strike.blast_"):   # energy in reach keeps the heads a hand's width apart (Legal e09)
		var gmax: float = float(pr.get("gap", 10.0))
		var n: int = 1
		var k: int = best
		while k > 0 and float(gaps[k]) <= gmax:
			n += 1
			k -= 1
		var deg: float = minf(float(pr.get("max_deg", 10.0)), float(pr.get("deg_per_blow", 2.0)) * float(n - 1))
		if deg > 0.01:
			var env: float = smoothstep(0.0, 0.8, ul)
			if dtc > 0.0:
				env *= 1.0 - smoothstep(0.0, 10.0 * DT, dtc)
			var ang: float = deg_to_rad(deg) * env
			q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), -ang * 0.5)
			q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), -ang * 0.5)
			q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 0, 1), ang * 0.4)
			press_lean = ang
			# the run's beat (data `press_run.bob`, homework 4: the three styles of a button must read apart): the pelvis dips on each blow of a run and comes back between, so a mashed button has a rhythm a tapped one has not
			var bob: float = float(pr.get("bob", 0.0))
			if bob > 0.0 and n >= 2:
				var bw: float = smoothstep(-3.0 * DT, 0.0, dtc) * (1.0 - smoothstep(0.0, 5.0 * DT, dtc))
				hips.y -= bob * bw * env
				press_bob = bob * bw * env
	var mr: Dictionary = prow.get("march", {})
	if not mr.is_empty() and RenderAnim.march and _mr_prev_tc >= 0.0 and tc - _mr_prev_tc <= float(mr.get("gap", 140.0)) * DT and tc > _mr_prev_tc:
		var pulse: float = smoothstep(-2.0 * DT, 0.0, dtc) * (1.0 - smoothstep(0.0, float(mr.get("dip_ticks", 5)) * DT, dtc))
		var fwd: float = smoothstep(-8.0 * DT, 0.0, dtc) * (1.0 - smoothstep(0.0, 12.0 * DT, dtc))
		_pr_dx += float(mr.get("step", 5.0)) * fwd
		var sp: Dictionary = AnimData.press.get("squash_pose", {})
		var pid: String = String(sp.get("by_fighter", {}).get(pair_key, sp.get("default", "brace")))
		if pulse > 0.001 and AnimData.pose_exists(pid):
			var spp: AnimPose = AnimData.pose(pid)
			var w: float = float(mr.get("dip", 0.3)) * pulse
			for bn in sp.get("bones", []):
				var bi: int = ix[String(bn)]
				_press_slerp(bi, spp.q[bi], w)
			hips.y = minf(hips.y, lerpf(hips.y, spp.hips.y, w))
		march_w = pulse
		if pulse > 0.5 and not press.is_empty():
			press["march"] = true


## The held X digs in (data `styles.burst.dig`; the nine cells' look audit, number 2): through a burst's stream the legs and the pelvis keep the set pose, wide, low and planted, and only the arms and the shoulders
## move, so a held X is a different body from a mashed one. In from a few ticks before the first blow of the stream, out over a few after the last; a blow of the foot or the knee keeps its legs (0 for it).
## Drawn after the contact-frame check and before the contact solve, so the hand still reaches and a blow's key pose is still what the check holds.
func _dig_in(strikes: Array, psts: Array, T: float, limb: String) -> void:
	var brow: Dictionary = AnimData.press.get("styles", {}).get("burst", {})
	var dg: Dictionary = brow.get("dig", {})
	if dg.is_empty() or not RenderAnim.dig_in:
		return
	var t_first: float = 1.0e9
	var t_last: float = -1.0e9
	for n in range(strikes.size()):
		if n < psts.size() and String(psts[n]) == "burst":
			t_first = minf(t_first, float(strikes[n][0]))
			t_last = maxf(t_last, float(strikes[n][0]))
	if t_last < 0.0:
		return
	var a: float = t_first - float(dg.get("lead", 6)) * DT
	var w: float = smoothstep(a, a + float(dg.get("in", 3)) * DT, T) * (1.0 - smoothstep(t_last, t_last + float(dg.get("out", 6)) * DT, T)) * float(dg.get("w", 0.8))
	if limb.begins_with("foot") or limb.begins_with("knee"):
		w = 0.0
	if w <= 0.001:
		return
	var pid: String = String(brow.get("set", {}).get("pose", {}).get(pair_key, ""))
	if pid == "" or not AnimData.pose_exists(pid):
		return
	var spp: AnimPose = AnimData.pose(pid)
	for bn in dg.get("bones", []):
		var bi: int = AnimRig.index[String(bn)]
		_press_slerp(bi, spp.q[bi], w)
	hips.y = minf(hips.y, lerpf(hips.y, spp.hips.y, w))
	dig_w = maxf(dig_w, w)


## A held X before its burst begins (Game Design section 3: until 16 ticks a held X is a tap, one light, and then he sets himself for about 10 ticks): the sim creates a burst's blows only as they are due, so there is no
## next beat to key the set on. The set is laid by the brawl's own slots instead: X_LIVE (the live tick of the light press while the button is still down) and BURST_N 0 (no burst yet): a pure read, as
## `DirBrawl.winding` is. It comes in 5 ticks after the press (the light's own follow-through is done) and is gone by 16, where the burst's first blow is already winding. Same pose, same row as `_burst_set`.
func _x_hold_set(S: SimState, f, T: float, strikes: Array = []) -> void:
	if not RenderAnim.second_pass() or not DirBrawl.inBrawl(S, f):
		return
	var x: int = DirBrawl._g(f, DirBrawl.X_LIVE)
	if x <= 0 or DirBrawl._g(f, DirBrawl.BURST_N) != 0:
		return
	var xt: int = DirBrawl._now(S) - x
	var row: Dictionary = AnimData.press.get("styles", {}).get("burst", {}).get("set", {})
	if row.is_empty() or xt < 4 or xt > 17:
		return
	var pid: String = String(row.get("pose", {}).get(pair_key, ""))
	if pid == "" or not AnimData.pose_exists(pid):
		return
	var w: float = smoothstep(4.0, 7.0, float(xt)) * (1.0 - smoothstep(14.0, 17.0, float(xt))) * float(row.get("w", 0.9))
	var near: float = 1.0e9   # the set never draws over a blow: the body is the blow's own key at its contact (a trade or a chain landing inside the set's 12 ticks), faded out 6 to 2 ticks either side of any contact
	for sk in strikes:
		near = minf(near, absf(T - float(sk[0])))
	w *= smoothstep(2.0 * DT, 6.0 * DT, near)
	if w <= 0.001 or w <= burst_set:
		return
	var sp: AnimPose = AnimData.pose(pid)
	AnimPose.mix(q, sp.q, w)
	hips = hips.lerp(sp.hips, w)
	curl = curl.lerp(sp.curl, w)
	burst_set = w


## The burst's set (Game Design, brawl-second-pass section 3: one light at once, then he sets himself for about 10 ticks before the stream, which is the burst's tell): when the next blow of the exchange is 14 ticks
## or more behind a burst blow, the body is mixed toward the fighter's set pose from a few ticks after the blow until a few before the next. `row` is the style's `set` (data/anim/press_styles.json): `pose` by fighter,
## `from` (ticks after the blow it comes in), `to_before` (ticks before the next blow it is gone), `in`, `out`, `w`, `min_gap`. Fills `press.set` for VFX and the tools.
func _burst_set(row: Dictionary, strikes: Array, tc: float, T: float) -> void:
	var nxt: float = 1.0e9
	for n in range(strikes.size()):
		var t2: float = float(strikes[n][0])
		if t2 > tc + 0.0001 and t2 < nxt:
			nxt = t2
	if nxt > 1.0e8 or (nxt - tc) / DT < float(row.get("min_gap", 14)):
		return
	var pid: String = String(row.get("pose", {}).get(pair_key, ""))
	if pid == "" or not AnimData.pose_exists(pid):
		return
	var a: float = tc + float(row.get("from", 4)) * DT
	var b: float = nxt - float(row.get("to_before", 3)) * DT
	var w: float = smoothstep(a, a + float(row.get("in", 2)) * DT, T) * (1.0 - smoothstep(b - float(row.get("out", 3)) * DT, b, T)) * float(row.get("w", 0.9))
	if w <= 0.001:
		return
	var sp: AnimPose = AnimData.pose(pid)
	AnimPose.mix(q, sp.q, w)
	hips = hips.lerp(sp.hips, w)
	curl = curl.lerp(sp.curl, w)
	burst_set = w
	if not press.is_empty():
		press["set"] = w


## The retract, blended: the new blow's wind-up starts from the pose the last blow was in, not from the guard, so the arm that
## struck eases back while the other one comes through.
func _press_carry(row: Dictionary, blow_id: int, tl: float) -> void:
	var span: float = float(row.get("carry_ticks", 5)) * DT
	if not _pc_ok or span <= 0.0 or tl >= span or _pr_blow != blow_id:
		return
	var k: float = smoothstep(0.0, 1.0, maxf(tl, 0.0) / span)
	var tmp: Array[Quaternion] = q.duplicate()
	for i in range(AnimRig.N):
		q[i] = _pc_q[i]
	AnimPose.mix(q, tmp, k)
	hips = _pc_hips.lerp(hips, k)
	curl = _pc_curl.lerp(curl, k)


func _press_slerp(i: int, to: Quaternion, w: float) -> void:
	var qa: Quaternion = q[i]
	if AnimJoints.ik_limits and AnimJoints.is_limb[i] == 1 and absf(qa.dot(to)) <= 0.9:
		q[i] = AnimJoints.slerp_limb(qa, to, w)
	else:
		q[i] = qa.slerp(to, w)


## Combat's rule for a medium thrown on Y's 12-tick wind-up (data/anim/medium_wind.json): the rule's numbers for this key set, or {} when the blow is not a medium, plays a long wind-up (a held Y, 15 ticks or more:
## the full coil) or the key set has no rule (a held-only one, or not a medium).
func _medium_rule(pstyle: String, ksid: String, bargs: Dictionary) -> Dictionary:
	if pstyle != "medium" or not RenderAnim.medium_wind or int(bargs.get("windup", 0)) > 14:
		return {}
	var w: String = String(AnimData.medium_wind.get("sets", {}).get(ksid, ""))
	if w == "":
		return {}
	return AnimData.medium_wind.get("rules", {}).get(w, {})


## The body of a styled blow on top of its key poses, all inside the joints' range (the squash is a blend of two valid poses, the
## stretch and the twist are a few hundredths of a radian on the spine, which has no limit of its own, and the limb pass
## runs after): the wind-up squashes (legs, pelvis and spine toward the squash pose, a lean back), the release stretches (the spine
## extends, the hips rise, the body is drawn ahead for a few ticks: the smear frame is the tick before contact), a mashed blow twists
## the loose body toward the striking side. Fills `press` for VFX.
func _press_body(row: Dictionary, style: String, ul: float, dtc: float, sn: float, hold: float, F: float, bw: float, ks: Dictionary, side: bool, blow_id: int, nth: int, tc: float, T: float) -> void:
	var ix: Dictionary = AnimRig.index
	var wsc: float = clampf(0.55 + 0.45 * bw, 0.4, 1.0)
	var s: float = 0.0
	var sq: float = float(row.get("squash", 0.0))
	if _cash_in_now:
		sq = 0.0   # an instant heavy has no tell to sink into: it is thrown from where he stands
	if sq > 0.0:
		s = smoothstep(0.0, 0.85, ul) * (1.0 - smoothstep(-3.0 * DT, 0.0, dtc))   # gone on the contact tick: the key pose is the blow
		var swk: float = float(ks.get("squash_w", 1.0))   # a key set may carry its own squash (data `squash_w`): the drive's tell is drawn in its chamber, not a crouch
		var sbd: Dictionary = row.get("squash_by_drive", {})
		if sbd.has(String(ks.get("drive", ""))):
			swk = float(sbd[String(ks.drive)])   # the style's own sink by the piece's drive (the heavy's tell sinks at fight size: a step, a turn or an unwind 0.55, a fall rises and does not sink)
		s *= sq * wsc * swk
		if s > 0.001:
			var sp: Dictionary = AnimData.press.get("squash_pose", {})
			var pid: String = String(row.get("squash_pose", {}).get(pair_key, sp.get("by_fighter", {}).get(pair_key, sp.get("default", "brace"))))   # a style's own sink pose (data `squash_pose` on the row: the heavy's tell sinks to the coil's depth)
			if AnimData.pose_exists(pid):
				var spp: AnimPose = AnimData.pose(pid)
				for bn in sp.get("bones", []):
					var bi: int = ix[String(bn)]
					_press_slerp(bi, spp.q[bi], s)
				hips.y = minf(hips.y, lerpf(hips.y, spp.hips.y, s))
			var lean: float = float(row.get("lean_back", 0.0)) * s
			q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), lean * 0.5)
			q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), lean * 0.5)
			q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 0, 1), -lean * 0.5)
			_pr_dx -= float(row.get("back", 0.0)) * s
	var st: Dictionary = row.get("stretch", {})
	var e: float = 0.0
	var smear_t: float = float(st.get("smear_ticks", 0)) * DT
	var st_t: float = float(st.get("ticks", 3)) * DT
	var smear: bool = false
	if float(st.get("spine", 0.0)) > 0.0 or float(st.get("lead", 0.0)) > 0.0 or float(st.get("rise", 0.0)) > 0.0:
		if dtc < -smear_t - 0.0001:
			e = smoothstep(-(smear_t + 2.0 * DT), -smear_t, dtc)
		elif dtc < 0.0001:
			e = 1.0
			smear = smear_t > 0.0 and dtc < -0.0001
		else:
			e = 1.0 - smoothstep(0.0, st_t, dtc)
		e *= wsc
		if e > 0.001:
			var ext: float = float(st.get("spine", 0.0)) * e
			q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), -ext * 0.5)
			q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), -ext * 0.5)
			q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 0, 1), ext * 0.4)
			hips.y += float(st.get("rise", 0.0)) * e
			_pr_dx += float(st.get("lead", 0.0)) * e
	var tw: float = float(row.get("twist", 0.0))
	var twk: float = 0.0
	if tw > 0.0:
		var tw_t: float = float(row.get("twist_ticks", 6)) * DT
		twk = smoothstep(-3.0 * DT, 0.0, dtc) if dtc < 0.0 else 1.0 - smoothstep(0.0, tw_t, dtc)
		var ang: float = tw * twk * (1.0 if side else -1.0)
		q[ix["spine_1"]] = q[ix["spine_1"]] * Quaternion(Vector3(0, 1, 0), ang * 0.5)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 1, 0), ang * 0.5)
		q[ix["pelvis"]] = q[ix["pelvis"]] * Quaternion(Vector3(0, 1, 0), -ang * 0.3)
	var phase: String = "load"
	if dtc >= 0.0001:
		phase = "contact" if dtc < 1.5 * DT else ("hold" if dtc < hold else ("follow" if dtc < F else "return"))
	elif smear:
		phase = "smear"
	elif dtc >= -sn - 0.0001:
		phase = "release"
	var limb: String = String(ks.get("limb", "hand_r"))
	if side and limb.contains("_"):
		limb = limb.substr(0, limb.length() - 1) + ("l" if limb.ends_with("r") else "r")
	var bone: String = limb.replace("elbow", "forearm").replace("knee", "shin")
	if not ix.has(bone):
		bone = "hand_r"
	press = {"style": "super" if style == "cash_in" else style, "phase": phase, "blow": blow_id, "ordinal": nth, "ticks_to_contact": roundi((tc - T) / DT), "limb": limb, "bone": bone, "side": side, "smear": smear, "ghosts": int(row.get("ghosts", 0)), "weight": bw, "squash": s, "stretch": e, "twist": twk, "dx": _pr_dx}
	if _pr_q.size() != AnimRig.N:
		_pr_q.resize(AnimRig.N)
	for i in range(AnimRig.N):
		_pr_q[i] = q[i]
	_pr_hips = hips
	_pr_curl = curl
	_pr_T = T


## What VFX reads (after a solve, while `press` is not empty and for a moment after): the afterimages are `press_pose(k)`, the pose k
## solves back (0 is the newest), and the smear wedge runs along `press_path` (the striking limb's tip at each of those solves).
func _press_record(T: float, f = null) -> void:
	if not press.is_empty() or not zip.is_empty():
		var snap: Array[Quaternion] = q.duplicate()
		var wp := Vector2.ZERO
		if f != null:
			wp = Vector2(f.x, f.y)
		press_ring.append({"T": T, "q": snap, "hips": hips, "root_off": root_off, "pos": wp, "vface": vface})
		press_path.append({"T": T, "tip": socket(String(press.get("bone", zip.get("bone", "hand_r"))))})
		if not zip.is_empty():
			zip_path.append({"T": T, "x": wp.x, "y": wp.y, "phase": String(zip.get("phase", ""))})
	while press_ring.size() > 12 or (not press_ring.is_empty() and T - float(press_ring[0].T) > 0.4):
		press_ring.pop_front()
	while press_path.size() > 12 or (not press_path.is_empty() and T - float(press_path[0].T) > 0.4):
		press_path.pop_front()
	while zip_path.size() > 24 or (not zip_path.is_empty() and T - float(zip_path[0].T) > 0.8):
		zip_path.pop_front()


## The pose `back` solves ago ({T, q, hips, root_off}), newest 0; {} when there is none.
func press_pose(back: int) -> Dictionary:
	var n: int = press_ring.size()
	return press_ring[n - 1 - back] if back >= 0 and back < n else {}


## The defensive and clash beats of the exchange (the sim's own: wind, slip, dodge, guardBreak, clashWave). Each is a short
## eased pose layer on the fighter it happens to, timed from the beat; a blow's own parts go over the top of them.
func _beat_layers(ex, role: String, t0: float, T: float) -> void:
	for b in ex.beats:
		var bt: float = t0 + b.t
		if T < bt - 0.2 or T > bt + 0.7:
			if b.op != "wind":
				continue
		match b.op:
			"wind":
				# the wind-up window: from the beat to the parryable blow that follows it
				var te: float = -1.0
				for b2 in ex.beats:
					if b2.op == "strike" and String(b2.args.a) == "A" and b2.t > b.t:
						te = t0 + b2.t
						break
				if te < 0.0 or T < bt or T > te + 0.4:
					continue
				var ready: float = smoothstep(bt, bt + 0.1, T) * (1.0 - smoothstep(te - 0.02, te + 0.1, T))
				if ready > 0.001 and not ex.cancel and role == "D":
					_mix_pose(AnimData.pose("def.parry_ready"), ready * 0.85)
				if ex.cancel:
					# parried: the defender sweeps the blow aside, the attacker is turned off line
					var pw: float = smoothstep(te - 0.02, te + 0.03, T) * (1.0 - smoothstep(te + 0.12, te + 0.3, T))
					if pw > 0.001:
						_mix_pose(AnimData.pose("def.parry" if role == "D" else "react.rebuff"), pw)
			"slip":
				if role == "D":
					_window_pose("def.slip", T - bt, 0.05, 0.15, 0.35)
			"dodge":
				if role == "D":
					var dargs: Dictionary = b.args if b.args is Dictionary else {}   # a dodge beat can carry no args (the spaced profile): the plain dodge
					if String(dargs.get("side", "")) == "cross":
						# the step-around: up and over the attacker, then down behind him (two moves, a few ticks each)
						var leg: float = float(dargs.get("dur", 0.15)) * 0.5
						var tau: float = T - bt
						if tau >= -0.02 and tau < 2.0 * leg + 0.2:
							_skip_inertia = true   # the two moves are a few ticks each: the pose pulses must show, not be smoothed away
						if tau >= 0.0 and tau < leg + 0.05:
							_mix_pose(AnimData.pose("def.hop"), smoothstep(0.0, 0.025, tau) * (1.0 - smoothstep(leg - 0.04, leg + 0.04, tau)))
						if tau >= leg - 0.05 and tau < 2.0 * leg + 0.2:
							_mix_pose(AnimData.pose("def.drop"), smoothstep(leg - 0.04, leg + 0.03, tau) * (1.0 - smoothstep(2.0 * leg - 0.02, 2.0 * leg + 0.15, tau)))
					else:
						_window_pose("def.blink_in", T - bt, 0.04, 0.12, 0.3)
			"guardBreak":
				if role == "D":
					_window_pose("def.guard_break", T - bt, 0.05, 0.25, 0.5)
			"clashWave":
				_window_pose("clash.push", T - bt, 0.05, 0.2, 0.4)


## A pose over the time since its beat: eased in over `rise`, held to `hold`, eased out by `end`.
func _window_pose(id: String, t: float, rise: float, hold: float, end: float) -> void:
	if t < 0.0 or t > end:
		return
	var w: float = smoothstep(0.0, rise, t) * (1.0 - smoothstep(hold, end, t))
	if w > 0.001:
		_mix_pose(AnimData.pose(id), w)


# ------------------------------------------------------------------ contact: the striking limb reaches the defender

## The defender's body point for a region (data/anim/sockets.json regions), in the defender's model space.
func _region_point(name: String) -> Vector3:
	var regs: Dictionary = AnimData.sockets.get("regions", {})
	var r: Dictionary = regs.get(name, regs.get("chest", {}))
	var bn: String = String(r.get("bone", "spine_2"))
	var off: Array = r.get("offset", [0, 3, 0])
	var bi: int = AnimRig.index[bn]
	if not _full_fk and not SOCKET_SET.has(bn):
		AnimPose.fk(q, hips, gq, gp)
		_full_fk = true
	return gp[bi] + gq[bi] * Vector3(float(off[0]), float(off[1]), float(off[2])) + root_off


## How far the striking part can reach from its root (the shoulder, the hip, the spine): the length of the chain for a two-bone
## limb, the distance to the tip for an aimed one. The tip is where the blow lands from (the wrist, the elbow, the head).
func _strike_tip(sk: Dictionary, a: int, b: int, c: int) -> Vector3:
	if String(sk.get("mode", "ik")) == "ik":
		return gp[c]
	var off: Array = sk.get("tip_offset", [0, 0, 0])
	return gp[c] + gq[c] * Vector3(float(off[0]), float(off[1]), float(off[2]))


func _strike_reach(sk: Dictionary, a: int, b: int, c: int) -> float:
	if String(sk.get("mode", "ik")) == "ik":
		return (gp[b] - gp[a]).length() + (gp[c] - gp[b]).length() - 0.5
	return (_strike_tip(sk, a, b, c) - gp[a]).length()


## IK the striking hand or foot onto the defender's body: the wrist (ankle) goes to the region's surface minus the fist, so
## the fist lands on him on the contact tick, and the hips lunge for what the arm cannot reach. The authored limb blends
## into the solved one by the contact weight, so the key poses stay the look and the defender's actual position decides
## where it lands. Nothing happens if the opponent is behind the thrower (the face override turns him first).
func _contact_ik(S: SimState, f) -> void:
	_contact_one(S, f, _ci_limb, false)
	if _ci_limb2 != "":
		_contact_one(S, f, _ci_limb2, true)


## One striking limb onto the defender. A second limb of the same blow (second = true) reaches from where the first left the body:
## the hips' lunge is already in the pose and the step-in in `_step_x`, so it only asks for what is still missing.
func _contact_one(S: SimState, f, base_limb: String, second: bool) -> void:
	var opp = _ci_opp
	if opp == null or _ci_dmg <= 0.0:
		return
	var oaf: AnimFighter = RenderAnim.fighter(S, opp)
	if oaf.version == 0:
		return
	var limb: String = base_limb
	var sided: bool = base_limb.contains("_")
	if _ci_side and sided:
		limb = base_limb.substr(0, base_limb.length() - 1) + ("l" if base_limb.ends_with("r") else "r")
	var kind: String = limb.get_slice("_", 0)
	var sk: Dictionary = AnimData.sockets.get("limbs", {}).get(kind, {})
	if sk.is_empty():
		return
	var aim: bool = String(sk.get("mode", "ik")) == "aim"
	var sfx: String = limb.substr(limb.length() - 1) if sided else "r"
	var zs: float = (1.0 if sfx == "r" else -1.0) if sided else 0.0
	var end_len: float = float(sk.get("end_len", 6.0))
	var lunge_max: float = float(sk.get("lunge_max", 8.0))
	var step_max: float = (float(sk.get("step_max", 10.0)) if _ci_step < 0.0 else _ci_step) * _ci_step_k
	var dx: float = SimWrap.sdx(f.x, opp.x)
	if S.depthOn:
		# fighters in depth: the rival is not on the plane, so the target is straight ahead of a body turned along the line (`depth_yaw`) at the three-axis distance; its reach on screen is the plane's
		var ddz: float = opp.z - f.z
		dx = (1.0 if dx >= 0.0 else -1.0) * sqrt(dx * dx + ddz * ddz)
	var rp: Vector3 = oaf._region_point(_ci_target)
	var mx: float = (dx + oaf.vface * rp.x) * vface
	if mx < 4.0:
		return
	var my: float = (opp.y - f.y) + rp.y
	if not press.is_empty():
		# a styled blow's held beat keeps the point it landed on: the defender's recoil must not drag the arm after him through the hold
		var li: int = 1 if second else 0
		if S.T >= _ci_tc - 0.0001:
			if absf(float(_ci_latch_tc[li]) - _ci_tc) > 0.0001:
				_ci_latch_tc[li] = _ci_tc
				_ci_latch[li] = Vector2(mx, my)
			else:
				mx = _ci_latch[li].x
				my = _ci_latch[li].y
	var surf: float = float(AnimData.sockets.get("regions", {}).get(_ci_target, {}).get("surface", 6.5))
	var tgt := Vector3(mx - surf - end_len - _smear_now(S.T) - _pr_dx - (_step_x if second else 0.0), my, float(sk.get("reach_z", 5.0)) * zs)
	var ix: Dictionary = AnimRig.index
	var a: int
	var b: int
	var c: int
	if aim:
		var abn: String = String(sk["bone"])
		a = ix[abn + "_" + sfx] if (sided and ix.has(abn + "_" + sfx)) else ix[abn]   # a bone with a side (upper_arm) or one without (spine_1)
		b = a
		c = ix[String(sk["tip"]) + ("_" + sfx if sided else "")]
	else:
		var ch: Array = sk["chain"]
		a = ix[String(ch[0]) + "_" + sfx]
		b = ix[String(ch[1]) + "_" + sfx]
		c = ix[limb]
	AnimPose.fk(q, hips, gq, gp)
	_full_fk = true
	var reach: float = _strike_reach(sk, a, b, c)
	# how far forward the shoulder must come (along x, the way the hips and the step move it) for the arm to just reach
	var d3: Vector3 = tgt - gp[a]
	var side2: float = d3.y * d3.y + d3.z * d3.z
	var need: float = d3.x - (sqrt(reach * reach - side2) if side2 < reach * reach else 0.0)
	need = maxf(need, 0.0)
	# the clavicle hunch brings the shoulder to meet it first (an arm blow; the legs and the head have no shoulder to give)
	var hm: float = float(sk.get("hunch_max", 0.0))
	if hm > 0.0 and need > 0.0 and AnimPose.hunch_auto and sided:
		AnimPose.hunch(q, sfx, minf(need, hm) * _ci_w, 0.0)
		AnimPose.fk(q, hips, gq, gp)
		reach = _strike_reach(sk, a, b, c)
		d3 = tgt - gp[a]
		side2 = d3.y * d3.y + d3.z * d3.z
		need = maxf(d3.x - (sqrt(reach * reach - side2) if side2 < reach * reach else 0.0), 0.0)
	# above or below the arm's reach whatever the lunge (a defender on another level): the excess is what is left over
	var excess: float = need - lunge_max - step_max
	if side2 >= reach * reach:
		excess = sqrt(side2) - reach
	elif need <= 0.0 and d3.length() > reach:
		excess = d3.length() - reach   # the target is behind the shoulder (the fighters overlap): no step forward helps
	var lunge: float = minf(need, lunge_max) * _ci_w
	var step: float = clampf(need - lunge_max, 0.0, step_max) * _ci_w
	# a kick whose hips are already past its target (the pose's own lunge, or a defender closer than the blow's range) would have to swing the thigh back through its limit: the body gives ground
	# instead, as far as data `min_fwd` asks (the foot's target at least that far ahead of the hip), at most `retreat_max` (homework 4's pulled frames: a front kick's thigh pulled 100 degrees)
	var min_fwd: float = float(sk.get("min_fwd", 0.0))
	if min_fwd > 0.0 and not aim and need <= 0.0 and (RenderAnim.hand_retreat if kind == "hand" else RenderAnim.kick_retreat):
		var back: float = clampf(min_fwd - d3.x, 0.0, float(sk.get("retreat_max", 12.0)))
		if side2 < reach * reach:
			back = minf(back, maxf(sqrt(reach * reach - side2) - d3.x - 1.0, 0.0))   # never so far that the foot no longer reaches
		if back > 0.0:
			step = -back * _ci_w
			debug["retreats"] = int(debug.get("retreats", 0)) + 1
	_step_x = (_step_x + step) if second else step
	var ik_t: Vector3 = tgt - Vector3(lunge + step, 0.0, 0.0)
	var qa0: Quaternion = q[a]
	var qb0: Quaternion = q[b]
	var gap: float
	if aim:
		# one bone turned so the tip points at the target: what the joint cannot reach is the gap, what is nearer is overshoot
		var tip: Vector3 = _strike_tip(sk, a, b, c)
		var dir_now: Vector3 = (tip - gp[a]).normalized()
		var dir_to: Vector3 = (ik_t - gp[a]).normalized()
		var qa_new: Quaternion = Quaternion(dir_now, dir_to) * gq[a]
		q[a] = gq[AnimRig.parent[a]].inverse() * qa_new
		q[a] = qa0.slerp(q[a], _ci_w)
		if RenderAnim.source_limits and AnimJoints.ik_limits:
			AnimJoints.clamp_bone(q, a, _rd.shape_key)   # an elbow or a knee blow turns the whole upper bone at the target: the turn stops at its limit and the tip is short, instead of a twist the last pass pulls
		gap = maxf(0.0, (ik_t - gp[a]).length() - reach)
	else:
		var pole: Vector3 = gp[b]   # the elbow (knee) stays on the side the authored pose has it, so the solved limb is its neighbour
		AnimPose.ik_limb(q, gq, gp, a, b, c, ik_t, pole, 1.0 if kind == "hand" else -1.0, _rd.shape_key, 0.0, RenderAnim.source_limits)
		q[a] = AnimJoints.slerp_limb(qa0, q[a], _ci_w) if AnimJoints.ik_limits else qa0.slerp(q[a], _ci_w)
		q[b] = qb0.slerp(q[b], _ci_w)
		if RenderAnim.source_limits and AnimJoints.ik_limits:
			# a plane the solve judged legal can still leave the blended upper bone a little past its range (the frame the held point is latched): stopped at the limit here
			if AnimJoints.bone_excess(q, a, _rd.shape_key) > 0.0:
				AnimJoints.clamp_bone(q, a, _rd.shape_key)
			if AnimJoints.bone_excess(q, b, _rd.shape_key) > 0.0:
				AnimJoints.clamp_bone(q, b, _rd.shape_key)
		# the gap is what the player sees: on the plane (the target's depth is a nominal reach_z, and the limit-respecting solve leaves the wrist a few units off it, which the side-on view cannot show). In depth (fighters off the plane) it stays three-dimensional
		gap = maxf(0.0, (ik_t - gp[c]).length() if S.depthOn else Vector2(ik_t.x - gp[c].x, ik_t.y - gp[c].y).length())
		if gap > 0.0 and (gp[c] - gp[a]).length() > (ik_t - gp[a]).length():
			gap = 0.0   # the limb folds no further than its joint allows, so it ends past a target that is nearer than that (inside the defender), not short of it
	hips.x += lunge
	debug["ik_frames"] += 1
	if second:
		if absf(S.T - _ci_tc) < DT * 0.5 and _ci_w > 0.99:
			debug["gap2_max"] = maxf(float(debug.get("gap2_max", 0.0)), gap)
			debug["gap2_n"] = int(debug.get("gap2_n", 0)) + 1
	elif absf(S.T - _ci_tc) < DT * 0.5 and _ci_w > 0.99 and _ci_tc != _gap_tc:
		_gap_tc = _ci_tc
		debug["gap_max"] = maxf(float(debug["gap_max"]), gap)
		debug["gap_sum"] += gap
		debug["gap_n"] += 1
		debug["gaps"].append(snappedf(gap, 0.1))
		debug["gaps"].append(snappedf(excess, 0.1))
		if gap > 1.5 and debug["notes"].size() < 40:
			var ex = S.dirS.ex
			debug["notes"].append("tick %d %s (%s): target %.0f u ahead, short by %.1f (need %.1f, lunge %.1f, step %.1f), %s %s dmg %.0f" % [S.tick, ex.kind if ex != null else "-", ex.tag if ex != null else "-", mx, gap, need, lunge, step, _ci_target, limb, _ci_dmg])


## The free arm of a blow (the one that is not striking) may turn only so far in one solve (data `joints.json` `slew.free_arm_deg`, degrees a 60th of a second; homework 4b: the key poses
## of a blow put the free arm at a plane of its own and the blend from the guard to it turned the upper arm 60 to 120 degrees in two ticks, the elbow's plane flipping on the way, which
## reads as the arm snapping). The striking arm is the blow's own timing and is never slowed; neither is a two-limb blow's. The drawn arm keeps to the limit, and catches up on the next ticks.
const WING_SIG_BONES := ["pelvis", "spine_1", "spine_2", "neck", "head", "clavicle_r", "clavicle_l", "upper_arm_r", "forearm_r", "upper_arm_l", "forearm_l"]
const SHAKE_S: float = 6.0 / 60.0   # the contact-keyed shake of a blow with no hit-stop of its own: 6 ticks, decaying
const SLEW_BONES := ["upper_arm_r", "forearm_r", "upper_arm_l", "forearm_l"]
var _wing_sig: float = 1.0e9             # the idle wing check's last signature of the pose it judged (the spine, the clavicles and the arms): an unchanged idle pose is not judged again


func _free_arm_slew(dt: float, state: String = "") -> void:
	var ix: Dictionary = AnimRig.index
	var names: Array = SLEW_BONES
	if _sl_prev.size() != 4:
		_sl_prev.resize(4)
		_sl_have = false
	var limit: float = AnimJoints.slew_free_arm
	var strike: bool = RenderAnim.free_arm_slew and limit > 0.0 and _sl_have and _ci_limb2 == "" and (_part != "" or _ci_w > 0.001) and String(_ci_limb).contains("_") and dt > 0.0
	var strike_side: String = ""
	var ttc: int = int(press.get("ticks_to_contact", 99)) if not press.is_empty() else 99   # ticks to the blow's contact (negative after it)
	if strike:
		strike_side = String(_ci_limb).substr(String(_ci_limb).length() - 1)
		if _ci_side:
			strike_side = "l" if strike_side == "r" else "r"
	var mx: float = deg_to_rad(limit) * minf(dt / DT, 3.0)
	if RenderAnim.debug_checks:
		debug["slew_state"] = "%s have=%s part=%s ciw=%.2f l2=%s dt=%.3f" % [str(strike), str(_sl_have), _part, _ci_w, _ci_limb2, dt]
	# a free arm caught in a wing between two keys (the elbow up and behind its shoulder, the forearm hanging from it) is drawn toward the guard arm by how much of a wing it is
	# (and a body that is standing or flying upright with no blow and no sequence: an idle arm can sit in one too)
	var idle_ok: bool = (state == "free" or state == "locked") and _part == "" and _seq.is_empty() and _ci_w < 0.001
	var skip_idle: bool = false
	if idle_ok and not strike and _wing_w[0] <= 0.001 and _wing_w[1] <= 0.001:
		# an idle body whose spine, clavicles and arms are the pose they were last tick (and had no wing then) is the same answer: it is not judged again (the check forward-kinematics the whole body)
		var sg: float = 0.0
		for bn in WING_SIG_BONES:
			var qq: Quaternion = q[int(ix[bn])]
			sg += qq.x + 2.0 * qq.y + 3.0 * qq.z + 4.0 * qq.w
		if absf(sg - _wing_sig) < 0.000001:
			skip_idle = true
		_wing_sig = sg
	else:
		_wing_sig = 1.0e9
	if not skip_idle and AnimJoints.wing_runtime > 0.0 and AnimData.pose_exists("stance.aggressive") and (strike or idle_ok or _wing_w[0] > 0.001 or _wing_w[1] > 0.001):
		var gd: AnimPose = AnimData.pose("stance.aggressive")
		var sides: Array = ["r", "l"]
		if strike or idle_ok:
			AnimPose.fk(q, hips, gq, gp)
		var upright: bool = true
		if idle_ok:
			var hd: Vector3 = gp[int(ix["head"])] - gp[int(ix["pelvis"])]
			upright = absf(hd.x) < 0.6 * hd.y   # judged against up: not a body laid over in flight
		for si in range(2):
			var sd: String = String(sides[si])
			var ua: int = int(ix["upper_arm_" + sd])
			var fa: int = int(ix["forearm_" + sd])
			var target: float = 0.0
			if (strike and sd != strike_side) or (idle_ok and upright):
				var sh: Vector3 = gp[ua]
				var el: Vector3 = gp[fa]
				var wr: Vector3 = gp[int(ix["hand_" + sd])]
				var fl: float = 180.0 - rad_to_deg((sh - el).normalized().angle_to((wr - el).normalized()))
				var s: float = clampf((el.y - sh.y - AnimJoints.wing_up) / 6.0, 0.0, 1.0) * clampf((el.y - wr.y - AnimJoints.wing_drop) / 8.0, 0.0, 1.0) * clampf((sh.x - el.x - AnimJoints.wing_back) / 4.0, 0.0, 1.0)
				if fl > rad_to_deg(AnimJoints.wing_psi):
					target = AnimJoints.wing_runtime * s
			# in over a few ticks, out over a few more: the correction itself must not be a snap
			_wing_w[si] = move_toward(_wing_w[si], target, (0.22 if target > _wing_w[si] else 0.12) * minf(dt / DT, 3.0))
			if strike and ttc == 0:
				_wing_w[si] = target   # on the contact tick the pose is the blow's key whatever came before (anim_check's tech consistency): the correction has arrived
			if _wing_w[si] > 0.001:
				q[ua] = q[ua].slerp(gd.q[ua], _wing_w[si])
				q[fa] = q[fa].slerp(gd.q[fa], _wing_w[si])
				debug["wing_fixes"] = int(debug.get("wing_fixes", 0)) + 1
	for k in range(4):
		var nm: String = String(names[k])
		var i: int = int(ix[nm])
		if strike and not nm.ends_with("_" + strike_side):
			var prev: Quaternion = _sl_prev[k]
			var ang: float = prev.angle_to(q[i])
			# the arm may not be late for the blow: with `ttc` ticks to the contact it may turn as much as it takes to be there on the contact tick (none left on that tick: it arrives), so the pose at
			# the contact is the key whatever the body came from (anim_check's tech consistency) and the approach is as smooth as the time allows
			var mx_now: float = mx
			if ttc >= 0 and ttc <= 8:
				mx_now = maxf(mx, 10.0 if ttc == 0 else ang / float(ttc))
			if ang > mx_now and ang > 0.0001:
				q[i] = prev.slerp(q[i], mx_now / ang)
				debug["slews"] = int(debug.get("slews", 0)) + 1
			if RenderAnim.source_limits and AnimJoints.ik_limits:
				# the arm held back by the rate limit can sit in a bend the pose itself never asks for; and an arm swung back through the shoulder's blind spot is brought out of it as it goes, not in one pull at the end
				if AnimJoints.bone_excess(q, i, _rd.shape_key) > 0.0:
					AnimJoints.clamp_bone(q, i, _rd.shape_key)
				if nm.begins_with("upper_arm"):
					AnimJoints.squeeze_arm_back(q, i, _rd.shape_key)
		elif strike and RenderAnim.source_limits and AnimJoints.ik_limits and nm.begins_with("upper_arm"):
			AnimJoints.squeeze_arm_back(q, i, _rd.shape_key)   # the striking arm keeps its own timing; only the shoulder's blind spot is kept clear of it
		_sl_prev[k] = q[i]
	_sl_have = true



## The side of the arm that is not striking while a one-limb hand blow is playing ("r" or "l"), or "" (no blow, a foot or a two-limb blow).
func _blow_free_side() -> String:
	if _ci_limb2 != "" or not (_part != "" or _ci_w > 0.001) or not String(_ci_limb).begins_with("hand_"):
		return ""
	var side: String = String(_ci_limb).substr(String(_ci_limb).length() - 1)
	if _ci_side:
		side = "l" if side == "r" else "r"
	return "l" if side == "r" else "r"


func _inertialise(dt: float, prof: Dictionary) -> void:
	var n: int = AnimRig.N
	if (_skip_inertia or not _form.is_empty()) and _ip_have:
		# a transformation plays inside a pause (no ticks, so nothing to settle a join on): its own beats are the easing, and
		# the way back into the fight is inertialised once the ticks run again
		for i in range(n):
			_ip_raw[i] = q[i]
			_ip_cur[i] = Quaternion.IDENTITY
		_ip_hraw = hips
		_ip_hcur = Vector3.ZERO
		_ip_active = false
		return
	if not _ip_have:
		_ip_have = true
		_ip_raw.resize(n)
		_ip_off.resize(n)
		_ip_cur.resize(n)
		for i in range(n):
			_ip_raw[i] = q[i]
			_ip_off[i] = Quaternion.IDENTITY
			_ip_cur[i] = Quaternion.IDENTITY
		_ip_hraw = hips
		return
	var jump: bool = false
	var skip_side: String = _blow_free_side() if RenderAnim.free_arm_slew else ""   # the free arm's own pose is the slew's business: its jump must not start a join of the whole body (the su_hammer step)
	for i in range(n):
		if skip_side != "" and (i == int(AnimRig.index["upper_arm_" + skip_side]) or i == int(AnimRig.index["forearm_" + skip_side]) or i == int(AnimRig.index["clavicle_" + skip_side])):
			continue
		if absf(q[i].dot(_ip_raw[i])) < _ip_cos:
			jump = true
			break
	if jump and _blow_snap and not RenderAnim.blow_join:
		jump = false
	if jump:
		# continuity: what was drawn last solve (the old pose with the offset it carried) minus the new raw pose
		for i in range(n):
			_ip_off[i] = (_ip_cur[i] * _ip_raw[i]) * q[i].inverse()
		_ip_hoff = (_ip_hraw + _ip_hcur) - hips
		_ip_t = 0.0
		_ip_active = true
		# a join close to a blow must be spent by the contact tick (the contact key is exact), so it settles in the time left
		var dur0: float = float(prof.get("inertia_s", INERTIA_SNAPPY if float(prof.get("solve_hz", 60.0)) < 59.0 else INERTIA_FLUID))
		_ip_dur = dur0 if _tc_left < 0.0 else minf(dur0, maxf(_tc_left - 2.0 * DT, 0.0))
	for i in range(n):
		_ip_raw[i] = q[i]
	_ip_hraw = hips
	if not _ip_active:
		_ip_acc = 0.0
		return
	var idt: float = minf(_ip_acc, 0.1)
	_ip_acc = 0.0
	_ip_t += idt
	var w: float = 1.0 - smoothstep(0.0, _ip_dur, _ip_t) if _ip_dur > 0.0 else 0.0
	var limit_join: bool = RenderAnim.source_limits and AnimJoints.ik_limits
	for i in range(n):
		var o: Quaternion = Quaternion.IDENTITY.slerp(_ip_off[i], w)
		var raw_q: Quaternion = q[i]
		q[i] = o * raw_q
		if limit_join and AnimJoints.kind[i] != AnimJoints.KIND_NONE:
			# the join's offset is the old pose's bend carried over the new one; on a jointed bone it can take the sum past the limit (an upper arm twisted 60 degrees for a few ticks). The offset is
			# trimmed on that bone until the sum is no worse than the pose itself, so there is nothing for the last pass to pull
			if AnimJoints.bone_excess(q, i, _rd.shape_key) > 0.02:
				q[i] = raw_q
				var raw_ex: float = AnimJoints.bone_excess(q, i, _rd.shape_key)
				var ws: float = w
				for it in range(5):
					ws *= 0.5
					o = Quaternion.IDENTITY.slerp(_ip_off[i], ws)
					q[i] = o * raw_q
					if AnimJoints.bone_excess(q, i, _rd.shape_key) <= raw_ex + 0.02:
						break
				if AnimJoints.bone_excess(q, i, _rd.shape_key) > raw_ex + 0.02:
					o = Quaternion.IDENTITY
					q[i] = raw_q
		_ip_cur[i] = o
	_ip_hcur = _ip_hoff * w
	hips += _ip_hcur
	if w <= 0.0:
		_ip_active = false
		for i in range(n):
			_ip_cur[i] = Quaternion.IDENTITY
		_ip_hcur = Vector3.ZERO


## How far behind the anchor the body is drawn now (the contact catch's smear); the contact solve reaches that much further.
func _smear_now(T: float) -> float:
	if _smear == 0.0:
		return 0.0
	var sp: float = (T - _smear_t0) / 0.05
	return 0.0 if sp >= 1.0 else _smear * (1.0 - smoothstep(0.0, 1.0, sp))


func _set_lag(k: float) -> void:
	if k == _lag_k:
		return
	_lag_k = k
	for i in range(AnimRig.N):
		_lag[i] = AnimData.bone_lag[i] * k / 0.45


## The timing profile for a kind of part (light, heavy, chain, rush, launch, power): Orb's mix unless a style is forced.
func _part_prof(kind: String) -> Dictionary:
	if RenderAnim.style_forced():
		return _prof
	var nm: String = String(AnimData.by_part.get(kind, ""))
	return AnimData.profile(nm) if nm != "" else _prof


# ------------------------------------------------------------------ beam, reactions, springs

func _rd_amp() -> float:
	return 0.35 if RenderAnim.reduced_motion else 1.0


## One sim tick of the ragdoll, from the fighter's own state (never random, never written back). Velocity and acceleration are
## taken in the body frame: the body is rotated by the sim's rot, mirrored by the visual facing. A launch, a slam, a skid, a
## brace before the ground and a tuck in a spin are all this one controller.
## How much each ragdoll degree of freedom may move: a broken arm hangs heavy, so its three (upper arm, its sideways swing and forearm) move at a third
## while the body tumbles or settles (a limp arm does not whip like a good one); every other one is free.
func _rd_scale() -> PackedFloat32Array:
	if not _arm_broken:
		return PackedFloat32Array()
	var sc := PackedFloat32Array()
	sc.resize(AnimRagdoll.N)
	for i in range(AnimRagdoll.N):
		sc[i] = 1.0
	var base: int = 5 if _hang_right else 2
	for j in range(3):
		sc[base + j] = 0.33
	sc[16 if _hang_right else 15] = 0.33   # the broken arm's twist hangs with it
	return sc


## RG0: which side of the body met a surface whose outward normal is (nx, ny) in the world: +1 the front (a fold), -1 the back (an arch), +1 again when it was nearer the head or the feet
## (the plain fold of before). The body's frame is the one the controller uses: mirrored by the facing, turned by the sim's rot.
func _hit_side(nx: float, ny: float) -> float:
	if not RenderAnim.rd_variety:
		return 1.0
	var c: float = cos(_rd_rot)
	var sn: float = sin(_rd_rot)
	var ox: float = nx * vface
	var bx: float = ox * c - ny * sn
	var score: float = -bx   # the surface is on the side the body's x points to when the normal points the other way
	if absf(score) < AnimRagdoll.side_dead:
		return 1.0
	return clampf(score / 0.6, -1.0, 1.0)


func _rd_tick(S: SimState, f, dt: float) -> void:
	if f.state == "intro" and RenderAnim.intro_poses:
		return   # the fall is scripted: nothing in the ragdoll should answer its speed
	if not RenderAnim.layer("ragdoll"):
		if _rd.out_w > 0.0 or _rd.energy() > 0.0:
			_rd.reset()
		_rd_have = false
		return
	var t0: int = Time.get_ticks_usec() if RenderAnim.debug_checks else 0
	var amp: float = _rd_amp()
	var vw := Vector2(f.vx, f.vy)
	var aw := Vector2.ZERO
	if _rd_have:
		aw = (vw - _rd_vw) / maxf(dt, 0.0001) + Vector2(0.0, 1000.0)
		if aw.length() > AnimRagdoll.a_max:
			aw = aw.normalized() * AnimRagdoll.a_max
	_rd_vw = vw
	var m: float = vface
	var c: float = cos(f.rot)
	var sn: float = sin(f.rot)
	var vo := Vector2(vw.x * m, vw.y)
	var ao := Vector2(aw.x * m, aw.y)
	var vl := Vector2(vo.x * c - vo.y * sn, vo.x * sn + vo.y * c)
	var al := Vector2(ao.x * c - ao.y * sn, ao.x * sn + ao.y * c)
	if _ab_w > 0.01:
		al *= 1.0 + (float(AnimData.brake.get("whip", 2.0)) - 1.0) * _ab_w   # braking: the limbs and cloth stream forward
	var st: String = f.state
	var sliding: bool = f.slide > 0.0
	var flying: bool = (st == "launched" or st == "dropped") and not sliding
	var speed: float = vw.length()
	_rd_rot = f.rot
	_fid = String(f.id)
	_rd.n_on = AnimRagdoll.N if (RenderAnim.rd_oop and not RenderAnim.reduced_motion) else AnimRagdoll.N_BASE   # reduced motion keeps the body in its plane
	_rd.weighted = RenderAnim.rd_weight
	if RenderAnim.rd_weight and (S.tick - _rd_tier_tk >= 12 or S.tick < _rd_tier_tk):
		_rd_tier_tk = S.tick   # the mass and the opponent's tier change rarely: read them twelve ticks apart, not every tick
		_rd.mass = float(AnimRagdoll.mass_of.get(String(f.id), AnimRagdoll.mass_of.get("default", 1.0)))
		var rdo = _opponent(S, f)
		_rd.tier = float(rdo.tier) if rdo != null else 1.0
	if RenderAnim.rd_variety and flying and not _rd_prev_flying:
		_rd_flights += 1
		_rd.set_flail_seed(slot, int(f.launchN), _rd_flights, vw.length())
	_rd_prev_flying = flying
	if _rd_have:
		# a slam (flight to down) folds the body; a skid starting from a flight whips it
		if st == "down" and _rd_prev_state == "launched":
			_rd.crumple(clampf(_rd_prev_speed / 3000.0, 0.3, 1.5), amp, _hit_side(0.0, 1.0))
		elif st == "down" and _rd_prev_state != "down" and is_same(S.game.ko, f):
			_rd.crumple(0.9, amp)
			_rd.kick(0, 6.0 * amp)
			debug["ko_falls"] += 1
		elif sliding and not _rd_prev_slide and _rd_prev_state == "launched":
			_rd.crumple(clampf(_rd_prev_speed / 4000.0, 0.2, 0.9), amp)
	if not _shape_set:
		_shape_set = true
		_rd.set_shape(String(f.id))
		_rd.phase = float(slot) * 0.9
	var free_t: float = 0.0
	var tuck: float = 0.0
	var brace: float = 0.0
	var skid: float = 0.0
	var crum: float = 0.0
	var flail: float = 0.0
	if flying:
		# the early launch is a flail (limbs thrown about); the body tucks only at a high spin and only after the first moments
		free_t = 0.6 if st == "dropped" else 0.85   # a drop was a shot, not a throw: looser than a stand, looser less than a launch
		tuck = AnimRagdoll.tuck_max * smoothstep(AnimRagdoll.tuck_spin.x, AnimRagdoll.tuck_spin.y, absf(f.spin)) * smoothstep(AnimRagdoll.tuck_after.x, AnimRagdoll.tuck_after.y, f.stateT) * (0.65 + 0.35 * cos(f.rot * 0.5))
		var fdur: float = _rd.fam_dur * _rd.launch_dur if RenderAnim.rd_variety else 1.0
		flail = (1.0 - smoothstep(AnimRagdoll.flail_fade.x * fdur, AnimRagdoll.flail_fade.y * fdur, f.stateT)) * (1.0 - tuck)
		flail *= 1.0 - _ab_w
		if f.vy < -200.0 and f.aimB < 0:
			var h: float = f.y - WorldWater.floorAt(S, f.x, f.z)
			if h > 0.0:
				var tc: float = (f.vy + sqrt(f.vy * f.vy + 2000.0 * h)) / 1000.0
				brace = 1.0 - smoothstep(AnimRagdoll.brace_time.x, AnimRagdoll.brace_time.y, tc)
				brace *= 1.0 - tuck * 0.5
				flail *= 1.0 - brace
	elif sliding:
		free_t = 0.55
		skid = AnimRagdoll.skid_w
	elif st == "down":
		free_t = 0.25 if f.stateT < 0.6 else 0.0
		crum = AnimRagdoll.crumple_down_w if f.stateT < 0.7 else 0.0
	# E: the defender's side. The blow the attacker is about to land is in the beat list ahead of time: a heavy one is braced for
	# (arms up, chin down, in the fighter's own brace shape) in the last 0.25 s, and a blow that misses (no damage) is flinched at
	var exc = S.dirS.ex
	var pre: float = 0.0
	if exc != null and exc.D == f and not flying and not sliding and st != "down" and RenderAnim.layer("defender"):
		var nb: Array = _next_blow(exc)
		if not nb.is_empty():
			var dtc: float = nb[0]
			if dtc > 0.0 and nb[2] > 0.0:
				pre = (1.0 - clampf(dtc / 0.25, 0.0, 1.0)) * (0.7 if nb[1] else 0.25) * (1.0 if int(f.stance) == 1 else 0.7)
				if pre > 0.05:
					debug["pre_brace"] += 1
			elif nb[2] <= 0.0 and dtc <= 0.0 and _miss_id != int(exc.n) * 64 + int(nb[3]) and not _has_evade(exc):
				_miss_id = int(exc.n) * 64 + int(nb[3])
				_near_miss(S, f, amp)
		# J: the dodge itself. He sees the blow coming and leans away from it in the 0.14 s before his dodge or slip beat
		var ev: Array = _next_evade(exc)
		if not ev.is_empty() and ev[0] > 0.0 and ev[0] < 0.14 and _lean_id != int(exc.n) * 64 + int(ev[1]):
			_lean_id = int(exc.n) * 64 + int(ev[1])
			_lean_away(S.T, amp)
	if exc != null and exc.A == f and not flying and not sliding and st != "down" and RenderAnim.layer("defender"):
		# J: the attacker's whiff: a blow that finds nothing (no damage, the defender gone) carries him past, off balance
		var ms: Array = _next_miss(exc)
		if not ms.is_empty() and ms[0] < 0.02 and _over_id != int(exc.n) * 64 + int(ms[1]):
			_over_id = int(exc.n) * 64 + int(ms[1])
			_over_commit(S.T, amp)
		else:
			# a dodge is the whiff of a rush: the defender is gone as the attacker arrives, and he is carried past
			var ea: Array = _next_evade(exc)
			if not ea.is_empty() and ea[0] < 0.02 and _over_id != int(exc.n) * 64 + 32 + int(ea[1]):
				_over_id = int(exc.n) * 64 + 32 + int(ea[1])
				_over_commit(S.T, amp)
	if not flying and not sliding:
		brace = maxf(brace, (1.0 - _hit_crum) * _hit_w * 0.45 + pre)
		crum = maxf(crum, _hit_crum * _hit_w * 0.5)
		free_t = maxf(free_t, 0.5 * _hit_w + 0.3 * pre)
	_hit_w = maxf(0.0, _hit_w - dt / (0.3 + 0.4 * _worn))
	_rd.w_tuck = tuck
	_rd.w_brace = brace
	_rd.w_skid = skid
	_rd.w_crumple = crum
	_rd.w_flail = flail
	# polish: the lean into acceleration while he is free, and the contact catch (a striker carried far in one tick is drawn
	# travelling to his place, not popping to it)
	var lean_t: float = 0.0
	if st == "free" or st == "locked":
		lean_t = clampf(ao.x / 9000.0, -1.0, 1.0) * 0.35 * amp
	_lean += (lean_t - _lean) * (1.0 - exp(-dt / 0.12))
	# G: banking into a turn, a burst on a dash start, a brake on a stop
	var bank_t: float = 0.0
	if (st == "free" or st == "locked") and (speed > 300.0 or _air_w > 0.3):
		bank_t = clampf(-ao.x / 9000.0, -1.0, 1.0) * 0.3 * amp
	_bank += (bank_t - _bank) * (1.0 - exp(-dt / 0.15))
	if st == "free":
		var ge: String = _gait_event(ao.x, _gait_speed, absf(vo.x))
		if ge == "burst" and S.T - _burst_t0 > 0.4:
			_burst_t0 = S.T
			debug["bursts"] += 1
		elif ge == "brake" and S.T - _brake_t0 > 0.5:
			_brake_t0 = S.T
			debug["brakes"] += 1
	_gait_speed = absf(vo.x)
	var cx: float = SimWrap.sdx(_prev_x, f.x) if _have_x else 0.0
	var pcx: float = _prev_cx
	_prev_x = f.x
	_prev_cx = cx
	_have_x = true
	var ex = S.dirS.ex
	if absf(cx) > 250.0 and ex != null and ex.A == f and not flying and not sliding and amp > 0.5 and _blow_due(ex):
		# a catch: the striker is carried far on the tick his blow lands; the body lags the anchor a little and the contact reaches that far
		_smear = clampf(-cx * m * 0.05, -10.0, 10.0)
		_smear_t0 = S.T
		debug["catches"] += 1
	_hit_free = maxf(0.0, _hit_free - dt * (1.6 - 0.8 * _worn))
	free_t = maxf(free_t, _hit_free)
	_rd_prev_state = st
	_rd_prev_slide = sliding
	_rd_prev_speed = speed if st == "launched" else _rd_prev_speed
	_rd_have = true
	var active: bool = st == "launched" or st == "down" or st == "dropped" or _rd.free > 0.02 or ((_rd.energy_over(0.03)) if RenderAnim.tick_fast else (_rd.energy() > 0.03))
	if active:
		_rd.step(dt, vl, al, free_t, amp, S.T)
	_rd.out_w = move_toward(_rd.out_w, 1.0 if active else 0.0, dt * 8.0)
	if not active and _rd.out_w <= 0.0 and _rd.energy() > 0.0:
		_rd.reset()
	if RenderAnim.debug_checks:
		debug["rd_ticks"] += 1
		debug["rd_usec"] += Time.get_ticks_usec() - t0


## Feet on the ground under them. A standing fighter on a slope (a crater wall, a rim, a heap) has one foot higher than the other:
## the pelvis follows the mean and each leg is solved to its own foot's ground (two-bone IK, the knee staying where the pose has
## it). A skid is pitched to the slope along its way. Reads the terrain only (WorldTerrain.groundY); cheap when the ground is flat
## (three reads, no solve).
func _ground_feet(S: SimState, f, dt: float) -> void:
	var st: String = f.state
	var sliding: bool = f.slide > 0.0
	# one ground read a solve; the slope reads only while he stands or slides, and cached while he stays within 3 units
	var g0: float
	if S.tick - _gf_gtick < 4 and absf(SimWrap.sdx(_gf_gx, f.x)) < 20.0:
		g0 = _gf_g0c
	else:
		g0 = WorldTerrain.groundY(S, f.x, f.z)
		_gf_g0c = g0
		_gf_gx = f.x
		_gf_gtick = S.tick
	var stand: bool = (st == "free" or st == "locked" or st == "charging") and not sliding and absf(f.y - g0) < 8.0
	var target_w: float = 0.0
	var pitch_t: float = 0.0
	if stand or sliding:
		if not (_gf_x_valid and absf(SimWrap.sdx(_gf_x, f.x)) < 3.0 and vface == _gf_face and S.tick - _gf_tick < 20):
			_gf_x_valid = true
			_gf_x = f.x
			_gf_face = vface
			_gf_tick = S.tick
			_gf_dF = WorldTerrain.groundY(S, f.x + vface * 10.0, f.z) - g0
			_gf_dB = WorldTerrain.groundY(S, f.x - vface * 10.0, f.z) - g0
			_gf_sl = (WorldTerrain.groundY(S, f.x + vface * 12.0, f.z) - WorldTerrain.groundY(S, f.x - vface * 12.0, f.z)) / 24.0
		if sliding:
			pitch_t = atan(_gf_sl) * 0.9
		elif absf(_gf_dF) > 2.5 or absf(_gf_dB) > 2.5:
			target_w = 1.0   # a gentler slope than this is under the pose's own tolerance and costs a leg solve for nothing
	if absf(target_w - _foot_w) < 0.001 and absf(pitch_t - _skid_pitch) < 0.001 and _foot_w < 0.02 and absf(_skid_pitch) < 0.01:
		_foot_shift = 0.0
		_foot_dh = Vector2.ZERO
		return
	var k: float = 1.0 - exp(-dt / 0.1)
	_foot_w += (target_w - _foot_w) * k
	_skid_pitch += (pitch_t - _skid_pitch) * (1.0 - exp(-dt / 0.08))
	if absf(_skid_pitch) > 0.01:
		var pe: int = AnimRig.index["pelvis"]
		q[pe] = q[pe] * Quaternion(Vector3(0, 0, 1), _skid_pitch)
	if _foot_w < 0.02:
		_foot_shift = 0.0
		_foot_dh = Vector2.ZERO
		return
	var ix: Dictionary = AnimRig.index
	# the leg solve runs every second tick; in between the last solve's local corrections are applied again (the pose moves little)
	if _leg_tick >= 0 and S.tick - _leg_tick == 1 and (S.tick & 1) == 1:
		hips.y += _foot_shift
		for kk in range(4):
			var bi: int = _LEG_BONES[kk]
			q[bi] = q[bi] * _leg_dq[kk]
		_leg_tick = S.tick
		return
	var q0: Array[Quaternion] = [q[16], q[17], q[19], q[20]]
	AnimPose.fk_chain(q, hips, gq, gp, LEG_CHAIN)   # only the legs and what they hang from
	var fl: int = ix["foot_l"]
	var fr: int = ix["foot_r"]
	var dhl: float = WorldTerrain.groundY(S, f.x + vface * gp[fl].x, f.z) - g0
	var dhr: float = WorldTerrain.groundY(S, f.x + vface * gp[fr].x, f.z) - g0
	_foot_dh = Vector2(dhl, dhr)
	var shift: float = clampf((dhl + dhr) * 0.5, -10.0, 10.0) * _foot_w
	_foot_shift = shift
	hips.y += shift
	for i in LEG_CHAIN:
		if i > 0:
			gp[i].y += shift
	debug["slope_frames"] += 1
	for leg in [["thigh_l", "shin_l", "foot_l", dhl], ["thigh_r", "shin_r", "foot_r", dhr]]:
		var a: int = ix[leg[0]]
		var b: int = ix[leg[1]]
		var c: int = ix[leg[2]]
		var want: float = float(leg[3]) * _foot_w - shift
		if absf(want) < 0.4:
			continue   # this foot is already where the ground is
		var tgt := Vector3(gp[c].x, gp[c].y + want, gp[c].z)
		var pole: Vector3 = gp[b]
		AnimPose.ik_limb(q, gq, gp, a, b, c, tgt, pole, -1.0, _rd.shape_key)
	if _leg_dq.size() != 4:
		_leg_dq.resize(4)
	for kk in range(4):
		_leg_dq[kk] = q0[kk].inverse() * q[_LEG_BONES[kk]]
	_leg_tick = S.tick


## The next blow the attacker throws in the running exchange: [time to contact, heavy, damage, beat index], or [] (a parried
## exchange has none). A blow just fired (up to 0.03 s ago) still counts, so a miss can be flinched at.
static func _next_blow(ex) -> Array:
	if ex.cancel:
		return []
	var best: Array = []
	var i: int = 0
	for b in ex.beats:
		if b.op == "strike" and String(b.args.a) == "A":
			var dtc: float = b.t - ex.t
			if dtc >= -0.03 and (best.is_empty() or dtc < best[0]):
				best = [dtc, _is_heavy(ex, b.args), float(b.args.get("dmg", 0.0)), i]
		i += 1
	return best


## The next dodge or slip beat of the exchange: [time to it, beat index], or [].
static func _next_evade(ex) -> Array:
	var best: Array = []
	var i: int = 0
	for b in ex.beats:
		if b.op == "dodge" or b.op == "slip":
			var dt_e: float = b.t - ex.t
			if dt_e >= 0.0 and (best.is_empty() or dt_e < best[0]):
				best = [dt_e, i]
		i += 1
	return best


## The attacker's next blow that does no damage (a whiff): [time to contact, beat index] from 0.03 s after it to 0.1 s before, or [].
static func _next_miss(ex) -> Array:
	var best: Array = []
	var i: int = 0
	for b in ex.beats:
		if b.op == "strike" and String(b.args.a) == "A" and float(b.args.get("dmg", 0.0)) <= 0.0:
			var dtc: float = b.t - ex.t
			if dtc >= -0.03 and dtc < 0.1 and (best.is_empty() or dtc < best[0]):
				best = [dtc, i]
		i += 1
	return best


## The defender's lean away from a blow he is about to dodge: head and chest back, arms flung back, the weight on the heels.
func _lean_away(T: float, amp: float) -> void:
	_lean_t0 = T
	_rd.kick(0, 8.0 * amp)
	_rd.kick(1, 7.0 * amp)
	_rd.kick(2, -3.0 * amp)
	_rd.kick(5, -3.0 * amp)
	_hit_free = minf(1.0, _hit_free + 0.25)
	_rd.out_w = 1.0
	debug["leans"] += 1


## The whiff's over-commit: the chest and head go forward after the blow, the arms with it, the body carried a step past.
func _over_commit(T: float, amp: float) -> void:
	_over_t0 = T
	_rd.kick(1, -8.0 * amp)
	_rd.kick(0, -5.0 * amp)
	_rd.kick(2, 6.0 * amp)
	_rd.kick(5, 6.0 * amp)
	_rd.kick(4, 3.0 * amp)
	_rd.kick(7, 3.0 * amp)
	_hit_free = minf(1.0, _hit_free + 0.3)
	_rd.out_w = 1.0
	debug["overcommits"] += 1


## His blow was blocked (the sim's damage event of kind guard): the arms bounce back, the chest rocks, a small step back.
func on_blocked(T: float) -> void:
	if not RenderAnim.layer("defender"):
		return
	_block_t0 = T
	var amp: float = _rd_amp()
	_rd.kick(2, -5.0 * amp)
	_rd.kick(5, -5.0 * amp)
	_rd.kick(1, 3.0 * amp)
	_rd.kick(0, 3.0 * amp)
	_rd.out_w = 1.0
	debug["blocked"] += 1


## The root offsets of the lean-away (back), the over-commit (forward) and the blocked recoil (back), decaying.
func _evade_offsets(T: float) -> float:
	var x: float = 0.0
	var a: float = _rd_amp()
	var tl: float = T - _lean_t0
	if tl >= 0.0 and tl < 0.6:
		x -= 3.0 * a * sin(minf(tl / 0.12, 1.0) * PI * 0.5) * exp(-tl / 0.3)
	var to: float = T - _over_t0
	if to >= 0.0 and to < 0.8:
		x += 7.0 * a * sin(minf(to / 0.1, 1.0) * PI * 0.5) * exp(-to / 0.25)
	var tb: float = T - _block_t0
	if tb >= 0.0 and tb < 0.5:
		x -= 4.0 * a * exp(-tb / 0.12)
	return x


## The attacker has a blow due now (from 0.03 s ago to 0.05 s ahead).
static func _blow_due(ex) -> bool:
	for b in ex.beats:
		if b.op == "chainStrike" or (b.op == "strike" and String(b.args.a) == "A"):
			var dtc: float = b.t - ex.t
			if dtc >= -0.03 and dtc <= 0.05:
				return true
	return false


static func _has_evade(ex) -> bool:
	for b in ex.beats:
		if b.op == "dodge" or b.op == "slip":
			return true
	return false


## A blow that does not land passes close: the head is pulled back and the body flinches, small, from the attacker's side.
func _near_miss(S: SimState, f, amp: float) -> void:
	var a = S.dirS.ex.A
	var d := Vector2(SimWrap.sdx(a.x, f.x) * vface, f.y - a.y)
	d = d.normalized() if d.length() > 1.0 else Vector2(-1.0, 0.0)
	_rd.hit(d.x, d.y, 0.3 * amp, 0, 0.0, 0.0)
	_hit_free = minf(1.0, _hit_free + 0.2)
	_rd.out_w = 1.0
	debug["near_miss"] += 1


func _flight_layers(T: float, f) -> void:
	if f.state != "free" or _part != "":
		return
	var tb: float = T - _burst_t0
	if tb >= 0.0 and tb < 0.22:
		_mix_pose(AnimData.pose("move.burst"), smoothstep(0.0, 0.03, tb) * (1.0 - smoothstep(0.08, 0.22, tb)) * 0.9)
	var tk: float = T - _brake_t0
	if tk >= 0.0 and tk < 0.3:
		_mix_pose(AnimData.pose("move.brake"), smoothstep(0.0, 0.04, tk) * (1.0 - smoothstep(0.1, 0.3, tk)) * 0.85)
	if absf(_bank) > 0.004:
		var ix: Dictionary = AnimRig.index
		q[ix["pelvis"]] = q[ix["pelvis"]] * Quaternion(Vector3(1, 0, 0), _bank * 0.6)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(1, 0, 0), _bank * 0.4)
	_shock_layer(T)


func _shock_layer(T: float) -> void:
	var ts: float = T - _shock_t0
	if ts >= 0.0 and ts < 1.2 and _shock_amp > 0.0:
		var e: float = exp(-ts / 0.5) * _shock_amp * _rd_amp()
		var w: float = sin(ts * TAU * 3.2)
		hips.y += 1.6 * e * w
		var s2: int = AnimRig.index["spine_2"]
		q[s2] = q[s2] * Quaternion(Vector3(0, 0, 1), 0.06 * e * cos(ts * TAU * 2.6))


func _base_lagged() -> bool:
	if _base_r.size() != AnimRig.N:
		_base_r.resize(AnimRig.N)
		var lagk: float = float(AnimData.personality.get("guard", {}).get("lag", 2.0))
		for i in range(AnimRig.N):
			_base_r[i] = 1.0 / (1.0 + lagk * AnimData.bone_lag[i])
	return true


## The guard comes up or goes down with overlap: the arms are kicked toward the new guard and settle back on their springs.
func _stance_kick(old: int, new: int) -> void:
	var g: Dictionary = AnimData.personality.get("guard", {})
	var amp: float = _rd_amp()
	var dir: Array = []
	if new == 1:
		dir = g.get("up", [6.0, 4.0])
	elif old == 1:
		dir = g.get("down", [-5.0, -3.0])
	if dir.is_empty():
		return
	_rd.kick(2, float(dir[0]) * amp)
	_rd.kick(5, float(dir[0]) * amp)
	_rd.kick(4, float(dir[1]) * amp)
	_rd.kick(7, float(dir[1]) * amp)
	_rd.out_w = 1.0
	debug["guard_kicks"] += 1


## The weight shift, the knee bounce, the heel lift and the breath of a stance, scaled by the form's tier. calm is 1 for a fighter
## standing still and falls to 0 as he moves.
func _personality_layer(T: float, stance: int, tier: int, calm: float) -> void:
	var P: Dictionary = AnimData.personality
	var st: Dictionary = P.stances[STANCES[clampi(stance, 0, 3)]]
	var tr: Dictionary = P.tiers[clampi(tier, 0, 3)]
	var amp: float = _rd_amp() * calm
	var ix: Dictionary = AnimRig.index
	var ph: float = float(slot) * 1.9
	var shp: Dictionary = AnimData.shapes.get(_rd.shape_key, {}).get("idle", {})
	var sway: float = float(st.sway) * float(tr.sway) * amp * float(shp.get("sway", 1.0))
	var hzm: float = float(shp.get("hz", 1.0))
	var s1: float = sin(T * TAU * float(st.hz) * float(tr.hz) * hzm + ph)
	var pe: int = ix["pelvis"]
	q[pe] = q[pe] * Quaternion(Vector3(1, 0, 0), s1 * 0.02 * sway)
	hips.z += s1 * 0.6 * sway
	hips.x += sin(T * TAU * float(st.hz) * float(tr.hz) * hzm * 0.7 + ph + 1.0) * 0.3 * sway
	var bn: float = float(st.bounce) * float(tr.bounce) * amp * float(shp.get("bounce", 1.0))
	var b1: float = sin(T * TAU * float(st.bounce_hz) * float(tr.hz) * hzm + ph)
	hips.y += absf(b1) * 0.45 * bn   # a hop on the toes (never a dip: the legs are posed, so a dip would sink the feet)
	var heel: float = float(st.heel) * amp * float(shp.get("heel", 1.0))
	q[ix["thigh_l"]] = q[ix["thigh_l"]] * Quaternion(Vector3(0, 0, 1), heel * maxf(0.0, b1))
	q[ix["shin_l"]] = q[ix["shin_l"]] * Quaternion(Vector3(0, 0, 1), -heel * 1.2 * maxf(0.0, b1))
	q[ix["thigh_r"]] = q[ix["thigh_r"]] * Quaternion(Vector3(0, 0, 1), heel * maxf(0.0, -b1))
	q[ix["shin_r"]] = q[ix["shin_r"]] * Quaternion(Vector3(0, 0, 1), -heel * 1.2 * maxf(0.0, -b1))
	var br: float = sin(T * TAU * 0.45 * float(tr.breath_hz) + ph) * 0.012 * float(tr.breath_amp) * float(st.breath) * amp * float(shp.get("breath", 1.0))
	q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), br)
	q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 0, 1), -br * 0.5)
	# the shape's own idle: arms that drift out and in (a sweeping build), a head that glances and holds (a machine)
	var sweep: float = float(shp.get("sweep", 0.0)) * amp
	if sweep > 0.0:
		var sv: float = sin(T * TAU * 0.31 + ph) * sweep
		q[ix["upper_arm_r"]] = q[ix["upper_arm_r"]] * Quaternion(Vector3(1, 0, 0), sv)
		q[ix["upper_arm_l"]] = q[ix["upper_arm_l"]] * Quaternion(Vector3(1, 0, 0), -sv)
	var servo: float = float(shp.get("servo", 0.0)) * amp
	if servo > 0.0:
		var cyc: float = T / 2.6 + float(slot) * 0.37
		var tt: float = cyc - floorf(cyc)
		var gl: float = smoothstep(0.0, 0.04, tt) * (1.0 - smoothstep(0.5, 0.54, tt))
		var sgn: float = 1.0 if (_hash(int(floorf(cyc)), slot, 17) & 1) == 0 else -1.0
		q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 1, 0), servo * 0.1 * gl * sgn)
	debug["personality"] += 1


## A turn-around is a step: the weight dips, one foot swings through, the hips twist toward the new side and the shoulders against
## it, over 0.22 s from the moment the visual facing flipped (the view turns through front-on over the same time).
func _turn_layer(T: float) -> void:
	var tp: Dictionary = AnimData.personality.get("turn", {})
	var dur: float = float(tp.get("dur", 0.22))
	var tau: float = T - _turn_t0
	if tau < 0.0 or tau >= dur:
		return
	var u: float = tau / dur
	var s: float = sin(PI * u) * _rd_amp()
	var ix: Dictionary = AnimRig.index
	hips.y -= float(tp.get("dip", 1.4)) * s
	var sw: float = float(tp.get("swing", 0.5)) * s
	q[ix["thigh_r"]] = q[ix["thigh_r"]] * Quaternion(Vector3(0, 0, 1), sw)
	q[ix["shin_r"]] = q[ix["shin_r"]] * Quaternion(Vector3(0, 0, 1), -sw * 1.2)
	q[ix["thigh_l"]] = q[ix["thigh_l"]] * Quaternion(Vector3(0, 0, 1), -sw * 0.4)
	var tw: float = float(tp.get("twist", 0.35)) * s * (1.0 - u) * _turn_dir
	var pe: int = ix["pelvis"]
	q[pe] = q[pe] * Quaternion(Vector3(0, 1, 0), tw)
	q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 1, 0), -tw * 0.6)
	debug["turn_steps"] += 1


## What a change of speed along the facing is: a dash start (a hard push from nearly still) or a brake (a hard slowdown from a run).
## ax the acceleration along the facing (u/s^2), prev and now the speeds before and after (u/s).
static func _gait_event(ax: float, prev: float, now: float) -> String:
	if ax > 15000.0 and prev < 250.0 and now > prev:
		return "burst"
	if ax < -9000.0 and prev > 500.0 and now < prev:
		return "brake"
	return ""


## The winner's beat after the KO: 1 standing spent, 2 looking over the wreckage, 3 the end (held or a raised fist).
static func _win_phase(ko_t: float, _id: String) -> int:
	var w: Dictionary = AnimData.winner
	var t0: float = float(w.get("start", 0.8))
	if ko_t < t0 + float(w.get("stand", 1.0)):
		return 1
	if ko_t < t0 + float(w.get("stand", 1.0)) + float(w.get("survey", 2.5)):
		return 2
	return 3


## How the winner ends: "hold" the survey or "victory" (emote.victory), by his shape key (a data choice, not code).
func _win_end(roster_id: String) -> String:
	var ends: Dictionary = AnimData.winner.get("end", {})
	var key: String = String(AnimRagdoll.shape_of.get(roster_id, AnimRagdoll.shape_of.get("default", "")))
	return String(ends.get(key, ends.get("default", "hold")))


## The survey: the head and neck sweep slowly across the scene, the chest heaves; only the winner, only after the KO.
func _win_layer(S: SimState, f, T: float) -> void:
	if S.game.ko == null or is_same(S.game.ko, f) or f.state != "free":
		return
	var w: Dictionary = AnimData.winner
	var t0: float = float(w.get("start", 0.8)) + float(w.get("stand", 1.0))
	var tau: float = S.game.koT - t0
	var amp: float = _rd_amp()
	var ix: Dictionary = AnimRig.index
	var heave: float = sin(T * TAU * 0.9) * 0.05 * amp
	q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), heave)
	if tau >= 0.0 and tau < float(w.get("survey", 2.5)):
		var u: float = tau / float(w.get("survey", 2.5))
		var yaw: float = sin(u * TAU) * float(w.get("yaw", 0.8)) * smoothstep(0.0, 0.15, u) * amp
		q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 1, 0), yaw * 0.6)
		q[ix["neck"]] = q[ix["neck"]] * Quaternion(Vector3(0, 1, 0), yaw * 0.4)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 1, 0), yaw * 0.1)
		debug["survey"] += 1


func _wound_read(f) -> void:
	if f.wd == null:
		return
	var at: float = float(f.wd.stageAt[2])
	var tot: float = 0.0
	for r in range(4):
		tot += float(f.wear[r])
	_worn = clampf(tot / (4.0 * at) * 1.6, 0.0, 1.0)
	_brinkp = SimWounds.brinkProgress(f)
	_arm_broken = int(f.stage[2]) == 3
	_leg_broken = int(f.stage[3]) == 3


## Heavy breathing from the average wear (faster and deeper as it rises, the shoulders heaving, the head heavy) and a
## stagger from the brink (a slow irregular sway of the pelvis and a little give in the hips). Sim time only, so it replays.
func _wear_motion(f, T: float) -> void:
	if f.state == "launched" or f.state == "down" or f.state == "dropped":
		return
	var ix: Dictionary = AnimRig.index
	var br: float = sin(T * TAU * (0.8 + 1.4 * _worn) + slot * 1.9)
	var amp: float = 0.02 + 0.08 * _worn
	var s2: int = ix["spine_2"]
	var hd: int = ix["head"]
	q[s2] = q[s2] * Quaternion(Vector3(0, 0, 1), br * amp)
	q[hd] = q[hd] * Quaternion(Vector3(0, 0, 1), -br * amp * 0.5 + 0.05 * _worn)
	var heave: float = br * 0.06 * _worn
	var cr: int = ix["clavicle_r"]
	var cl: int = ix["clavicle_l"]
	q[cr] = q[cr] * Quaternion(Vector3(1, 0, 0), -heave)
	q[cl] = q[cl] * Quaternion(Vector3(1, 0, 0), heave)
	var ps: float = smoothstep(0.45, 1.0, _brinkp)
	if ps > 0.0:
		var sw: float = 0.6 * sin(T * 1.7 + slot * 2.3) + 0.4 * sin(T * 2.9 + slot)
		var sw2: float = sin(T * 2.3 + slot * 1.1 + 1.0)
		var pe: int = ix["pelvis"]
		q[pe] = q[pe] * Quaternion(Vector3(1, 0, 0), ps * 0.07 * sw) * Quaternion(Vector3(0, 0, 1), ps * 0.04 * sw2)
		hips.x += ps * 2.0 * sw


## A broken arm hangs (the arm's bones go to wound.arm_limp, the hand slack) and a broken leg is favoured (the leg's bones and
## part of the pelvis go to wound.leg_favour, with a dip on each step when moving). Light in the air, strong on the ground.
func _wound_limbs(f, T: float) -> void:
	var ix: Dictionary = AnimRig.index
	var calm: bool = f.state != "launched" and f.state != "down" and f.state != "dropped"
	if _arm_broken:
		var lw: float = 0.92 if calm else 0.5
		var sfx: String = "r" if _hang_right else "l"
		var lp: AnimPose = AnimData.pose("wound.arm_limp", not _hang_right)
		for nm in ["upper_arm_", "forearm_", "hand_", "fingers_"]:
			var i: int = ix[nm + sfx]
			q[i] = q[i].slerp(lp.q[i], lw)
		if _hang_right:
			curl.y = lerpf(curl.y, lp.curl.y, lw)
		else:
			curl.x = lerpf(curl.x, lp.curl.x, lw)
	if _leg_broken:
		var lf: float = (0.85 if _part == "" else 0.5) if calm else 0.3
		var sf2: String = "r" if _leg_right else "l"
		var fp: AnimPose = AnimData.pose("wound.leg_favour", not _leg_right)
		for nm2 in ["thigh_", "shin_", "foot_"]:
			var i2: int = ix[nm2 + sf2]
			q[i2] = q[i2].slerp(fp.q[i2], lf)
		var pe: int = ix["pelvis"]
		q[pe] = q[pe].slerp(fp.q[pe], lf * 0.5)
		hips.z += fp.hips.z * lf * 0.7
		if calm and absf(f.vx) > 60.0 and _part == "":
			hips.y -= 2.0 * lf * maxf(0.0, sin(T * TAU * 1.6 + slot))


## The elapsed ticks of the running transformation, or -1 when it is over. full and short play inside the sim's pause, whose
## own ticks are the clock (S.pause.left counts them down); live has none and runs on sim time.
func _transform_layer(S: SimState, T: float) -> void:
	var v: String = String(_form.version)
	var spec: Dictionary = AnimData.forms[v]
	var total: int = int(spec.gather) + int(spec["break"]) + int(spec.settle)
	var e: float
	if v == "live":
		e = (T - float(_form.t0)) * 60.0
	elif S.pause.left > 0 and S.pause.actor == slot:
		e = float(total - S.pause.left)
	else:
		e = -1.0 if T > float(_form.t0) + 0.05 else 0.0
	if e < 0.0 or e >= float(total):
		_form = {}
		return
	_form_pose(spec, e, v == "live")


## The pose layer at `e` ticks into the transformation (the part tools test without a match).
func _form_pose(spec: Dictionary, e: float, live: bool) -> void:
	var g: float = float(spec.gather)
	var b: float = float(spec["break"])
	var s_: float = float(spec.settle)
	var hold: float = float(spec.hold)
	var fp: Dictionary = AnimData.form_poses
	if e < g:
		# the gather: compress (a live one is only a flinch inward)
		var u: float = e / g
		_mix_pose(AnimData.pose(String(fp.gather)), smoothstep(0.0, 1.0, u) * (0.6 if live else 1.0))
	elif e < g + b:
		# the break: one snap, the new pose locks on in this frame and the silhouette changes here and nowhere else
		var pb: AnimPose = AnimData.pose(String(fp["break"]))
		_set_pose(pb)
		var ub: float = (e - g) / b
		# a few ticks of overshoot past the lock, then the break pose holds
		var ov: float = sin(PI * clampf(ub * 4.0, 0.0, 1.0)) * 0.1
		AnimPose.mix(q, AnimData.pose(String(fp.settle)).q, clampf(smoothstep(0.4, 1.0, ub) - ov, 0.0, 1.0))
	else:
		# the settle: the new pose holds for `hold` ticks, then eases back into the fight (live: the upper body holds while he
		# drifts back, so it fades from the first tick)
		var ps: AnimPose = AnimData.pose(String(fp.settle))
		_set_pose(ps)
		var es: float = e - g - b
		var w: float = 1.0 - smoothstep(hold, s_, es)
		# back toward what he is doing
		for i in range(AnimRig.N):
			q[i] = _base[i].slerp(ps.q[i], w)
		hips = _base_hips.lerp(ps.hips, w)
		curl = _base_curl.lerp(ps.curl, w)


func _beam_layer(S: SimState, f, T: float) -> void:
	cast = {}
	if f.beamCharge != null:
		var p: float = clampf((T - float(f.beamCharge)) / 0.8, 0.0, 1.0)
		var cid: String = _cast_id("charge")
		_mix_pose(AnimData.pose(cid), smoothstep(0.0, 0.35, p))
		_aim_arms(_aim_angle(S, f, null), smoothstep(0.2, 0.6, p))
		cast = {"state": "charge", "pose": cid, "w": smoothstep(0.0, 0.35, p), "bone": _cast_bone()}
		return
	for b in S.beams:
		if b.A == f and b.t < b.life:
			var bwt: float = 1.0 - smoothstep(0.55, 0.95, b.t)
			var fid: String = _cast_id("fire")
			_mix_pose(AnimData.pose(fid), bwt)
			_aim_arms(_aim_angle(S, f, b), bwt)
			cast = {"state": "fire", "pose": fid, "w": bwt, "bone": _cast_bone()}
			return


## The fighter's own casting pose for a beam (data/anim/pair_live.json `roles.<fighter>.beam`: `charge` and `fire` pose ids, `bone` the firing hand): the generic closed-fist pair (beam.charge, beam.fire) when
## he has none. A beam is cast with ONE hand, open or closed, drawn back to the shoulder and thrown out; there is never anything held in it, between the hands or at the hip (Legal's franchise rule).
func _cast_id(state: String) -> String:
	var id: String = String(_en_role("beam").get(state, ""))
	return id if id != "" and AnimData.pose_exists(id) else "beam." + state


func _cast_bone() -> String:
	return String(_en_role("beam").get("bone", "hand_r"))


## Where the beam leaves the body, for VFX (model space, root offset included; Vector3.ZERO when no beam is being cast): the heel of the palm for the Protagonist, the fist for the Anti-hero.
func cast_origin() -> Vector3:
	return socket(String(cast.bone)) if not cast.is_empty() else Vector3.ZERO


## The angle the signature is aimed at, in the body frame (0 forward, positive up): the beam's own direction once it is fired, the
## opponent's direction while it charges.
func _aim_angle(S: SimState, f, b) -> float:
	if b != null:
		return clampf(atan2(float(b.uy), float(b.ux) * vface), -1.2, 1.2)
	var opp = _opponent(S, f)
	if opp == null:
		return 0.0
	var dx: float = absf(SimWrap.sdx(f.x, opp.x))
	return clampf(atan2((opp.y + 55.0) - (f.y + 55.0), maxf(dx, 40.0)), -1.2, 1.2)


## Both arms (and a little of the chest) turn to the aim: a beam is thrown along its line, not along the pose's fixed forward.
func _aim_arms(alpha: float, w: float) -> void:
	if not RenderAnim.layer("aim") or w <= 0.001:
		return
	var a: float = alpha * w * _rd_amp()
	var ix: Dictionary = AnimRig.index
	# the turn is shortened until neither upper arm is past its limit (homework 4: a cast pose's arm turned to a steep aim was pulled 77 degrees by the last pass: an arm that snaps)
	var base_l: Quaternion = q[ix["upper_arm_l"]]
	var base_r: Quaternion = q[ix["upper_arm_r"]]
	var sc: float = 1.0
	for it in range(6):
		var qa := Quaternion(Vector3(0, 0, 1), a * sc)
		q[ix["upper_arm_l"]] = base_l * qa
		q[ix["upper_arm_r"]] = base_r * qa
		var el: Vector2 = AnimJoints.ball_excess(q, ix["upper_arm_l"], _rd.shape_key) if AnimJoints.ik_limits else Vector2.ZERO
		var er: Vector2 = AnimJoints.ball_excess(q, ix["upper_arm_r"], _rd.shape_key) if AnimJoints.ik_limits else Vector2.ZERO
		if el.x + el.y + er.x + er.y <= 0.02:
			break
		sc *= 0.7
	q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), a * 0.25)
	debug["aims"] += 1


## The head looks at the opponent: up or down by where his head is, smoothed, in an exchange or when he is near (overhaul unit D).
func _look_tick(S: SimState, f, dt: float) -> void:
	# once per sim tick (so a replay shows the same head); the target is re-aimed every third tick, the smoothing is linear
	if (S.tick + slot) % 3 == 0:
		var opp = _opponent(S, f)
		var t: float = 0.0
		var st: String = f.state
		if opp != null and st != "launched" and st != "down" and st != "dropped" and not (f.beamCharge != null):
			var dxo: float = SimWrap.sdx(f.x, opp.x) * vface
			if dxo > 10.0 and dxo < 1200.0:
				t = clampf(atan2(opp.y - f.y, maxf(dxo, 40.0)), -0.7, 0.7) * 0.8
		_look_target = t
	_look += (_look_target - _look) * clampf(dt * 8.0, 0.0, 1.0)


func _look_at(S: SimState, f, dt: float) -> void:
	if absf(_look) > 0.004:
		var a: float = _look * _rd_amp()
		var ix: Dictionary = AnimRig.index
		q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 0, 1), a * 0.55)
		q[ix["neck"]] = q[ix["neck"]] * Quaternion(Vector3(0, 0, 1), a * 0.3)
		q[ix["spine_2"]] = q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), a * 0.1)


## Hit reactions with variety (docs/animation/hit-reactions.md; data/anim/reactions.json). Each blow picks a variant by its weight (the force), the way it came (front or back, and whether it lifts him, drives him down or is level) and the
## body part it hit, and never the one the last blow picked; the pick is a hash of the tick, the slot and the hit's number, so a replay draws the same. `""` for no variant (a guarded blow, no data, the switch off): the generic flinch plays alone.
func _pick_reaction(region: String, front: bool, force: float, d: Vector2, h: int, kind: String) -> String:
	var R: Dictionary = AnimData.reactions
	if R.is_empty() or not RenderAnim.hit_variants or kind == "guard":
		return ""
	var wc: String = _rv_weight(force, R)
	var vert: String = "up" if d.y > 0.35 else ("down" if d.y < -0.35 else "level")
	var dir: String = "front" if front else "back"
	var cands: Array = []
	for v in R.variants:
		if not _rv_has(v.weight, wc) or not _rv_has(v.region, region) or not _rv_has(v.dir, dir) or not _rv_has(v.vert, vert):
			continue
		cands.append(String(v.id))
	if cands.is_empty():
		return ""
	if cands.size() > 1:
		cands.erase(_rv_last)   # never the one the last blow picked
	var id: String = String(cands[((h >> 12) & 0xFFFF) % cands.size()])
	_rv_last = id
	return id


static func _rv_weight(force: float, R: Dictionary) -> String:
	return "light" if force < float(R.get("light_max", 0.5)) else ("medium" if force < float(R.get("medium_max", 1.0)) else "heavy")


static func _rv_has(list: Array, v: String) -> bool:
	return list.has("any") or list.has(v)


func _rv_row(id: String) -> Dictionary:
	for v in AnimData.reactions.get("variants", []):
		if String(v.id) == id:
			return v
	return {}


## One variant's bone turns on the body, in its own envelope, scaled by the blow. Pitch (z) is in the away-from-the-blow frame (a blow from behind mirrors it); yaw (y) and roll (x) take a side from the blow's own draw.
func _apply_reaction_variant(row: Dictionary, r: Dictionary, tau: float) -> void:
	var R: Dictionary = AnimData.reactions
	var att: float = maxf(float(R.get("attack", 0.05)), 0.05)
	var dur: float = float(row.dur)
	if tau >= dur:
		return
	var e: float = smoothstep(0.0, att, tau) * (1.0 - smoothstep(att + float(row.get("hold", 0.1)), dur, tau))
	if e <= 0.001:
		return
	var sc: float = lerpf(0.6, 1.2, clampf(float(r.f) / 1.5, 0.0, 1.0)) * clampf(float(r.amp) + 0.3, 0.5, 1.2) * (1.0 + 0.3 * _worn) * (0.6 if RenderAnim.reduced_motion else 1.0)
	var k: float = e * sc
	var ps: float = 1.0 if bool(r.front) else -1.0
	var us: float = 1.0 if float(r.u) >= 0.0 else -1.0
	var ix: Dictionary = AnimRig.index
	var bones: Dictionary = row.get("bones", {})
	for bn in bones:
		var a: Array = bones[bn]
		q[ix[String(bn)]] = q[ix[String(bn)]] * (Quaternion(Vector3(1, 0, 0), float(a[0]) * k * us) * Quaternion(Vector3(0, 1, 0), float(a[1]) * k * us) * Quaternion(Vector3(0, 0, 1), float(a[2]) * k * ps))
	hips.y -= float(row.get("hips", 0.0)) * k
	var pid: String = String(row.get("pose", ""))
	if pid != "" and AnimData.pose_exists(pid):
		_mix_pose(AnimData.pose(pid), float(row.get("pose_w", 0.5)) * k)
	var rdx: float = float(r.get("dx", -1.0 if bool(r.front) else 1.0))
	_recoil_x += rdx * (float(row.get("dx", 1.0)) - 1.0) * float(r.f) * 3.0 * exp(-tau / 0.09)
	debug["reaction_variants"] = int(debug.get("reaction_variants", 0)) + 1


## The recovery after a variant: the body getting itself back (a nod, a shake of the head, a breath), by the blow's weight; ramps of 0.1 s or more.
func _apply_reaction_recovery(r: Dictionary, tau: float) -> void:
	var R: Dictionary = AnimData.reactions
	var wc: String = String(r.get("wc", "light"))
	for rec in R.get("recover", []):
		if not _rv_has(rec.weight, wc):
			continue
		var tt: float = tau - float(rec.start)
		var dur: float = float(rec.dur)
		if tt < 0.0 or tt >= dur:
			return
		var e: float = smoothstep(0.0, 0.12, tt) * (1.0 - smoothstep(maxf(dur - 0.15, 0.13), dur, tt))
		var k: float = e * (0.6 if RenderAnim.reduced_motion else 1.0) * clampf(float(r.amp) + 0.3, 0.5, 1.2)
		var us: float = 1.0 if float(r.u) >= 0.0 else -1.0
		var ix: Dictionary = AnimRig.index
		var bones: Dictionary = rec.get("bones", {})
		for bn in bones:
			var a: Array = bones[bn]
			q[ix[String(bn)]] = q[ix[String(bn)]] * (Quaternion(Vector3(1, 0, 0), float(a[0]) * k * us) * Quaternion(Vector3(0, 1, 0), float(a[1]) * k * us) * Quaternion(Vector3(0, 0, 1), float(a[2]) * k))
		hips.y -= float(rec.get("hips", 0.0)) * k
		var sh: float = float(rec.get("shake", 0.0))
		if sh > 0.0:
			q[ix["head"]] = q[ix["head"]] * Quaternion(Vector3(0, 1, 0), sh * sin(tt * TAU * 3.5) * k * us)
		debug["reaction_recoveries"] = int(debug.get("reaction_recoveries", 0)) + 1
		return


func _reaction_layer(T: float) -> void:
	var keep: Array = []
	for r in _reacts:
		var tau: float = T - float(r.t0)
		var amp: float = float(r.amp)
		var hg: float = float(r.get("hang", 0.0))   # a held hit's flinch hangs at its peak for the length of the attacker's pin, then lets go (the tenth round's "the flinch hangs for a beat")
		if tau < 0.0 or tau > float(r.get("life", 0.7)) + hg:
			if tau < 0.0:
				keep.append(r)
			continue
		keep.append(r)
		var rf: float = float(r.get("f", amp))
		var rdx: float = float(r.get("dx", -1.0 if bool(r.front) else 1.0))
		var rdy: float = float(r.get("dy", 0.0))
		var wk: float = 1.0 + 0.5 * _worn
		_recoil_x += rdx * rf * 7.0 * wk * smoothstep(0.0, 0.02, tau) * exp(-tau / 0.07)
		_recoil_y += rdy * rf * 4.0 * smoothstep(0.0, 0.02, tau) * exp(-tau / 0.08)
		if rf > 0.8:
			# a heavy blow staggers him: a quick sway after the push
			_recoil_x += rdx * rf * 2.5 * sin(tau * TAU * 3.0) * exp(-tau / 0.25)
		var bk: float = 1.0   # how much of the generic flinch a variant leaves
		var vid: String = String(r.get("var", ""))
		if vid != "":
			var vrow: Dictionary = _rv_row(vid)
			if not vrow.is_empty():
				bk = float(vrow.get("base", 1.0))
				_apply_reaction_variant(vrow, r, tau)
				if is_same(r, _reacts.back()):
					_apply_reaction_recovery(r, tau)
		var tw: float = tau
		if hg > 0.0 and tau >= 0.12:
			tw = 0.12 if tau < 0.12 + hg else tau - hg
		var w: float = amp * smoothstep(0.0, 0.05, tw) * (1.0 - smoothstep(0.12, 0.12 + 0.3 * amp, tw))
		if w <= 0.001:
			continue
		if String(r.get("kind", "")) == "guard":
			# a guarded blow: forearms up and rocked back, no wound wave
			_mix_pose(AnimData.pose("def.guard_hit"), w * 0.85)
			continue
		var pose_id: String = "react.flinch_f" if bool(r.front) else "react.flinch_b"
		if String(r.region) == "core":
			pose_id = "react.fold" if amp > 0.7 else pose_id
		_mix_pose(AnimData.pose(pose_id), w * (0.55 if RenderAnim.ragdoll_enabled else 0.7) * bk)
		var add_id: String = "react." + String(r.region)
		if AnimData.pose_exists(add_id):
			AnimPose.add(q, AnimData.pose(add_id).q, w * bk)
		# a damped wave up the spine
		var ix: Dictionary = AnimRig.index
		for pair in [["spine_1", 0.0], ["spine_2", 0.05], ["neck", 0.1], ["head", 0.15]]:
			var b2: int = ix[pair[0]]
			var ph: float = sin((tau - float(pair[1])) * 50.0) * exp(-(tau) * 9.0) * amp * 0.12
			q[b2] = q[b2] * Quaternion(Vector3(0, 0, 1), ph * (1.0 if bool(r.front) else -1.0))
	_reacts = keep


## Follow-through (docs/animation/secondary-motion.md; data/anim/secondary.json): the head, the upper back and the forearms lag the body and swing past on every change of its velocity and on every blow. One tick of the springs; the angles are applied in `_follow_apply`.
func _follow_tick(S: SimState, f, dt: float, frozen: bool) -> void:
	if not RenderAnim.tick_fast:
		_follow_tick_ref(S, f, dt, frozen)
		return
	var D: Dictionary = AnimData.secondary
	if D.is_empty() or not RenderAnim.secondary_motion:
		for i in range(_fw_x.size()):
			_fw_x[i] = 0.0
			_fw_v[i] = 0.0
		_fw_have = false
		return
	var vw := Vector2(f.vx * vface, f.vy)
	var dv := Vector2.ZERO
	if _fw_have and f.state != "intro":
		dv = vw - _fw_vw
	_fw_vw = vw
	_fw_have = true
	_fw_read(D)
	var kx: float = clampf(dv.x / _fw_ref0, -1.0, 1.0)
	var ky: float = clampf(dv.y / _fw_ref1, -1.0, 1.0)
	var sc: float = _fw_scale * (0.5 if RenderAnim.reduced_motion else 1.0)
	var dm: float = _fw_damp
	var h_all: float = dt * (0.1 if frozen else 1.0)
	var n: int = 2
	var h: float = h_all / float(n)
	for i in range(_fw_n):
		_fw_v[i] += (kx * _fw_gx[i] + ky * _fw_gy[i]) * sc
		for _s in range(n):
			var a: float = -_fw_stiff[i] * _fw_x[i] - _fw_dmp[i] * dm * _fw_v[i]
			_fw_v[i] += a * h
			_fw_x[i] += _fw_v[i] * h
		var cl: float = clampf(_fw_x[i], -_fw_max[i], _fw_max[i])
		if cl != _fw_x[i]:
			_fw_v[i] = 0.0   # at its bound the part stops there
		_fw_x[i] = cl


## The follow-through data as flat arrays for this fighter, read again only when the data or the fighter changes.
func _fw_read(D: Dictionary) -> void:
	if is_same(_fw_src, D) and _fw_fid == _fid:
		return
	_fw_src = D
	_fw_fid = _fid
	var ref: Array = D.dv_ref
	_fw_ref0 = float(ref[0])
	_fw_ref1 = float(ref[1])
	var FP: Dictionary = D.get("fighters", {}).get(_fid, {})
	_fw_scale = float(FP.get("scale", 1.0))
	_fw_damp = float(FP.get("damp", 1.0))
	_fw_force_ref = float(D.hit.force_ref)
	var parts: Dictionary = D.parts
	var names: Array = parts.keys()
	_fw_n = names.size()
	_fw_gx = []
	_fw_gy = []
	_fw_stiff = []
	_fw_dmp = []
	_fw_max = []
	_fw_hit = []
	_fw_bone = []
	_fw_arm = []
	for nm in names:
		var P: Dictionary = parts[nm]
		_fw_gx.append(float(P.gx))
		_fw_gy.append(float(P.gy))
		_fw_stiff.append(float(P.stiff))
		_fw_dmp.append(float(P.damp))
		_fw_max.append(float(P.max))
		_fw_hit.append(float(P.hit))
		_fw_bone.append(AnimRig.index[String(nm)])
		_fw_arm.append(String(nm).begins_with("forearm"))


## A blow sets the loose parts swinging, away from it: `front` is a blow from the front, the force the sim's.
func _follow_kick(front: bool, force: float) -> void:
	if not RenderAnim.tick_fast:
		_follow_kick_ref(front, force)
		return
	var D: Dictionary = AnimData.secondary
	if D.is_empty() or not RenderAnim.secondary_motion:
		return
	_fw_read(D)
	var sc: float = _fw_scale * (0.5 if RenderAnim.reduced_motion else 1.0) * clampf(force / _fw_force_ref, 0.2, 1.5)
	var pf: float = 1.0 if front else -1.0
	for i in range(_fw_n):
		_fw_v[i] += _fw_hit[i] * sc * pf


func _follow_apply() -> void:
	if not RenderAnim.tick_fast:
		_follow_apply_ref()
		return
	var D: Dictionary = AnimData.secondary
	if D.is_empty() or not RenderAnim.secondary_motion:
		return
	_fw_read(D)
	if _fw_n > _fw_x.size():
		return   # a part the arrays do not hold
	for i in range(_fw_n):
		if absf(_fw_x[i]) < 0.0005:
			continue
		var bi: int = _fw_bone[i]
		var ik_keep: float = 1.0 - clampf(_ci_w, 0.0, 1.0) if _fw_arm[i] else 1.0   # a striking arm is on its contact solve: it keeps its target
		q[bi] = q[bi] * Quaternion(Vector3(0, 0, 1), _fw_x[i] * ik_keep)
	debug["fw_head"] = _fw_x[0]
	debug["fw_arm"] = _fw_x[2]


## The sash and pack chains, one step per sim tick (never per frame, so a replay shows the same cloth): driven by the velocity along
## the way he faces, the acceleration, and a flutter at speed (overhaul unit D); frozen ticks run at a tenth.
const _SPRING_STIFF: Array = [40.0, 60.0, 90.0, 60.0, 90.0]
const _SPRING_GOAL: Array = [0.5, 1.0, 0.8, 1.0, 0.8]


func _spring_tick(S: SimState, f, dt: float, frozen: bool) -> void:
	if not RenderAnim.tick_fast:
		_spring_tick_ref(S, f, dt, frozen)
		return
	var m: float = vface
	var vw := Vector2(f.vx * m, f.vy) if not (f.state == "intro" and RenderAnim.intro_poses) else Vector2.ZERO   # no wind in the opening
	var aw := Vector2.ZERO
	if _sp_have:
		aw = (vw - _sp_vw) / maxf(dt, 0.0001)
	_sp_vw = vw
	_sp_have = true
	var h_all: float = dt * (0.1 if frozen else 1.0)
	var sp_n: float = clampf(vw.length() / 1600.0, 0.0, 1.0)
	var flutter: float = 0.12 * sp_n * (0.35 if RenderAnim.reduced_motion else 1.0) * (1.0 if RenderAnim.layer("cloth") else 0.0)
	var ov: float = 1.0 if RenderAnim.layer("cloth") else 0.0
	var target: float = -clampf(vw.x / 1600.0, -1.0, 1.0) * 0.9 - clampf(aw.x / 12000.0, -1.0, 1.0) * 0.5 * ov - clampf(-vw.y / 2400.0, 0.0, 1.0) * 0.6 * ov
	var n: int = 2
	var h: float = h_all / float(n)
	for kx in range(5):
		# each spring's goal is the same on both half steps: worked out once
		var goal: float = target * _SPRING_GOAL[kx] + flutter * sin(S.T * TAU * 4.5 + float(kx) * 1.3 + float(slot))
		var stiff: float = _SPRING_STIFF[kx]
		for _s in range(n):
			var a: float = -stiff * (_sx[kx] - goal) - 5.0 * _sv[kx]
			_sv[kx] += a * h
			_sx[kx] += _sv[kx] * h


## The cloth and follow-through ticks as they were before their tables were made (`--no-tick-fast`; the bench's before, and what `_test_tick_fast` compares them with).
func _spring_tick_ref(S: SimState, f, dt: float, frozen: bool) -> void:
	var m: float = vface
	var vw := Vector2(f.vx * m, f.vy) if not (f.state == "intro" and RenderAnim.intro_poses) else Vector2.ZERO   # no wind in the opening
	var aw := Vector2.ZERO
	if _sp_have:
		aw = (vw - _sp_vw) / maxf(dt, 0.0001)
	_sp_vw = vw
	_sp_have = true
	var h_all: float = dt * (0.1 if frozen else 1.0)
	var sp_n: float = clampf(vw.length() / 1600.0, 0.0, 1.0)
	var flutter: float = 0.12 * sp_n * (0.35 if RenderAnim.reduced_motion else 1.0) * (1.0 if RenderAnim.layer("cloth") else 0.0)
	var ov: float = 1.0 if RenderAnim.layer("cloth") else 0.0
	var target: float = -clampf(vw.x / 1600.0, -1.0, 1.0) * 0.9 - clampf(aw.x / 12000.0, -1.0, 1.0) * 0.5 * ov - clampf(-vw.y / 2400.0, 0.0, 1.0) * 0.6 * ov
	var n: int = 2
	var h: float = h_all / float(n)
	for _s in range(n):
		for kx in range(5):
			var stiff: float = [40.0, 60.0, 90.0, 60.0, 90.0][kx]
			var damp: float = 5.0
			var goal: float = target * [0.5, 1.0, 0.8, 1.0, 0.8][kx] + flutter * sin(S.T * TAU * 4.5 + float(kx) * 1.3 + float(slot))
			var a: float = -stiff * (_sx[kx] - goal) - damp * _sv[kx]
			_sv[kx] += a * h
			_sx[kx] += _sv[kx] * h


func _follow_tick_ref(S: SimState, f, dt: float, frozen: bool) -> void:
	var D: Dictionary = AnimData.secondary
	if D.is_empty() or not RenderAnim.secondary_motion:
		for i in range(_fw_x.size()):
			_fw_x[i] = 0.0
			_fw_v[i] = 0.0
		_fw_have = false
		return
	var vw := Vector2(f.vx * vface, f.vy)
	var dv := Vector2.ZERO
	if _fw_have and f.state != "intro":
		dv = vw - _fw_vw
	_fw_vw = vw
	_fw_have = true
	var ref: Array = D.dv_ref
	var kx: float = clampf(dv.x / float(ref[0]), -1.0, 1.0)
	var ky: float = clampf(dv.y / float(ref[1]), -1.0, 1.0)
	var FP: Dictionary = D.get("fighters", {}).get(_fid, {})
	var sc: float = float(FP.get("scale", 1.0)) * (0.5 if RenderAnim.reduced_motion else 1.0)
	var dm: float = float(FP.get("damp", 1.0))
	var h_all: float = dt * (0.1 if frozen else 1.0)
	var parts: Dictionary = D.parts
	var names: Array = parts.keys()
	var n: int = 2
	var h: float = h_all / float(n)
	for i in range(names.size()):
		var P: Dictionary = parts[names[i]]
		_fw_v[i] += (kx * float(P.gx) + ky * float(P.gy)) * sc
		for _s in range(n):
			var a: float = -float(P.stiff) * _fw_x[i] - float(P.damp) * dm * _fw_v[i]
			_fw_v[i] += a * h
			_fw_x[i] += _fw_v[i] * h
		var cl: float = clampf(_fw_x[i], -float(P.max), float(P.max))
		if cl != _fw_x[i]:
			_fw_v[i] = 0.0   # at its bound the part stops there
		_fw_x[i] = cl


func _follow_kick_ref(front: bool, force: float) -> void:
	var D: Dictionary = AnimData.secondary
	if D.is_empty() or not RenderAnim.secondary_motion:
		return
	var FP: Dictionary = D.get("fighters", {}).get(_fid, {})
	var sc: float = float(FP.get("scale", 1.0)) * (0.5 if RenderAnim.reduced_motion else 1.0) * clampf(force / float(D.hit.force_ref), 0.2, 1.5)
	var pf: float = 1.0 if front else -1.0
	var parts: Dictionary = D.parts
	var names: Array = parts.keys()
	for i in range(names.size()):
		_fw_v[i] += float(parts[names[i]].hit) * sc * pf


func _follow_apply_ref() -> void:
	var D: Dictionary = AnimData.secondary
	if D.is_empty() or not RenderAnim.secondary_motion:
		return
	var names: Array = D.parts.keys()
	if names.size() > _fw_x.size():
		return   # a part the arrays do not hold
	var ix: Dictionary = AnimRig.index
	for i in range(names.size()):
		if absf(_fw_x[i]) < 0.0005:
			continue
		var bi: int = ix[String(names[i])]
		var ik_keep: float = 1.0 - clampf(_ci_w, 0.0, 1.0) if String(names[i]).begins_with("forearm") else 1.0   # a striking arm is on its contact solve: it keeps its target
		q[bi] = q[bi] * Quaternion(Vector3(0, 0, 1), _fw_x[i] * ik_keep)
	debug["fw_head"] = _fw_x[0]
	debug["fw_arm"] = _fw_x[2]



func _springs(f) -> void:
	for kx in range(5):
		var bi: int = _spring_bones[kx]
		q[bi] = q[bi] * Quaternion(Vector3(0, 0, 1), clampf(_sx[kx], -0.9, 0.9))
