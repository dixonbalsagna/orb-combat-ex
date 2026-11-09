class_name SimInputData
## The input scheme's data (docs/controls/input-schema.md): the action list, the presets and every tick value, loaded
## once from res://data/input/. The layout layer (layout.gd, touch.gd, hub.gd) reads its numbers from here and never
## from code. If the files are missing (a headless tool run from a copy without them) the built-in copy of the shipped
## values is used, so a test or a batch plays the same without the data folder.
##
## load_and_apply() also sets SimAct's three statics from this data, as intent-v2.md section 6c asks.

const DIR: String = "res://data/input/"

## The shipped timing.json, as a fallback. Keep it equal to the file; sim/input/test/hub_test.gd checks that it is.
const DEFAULT_TIMING: Dictionary = {
	"schema": 1, "ticksPerSecond": 60,
	"tapHold": {"holdStart": 12, "transformConfirm": 30, "encoreConfirm": 18, "encoreOffer": 180, "chordWindow": 6},
	"perfectBlock": {"lightWindow": 8, "heavyWindow": 10, "buffer": 4, "touchBufferBonus": 2, "antiMashLockout": 20, "assistFactor": 2},
	"dodge": {"buffer": 4, "stateTicks": 12},
	"attackQueue": {"max": 3, "expiry": 36, "upgradeWindow": 24, "heavyKi": 4, "signatureKi": 45},
	"mode": {"toggleCooldown": 12},
	"touch": {"flickToDodgeTicks": 6, "flickThreshold": 0.7, "outerRingScale": 1.3, "outerRingHold": 6, "fullDeflectionSprint": 30, "swipeUpPx": 40, "swipeUpTicks": 24, "edgeIgnoreDp": 8},
	"stick": {"deadzone": 0.2, "quant": 16, "triggerOn": 0.35, "triggerOff": 0.25, "awayDead": 0.3},
}

## Values the schema does not carry (dodge.lungeTicks, stick.fullAt are code defaults until it does), and the last
## fallback for any key a data file lacks.
const EXTRA: Dictionary = {
	"chordWindow": 6,     # two triggers down within this many ticks are the transform chord
	"stateTicks": 12,     # a dodge reads as the Dodge state for this long (SimAct.dodgeWindow)
	"lungeTicks": 12,     # the dash that goes with a dodge until the director moves the fighter itself
	"awayDead": 0.3,      # SimAct.awayDead
	"fullAt": 0.9,        # a stick reaches full speed at this fraction of its travel
}

## Presets that were removed, and the preset a saved choice of them becomes (the Brawler's attacks sat on RB and RT, which are
## stance buttons now: a fighting-game player remaps Arena). A saved remap of a retired preset is dropped.
const RETIRED: Dictionary = {"brawler": "arena"}

static var timing: Dictionary = {}
static var stances: Dictionary = {}     # data/input/stances.json: the enabled hybrid masks
static var presets: Dictionary = {}
static var actions: Dictionary = {}
static var loaded: bool = false
## Bumped by every load_data() and by invalidate(). A reader that keeps a copy of what it built from this data (SimPressRead.params,
## SimAim.params) keeps it only while this number is the one it was built at.
static var revision: int = 0
## The players' remaps, one layer per slot: overrides[slot][preset id] -> the override entries (SimInputRemap). Two players
## on the same preset each have their own.
static var overrides: Array = [{}, {}]
static var _merged: Array = [{}, {}]


## Read the three files. True if they were found; the defaults stand in otherwise. Safe to call more than once.
static func load_data(dir: String = DIR) -> bool:
	var ok := true
	var t = _read(dir + "timing.json")
	if t is Dictionary:
		timing = t
	else:
		timing = DEFAULT_TIMING.duplicate(true)
		ok = false
	var l = _read(dir + "layouts.json")
	presets = {}
	if l is Dictionary and l.has("presets"):
		for p in l["presets"]:
			presets[str(p["id"])] = p
	else:
		ok = false
	_derive_swapped()
	var st = _read(dir + "stances.json")
	stances = st if st is Dictionary else {"schema": 1, "hybrids": []}
	var a = _read(dir + "actions.json")
	actions = {}
	if a is Dictionary and a.has("actions"):
		for x in a["actions"]:
			actions[str(x["id"])] = x
	loaded = true
	revision += 1
	return ok


## Throw away every reader's kept copy. A load does it already; call this after changing a section of `timing` IN PLACE (a section
## replaced by a new dictionary is noticed by the readers on their own).
static func invalidate() -> void:
	revision += 1


## The hybrid stance masks switched on in data/input/stances.json (LT+RB 10, LB+RB 3, LT+LB 9). None until Game Design ships one:
## until then a held pair reads as its newer button (SimStance).
static func hybrids() -> Array:
	ensure()
	var out: Array = []
	for m in stances.get("hybrids", []):
		out.append(int(m))
	if right_stick_on():   # the right-hand attacks bring the lay (LB+RB 3) and the kite (LT+RB 10) with them; the terrain hybrid (9) stays off
		for m in stances.get("withRightStick", [3, 10]):
			if not out.has(int(m)):
				out.append(int(m))
	return out


## A preset id with a retired one mapped to its replacement (the Brawler to Arena); any other id comes back unchanged.
static func migrate(id: String) -> String:
	return str(RETIRED.get(id, id))


static func _read(path: String):
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func ensure() -> void:
	if not loaded:
		load_data()


## One timing value by path, for example t(["tapHold", "holdStart"]); the built-in values and EXTRA back it up.
static func t(path: Array, fallback = null):
	ensure()
	var cur = timing
	for k in path:
		if cur is Dictionary and cur.has(k):
			cur = cur[k]
		else:
			cur = null
			break
	if cur != null:
		return cur
	var d = DEFAULT_TIMING
	for k in path:
		if d is Dictionary and d.has(k):
			d = d[k]
		else:
			d = null
			break
	if d != null:
		return d
	return EXTRA.get(path[path.size() - 1], fallback)


static func ti(path: Array, fallback: int = 0) -> int:
	return int(t(path, fallback))


static func tf(path: Array, fallback: float = 0.0) -> float:
	return float(t(path, fallback))


## The swapped layout of every shipped pad preset (Accessibility's `hand_layout`): `<id>-swapped`, the whole-pad mirror of SimSwap, tagged `hand: "swapped"` so the
## layout takes the swapped thumb's lockouts. Not the default of anything. A user's remap of Arena is Arena's; the swapped preset has its own.
static func _derive_swapped() -> void:
	var ids: Array = presets.keys()
	for id in ids:
		var p: Dictionary = presets[id]
		if str(p.get("device", "")) != "pad" or SimSwap.is_swapped_id(str(id)) or str(p.get("hand", "standard")) == "swapped":
			continue
		var q: Dictionary = SimSwap.mirror_preset(p)
		q["id"] = SimSwap.swapped_id(str(id))
		q["name"] = str(p.get("name", id)) + " (swapped)"
		q["hand"] = "swapped"
		q.erase("default")
		if q.has("pair"):
			q.erase("pair")
		presets[q["id"]] = q


## Whether the right-hand attacks are on (timing.json switches.rightStick, off): the strike stick, the left hand's brace and vanish, hybrids 3 and 10
## and the freed R3. With it off nothing in the input layer reads any of it and every record is the one it always was.
static func right_stick_on() -> bool:
	return bool(t(["switches", "rightStick"], false))


## The strike charge's rumble, one pulse as each rung of the ladder is reached (docs/controls/rule-of-cool-pitches.md pitch 1; switches.hapticLadder, off). Needs the right-hand switch.
static func haptic_ladder_on() -> bool:
	return right_stick_on() and bool(t(["switches", "hapticLadder"], false))


## The charge rumble from the director's stages (docs/controls/stage-pulses.md; switches.hapticStages, off): a pulse for each stick_stage cue, the hub's own rungs aside. Needs the ladder switch.
static func haptic_stages_on() -> bool:
	return haptic_ladder_on() and bool(t(["switches", "hapticStages"], false))


## The signature is RT + B only (docs/design/energy-overhaul.md E121; the EP's decision of 2026-11-01): B with LB, RB or LT held is the heavy of that stance (B with RB is Y's blast until the Driver
## has its own job), so a guard or a dodge can never fire a beam by accident. B alone stays the big blow. switches.signatureRtOnly, off.
static func signature_rt_only() -> bool:
	return bool(t(["switches", "signatureRtOnly"], false))


## The Driver is on RB + B (docs/director/pending/driver; data/director/interrupts.json blast.driver.enabled): with switches.signatureRtOnly, RB + B is then left as the B press for the Driver
## to read, instead of being sent as Y's blast. Set together with the Driver's own switch. switches.driverOnRb, off.
static func driver_on_rb() -> bool:
	return bool(t(["switches", "driverOnRb"], false))


## The flight strike's B (docs/controls/flight-strike-b.md; data/director/interrupts.json zip.flightStrikes.enabled): with switches.signatureRtOnly, LT + B is left as the B press for the flight strike to read (its biggest blow),
## instead of being sent as Y's heavy. LT + LB + B (the vanish), LB + B and RB + B are as they were. Set together with the flight strikes' own switch and dodgeHeld. switches.flightStrikeB, off.
static func flight_strike_b() -> bool:
	return bool(t(["switches", "flightStrikeB"], false))


## A player's B never starts a beam (docs/controls/b-no-beam.md; Orb, 2026-11-01: beams come only from the right stick): DirBrawl.isB reads every player's B press as the heavy, not only B with no layer held.
## The stick's own beam (DirStick.firing) is not a press of B and is unaffected. Needs nothing else. switches.bNoBeam, off.
static func b_no_beam() -> bool:
	return bool(t(["switches", "bNoBeam"], false))


## The interim of bNoBeam (the EP, 2026-11-08; Game Design's condition): RT + B is still the signature as a chord only, B within tapHold.holdStart ticks of RT's press, until RT + right stick is built, so the signature is never unreachable. A B during an RT channel is the heavy. Needs bNoBeam. switches.bNoBeamKeepRt, off.
static func b_no_beam_keep_rt() -> bool:
	return bool(t(["switches", "bNoBeamKeepRt"], false))


## A right-stick push on a layer where the strike stick is inert (RT held, or LB + RB: strike.inertMasks) is told, once per push (docs/controls/inert-knock.md): the layout adds a refusal "charging" ("warding")
## to its dropped list, so the hub knocks the pad once and UI can say "Charging". Needs rightStick and hapticRefused (the hub's refusal cues). switches.inertKnock, off.
static func inert_knock_on() -> bool:
	return bool(t(["switches", "inertKnock"], false))


## A lost charge is felt (docs/controls/charge-lost.md; switches.chargeLostCue, off): the heavy's charge, a stick strike's or a beam hold's taken by a blow, a charge lost to a stagger or the brawl's end, and a stick hold
## let go of before its first stage each get a pad pulse of their own and a refusal code for UI. Independent of the other haptic switches (the hold's tap needs the right stick, which has no hold without it).
static func charge_lost_cue_on() -> bool:
	return bool(t(["switches", "chargeLostCue"], false))


## The least ticks a right-stick hold lasts for its early release to be told (strike.shortHoldTicks).
static func short_hold_ticks() -> int:
	return clampi(ti(["strike", "shortHoldTicks"], 6), 2, 12)


## The director keeps a flick it cannot start yet (data/director/stick.json flickKeep, up to pendFollow.maxTicks = 90 ticks, with no cue while it waits), so the hub's wait for an answer is strike.refuseTicksKept (120)
## and not refuseTicks (30), or the pad knocks "Didn't start" at 31 ticks and the held flick then fires anyway (docs/controls/flick-kept.md). Set together with flickKeep. switches.flickKept, off.
static func flick_kept_on() -> bool:
	return bool(t(["switches", "flickKept"], false))


## LT's dash is on from the press tick and only while LT is held (docs/controls/dash-handover.md; Game Design's ruling of 2026-11-08 (c): LT's high speed is fast from the first tick, and a tapped LT stays the slip):
## no free 12-tick lunge after a release, so a tap is a tap and a hold is the high speed from tick 1. The sprint bit and the dodge edge are as they were. switches.dashHandover, off.
static func dash_handover_on() -> bool:
	return bool(t(["switches", "dashHandover"], false))


## Two attack presses on one tick are one blow, the biggest (docs/controls/chord-pick.md; switches.chordPick, off): B with X or Y, or Y with X, goes as the bigger press and the smaller is told "chord".
## Independent of the right-hand switch (a keyboard chords too).
static func chord_pick_on() -> bool:
	return bool(t(["switches", "chordPick"], false))


## The power specials are off (docs/design/pad-first-press.md: RT + X, Y, A are not built; a press is the plain blow and the charge drops). switches.specialsOff, off.
static func specials_off() -> bool:
	return bool(t(["switches", "specialsOff"], false))


## A stick press that never started a strike is told to its pad (the audit's gap 2; switches.hapticRefused, off). Needs the right-hand switch.
static func haptic_refused_on() -> bool:
	return right_stick_on() and bool(t(["switches", "hapticRefused"], false))


## The beam-answer window's rumble on the receiver's pad (docs/design/rule-of-cool-map.md row 40; switches.hapticIncomingBeam, off). Independent of the right-hand
## switch: a signature beam warns too.
static func haptic_beam_on() -> bool:
	return bool(t(["switches", "hapticIncomingBeam"], false))


## The incoming strike's rumble on the defender's pad (pitch 3; switches.hapticIncoming, off). Needs the right-hand switch.
static func haptic_incoming_on() -> bool:
	return right_stick_on() and bool(t(["switches", "hapticIncoming"], false))


## The quick read (docs/controls/responsiveness.md): the strike and brace settle one tick sooner, the vanish resolves on the second press, and the layout
## publishes the stick's pre-read for the pose. Needs the right-hand switch; off, every number is the one it always was.
static func quick_on() -> bool:
	return right_stick_on() and bool(t(["switches", "quickRead"], false))


## LT held, in the second word (docs/controls/dodge-held.md; switches.dodgeHeld, off): the intent says whether the dodge control is physically down this tick, so the flight strike's take-back can ask
## "LT still held at the face press". Needs the right-hand switch (the second word is its); off, every record is the one it always was.
static func dodge_held_on() -> bool:
	return right_stick_on() and bool(t(["switches", "dodgeHeld"], false))


## No input lost in a stall (docs/controls/stall-keep.md; switches.stallKeep, off): when the page hitches, several steps read the one pad snapshot the events left, so a flick that rose and fell between two
## steps was never seen. With it on the layout keeps the strike stick's furthest point (and a strike key's press) since its last build and reads it once.
## Needs the right-hand switch; off, every record is the one it always was.
static func stall_keep_on() -> bool:
	return right_stick_on() and bool(t(["switches", "stallKeep"], false))


## Every press answered (docs/controls/refusals.md): a press the game let go of with no sign knocks the pad of the one who made it and is listed for UI with a reason code. The same switch as the stick's
## refused knock (switches.hapticRefused, off); this is the form that needs no right-hand switch (a perfect block's lockout, a stun limit and the director's queue are not the stick's).
static func refusal_cues_on() -> bool:
	return bool(t(["switches", "hapticRefused"], false))


## The hits, closes, launches, landings and building breaks on the pad (Orb's 2026-10-05 rumble picks; docs/controls/impact-haptics.md; switches.hapticImpact, off). Independent of the right-hand switch.
static func haptic_impact_on() -> bool:
	return bool(t(["switches", "hapticImpact"], false))


## For the checks: every Controls switch off, as the data first shipped them, so a check of the old behaviour runs against it whatever the page's values are (the shipped data has them on).
## Reads the data as it is, sets the switches in memory and drops the caches; nothing is written.
static func pin_switches_off() -> void:
	var sw: Dictionary = timing.get("switches", {})
	for k in ["rightStick", "beamAim", "quickRead", "hapticLadder", "hapticIncoming", "hapticIncomingBeam", "hapticRefused", "specialsOff", "signatureRtOnly", "driverOnRb", "flightStrikeB", "chordPick", "dashHandover", "flickKept", "inertKnock", "chargeLostCue", "bNoBeam", "bNoBeamKeepRt", "webRumble", "stallKeep", "hapticImpact", "dodgeHeld"]:
		sw[k] = false
	timing["switches"] = sw
	clear_overrides()
	invalidate()


## The beam's aim (docs/controls/beam-aim-feel.md): the strike stick's aim trails the thumb by a small dead band, and the throw carries the aim the stick held at the rim,
## not the zero of a stick that has already sprung home. Needs the right-hand switch (switches.beamAim, off); off, every record is the one it always was.
static func beam_aim_on() -> bool:
	return right_stick_on() and bool(t(["switches", "beamAim"], false))


## A preset with its parked strike bindings (`strikeBindings`, the same shape as `bindings`) joined to its bindings while the right-hand switch is on, so the
## layout, the remap screen and the checks see one list. With the switch off, or no strike bindings, the preset comes back as it is.
static func _with_strike(p: Dictionary) -> Dictionary:
	if p.is_empty() or not p.has("strikeBindings") or not right_stick_on():
		return p
	var q: Dictionary = p.duplicate(true)
	for b in q["strikeBindings"]:
		q["bindings"].append(b)
	q.erase("strikeBindings")
	if str(q.get("device", "")) == "pad" and bool(t(["strike", "freeR3"], true)):
		# R3 (and L3, its swapped twin) is freed: a hard flick clicks the stick. The shipped Escape on it goes; the player may bind `escape` to any control in Remap.
		var kept: Array = []
		for b in q["bindings"]:
			var c: Array = b["controls"]
			if str(b["action"]) == "escape" and c.size() == 1 and (str(c[0]) == "pad:r3" or str(c[0]) == "pad:l3"):
				continue
			kept.append(b)
		q["bindings"] = kept
	return q


## A preset by id with the overrides of `slot`'s player applied (slot 0, player one, by default), or an empty dictionary.
static func preset(id: String, slot: int = 0) -> Dictionary:
	ensure()
	if overrides[slot].has(id) and presets.has(id):
		if not _merged[slot].has(id):
			_merged[slot][id] = SimInputRemap.apply_overrides(_with_strike(presets[id]), overrides[slot][id])
		return _merged[slot][id]
	return _with_strike(presets.get(id, {}))


## The shipped preset, without the player's changes (what Reset goes back to).
static func original(id: String) -> Dictionary:
	ensure()
	return _with_strike(presets.get(id, {}))


## Apply the player's overrides for a preset: the shipped bindings stay, the effective preset is those plus the overrides
## (SimInputRemap.apply_overrides). Idempotent; an empty list restores the shipped preset. Returns the effective preset,
## which preset(id) returns from now on. Not for touch presets (they are not remapped).
static func apply_overrides(id: String, entries: Array, slot: int = 0) -> Dictionary:
	ensure()
	set_overrides(id, entries, slot)
	return preset(id, slot)


## Problems in a preset (the effective one by default): [{rule, action, control}], one source of truth for the screen. `slot`
## is the player the preset belongs to; the shared-keyboard pair rule compares it with the other player's half.
static func check_bindings(p: Dictionary, slot: int = 0) -> Array:
	ensure()
	var pair: Dictionary = {}
	if p.has("pair"):
		pair = preset(str(p["pair"]), 1 - slot)
	return SimInputRemap.check_bindings(p, pair)


## Write the current overrides to the player's file (user://input.json), keeping what else it holds: `presets` is player
## one's, `presets_p2` is player two's.
static func save_overrides(path: String = SimInputRemap.USER_PATH) -> bool:
	var d: Dictionary = SimInputRemap.load_file(path)
	d["presets"] = {}
	d["presets_p2"] = {}
	for id in overrides[0]:
		d["presets"][id] = {"overrides": overrides[0][id]}
	for id in overrides[1]:
		d["presets_p2"][id] = {"overrides": overrides[1][id]}
	return SimInputRemap.save_file(d, path)


static func set_overrides(id: String, entries: Array, slot: int = 0) -> void:
	if entries.is_empty():
		overrides[slot].erase(id)
	else:
		overrides[slot][id] = entries
	_merged[slot].erase(id)


static func clear_overrides() -> void:
	overrides = [{}, {}]
	_merged = [{}, {}]


## The default preset id for a device ("kb", "pad" or "touch").
static func default_preset(device: String) -> String:
	ensure()
	for id in presets:
		var p: Dictionary = presets[id]
		if p.get("device", "") == device and p.get("default", false) == true:
			return id
	return ""


## Load the data and set SimAct's statics from it: the request queue's depth, the dodge's state window and the away
## dead zone. Called once by the host at startup.
static func load_and_apply() -> void:
	load_data()
	SimInputRemap.apply_file(SimInputRemap.load_file())   # the player's remaps, if there is a file
	SimAct.queueMax = ti(["attackQueue", "max"], SimAct.queueMax)
	SimAct.dodgeWindow = ti(["dodge", "stateTicks"], SimAct.dodgeWindow)
	SimAct.awayDead = tf(["stick", "awayDead"], SimAct.awayDead)
