class_name VfxFlashRegistry
extends RefCounted
## The shared flash registry: one register in the hub that every full flash asks before it draws (Legal's condition for the public web build,
## docs/legal/photosensitivity-note.md; WCAG 2.2 criterion 2.3.1, "three flashes or below threshold"). A full flash is a filled or large bright pop (an energy landing's soft
## disc, an explosion's flame burst, a transformation's break flash) or a flash ring a sound effect would be paired with (a block's, a shot's hit, a guard break's). Hollow rings,
## thin lines and after-images are not flashes (docs/vfx/flash-registry.md has the table of every source and why).
##
## WEIGHTED BY SIZE (2026-10-06, after Tools' frame analyser): the standard counts a flash only when the pixels that changed by 0.10 of relative luminance cover 25% of a 341 by 256 window
## (21,824 px at 1024 by 768, 2.8% of the frame), so a small hit ring is nothing and an explosion near the camera is one flash alone. A flash is asked for with its AREA (`area_px`,
## its peak at 1024 by 768 equivalent) and its STEP (the luminance swing it makes against what is behind it):
##   weight w = min(1, area_px / AREA_FULL); a step under STEP_MIN (0.10) costs nothing and is not a flash; an ask with no area is weighted by its source (DEFAULT_WEIGHT: 1 for a big
##   event, the estimate in docs/vfx/flash-registry.md for a small one), so a caller that does not give them keeps working.
## The budget, in any WINDOW (60) ticks across the whole screen, both fighters and every effect:
##   - the SUM of the granted weights is at most BUDGET (2.5, Legal's gate); with `reduced` (reduced motion or the reduced-flashing setting) at most BUDGET_REDUCED (1.0);
##   - the low-priority sources (a fight makes many of them: energy, block, shot hits, mines, a guard break's ring, Rendering's body hit, head flash and cue flare) take at most LOW_BUDGET (1.5: the EP asked for 2 of the 2.5, which leaves 0.5, and a weight-1 explosion could then never be granted)
##     of it, none when reduced, so a slot is always left for the big events and for a perfect block's guard flash;
##   - the last RESERVE_BIG (0.5) of a normal second is for the big flashes: the low-priority sources and Camera's cut-in panel are not granted past BUDGET - RESERVE_BIG, so a clash or a beam is never refused for
##     a head's icon pulse and a recount cannot sit on the gate (the sum of the small ones ends at 2.0);
##   - today's count stays as a ceiling: at most BIG_CAP (3) granted flashes of weight BIG_W (0.5) or more (1 when reduced), and at most RATE_CAP (6) flashes of any weight (3 when reduced).
## Nothing red is ever granted. A refused flash is not drawn in its flash form (the source draws what is left: the table says what).
##
## The clock is the hub's own count of ticks (one per consume(), frozen ticks included), so a hit-stop does not stop the second. Every ask and every refusal is logged with its tick,
## its weight and the running sum, so a tool can check recorded worst cases (`summary()`, `log_rows()`) and UI can read what is being refused.
## The honest limit: this makes the register limit something closer to what the analyser measures, but it cannot see scenery sweeping past a moving camera, a panel wiping open or a
## whole-screen dip unless the system that makes it asks (Camera's dip and panel, Rendering's beam). The analyser on the recorded clips stays the test.
## Presentation only: it reads nothing from the sim and draws no random number.

const WINDOW: int = 60
const AREA_FULL: float = 21824.0         # px: 25% of the standard's 341 by 256 window at 1024 by 768
const STEP_MIN: float = 0.10             # a luminance swing under this is not a flash
const BUDGET: float = 2.5                # the sum of weights in any WINDOW ticks (Legal's gate)
const BUDGET_REDUCED: float = 1.0
## The last RESERVE_BIG of a normal-mode second is kept for the gameplay's big flashes (a beam's core, a beam clash, an explosion, a transformation's break): the low-priority sources (the
## fight's many small ones) and the decorative one (Camera's cut-in panel) are not granted past BUDGET - RESERVE_BIG. A seed-7 match in the nine-cells chain read 2.50006 of weight (a beam 1.0, its
## cut-in 1.0, a clash 0.4751 and a head flash 0.0249 granted at 2.5001 by a 0.0001 tolerance) against the gate's 2.5: the clash is a gameplay flare and the head's icon pulse is not, so the pulse gives
## way, and by construction the small sources' share ends 0.5 under the gate. Reduced mode keeps its whole 1.0 (one weight-1 flash must fit; its low class is none).
const RESERVE_BIG: float = 0.5
const DECOR: Array = ["cut_in_panel"]
const EPS: float = 0.000001                # the tolerance of a sum (the check's own is 1e-6)
const LOW_BUDGET: float = 1.5            # of it, the low-priority class's share
const BIG_W: float = 0.5                 # a flash of at least this weight counts toward BIG_CAP
const BIG_CAP: int = 3
const BIG_CAP_REDUCED: int = 1
const RATE_CAP: int = 6
const RATE_CAP_REDUCED: int = 3
const LOG_MAX: int = 2400
## Kept for callers that read them: the count of a second under the first version of the rule.
const CAP: int = 3
const CAP_REDUCED: int = 1
const LOW_CAP: int = 2
## The sources that leave a slot free: everything a fight makes many of (VFX's, and Rendering's body hit, head flash and cue flare: docs/rendering/flash-sources.md). A perfect block's
## guard flash is NOT low: a skill moment the player earned, it may take the third slot (the EP's ruling, 2026-10-06).
const LOW: Array = ["energy", "block", "shot_hit", "mine", "zip_break", "body_hit", "head_flash", "cue_flare", "divider_slam", "far_impact", "biome_star"]
## THE CATASTROPHE CLASS (docs/vfx/catastrophe-plan.md section 1; Legal c01 to c05, run-mode section 3.2): a world-scale light event (the blast cloud's fireball, the crust breach's flare, a big
## impact seen from the exosphere, a meteor) is asked with ask_cat(), which adds to the ordinary rules: one event per CAT_GAP ticks across the screen, a rise of at least CAT_RISE_MIN ticks
## and a fall of at least CAT_FALL_MIN (cat_shape() clamps them), a calm form under `reduced` (a lower peak, a slower rise and fall, and no second event within CAT_REPEAT_QUIET), and a peak
## that gives way as the sky darkens (`ash`). A glow whose area weighs under CAT_SMALL_W is not a catastrophe event but an ordinary low-priority `far_impact`. An event is asked once by its
## id: a second view of it (Camera's window beside the wide) takes the same answer. A refused event draws its body without its light.
const CAT_GAP: int = 120                  # ticks (2 s) between two catastrophe light events, whatever the pane
const CAT_RISE_MIN: int = 18              # ticks (0.3 s)
const CAT_FALL_MIN: int = 60              # ticks (1 s)
const CAT_SMALL_W: float = 0.05           # of AREA_FULL: about 1,090 px at 1024 by 768 (Legal to confirm)
const CAT_ASH_K: float = 0.35             # the peak is scaled by 1 - CAT_ASH_K * ash (a starting value; the darkened-sky clip sets it)
const CAT_CALM_PEAK: float = 0.6
const CAT_CALM_RISE_K: float = 1.7
const CAT_CALM_RISE_FLOOR: int = 30       # ticks (0.5 s)
const CAT_CALM_FALL_K: float = 1.5
const CAT_REPEAT_QUIET: int = 240         # ticks (4 s): under `reduced`, no second event this soon draws a light
const CAT_KEEP: int = 600                 # ticks an event's answer and peak are remembered
## ONE REGISTER FOR A SCREEN, TWO FIGHTS ON IT (2v2; Legal RL-249, docs/vfx/shared-register.md). The main hub's register is the screen's: an other fight's hub (stage_feed.gd) holds this same object and asks it
## through a CHANNEL (`channel` 0 is the screen's own fight; 1 and up an other fight, set around that hub's consume), so the limits apply to the SUM and each hub is only a feeder. The own fight is never made to
## give way (3): its asks are measured against its own grants and the 2.5 gate over everything, and the other fight's asks are held to OTHER_CAP of weight at once (none when reduced), to the same low,
## big and rate counts over the sum, and to the gate. A refused other-fight flash draws its calm form (the source's own) and that calm form is COUNTED (2) at OTHER_CALM_K of its weight, up to OTHER_CALM_CAP in a window.
## An other fight that is not on screen (`set_visible`) asks a shadow window of its own: nothing it does counts toward the screen until it is on screen, and when it swings into view what it did in the last
## WINDOW ticks is counted from that tick (4). A catastrophe event of the other fight starts only in a gap clear of every event, and its light is bounded by the room the own fight's light leaves (`cat_room()`): one envelope.
const OTHER_CAP: float = 1.0              # weight the other fight's full flashes may hold at once (normal mode)
const OTHER_CAP_REDUCED: float = 0.0      # ... under Reduce flashing: calm forms only
const OTHER_CALM_K: float = 0.2           # a calm form counts this share of the flash it stands in for
const OTHER_CALM_CAP: float = 0.3         # most weight the other fight's calm forms may hold in a window
const TOTAL_GATE: float = 2.5             # Legal's primary cap over everything on the screen, both modes
const CAT_CH_KEY: int = 1099511627776     # a catastrophe event's id is made per channel (2^40 apart), so two fights' counters never meet
## A source's weight when the ask gives no area: 1 for the big events (an unknown source too), and the estimate of a small source's flash against the 21,824-px threshold at the
## close framing (about 1.3 px a world unit).
const DEFAULT_WEIGHT: Dictionary = {
	"energy": 0.15, "block": 0.05, "shot_hit": 0.4, "mine": 0.4, "zip_break": 0.1, "body_hit": 0.17, "head_flash": 0.07, "guard_flash": 0.2, "cue_flare": 0.4,
	"double_hit": 0.15, "charge_full": 0.05, "divider_slam": 0.3, "biome_star": 0.1,
	"explosion": 1.0, "transform": 1.0, "beam": 1.0, "beam_clash": 1.0, "far_impact": 0.03, "hard_cut": 1.0,
}

var reduced: bool = false           # reduced motion or the reduced-flashing setting: set by the hub every tick
var cam_dist: float = 0.0           # the camera's distance to the fighters' plane in units (the hub's), 0 = unknown: ppu_at is ppu
var ppu: float = 1.3                # pixels per world unit at 1024 by 768 on the fighters' plane: the host sets it from the camera (hub.px_per_unit); the close framing is about 1.3
var now: int = 0                    # the clock, in ticks
var grants: Array = []              # {now, w, low}: the flashes granted in the last WINDOW ticks
var log: Array = []                 # {now, tick, source, granted, why, in_window, weight, sum}, oldest first, at most LOG_MAX
var granted_by: Dictionary = {}
var refused_by: Dictionary = {}
var worst_second: int = 0           # the most granted flashes in any one window so far
var worst_weight: float = 0.0       # the largest sum of weights in any one window so far
var cat_last: int = -1000000        # the clock tick of the last catastrophe light event granted
var cat_events: Array = []          # {id, now, rise, fall, peak_tick, source}: the granted ones of the last CAT_KEEP ticks
var cat_answers: Dictionary = {}    # cat_id -> the answer ask_cat gave (the same event asked again takes it)
var channel: int = 0                # whose ask this is: 0 the screen's own fight, 1 and up an other fight (set by its hub around its consume; ask_in sets it for one call)
var seen: Dictionary = {}           # channel -> whether that fight is on screen (absent: yes, counted); set by the host through set_visible
var shadow: Array = []              # {now, w, low, ch, calm, src}: an off-screen other fight's would-be grants in the last WINDOW ticks, counted from the tick it comes into view
var cat_last_own: int = -1000000    # the clock tick of the last catastrophe light event of the own fight
var calm_noted: int = 0             # calm forms counted for a refused other-fight flash
var calm_unfit: int = 0             # ... and the ones that did not fit (left uncounted; the check wants none)
var own_total_refused: int = 0      # the own fight's asks the gate over the sum refused (the check wants none in the 2v2 scenes)


func reset() -> void:
	reduced = false
	now = 0
	channel = 0
	seen.clear()
	shadow.clear()
	cat_last_own = -1000000
	calm_noted = 0
	calm_unfit = 0
	own_total_refused = 0
	cat_last = -1000000
	cat_events.clear()
	cat_answers.clear()
	grants.clear()
	log.clear()
	granted_by.clear()
	refused_by.clear()
	worst_second = 0
	worst_weight = 0.0


## Once per consume(), first.
func begin_tick(p_reduced: bool) -> void:
	reduced = p_reduced
	now += 1
	while not grants.is_empty() and int(grants[0]["now"]) <= now - WINDOW:
		grants.pop_front()
	while not shadow.is_empty() and int(shadow[0]["now"]) <= now - WINDOW:
		shadow.pop_front()
	while not cat_events.is_empty() and int(cat_events[0]["now"]) <= now - CAT_KEEP:
		cat_events.pop_front()
	if not cat_answers.is_empty():
		for id in cat_answers.keys():
			if int(cat_answers[id]["start"]) <= now - CAT_KEEP:
				cat_answers.erase(id)


static func is_red(c: Color) -> bool:
	return c.r > 0.55 and c.g < 0.45 * c.r and c.b < 0.45 * c.r


## Pixels per world unit at depth z (positive toward the camera): the plane's, scaled by how much nearer or farther from the camera that depth is, so a flash in the middle street covers
## the pixels it covers there (a fighter at 54% size is 0.29 of the area). Without the camera's distance, the plane's.
func ppu_at(z: float) -> float:
	if cam_dist <= 1.0 or z == 0.0:
		return ppu
	return ppu * clampf(cam_dist / maxf(cam_dist - z, cam_dist * 0.2), 0.25, 3.0)


## A disc of r world units, in px at 1024 by 768 for a ppu: a flash's area for the ask.
static func disc_px(r_units: float, p_ppu: float) -> float:
	return PI * r_units * r_units * p_ppu * p_ppu


## A ring of r world units and t units thick (its drawn pixels).
static func ring_px(r_units: float, t_units: float, p_ppu: float) -> float:
	return TAU * r_units * t_units * p_ppu * p_ppu


func in_window() -> int:
	return grants.size()


## The sum over everything on the screen (every fight, calm forms too): what the gate limits.
func sum_in_window() -> float:
	var s: float = 0.0
	for g in grants:
		s += float(g["w"])
	return s


## The own fight's share of it: what the own fight's asks are measured against, so the other fight never takes its place.
func own_sum() -> float:
	var s: float = 0.0
	for g in grants:
		if int(g.get("ch", 0)) == 0:
			s += float(g["w"])
	return s


func _own_n() -> int:
	var k: int = 0
	for g in grants:
		if int(g.get("ch", 0)) == 0:
			k += 1
	return k


## Counts of the granted flashes of weight min_w or more: the own fight's (own) or the screen's (all, calm forms too).
func _count(min_w: float, own: bool = true) -> int:
	var k: int = 0
	for g in grants:
		if float(g["w"]) >= min_w and (not own or int(g.get("ch", 0)) == 0):
			k += 1
	return k


func _low_sum(own: bool = true) -> float:
	var s: float = 0.0
	for g in grants:
		if bool(g["low"]) and (not own or int(g.get("ch", 0)) == 0):
			s += float(g["w"])
	return s


## The sum of weights in `arr` (grants or shadow) of one channel, calm forms only when `calm`.
static func _ch_sum(arr: Array, ch: int, calm: bool = false) -> float:
	var s: float = 0.0
	for g in arr:
		if int(g.get("ch", 0)) == ch and (not calm or bool(g.get("calm", false))):
			s += float(g["w"])
	return s


## The host says whether other fight `ch` is drawn on this screen. Off, its asks go to a shadow window and count for nothing; the tick it comes into view what it did in the last WINDOW ticks is counted
## from that tick (a fight swinging into view cannot surprise the register). Unset, a fight counts as on screen.
func set_visible(ch: int, on: bool) -> void:
	var was: bool = bool(seen.get(ch, true))
	seen[ch] = on
	if on and not was:
		var keep: Array = []
		for sh in shadow:
			if int(sh["ch"]) == ch:
				_record(String(sh["src"]), true, "swing_in", -1, float(sh["w"]), bool(sh["low"]), ch)
				grants.append({"now": int(sh["now"]), "w": float(sh["w"]), "low": bool(sh["low"]), "ch": ch, "calm": bool(sh["calm"])})
			else:
				keep.append(sh)
		shadow = keep
		worst_second = maxi(worst_second, grants.size())
		worst_weight = maxf(worst_weight, sum_in_window())


## What a flash is told, in a word, for a caller that draws one of several forms (Rendering's drawn beams, a hit, a shared-world glow): "full" (granted), "calm" (it gives way: draw the calm, thin form; the calm form
## is counted) or "later" (even the calm form does not fit now: start it `ticks_until_room()` ticks from now, or draw nothing of its light). Never "off": nothing is hidden, dissolved, faded or marked.
## `ch` 0 is the screen's own fight (never made to give way beyond its own rules), 1 and up an other fight (fight index + 1). `first_tick` is not asked: the count starts on the tick the effect is on screen, which is
## set_visible's and the caller's first ask.
func ask_form(ch: int, source: String, col: Color = Color.WHITE, tick: int = -1, area_px: float = -1.0, step: float = -1.0) -> String:
	var unfit: int = calm_unfit
	var noted: int = calm_noted
	if ask_in(ch, source, col, tick, area_px, step):
		return "full"
	if ch == 0:
		return "calm"
	if calm_noted > noted:
		return "calm"
	if calm_unfit > unfit:
		return "later"
	return "calm"      # red: its form is calm, nothing counted


## Ticks from now until a flash of weight `w` would fit under the own fight's rules (the budget, the big and rate counts), counting the grants that leave the window as they do. 0 if it fits now; WINDOW at the most.
func ticks_until_room(w: float, own: bool = true) -> int:
	var budget: float = BUDGET_REDUCED if reduced else BUDGET
	var big_cap: int = BIG_CAP_REDUCED if reduced else BIG_CAP
	var rate_cap: int = RATE_CAP_REDUCED if reduced else RATE_CAP
	for dt in range(0, WINDOW + 1):
		var sum: float = 0.0
		var nbig: int = 0
		var n: int = 0
		for g in grants:
			if int(g["now"]) <= now + dt - WINDOW:
				continue
			if own and int(g.get("ch", 0)) != 0:
				continue
			sum += float(g["w"])
			n += 1
			if float(g["w"]) >= BIG_W:
				nbig += 1
		if sum + w <= budget + EPS and n < rate_cap and (w < BIG_W or nbig < big_cap):
			return dt
	return WINDOW


## A HARD CUT that changes most of the screen (CD-04; Camera's `_mark_cut` callers: side_swap, relocate, rush_pin, solo_cut_in, insert, transform, intro and the rest) is one light event in the register, asked
## by the camera before it cuts: `why` names it for the log, `area` is the share of the frame the cut changes (0 to 1), `step` the change in relative luminance the cut makes there (-1 unknown: it is weighed by
## its area alone). A cut is one transition and the analyser counts a flash as a pair, so it is weighed as a whole flash on purpose: cut, cut back and the pair is two. Returns {"form": "cut" | "ease" | "wait",
## "wait": ticks}: "cut" is granted (the cut may be made now); "ease" is refused (the frame eases to the new view, as a whip does, instead of jumping: no dissolve, no fade); "wait" is refused and would fit in `wait`
## ticks (the cut may be held that long, never a lock). A cut under the step threshold costs nothing. Under Reduce flashing the budget is 1.0, so a second full-screen cut inside a second eases.
func ask_cut(why: String, area: float, step: float = -1.0, tick: int = -1) -> Dictionary:
	var area_px: float = clampf(area, 0.0, 1.0) * 1024.0 * 768.0
	var keep: int = channel
	channel = 0
	var ok: bool = ask("hard_cut", Color(0.3, 0.3, 0.35), tick, area_px, step)
	channel = keep
	if ok:
		return {"form": "cut", "wait": 0}
	var wait: int = ticks_until_room(weight_of("hard_cut", area_px))
	return {"form": "wait" if wait <= 30 else "ease", "wait": wait}


## One ask on behalf of other fight `ch` (the hub's consume does this for its own events; Rendering's drawn beams and hits ask through it).
func ask_in(ch: int, source: String, col: Color = Color.WHITE, tick: int = -1, area_px: float = -1.0, step: float = -1.0) -> bool:
	var keep: int = channel
	channel = ch
	var ok: bool = ask(source, col, tick, area_px, step)
	channel = keep
	return ok


## The weight of a flash: from its area when the ask gives one, else from its source.
func weight_of(source: String, area_px: float) -> float:
	if area_px >= 0.0:
		return minf(1.0, area_px / AREA_FULL)
	return float(DEFAULT_WEIGHT.get(source, 1.0))


## Whether a flash of `source` may be drawn now (and if so it takes its weight of the budget). col is the flash's colour: a red one is never granted. tick is the sim tick, for the log
## only. area_px and step are optional (see the header): without them the flash is weighted by its source.
func ask(source: String, col: Color = Color.WHITE, tick: int = -1, area_px: float = -1.0, step: float = -1.0) -> bool:
	if channel > 0:
		return _ask_other(source, col, tick, area_px, step)
	if step >= 0.0 and step < STEP_MIN:
		_record(source, true, "below_step", tick, 0.0, false)
		return true
	var low: bool = LOW.has(source)
	var w: float = weight_of(source, area_px)
	var budget: float = BUDGET_REDUCED if reduced else BUDGET
	var small_cap: float = budget if reduced else budget - RESERVE_BIG     # what the small and decorative sources may fill to
	var small: bool = low or DECOR.has(source)
	var low_budget: float = 0.0 if reduced else LOW_BUDGET
	var big_cap: int = BIG_CAP_REDUCED if reduced else BIG_CAP
	var rate_cap: int = RATE_CAP_REDUCED if reduced else RATE_CAP
	var why: String = "ok"
	var ok: bool = true
	if is_red(col):
		ok = false
		why = "red"
	elif own_sum() + w > (small_cap if small else budget) + EPS:
		ok = false
		why = "budget"
	elif sum_in_window() + w > TOTAL_GATE + EPS:
		ok = false
		why = "total"
		own_total_refused += 1
	elif low and _low_sum() + w > low_budget + EPS:
		ok = false
		why = "reduced" if reduced else "low_priority"
	elif w >= BIG_W and _count(BIG_W) >= big_cap:
		ok = false
		why = "cap"
	elif _own_n() >= rate_cap:
		ok = false
		why = "cap"
	_record(source, ok, why, tick, w, low)
	if ok:
		grants.append({"now": now, "w": w, "low": low, "ch": 0})
		worst_second = maxi(worst_second, grants.size())
		worst_weight = maxf(worst_weight, sum_in_window())
	return ok


## An other fight's flash (channel > 0). Held to OTHER_CAP of weight at once (none when reduced), to the low, big and rate counts over the SUM and to the gate; refused, it draws its calm form and the calm form is
## counted. Off screen it asks its shadow window alone and is counted for nothing until it is on screen (set_visible). Never red.
func _ask_other(source: String, col: Color, tick: int, area_px: float, step: float) -> bool:
	var ch: int = channel
	if step >= 0.0 and step < STEP_MIN:
		_record(source, true, "below_step", tick, 0.0, false, ch)
		return true
	var low: bool = LOW.has(source)
	var w: float = weight_of(source, area_px)
	var wc: float = w * OTHER_CALM_K
	var on: bool = bool(seen.get(ch, true))
	var arr: Array = grants if on else shadow
	var cap: float = OTHER_CAP_REDUCED if reduced else OTHER_CAP
	var big_cap: int = BIG_CAP_REDUCED if reduced else BIG_CAP
	var rate_cap: int = RATE_CAP_REDUCED if reduced else RATE_CAP
	var low_budget: float = 0.0 if reduced else LOW_BUDGET
	var why: String = "ok"
	var ok: bool = true
	if is_red(col):
		ok = false
		why = "red"
	elif _ch_sum(arr, ch) + w > cap + EPS:
		ok = false
		why = "gives_way"
	elif on and sum_in_window() + w > TOTAL_GATE + EPS:
		ok = false
		why = "gives_way"
	elif on and low and _low_sum(false) + w > low_budget + EPS:
		ok = false
		why = "gives_way"
	elif on and w >= BIG_W and _count(BIG_W, false) >= big_cap:
		ok = false
		why = "gives_way"
	elif on and grants.size() >= rate_cap:
		ok = false
		why = "gives_way"
	if ok:
		if on:
			_record(source, true, "ok", tick, w, low, ch)
			grants.append({"now": now, "w": w, "low": low, "ch": ch, "calm": false})
			worst_second = maxi(worst_second, grants.size())
			worst_weight = maxf(worst_weight, sum_in_window())
		else:
			shadow.append({"now": now, "w": w, "low": low, "ch": ch, "calm": false, "src": source})
			_record(source, true, "off_screen", tick, 0.0, low, ch)
		return true
	# refused: its calm form is drawn, and counted (RL-249 (2)); a calm form that does not fit is left uncounted and shows in calm_unfit
	if why != "red" and wc > 0.0 and _ch_sum(arr, ch, true) + wc <= OTHER_CALM_CAP + EPS and (not on or sum_in_window() + wc <= TOTAL_GATE + EPS):
		calm_noted += 1
		if on:
			_record(source, true, "calm_counted", tick, wc, low, ch)
			grants.append({"now": now, "w": wc, "low": low, "ch": ch, "calm": true})
			worst_second = maxi(worst_second, grants.size())
			worst_weight = maxf(worst_weight, sum_in_window())
		else:
			shadow.append({"now": now, "w": wc, "low": low, "ch": ch, "calm": true, "src": source})
			_record(source, true, "off_screen", tick, 0.0, low, ch)
	else:
		if why != "red":
			calm_unfit += 1
		_record(source, false, why, tick, w, low, ch)
	return false


## The shape a catastrophe light event may have: the asked rise and fall clamped to the floors, the peak scaled for the darkness of the sky, and the calm form when `calm`. Static, so the
## effects' own drawing and the checks use the same numbers. Returns {peak, rise, fall} (the rise and fall in ticks).
static func cat_shape(rise: int, fall: int, peak: float, ash: float, calm: bool) -> Dictionary:
	var r: int = maxi(rise, CAT_RISE_MIN)
	var f: int = maxi(fall, CAT_FALL_MIN)
	var p: float = peak * (1.0 - CAT_ASH_K * clampf(ash, 0.0, 1.0))
	if calm:
		p *= CAT_CALM_PEAK
		r = maxi(int(ceil(float(r) * CAT_CALM_RISE_K)), CAT_CALM_RISE_FLOOR)
		f = int(ceil(float(f) * CAT_CALM_FALL_K))
	return {"peak": p, "rise": r, "fall": f}


## A catastrophe event's light at `age` ticks after its start, 0 to 1 of its peak: a smootherstep up over `rise`, a smootherstep down over `fall`, nothing before or after. The steepest step
## of a tick is 1.875 / min(rise, fall) of the peak (0.104 at the 18-tick floor).
static func cat_level(age: float, rise: int, fall: int) -> float:
	if age <= 0.0 or age >= float(rise + fall):
		return 0.0
	if age < float(rise):
		var u: float = age / float(rise)
		return u * u * u * (u * (u * 6.0 - 15.0) + 10.0)
	var d: float = (age - float(rise)) / float(fall)
	return 1.0 - d * d * d * (d * (d * 6.0 - 15.0) + 10.0)


## Ask for a catastrophe light event. `cat_id` names the event (a sim counter or a hash of its cue): a second ask for it, by another pane or view, takes the first answer and counts nothing
## more. `area_px` is the glow's peak area at 1024 by 768 (its weight is area / AREA_FULL). `rise` and `fall` are the asked ticks, `peak` the asked strength (0 to 1), `ash` the world's
## darkening (0 to 1). Returns {ok, cat, why, peak, rise, fall, weight, start}: the light may be drawn at `peak` with `rise` and `fall` when `ok`; when not, draw the event's body alone.
## `cat` is false for a small glow (under CAT_SMALL_W), which is only an ordinary low-priority `far_impact`.
func ask_cat(source: String, cat_id: int, col: Color, area_px: float, rise: int, fall: int, peak: float = 1.0, ash: float = 0.0, tick: int = -1) -> Dictionary:
	var key: int = cat_id + channel * CAT_CH_KEY
	if cat_answers.has(key):
		return cat_answers[key]
	var w: float = weight_of(source, area_px)
	var sh: Dictionary = cat_shape(rise, fall, peak, ash, reduced)
	var out: Dictionary = {"ok": false, "cat": w >= CAT_SMALL_W, "why": "ok", "peak": float(sh["peak"]), "rise": int(sh["rise"]), "fall": int(sh["fall"]), "weight": w, "start": now}
	if not bool(out["cat"]):
		out["ok"] = ask("far_impact", col, tick, area_px)
		out["why"] = String(log.back()["why"])
	elif (cat_last_own if channel == 0 else cat_last) >= 0 and now - (cat_last_own if channel == 0 else cat_last) < (CAT_REPEAT_QUIET if reduced else CAT_GAP):
		out["why"] = "cat_calm_repeat" if reduced else "cat_gap"
		_record(source, false, String(out["why"]), tick, w, false)
	else:
		out["ok"] = ask(source, col, tick, area_px)
		out["why"] = String(log.back()["why"])
		if bool(out["ok"]):
			cat_last = now
			if channel == 0:
				cat_last_own = now
			cat_events.append({"id": cat_id, "now": now, "rise": int(out["rise"]), "fall": int(out["fall"]), "peak_tick": now + int(out["rise"]), "source": source, "ch": channel, "peak": float(out["peak"])})
	if not bool(out["ok"]):
		out["peak"] = 0.0
	cat_answers[key] = out
	return out


## ask_cat for other fight `ch` (Rendering's drawn catastrophe events ask through it; a hub's own consume sets the channel itself).
func ask_cat_in(ch: int, source: String, cat_id: int, col: Color, area_px: float, rise: int, fall: int, peak: float = 1.0, ash: float = 0.0, tick: int = -1) -> Dictionary:
	var keep: int = channel
	channel = ch
	var out: Dictionary = ask_cat(source, cat_id, col, area_px, rise, fall, peak, ash, tick)
	channel = keep
	return out


## The light an other fight's catastrophe event may draw now: what is left under one event's peak once the own fight's catastrophe light is taken (RL-249 (1): one envelope over both fights, never two
## full-strength ones stacked). The own fight is never held down by it. The other fight's light is min(its envelope, cat_room()), so the sum never passes the one peak and no step is steeper than the floor's.
func cat_room() -> float:
	var cap: float = CAT_CALM_PEAK if reduced else 1.0
	var own: float = 0.0
	for e in cat_events:
		if int(e.get("ch", 0)) == 0:
			own += cat_level(float(now - int(e["now"])), int(e["rise"]), int(e["fall"])) * float(e.get("peak", 1.0))
	return maxf(0.0, cap - own)


## Whether a granted catastrophe event's peak is within `margin` ticks of now (Camera's rule: no cut within 0.5 s of a peak; 30 ticks).
func cat_peak_near(margin: int = 30) -> bool:
	for e in cat_events:
		if absi(int(e["peak_tick"]) - now) <= margin:
			return true
	return false


## A flash that another system draws and this one cannot refuse (Rendering's, until it asks): counted, never refused.
func note(source: String, tick: int = -1, area_px: float = -1.0) -> void:
	var w: float = weight_of(source, area_px)
	_record(source, true, "unregulated", tick, w, LOW.has(source), channel)
	grants.append({"now": now, "w": w, "low": LOW.has(source), "ch": channel, "calm": false})
	worst_second = maxi(worst_second, grants.size())
	worst_weight = maxf(worst_weight, sum_in_window())


func _record(source: String, ok: bool, why: String, tick: int, w: float, low: bool, ch: int = 0) -> void:
	var counted: bool = why != "below_step" and why != "off_screen"
	if counted:
		if ok:
			granted_by[source] = int(granted_by.get(source, 0)) + 1
		else:
			refused_by[source] = int(refused_by.get(source, 0)) + 1
	var sum_after: float = sum_in_window() + (w if ok and counted else 0.0)
	log.append({"now": now, "tick": tick, "source": source, "granted": ok, "why": why, "in_window": grants.size() + (1 if ok and counted else 0), "weight": w, "sum": sum_after, "ch": ch})
	while log.size() > LOG_MAX:
		log.pop_front()


## The log as rows for a tool: [now, tick, source, granted, why, flashes in the window after this one, weight, the running sum of weights after it]. The channel of a row is `log[i]["ch"]` and `summary().by_channel`.
func log_rows() -> Array:
	var out: Array = []
	for r in log:
		out.append([r["now"], r["tick"], r["source"], r["granted"], r["why"], r["in_window"], r["weight"], r["sum"]])
	return out


## The most granted flashes in any WINDOW-tick window of the log, counted from the log itself (not the running figure).
func worst_from_log() -> int:
	var best: int = 0
	var ts: Array = []
	for r in log:
		if bool(r["granted"]) and String(r["why"]) != "below_step" and String(r["why"]) != "off_screen":
			ts.append(int(r["now"]))
	for i in range(ts.size()):
		var k: int = 0
		for j in range(i, ts.size()):
			if int(ts[j]) < int(ts[i]) + WINDOW:
				k += 1
			else:
				break
		best = maxi(best, k)
	return best


## ... and the largest sum of weights in any WINDOW-tick window of the log: the figure the budget limits.
func worst_weight_from_log() -> float:
	var best: float = 0.0
	var ev: Array = []
	for r in log:
		if bool(r["granted"]) and String(r["why"]) != "below_step" and String(r["why"]) != "off_screen":
			ev.append([int(r["now"]), float(r["weight"])])
	for i in range(ev.size()):
		var s: float = 0.0
		for j in range(i, ev.size()):
			if int(ev[j][0]) < int(ev[i][0]) + WINDOW:
				s += float(ev[j][1])
			else:
				break
		best = maxf(best, s)
	return best


func summary() -> Dictionary:
	var refused: int = 0
	for k in refused_by.keys():
		refused += int(refused_by[k])
	var granted: int = 0
	for k in granted_by.keys():
		granted += int(granted_by[k])
	return {"granted": granted, "refused": refused, "worst_second": worst_from_log(), "worst_running": worst_second, "worst_weight": worst_weight_from_log(), "worst_weight_running": worst_weight,
		"granted_by": granted_by.duplicate(), "refused_by": refused_by.duplicate(), "budget": BUDGET_REDUCED if reduced else BUDGET, "cap": BIG_CAP_REDUCED if reduced else BIG_CAP,
		"calm_noted": calm_noted, "calm_unfit": calm_unfit, "own_total_refused": own_total_refused, "by_channel": _by_channel()}


## Granted and refused rows for each channel, from the log: the count a 2v2 clip's report prints (the own fight's and the other's).
func _by_channel() -> Dictionary:
	var out: Dictionary = {}
	for r in log:
		var ch: int = int(r.get("ch", 0))
		var d: Dictionary = out.get(ch, {"granted": 0, "refused": 0, "calm": 0, "weight": 0.0})
		var why: String = String(r["why"])
		if why == "off_screen" or why == "below_step":
			continue
		if bool(r["granted"]):
			d["granted"] = int(d["granted"]) + 1
			d["weight"] = float(d["weight"]) + float(r["weight"])
			if why == "calm_counted":
				d["calm"] = int(d["calm"]) + 1
		else:
			d["refused"] = int(d["refused"]) + 1
		out[ch] = d
	return out
