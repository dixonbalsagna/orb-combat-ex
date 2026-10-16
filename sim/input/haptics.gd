class_name SimHaptics
extends RefCounted
## The pulses a pad or a phone gives (docs/controls/haptics.md): what UI asks for with `haptic_requested(slot, kind)` and the host plays.
## Pure functions over data: no engine call, no clock, no state, no RNG. The host (render/core/main.gd) calls `plan` and does the
## engine calls it returns (`Input.start_joy_vibration`, `Input.vibrate_handheld`); nothing here reads or writes the sim, the replay or
## the hash, and a pulse is never the only cue (UI's chip says the same).
##
## The numbers are `haptics` in data/input/timing.json: for each kind (UI's names: "launch_open", "form_prompt") the two motors
## (`weak`, the high-frequency one, and `strong`, the low, each 0 to 1), `ms` (a pad's pulse, in milliseconds) and `handheldMs` (a
## phone's vibration); and `minGapMs`, the gap under which a second pulse for the same slot is dropped (a mash of events must not
## become a buzz). Absent, these defaults stand.

const DEFAULTS: Dictionary = {
	"launch_open": {"weak": 0.7, "strong": 0.0, "ms": 25, "handheldMs": 25},   # a sharp tick: the launch is ready (the lit B)
	"form_prompt": {"weak": 0.3, "strong": 0.3, "ms": 15, "handheldMs": 15},   # a soft thump: the form is ready
}
const MIN_GAP_MS: int = 80


## The kinds this knows.
static func kinds() -> Array:
	return DEFAULTS.keys()


## The minimum gap between two pulses for one slot, in milliseconds.
static func min_gap_ms() -> int:
	return SimInputData.ti(["haptics", "minGapMs"], MIN_GAP_MS)


## One kind's numbers: {weak, strong, ms, handheldMs}, or {} for a kind it does not know.
static func numbers(kind: String) -> Dictionary:
	if not DEFAULTS.has(kind):
		return {}
	var d: Dictionary = DEFAULTS[kind]
	return {
		"weak": clampf(SimInputData.tf(["haptics", kind, "weak"], float(d["weak"])), 0.0, 1.0),
		"strong": clampf(SimInputData.tf(["haptics", kind, "strong"], float(d["strong"])), 0.0, 1.0),
		"ms": maxi(0, SimInputData.ti(["haptics", kind, "ms"], int(d["ms"]))),
		"handheldMs": maxi(0, SimInputData.ti(["haptics", kind, "handheldMs"], int(d["handheldMs"]))),
	}


## Whether a pulse at `now_ms` may play, `last_ms` being when this slot's last one did (host milliseconds; the host owns the clock).
static func allow(last_ms: int, now_ms: int) -> bool:
	return now_ms - last_ms >= min_gap_ms() or now_ms < last_ms


## What to play for UI's request, or {} for nothing. `target` is `hub.rumble_target(slot)` ({kind, id}); `enabled` is the player's
## haptics option; `last_ms` and `now_ms` are the host's clock for this slot.
##   a pad:   {via: "pad", id, weak, strong, seconds}                        -> Input.start_joy_vibration(id, weak, strong, seconds)
##   a phone: {via: "handheld", ms}                                          -> Input.vibrate_handheld(ms)
## A keyboard, a slot nobody holds, an unknown kind, a pulse of no length, the option off, or a pulse too soon after the last: {}.
static func plan(kind: String, target: Dictionary, enabled: bool, last_ms: int, now_ms: int) -> Dictionary:
	if not enabled or not allow(last_ms, now_ms):
		return {}
	var n: Dictionary = numbers(kind)
	if n.is_empty():
		return {}
	match str(target.get("kind", "none")):
		"pad":
			if int(n["ms"]) <= 0 or (float(n["weak"]) <= 0.0 and float(n["strong"]) <= 0.0):
				return {}
			return {"via": "pad", "id": int(target.get("id", -1)), "weak": float(n["weak"]), "strong": float(n["strong"]), "seconds": float(n["ms"]) / 1000.0}
		"touch":
			if int(n["handheldMs"]) <= 0:
				return {}
			return {"via": "handheld", "ms": int(n["handheldMs"])}
	return {}
