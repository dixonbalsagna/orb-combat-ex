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
const LOW: Array = ["energy", "block", "shot_hit", "mine", "zip_break", "body_hit", "head_flash", "cue_flare", "divider_slam"]
## A source's weight when the ask gives no area: 1 for the big events (an unknown source too), and the estimate of a small source's flash against the 21,824-px threshold at the
## close framing (about 1.3 px a world unit).
const DEFAULT_WEIGHT: Dictionary = {
	"energy": 0.15, "block": 0.05, "shot_hit": 0.4, "mine": 0.4, "zip_break": 0.1, "body_hit": 0.17, "head_flash": 0.07, "guard_flash": 0.2, "cue_flare": 0.4,
	"double_hit": 0.15, "charge_full": 0.05, "divider_slam": 0.3,
	"explosion": 1.0, "transform": 1.0, "beam": 1.0, "beam_clash": 1.0,
}

var reduced: bool = false           # reduced motion or the reduced-flashing setting: set by the hub every tick
var ppu: float = 1.3                # pixels per world unit at 1024 by 768 on the fighters' plane: the host sets it from the camera (hub.px_per_unit); the close framing is about 1.3
var now: int = 0                    # the clock, in ticks
var grants: Array = []              # {now, w, low}: the flashes granted in the last WINDOW ticks
var log: Array = []                 # {now, tick, source, granted, why, in_window, weight, sum}, oldest first, at most LOG_MAX
var granted_by: Dictionary = {}
var refused_by: Dictionary = {}
var worst_second: int = 0           # the most granted flashes in any one window so far
var worst_weight: float = 0.0       # the largest sum of weights in any one window so far


func reset() -> void:
	reduced = false
	now = 0
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


static func is_red(c: Color) -> bool:
	return c.r > 0.55 and c.g < 0.45 * c.r and c.b < 0.45 * c.r


## A disc of r world units, in px at 1024 by 768 for a ppu: a flash's area for the ask.
static func disc_px(r_units: float, p_ppu: float) -> float:
	return PI * r_units * r_units * p_ppu * p_ppu


## A ring of r world units and t units thick (its drawn pixels).
static func ring_px(r_units: float, t_units: float, p_ppu: float) -> float:
	return TAU * r_units * t_units * p_ppu * p_ppu


func in_window() -> int:
	return grants.size()


func sum_in_window() -> float:
	var s: float = 0.0
	for g in grants:
		s += float(g["w"])
	return s


func _count(min_w: float) -> int:
	var k: int = 0
	for g in grants:
		if float(g["w"]) >= min_w:
			k += 1
	return k


func _low_sum() -> float:
	var s: float = 0.0
	for g in grants:
		if bool(g["low"]):
			s += float(g["w"])
	return s


## The weight of a flash: from its area when the ask gives one, else from its source.
func weight_of(source: String, area_px: float) -> float:
	if area_px >= 0.0:
		return minf(1.0, area_px / AREA_FULL)
	return float(DEFAULT_WEIGHT.get(source, 1.0))


## Whether a flash of `source` may be drawn now (and if so it takes its weight of the budget). col is the flash's colour: a red one is never granted. tick is the sim tick, for the log
## only. area_px and step are optional (see the header): without them the flash is weighted by its source.
func ask(source: String, col: Color = Color.WHITE, tick: int = -1, area_px: float = -1.0, step: float = -1.0) -> bool:
	if step >= 0.0 and step < STEP_MIN:
		_record(source, true, "below_step", tick, 0.0, false)
		return true
	var low: bool = LOW.has(source)
	var w: float = weight_of(source, area_px)
	var budget: float = BUDGET_REDUCED if reduced else BUDGET
	var low_budget: float = 0.0 if reduced else LOW_BUDGET
	var big_cap: int = BIG_CAP_REDUCED if reduced else BIG_CAP
	var rate_cap: int = RATE_CAP_REDUCED if reduced else RATE_CAP
	var why: String = "ok"
	var ok: bool = true
	if is_red(col):
		ok = false
		why = "red"
	elif sum_in_window() + w > budget + 0.0001:
		ok = false
		why = "budget"
	elif low and _low_sum() + w > low_budget + 0.0001:
		ok = false
		why = "reduced" if reduced else "low_priority"
	elif w >= BIG_W and _count(BIG_W) >= big_cap:
		ok = false
		why = "cap"
	elif grants.size() >= rate_cap:
		ok = false
		why = "cap"
	_record(source, ok, why, tick, w, low)
	if ok:
		grants.append({"now": now, "w": w, "low": low})
		worst_second = maxi(worst_second, grants.size())
		worst_weight = maxf(worst_weight, sum_in_window())
	return ok


## A flash that another system draws and this one cannot refuse (Rendering's, until it asks): counted, never refused.
func note(source: String, tick: int = -1, area_px: float = -1.0) -> void:
	var w: float = weight_of(source, area_px)
	_record(source, true, "unregulated", tick, w, LOW.has(source))
	grants.append({"now": now, "w": w, "low": LOW.has(source)})
	worst_second = maxi(worst_second, grants.size())
	worst_weight = maxf(worst_weight, sum_in_window())


func _record(source: String, ok: bool, why: String, tick: int, w: float, low: bool) -> void:
	var counted: bool = why != "below_step"
	if counted:
		if ok:
			granted_by[source] = int(granted_by.get(source, 0)) + 1
		else:
			refused_by[source] = int(refused_by.get(source, 0)) + 1
	var sum_after: float = sum_in_window() + (w if ok and counted else 0.0)
	log.append({"now": now, "tick": tick, "source": source, "granted": ok, "why": why, "in_window": grants.size() + (1 if ok and counted else 0), "weight": w, "sum": sum_after})
	while log.size() > LOG_MAX:
		log.pop_front()


## The log as rows for a tool: [now, tick, source, granted, why, flashes in the window after this one, weight, the running sum of weights after it].
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
		if bool(r["granted"]) and String(r["why"]) != "below_step":
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
		if bool(r["granted"]) and String(r["why"]) != "below_step":
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
		"granted_by": granted_by.duplicate(), "refused_by": refused_by.duplicate(), "budget": BUDGET_REDUCED if reduced else BUDGET, "cap": BIG_CAP_REDUCED if reduced else BIG_CAP}
