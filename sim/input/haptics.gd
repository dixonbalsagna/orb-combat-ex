class_name SimHaptics
extends RefCounted
## The pulses a pad or a phone gives (docs/controls/haptics.md): what UI asks for with `haptic_requested(slot, kind)` and the host plays.
## Pure functions over data: no engine call, no clock, no state, no RNG. The host (render/core/main.gd) calls `plan` and plays the steps
## it returns (`Input.start_joy_vibration`, `Input.vibrate_handheld`), the later ones on host timers; nothing here reads or writes the
## sim, the replay or the hash, and a pulse is never the only cue (UI's chip and Audio's sound say the same).
##
## The numbers are `haptics` in data/input/timing.json. For each kind (UI's and Audio's names: "launch_open", "form_prompt",
## "struggle_pulse", "struggle_surge", "struggle_lose") there are two lists of STEPS, `pad` and `handheld`:
##   a pad step {at, weak, strong, ms}: `at` milliseconds after the request, the two motors (`weak` the high-frequency one, `strong` the
##     low, each 0 to 1) and `ms` its length;
##   a phone step {at, ms}.
## Three global numbers: `minGapMs` (a second request for the same slot inside it is dropped), `padMinMs` and `handheldMinMs` (the shortest
## pulse the hardware can feel: a motor needs about 20 to 40 ms to spin up, so a shorter request is lengthened to this, never dropped,
## and never passed as 0, which Godot reads as "for as long as it can"). Absent, these defaults stand.
## The feel of each shape is Audio's (docs/audio/launch-and-tug.md); the hardware floors are Controls'.

const DEFAULTS: Dictionary = {
	# A thump with a ring after it: the pluck and the head snap, then the ring (Audio's shape, 150 ms in all).
	"launch_open": {
		"pad": [{"at": 0, "weak": 0.3, "strong": 0.7, "ms": 80}, {"at": 90, "weak": 0.2, "strong": 0.0, "ms": 60}],
		"handheld": [{"at": 0, "ms": 25}, {"at": 85, "ms": 10}],
	},
	"form_prompt": {"pad": [{"at": 0, "weak": 0.3, "strong": 0.3, "ms": 20}], "handheld": [{"at": 0, "ms": 15}]},
	# The beam struggle: the beat both players feel, a player's own surge, and the loser's end.
	"struggle_pulse": {"pad": [{"at": 0, "weak": 0.0, "strong": 0.4, "ms": 20}], "handheld": [{"at": 0, "ms": 10}]},
	"struggle_surge": {"pad": [{"at": 0, "weak": 0.5, "strong": 0.3, "ms": 30}], "handheld": [{"at": 0, "ms": 15}]},
	"struggle_lose": {"pad": [{"at": 0, "weak": 0.4, "strong": 0.8, "ms": 60}], "handheld": [{"at": 0, "ms": 40}]},
}
const MIN_GAP_MS: int = 80
const PAD_MIN_MS: int = 20
const HANDHELD_MIN_MS: int = 10
const MAX_STEPS: int = 4
const MAX_AT_MS: int = 1000


## The kinds this knows.
static func kinds() -> Array:
	return DEFAULTS.keys()


## The minimum gap between two requests for one slot, in milliseconds.
static func min_gap_ms() -> int:
	return SimInputData.ti(["haptics", "minGapMs"], MIN_GAP_MS)


## One kind's steps for a device ("pad" or "handheld"), cleaned: each `at` 0 to 1000 ms, motors clamped to 0 to 1, each length raised to the
## hardware floor, a step with no strength (a pad) or no length left out, at most 4 steps, in order of `at`. [] for an unknown kind.
static func steps(kind: String, device: String) -> Array:
	if not DEFAULTS.has(kind) or (device != "pad" and device != "handheld"):
		return []
	var raw = SimInputData.t(["haptics", kind, device], DEFAULTS[kind][device])
	if not (raw is Array):
		raw = DEFAULTS[kind][device]
	var floor_ms: int = SimInputData.ti(["haptics", "padMinMs"], PAD_MIN_MS) if device == "pad" else SimInputData.ti(["haptics", "handheldMinMs"], HANDHELD_MIN_MS)
	var out: Array = []
	for s in raw:
		if not (s is Dictionary):
			continue
		var ms: int = int(s.get("ms", 0))
		if ms <= 0:
			continue
		var st: Dictionary = {"at": clampi(int(s.get("at", 0)), 0, MAX_AT_MS), "ms": maxi(ms, floor_ms)}
		if device == "pad":
			st["weak"] = clampf(float(s.get("weak", 0.0)), 0.0, 1.0)
			st["strong"] = clampf(float(s.get("strong", 0.0)), 0.0, 1.0)
			if float(st["weak"]) <= 0.0 and float(st["strong"]) <= 0.0:
				continue
		out.append(st)
	out.sort_custom(func(a, b): return int(a["at"]) < int(b["at"]))
	if out.size() > MAX_STEPS:
		out.resize(MAX_STEPS)
	return out


## Whether a request at `now_ms` may play, `last_ms` being when this slot's last one did (host milliseconds; the host owns the clock).
static func allow(last_ms: int, now_ms: int) -> bool:
	return now_ms - last_ms >= min_gap_ms() or now_ms < last_ms


## What to play for UI's request, or {} for nothing. `target` is `hub.rumble_target(slot)` ({kind, id}); `enabled` is the player's haptics
## option; `last_ms` and `now_ms` are the host's clock for this slot. Each step is played `at` milliseconds after the request (the first
## now, the rest on host timers):
##   a pad:   {via: "pad", id, steps: [{at, weak, strong, seconds}]}   -> Input.start_joy_vibration(id, weak, strong, seconds)
##   a phone: {via: "handheld", steps: [{at, ms}]}                      -> Input.vibrate_handheld(ms)
## A keyboard, a slot nobody holds, an unknown kind, the option off, nothing left in the steps, or a request too soon after the last: {}.
static func plan(kind: String, target: Dictionary, enabled: bool, last_ms: int, now_ms: int) -> Dictionary:
	if not enabled or not allow(last_ms, now_ms):
		return {}
	match str(target.get("kind", "none")):
		"pad":
			var ps: Array = steps(kind, "pad")
			if ps.is_empty():
				return {}
			var out: Array = []
			for s in ps:
				out.append({"at": int(s["at"]), "weak": float(s["weak"]), "strong": float(s["strong"]), "seconds": float(s["ms"]) / 1000.0})
			return {"via": "pad", "id": int(target.get("id", -1)), "steps": out}
		"touch":
			var hs: Array = steps(kind, "handheld")
			if hs.is_empty():
				return {}
			return {"via": "handheld", "steps": hs}
	return {}
