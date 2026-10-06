class_name VfxFlashRegistry
extends RefCounted
## The shared flash registry: one register in the hub that every full flash asks before it draws (Legal's condition for the public web build,
## docs/legal/photosensitivity-note.md; WCAG 2.2 criterion 2.3.1, "three flashes or below threshold"). A full flash is a filled or large bright pop (an energy landing's soft
## disc, an explosion's flame burst, a transformation's break flash) or a flash ring a sound effect would be paired with (a block's, a shot's hit, a guard break's). Hollow rings,
## thin lines and after-images are not flashes (docs/vfx/flash-registry.md has the table of every source and why).
##
## The rule: at most CAP (3) granted flashes in any window of 60 clock ticks (a second), across the whole screen, both fighters and every effect together. Low-priority sources
## (energy, block, shot hits, mines, a guard break's ring) get at most LOW_CAP (2) of the 3 so one is always left for the big events (an explosion, a transformation). With
## `reduced` (reduced motion, or the reduced-flashing setting) the cap is 1 and low-priority sources get none. A refused flash is not drawn in its flash form (the source
## draws its sparks, rings or lines instead: the table says which); nothing red is ever granted.
##
## The clock is the hub's own count of ticks (one per consume(), frozen ticks included), so a hit-stop does not stop the second. Every ask and every refusal is logged
## with its tick, so a tool can check recorded worst cases (`summary()`, `log_rows()`) and UI can read what is being refused.
## Presentation only: it reads nothing from the sim and draws no random number.

const WINDOW: int = 60
const CAP: int = 3
const CAP_REDUCED: int = 1
const LOW_CAP: int = 2
const LOG_MAX: int = 2400
## The sources that leave a slot free: everything a fight makes many of.
const LOW: Array = ["energy", "block", "shot_hit", "mine", "zip_break"]

var reduced: bool = false           # reduced motion or the reduced-flashing setting: set by the hub every tick
var now: int = 0                    # the clock, in ticks
var grants: Array = []              # the clock ticks of the flashes granted in the last WINDOW ticks
var log: Array = []                 # {now, tick, source, granted, why, in_window}, oldest first, at most LOG_MAX
var granted_by: Dictionary = {}
var refused_by: Dictionary = {}
var worst_second: int = 0           # the most granted flashes in any one window so far


func reset() -> void:
	reduced = false
	now = 0
	grants.clear()
	log.clear()
	granted_by.clear()
	refused_by.clear()
	worst_second = 0


## Once per consume(), first.
func begin_tick(p_reduced: bool) -> void:
	reduced = p_reduced
	now += 1
	while not grants.is_empty() and int(grants[0]) <= now - WINDOW:
		grants.pop_front()


static func is_red(c: Color) -> bool:
	return c.r > 0.55 and c.g < 0.45 * c.r and c.b < 0.45 * c.r


func in_window() -> int:
	return grants.size()


## Whether a flash of `source` may be drawn now (and if so it takes a slot). col is the flash's colour: a red one is never granted. tick is the sim tick, for the log only.
func ask(source: String, col: Color = Color.WHITE, tick: int = -1) -> bool:
	var low: bool = LOW.has(source)
	var cap: int = CAP_REDUCED if reduced else CAP
	var low_cap: int = 0 if reduced else LOW_CAP
	var why: String = "ok"
	var ok: bool = true
	if is_red(col):
		ok = false
		why = "red"
	elif grants.size() >= cap:
		ok = false
		why = "cap"
	elif low and grants.size() >= low_cap:
		ok = false
		why = "reduced" if reduced else "low_priority"
	_record(source, ok, why, tick)
	if ok:
		grants.append(now)
		worst_second = maxi(worst_second, grants.size())
	return ok


## A flash that another system draws and this one cannot refuse (Rendering's, until it asks): counted, never refused.
func note(source: String, tick: int = -1) -> void:
	_record(source, true, "unregulated", tick)
	grants.append(now)
	worst_second = maxi(worst_second, grants.size())


func _record(source: String, ok: bool, why: String, tick: int) -> void:
	if ok:
		granted_by[source] = int(granted_by.get(source, 0)) + 1
	else:
		refused_by[source] = int(refused_by.get(source, 0)) + 1
	log.append({"now": now, "tick": tick, "source": source, "granted": ok, "why": why, "in_window": grants.size() + (1 if ok else 0)})
	while log.size() > LOG_MAX:
		log.pop_front()


## The log as rows for a tool: [now, tick, source, granted, why, flashes in the window after this one].
func log_rows() -> Array:
	var out: Array = []
	for r in log:
		out.append([r["now"], r["tick"], r["source"], r["granted"], r["why"], r["in_window"]])
	return out


## The most granted flashes in any WINDOW-tick window of the log, counted from the log itself (not the running figure), and how many were refused.
func worst_from_log() -> int:
	var best: int = 0
	var ts: Array = []
	for r in log:
		if bool(r["granted"]):
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


func summary() -> Dictionary:
	var refused: int = 0
	for k in refused_by.keys():
		refused += int(refused_by[k])
	var granted: int = 0
	for k in granted_by.keys():
		granted += int(granted_by[k])
	return {"granted": granted, "refused": refused, "worst_second": worst_from_log(), "worst_running": worst_second, "granted_by": granted_by.duplicate(), "refused_by": refused_by.duplicate(), "cap": CAP_REDUCED if reduced else CAP}
