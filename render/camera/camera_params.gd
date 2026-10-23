class_name CamParams
## Every number of the dynamic split screen (docs/camera/split-screen.md), in one place. Screen fractions are of the
## screen height (vh) or width (vw) as named; times are seconds on the fixed 60 Hz step; distances are world units.
## Defaults marked "Orb decides" in the design doc are the ones a playtest will change.

# --- the trigger (section 2) ---
const R_SPLIT: float = 0.055           # split when a fighter's height falls under this fraction of vh (Orb decides; 0.035 until director step 1, 2026-10-22: no one view under 40 px at 720p)
const R_MERGE: float = 0.07            # merge when it stays above this (Orb decides; 0.047 until director step 1)
const R_BEAM_MIN: float = 0.032        # a beam struggle keeps the merged wide shot down to this
const MIN_PX: float = 18.0             # under 600 px of screen height the split line is at least this many pixels
const R_FLOOR: float = 0.032          # camera v2: no fighter is shown smaller than this anywhere (23 px at 720p)
const R_MAX: float = 0.14              # camera v2: the largest the one view zooms in (101 px at 720p), times the zoom setting
const R_CLOSE: float = 0.20            # a close-up shot (transformation, KO) may go this close, times the zoom setting
const FIT_MARGIN_X: float = 450.0      # camera v2: the one view's margin round two fighters, so melee is 11% of the height
const ZOOM_PREF_DEFAULT: float = 7.0   # the zoom setting, 0 to 10
const ZOOM_PREF_K: float = 0.08        # every size target is multiplied by exp(K (pref - 7))
const SHAKE_PREF_DEFAULT: float = 2.0  # the shake setting, 0 to 10; effective scale = pref / 10 * SHAKE_PREF_TOP
const SHAKE_PREF_TOP: float = 1.4      # 10 of 10 is the old prototype's strength (cap 4.2% of the height)
const SPLIT_DWELL: float = 0.25
const WIDE_HOLD: float = 0.4          # (1.0 until director step 1) extra dwell while the fighters are still moving apart: the shared zoom-out ("flying around the world") lasts this much longer
const MERGE_DWELL: float = 0.40
const MIN_SPLIT_AGE: float = 1.2       # before a dissolve merge
const MIN_MERGED_AGE: float = 0.8      # before splitting again
const MIN_OUT_OF_FRAME_AGE: float = 0.25   # ... or this, when a fighter is already out of the one view
const CLOSING_LOOKAHEAD: float = 0.4   # do not open if the fighters will be back over the split line by then
const SEP_RATE_TAU: float = 0.15        # the separation rate the one view zooms ahead for is smoothed over this
const SLAM_ZOOM_RATE: float = 3.0       # the slam's zoom rate cap, e-folds a second (it was unlimited: 17 and more)
const ZOOM_OUT_LOOKAHEAD: float = 0.3  # the one-view camera zooms for the separation it will have this soon, if growing
const FRAME_MARGIN: float = 0.46       # a fighter farther than this fraction of vw from the one-view centre opens the split at once
const BODY_H: float = 75.0             # a fighter's height in world units (FighterView.HEIGHT)
const REF_MARGIN_X: float = 700.0      # the reference camera's constants
const REF_MARGIN_Y: float = 500.0
const REF_TIER: float = 0.06
const ZONE_W: float = 0.0  # 0 = off. Was 0.51 (UI's clear-zone width) to keep fighters out from under UI's edge chips; Orb preferred the longer shared zoom-out, and the chips dodge the fighters instead             # UI's fighter-clear zone is 51% of the width (docs/ui/hud-spec.md 2.1): both fighters fit inside it
const ZOOM_MIN: float = 0.006
const RING_SHOW: float = 0.9           # on World's ring arena no pane shows more than this share of the ring (the ground would repeat on the screen): SplitRig.z_min
const ZOOM_MAX: float = 1.15          # the reference camera's cap, kept for the parity docs; v2 uses R_MAX

# --- divider geometry (section 3) ---
const PHI_MAX: float = 0.5235988       # 30 degrees
const TILT_K: float = 0.6
const TILT_FLOOR: float = 900.0        # units; the tilt uses max(|u|, this)
const TILT_TAU: float = 0.20
const TILT_RATE_MAX: float = 2.0943951 # 120 degrees a second
const TILT_DEAD: float = 0.0523599     # 3 degrees
const ANCHOR_LX: float = 0.28          # x offset of a fighter from the divider centre, times vw, along n.x
const ANCHOR_LY: float = 0.24          # y offset, times vh, along n.y
const ANCHOR_DROP: float = 0.12        # the chest sits this far below the divider centre, times vh
const GAP_FRAC: float = 0.005          # divider gap, fraction of vw (at least GAP_MIN_PX)
const GAP_MIN_PX: float = 3.0
const FEATHER_FRAC: float = 0.05       # dissolve feather at its widest, fraction of vw

# --- pane cameras (section 4) ---
const R_PANE: float = 0.085
const ALT_START: float = 3.0           # body heights above the ground where the altitude zoom-out begins
const ALT_SCALE: float = 40.0
const ALT_FLOOR: float = 0.69
const TAU_X: float = 0.10
const TAU_Y: float = 0.14
const TAU_Z: float = 0.35
const CHEST: float = 38.0              # the point followed, above the feet
const MERGED_TAU: float = 0.2557       # the reference camera's ease: 1 - 0.02^dt
const CAM_Y_MIN: float = -3200.0       # below the deepest sea floor (the reference camera's -180 predates the scaled world)
const CAM_Y_TOP: float = 200.0         # camera y is clamped to CEILING - this
const PLANE_Y: float = 0.7             # the fighter plane on screen in the reference camera, times vh

# --- opening, merging, the slam (sections 6 and 7) ---
const T_OPEN: float = 0.45
const RUSH_CUT_SCREENS: float = 1.2     # a rush this long in screens (at the rusher pane's zoom) cuts his pane ahead to where it ends
const RUSH_COMMIT_TICKS: int = 6        # the cut ahead is made this many ticks after the rush begins, if it is still on (0 = at once)
const INCOMING_MIN_CLOSING: float = 3000.0   # an incoming read shows when the other fighter closes this fast (units a second) off the pane
const CHASE_LEAD_X: float = 0.12        # lead room for a chased launch: the focus ahead of him by at most this share of the pane width
const CHASE_LEAD_T: float = 0.25        # seconds of his velocity (the lead before the cap)
const CHASE_LEAD_TAU: float = 0.3       # the lead is smoothed with this time constant
const RUSH_LEAD_MAX: float = 0.12        # the follow point's velocity lead in a rush is at most this share of the pane width
const ZIP_FRAME_TAU: float = 0.20        # the zip frame (the box the camera holds) is followed with this time constant
const STRUGGLE_FOCUS: float = 0.5     # the beam struggle (docs/camera/beam-struggle.md): the shared view's focus moves this share of the way from the pair's middle to the meeting point ...
# The brink (docs/camera/feel.md step 5): when the meeting point has been pushed most of the way to one fighter, the shared view
# frames the meeting point and the fighter about to lose, filling STRUGGLE_BRINK_FILL of the width; the winner may leave the edge
# (his beam still comes in from it). Weighted in between lean STRUGGLE_BRINK_0 and STRUGGLE_BRINK_1 (lean: 0 at the middle, 1 at a fighter).
const STRUGGLE_BRINK_0: float = 0.2
const STRUGGLE_BRINK_1: float = 0.6
const STRUGGLE_BRINK_FILL: float = 0.6
const STRUGGLE_BRINK_HOLD: float = 0.3   # the winner may stay off the edge this long after the brink, while the view widens back (no split for it)
const STRUGGLE_FADE: float = 0.4     # the framing comes in and goes out over this many seconds
const STRUGGLE_MID_TAU: float = 0.3   # ... which is eased (the point jumps 10 to 15% of the line at a surge)
const STRUGGLE_PUSH: float = 0.10     # the view tightens by up to this much as the point nears a fighter (the decision is near) ...
const STRUGGLE_TIME_PUSH: float = 0.04   # ... and by this much more over the last 40% of the struggle's time
const STRUGGLE_SURGE_PUNCH: float = 0.02   # a surge is a 2% punch of the zoom (6 ticks), a sharp one 3.5%: the beat, seen
const STRUGGLE_SHARP_PUNCH: float = 0.035
const STRUGGLE_DETONATE_WIDE: float = 0.7   # a detonation pulls the shared view out for this long (the crater is the picture)
const MERGE_LOOKAHEAD: float = 1.0     # the merge condition looks this many seconds ahead at a pair that is moving apart
const GOV_ARM_TAIL: float = 0.1         # the arming outlasts the charge's move by this many seconds
const GOV_ARM_SPEED: float = 6000.0     # a charge's cue arms the scroll governor as if the view were already moving this fast
const SWEEP_FEATHER_FRAC: float = 0.30   # the feathered sweep (a switch): the blend's half-width at its widest, a fraction of the width
# The re-frame at an impact (a body's velocity steps from rest: a beam's launch out of hit-stop, ground that falls away):
const LEAD_SLEW: float = 2700.0          # the lead velocity's change a tick, units a second (45 units a tick each tick): a step is eased over about three ticks
const ONSET_MAX: float = 12000.0         # a velocity step over this (units a second) is a fling: not eased, chased as before
# The travel budget (split_rig `_travel_budget`): how much of the screen's width a pane's picture may change by in a tick from
# camera motion of any kind, and what the camera does when a fight is faster than that.
const TRAVEL_MAX: float = 0.045          # the pane's displayed camera: its step at its zoom, in widths, plus half its zoom's change, a tick
const TRAVEL_MAX_REDUCED: float = 0.03   # under reduced flashing or reduced motion
const TRAVEL_CATCH: float = 0.01         # catching up with a target goes no faster than this (of the width a tick) more than the target itself moves
const TRAVEL_PAD: float = 0.04           # a subject is leaving his pane when the limited camera puts him within this (of the width) of its edge
const TRAVEL_WAIT: float = 0.6           # a subject outside his pane's picture (the budget held its camera back) is waited for this long before the pane cuts to him
const TRAVEL_COOL: float = 1.0           # a pane cuts for the budget at most once in this many seconds (a cut and its dip are a flash)
const TRAVEL_COOL_MORPH: float = 0.1     # (a pane that is opening or closing cuts at most once in this many: its target settles, and the fighter it opens for must be seen)
const GOV_HEADROOM: float = 0.9          # the zoom governor aims at this share of the budget (SCROLL_MAX is the budget's number), so the displayed camera can catch up
# The dolly (docs/camera/city-in-depth.md section 6): the camera's focus plane follows the pair's depth.
const DOLLY_TAU: float = 0.5             # the focus depth is eased with this time constant (s)
const DOLLY_CAP_BRAWL: float = 225.0     # and moves at most this fast in a brawl (units a second: 3 bh; the sim's own drift is 1.2 bh)
const DOLLY_CAP_FLIGHT: float = 900.0    # ... and this fast in a flight (12 bh a second)
const DOLLY_FEED: float = 0.5            # the focus takes this share of the target's own depth step outright each tick (the rest is eased)
const DOLLY_LAG: float = 300.0           # the focus is never farther than this (units, 4 bh) from the depth it is following: a fighter that far off is 0.8 to 1.35 of his size
const DOLLY_NEAR_RATE: float = 0.6       # the lens closes on a building face straight ahead no faster than this share of its distance a second ...
const DOLLY_NEAR_MIN: float = 60.0       # ... and never slower than this (units a second): the dolly is slowed, not stopped
const DOLLY_NEAR_LOOK: float = 1500.0    # a face farther than this from the lens is not looked at
const DOLLY_NEAR_CENTRE: float = 0.6     # "straight ahead": the face's span meets the central share of the view's width
const DOLLY_LAG_NEAR: float = 600.0      # while the cap binds the focus may trail the depth it follows by this much (units; 0.66 of his size at the close brawl)
const DOLLY_Z_FRONT: float = 187.5       # the band's limits for the focus depth (units; +2.5 bh and -29.5 bh)
const DOLLY_Z_BACK: float = -2212.5
# The patch and the open floors (docs/camera/city-in-depth.md sections 2 and 3): what the foreground opens, and how fast.
const CLEAR_PAD: float = 0.5             # the action's boxes are grown by this many body heights on screen
const CLEAR_P0: float = 0.18             # below this share of the pane the patch only; ...
const CLEAR_P1: float = 0.40             # ... above it everything stands as a stub; between, the building shrinks by smoothstep
const CLEAR_GROW: float = 0.045          # an edge grows at most this much of the pane's width a tick (the travel budget's number)
const CLEAR_SHRINK: float = 0.02         # and closes at most this much, and only after the hold
const CLEAR_HOLD: float = 0.75           # seconds with no demand for the space before anything narrows or stands again
const CLEAR_SINK: float = 0.5            # sigma 0 to 1 in at least this many seconds ...
const CLEAR_STAND: float = 0.75          # ... and 1 to 0 in at least this many
const CLEAR_LEAD_TICKS: float = 8.0      # the rectangle also reaches this many ticks of the chest's own screen step ahead of it
const CLEAR_LEAD: float = 0.5            # seconds of the action's own motion the rectangle leads by ...
const CLEAR_LEAD_MAX: float = 0.2        # ... capped at this share of the pane's width
const CLEAR_ROOM: float = 0.5            # a split pane's strip toward the rival runs at most this share of the pane's width
const GOV_TAU: float = 0.2             # a zoom-out the scroll governor asks for is taken with this time constant (and at the transition's rate cap)
const LAUNCH_FLOOR: float = 0.05         # a launched body's pane is governed like any pursuit, but he is never smaller than this share of the height for it
const SETDOWN_STEP: float = 120.0        # a body that is not launched and changes height by this much (units) in one tick was set down by the sim ...
const SETDOWN_HOLD: int = 30             # ... and the focus holds its height this many ticks before it follows him
const SETDOWN_ROOM: float = 0.22        # but he stays within this share of the height from the focus
const ONSET_MAX_Y: float = 40000.0       # ... in y a step this big is a body set down on lower ground, not a flight (the fastest is about 8,000): eased as any re-frame
const CAP_TICKS: int = 4                 # a step arms the limiter for this many ticks (it stays on while it is binding) ...
const CAP_COOL: int = 30                 # ... and a step may not arm it again for this many ticks (one onset, not a whole ramp)
const SCROLL_CAP: float = 0.045          # the limiter: a pane's focus moves at most this much of the width a tick (SCROLL_MAX_REDUCED under reduced motion) ...
const CAP_MAX: int = 20                  # ... for at most this many ticks in one onset ...
const CAP_LAG: float = 0.14              # ... and gives way when the fighter is this far (of the width) from the focus: from there he is followed at his speed
const SCROLL_MAX: float = 0.045          # the scroll governor: the scenery crosses the screen no faster than this much of its width a tick ...
const SCROLL_MAX_REDUCED: float = 0.045   # ... and this much under reduced motion or reduced flashing (0.03 for Tools' flash analyser until director step 1, 2026-10-22: the flash work is paused and the shipped mode zoomed fighters out to 25 px)
const BRAWL_FOCUS_TAU: float = 0.05       # the one view follows a brawl's centre eased with this time constant (its drift as the lead)
const BRAWL_RELEASE: float = 0.5         # and eases back to the pair's middle over this long when the brawl ends
const ZIP_RELEASE: float = 0.6          # after a hold the frame eases back to the live pair for this long
const ZIP_HOLD_MARGIN: float = 0.6        # a zip's hold runs this long past the cue's whole-zip ticks, until zip_end decides
const ZIP_HOLD_MAX: float = 2.2           # and never longer than this from the cue
const LUNGE_HOLD_AFTER: float = 0.4       # a lunge's hold runs this long after he is back (wind-up + out + back + this)
const LUNGE_HOLD_MAX: float = 1.6         # and never longer than this: a lunge that does not return is not a lunge to the camera
const LUNGE_FOCUS_LEAD: float = 0.1       # the one view's focus may lean toward the lunger by this share of the width
const KNOCK_APART_RATE: float = 1500.0  # a chased fighter flying apart this fast (units a second, smoothed) opens the split at once
const T_OPEN_URGENT: float = 0.20       # the split opens this fast when a fighter has left the shared view or one was knocked away
const T_CLOSE: float = 0.55
const SLAM_WINDOW: float = 0.8         # a rush this close to its end starts the lean
const SLAM_TIME: float = 0.14
const SLAM_TIME_REDUCED: float = 0.04   # reduced motion: the slam is a near-cut
const SLAM_LEAN: float = 0.0           # how far the panes lean together before the slam (0: they hold until 0.14 s from contact)
const SLAM_STIFF_RAMP: float = 0.06    # the slam's stiff filters come in over this, seconds
const SLAM_TAU: float = 0.03           # stiff pane filters during the slam
const SLAM_FLASH: float = 0.08
const SLAM_CANCEL: float = 0.25

# --- orientation and the swap (section 5) ---
const HYST_M: float = 0.02             # antipode margin, fraction of W
const HYST_M0: float = 225.0           # pass-through dead band (3 body heights)
const FLIP_DWELL: float = 1.0
const T_SWING: float = 0.60
const T_SWING_REDUCED: float = 0.15
const INSTANT_SWAP_E: float = 0.9      # a pane expanded this far hides the swap: flip at once

# --- launch follow (section 8) ---
const LAUNCH_MIN_SPEED: float = 4000.0
const R_LAUNCH: float = 0.11
const LAUNCH_TAU: float = 0.02
const LAUNCH_LEAD: float = 0.05        # s of velocity added to the follow point
const LAUNCH_TRAIL: float = 0.35       # the fighter sits this far from the trailing edge, times vw
const T_ENGAGE: float = 0.32
const LAND_HOLD: float = 0.35
const T_SETTLE: float = 0.60
const T_REVEAL: float = 0.35           # the far pane wipes back in
const MAX_FOLLOW: float = 6.0
const LAND_PUSH: float = 0.08

# --- cinematics (section 9) ---
const R_CINE: float = 0.14             # respected transformation
const CINE_SLIVER: float = 0.14        # the other fighter's share of the screen (Orb decides)
const R_KO: float = 0.16
const KO_DOLLY: float = 1.5
const TIER_PUSH: float = 0.12
const TIER_PUSH_IN: float = 0.25
const TIER_PUSH_HOLD: float = 0.50
const TIER_PUSH_OUT: float = 0.60
const FOLD_FIT: float = 2.4            # the fold's diameter fits this many times across the shorter screen side

# --- comfort limits (section 12); the tests enforce them ---
const ZOOM_RATE: float = 1.2           # e-folds a second, ordinary
const ZOOM_RATE_TRANS: float = 2.4     # in a transition
const ANCHOR_STEP: float = 0.02        # screen motion of a fighter relative to its anchor per tick, times vw
const ANCHOR_STEP_TRANS: float = 0.05
const ANCHOR_REPORT_STEP: float = 0.15   # the frame's reported anchor moves at most this share of the width in a tick (a launch that begins in the last tick of a closing hands the nominal anchor from its rest value to the fighter's place at once; the picture is continuous, the report was not)
const DIVIDER_STEP: float = 0.06       # divider centre motion per tick, times vw, outside the slam
const SHAKE_CAP: float = 0.03          # times vh
const SHAKE_HIT_STEP: float = 1.0

# --- the lag bound (camera v2 section 2) ---
const LAG_SOFT: float = 0.06           # a tracked fighter this far from his anchor (screen widths): ordinary filter
const LAG_HARD: float = 0.20           # ... this far: the focus is held to it (a whip)
const LAG_GAIN: float = 6.0            # the filters speed up by 1 + LAG_GAIN * (e - SOFT) / (HARD - SOFT)
const LAG_CUT: float = 1.5             # farther than this in one tick: a cut (a counted safety net)
const CUT_FADE: float = 0.08           # a safety cut's dip fades in over this, seconds
# The dip's depth is chosen so that no pixel can change by 10% of the maximum relative luminance (WCAG 2.2 criterion 2.3.1's
# threshold for a flash): a dip of d darkens a pixel of luminance L by d x L, at most d. It was 0.30, which on a bright sky
# is 0.21; it is under 0.10 now whatever is on the screen, so even unasked it cannot be a general flash. The register is
# asked at its leading edge as well (split_view.gd), and a refused dip is a cut with no dip.
const CUT_DIM: float = 0.09
const REDUCED_CUT_DIM: float = 0.06    # reduced motion: shallower still, and a slow one-way ease back
const REDUCED_CUT_FADE: float = 0.60
const CUT_DISSOLVE_S: float = 0.40     # a cut under Reduce flashing or reduced motion cross-dissolves over this (the compositor; Legal asks at least 0.3)
const PANEL_OPEN_REDUCED: float = 0.08  # under Reduce flashing a strip wipes open over this, and shut over PANEL_CLOSE_REDUCED
const PANEL_CLOSE_REDUCED: float = 0.12   # back to the normal wipe on Orb's word 2026-10-18 (the 0.3 s wipes read as fading)

# --- fighters in depth (docs/camera/depth-and-chains.md) ---
const K_FACTOR: float = 1.8660254      # 1 / (2 tan 15 degrees): the camera's distance to the fighter plane is K_FACTOR * vh / zoom
const TAN_HALF_FOV: float = 0.2679491924   # tan(15 degrees): the lens is 30 degrees
const DEPTH_S_MIN: float = 0.2         # perspective scale floor, so the anchor compensation cannot blow up
const LEAD_FRAC: float = 0.35          # how far toward the aimed building the focus leads
const LEAD_MAX_X: float = 0.18         # ... at most this fraction of the width, on screen
const LEAD_MAX_Y: float = 0.12         # ... and of the height
# The blow push (docs/camera/feel.md): every landed blow above a light pushes the picture in a little, by its weight, and lets go:
# up over BLOW_UP, held for the hit-stop, back over BLOW_DOWN. After the filters, so it is crisp; a bigger one replaces a smaller one.
const BLOW_PUSH: Dictionary = {"medium": 0.008, "heavy": 0.016, "guard_break": 0.016, "perfect_block": 0.010, "launch": 0.020}
const BLOW_UP: float = 0.12           # the push's rise: a fast start and a soft landing, 7 frames (Research's impact push, 5 to 10; 3 until 2026-10-23)
# The one view leads a pair moving together (docs/camera/feel.md step 4): the focus sits ahead of them by their speed times
# MERGED_LEAD_T, at most MERGED_LEAD_X of the width, faded in between MERGED_LEAD_V0 and MERGED_LEAD_V1 (units a second), eased
# with MERGED_LEAD_TAU, and never so far that a fighter leaves the middle MERGED_LEAD_KEEP of the width.
const MERGED_LEAD_T: float = 0.3
# Anticipation (docs/camera/director.md section 4): the choreographer schedules each blow a few ticks ahead (the exchange's beats); before a
# heavy blow or a launch the one view leans toward the contact and tightens a little, so the hit lands where the eye already is.
const ANT_LEAD_TICKS: float = 18.0     # how far ahead a scheduled contact is read
const ANT_SHIFT: float = 0.25          # the focus moves this share of the way to the contact point
const ANT_PUSH: float = 0.20           # ... and the view tightens by this much
const ANT_TAU_IN: float = 0.18
const WHIP_TICKS: int = 12            # a catch-up the follow cannot make is a crisp whip of this many frames, a hard ease at both ends, no blur
const WHIP_MAX: float = 3.0            # ... up to this many widths; beyond it a move would only smear, and it cuts (a change of space)
const ANT_TAU_OUT: float = 0.25
const ANT_W: Dictionary = {"launch": 1.0, "ender": 1.0, "heavy": 0.7, "medium": 0.0, "light": 0.0}
# the push's share by kind: a launch is followed by a chase or a split, so it tightens less (the opening starts from a camera near the pane's)
const ANT_PUSH_W: Dictionary = {"launch": 0.3, "ender": 0.3, "heavy": 1.0}
const MERGED_LEAD_X: float = 0.12
const MERGED_LEAD_V0: float = 300.0
const MERGED_LEAD_V1: float = 1200.0
const MERGED_LEAD_TAU: float = 0.35
const MERGED_LEAD_KEEP: float = 0.80
const BLOW_DOWN: float = 0.25
# The launch curve's arrival (docs/camera/director.md step 4b, Simulation's `flight` cue): from `arrive` (the contact about 10 ticks
# ahead) the chased body's pane widens by ARR_WIDE to take in where he lands, holds it ARR_HOLD past the contact, and lets go over ARR_OUT.
const ARR_WIDE: float = 0.15
const ARR_IN: float = 0.15
const ARR_HOLD: float = 0.45
const ARR_OUT: float = 0.35
# The ring's turn (World's window 3, `arena_turn`; Rendering rebuilds every pane's ground on that tick): a motivated hard cut on
# the tick to a low wide on the pair, the far land (the only land the turn changes: past 12,000 units) against the sky, every pane
# at TURN_WIDE of its size and TURN_PITCH degrees (a low angle, limited so the camera stays above the ground; a high angle looked
# into the slope behind the pair), held TURN_HOLD, then eased back over TURN_OUT. The cut in is a scene change (the world beyond
# the pair is a new one): the ridges change on the cut, never under a still camera (148,000 pixels at fight framing).
const TURN_WIDE: float = 0.6
const TURN_PITCH: float = -6.0
const TURN_HOLD: float = 1.2
const TURN_OUT: float = 0.5            # ... then the wide eases back to the fight's framing and level over this (the cut in is the scene change; the way back is a move)
# Pacing (docs/camera/director.md section 6): relax, build, peak and fade, from the blows landed in the last
# PACE_WINDOW, the feed's story weight and the decisive events (a launch, a transformation, a finisher, `decisive`). It weights the
# blow push by state (the anticipation's push stays as it is: weighting it moved the view under a strip), and sizes the one view by state (PACE_ZOOM: the reference size in relax and build,
# a little tighter at a peak and a little wider in the fade after it), eased over PACE_ZOOM_TAU in the plain one view only and
# held while the layout changes.
const PACE_WINDOW: float = 2.0
const PACE_BUILD_HITS: int = 3           # landed blows in the window for build
const PACE_STORY: int = 4                # a running plan of this story weight or more is a peak (a finisher is 5)
const PACE_BIG_HOLD: float = 1.0         # a decisive event keeps peak this long
const PACE_FADE: float = 1.5             # fade's length after a peak (unless the blows keep coming: build)
const PACE_MIN: float = 0.5              # a state holds at least this long
const PACE_BLOW: Dictionary = {"relax": 0.6, "build": 1.0, "peak": 1.3, "fade": 0.8}
const PACE_ZOOM: Dictionary = {"relax": 1.0, "build": 1.0, "peak": 1.05, "fade": 0.93}
const PACE_ZOOM_TAU: float = 0.6
# Angles by context (docs/camera/director.md section 6): a decisive moment at a peak (ANGLE_KINDS: a knockback, a guard break, an
# interrupt, a barrage, a beam or a clash) in the plain one view tilts to an angle chosen by the ground under the pair, a crane move
# eased in over ANGLE_IN, held ANGLE_HOLD while the camera keeps following, eased back over ANGLE_OUT; no cut (Orb, 2026-10-22). The variety ledger spaces them: one in ANGLE_GAP at most.
const ANGLE_LOW: float = -7.0          # city, towns, mountains: the towers and the ridge loom (limited so the camera stays above the ground)
const ANGLE_HIGH: float = 5.5          # ocean and forest, and only where the ground has something to show (ANGLE_SHOW_*): 5.5 degrees down keeps about
                                       # a third of the frame for the horizon and the sky (10 took it all, the EP's look gate, 2026-10-22)
const ANGLE_SHOW_R: float = 1000.0     # ... within this of the pair: a crater, a building, or ANGLE_SHOW_COLS columns scorched or cracked
const ANGLE_SHOW_COLS: int = 8
const ANGLE_HOLD: float = 1.0
const ANGLE_IN: float = 0.45           # the angle shot is a crane tilt, eased in over this ... (Orb, 2026-10-22: no instant camera move without a reason)
const ANGLE_OUT: float = 0.6           # ... and back to level over this; no cut either way
const PITCH_CUT_DEG: float = 1.0       # a change of angle bigger than this in a tick is a cut (an authored jump); an eased tilt is a camera move
const ANGLE_GAP: float = 20.0
const ANGLE_KINDS: Array = ["knockback", "guard_break", "interrupt", "barrage", "beam", "beam_clash", "clash"]
const ANGLE_BIOME: Dictionary = {"city": "low", "village": "low", "mountains": "low", "ocean": "high", "forest": "high"}   # the rest alternate
const HIT_PUSH: float = 0.06           # zoom push on the first building hit; later links push less
const HIT_PUSH_LATER: float = 0.03
const LOW_AIR_DEAD: float = 112.0       # a launched body this near the ground (1.5 body heights) is not followed up; 0 turns it off
const LAST_STAND_DUR: float = 0.7        # the last stand's cut-in on the fighter at the brink (one view), in seconds
const BOUNCE_PUSH: float = 0.03        # a ground bounce: a small impact push on the pane that has him ...
const BOUNCE_HOLD: float = 0.05        # ... held this long
const HIT_UP: float = 0.15
const HIT_HOLD_FIRST: float = 0.35     # the sim's hold on a first hit (buildings-in-depth.md 4b)
const HIT_HOLD_LATER: float = 0.12
const HIT_DOWN: float = 0.40

# --- the hybrid launch rule and the cut (camera-v2.md sections 3 and 12) ---
const HOLD_MAX: float = 1.5            # the camera stays on the attacker at most this long before the impact cut
const CUT_SHOT: float = 0.5            # the impact cut lasts this long
const CUT_PUSH: float = 0.10           # ... zoomed in this much past the chase size
const CUTAWAY_MIN_PX: float = 70.0     # the occlusion hole's radius is at least this, and 1.6 x the fighter's height
const CUTAWAY_K: float = 1.6

# --- the set-piece shots (camera-v2.md section 4) ---
const R_FIGHT: float = 0.11            # the fight size, for the start of a dolly
const R_FINISH: float = 0.16           # a finisher dollies in to this
const TRANSFORM_R0: float = 0.14       # a transformation: the face, then the body, then the reveal
const TRANSFORM_R1: float = 0.11
const TRANSFORM_R2: float = 0.07
# --- the opening: the crater-landing entrance and the staredown (rule-of-cool row 7, docs/architecture/intro-phase.md) ---
const INTRO_R_FALL: float = 0.10       # the descent: the faller at this fraction of the screen height, the camera falling with him
const INTRO_FALL_ANCHOR_Y: float = 0.38  # ... high in the frame, so the ground that comes up is below him
const INTRO_FALL_DROP: float = 180.0    # the faller starts this far above his anchor and drops to it as he lands (units)
const INTRO_R_LAND_MIN: float = 0.07   # the landing: low and wide, the crater's diameter filling INTRO_LAND_FIT of the width,
const INTRO_R_LAND_MAX: float = 0.12   # ... his height between these
const INTRO_LAND_FIT: float = 0.55
const INTRO_LAND_PITCH: float = -6.0   # the low angle (limited by the ground rule, as the transformation's break)
const INTRO_LAND_ANCHOR_Y: float = 0.74
const INTRO_LAND_PUSH: float = 0.06     # the touchdown's impact push, 0.1 s
const INTRO_SHAKE: float = 10.0         # the touchdown's shake, px before the cap and the player's scale
# --- the building stage and the launch that is not followed (docs/camera/buildings-in-frame.md sections 3 and 7) ---
const STAGE_ZOOM_MIN: float = 0.5      # a stage is never wider than this zoom at 720p (the body at 37 px, 5.2% of the height)
const STAGE_MARGIN: float = 0.15       # of the width, each side of the two links a stage frames
const STAGE_BLD_HALF: float = 300.0    # half a building's width (units): the edge a stage must keep in frame
const STAGE_TAU: float = 0.25          # the focus eases to a stage with this time constant ...
const STAGE_STEP: float = 0.03         # ... and moves at most this much of the width a tick
const STAGE_LAG_HARD: float = 0.40     # in a stage the lag bound's whip is at this share of the width from the focus
const STAGE_EXIT: float = 0.46         # a body this far (of the width) from the focus has left the stage: the ordinary follow takes over
const STAGE_HANDOVER: int = 20        # ticks the lag bound takes to close from a stage's to the ordinary one after it ends (no yank)
const STAGE_MAX: int = 300             # ticks: a stage ends by itself after 5 s
const STAGE_LODGE: int = 54            # ticks a stage outlives the launch (the lodge's hold is 30 to 54)
const LH_SPEED: float = 0.03           # of the width a tick at the launch floor's zoom: a launch faster than this is not followed ...
const LH_ENGAGE_W: float = 0.6         # the rule engages once a fast body has covered this much of the width (at the pane's zoom): a spike that dies is followed
const LH_BIG: float = 0.15            # ... or at once when his step at the pane's own zoom is over this much of the width a tick (a fling: 32,000 units a second is 0.3; 7,000 at the close zoom is 0.09)
const LH_ENGAGE_W_REDUCED: float = 0.25   # under reduced flashing the rule engages sooner: after this much of the width covered ...
const LH_BIG_REDUCED: float = 0.05     # ... or at once at this step a tick (the reduced line is 0.03 where the ordinary is 0.045)
const MANY_PIX_FLOOR: float = 24.0    # one versus many (docs/camera/one-v-many.md): no body drawn is smaller than this many pixels (R_FLOOR is a share: 12 px on a phone in landscape)
const MANY_PIX_PRINCIPAL: float = 32.0  # ... and a principal not under this (R_PANE's 8.5% on that phone): the others join the frame while he stays at it
const MANY_KEEP: float = 0.75         # a body joins the framing set only if the zoom stays at 0.75 of the principals' own: a guard does not pull the frame out by a quarter
const MANY_JOIN: float = 0.9          # a body's weight is 0 at this share of the zoom's limit ...
const MANY_LEAVE: float = 1.1         # ... and 1 at this share (the weight moves at MANY_RATE a tick: no step)
const MANY_RATE: float = 0.025        # the weight's change a tick: a join or a leave takes 40 ticks
const MANY_UP_BH: float = 8.0         # a body higher than this many body heights over the principals is a marker, not a reason to zoom out
const MANY_DEPTH: float = 600.0       # a body deeper than this from the principals' plane is out of the frame for sizing (drawn if on screen)
const MANY_PULL: float = 0.15         # the group's bounding centre pulls the focus off the principals' midpoint by at most this much of the width
const MANY_ASSIGN_BH: float = 4.0     # a body belongs to the second principal's pane unless he is this many body heights nearer the one (the partner always goes with the one)
const MANY_PANE_PULL: float = 0.15    # a pane's focus is pulled toward the centre of its assigned bodies by at most this much of the pane's width
const MANY_PARTNER_BH: float = 1.0    # the partner is the nearest of the others to the one; another takes over only when this much nearer
const LH_SKY_ALT: float = 1500.0      # the rule does not engage for a body this high above the ground (units): the picture under a high flight is sky, which a chase does not change
const LH_SLOW: float = 0.8             # ... and ends when his speed has been under this share of the threshold ...
const LH_SLOW_TICKS: int = 6           # ... for this many ticks (or he has landed): one cut if he is far, else the ordinary follow takes him
const LH_CUT_OFFSET: float = 0.25      # "far": more than this much of the width from the held frame
const LH_CATCH_W: float = 0.15         # a launch shot does not end (the panes do not merge) while he is farther than this from his pane's focus ...
const LH_CATCH_MAX: float = 1.0        # ... for at most this many seconds more
const MZ_RATE: float = 0.0035          # merge zoom limit: while the panes merge the zoom comes in no faster than this (log units a tick) ...
const MZ_NEAR: float = 300.0           # a closing counts as merging for the zoom limit once the pair is this near (units): a closing that ends in a re-opening is not
const MZ_WINDOW: float = 2.0           # ... from the shot's end to this many seconds after the layout is one view
const LH_WAIT: float = 0.6             # (no longer read: the frame is held for the whole flight)
const LH_NEAR: float = 0.9             # on landing: nearer than this (of the width) from the held frame, the pane pans to him, farther it cuts once ...
const LH_STEP: float = 0.026           # ... at most this much of the width a tick (and the zoom's share with it: 0.03 in all) ...
const LH_ZOOM_STEP: float = 0.008      # ... and the zoom changes by at most this (of a log unit) a tick while it pans (half of it is travel)
const LH_CUT_UNITS: float = 20000.0    # (no longer read: one cut at the landing, none in the air)
const INTRO_STARE_PUSH: float = 0.10    # the two-shot pushes in this much over the staredown
const INTRO_FACES: bool = true          # two face cuts before the clock, if the animation has a face to show
const INTRO_FACE_R: float = 0.20
const INTRO_FACE_TICKS: int = 24        # each face lasts this many ticks ...
const INTRO_FACES_MIN: int = 120       # a staredown shorter than this (2 s) has no face cuts: three cuts in a second are the flash rule's, and the look is the shot
const INTRO_FACE_LEAD: int = 60         # ... and the first starts this many ticks before the clock; the last 12 are the two-shot again
const INTRO_BELL: float = 0.05          # the clock: a punch-in this big for 3 ticks
const INTRO_BELL_LEN: float = 0.05
const INTRO_EASE_OUT: float = 0.6       # the staredown push eases out over this after the clock

# --- the panel cut-in (pitches.md 8a option B, rule-of-cool.md row 11) ---
const PANEL_W: float = 0.56            # the strip's visible width, of the screen width
const PANEL_H: float = 0.20            # its height, of the screen height
const PANEL_SLANT: float = 0.22        # the slanted ends: this much of its height
const PANEL_TOP_Y: float = 0.19        # the top band starts here (the clear zone's top edge is 17.9%)
const PANEL_BOTTOM_Y: float = 0.80     # the bottom band starts here (the clear zone's bottom edge is 80.1%)
const PANEL_OPEN: float = 0.08         # seconds to wipe open
const PANEL_CLOSE: float = 0.12        # seconds to wipe shut
const PANEL_BODY: float = 60.0         # the stretch of the fighter that fills the strip's height, world units
const PANEL_FOCUS: float = 60.0        # the point of the fighter at the strip's centre, above his feet: the head and chest (the real renderer draws the plane a little low)
const PANEL_FILL: float = 0.88
const PANEL_PUSH: float = 0.06         # a slow push over the strip's life
const SIG_WINDOW: float = 4.0           # a signature asked for makes its panel within this many seconds (the tell, the 20 ticks of travel)
const PANEL_EARNED_GAP: float = 12.0   # earned hits share one panel in this many seconds; the peaks always play
const PANEL_RIPOSTE_WINDOW: float = 2.0  # a launch this soon after the launcher's parry is a riposte
# kind: {prio (a higher one replaces a lower one), dur (seconds), earned (shares the 12 s ration)}
const PANEL_KINDS: Dictionary = {
	"ko": {"prio": 5, "dur": 1.4, "earned": false},
	"finisher": {"prio": 4, "dur": 1.1, "earned": false},
	"crippling": {"prio": 3, "dur": 0.8, "earned": false},
	"signature": {"prio": 2, "dur": 0.9, "earned": false},
	"clash": {"prio": 1, "dur": 0.7, "earned": true},
	"riposte": {"prio": 1, "dur": 0.7, "earned": true},
	"rally": {"prio": 1, "dur": 0.7, "earned": true},
	"double": {"prio": 3, "dur": 0.75, "earned": false},   # the even mash's double hit: the pair at the contact; rationed apart (DOUBLE_RATION)
}
const DOUBLE_RATION: float = 45.0        # a double hit's close-up: the first of a match, then at most once in this many seconds
const DOUBLE_OPEN_BEFORE: int = 6        # it opens this many ticks before the blows land
const DOUBLE_MAIN_RULES: float = 0.8     # the main view's rules (no push, the pull-back, half the shake) run this long past the contact
const DOUBLE_SLIDE_SPAN: float = 1000.0  # the pull-back holds both slides: 6 body heights each way is 900 units, and some room
const DOUBLE_PANEL_PUSH: float = 0.03    # the close-up pushes 3% inside its own frame

# --- the winner in the wreckage (rule-of-cool.md row 8) ---
const WRECK_AT: float = 1.8            # seconds after the KO: the loser's close-up has played, the sim's slow motion is ending
const WRECK_T: float = 3.5             # the pull-back from a close-up to the wide shot, eased
const R_WRECK_0: float = 0.13          # it starts on the winner at this size ...
const R_WRECK: float = 0.04            # ... and ends with him this small (29 px at 720p)
const WRECK_ANCHOR_X: float = 0.20     # he ends this far (of the width) off centre, away from the most wreckage
const WRECK_REACH: float = 0.70        # the wreckage counted: this much of the screen width on the wreckage's side
const WRECK_BUILDING_W: float = 0.05   # a ruined building's weight against a crater's (area x depth)
const WRECK_MIN: float = 4000.0        # less than this much scar in view and he stays centred
const WRECK_TAU: float = 0.5           # the zoom filter during the pull-back
const BREAK_PITCH: float = -8.0        # the transformation's break: a low angle, the silhouette against the sky (full version)
const BREAK_CAM_MIN_H: float = 15.0   # the low angle keeps the camera at least this far above the fighter's feet (units)
const CUTAWAY_BREAK_R: float = 0.5      # the break asks for an occlusion hole this wide: half the screen height, the sky round him
const TRANSFORM_R0_SHORT: float = 0.125   # the short version's gather pushes half as far
const LIVE_PUNCH: float = 0.08         # the live version's 6-tick punch-in at the break
const LIVE_PUNCH_AT: int = 10          # ... after the 10-tick gather
const LIVE_PUNCH_LEN: float = 0.20
const LIVE_STEP_MAX: float = 1.2      # a transformation hold shorter than this is the live version (no pause): a push, no cut
const WIDE_PULL: float = 0.75          # a world-change pause pulls the shared view out to this much of its zoom
const WIDE_IN: float = 0.5             # seconds to get there, and to come back
const OV_COOLDOWN: float = 6.0         # between camera-only cuts (the sim-owned shots are exempt)
const OV_MAX_PER_MIN: int = 6
const OV_SMASH_DUR: float = 0.45       # the building-smash cut: the sim's 0.35 s hold and a beat
const OV_CRIPPLE_DUR: float = 0.80
const SHAKE_FALLOFF: float = 4000.0   # a shake event at this distance from a pane's centre is scaled down to SHAKE_FAR (Controls' shake pass)
const SHAKE_FAR: float = 0.35         # ... and the pane farther from the event gets this share of it
const SHAKE_DECAY: float = 0.02       # per second, the fx consumer's decay
const MODE_CHANGE_GAP: float = 0.8
