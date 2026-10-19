class_name SimHaptics
extends RefCounted
## The pulses a pad or a phone gives (docs/controls/haptics.md): what a cue from the sim asks for and the host plays.
## Pure functions over data: no engine call, no clock, no state, no RNG. The host (render/core/main.gd) calls `plan` and plays the steps
## it returns (`Input.start_joy_vibration`, `Input.vibrate_handheld`), the later ones on host timers; nothing here reads or writes the
## sim, the replay or the hash, and a pulse is never the only cue (UI's chip, Audio's sound and the fighters' own bodies say the same).
##
## The numbers are `haptics` in data/input/timing.json. For each kind (see KINDS) there are two lists of STEPS, `pad` and `handheld`:
##   a pad step {at, weak, strong, ms}: `at` milliseconds after the request, the two motors (`weak` the high-frequency one, `strong` the
##     low, each 0 to 1) and `ms` its length;
##   a phone step {at, ms}.
## Global numbers: `minGapMs` (a second request for the same slot inside it is dropped), `padMinMs` and `handheldMinMs` (the shortest
## pulse the hardware can feel: a motor needs about 20 to 40 ms to spin up, so a shorter request is lengthened to this, never dropped,
## and never passed as 0, which Godot reads as "for as long as it can"), `scaleMin` (see SCALE) and `padMinStrength` (a motor below this
## is not felt, so a scaled step is raised to it). A kind may carry its own `gapMs`: the least time between two of that kind for one
## slot, so a mashed button or a steady beat can never make the pad buzz without a break. Absent, these defaults stand.
## The feel of each shape is Audio's (docs/audio/launch-and-tug.md); the hardware floors and the rate limits are Controls'.
##
## SCALE. `plan` and `steps` take a scale from 0 to 1 (the struggle's share, the clinch's grip): a pad step's motors are multiplied by
## scaleMin + (1 - scaleMin) * scale and raised to padMinStrength; a phone, which has no strength, gets a shorter pulse the same way (never
## under handheldMinMs). A scale of 1 is the data as written.
## MAPPING. `requests` turns a sim cue into who feels what, from the cue's own fields (no state but the firer's slot, which the host keeps
## from the beam struggle's first cue).

const DEFAULTS: Dictionary = {
	# A thump with a ring after it: the pluck and the head snap, then the ring (Audio's shape, 150 ms in all). The launcher only.
	"launch_open": {
		"pad": [{"at": 0, "weak": 0.3, "strong": 0.7, "ms": 80}, {"at": 90, "weak": 0.2, "strong": 0.0, "ms": 60}],
		"handheld": [{"at": 0, "ms": 25}, {"at": 85, "ms": 10}],
		"gapMs": 300,
	},
	# The form is ready: two light taps, the second firmer. Rising, so it says "now" rather than "hit".
	"form_prompt": {
		"pad": [{"at": 0, "weak": 0.25, "strong": 0.25, "ms": 20}, {"at": 70, "weak": 0.4, "strong": 0.4, "ms": 30}],
		"handheld": [{"at": 0, "ms": 10}, {"at": 70, "ms": 20}],
		"gapMs": 200,
	},
	# The air brake can be set: one sharp tick on the high motor alone. Nothing low in it, which is what tells it from every other kind.
	"brake_ready": {
		"pad": [{"at": 0, "weak": 0.6, "strong": 0.0, "ms": 20}],
		"handheld": [{"at": 0, "ms": 10}],
		"gapMs": 200,
	},
	# The heavy's charge is full: one firm snap on both motors.
	"charge_full": {
		"pad": [{"at": 0, "weak": 0.5, "strong": 0.6, "ms": 40}],
		"handheld": [{"at": 0, "ms": 35}],
		"gapMs": 200,
	},
	# The clinch's pulse (every 20 ticks): a low creak, then a faint scrape after it. Scaled by the grip.
	"clinch_pulse": {
		"pad": [{"at": 0, "weak": 0.0, "strong": 0.3, "ms": 30}, {"at": 50, "weak": 0.15, "strong": 0.0, "ms": 20}],
		"handheld": [{"at": 0, "ms": 15}, {"at": 50, "ms": 10}],
		"gapMs": 250,
	},
	# The beam struggle, off the beat: a player's own surge (a bright tick, the high motor) and a surge made against him (a heavy low
	# push), both scaled by the share of the point the pusher holds. The loser's end is once.
	"struggle_push": {
		"pad": [{"at": 0, "weak": 0.5, "strong": 0.1, "ms": 25}],
		"handheld": [{"at": 0, "ms": 20}],
		"gapMs": 100,
	},
	"struggle_pushed": {
		"pad": [{"at": 0, "weak": 0.0, "strong": 0.6, "ms": 40}],
		"handheld": [{"at": 0, "ms": 30}],
		"gapMs": 160,
	},
	"struggle_lose": {
		"pad": [{"at": 0, "weak": 0.4, "strong": 0.8, "ms": 60}],
		"handheld": [{"at": 0, "ms": 40}],
		"gapMs": 300,
	},
}
const MIN_GAP_MS: int = 80
const PAD_MIN_MS: int = 20
const HANDHELD_MIN_MS: int = 10
const SCALE_MIN: float = 0.35
const PAD_MIN_STRENGTH: float = 0.15
const GRIP_STEPS: int = 5
const SHARP_BOOST: float = 0.25
const MAX_STEPS: int = 4
const MAX_AT_MS: int = 1000


## The kinds this knows.
static func kinds() -> Array:
	return DEFAULTS.keys()


## The minimum gap between two requests for one slot, in milliseconds.
static func min_gap_ms() -> int:
	return SimInputData.ti(["haptics", "minGapMs"], MIN_GAP_MS)


## The least time between two requests of one kind for one slot: the kind's own `gapMs`, never under the slot-wide gap. 0 for an unknown kind.
static func kind_gap_ms(kind: String) -> int:
	if not DEFAULTS.has(kind):
		return 0
	return maxi(min_gap_ms(), SimInputData.ti(["haptics", kind, "gapMs"], int(DEFAULTS[kind].get("gapMs", 0))))


## One kind's steps for a device ("pad" or "handheld"), cleaned: each `at` 0 to 1000 ms, motors clamped to 0 to 1, each length raised to the
## hardware floor, a step with no strength (a pad) or no length left out, at most 4 steps, in order of `at`; then scaled (see SCALE).
## [] for an unknown kind.
static func steps(kind: String, device: String, scale: float = 1.0) -> Array:
	if not DEFAULTS.has(kind) or (device != "pad" and device != "handheld"):
		return []
	var raw = SimInputData.t(["haptics", kind, device], DEFAULTS[kind][device])
	if not (raw is Array):
		raw = DEFAULTS[kind][device]
	var floor_ms: int = SimInputData.ti(["haptics", "padMinMs"], PAD_MIN_MS) if device == "pad" else SimInputData.ti(["haptics", "handheldMinMs"], HANDHELD_MIN_MS)
	var f: float = scale_factor(scale)
	var min_strength: float = clampf(SimInputData.tf(["haptics", "padMinStrength"], PAD_MIN_STRENGTH), 0.0, 1.0)
	var out: Array = []
	for s in raw:
		if not (s is Dictionary):
			continue
		var ms: int = int(s.get("ms", 0))
		if ms <= 0:
			continue
		ms = maxi(ms, floor_ms)
		var st: Dictionary = {"at": clampi(int(s.get("at", 0)), 0, MAX_AT_MS), "ms": ms}
		if device == "pad":
			var weak: float = clampf(float(s.get("weak", 0.0)), 0.0, 1.0)
			var strong: float = clampf(float(s.get("strong", 0.0)), 0.0, 1.0)
			if weak <= 0.0 and strong <= 0.0:
				continue
			st["weak"] = _scaled(weak, f, min_strength)
			st["strong"] = _scaled(strong, f, min_strength)
		elif f < 1.0:
			st["ms"] = maxi(floor_ms, int(round(float(ms) * f)))
		out.append(st)
	out.sort_custom(func(a, b): return int(a["at"]) < int(b["at"]))
	if out.size() > MAX_STEPS:
		out.resize(MAX_STEPS)
	return out


## A motor value scaled by `f`, raised to the least strength a motor can be felt at, but a motor that was off stays off.
static func _scaled(v: float, f: float, min_strength: float) -> float:
	if v <= 0.0 or f >= 1.0:
		return v
	return clampf(maxf(v * f, min_strength), 0.0, 1.0)


## The factor a scale of 0 to 1 gives: scaleMin at 0, 1 at 1, linear between; anything outside is clamped.
static func scale_factor(scale: float) -> float:
	var lo: float = clampf(SimInputData.tf(["haptics", "scaleMin"], SCALE_MIN), 0.0, 1.0)
	return lo + (1.0 - lo) * clampf(scale, 0.0, 1.0)


## Whether a request at `now_ms` may play, `last_ms` being when this slot's last one did (host milliseconds; the host owns the clock).
## `gap_ms` overrides the slot-wide gap (the kind's own: `kind_gap_ms`).
static func allow(last_ms: int, now_ms: int, gap_ms: int = -1) -> bool:
	var gap: int = min_gap_ms() if gap_ms < 0 else gap_ms
	return now_ms - last_ms >= gap or now_ms < last_ms


## What to play for a request, or {} for nothing. `target` is `hub.rumble_target(slot)` ({kind, id}); `enabled` is the player's haptics
## option; `last_ms` and `now_ms` are the host's clock for this slot (its last pulse of any kind), `last_kind_ms` is when this slot last
## felt this kind (a kind's own gap; default none yet), and `scale` is 0 to 1 (see SCALE). Each step is played `at` milliseconds after the
## request (the first now, the rest on host timers):
##   a pad:   {via: "pad", id, steps: [{at, weak, strong, seconds}]}   -> Input.start_joy_vibration(id, weak, strong, seconds)
##   a phone: {via: "handheld", steps: [{at, ms}]}                      -> Input.vibrate_handheld(ms)
## A keyboard, a slot nobody holds, an unknown kind, the option off, nothing left in the steps, a request too soon after the last or too
## soon after the last of its own kind: {}.
static func plan(kind: String, target: Dictionary, enabled: bool, last_ms: int, now_ms: int, scale: float = 1.0, last_kind_ms: int = -1000000) -> Dictionary:
	if not enabled or not DEFAULTS.has(kind) or not allow(last_ms, now_ms) or not allow(last_kind_ms, now_ms, kind_gap_ms(kind)):
		return {}
	match str(target.get("kind", "none")):
		"pad":
			var ps: Array = steps(kind, "pad", scale)
			if ps.is_empty():
				return {}
			var out: Array = []
			for s in ps:
				out.append({"at": int(s["at"]), "weak": float(s["weak"]), "strong": float(s["strong"]), "seconds": float(s["ms"]) / 1000.0})
			return {"via": "pad", "id": int(target.get("id", -1)), "steps": out}
		"touch":
			var hs: Array = steps(kind, "handheld", scale)
			if hs.is_empty():
				return {}
			return {"via": "handheld", "steps": hs}
	return {}


## The pusher's share of the beam struggle's point. `point` is the cue's `amount`: 0 at the firer's hands, 1 at the other's, so the
## firer pushes it up and the other down. 0 to 1, 0.5 at an even tug.
static func push_share(point: float, pusher_is_firer: bool) -> float:
	var p: float = clampf(point, 0.0, 1.0)
	return p if pusher_is_firer else 1.0 - p


## Who feels what for one sim cue: an array of {slot, kind, scale}, [] for a cue that rumbles nothing. The cue's own fields, as the sim
## sends them (`name` the cue's kind, or the event's type for transform_ready):
##   launcher_open        actor = the fighter who may launch           -> that slot, launch_open
##   transform_ready      actor                                        -> that slot, form_prompt
##   charge_full          actor = the charger                          -> that slot, charge_full
##   air_brake text "ready"  actor (the brake can be set: Simulation's -> that slot, brake_ready
##                        event to add; start and end rumble nothing)
##   grapple_pulse        actor, target, amount = the catcher's grip   -> both, clinch_pulse, scaled by |grip| / 5
##   beam_surge           actor (the pusher), target, amount = the    -> the pusher struggle_push, the other struggle_pushed, both
##                        point after it, text "sharp" (a surge in the  scaled by the pusher's share of the point (a sharp one
##                        window's first tick)                          adds sharpBoost)
##   beam_end text "overwhelmed"   actor = the winner, target = the  -> the target, struggle_lose
##                        overwhelmed fighter
## `firer` is the slot that fired the struggle's first beam (the `beam_struggle` cue's actor, whose hands are the point's 0), which the
## host keeps; -1 if unknown (the surge's actor is then taken as the firer). A beam_stray and every other cue rumble nothing.
static func requests(name: String, actor: int, target: int, text: String, amount: float, firer: int = -1) -> Array:
	match name:
		"launcher_open":
			return [{"slot": actor, "kind": "launch_open", "scale": 1.0}] if actor >= 0 else []
		"transform_ready":
			return [{"slot": actor, "kind": "form_prompt", "scale": 1.0}] if actor >= 0 else []
		"charge_full":
			return [{"slot": actor, "kind": "charge_full", "scale": 1.0}] if actor >= 0 else []
		"air_brake":
			return [{"slot": actor, "kind": "brake_ready", "scale": 1.0}] if actor >= 0 and text == "ready" else []
		"grapple_pulse":
			var steps_n: float = float(maxi(1, SimInputData.ti(["haptics", "gripSteps"], GRIP_STEPS)))
			var sc: float = clampf(absf(amount) / steps_n, 0.0, 1.0)
			var out: Array = []
			if actor >= 0:
				out.append({"slot": actor, "kind": "clinch_pulse", "scale": sc})
			if target >= 0 and target != actor:
				out.append({"slot": target, "kind": "clinch_pulse", "scale": sc})
			return out
		"beam_surge":
			if actor < 0:
				return []
			var other: int = target if target >= 0 and target != actor else 1 - actor
			var share: float = push_share(amount, actor == firer or firer < 0)
			if text == "sharp":
				share = minf(1.0, share + SimInputData.tf(["haptics", "sharpBoost"], SHARP_BOOST))
			var res: Array = [{"slot": actor, "kind": "struggle_push", "scale": share}]
			if other >= 0 and other != actor:
				res.append({"slot": other, "kind": "struggle_pushed", "scale": share})
			return res
		"beam_end":
			# The sim's cue names the winner as the actor and the overwhelmed fighter as the target.
			return [{"slot": target, "kind": "struggle_lose", "scale": 1.0}] if text == "overwhelmed" and target >= 0 else []
	return []
