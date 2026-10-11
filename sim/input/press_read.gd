class_name SimPressRead
extends RefCounted
## The press reader for the "fight alchemist" (docs/controls/agency-input.md, 1a): from a short log of a fighter's attack
## presses it says whether the player is holding, tapping in time with the blows, mashing, or tapping deliberately, and
## what the running mix of attack types is. Pure functions over plain data: no state, no engine, no clock, no RNG, so the
## sim, the AI, QA and the tests all read a log the same way and a replay reproduces it. The log itself is the sim's state
## (Encounter and Simulation own it); this file only builds and reads it.
##
## A log is an Array of entries, oldest first, at most `logSize` long (20: the running mix; the recipe reads the latest `mixShort`, 5):
##   {kind: int (LIGHT, HEAVY, SIG, CONTEXT, PAIR), mode: int (0 physical, 1 energy), down: int tick, up: int tick or -1 while held,
##    beat: int, stance: int (the stance mask the press was made in, 0 martial; absent reads as 0)}
## and, when the director stamps them (brawl second pass, C2a), `ldown` and `lup`: the LIVE tick of the press and of its release
## (the clock that stops in a hit freeze, which the wind-ups and the burst count). Absent, every read falls back to `down` and `up`.
## `beat` is the signed distance in ticks from the press to the nearest blow contact of the running exchange (negative:
## early), or NO_BEAT outside one. A charged press (a hold at range or close) also carries `flash`: the tick the sim's
## charge flashed, or NO_FLASH; releasing on the flash is the timed release. The director stamps the PLANNED flash tick when
## the charge begins (a tick that may still be ahead), so a release before it reads as "early" rather than as no grade. All numbers are data (timing.json, the `read`
## block), whole ticks at 60 a second.
##
## Timing grades (docs/controls/agency-input.md 1a): a press or a release is "perfect" within beatHalf ticks of its mark, "good"
## within 2 * beatHalf, otherwise "off". A style's top level comes from perfect timing: a steady mash, three perfect presses in
## a row, or a hold released on the flash. The sim reads the grade; the damage, the blur and the guard break are Game Design's.
##
## Agency pass section 20 (2026-10-03): "steady" is on the beat, with no spacing test: the last steadyPresses presses are each
## within blurBeatHalf ticks of a DIFFERENT blow's contact (the contact is `down - beat`), consecutive in the log, so any press
## between them that is off a blow breaks it and two presses on one blow count once. It is immune to hit-stop (live contacts are a
## cadence plus 4 to 5 ticks apart, and a TRADE BLOWS opener lands 28 and 44 ticks apart) and to the opener's rhythm; a blind
## metronome is not steady because it is not on the blows. The window of presses lapses as a whole after expireTicks with no press
## (not press by press), and the recipe style (blur, combo, power)
## goes by the share of heavies among the presses present, so a lone heavy is a power blow.

const LIGHT: int = 0
const HEAVY: int = 1
const SIG: int = 2
const CONTEXT: int = 3   # A: the grab, the channel, the zip tackle (a press and a hold)
const PAIR: int = 4      # two adjacent face buttons pressed together (pair_commit): one press in the log
const NO_BEAT: int = 32767
## What the classifier and the zip's heavy reading count as a held X until the director's second pass (C2a) reads the burst: the old
## holdLight, 8. The burst itself starts at `burstStart` (16), which burst_read reads. Fold this into burstStart when C2a lands.
const LEGACY_LIGHT_HOLD: int = 8
const NO_FLASH: int = 32767

const DEFAULTS: Dictionary = {
	"logSize": 20,        # presses kept: the running mix reads 20, the recipe the latest 5 (agency-pass.md section 2)
	"holdTicks": 12,      # a button down this long is a hold (the number sprint and the channel use: tapHold.holdStart)
	"beatHalf": 4,        # a press within this many ticks of a blow's contact is on the beat (8-tick window)
	"touchBeatHalf": 5,   # the same on touch (10 ticks)
	"rhythmOf": 3,        # the last N presses ...
	"rhythmNeed": 2,      # ... of which this many on the beat are rhythm
	"mashPresses": 4,     # this many presses ...
	"mashGap": 10,        # ... with every gap this many ticks or fewer are a mash
	"mashClear": 20,      # a mash is over after this many ticks without a press
	"staleTicks": 60,     # a log older than this reads as nothing
	"mixShort": 5,        # the short mix window: the latest presses the recipe reads
	"expireTicks": 90,    # the whole window lapses after this many ticks with no press (section 20)
	"powerShare": 60,     # heavies over this percent of the presses present make the power style; up to it, combo; none, blur
	"steadyPresses": 4,   # a steady mash is this many presses in a row, evenly spaced and on the beat (section 20: four)
	"blurBeatHalf": 2,    # each within this many ticks of a blow's contact (the combo's timed press is beatHalf, 4)
	"blurBeatBonus": 0,   # added on touch or at 30 fps ("slow"); 0 by ruling (two more ticks would cover a whole 7-tick beat)
	"assistFactor": 2,    # accessibility: the beat window doubles
	"perfectStreak": 3,   # this many perfect presses in a row make a timed string
	"zipMashPresses": 3,  # a zip has three hits: the starter and two more presses make its speed reading
	"zipMashGap": 10,     # ... each within this many ticks of the one before
	"burstStart": 16,     # a light held this many live ticks starts the burst: the same line as Y's and A's hold (brawl second pass section 3)
	"windupMedium": 12,   # Y: a tap lands when this wind-up ends; still down at wind-up + grace it is the charged medium
	"windupHeavy": 28,    # B in the martial stance: the heavy's wind-up
	"windupContext": 12,  # A: the shove's wind-up; held to wind-up + grace it is the tackle's coil
	"windupGrace": 4,     # a release in this many ticks after the wind-up's end is still a tap (every device)
	"pairWindow": 3,      # two adjacent face buttons within this many ticks are one press (doubled by the assist setting)
	"pairFresh": 8,       # ... and neither was pressed in the ticks before
	"flurryGapX": 12,     # the pace of each flurry: a press of the same button within this many ticks continues it
	"flurryGapY": 16,
	"flurryGapB": 34,
	"flurryNeedSlow": 2,  # presses that make a Y or B flurry (X is mashPresses)
	"mixupSwitches": 2,   # button changes in one chain that make a mix-up (X Y X)
	"simpleMediumStart": 12,   # the Simple layout: the hold is the wind-up; from this many live ticks the release is the medium ...
	"simpleHeavyStart": 28,    # ... and from this many the heavy
}


## The numbers, from data over the defaults.
static func params() -> Dictionary:
	var p: Dictionary = DEFAULTS.duplicate()
	for k in DEFAULTS:
		p[k] = SimInputData.ti(["read", k], int(DEFAULTS[k]))
	p["holdTicks"] = SimInputData.ti(["read", "holdTicks"], SimInputData.ti(["tapHold", "holdStart"], int(DEFAULTS["holdTicks"])))
	return p


## A new press at `tick`. Trims the log to `logSize` and returns it. `beat_offset` is NO_BEAT outside an exchange.
static func push(log: Array, kind: int, mode: int, tick: int, beat_offset: int = NO_BEAT, size: int = -1, stance: int = 0, live: int = -1, latched: bool = false) -> Array:
	var n: int = size if size > 0 else SimInputData.ti(["read", "logSize"], int(DEFAULTS["logSize"]))
	if not latched:
		# A fresh press edge on a button the log still has held means "released, then pressed": a release and a re-press inside one
		# hit freeze reach the sim as the level unchanged and one new edge (docs/controls/windup-read.md, section 1). The old press
		# is let go at the point the new one is read. Not on a latched button, where the next press IS the release and sends no edge.
		release(log, kind, tick, live)
	var e: Dictionary = {"kind": kind, "mode": mode, "down": tick, "up": -1, "beat": beat_offset, "flash": NO_FLASH, "stance": stance}
	if live >= 0:
		e["ldown"] = live
	log.append(e)
	while log.size() > n:
		log.pop_front()
	return log


## The button of `kind` was released at `tick` (and at live tick `live`, when the caller keeps one): closes the latest still-held
## entry of that kind.
static func release(log: Array, kind: int, tick: int, live: int = -1) -> void:
	for k in range(log.size() - 1, -1, -1):
		var e: Dictionary = log[k]
		if int(e["kind"]) == kind and int(e["up"]) < 0:
			e["up"] = tick
			if live >= 0:
				e["lup"] = live
			return


## The charge of the latest still-held entry of `kind` flashes at `tick`: the sim's planned tick, stamped when the charge begins.
static func set_flash(log: Array, kind: int, tick: int) -> void:
	for k in range(log.size() - 1, -1, -1):
		var e: Dictionary = log[k]
		if int(e["kind"]) == kind and int(e["up"]) < 0:
			e["flash"] = tick
			return


## The grade of a distance from a mark: "perfect" within the window's half, "good" within twice that, else "off". `opts` as
## classify's (touch, assist, offset, p).
static func grade_of(distance: int, opts: Dictionary = {}) -> String:
	var p: Dictionary = opts.get("p", params())
	var half: int = _half(p, opts)
	var d: int = absi(distance - int(opts.get("offset", 0)))
	if d <= half:
		return "perfect"
	if d <= half * 2:
		return "good"
	return "off"


## How a charged press was let go: "perfect" released on the flash, "good" near it, "early" before the good window, "late"
## after it, "held" if the button is still down, "none" if the entry has no flash. The beat window and its touch, assist
## and offset rules apply; the release is measured from the flash, so a player's offset shifts it like any press.
static func release_grade(entry: Dictionary, opts: Dictionary = {}) -> String:
	if int(entry.get("flash", NO_FLASH)) == NO_FLASH:
		return "none"
	if int(entry["up"]) < 0:
		return "held"
	var d: int = int(entry["up"]) - int(entry["flash"])
	var g: String = grade_of(d, opts)
	if g != "off":
		return g
	return "early" if d - int(opts.get("offset", 0)) < 0 else "late"


## The wind-up of this entry's button, in live ticks (brawl second pass sections 2 to 4): Y the medium 12, B the heavy 28 (martial stance
## only: in the other stances B is that stance's own signature, whose hold is the director's), A the shove 12, in any stance. -1 for
## a button with no wind-up: X (a tap is instant and a hold is the burst), PAIR, and B outside the martial stance. Y keeps its 12 in
## the energy stance (RB + Y, the blast).
static func windup_for(entry: Dictionary, p: Dictionary = {}) -> int:
	var q: Dictionary = p if not p.is_empty() else params()
	var stance: int = int(entry.get("stance", 0))
	match int(entry.get("kind", LIGHT)):
		HEAVY: return int(q["windupMedium"]) if (stance & 4) == 0 else -1
		SIG: return int(q["windupHeavy"]) if stance == 0 else -1
		CONTEXT: return int(q["windupContext"])
	return -1


## Where a tap ends and a charge begins: the wind-up plus the grace (Y 16, B 32, A 16), in live ticks from the press. -1 for a
## button with no wind-up.
static func decision_for(entry: Dictionary, p: Dictionary = {}) -> int:
	var q: Dictionary = p if not p.is_empty() else params()
	var w: int = windup_for(entry, q)
	return -1 if w < 0 else w + int(q["windupGrace"])


## How long a button of this entry must be down to count as held (the classifier's `hold` style, the zip's heavy): the decision point
## for a button with a wind-up, 8 for X (LEGACY_LIGHT_HOLD: the burst's start, burstStart, is read by burst_read), and the game's hold
## for the rest (a stance's own signature).
## `opts.hold_ticks` overrides it for every cell (a caller with its own rule).
static func hold_ticks_for(entry: Dictionary, p: Dictionary, opts: Dictionary = {}) -> int:
	if opts.has("hold_ticks"):
		return int(opts["hold_ticks"])
	if int(entry.get("kind", LIGHT)) == LIGHT:
		return LEGACY_LIGHT_HOLD
	var d: int = decision_for(entry, p)
	return d if d >= 0 else int(p["holdTicks"])


## The ticks an entry has been down: on the live clock when it carries `ldown` (a still-held press runs to `live_now`, a released one
## to its `lup`), else on the real clock (`now`, `up`).
static func held_ticks(entry: Dictionary, now: int, live_now: int = -1) -> int:
	if entry.has("ldown") and (int(entry["up"]) < 0 or entry.has("lup")):
		var lend: int = int(entry["lup"]) if int(entry["up"]) >= 0 else (live_now if live_now >= 0 else now)
		return lend - int(entry["ldown"])
	var end: int = int(entry["up"]) if int(entry["up"]) >= 0 else now
	return end - int(entry["down"])


## The read of a slow button (Y, B, A) at the wind-up's end (docs/controls/windup-read.md): "winding" while it is down before the
## decision point, "tap" if it was let go at or before wind-up plus grace live ticks (the blow lands when the wind-up ends, or at the
## release if that is later: tap_throw_at), "charge" if it is still down at the decision point or was let go after it. "none" for a
## button with no wind-up (X, and B outside the martial stance). `live_now` is the director's live tick.
static func charge_read(entry: Dictionary, live_now: int, p: Dictionary = {}) -> String:
	var q: Dictionary = p if not p.is_empty() else params()
	var dec: int = decision_for(entry, q)
	if dec < 0:
		return "none"
	var held: int = held_ticks(entry, live_now, live_now)
	if int(entry["up"]) >= 0:
		return "tap" if held <= dec else "charge"
	return "winding" if held < dec else "charge"


## The live tick a tap's blow is thrown: when its wind-up ends, or at its release if that came after the wind-up's end (inside the
## grace). -1 unless the entry is a tap. The press must carry `ldown` (and the release `lup`).
static func tap_throw_at(entry: Dictionary, p: Dictionary = {}) -> int:
	var q: Dictionary = p if not p.is_empty() else params()
	if charge_read(entry, 0, q) != "tap":
		return -1
	var start: int = int(entry.get("ldown", entry["down"]))
	var end: int = int(entry["lup"]) if entry.has("lup") else int(entry["up"])
	return maxi(start + windup_for(entry, q), end)


## The burst on a held X (section 3): the press was an instant light; from `burstStart` live ticks down more blows follow by
## themselves. {held, ready, since, stance}: how long it has been down, whether the burst is on, how many live ticks past its start,
## and the stance it was pressed in (the director decides what a held X is outside the martial stance: at range, in the energy
## stance, it is the volley). The burst's lights are the director's: not pushed to the log, never graded for timing, not counted as
## mash. Letting go (the entry's `up`) ends it.
static func burst_read(entry: Dictionary, live_now: int, p: Dictionary = {}) -> Dictionary:
	var q: Dictionary = p if not p.is_empty() else params()
	if int(entry.get("kind", LIGHT)) != LIGHT:
		return {"held": 0, "ready": false, "since": 0, "stance": int(entry.get("stance", 0))}
	var held: int = held_ticks(entry, live_now, live_now)
	var ready: bool = int(entry["up"]) < 0 and held >= int(q["burstStart"])
	return {"held": held, "ready": ready, "since": maxi(0, held - int(q["burstStart"])) if ready else 0, "stance": int(entry.get("stance", 0))}


## The reading of a zip (docs/controls/lunge-control.md B6.4): "plain", "speed", "tech" or "heavy". The starter is the press made at
## `zip_start` (the press that began the zip); `arrival` is the tick of the zip's first contact (NO_BEAT if not known yet). Precedence
## is the classifier's: hold, then timed, then mashed.
##   heavy: the starter button is down for its cell's hold ticks (still down at `now` counts);
##   tech: the starter is within beatHalf of a blow's contact (its `beat`), or a later press is within beatHalf of `arrival`;
##   speed: the starter and `zipMashPresses` minus one more presses, each within `zipMashGap` ticks of the one before.
## `opts` as classify's (touch, assist, offset, p).
static func zip_read(log: Array, now: int, zip_start: int, arrival: int, opts: Dictionary = {}) -> String:
	var p: Dictionary = opts.get("p", params())
	var si: int = -1
	for k in range(log.size()):
		if int(log[k]["down"]) == zip_start:
			si = k
	if si < 0:
		return "plain"
	var st: Dictionary = log[si]
	# Heavy: the starter is a charge (still down at wind-up plus grace, or let go after it), on the live clock when the log carries it.
	# X, which has no wind-up, is a heavy zip as before when held for the burst's start.
	var live_now: int = int(opts.get("live_now", now))
	var hs: int = held_ticks(st, now, live_now)
	var released: bool = int(st["up"]) >= 0
	var thr: int = hold_ticks_for(st, p, opts)
	# A release AT the decision point is a tap only for a log that carries live ticks (the director's C2a log); an unstamped log (today's)
	# keeps the old rule, where a press held for the number of ticks counts, so nothing live changes before the director stamps its log.
	var new_rule: bool = released and st.has("ldown") and windup_for(st, p) >= 0 and not opts.has("hold_ticks")
	if (hs > thr) if new_rule else (hs >= thr):
		return "heavy"
	var half: int = _half(p, opts)
	var shift: int = int(opts.get("offset", 0))
	var b: int = int(st["beat"])
	if b != NO_BEAT and absi(b - shift) <= half:
		return "tech"
	if arrival != NO_BEAT:
		for k in range(si + 1, log.size()):
			if absi(int(log[k]["down"]) - arrival - shift) <= half:
				return "tech"
	var chain: int = 1
	var prev: int = int(st["down"])
	for k in range(si + 1, log.size()):
		var d: int = int(log[k]["down"])
		if d - prev <= int(p["zipMashGap"]):
			chain += 1
			prev = d
		else:
			break
	if chain >= int(p["zipMashPresses"]):
		return "speed"
	return "plain"


## The four pairs are the diamond's edges (docs/controls/q19-input.md section 2; X is LIGHT, Y HEAVY, B SIG, A CONTEXT): X+Y, X+A, Y+B,
## A+B. X+B and Y+A cross the pad and are not pairs. Keyed by the two kinds, smaller first.
const _PAIRS: Dictionary = {"01": "xy", "03": "xa", "12": "yb", "23": "ab"}


static func _kinds_of(e: Dictionary) -> Array:
	return e["cells"] if int(e["kind"]) == PAIR else [int(e["kind"])]


## Whether the last two presses in the log are a pair (brawl second pass section 6): adjacent face buttons within `pairWindow` ticks
## (doubled by `opts.assist`), both FRESH (neither button, nor a pair that used it, pressed in the `pairFresh` ticks before the
## first), neither already part of a pair, and not made under RT (no pairs under the charging stance). The first press is never
## delayed: it has been thrown as its own blow, and a LIGHT pressed first is kept (`keep_light`: it lands 2 ticks after its press, its
## damage stands); a Y, B or A pressed first has only just begun its wind-up, which the pair replaces. Returns {} when there is no
## pair, else {pair: "xy" | "xa" | "yb" | "ab", first, second (kinds), t1, t2 (the graded ticks), keep_light, stance}. No intent
## bit: the edges are the intent's own (light, heavy, sig, context).
static func pair_read(log: Array, opts: Dictionary = {}) -> Dictionary:
	if log.size() < 2:
		return {}
	var p: Dictionary = opts.get("p", params())
	var e2: Dictionary = log[log.size() - 1]
	var e1: Dictionary = log[log.size() - 2]
	if e1.get("paired", false) or e2.get("paired", false):
		return {}
	var k1: int = int(e1["kind"])
	var k2: int = int(e2["kind"])
	if k1 == k2 or k1 > CONTEXT or k2 > CONTEXT:
		return {}
	var key: String = "%d%d" % [mini(k1, k2), maxi(k1, k2)]
	if not _PAIRS.has(key):
		return {}
	if ((int(e1.get("stance", 0)) | int(e2.get("stance", 0))) & 4) != 0:
		return {}
	var window: int = int(p["pairWindow"]) * (int(p["assistFactor"]) if opts.get("assist", false) else 1)
	var gap: int = int(e2["down"]) - int(e1["down"])
	if gap < 0 or gap > window:
		return {}
	for k in range(log.size() - 2):
		var prev: Dictionary = log[k]
		var kinds: Array = _kinds_of(prev)
		if (kinds.has(k1) or kinds.has(k2)) and int(e1["down"]) - int(prev["down"]) < int(p["pairFresh"]):
			return {}
	return {"pair": _PAIRS[key], "first": k1, "second": k2, "t1": int(e1["down"]), "t2": int(e2["down"]), "keep_light": k1 == LIGHT, "stance": int(e2.get("stance", 0))}


## A pair is ONE press in the log: replaces the last two entries (the ones pair_read found) with a PAIR entry carrying the pair's
## code and the two kinds, counted once in the mix and in a mash. Does nothing for an empty read.
static func pair_commit(log: Array, pr: Dictionary) -> void:
	if pr.is_empty() or log.size() < 2:
		return
	var e1: Dictionary = log[log.size() - 2]
	var e2: Dictionary = log[log.size() - 1]
	log.resize(log.size() - 2)
	var up: int = -1 if (int(e1["up"]) < 0 or int(e2["up"]) < 0) else maxi(int(e1["up"]), int(e2["up"]))
	var e: Dictionary = {"kind": PAIR, "mode": int(e2["mode"]), "down": int(e1["down"]), "up": up, "beat": NO_BEAT, "flash": NO_FLASH, "stance": int(e2.get("stance", 0)),
			"pair": str(pr["pair"]), "cells": [int(pr["first"]), int(pr["second"])], "t2": int(pr["t2"])}
	if e1.has("ldown"):
		e["ldown"] = int(e1["ldown"])
	log.append(e)


## The pace of each button's flurry: the longest gap that still continues it (X 12, Y 16, B 34; brawl second pass section 2).
static func flurry_gap(kind: int, p: Dictionary = {}) -> int:
	var q: Dictionary = p if not p.is_empty() else params()
	match kind:
		LIGHT: return int(q["flurryGapX"])
		HEAVY: return int(q["flurryGapY"])
		SIG: return int(q["flurryGapB"])
	return int(q["mashGap"])


## Whether the presses of ONE button are a flurry: {mash, presses, gap, going}. `presses` counts the latest run of this kind with
## every gap within the button's pace; `going` is whether the last is within that pace of `now`; `mash` is going with at least
## `mashPresses` presses (X) or `flurryNeedSlow` (Y, B). Other buttons in between do not break it: a Y flurry with a light thrown
## between its blows is still a Y flurry.
static func mash_of(log: Array, kind: int, now: int, opts: Dictionary = {}) -> Dictionary:
	var p: Dictionary = opts.get("p", params())
	var gap: int = flurry_gap(kind, p)
	var same: Array = []
	for e in log:
		if int(e["kind"]) == kind:
			same.append(e)
	if same.is_empty():
		return {"mash": false, "presses": 0, "gap": 0, "going": false}
	var n: int = 1
	var last_gap: int = 0
	var k: int = same.size() - 1
	while k > 0:
		var g: int = int(same[k]["down"]) - int(same[k - 1]["down"])
		if g > gap:
			break
		if n == 1:
			last_gap = g
		n += 1
		k -= 1
	var going: bool = now - int(same[same.size() - 1]["down"]) <= gap
	var need: int = int(p["mashPresses"]) if kind == LIGHT else int(p["flurryNeedSlow"])
	return {"mash": going and n >= need, "presses": n, "gap": last_gap, "going": going}


## The mix-up (section 2: "the three in any order"): the latest chain of X, Y and B presses where each press came within the
## PREVIOUS press's button's pace of the next (an X within 12, a Y within 16, a B within 34), and the chain is still going at `now`.
## {presses, switches (changes of button along it), kinds (bits: X 1, Y 2, B 4), mixup (switches >= mixupSwitches)}.
## `opts.n` caps the chain (8). With `opts.count_mode` a change of mode (fist to bolt: the energy arts in reach, section 5b) counts as a
## switch too, so "punches and bolts" read as a mix-up of two instruments although every press is an X.
static func alternation(log: Array, now: int, opts: Dictionary = {}) -> Dictionary:
	var p: Dictionary = opts.get("p", params())
	var cap: int = int(opts.get("n", 8))
	var out: Dictionary = {"presses": 0, "switches": 0, "kinds": 0, "mixup": false}
	if log.is_empty():
		return out
	var last: Dictionary = log[log.size() - 1]
	var lk: int = int(last["kind"])
	if lk > SIG or now - int(last["down"]) > flurry_gap(lk, p):
		return out
	var presses: int = 1
	var switches: int = 0
	var kinds: int = 1 << lk
	var i: int = log.size() - 2
	while i >= 0 and presses < cap:
		var prev: Dictionary = log[i]
		var cur: Dictionary = log[i + 1]
		var pk: int = int(prev["kind"])
		if pk > SIG or int(cur["down"]) - int(prev["down"]) > flurry_gap(pk, p):
			break
		presses += 1
		kinds |= 1 << pk
		if pk != int(cur["kind"]) or (opts.get("count_mode", false) and int(prev["mode"]) != int(cur["mode"])):
			switches += 1
		i -= 1
	out["presses"] = presses
	out["switches"] = switches
	out["kinds"] = kinds
	out["mixup"] = switches >= int(p["mixupSwitches"])
	return out


## A's three readings (section 4), on the live clock: {read, held, taps, since, throw_at, frac}.
##   "none":    no press of A in the log;
##   "winding": the latest A is down inside the shove's wind-up (12 live ticks): nothing is decided yet;
##   "shove":   it was let go by the wind-up's end or inside its grace: the shove goes (`throw_at`, the live tick);
##   "coil":    still down at wind-up plus grace (16): he coils for the tackle, no shove is thrown. `since` is the live ticks past the
##              decision and `frac` the coil's share of the way to full (`opts.coil_full`, the tackle's full-coil tick, 36);
##   "clinch":  a SECOND press of A inside the first's wind-up turns the shove into the reach for a clinch (the shove is not thrown).
##              `taps` counts the presses after the second within `opts.clinch_max` (45) live ticks of the first (the vicious blows);
##              `since` runs from the second press.
## The press log entries carry `ldown` (and `lup`) when the director stamps them; without them the real ticks stand in.
static func a_read(log: Array, live_now: int, opts: Dictionary = {}) -> Dictionary:
	var p: Dictionary = opts.get("p", params())
	var out: Dictionary = {"read": "none", "held": 0, "taps": 0, "since": 0, "throw_at": -1, "frac": 0.0}
	var runs: Array = []
	for e in log:
		if int(e["kind"]) == CONTEXT:
			runs.append(e)
	if runs.is_empty():
		return out
	var last: Dictionary = runs[runs.size() - 1]
	var clinch_max: int = int(opts.get("clinch_max", 45))
	var lv: Callable = func(e: Dictionary) -> int: return int(e.get("ldown", e["down"]))
	var start: int = runs.size() - 1
	while start > 0 and lv.call(last) - lv.call(runs[start - 1]) <= clinch_max:
		start -= 1
	var w: int = int(p["windupContext"])
	if runs.size() - start >= 2:
		var first: Dictionary = runs[start]
		var second: Dictionary = runs[start + 1]
		if lv.call(second) - lv.call(first) < w:
			out["read"] = "clinch"
			out["taps"] = runs.size() - start - 2
			out["since"] = live_now - lv.call(second)
			out["held"] = held_ticks(last, live_now, live_now)
			return out
	out["held"] = held_ticks(last, live_now, live_now)
	match charge_read(last, live_now, p):
		"winding":
			out["read"] = "winding"
		"tap":
			out["read"] = "shove"
			out["throw_at"] = tap_throw_at(last, p)
		"charge":
			out["read"] = "coil"
			var dec: int = decision_for(last, p)
			out["since"] = int(out["held"]) - dec
			var full: int = int(opts.get("coil_full", 36))
			out["frac"] = clampf(float(int(out["held"]) - dec) / maxf(1.0, float(full - dec)), 0.0, 1.0)
	return out


static func _half(p: Dictionary, opts: Dictionary) -> int:
	var half: int = int(p["touchBeatHalf"]) if opts.get("touch", false) else int(p["beatHalf"])
	if opts.get("assist", false):
		half *= int(p["assistFactor"])
	return half


## Signed distance from `tick` to the nearest of `blows` (contact ticks), tick minus blow, NO_BEAT if there are none.
static func beat_offset(tick: int, blows: Array) -> int:
	var best: int = NO_BEAT
	for b in blows:
		var d: int = tick - int(b)
		if best == NO_BEAT or absi(d) < absi(best):
			best = d
	return best


## Read a log at tick `now`. `opts`: touch (bool, the wider beat window), assist (bool, the doubled one), offset (int, the
## player's timing offset in ticks, -6 to 6: it shifts where the beat is for them), p (a params dictionary, for tests).
## `slow` (bool) is a 30 fps client: the blur's beat gets blurBeatBonus ticks more, as on touch (0 now: no extra tolerance).
## Returns {style, hold_ticks, on_beat, presses, mix_short, mix_long, recipe, rate}:
##   style: "none" (nothing recent), "hold", "rhythm", "mash" or "taps";
##   timing: "perfect" (a timed string: a steady mash, a run of perfect presses, or the last release on the flash), "good" (some
##     timing: a perfect press or a good release) or "none";
##   streak: perfect presses in a row ending at the latest; steady: the last steadyPresses presses are each within blurBeatHalf
##     ticks of a different blow's contact, consecutive, with no spacing test (any style: it makes timing perfect);
##   release: the grade of the latest released charge ("none" if there is none);
##   hold_ticks: how long the held button has been down (0 if none held);
##   on_beat: how many of the last `rhythmOf` presses were on the beat;
##   mix_short / mix_long: {light, heavy, sig, energy} counts over the last `mixShort` and `logSize` presses; the whole window is
##     empty once `expireTicks` (90) have passed with no press;
##   recipe: the string's style from the share of heavies among the presses present in mix_short: "none" (no press present),
##     "blur" (no heavy), "combo" (heavies up to powerShare percent) or "power" (over it). With five presses present: none is
##     blur, one to three combo, four or five power; a lone heavy is power;
##   rate: presses a second over the latest `mixShort` presses (0 with fewer than two); for display only.
## Precedence: hold, then rhythm, then mash, then taps. A mash that lands on the blows is rhythm.
static func classify(log: Array, now: int, opts: Dictionary = {}) -> Dictionary:
	var p: Dictionary = opts.get("p", params())
	var lapsed: bool = log.is_empty() or now - int(log[log.size() - 1]["down"]) > int(p["expireTicks"])
	var ms: Dictionary = _mix(log, int(p["mixShort"]), lapsed)
	var out: Dictionary = {"style": "none", "timing": "none", "streak": 0, "steady": false, "release": "none", "hold_ticks": 0, "on_beat": 0, "presses": 0 if lapsed else log.size(), "mix_short": ms, "mix_long": _mix(log, int(p["logSize"]), lapsed), "recipe": _recipe(ms, int(p["powerShare"])), "rate": 0.0}
	if log.is_empty():
		return out
	var last: Dictionary = log[log.size() - 1]
	# The latest released charge's grade, whatever its age (the sim reads it at the release).
	for k in range(log.size() - 1, -1, -1):
		var g: String = release_grade(log[k], opts)
		if g != "none" and g != "held":
			out["release"] = g
			break
	# A held button is a hold from holdTicks on, however old the log is.
	for k in range(log.size() - 1, -1, -1):
		var e: Dictionary = log[k]
		if int(e["up"]) < 0:
			var held: int = now - int(e["down"])
			out["hold_ticks"] = held
			if held >= hold_ticks_for(e, p, opts):
				out["style"] = "hold"
				out["timing"] = "perfect" if out["release"] == "perfect" else ("good" if out["release"] == "good" else "none")
				return out
			break
	if now - int(last["down"]) > int(p["staleTicks"]):
		return out
	out["rate"] = _rate(log, int(p["mixShort"]))
	# Rhythm: the player is watching the blows.
	var half: int = _half(p, opts)
	var shift: int = int(opts.get("offset", 0))
	# Steady (section 20, the EP's ruling): the last steadyPresses presses, consecutive in the log, each within the blur's tolerance
	# of a DIFFERENT blow's contact (`down - beat`). No spacing test and no gap cap, so hit-stop and the opener's rhythm do not
	# matter; an off-beat press among them breaks it; two presses on one blow count once.
	var sneed: int = int(p["steadyPresses"])
	var bhalf: int = int(p["blurBeatHalf"])
	if opts.get("touch", false) or opts.get("slow", false):
		bhalf += int(p["blurBeatBonus"])
	if opts.get("assist", false):
		bhalf *= int(p["assistFactor"])
	if log.size() >= sneed:
		var contacts: Array = []
		var on_blows: bool = true
		for k in range(log.size() - sneed, log.size()):
			var bb: int = int(log[k]["beat"])
			if bb == NO_BEAT or absi(bb - shift) > bhalf:
				on_blows = false
				break
			var contact: int = int(log[k]["down"]) - bb
			if contacts.has(contact):
				on_blows = false   # a second press on the same blow
				break
			contacts.append(contact)
		if on_blows:
			out["steady"] = true
	var of: int = mini(int(p["rhythmOf"]), log.size())
	var on: int = 0
	for k in range(log.size() - of, log.size()):
		var b: int = int(log[k]["beat"])
		if b != NO_BEAT and absi(b - shift) <= half:
			on += 1
	out["on_beat"] = on
	# Perfect presses in a row, from the latest back.
	var streak: int = 0
	for k in range(log.size() - 1, -1, -1):
		var b2: int = int(log[k]["beat"])
		if b2 != NO_BEAT and absi(b2 - shift) <= half:
			streak += 1
		else:
			break
	out["streak"] = streak
	var any_perfect: bool = false
	for k in range(maxi(0, log.size() - of), log.size()):
		var b3: int = int(log[k]["beat"])
		if b3 != NO_BEAT and absi(b3 - shift) <= half:
			any_perfect = true
	if on >= int(p["rhythmNeed"]):
		out["style"] = "rhythm"
		out["timing"] = "perfect" if (streak >= int(p["perfectStreak"]) or out["steady"]) else "good"
		return out
	# Mash: the last mashPresses presses all close together, and still going.
	var need: int = int(p["mashPresses"])
	if log.size() >= need and now - int(last["down"]) <= int(p["mashClear"]):
		var fast: bool = true
		for k in range(log.size() - need + 1, log.size()):
			if int(log[k]["down"]) - int(log[k - 1]["down"]) > int(p["mashGap"]):
				fast = false
				break
		if fast:
			out["style"] = "mash"
			out["timing"] = "perfect" if out["steady"] else ("good" if any_perfect else "none")
			return out
	out["style"] = "taps"
	out["timing"] = "good" if any_perfect else "none"
	return out


static func _mix(log: Array, n: int, lapsed: bool) -> Dictionary:
	var m: Dictionary = {"light": 0, "heavy": 0, "sig": 0, "context": 0, "energy": 0}
	if lapsed:
		return m
	for k in range(maxi(0, log.size() - n), log.size()):
		match int(log[k]["kind"]):
			LIGHT: m["light"] += 1
			HEAVY: m["heavy"] += 1
			SIG: m["sig"] += 1
			CONTEXT: m["context"] += 1
			PAIR: m["pair"] = int(m.get("pair", 0)) + 1
		if int(log[k]["mode"]) == 1:
			m["energy"] += 1
	return m


## The string's style from the share of heavies among the presses present: "none" with no press, "blur" with no heavy, "combo"
## up to powerShare percent heavies, "power" over it. Integer arithmetic, so no float decides a style.
static func _recipe(m: Dictionary, power_share: int) -> String:
	var n: int = int(m["light"]) + int(m["heavy"]) + int(m["sig"])
	if n == 0:
		return "none"
	var h: int = int(m["heavy"])
	if h == 0:
		return "blur"
	return "power" if h * 100 > power_share * n else "combo"


static func _rate(log: Array, n: int) -> float:
	var first: int = maxi(0, log.size() - n)
	if log.size() - first < 2:
		return 0.0
	var span: int = int(log[log.size() - 1]["down"]) - int(log[first]["down"])
	if span <= 0:
		return 0.0
	return float(log.size() - first - 1) * 60.0 / float(span)
